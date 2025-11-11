use serde::{Deserialize, Serialize};

/// Position in text (line, column)
///
/// Zero-indexed. Immutable value object.
/// Follow LSP (Language Server Protocol) conventions.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct Position {
    /// Line number (0-indexed)
    pub line: u32,

    /// Column/character position (0-indexed, UTF-8 bytes)
    pub column: u32,
}

impl Position {
    /// Create new position with validation
    pub fn new(line: u32, column: u32) -> Self {
        Self { line, column }
    }

    /// Create position from byte offset in text
    pub fn from_byte_offset(text: &str, offset: usize) -> Self {
        let mut line = 0;
        let mut column = 0;

        for (i, ch) in text.char_indices() {
            if i >= offset {
                break;
            }
            if ch == '\n' {
                line += 1;
                column = 0;
            } else {
                column += ch.len_utf8() as u32;
            }
        }

        Self::new(line, column)
    }
}

impl PartialOrd for Position {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for Position {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        match self.line.cmp(&other.line) {
            std::cmp::Ordering::Equal => self.column.cmp(&other.column),
            ordering => ordering,
        }
    }
}

/// Range in text (start, end positions)
///
/// Immutable, self-validating (end >= start).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct Range {
    pub start: Position,
    pub end: Position,
}

impl Range {
    /// Create new range with validation
    pub fn new(start: Position, end: Position) -> Result<Self, String> {
        if end < start {
            return Err("Range end must be >= start".to_string());
        }
        Ok(Self { start, end })
    }

    /// Create range from byte offsets
    pub fn from_byte_offsets(text: &str, start_byte: usize, end_byte: usize) -> Result<Self, String> {
        let start = Position::from_byte_offset(text, start_byte);
        let end = Position::from_byte_offset(text, end_byte);
        Self::new(start, end)
    }

    /// Check if range contains position
    pub fn contains(&self, pos: Position) -> bool {
        pos >= self.start && pos <= self.end
    }

    /// Check if ranges overlap
    pub fn overlaps(&self, other: &Range) -> bool {
        self.start <= other.end && other.start <= self.end
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_position_ordering() {
        let p1 = Position::new(0, 5);
        let p2 = Position::new(0, 10);
        let p3 = Position::new(1, 0);

        assert!(p1 < p2);
        assert!(p2 < p3);
    }

    #[test]
    fn test_range_validation() {
        let start = Position::new(0, 0);
        let end = Position::new(1, 0);

        let range = Range::new(start, end);
        assert!(range.is_ok());

        let invalid = Range::new(end, start);
        assert!(invalid.is_err());
    }

    #[test]
    fn test_range_contains() {
        let range = Range::new(
            Position::new(0, 5),
            Position::new(0, 10),
        ).unwrap();

        assert!(range.contains(Position::new(0, 7)));
        assert!(!range.contains(Position::new(0, 15)));
    }
}
