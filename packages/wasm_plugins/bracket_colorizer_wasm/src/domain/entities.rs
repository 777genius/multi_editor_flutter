// Domain Entities - Core business objects

use serde::{Deserialize, Serialize};
use super::value_objects::{BracketType, BracketSide, Position, ColorLevel};

/// A single bracket in the source code
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Bracket {
    /// Type of bracket
    pub bracket_type: BracketType,

    /// Side (opening or closing)
    pub side: BracketSide,

    /// Position in source code
    pub position: Position,

    /// Nesting depth
    pub depth: usize,

    /// Color level for this bracket
    pub color_level: ColorLevel,

    /// Character representation
    pub character: char,
}

impl Bracket {
    pub fn new(
        bracket_type: BracketType,
        side: BracketSide,
        position: Position,
        depth: usize,
        color_level: ColorLevel,
    ) -> Self {
        let character = match side {
            BracketSide::Opening => bracket_type.opening_char(),
            BracketSide::Closing => bracket_type.closing_char(),
        };

        Self {
            bracket_type,
            side,
            position,
            depth,
            color_level,
            character,
        }
    }

    /// Check if this is an opening bracket
    pub fn is_opening(&self) -> bool {
        self.side == BracketSide::Opening
    }

    /// Check if this is a closing bracket
    pub fn is_closing(&self) -> bool {
        self.side == BracketSide::Closing
    }

    /// Check if this bracket matches another bracket type
    pub fn matches_type(&self, other: &Bracket) -> bool {
        self.bracket_type == other.bracket_type
    }
}

/// A matched pair of brackets (opening and closing)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BracketPair {
    /// Opening bracket
    pub opening: Bracket,

    /// Closing bracket
    pub closing: Bracket,

    /// Nesting depth
    pub depth: usize,

    /// Whether this pair is properly matched
    pub is_matched: bool,
}

impl BracketPair {
    pub fn new(opening: Bracket, closing: Bracket) -> Self {
        let is_matched = opening.matches_type(&closing)
            && opening.is_opening()
            && closing.is_closing();

        let depth = opening.depth;

        Self {
            opening,
            closing,
            depth,
            is_matched,
        }
    }

    /// Get the bracket type
    pub fn bracket_type(&self) -> BracketType {
        self.opening.bracket_type
    }

    /// Get the color level
    pub fn color_level(&self) -> ColorLevel {
        self.opening.color_level
    }

    /// Check if this pair contains a position
    pub fn contains_position(&self, pos: &Position) -> bool {
        pos >= &self.opening.position && pos <= &self.closing.position
    }

    /// Get the range span (number of characters between brackets)
    pub fn span(&self) -> u32 {
        self.closing.position.offset - self.opening.position.offset
    }
}

/// Unmatched bracket (orphan)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UnmatchedBracket {
    /// The unmatched bracket
    pub bracket: Bracket,

    /// Reason for being unmatched
    pub reason: UnmatchedReason,
}

/// Reason why a bracket is unmatched
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum UnmatchedReason {
    /// No corresponding closing bracket found
    MissingClosing,

    /// No corresponding opening bracket found
    MissingOpening,

    /// Mismatched bracket type
    TypeMismatch { expected: BracketType, found: BracketType },

    /// Bracket appears in string or comment
    InStringOrComment,
}

/// Collection of all brackets and pairs in a document
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BracketCollection {
    /// All matched bracket pairs
    pub pairs: Vec<BracketPair>,

    /// All unmatched brackets
    pub unmatched: Vec<UnmatchedBracket>,

    /// Maximum nesting depth found
    pub max_depth: usize,

    /// Total number of brackets processed
    pub total_brackets: usize,

    /// Analysis duration in milliseconds
    pub analysis_duration_ms: u64,

    /// Statistics by bracket type
    pub statistics: BracketStatistics,
}

impl BracketCollection {
    pub fn new(
        pairs: Vec<BracketPair>,
        unmatched: Vec<UnmatchedBracket>,
        max_depth: usize,
        analysis_duration_ms: u64,
    ) -> Self {
        let total_brackets = pairs.len() * 2 + unmatched.len();
        let statistics = BracketStatistics::calculate(&pairs, &unmatched);

        Self {
            pairs,
            unmatched,
            max_depth,
            total_brackets,
            analysis_duration_ms,
            statistics,
        }
    }

    /// Get all brackets at a specific depth
    pub fn brackets_at_depth(&self, depth: usize) -> Vec<&BracketPair> {
        self.pairs.iter().filter(|p| p.depth == depth).collect()
    }

    /// Find bracket pair containing a position
    pub fn find_pair_at_position(&self, pos: &Position) -> Option<&BracketPair> {
        self.pairs.iter().find(|p| p.contains_position(pos))
    }

    /// Check if there are any unmatched brackets
    pub fn has_errors(&self) -> bool {
        !self.unmatched.is_empty()
    }
}

/// Statistics about brackets
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct BracketStatistics {
    /// Count of round brackets ()
    pub round_pairs: usize,

    /// Count of curly brackets {}
    pub curly_pairs: usize,

    /// Count of square brackets []
    pub square_pairs: usize,

    /// Count of angle brackets <>
    pub angle_pairs: usize,

    /// Count of unmatched brackets
    pub unmatched_count: usize,

    /// Count of mismatched brackets
    pub mismatched_count: usize,
}

impl BracketStatistics {
    pub fn calculate(pairs: &[BracketPair], unmatched: &[UnmatchedBracket]) -> Self {
        let mut stats = Self::default();

        for pair in pairs {
            match pair.bracket_type() {
                BracketType::Round => stats.round_pairs += 1,
                BracketType::Curly => stats.curly_pairs += 1,
                BracketType::Square => stats.square_pairs += 1,
                BracketType::Angle => stats.angle_pairs += 1,
            }
        }

        stats.unmatched_count = unmatched.len();
        stats.mismatched_count = unmatched
            .iter()
            .filter(|u| matches!(u.reason, UnmatchedReason::TypeMismatch { .. }))
            .count();

        stats
    }

    /// Total number of matched pairs
    pub fn total_pairs(&self) -> usize {
        self.round_pairs + self.curly_pairs + self.square_pairs + self.angle_pairs
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::value_objects::*;

    #[test]
    fn test_bracket_creation() {
        let bracket = Bracket::new(
            BracketType::Round,
            BracketSide::Opening,
            Position::new(0, 0, 0),
            0,
            ColorLevel::new(0),
        );

        assert_eq!(bracket.character, '(');
        assert!(bracket.is_opening());
        assert!(!bracket.is_closing());
    }

    #[test]
    fn test_bracket_pair_matching() {
        let opening = Bracket::new(
            BracketType::Round,
            BracketSide::Opening,
            Position::new(0, 0, 0),
            0,
            ColorLevel::new(0),
        );

        let closing = Bracket::new(
            BracketType::Round,
            BracketSide::Closing,
            Position::new(0, 10, 10),
            0,
            ColorLevel::new(0),
        );

        let pair = BracketPair::new(opening, closing);

        assert!(pair.is_matched);
        assert_eq!(pair.bracket_type(), BracketType::Round);
        assert_eq!(pair.span(), 10);
    }

    #[test]
    fn test_bracket_pair_mismatched() {
        let opening = Bracket::new(
            BracketType::Round,
            BracketSide::Opening,
            Position::new(0, 0, 0),
            0,
            ColorLevel::new(0),
        );

        let closing = Bracket::new(
            BracketType::Curly, // Mismatch!
            BracketSide::Closing,
            Position::new(0, 10, 10),
            0,
            ColorLevel::new(0),
        );

        let pair = BracketPair::new(opening, closing);

        assert!(!pair.is_matched);
    }

    #[test]
    fn test_bracket_collection() {
        let opening = Bracket::new(
            BracketType::Round,
            BracketSide::Opening,
            Position::new(0, 0, 0),
            0,
            ColorLevel::new(0),
        );

        let closing = Bracket::new(
            BracketType::Round,
            BracketSide::Closing,
            Position::new(0, 10, 10),
            0,
            ColorLevel::new(0),
        );

        let pair = BracketPair::new(opening, closing);
        let collection = BracketCollection::new(vec![pair], vec![], 1, 5);

        assert_eq!(collection.total_brackets, 2);
        assert_eq!(collection.max_depth, 1);
        assert!(!collection.has_errors());
        assert_eq!(collection.statistics.round_pairs, 1);
    }
}
