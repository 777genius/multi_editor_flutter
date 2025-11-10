use ropey::Rope;
use crate::editor::cursor::Position;

/// Comment toggling utilities.
///
/// Provides functionality for:
/// - Toggle line comments (e.g., `//` for Rust)
/// - Toggle block comments (e.g., `/* */` for Rust)
/// - Smart comment/uncomment based on selection
///
/// Example:
/// ```
/// // Before: hello world
/// // After toggle: // hello world
/// // After toggle again: hello world
/// ```
#[derive(Debug, Clone)]
pub struct CommentConfig {
    /// Line comment syntax (e.g., "//" for Rust, "#" for Python)
    pub line_comment: String,

    /// Block comment start (e.g., "/*" for Rust)
    pub block_comment_start: Option<String>,

    /// Block comment end (e.g., "*/" for Rust)
    pub block_comment_end: Option<String>,
}

impl CommentConfig {
    /// Creates config for Rust-style comments.
    pub fn rust() -> Self {
        Self {
            line_comment: "//".to_string(),
            block_comment_start: Some("/*".to_string()),
            block_comment_end: Some("*/".to_string()),
        }
    }

    /// Creates config for Python-style comments.
    pub fn python() -> Self {
        Self {
            line_comment: "#".to_string(),
            block_comment_start: Some("\"\"\"".to_string()),
            block_comment_end: Some("\"\"\"".to_string()),
        }
    }

    /// Creates config for JavaScript-style comments.
    pub fn javascript() -> Self {
        Self {
            line_comment: "//".to_string(),
            block_comment_start: Some("/*".to_string()),
            block_comment_end: Some("*/".to_string(),),
        }
    }

    /// Creates config for custom line comment.
    pub fn line_only(line_comment: &str) -> Self {
        Self {
            line_comment: line_comment.to_string(),
            block_comment_start: None,
            block_comment_end: None,
        }
    }
}

/// Toggles line comments for selected lines.
///
/// If all selected lines are commented, uncomments them.
/// Otherwise, comments all selected lines.
///
/// Parameters:
/// - `rope`: The rope to modify
/// - `start_line`: First line in selection
/// - `end_line`: Last line in selection (inclusive)
/// - `config`: Comment configuration
///
/// Returns: true if lines were commented, false if uncommented
pub fn toggle_line_comments(
    rope: &mut Rope,
    start_line: usize,
    end_line: usize,
    config: &CommentConfig,
) -> bool {
    // Check if all lines are already commented
    let all_commented = are_lines_commented(rope, start_line, end_line, config);

    if all_commented {
        // Uncomment all lines
        uncomment_lines(rope, start_line, end_line, config);
        false
    } else {
        // Comment all lines
        comment_lines(rope, start_line, end_line, config);
        true
    }
}

/// Comments selected lines.
///
/// Adds line comment at the beginning of each line.
///
/// Parameters:
/// - `rope`: The rope to modify
/// - `start_line`: First line
/// - `end_line`: Last line (inclusive)
/// - `config`: Comment configuration
pub fn comment_lines(
    rope: &mut Rope,
    start_line: usize,
    end_line: usize,
    config: &CommentConfig,
) {
    let comment_prefix = format!("{} ", config.line_comment);

    for line_idx in start_line..=end_line.min(rope.len_lines().saturating_sub(1)) {
        let line_start_offset = rope.line_to_char(line_idx);

        // Find first non-whitespace position
        let line = rope.line(line_idx);
        let line_text = line.to_string();
        let first_non_ws = line_text
            .chars()
            .position(|c| !c.is_whitespace())
            .unwrap_or(0);

        // Insert comment after leading whitespace
        let insert_offset = line_start_offset + first_non_ws;
        rope.insert(insert_offset, &comment_prefix);
    }
}

/// Uncomments selected lines.
///
/// Removes line comment from the beginning of each line.
///
/// Parameters:
/// - `rope`: The rope to modify
/// - `start_line`: First line
/// - `end_line`: Last line (inclusive)
/// - `config`: Comment configuration
pub fn uncomment_lines(
    rope: &mut Rope,
    start_line: usize,
    end_line: usize,
    config: &CommentConfig,
) {
    for line_idx in start_line..=end_line.min(rope.len_lines().saturating_sub(1)) {
        let line_start_offset = rope.line_to_char(line_idx);
        let line = rope.line(line_idx);
        let line_text = line.to_string();

        // Find comment marker
        if let Some(comment_pos) = line_text.find(&config.line_comment) {
            let comment_offset = line_start_offset + comment_pos;

            // Remove comment marker
            let mut remove_len = config.line_comment.len();

            // Also remove following space if present
            if line_text[comment_pos..].starts_with(&format!("{} ", config.line_comment)) {
                remove_len += 1;
            }

            rope.remove(comment_offset..(comment_offset + remove_len));
        }
    }
}

/// Checks if lines are commented.
///
/// Returns true if all non-empty lines have line comments.
pub fn are_lines_commented(
    rope: &Rope,
    start_line: usize,
    end_line: usize,
    config: &CommentConfig,
) -> bool {
    for line_idx in start_line..=end_line.min(rope.len_lines().saturating_sub(1)) {
        let line = rope.line(line_idx);
        let line_text = line.to_string();
        let line_trimmed = line_text.trim();

        // Skip empty lines
        if line_trimmed.is_empty() {
            continue;
        }

        // Check if line starts with comment
        if !line_trimmed.starts_with(&config.line_comment) {
            return false;
        }
    }

    true
}

/// Toggles block comment for selection.
///
/// If selection is already surrounded by block comment, removes it.
/// Otherwise, adds block comment around selection.
///
/// Parameters:
/// - `rope`: The rope to modify
/// - `start_pos`: Start position of selection
/// - `end_pos`: End position of selection
/// - `config`: Comment configuration
///
/// Returns: true if block comment was added, false if removed
pub fn toggle_block_comment(
    rope: &mut Rope,
    start_pos: Position,
    end_pos: Position,
    config: &CommentConfig,
) -> bool {
    let Some(_block_start) = &config.block_comment_start else {
        return false; // No block comments for this language
    };

    let Some(_block_end) = &config.block_comment_end else {
        return false;
    };

    let start_offset = position_to_offset(rope, start_pos);
    let end_offset = position_to_offset(rope, end_pos);

    // Check if selection is already surrounded by block comment
    let is_commented = is_block_commented(rope, start_offset, end_offset, config);

    if is_commented {
        // Remove block comment
        remove_block_comment(rope, start_offset, end_offset, config);
        false
    } else {
        // Add block comment
        add_block_comment(rope, start_offset, end_offset, config);
        true
    }
}

/// Adds block comment around text range.
fn add_block_comment(
    rope: &mut Rope,
    start_offset: usize,
    end_offset: usize,
    config: &CommentConfig,
) {
    let block_start = config.block_comment_start.as_ref().unwrap();
    let block_end = config.block_comment_end.as_ref().unwrap();

    // Insert closing comment first (to not affect start offset)
    rope.insert(end_offset, block_end);

    // Insert opening comment
    rope.insert(start_offset, block_start);
}

/// Removes block comment from text range.
fn remove_block_comment(
    rope: &mut Rope,
    start_offset: usize,
    end_offset: usize,
    config: &CommentConfig,
) {
    let block_start = config.block_comment_start.as_ref().unwrap();
    let block_end = config.block_comment_end.as_ref().unwrap();

    // Remove ending comment first
    let end_remove_start = end_offset - block_end.len();
    rope.remove(end_remove_start..end_offset);

    // Remove starting comment
    rope.remove(start_offset..(start_offset + block_start.len()));
}

/// Checks if range is surrounded by block comment.
fn is_block_commented(
    rope: &Rope,
    start_offset: usize,
    end_offset: usize,
    config: &CommentConfig,
) -> bool {
    let Some(block_start) = &config.block_comment_start else {
        return false;
    };

    let Some(block_end) = &config.block_comment_end else {
        return false;
    };

    // Check if text starts with block_start
    let start_text = rope.slice(start_offset..(start_offset + block_start.len().min(rope.len_chars() - start_offset)));
    if start_text.to_string() != *block_start {
        return false;
    }

    // Check if text ends with block_end
    let end_start = end_offset.saturating_sub(block_end.len());
    let end_text = rope.slice(end_start..end_offset);
    end_text.to_string() == *block_end
}

/// Helper: Converts position to offset.
fn position_to_offset(rope: &Rope, position: Position) -> usize {
    let line_offset = rope.line_to_char(position.line.min(rope.len_lines().saturating_sub(1)));
    let line = rope.line(position.line.min(rope.len_lines().saturating_sub(1)));
    line_offset + position.column.min(line.len_chars())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_comment_config_rust() {
        let config = CommentConfig::rust();
        assert_eq!(config.line_comment, "//");
        assert_eq!(config.block_comment_start, Some("/*".to_string()));
        assert_eq!(config.block_comment_end, Some("*/".to_string()));
    }

    #[test]
    fn test_comment_config_python() {
        let config = CommentConfig::python();
        assert_eq!(config.line_comment, "#");
    }

    #[test]
    fn test_comment_lines() {
        let mut rope = Rope::from_str("line1\nline2\nline3");
        let config = CommentConfig::rust();

        comment_lines(&mut rope, 0, 2, &config);
        assert_eq!(rope.to_string(), "// line1\n// line2\n// line3");
    }

    #[test]
    fn test_uncomment_lines() {
        let mut rope = Rope::from_str("// line1\n// line2\n// line3");
        let config = CommentConfig::rust();

        uncomment_lines(&mut rope, 0, 2, &config);
        assert_eq!(rope.to_string(), "line1\nline2\nline3");
    }

    #[test]
    fn test_are_lines_commented_true() {
        let rope = Rope::from_str("// line1\n// line2");
        let config = CommentConfig::rust();

        assert!(are_lines_commented(&rope, 0, 1, &config));
    }

    #[test]
    fn test_are_lines_commented_false() {
        let rope = Rope::from_str("// line1\nline2");
        let config = CommentConfig::rust();

        assert!(!are_lines_commented(&rope, 0, 1, &config));
    }

    #[test]
    fn test_toggle_line_comments_comment() {
        let mut rope = Rope::from_str("line1\nline2");
        let config = CommentConfig::rust();

        let commented = toggle_line_comments(&mut rope, 0, 1, &config);
        assert!(commented);
        assert_eq!(rope.to_string(), "// line1\n// line2");
    }

    #[test]
    fn test_toggle_line_comments_uncomment() {
        let mut rope = Rope::from_str("// line1\n// line2");
        let config = CommentConfig::rust();

        let commented = toggle_line_comments(&mut rope, 0, 1, &config);
        assert!(!commented);
        assert_eq!(rope.to_string(), "line1\nline2");
    }

    #[test]
    fn test_add_block_comment() {
        let mut rope = Rope::from_str("hello world");
        let config = CommentConfig::rust();

        add_block_comment(&mut rope, 0, 11, &config);
        assert_eq!(rope.to_string(), "/*hello world*/");
    }

    #[test]
    fn test_remove_block_comment() {
        let mut rope = Rope::from_str("/*hello world*/");
        let config = CommentConfig::rust();

        remove_block_comment(&mut rope, 0, 15, &config);
        assert_eq!(rope.to_string(), "hello world");
    }

    #[test]
    fn test_is_block_commented_true() {
        let rope = Rope::from_str("/*hello*/");
        let config = CommentConfig::rust();

        assert!(is_block_commented(&rope, 0, 9, &config));
    }

    #[test]
    fn test_is_block_commented_false() {
        let rope = Rope::from_str("hello");
        let config = CommentConfig::rust();

        assert!(!is_block_commented(&rope, 0, 5, &config));
    }

    #[test]
    fn test_toggle_block_comment_add() {
        let mut rope = Rope::from_str("hello");
        let config = CommentConfig::rust();

        let added = toggle_block_comment(
            &mut rope,
            Position::new(0, 0),
            Position::new(0, 5),
            &config,
        );
        assert!(added);
        assert_eq!(rope.to_string(), "/*hello*/");
    }

    #[test]
    fn test_toggle_block_comment_remove() {
        let mut rope = Rope::from_str("/*hello*/");
        let config = CommentConfig::rust();

        let added = toggle_block_comment(
            &mut rope,
            Position::new(0, 0),
            Position::new(0, 9),
            &config,
        );
        assert!(!added);
        assert_eq!(rope.to_string(), "hello");
    }
}
