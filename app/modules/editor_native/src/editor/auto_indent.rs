use ropey::Rope;
use crate::editor::cursor::Position;

/// Auto-indentation utilities.
///
/// Provides smart indentation based on:
/// - Previous line indentation
/// - Bracket context (indent after `{`, dedent after `}`)
/// - Language-specific rules
///
/// Example:
/// ```
/// fn main() {
///     println!("hello");  // Auto-indented to 4 spaces
/// }  // Auto-dedented
/// ```
#[derive(Debug, Clone)]
pub struct IndentConfig {
    /// Use spaces for indentation
    pub use_spaces: bool,

    /// Number of spaces per indent level (if use_spaces = true)
    pub tab_size: usize,

    /// Auto-indent on newline
    pub auto_indent: bool,

    /// Auto-dedent closing brackets
    pub auto_dedent_brackets: bool,
}

impl Default for IndentConfig {
    fn default() -> Self {
        Self {
            use_spaces: true,
            tab_size: 4,
            auto_indent: true,
            auto_dedent_brackets: true,
        }
    }
}

impl IndentConfig {
    /// Creates config for spaces indentation.
    pub fn spaces(tab_size: usize) -> Self {
        Self {
            use_spaces: true,
            tab_size,
            auto_indent: true,
            auto_dedent_brackets: true,
        }
    }

    /// Creates config for tabs indentation.
    pub fn tabs() -> Self {
        Self {
            use_spaces: false,
            tab_size: 4, // For display purposes
            auto_indent: true,
            auto_dedent_brackets: true,
        }
    }

    /// Gets indent string for one level.
    pub fn indent_string(&self) -> String {
        if self.use_spaces {
            " ".repeat(self.tab_size)
        } else {
            "\t".to_string()
        }
    }
}

/// Calculates indentation for a new line.
///
/// Parameters:
/// - `rope`: The rope
/// - `position`: Current cursor position
/// - `config`: Indentation configuration
///
/// Returns: Indentation string to insert
pub fn calculate_indent_for_newline(
    rope: &Rope,
    position: Position,
    config: &IndentConfig,
) -> String {
    if !config.auto_indent {
        return String::new();
    }

    // Get current line
    let line = get_line_text(rope, position.line);

    // Get indentation of current line
    let current_indent = get_indent_level(&line, config);

    // Check if current line ends with opening bracket
    let line_trimmed = line.trim_end();
    let should_increase_indent = line_trimmed.ends_with('{')
        || line_trimmed.ends_with('[')
        || line_trimmed.ends_with('(');

    // Calculate new indent level
    let new_indent_level = if should_increase_indent {
        current_indent + 1
    } else {
        current_indent
    };

    // Generate indent string
    config.indent_string().repeat(new_indent_level)
}

/// Calculates indentation when typing closing bracket.
///
/// Parameters:
/// - `rope`: The rope
/// - `position`: Position where bracket is being typed
/// - `bracket`: The closing bracket character
/// - `config`: Indentation configuration
///
/// Returns: Indentation adjustment (negative = dedent)
pub fn calculate_bracket_dedent(
    rope: &Rope,
    position: Position,
    bracket: char,
    config: &IndentConfig,
) -> isize {
    if !config.auto_dedent_brackets {
        return 0;
    }

    if !matches!(bracket, '}' | ']' | ')') {
        return 0;
    }

    // Get current line
    let line = get_line_text(rope, position.line);

    // Check if line only has whitespace before cursor
    let before_cursor = &line[..position.column.min(line.len())];
    if !before_cursor.trim().is_empty() {
        return 0; // Don't dedent if there's code before bracket
    }

    // Dedent by one level
    -1
}

/// Gets indentation level of a line.
///
/// Parameters:
/// - `line`: Line text
/// - `config`: Indentation configuration
///
/// Returns: Indentation level (number of indent units)
pub fn get_indent_level(line: &str, config: &IndentConfig) -> usize {
    let indent_str = get_line_indent(line);

    if config.use_spaces {
        indent_str.len() / config.tab_size
    } else {
        indent_str.chars().filter(|&c| c == '\t').count()
    }
}

/// Gets indentation string of a line.
///
/// Returns the leading whitespace.
pub fn get_line_indent(line: &str) -> String {
    line.chars()
        .take_while(|c| c.is_whitespace())
        .collect()
}

/// Indents selected lines.
///
/// Parameters:
/// - `rope`: The rope to modify
/// - `start_line`: First line to indent
/// - `end_line`: Last line to indent (inclusive)
/// - `config`: Indentation configuration
///
/// Returns: Number of lines indented
pub fn indent_lines(
    rope: &mut Rope,
    start_line: usize,
    end_line: usize,
    config: &IndentConfig,
) -> usize {
    let indent_str = config.indent_string();
    let mut lines_indented = 0;

    for line_idx in start_line..=end_line.min(rope.len_lines().saturating_sub(1)) {
        let line_start_offset = rope.line_to_char(line_idx);

        // Insert indent at line start
        rope.insert(line_start_offset, &indent_str);
        lines_indented += 1;
    }

    lines_indented
}

/// Dedents selected lines.
///
/// Parameters:
/// - `rope`: The rope to modify
/// - `start_line`: First line to dedent
/// - `end_line`: Last line to dedent (inclusive)
/// - `config`: Indentation configuration
///
/// Returns: Number of lines dedented
pub fn dedent_lines(
    rope: &mut Rope,
    start_line: usize,
    end_line: usize,
    config: &IndentConfig,
) -> usize {
    let indent_str = config.indent_string();
    let mut lines_dedented = 0;

    for line_idx in start_line..=end_line.min(rope.len_lines().saturating_sub(1)) {
        let line_start_offset = rope.line_to_char(line_idx);
        let line = rope.line(line_idx);
        let line_text = line.to_string();

        // Check if line starts with indent
        if line_text.starts_with(&indent_str) {
            let end_offset = line_start_offset + indent_str.len();
            rope.remove(line_start_offset..end_offset);
            lines_dedented += 1;
        }
    }

    lines_dedented
}

/// Normalizes indentation of entire document.
///
/// Converts all indentation to match config (spaces or tabs).
///
/// Parameters:
/// - `rope`: The rope to modify
/// - `config`: Indentation configuration
pub fn normalize_indentation(rope: &mut Rope, config: &IndentConfig) {
    let line_count = rope.len_lines();

    for line_idx in 0..line_count {
        let line_start_offset = rope.line_to_char(line_idx);
        let line = rope.line(line_idx);
        let line_text = line.to_string();

        // Get current indent
        let current_indent = get_line_indent(&line_text);
        if current_indent.is_empty() {
            continue;
        }

        // Calculate indent level
        let level = if config.use_spaces {
            // Count spaces (assume 4 spaces = 1 tab)
            current_indent.chars().filter(|&c| c == ' ').count() / 4
                + current_indent.chars().filter(|&c| c == '\t').count()
        } else {
            // Count tabs and spaces
            current_indent.chars().filter(|&c| c == '\t').count()
                + (current_indent.chars().filter(|&c| c == ' ').count() / 4)
        };

        // Generate new indent
        let new_indent = config.indent_string().repeat(level);

        // Replace old indent with new indent
        if new_indent != current_indent {
            let end_offset = line_start_offset + current_indent.len();
            rope.remove(line_start_offset..end_offset);
            rope.insert(line_start_offset, &new_indent);
        }
    }
}

/// Helper: Gets line text.
fn get_line_text(rope: &Rope, line: usize) -> String {
    if line < rope.len_lines() {
        rope.line(line).to_string()
    } else {
        String::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_indent_config_default() {
        let config = IndentConfig::default();
        assert!(config.use_spaces);
        assert_eq!(config.tab_size, 4);
        assert_eq!(config.indent_string(), "    ");
    }

    #[test]
    fn test_indent_config_spaces() {
        let config = IndentConfig::spaces(2);
        assert_eq!(config.indent_string(), "  ");
    }

    #[test]
    fn test_indent_config_tabs() {
        let config = IndentConfig::tabs();
        assert!(!config.use_spaces);
        assert_eq!(config.indent_string(), "\t");
    }

    #[test]
    fn test_get_line_indent() {
        assert_eq!(get_line_indent("    hello"), "    ");
        assert_eq!(get_line_indent("\t\thello"), "\t\t");
        assert_eq!(get_line_indent("hello"), "");
    }

    #[test]
    fn test_get_indent_level_spaces() {
        let config = IndentConfig::spaces(4);
        assert_eq!(get_indent_level("hello", &config), 0);
        assert_eq!(get_indent_level("    hello", &config), 1);
        assert_eq!(get_indent_level("        hello", &config), 2);
    }

    #[test]
    fn test_get_indent_level_tabs() {
        let config = IndentConfig::tabs();
        assert_eq!(get_indent_level("\thello", &config), 1);
        assert_eq!(get_indent_level("\t\thello", &config), 2);
    }

    #[test]
    fn test_calculate_indent_for_newline_simple() {
        let rope = Rope::from_str("    hello");
        let config = IndentConfig::spaces(4);

        let indent = calculate_indent_for_newline(&rope, Position::new(0, 9), &config);
        assert_eq!(indent, "    ");
    }

    #[test]
    fn test_calculate_indent_for_newline_with_opening_bracket() {
        let rope = Rope::from_str("    fn main() {");
        let config = IndentConfig::spaces(4);

        let indent = calculate_indent_for_newline(&rope, Position::new(0, 15), &config);
        assert_eq!(indent, "        "); // Increased indent
    }

    #[test]
    fn test_calculate_bracket_dedent() {
        let rope = Rope::from_str("        ");
        let config = IndentConfig::spaces(4);

        let dedent = calculate_bracket_dedent(&rope, Position::new(0, 8), '}', &config);
        assert_eq!(dedent, -1);
    }

    #[test]
    fn test_indent_lines() {
        let mut rope = Rope::from_str("line1\nline2\nline3");
        let config = IndentConfig::spaces(4);

        let count = indent_lines(&mut rope, 0, 2, &config);
        assert_eq!(count, 3);
        assert_eq!(rope.to_string(), "    line1\n    line2\n    line3");
    }

    #[test]
    fn test_dedent_lines() {
        let mut rope = Rope::from_str("    line1\n    line2\n    line3");
        let config = IndentConfig::spaces(4);

        let count = dedent_lines(&mut rope, 0, 2, &config);
        assert_eq!(count, 3);
        assert_eq!(rope.to_string(), "line1\nline2\nline3");
    }

    #[test]
    fn test_normalize_indentation_tabs_to_spaces() {
        let mut rope = Rope::from_str("\tline1\n\t\tline2");
        let config = IndentConfig::spaces(4);

        normalize_indentation(&mut rope, &config);
        assert_eq!(rope.to_string(), "    line1\n        line2");
    }

    #[test]
    fn test_normalize_indentation_spaces_to_tabs() {
        let mut rope = Rope::from_str("    line1\n        line2");
        let config = IndentConfig::tabs();

        normalize_indentation(&mut rope, &config);
        assert_eq!(rope.to_string(), "\tline1\n\t\tline2");
    }
}
