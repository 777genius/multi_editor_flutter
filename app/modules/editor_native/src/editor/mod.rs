use anyhow::Result;
use ropey::Rope;
use tree_sitter::{Parser, Language, Tree};
use tree_sitter_highlight::{HighlightConfiguration, Highlighter, HighlightEvent};
use std::collections::HashMap;

/// Cursor position in the editor (0-indexed)
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Position {
    pub line: usize,
    pub column: usize,
}

impl Position {
    pub fn new(line: usize, column: usize) -> Self {
        Self { line, column }
    }

    /// Converts position to byte offset in rope
    pub fn to_byte_offset(&self, rope: &Rope) -> usize {
        let line_offset = rope.line_to_byte(self.line);
        let line = rope.line(self.line);
        let char_offset = line.char_to_byte(self.column.min(line.len_chars()));
        line_offset + char_offset
    }

    /// Creates position from byte offset
    pub fn from_byte_offset(rope: &Rope, byte_offset: usize) -> Self {
        let line = rope.byte_to_line(byte_offset);
        let line_start = rope.line_to_byte(line);
        let column_bytes = byte_offset - line_start;
        let line_slice = rope.line(line);
        let column = line_slice.byte_to_char(column_bytes.min(line_slice.len_bytes()));

        Self { line, column }
    }
}

/// Text selection range
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Selection {
    pub start: Position,
    pub end: Position,
}

impl Selection {
    pub fn new(start: Position, end: Position) -> Self {
        Self { start, end }
    }

    pub fn is_empty(&self) -> bool {
        self.start == self.end
    }

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
}

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

impl LanguageId {
    pub fn from_str(s: &str) -> Self {
        match s.to_lowercase().as_str() {
            "rust" | "rs" => Self::Rust,
            "javascript" | "js" => Self::JavaScript,
            "typescript" | "ts" => Self::TypeScript,
            "python" | "py" => Self::Python,
            "java" => Self::Java,
            "go" => Self::Go,
            "dart" => Self::Dart,
            _ => Self::PlainText,
        }
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

/// Undo/Redo history
#[derive(Debug, Clone)]
struct Edit {
    position: usize,
    deleted_text: String,
    inserted_text: String,
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

    #[test]
    fn test_insert_text() {
        let mut editor = Editor::new();
        editor.insert_text("Hello, ").unwrap();
        editor.insert_text("World!").unwrap();
        assert_eq!(editor.content(), "Hello, World!");
    }

    #[test]
    fn test_undo_redo() {
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
    fn test_position_conversion() {
        let rope = Rope::from_str("Line 1\nLine 2\nLine 3");
        let pos = Position::new(1, 3);
        let offset = pos.to_byte_offset(&rope);
        let back = Position::from_byte_offset(&rope, offset);
        assert_eq!(pos, back);
    }
}
