use ropey::Rope;
use crate::editor::cursor::Position;

/// Clipboard operations for the editor.
///
/// Provides cut, copy, paste functionality with support for:
/// - Line-based operations
/// - Column-based operations (rectangular selection)
/// - Multiple cursors
///
/// The clipboard is stored in memory and can be synchronized
/// with the system clipboard via FFI.
#[derive(Debug, Clone)]
pub struct Clipboard {
    /// Clipboard content
    content: String,

    /// Clipboard mode (character, line, or block)
    mode: ClipboardMode,
}

/// Clipboard operation mode.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ClipboardMode {
    /// Character-wise (normal selection)
    Character,

    /// Line-wise (whole lines)
    Line,

    /// Block-wise (rectangular selection)
    Block,
}

impl Default for Clipboard {
    fn default() -> Self {
        Self::new()
    }
}

impl Clipboard {
    /// Creates a new empty clipboard.
    pub fn new() -> Self {
        Self {
            content: String::new(),
            mode: ClipboardMode::Character,
        }
    }

    /// Sets clipboard content.
    pub fn set(&mut self, content: String, mode: ClipboardMode) {
        self.content = content;
        self.mode = mode;
    }

    /// Gets clipboard content.
    pub fn get(&self) -> &str {
        &self.content
    }

    /// Gets clipboard mode.
    pub fn mode(&self) -> ClipboardMode {
        self.mode
    }

    /// Clears clipboard.
    pub fn clear(&mut self) {
        self.content.clear();
        self.mode = ClipboardMode::Character;
    }

    /// Checks if clipboard is empty.
    pub fn is_empty(&self) -> bool {
        self.content.is_empty()
    }

    /// Gets line count in clipboard.
    pub fn line_count(&self) -> usize {
        if self.content.is_empty() {
            0
        } else {
            self.content.lines().count()
        }
    }
}

/// Copies text from rope to clipboard.
///
/// Parameters:
/// - `rope`: The rope to copy from
/// - `start`: Start position
/// - `end`: End position
/// - `mode`: Clipboard mode
///
/// Returns: Clipboard with copied content
pub fn copy_text(
    rope: &Rope,
    start: Position,
    end: Position,
    mode: ClipboardMode,
) -> Clipboard {
    let start_offset = position_to_offset(rope, start);
    let end_offset = position_to_offset(rope, end);

    let content = rope.slice(start_offset..end_offset).to_string();

    Clipboard {
        content,
        mode,
    }
}

/// Cuts text from rope to clipboard.
///
/// Parameters:
/// - `rope`: The rope to cut from
/// - `start`: Start position
/// - `end`: End position
/// - `mode`: Clipboard mode
///
/// Returns: (Clipboard with cut content, modified rope)
pub fn cut_text(
    rope: &mut Rope,
    start: Position,
    end: Position,
    mode: ClipboardMode,
) -> Clipboard {
    let clipboard = copy_text(rope, start, end, mode);

    let start_offset = position_to_offset(rope, start);
    let end_offset = position_to_offset(rope, end);

    rope.remove(start_offset..end_offset);

    clipboard
}

/// Pastes clipboard content into rope.
///
/// Parameters:
/// - `rope`: The rope to paste into
/// - `position`: Position to paste at
/// - `clipboard`: Clipboard to paste from
///
/// Returns: New cursor position after paste
pub fn paste_text(
    rope: &mut Rope,
    position: Position,
    clipboard: &Clipboard,
) -> Position {
    let offset = position_to_offset(rope, position);

    match clipboard.mode {
        ClipboardMode::Character => {
            // Insert at cursor position
            rope.insert(offset, &clipboard.content);

            // Calculate new position
            let lines_added = clipboard.content.lines().count().saturating_sub(1);
            let last_line = clipboard.content.lines().last().unwrap_or("");

            Position::new(
                position.line + lines_added,
                if lines_added > 0 {
                    last_line.len()
                } else {
                    position.column + last_line.len()
                },
            )
        }
        ClipboardMode::Line => {
            // Insert at beginning of line
            let line_start = rope.line_to_char(position.line);
            rope.insert(line_start, &clipboard.content);

            if !clipboard.content.ends_with('\n') {
                rope.insert(line_start + clipboard.content.len(), "\n");
            }

            Position::new(
                position.line + clipboard.line_count(),
                0,
            )
        }
        ClipboardMode::Block => {
            // Insert each line at the same column
            let mut current_line = position.line;
            for line_content in clipboard.content.lines() {
                if current_line < rope.len_lines() {
                    let line_start = rope.line_to_char(current_line);
                    let line = rope.line(current_line);
                    let insert_offset = line_start + position.column.min(line.len_chars());

                    rope.insert(insert_offset, line_content);
                } else {
                    // Add new line if needed
                    rope.insert(rope.len_chars(), "\n");
                    rope.insert(rope.len_chars(), line_content);
                }
                current_line += 1;
            }

            Position::new(
                position.line + clipboard.line_count() - 1,
                position.column + clipboard.content.lines().last().unwrap_or("").len(),
            )
        }
    }
}

/// Copies entire line(s) to clipboard.
///
/// Parameters:
/// - `rope`: The rope to copy from
/// - `start_line`: Start line (inclusive)
/// - `end_line`: End line (inclusive)
///
/// Returns: Clipboard with copied lines
pub fn copy_lines(
    rope: &Rope,
    start_line: usize,
    end_line: usize,
) -> Clipboard {
    let start_offset = rope.line_to_char(start_line);
    let end_offset = if end_line + 1 < rope.len_lines() {
        rope.line_to_char(end_line + 1)
    } else {
        rope.len_chars()
    };

    let content = rope.slice(start_offset..end_offset).to_string();

    Clipboard {
        content,
        mode: ClipboardMode::Line,
    }
}

/// Cuts entire line(s) to clipboard.
///
/// Parameters:
/// - `rope`: The rope to cut from
/// - `start_line`: Start line (inclusive)
/// - `end_line`: End line (inclusive)
///
/// Returns: Clipboard with cut lines
pub fn cut_lines(
    rope: &mut Rope,
    start_line: usize,
    end_line: usize,
) -> Clipboard {
    let clipboard = copy_lines(rope, start_line, end_line);

    let start_offset = rope.line_to_char(start_line);
    let end_offset = if end_line + 1 < rope.len_lines() {
        rope.line_to_char(end_line + 1)
    } else {
        rope.len_chars()
    };

    rope.remove(start_offset..end_offset);

    clipboard
}

/// Converts position to character offset in rope.
fn position_to_offset(rope: &Rope, position: Position) -> usize {
    let line_start = rope.line_to_char(position.line.min(rope.len_lines().saturating_sub(1)));
    let line = rope.line(position.line.min(rope.len_lines().saturating_sub(1)));
    line_start + position.column.min(line.len_chars())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_clipboard_basic() {
        let mut clipboard = Clipboard::new();

        assert!(clipboard.is_empty());
        assert_eq!(clipboard.line_count(), 0);

        clipboard.set("Hello".to_string(), ClipboardMode::Character);

        assert!(!clipboard.is_empty());
        assert_eq!(clipboard.get(), "Hello");
        assert_eq!(clipboard.mode(), ClipboardMode::Character);

        clipboard.clear();
        assert!(clipboard.is_empty());
    }

    #[test]
    fn test_copy_text() {
        let rope = Rope::from_str("Hello World\nSecond Line");

        let clipboard = copy_text(
            &rope,
            Position::new(0, 0),
            Position::new(0, 5),
            ClipboardMode::Character,
        );

        assert_eq!(clipboard.get(), "Hello");
        assert_eq!(clipboard.mode(), ClipboardMode::Character);
    }

    #[test]
    fn test_cut_text() {
        let mut rope = Rope::from_str("Hello World\nSecond Line");

        let clipboard = cut_text(
            &mut rope,
            Position::new(0, 0),
            Position::new(0, 6),
            ClipboardMode::Character,
        );

        assert_eq!(clipboard.get(), "Hello ");
        assert_eq!(rope.to_string(), "World\nSecond Line");
    }

    #[test]
    fn test_paste_character() {
        let mut rope = Rope::from_str("Hello World");
        let mut clipboard = Clipboard::new();
        clipboard.set("INSERTED".to_string(), ClipboardMode::Character);

        let new_pos = paste_text(&mut rope, Position::new(0, 6), &clipboard);

        assert_eq!(rope.to_string(), "Hello INSERTEDWorld");
        assert_eq!(new_pos, Position::new(0, 14));
    }

    #[test]
    fn test_paste_line() {
        let mut rope = Rope::from_str("Line 1\nLine 2\nLine 3");
        let mut clipboard = Clipboard::new();
        clipboard.set("Inserted Line\n".to_string(), ClipboardMode::Line);

        let new_pos = paste_text(&mut rope, Position::new(1, 0), &clipboard);

        assert!(rope.to_string().contains("Inserted Line"));
        assert_eq!(new_pos.line, 2);
    }

    #[test]
    fn test_copy_lines() {
        let rope = Rope::from_str("Line 1\nLine 2\nLine 3");

        let clipboard = copy_lines(&rope, 0, 1);

        assert_eq!(clipboard.get(), "Line 1\nLine 2\n");
        assert_eq!(clipboard.mode(), ClipboardMode::Line);
    }

    #[test]
    fn test_cut_lines() {
        let mut rope = Rope::from_str("Line 1\nLine 2\nLine 3");

        let clipboard = cut_lines(&mut rope, 1, 1);

        assert_eq!(clipboard.get(), "Line 2\n");
        assert_eq!(rope.to_string(), "Line 1\nLine 3");
    }

    #[test]
    fn test_clipboard_line_count() {
        let mut clipboard = Clipboard::new();
        clipboard.set("Line 1\nLine 2\nLine 3".to_string(), ClipboardMode::Line);

        assert_eq!(clipboard.line_count(), 3);
    }
}
