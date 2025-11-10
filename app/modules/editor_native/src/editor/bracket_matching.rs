use ropey::Rope;
use crate::editor::cursor::Position;

/// Bracket matching and navigation.
///
/// Provides utilities for:
/// - Finding matching brackets
/// - Jumping to matching bracket
/// - Checking if brackets are balanced
/// - Auto-closing brackets
///
/// Supported bracket pairs:
/// - `()` - Parentheses
/// - `[]` - Square brackets
/// - `{}` - Curly braces
/// - `<>` - Angle brackets (for generics)
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BracketType {
    Round,   // ()
    Square,  // []
    Curly,   // {}
    Angle,   // <>
}

impl BracketType {
    /// Gets opening and closing characters for bracket type.
    pub fn chars(&self) -> (char, char) {
        match self {
            BracketType::Round => ('(', ')'),
            BracketType::Square => ('[', ']'),
            BracketType::Curly => ('{', '}'),
            BracketType::Angle => ('<', '>'),
        }
    }

    /// Checks if character is an opening bracket.
    pub fn is_opening(ch: char) -> bool {
        matches!(ch, '(' | '[' | '{' | '<')
    }

    /// Checks if character is a closing bracket.
    pub fn is_closing(ch: char) -> bool {
        matches!(ch, ')' | ']' | '}' | '>')
    }

    /// Gets bracket type from character.
    pub fn from_char(ch: char) -> Option<Self> {
        match ch {
            '(' | ')' => Some(BracketType::Round),
            '[' | ']' => Some(BracketType::Square),
            '{' | '}' => Some(BracketType::Curly),
            '<' | '>' => Some(BracketType::Angle),
            _ => None,
        }
    }

    /// Gets matching bracket character.
    pub fn matching_bracket(ch: char) -> Option<char> {
        match ch {
            '(' => Some(')'),
            ')' => Some('('),
            '[' => Some(']'),
            ']' => Some('['),
            '{' => Some('}'),
            '}' => Some('{'),
            '<' => Some('>'),
            '>' => Some('<'),
            _ => None,
        }
    }
}

/// Result of bracket matching.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BracketMatch {
    /// Position of opening bracket
    pub opening: Position,

    /// Position of closing bracket
    pub closing: Position,

    /// Type of bracket
    pub bracket_type: BracketType,
}

/// Finds matching bracket for bracket at position.
///
/// Parameters:
/// - `rope`: The rope to search in
/// - `position`: Position of bracket
///
/// Returns: Position of matching bracket, or None if not found
pub fn find_matching_bracket(
    rope: &Rope,
    position: Position,
) -> Option<Position> {
    let char_offset = position_to_offset(rope, position);
    if char_offset >= rope.len_chars() {
        return None;
    }

    let ch = rope.char(char_offset);
    let bracket_type = BracketType::from_char(ch)?;
    let (open_char, close_char) = bracket_type.chars();

    if BracketType::is_opening(ch) {
        // Search forward for closing bracket
        find_closing_bracket(rope, char_offset, open_char, close_char)
    } else if BracketType::is_closing(ch) {
        // Search backward for opening bracket
        find_opening_bracket(rope, char_offset, open_char, close_char)
    } else {
        None
    }
}

/// Finds closing bracket starting from position.
fn find_closing_bracket(
    rope: &Rope,
    start_offset: usize,
    open_char: char,
    close_char: char,
) -> Option<Position> {
    let mut depth = 1;
    let mut current_offset = start_offset + 1;

    while current_offset < rope.len_chars() {
        let ch = rope.char(current_offset);

        if ch == open_char {
            depth += 1;
        } else if ch == close_char {
            depth -= 1;
            if depth == 0 {
                return Some(offset_to_position(rope, current_offset));
            }
        }

        current_offset += 1;
    }

    None
}

/// Finds opening bracket starting from position.
fn find_opening_bracket(
    rope: &Rope,
    start_offset: usize,
    open_char: char,
    close_char: char,
) -> Option<Position> {
    let mut depth = 1;
    let mut current_offset = start_offset;

    while current_offset > 0 {
        current_offset -= 1;
        let ch = rope.char(current_offset);

        if ch == close_char {
            depth += 1;
        } else if ch == open_char {
            depth -= 1;
            if depth == 0 {
                return Some(offset_to_position(rope, current_offset));
            }
        }
    }

    None
}

/// Finds all bracket pairs in rope.
///
/// Useful for bracket highlighting and error detection.
///
/// Parameters:
/// - `rope`: The rope to search
///
/// Returns: Vector of bracket matches
pub fn find_all_bracket_pairs(rope: &Rope) -> Vec<BracketMatch> {
    let mut matches = Vec::new();
    let mut stack: Vec<(char, usize)> = Vec::new();

    for char_idx in 0..rope.len_chars() {
        let ch = rope.char(char_idx);

        if BracketType::is_opening(ch) {
            stack.push((ch, char_idx));
        } else if BracketType::is_closing(ch) {
            if let Some((open_ch, open_idx)) = stack.pop() {
                if let Some(matching_close) = BracketType::matching_bracket(open_ch) {
                    if matching_close == ch {
                        if let Some(bracket_type) = BracketType::from_char(open_ch) {
                            matches.push(BracketMatch {
                                opening: offset_to_position(rope, open_idx),
                                closing: offset_to_position(rope, char_idx),
                                bracket_type,
                            });
                        }
                    }
                }
            }
        }
    }

    matches
}

/// Checks if brackets are balanced in rope.
///
/// Returns true if all brackets have matching pairs.
pub fn are_brackets_balanced(rope: &Rope) -> bool {
    let mut stack = Vec::new();

    for char_idx in 0..rope.len_chars() {
        let ch = rope.char(char_idx);

        if BracketType::is_opening(ch) {
            stack.push(ch);
        } else if BracketType::is_closing(ch) {
            if let Some(open_ch) = stack.pop() {
                if let Some(expected_close) = BracketType::matching_bracket(open_ch) {
                    if expected_close != ch {
                        return false; // Mismatched brackets
                    }
                }
            } else {
                return false; // Closing bracket without opening
            }
        }
    }

    stack.is_empty() // True if all brackets are matched
}

/// Gets the bracket character to auto-insert when typing opening bracket.
///
/// Parameters:
/// - `opening_bracket`: The opening bracket that was typed
///
/// Returns: Closing bracket to insert, or None
pub fn get_auto_close_bracket(opening_bracket: char) -> Option<char> {
    BracketType::matching_bracket(opening_bracket)
}

/// Helper: Converts position to character offset.
fn position_to_offset(rope: &Rope, position: Position) -> usize {
    let line_offset = rope.line_to_char(position.line.min(rope.len_lines().saturating_sub(1)));
    let line = rope.line(position.line.min(rope.len_lines().saturating_sub(1)));
    line_offset + position.column.min(line.len_chars())
}

/// Helper: Converts character offset to position.
fn offset_to_position(rope: &Rope, offset: usize) -> Position {
    let line = rope.char_to_line(offset.min(rope.len_chars()));
    let line_start = rope.line_to_char(line);
    let column = offset.saturating_sub(line_start);

    Position::new(line, column)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_bracket_type_chars() {
        assert_eq!(BracketType::Round.chars(), ('(', ')'));
        assert_eq!(BracketType::Square.chars(), ('[', ']'));
        assert_eq!(BracketType::Curly.chars(), ('{', '}'));
        assert_eq!(BracketType::Angle.chars(), ('<', '>'));
    }

    #[test]
    fn test_is_opening() {
        assert!(BracketType::is_opening('('));
        assert!(BracketType::is_opening('['));
        assert!(BracketType::is_opening('{'));
        assert!(BracketType::is_opening('<'));
        assert!(!BracketType::is_opening(')'));
        assert!(!BracketType::is_opening('a'));
    }

    #[test]
    fn test_is_closing() {
        assert!(BracketType::is_closing(')'));
        assert!(BracketType::is_closing(']'));
        assert!(BracketType::is_closing('}'));
        assert!(BracketType::is_closing('>'));
        assert!(!BracketType::is_closing('('));
        assert!(!BracketType::is_closing('a'));
    }

    #[test]
    fn test_from_char() {
        assert_eq!(BracketType::from_char('('), Some(BracketType::Round));
        assert_eq!(BracketType::from_char(')'), Some(BracketType::Round));
        assert_eq!(BracketType::from_char('['), Some(BracketType::Square));
        assert_eq!(BracketType::from_char('a'), None);
    }

    #[test]
    fn test_matching_bracket() {
        assert_eq!(BracketType::matching_bracket('('), Some(')'));
        assert_eq!(BracketType::matching_bracket(')'), Some('('));
        assert_eq!(BracketType::matching_bracket('['), Some(']'));
        assert_eq!(BracketType::matching_bracket('a'), None);
    }

    #[test]
    fn test_find_matching_bracket_simple() {
        let rope = Rope::from_str("(hello)");

        let result = find_matching_bracket(&rope, Position::new(0, 0));
        assert_eq!(result, Some(Position::new(0, 6)));

        let result = find_matching_bracket(&rope, Position::new(0, 6));
        assert_eq!(result, Some(Position::new(0, 0)));
    }

    #[test]
    fn test_find_matching_bracket_nested() {
        let rope = Rope::from_str("(a(b)c)");

        let result = find_matching_bracket(&rope, Position::new(0, 0));
        assert_eq!(result, Some(Position::new(0, 6)));

        let result = find_matching_bracket(&rope, Position::new(0, 2));
        assert_eq!(result, Some(Position::new(0, 4)));
    }

    #[test]
    fn test_find_matching_bracket_no_match() {
        let rope = Rope::from_str("(hello");

        let result = find_matching_bracket(&rope, Position::new(0, 0));
        assert_eq!(result, None);
    }

    #[test]
    fn test_find_all_bracket_pairs() {
        let rope = Rope::from_str("(a[b]c)");

        let pairs = find_all_bracket_pairs(&rope);
        assert_eq!(pairs.len(), 2);

        assert_eq!(pairs[0].opening, Position::new(0, 2));
        assert_eq!(pairs[0].closing, Position::new(0, 4));
        assert_eq!(pairs[0].bracket_type, BracketType::Square);

        assert_eq!(pairs[1].opening, Position::new(0, 0));
        assert_eq!(pairs[1].closing, Position::new(0, 6));
        assert_eq!(pairs[1].bracket_type, BracketType::Round);
    }

    #[test]
    fn test_are_brackets_balanced_true() {
        assert!(are_brackets_balanced(&Rope::from_str("()")));
        assert!(are_brackets_balanced(&Rope::from_str("(a[b]c)")));
        assert!(are_brackets_balanced(&Rope::from_str("{[(a)]}")));
    }

    #[test]
    fn test_are_brackets_balanced_false() {
        assert!(!are_brackets_balanced(&Rope::from_str("(")));
        assert!(!are_brackets_balanced(&Rope::from_str("(]")));
        assert!(!are_brackets_balanced(&Rope::from_str("(()")));
    }

    #[test]
    fn test_auto_close_bracket() {
        assert_eq!(get_auto_close_bracket('('), Some(')'));
        assert_eq!(get_auto_close_bracket('['), Some(']'));
        assert_eq!(get_auto_close_bracket('{'), Some('}'));
        assert_eq!(get_auto_close_bracket('a'), None);
    }
}
