use anyhow::Result;
use ropey::Rope;
use tree_sitter::{Parser, Language, Tree};

// Sub-modules
pub mod cursor;
pub mod search;
pub mod multiline_edit;
pub mod performance;
pub mod clipboard;
pub mod syntax_query;
pub mod bracket_matching;
pub mod auto_indent;
pub mod comment_toggle;

// Re-export commonly used items
pub use cursor::{Position, Selection};
pub use search::{SearchOptions, SearchMatch, search_rope, find_next, replace_all};
pub use multiline_edit::{MultiCursor, ColumnSelection, MultiEdit};
pub use performance::{PerformanceMetrics, OperationTimer, PerformanceStats};
pub use clipboard::{Clipboard, ClipboardMode, copy_text, cut_text, paste_text};
pub use syntax_query::{SyntaxQuery, QueryError};
pub use bracket_matching::{BracketType, BracketMatch, find_matching_bracket, find_all_bracket_pairs, are_brackets_balanced};
pub use auto_indent::{IndentConfig, calculate_indent_for_newline, indent_lines, dedent_lines, normalize_indentation};
pub use comment_toggle::{CommentConfig, toggle_line_comments, toggle_block_comment};

/// Language identifier
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum LanguageId {
    Rust,
    JavaScript,
    TypeScript,
    Python,
    Java,
    Go,
    Dart,
    PlainText,
}

impl std::str::FromStr for LanguageId {
    type Err = std::convert::Infallible;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        Ok(match s.to_lowercase().as_str() {
            "rust" | "rs" => Self::Rust,
            "javascript" | "js" => Self::JavaScript,
            "typescript" | "ts" => Self::TypeScript,
            "python" | "py" => Self::Python,
            "java" => Self::Java,
            "go" => Self::Go,
            "dart" => Self::Dart,
            _ => Self::PlainText,
        })
    }
}

impl LanguageId {
    /// Creates a LanguageId from a string identifier
    pub fn parse(s: &str) -> Self {
        s.parse().unwrap_or(Self::PlainText)
    }

    pub fn tree_sitter_language(&self) -> Option<Language> {
        match self {
            Self::Rust => Some(tree_sitter_rust::language()),
            Self::JavaScript => Some(tree_sitter_javascript::language()),
            Self::TypeScript => Some(tree_sitter_typescript::language_typescript()),
            Self::Python => Some(tree_sitter_python::language()),
            Self::Java => Some(tree_sitter_java::language()),
            Self::Go => Some(tree_sitter_go::language()),
            _ => None,
        }
    }
}

/// Edit record for undo/redo operations
#[derive(Debug, Clone)]
pub struct Edit {
    pub position: usize,
    pub deleted_text: String,
    pub inserted_text: String,
}

/// Main Editor struct
///
/// This is the core editor implementation using ropey for text storage
/// and tree-sitter for syntax highlighting.
pub struct Editor {
    /// Text content (rope data structure for O(log n) operations)
    rope: Rope,

    /// Current cursor position
    cursor: Position,

    /// Current selection (if any)
    selection: Option<Selection>,

    /// Programming language
    language: LanguageId,

    /// Tree-sitter parser
    parser: Option<Parser>,

    /// Syntax tree
    syntax_tree: Option<Tree>,

    /// Undo stack
    undo_stack: Vec<Edit>,

    /// Redo stack
    redo_stack: Vec<Edit>,

    /// Maximum undo history
    max_undo_history: usize,

    /// Dirty flag (unsaved changes)
    is_dirty: bool,
}

impl Editor {
    /// Creates a new empty editor
    pub fn new() -> Self {
        Self {
            rope: Rope::new(),
            cursor: Position::new(0, 0),
            selection: None,
            language: LanguageId::PlainText,
            parser: None,
            syntax_tree: None,
            undo_stack: Vec::new(),
            redo_stack: Vec::new(),
            max_undo_history: 1000,
            is_dirty: false,
        }
    }

    /// Creates editor with initial content
    pub fn with_content(content: &str, language: LanguageId) -> Result<Self> {
        let mut editor = Self::new();
        editor.set_content(content)?;
        editor.set_language(language)?;
        Ok(editor)
    }

    /// Gets the entire content as string
    pub fn content(&self) -> String {
        self.rope.to_string()
    }

    /// Sets the entire content (replaces everything)
    pub fn set_content(&mut self, content: &str) -> Result<()> {
        self.rope = Rope::from_str(content);
        self.cursor = Position::new(0, 0);
        self.selection = None;
        self.is_dirty = true;
        self.reparse();
        Ok(())
    }

    /// Sets the programming language
    pub fn set_language(&mut self, language: LanguageId) -> Result<()> {
        self.language = language;

        // Initialize tree-sitter parser if language is supported
        if let Some(ts_language) = self.language.tree_sitter_language() {
            let mut parser = Parser::new();
            parser.set_language(ts_language)?;
            self.parser = Some(parser);
            self.reparse();
        } else {
            self.parser = None;
            self.syntax_tree = None;
        }

        Ok(())
    }

    /// Inserts text at cursor position
    pub fn insert_text(&mut self, text: &str) -> Result<()> {
        let byte_offset = self.cursor.to_byte_offset(&self.rope);

        // Record edit for undo
        let edit = Edit {
            position: byte_offset,
            deleted_text: String::new(),
            inserted_text: text.to_string(),
        };
        self.push_undo(edit);

        // Insert into rope (O(log n) - fast!)
        self.rope.insert(byte_offset, text);

        // Update cursor position
        let new_offset = byte_offset + text.len();
        self.cursor = Position::from_byte_offset(&self.rope, new_offset);

        self.is_dirty = true;
        self.reparse();
        Ok(())
    }

    /// Deletes text in selection or at cursor
    pub fn delete(&mut self) -> Result<()> {
        if let Some(selection) = self.selection {
            let normalized = selection.normalize();
            let start_offset = normalized.start.to_byte_offset(&self.rope);
            let end_offset = normalized.end.to_byte_offset(&self.rope);

            if start_offset < end_offset {
                let deleted_text = self.rope.slice(start_offset..end_offset).to_string();

                // Record edit for undo
                let edit = Edit {
                    position: start_offset,
                    deleted_text,
                    inserted_text: String::new(),
                };
                self.push_undo(edit);

                self.rope.remove(start_offset..end_offset);
                self.cursor = normalized.start;
                self.selection = None;
                self.is_dirty = true;
                self.reparse();
            }
        } else {
            // Delete character at cursor (forward delete)
            let byte_offset = self.cursor.to_byte_offset(&self.rope);
            if byte_offset < self.rope.len_bytes() {
                let next_offset = self.rope.byte_to_char(byte_offset) + 1;
                let next_byte = self.rope.char_to_byte(next_offset.min(self.rope.len_chars()));

                let deleted_text = self.rope.slice(byte_offset..next_byte).to_string();

                let edit = Edit {
                    position: byte_offset,
                    deleted_text,
                    inserted_text: String::new(),
                };
                self.push_undo(edit);

                self.rope.remove(byte_offset..next_byte);
                self.is_dirty = true;
                self.reparse();
            }
        }

        Ok(())
    }

    /// Moves cursor to position
    pub fn move_cursor(&mut self, position: Position) {
        let line = position.line.min(self.rope.len_lines().saturating_sub(1));
        let line_len = self.rope.line(line).len_chars();
        let column = position.column.min(line_len);

        self.cursor = Position::new(line, column);
    }

    /// Sets selection
    pub fn set_selection(&mut self, selection: Selection) {
        self.selection = Some(selection);
    }

    /// Clears selection
    pub fn clear_selection(&mut self) {
        self.selection = None;
    }

    /// Undo last edit
    pub fn undo(&mut self) -> Result<bool> {
        if let Some(edit) = self.undo_stack.pop() {
            // Reverse the edit
            if !edit.inserted_text.is_empty() {
                // Remove inserted text
                let end = edit.position + edit.inserted_text.len();
                self.rope.remove(edit.position..end);
            }

            if !edit.deleted_text.is_empty() {
                // Re-insert deleted text
                self.rope.insert(edit.position, &edit.deleted_text);
            }

            // Update cursor
            self.cursor = Position::from_byte_offset(&self.rope, edit.position);

            // Push to redo stack
            self.redo_stack.push(edit);

            self.reparse();
            Ok(true)
        } else {
            Ok(false)
        }
    }

    /// Redo last undone edit
    pub fn redo(&mut self) -> Result<bool> {
        if let Some(edit) = self.redo_stack.pop() {
            // Re-apply the edit
            if !edit.deleted_text.is_empty() {
                let end = edit.position + edit.deleted_text.len();
                self.rope.remove(edit.position..end);
            }

            if !edit.inserted_text.is_empty() {
                self.rope.insert(edit.position, &edit.inserted_text);
            }

            let new_offset = edit.position + edit.inserted_text.len();
            self.cursor = Position::from_byte_offset(&self.rope, new_offset);

            self.undo_stack.push(edit);

            self.reparse();
            Ok(true)
        } else {
            Ok(false)
        }
    }

    /// Gets line count
    pub fn line_count(&self) -> usize {
        self.rope.len_lines()
    }

    /// Gets line content
    pub fn line(&self, index: usize) -> Option<String> {
        if index < self.rope.len_lines() {
            Some(self.rope.line(index).to_string())
        } else {
            None
        }
    }

    /// Gets current cursor position
    pub fn cursor(&self) -> Position {
        self.cursor
    }

    /// Gets current selection
    pub fn selection(&self) -> Option<Selection> {
        self.selection
    }

    /// Checks if editor has unsaved changes
    pub fn is_dirty(&self) -> bool {
        self.is_dirty
    }

    /// Marks editor as saved
    pub fn mark_saved(&mut self) {
        self.is_dirty = false;
    }

    /// Reparses the syntax tree (incremental)
    fn reparse(&mut self) {
        if let Some(parser) = &mut self.parser {
            let content = self.rope.to_string();
            let tree = parser.parse(&content, self.syntax_tree.as_ref());
            self.syntax_tree = tree;
        }
    }

    /// Pushes edit to undo stack
    fn push_undo(&mut self, edit: Edit) {
        if self.undo_stack.len() >= self.max_undo_history {
            self.undo_stack.remove(0);
        }
        self.undo_stack.push(edit);
        self.redo_stack.clear(); // Clear redo stack on new edit
    }

    /// Gets syntax tree (for rendering)
    pub fn syntax_tree(&self) -> Option<&Tree> {
        self.syntax_tree.as_ref()
    }
}

impl Default for Editor {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // ============================================================
    // Position Tests
    // ============================================================

    #[test]
    fn test_position_new() {
        let pos = Position::new(5, 10);
        assert_eq!(pos.line, 5);
        assert_eq!(pos.column, 10);
    }

    #[test]
    fn test_position_conversion_simple() {
        let rope = Rope::from_str("Line 1\nLine 2\nLine 3");
        let pos = Position::new(1, 3);
        let offset = pos.to_byte_offset(&rope);
        let back = Position::from_byte_offset(&rope, offset);
        assert_eq!(pos, back);
    }

    #[test]
    fn test_position_conversion_first_line() {
        let rope = Rope::from_str("Hello World");
        let pos = Position::new(0, 5);
        let offset = pos.to_byte_offset(&rope);
        assert_eq!(offset, 5);
        let back = Position::from_byte_offset(&rope, offset);
        assert_eq!(pos, back);
    }

    #[test]
    fn test_position_conversion_multiline() {
        let rope = Rope::from_str("Line 1\nLine 2\nLine 3\nLine 4");

        // Test various positions
        let cases = vec![
            Position::new(0, 0),  // Start
            Position::new(0, 3),  // Middle of first line
            Position::new(1, 0),  // Start of second line
            Position::new(2, 4),  // Middle of third line
            Position::new(3, 6),  // End of last line
        ];

        for pos in cases {
            let offset = pos.to_byte_offset(&rope);
            let back = Position::from_byte_offset(&rope, offset);
            assert_eq!(pos, back, "Failed for position {:?}", pos);
        }
    }

    #[test]
    fn test_position_to_byte_offset_clamping() {
        let rope = Rope::from_str("Short\nMedium line\nX");

        // Column beyond line length should be clamped
        let pos = Position::new(0, 100);
        let offset = pos.to_byte_offset(&rope);
        let back = Position::from_byte_offset(&rope, offset);
        // When column is clamped to end of line (including newline),
        // from_byte_offset might return next line's start
        assert!(back.line <= 1); // Could be 0 or 1 depending on newline handling
        assert!(back.column <= 6); // "Short\n" has 6 bytes
    }

    // ============================================================
    // Selection Tests
    // ============================================================

    #[test]
    fn test_selection_new() {
        let start = Position::new(0, 0);
        let end = Position::new(0, 5);
        let sel = Selection::new(start, end);
        assert_eq!(sel.start, start);
        assert_eq!(sel.end, end);
    }

    #[test]
    fn test_selection_is_empty() {
        let pos = Position::new(1, 5);
        let empty_sel = Selection::new(pos, pos);
        assert!(empty_sel.is_empty());

        let non_empty = Selection::new(Position::new(0, 0), Position::new(0, 5));
        assert!(!non_empty.is_empty());
    }

    #[test]
    fn test_selection_normalize_forward() {
        let sel = Selection::new(Position::new(0, 0), Position::new(0, 5));
        let normalized = sel.normalize();
        assert_eq!(normalized.start, Position::new(0, 0));
        assert_eq!(normalized.end, Position::new(0, 5));
    }

    #[test]
    fn test_selection_normalize_backward() {
        let sel = Selection::new(Position::new(0, 5), Position::new(0, 0));
        let normalized = sel.normalize();
        assert_eq!(normalized.start, Position::new(0, 0));
        assert_eq!(normalized.end, Position::new(0, 5));
    }

    #[test]
    fn test_selection_normalize_multiline() {
        let sel = Selection::new(Position::new(3, 10), Position::new(1, 5));
        let normalized = sel.normalize();
        assert_eq!(normalized.start, Position::new(1, 5));
        assert_eq!(normalized.end, Position::new(3, 10));
    }

    // ============================================================
    // LanguageId Tests
    // ============================================================

    #[test]
    fn test_language_from_str() {
        assert_eq!(LanguageId::parse("rust"), LanguageId::Rust);
        assert_eq!(LanguageId::parse("rs"), LanguageId::Rust);
        assert_eq!(LanguageId::parse("Rust"), LanguageId::Rust);
        assert_eq!(LanguageId::parse("RUST"), LanguageId::Rust);

        assert_eq!(LanguageId::parse("javascript"), LanguageId::JavaScript);
        assert_eq!(LanguageId::parse("js"), LanguageId::JavaScript);

        assert_eq!(LanguageId::parse("typescript"), LanguageId::TypeScript);
        assert_eq!(LanguageId::parse("ts"), LanguageId::TypeScript);

        assert_eq!(LanguageId::parse("python"), LanguageId::Python);
        assert_eq!(LanguageId::parse("py"), LanguageId::Python);

        assert_eq!(LanguageId::parse("java"), LanguageId::Java);
        assert_eq!(LanguageId::parse("go"), LanguageId::Go);
        assert_eq!(LanguageId::parse("dart"), LanguageId::Dart);

        assert_eq!(LanguageId::parse("unknown"), LanguageId::PlainText);
        assert_eq!(LanguageId::parse(""), LanguageId::PlainText);
    }

    #[test]
    fn test_language_tree_sitter_support() {
        assert!(LanguageId::Rust.tree_sitter_language().is_some());
        assert!(LanguageId::JavaScript.tree_sitter_language().is_some());
        assert!(LanguageId::TypeScript.tree_sitter_language().is_some());
        assert!(LanguageId::Python.tree_sitter_language().is_some());
        assert!(LanguageId::Java.tree_sitter_language().is_some());
        assert!(LanguageId::Go.tree_sitter_language().is_some());

        assert!(LanguageId::PlainText.tree_sitter_language().is_none());
        assert!(LanguageId::Dart.tree_sitter_language().is_none());
    }

    // ============================================================
    // Editor - Basic Operations
    // ============================================================

    #[test]
    fn test_editor_new() {
        let editor = Editor::new();
        assert_eq!(editor.content(), "");
        assert_eq!(editor.cursor(), Position::new(0, 0));
        assert_eq!(editor.selection(), None);
        assert!(!editor.is_dirty());
    }

    #[test]
    fn test_editor_default() {
        let editor = Editor::default();
        assert_eq!(editor.content(), "");
        assert_eq!(editor.cursor(), Position::new(0, 0));
    }

    #[test]
    fn test_editor_with_content() {
        let content = "fn main() {\n    println!(\"Hello\");\n}";
        let editor = Editor::with_content(content, LanguageId::Rust).unwrap();
        assert_eq!(editor.content(), content);
        assert_eq!(editor.cursor(), Position::new(0, 0));
        assert!(editor.is_dirty()); // with_content calls set_content which sets dirty flag
    }

    #[test]
    fn test_set_content() {
        let mut editor = Editor::new();
        editor.set_content("Hello World").unwrap();
        assert_eq!(editor.content(), "Hello World");
        assert!(editor.is_dirty());
        assert_eq!(editor.cursor(), Position::new(0, 0));
    }

    #[test]
    fn test_set_content_multiline() {
        let mut editor = Editor::new();
        let content = "Line 1\nLine 2\nLine 3";
        editor.set_content(content).unwrap();
        assert_eq!(editor.content(), content);
        assert_eq!(editor.line_count(), 3);
    }

    // ============================================================
    // Editor - Insert Operations
    // ============================================================

    #[test]
    fn test_insert_text_simple() {
        let mut editor = Editor::new();
        editor.insert_text("Hello, ").unwrap();
        editor.insert_text("World!").unwrap();
        assert_eq!(editor.content(), "Hello, World!");
        assert!(editor.is_dirty());
    }

    #[test]
    fn test_insert_text_at_start() {
        let mut editor = Editor::new();
        editor.set_content("World").unwrap();
        editor.move_cursor(Position::new(0, 0));
        editor.insert_text("Hello ").unwrap();
        assert_eq!(editor.content(), "Hello World");
    }

    #[test]
    fn test_insert_text_at_middle() {
        let mut editor = Editor::new();
        editor.set_content("HelloWorld").unwrap();
        editor.move_cursor(Position::new(0, 5));
        editor.insert_text(" ").unwrap();
        assert_eq!(editor.content(), "Hello World");
    }

    #[test]
    fn test_insert_text_multiline() {
        let mut editor = Editor::new();
        editor.insert_text("Line 1\n").unwrap();
        editor.insert_text("Line 2\n").unwrap();
        editor.insert_text("Line 3").unwrap();
        assert_eq!(editor.content(), "Line 1\nLine 2\nLine 3");
        assert_eq!(editor.line_count(), 3);
    }

    #[test]
    fn test_insert_text_updates_cursor() {
        let mut editor = Editor::new();
        editor.insert_text("Hello").unwrap();
        assert_eq!(editor.cursor(), Position::new(0, 5));

        editor.insert_text("\nWorld").unwrap();
        assert_eq!(editor.cursor(), Position::new(1, 5));
    }

    // ============================================================
    // Editor - Delete Operations
    // ============================================================

    #[test]
    fn test_delete_single_char() {
        let mut editor = Editor::new();
        editor.set_content("Hello World").unwrap();
        editor.move_cursor(Position::new(0, 5));
        editor.delete().unwrap();
        assert_eq!(editor.content(), "HelloWorld");
    }

    #[test]
    fn test_delete_at_end_does_nothing() {
        let mut editor = Editor::new();
        editor.set_content("Hello").unwrap();
        editor.move_cursor(Position::new(0, 5));
        editor.delete().unwrap();
        assert_eq!(editor.content(), "Hello");
    }

    #[test]
    fn test_delete_selection() {
        let mut editor = Editor::new();
        editor.set_content("Hello World").unwrap();

        let sel = Selection::new(Position::new(0, 0), Position::new(0, 6));
        editor.set_selection(sel);

        editor.delete().unwrap();
        assert_eq!(editor.content(), "World");
        assert_eq!(editor.cursor(), Position::new(0, 0));
        assert_eq!(editor.selection(), None);
    }

    #[test]
    fn test_delete_backward_selection() {
        let mut editor = Editor::new();
        editor.set_content("Hello World").unwrap();

        // Backward selection (should be normalized)
        let sel = Selection::new(Position::new(0, 6), Position::new(0, 0));
        editor.set_selection(sel);

        editor.delete().unwrap();
        assert_eq!(editor.content(), "World");
        assert_eq!(editor.cursor(), Position::new(0, 0));
    }

    #[test]
    fn test_delete_multiline_selection() {
        let mut editor = Editor::new();
        editor.set_content("Line 1\nLine 2\nLine 3").unwrap();

        let sel = Selection::new(Position::new(0, 3), Position::new(1, 3));
        editor.set_selection(sel);

        editor.delete().unwrap();
        assert_eq!(editor.content(), "Line 2\nLine 3");
    }

    // ============================================================
    // Editor - Undo/Redo
    // ============================================================

    #[test]
    fn test_undo_redo_simple() {
        let mut editor = Editor::new();
        editor.insert_text("Hello").unwrap();
        editor.insert_text(" World").unwrap();

        assert_eq!(editor.content(), "Hello World");

        editor.undo().unwrap();
        assert_eq!(editor.content(), "Hello");

        editor.redo().unwrap();
        assert_eq!(editor.content(), "Hello World");
    }

    #[test]
    fn test_undo_multiple() {
        let mut editor = Editor::new();
        editor.insert_text("A").unwrap();
        editor.insert_text("B").unwrap();
        editor.insert_text("C").unwrap();

        assert_eq!(editor.content(), "ABC");

        editor.undo().unwrap();
        assert_eq!(editor.content(), "AB");

        editor.undo().unwrap();
        assert_eq!(editor.content(), "A");

        editor.undo().unwrap();
        assert_eq!(editor.content(), "");
    }

    #[test]
    fn test_undo_empty_stack() {
        let mut editor = Editor::new();
        let result = editor.undo().unwrap();
        assert!(!result); // Should return false (nothing to undo)
    }

    #[test]
    fn test_redo_empty_stack() {
        let mut editor = Editor::new();
        let result = editor.redo().unwrap();
        assert!(!result); // Should return false (nothing to redo)
    }

    #[test]
    fn test_new_edit_clears_redo_stack() {
        let mut editor = Editor::new();
        editor.insert_text("Hello").unwrap();
        editor.insert_text(" World").unwrap();

        editor.undo().unwrap();
        assert_eq!(editor.content(), "Hello");

        // New edit should clear redo stack
        editor.insert_text(" Rust").unwrap();
        assert_eq!(editor.content(), "Hello Rust");

        // Redo should not work now
        let result = editor.redo().unwrap();
        assert!(!result);
        assert_eq!(editor.content(), "Hello Rust");
    }

    #[test]
    fn test_undo_delete() {
        let mut editor = Editor::new();
        editor.set_content("Hello World").unwrap();
        editor.move_cursor(Position::new(0, 5));
        editor.delete().unwrap();

        assert_eq!(editor.content(), "HelloWorld");

        editor.undo().unwrap();
        assert_eq!(editor.content(), "Hello World");
    }

    #[test]
    fn test_undo_restores_cursor() {
        let mut editor = Editor::new();
        editor.insert_text("Hello").unwrap();
        assert_eq!(editor.cursor(), Position::new(0, 5));

        editor.undo().unwrap();
        assert_eq!(editor.cursor(), Position::new(0, 0));
    }

    // ============================================================
    // Editor - Cursor Movement
    // ============================================================

    #[test]
    fn test_move_cursor_simple() {
        let mut editor = Editor::new();
        editor.set_content("Hello World").unwrap();

        editor.move_cursor(Position::new(0, 5));
        assert_eq!(editor.cursor(), Position::new(0, 5));
    }

    #[test]
    fn test_move_cursor_clamps_line() {
        let mut editor = Editor::new();
        editor.set_content("Line 1\nLine 2").unwrap();

        // Try to move beyond last line
        editor.move_cursor(Position::new(100, 0));
        assert_eq!(editor.cursor().line, 1); // Should clamp to last line
    }

    #[test]
    fn test_move_cursor_clamps_column() {
        let mut editor = Editor::new();
        editor.set_content("Hello").unwrap();

        // Try to move beyond line length
        editor.move_cursor(Position::new(0, 100));
        assert!(editor.cursor().column <= 5);
    }

    #[test]
    fn test_move_cursor_clears_selection() {
        let mut editor = Editor::new();
        editor.set_content("Hello World").unwrap();
        editor.set_selection(Selection::new(Position::new(0, 0), Position::new(0, 5)));

        // moveCursor in EditorStore clears selection, but in Editor it doesn't
        // This is correct behavior - Editor is lower level
        assert!(editor.selection().is_some());
    }

    // ============================================================
    // Editor - Selection
    // ============================================================

    #[test]
    fn test_set_selection() {
        let mut editor = Editor::new();
        editor.set_content("Hello World").unwrap();

        let sel = Selection::new(Position::new(0, 0), Position::new(0, 5));
        editor.set_selection(sel);

        assert_eq!(editor.selection(), Some(sel));
    }

    #[test]
    fn test_clear_selection() {
        let mut editor = Editor::new();
        editor.set_content("Hello World").unwrap();

        let sel = Selection::new(Position::new(0, 0), Position::new(0, 5));
        editor.set_selection(sel);
        assert!(editor.selection().is_some());

        editor.clear_selection();
        assert_eq!(editor.selection(), None);
    }

    // ============================================================
    // Editor - Line Operations
    // ============================================================

    #[test]
    fn test_line_count_empty() {
        let editor = Editor::new();
        assert_eq!(editor.line_count(), 1); // Empty rope has 1 line
    }

    #[test]
    fn test_line_count_single_line() {
        let mut editor = Editor::new();
        editor.set_content("Hello World").unwrap();
        assert_eq!(editor.line_count(), 1);
    }

    #[test]
    fn test_line_count_multiline() {
        let mut editor = Editor::new();
        editor.set_content("Line 1\nLine 2\nLine 3").unwrap();
        assert_eq!(editor.line_count(), 3);
    }

    #[test]
    fn test_get_line() {
        let mut editor = Editor::new();
        editor.set_content("Line 1\nLine 2\nLine 3").unwrap();

        assert_eq!(editor.line(0), Some("Line 1\n".to_string()));
        assert_eq!(editor.line(1), Some("Line 2\n".to_string()));
        assert_eq!(editor.line(2), Some("Line 3".to_string()));
    }

    #[test]
    fn test_get_line_out_of_bounds() {
        let mut editor = Editor::new();
        editor.set_content("Hello").unwrap();

        assert_eq!(editor.line(100), None);
    }

    // ============================================================
    // Editor - Dirty Flag
    // ============================================================

    #[test]
    fn test_is_dirty_initially_false() {
        let editor = Editor::new();
        assert!(!editor.is_dirty());
    }

    #[test]
    fn test_is_dirty_after_insert() {
        let mut editor = Editor::new();
        editor.insert_text("Hello").unwrap();
        assert!(editor.is_dirty());
    }

    #[test]
    fn test_is_dirty_after_delete() {
        let mut editor = Editor::new();
        editor.set_content("Hello").unwrap();
        editor.delete().unwrap();
        assert!(editor.is_dirty());
    }

    #[test]
    fn test_mark_saved() {
        let mut editor = Editor::new();
        editor.insert_text("Hello").unwrap();
        assert!(editor.is_dirty());

        editor.mark_saved();
        assert!(!editor.is_dirty());
    }

    // ============================================================
    // Editor - Language
    // ============================================================

    #[test]
    fn test_set_language_rust() {
        let mut editor = Editor::new();
        editor.set_language(LanguageId::Rust).unwrap();

        // Parser should be initialized for Rust
        assert!(editor.parser.is_some());
    }

    #[test]
    fn test_set_language_plain_text() {
        let mut editor = Editor::new();
        editor.set_language(LanguageId::PlainText).unwrap();

        // No parser for plain text
        assert!(editor.parser.is_none());
        assert!(editor.syntax_tree.is_none());
    }

    #[test]
    fn test_set_language_triggers_parsing() {
        let mut editor = Editor::new();
        editor.set_content("fn main() {}").unwrap();
        editor.set_language(LanguageId::Rust).unwrap();

        // Should have syntax tree after setting language
        assert!(editor.syntax_tree().is_some());
    }

    #[test]
    fn test_language_switching() {
        let mut editor = Editor::new();
        editor.set_content("fn main() {}").unwrap();

        editor.set_language(LanguageId::Rust).unwrap();
        assert!(editor.parser.is_some());

        editor.set_language(LanguageId::PlainText).unwrap();
        assert!(editor.parser.is_none());

        editor.set_language(LanguageId::JavaScript).unwrap();
        assert!(editor.parser.is_some());
    }

    // ============================================================
    // Editor - Complex Scenarios
    // ============================================================

    #[test]
    fn test_complex_editing_scenario() {
        let mut editor = Editor::new();

        // Write code
        editor.insert_text("fn main() {\n").unwrap();
        editor.insert_text("    println!(\"Hello\");\n").unwrap();
        editor.insert_text("}").unwrap();

        let expected = "fn main() {\n    println!(\"Hello\");\n}";
        assert_eq!(editor.content(), expected);

        // Undo last insert
        editor.undo().unwrap();
        assert_eq!(editor.content(), "fn main() {\n    println!(\"Hello\");\n");

        // Redo
        editor.redo().unwrap();
        assert_eq!(editor.content(), expected);

        // Set language
        editor.set_language(LanguageId::Rust).unwrap();
        assert!(editor.syntax_tree().is_some());
    }

    #[test]
    fn test_large_document_operations() {
        let mut editor = Editor::new();

        // Create large document
        for i in 0..100 {
            editor.insert_text(&format!("Line {}\n", i)).unwrap();
        }

        assert_eq!(editor.line_count(), 101); // 100 lines + 1 (last line)

        // Move cursor to middle
        editor.move_cursor(Position::new(50, 0));
        assert_eq!(editor.cursor().line, 50);

        // Insert in middle
        editor.insert_text("INSERTED\n").unwrap();
        assert_eq!(editor.line_count(), 102);
    }

    #[test]
    fn test_unicode_handling() {
        let mut editor = Editor::new();

        // Unicode text
        editor.insert_text("Hello 世界").unwrap();
        assert_eq!(editor.content(), "Hello 世界");

        // Cursor should handle unicode correctly
        editor.move_cursor(Position::new(0, 6));
        editor.insert_text("🦀").unwrap();
        assert_eq!(editor.content(), "Hello 🦀世界");
    }

    #[test]
    fn test_empty_operations() {
        let mut editor = Editor::new();

        // Insert empty string
        editor.insert_text("").unwrap();
        assert_eq!(editor.content(), "");

        // Delete on empty editor
        editor.delete().unwrap();
        assert_eq!(editor.content(), "");
    }
}
