use ropey::Rope;

/// Cursor position in the editor (0-indexed).
///
/// Represents a position in the editor as (line, column).
/// Both line and column are 0-indexed.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct Position {
    pub line: usize,
    pub column: usize,
}

impl Position {
    /// Creates a new position.
    pub fn new(line: usize, column: usize) -> Self {
        Self { line, column }
    }

    /// Creates position at start of document.
    pub fn start() -> Self {
        Self { line: 0, column: 0 }
    }

    /// Converts position to byte offset in rope.
    pub fn to_byte_offset(&self, rope: &Rope) -> usize {
        let line_offset = rope.line_to_byte(self.line);
        let line = rope.line(self.line);
        let char_offset = line.char_to_byte(self.column.min(line.len_chars()));
        line_offset + char_offset
    }

    /// Creates position from byte offset.
    pub fn from_byte_offset(rope: &Rope, byte_offset: usize) -> Self {
        let line = rope.byte_to_line(byte_offset);
        let line_start = rope.line_to_byte(line);
        let column_bytes = byte_offset - line_start;
        let line_slice = rope.line(line);
        let column = line_slice.byte_to_char(column_bytes.min(line_slice.len_bytes()));

        Self { line, column }
    }

    /// Converts position to character offset in rope.
    pub fn to_char_offset(&self, rope: &Rope) -> usize {
        let line_offset = rope.line_to_char(self.line.min(rope.len_lines().saturating_sub(1)));
        let line = rope.line(self.line.min(rope.len_lines().saturating_sub(1)));
        line_offset + self.column.min(line.len_chars())
    }

    /// Creates position from character offset.
    pub fn from_char_offset(rope: &Rope, char_offset: usize) -> Self {
        let line = rope.char_to_line(char_offset.min(rope.len_chars()));
        let line_start = rope.line_to_char(line);
        let column = char_offset.saturating_sub(line_start);

        Self { line, column }
    }

    /// Clamps position to valid range in rope.
    pub fn clamp(&self, rope: &Rope) -> Self {
        let line = self.line.min(rope.len_lines().saturating_sub(1));
        let line_len = rope.line(line).len_chars();
        let column = self.column.min(line_len);

        Self { line, column }
    }
}

/// Text selection range.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Selection {
    pub start: Position,
    pub end: Position,
}

impl Selection {
    /// Creates a new selection.
    pub fn new(start: Position, end: Position) -> Self {
        Self { start, end }
    }

    /// Checks if selection is empty (start == end).
    pub fn is_empty(&self) -> bool {
        self.start == self.end
    }

    /// Normalizes selection (start <= end).
    pub fn normalize(&self) -> Self {
        if self.start.line < self.end.line
            || (self.start.line == self.end.line && self.start.column <= self.end.column)
        {
            *self
        } else {
            Self {
                start: self.end,
                end: self.start,
            }
        }
    }

    /// Gets length of selection in characters.
    pub fn len(&self, rope: &Rope) -> usize {
        let normalized = self.normalize();
        let start_offset = normalized.start.to_char_offset(rope);
        let end_offset = normalized.end.to_char_offset(rope);
        end_offset.saturating_sub(start_offset)
    }

    /// Checks if position is inside selection.
    pub fn contains(&self, position: Position) -> bool {
        let normalized = self.normalize();

        if position.line < normalized.start.line || position.line > normalized.end.line {
            return false;
        }

        if position.line == normalized.start.line && position.column < normalized.start.column {
            return false;
        }

        if position.line == normalized.end.line && position.column > normalized.end.column {
            return false;
        }

        true
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_position_new() {
        let pos = Position::new(5, 10);
        assert_eq!(pos.line, 5);
        assert_eq!(pos.column, 10);
    }

    #[test]
    fn test_position_start() {
        let pos = Position::start();
        assert_eq!(pos.line, 0);
        assert_eq!(pos.column, 0);
    }

    #[test]
    fn test_position_to_char_offset() {
        let rope = Rope::from_str("Line 1\nLine 2\nLine 3");

        assert_eq!(Position::new(0, 0).to_char_offset(&rope), 0);
        assert_eq!(Position::new(0, 6).to_char_offset(&rope), 6);
        assert_eq!(Position::new(1, 0).to_char_offset(&rope), 7);
        assert_eq!(Position::new(1, 6).to_char_offset(&rope), 13);
    }

    #[test]
    fn test_position_from_char_offset() {
        let rope = Rope::from_str("Line 1\nLine 2\nLine 3");

        assert_eq!(Position::from_char_offset(&rope, 0), Position::new(0, 0));
        assert_eq!(Position::from_char_offset(&rope, 7), Position::new(1, 0));
        assert_eq!(Position::from_char_offset(&rope, 14), Position::new(2, 0));
    }

    #[test]
    fn test_position_clamp() {
        let rope = Rope::from_str("Short\nMedium line\nX");

        let pos = Position::new(0, 100).clamp(&rope);
        assert!(pos.column <= 5);

        let pos = Position::new(100, 0).clamp(&rope);
        assert!(pos.line <= 2);
    }

    #[test]
    fn test_selection_new() {
        let sel = Selection::new(Position::new(0, 0), Position::new(0, 5));
        assert_eq!(sel.start, Position::new(0, 0));
        assert_eq!(sel.end, Position::new(0, 5));
    }

    #[test]
    fn test_selection_is_empty() {
        let empty = Selection::new(Position::new(1, 5), Position::new(1, 5));
        assert!(empty.is_empty());

        let non_empty = Selection::new(Position::new(0, 0), Position::new(0, 5));
        assert!(!non_empty.is_empty());
    }

    #[test]
    fn test_selection_normalize() {
        let sel = Selection::new(Position::new(0, 5), Position::new(0, 0));
        let normalized = sel.normalize();
        assert_eq!(normalized.start, Position::new(0, 0));
        assert_eq!(normalized.end, Position::new(0, 5));
    }

    #[test]
    fn test_selection_contains() {
        let sel = Selection::new(Position::new(0, 0), Position::new(2, 5));

        assert!(sel.contains(Position::new(0, 0)));
        assert!(sel.contains(Position::new(1, 3)));
        assert!(sel.contains(Position::new(2, 5)));
        assert!(!sel.contains(Position::new(3, 0)));
    }
}
