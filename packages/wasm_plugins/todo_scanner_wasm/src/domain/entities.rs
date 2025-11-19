// Domain Entities - Core business objects

use serde::{Deserialize, Serialize};
use super::value_objects::{TodoType, TodoPriority, Position};

/// Represents a TODO/FIXME/HACK comment found in source code
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct TodoItem {
    /// Type of TODO marker (TODO, FIXME, HACK, NOTE, XXX, etc.)
    pub todo_type: TodoType,

    /// Priority level (High, Medium, Low)
    pub priority: TodoPriority,

    /// The actual comment text (without the marker)
    pub text: String,

    /// Line number where TODO was found (0-indexed)
    pub line: u32,

    /// Column number where TODO starts (0-indexed)
    pub column: u32,

    /// Position information
    pub position: Position,

    /// Optional author extracted from comment (e.g., "// TODO(john): fix this")
    pub author: Option<String>,

    /// Optional tags extracted from comment (e.g., "// TODO #bug #critical")
    pub tags: Vec<String>,
}

impl TodoItem {
    /// Create a new TODO item
    pub fn new(
        todo_type: TodoType,
        priority: TodoPriority,
        text: String,
        line: u32,
        column: u32,
    ) -> Self {
        Self {
            todo_type: todo_type.clone(),
            priority,
            text,
            line,
            column,
            position: Position::new(line, column),
            author: None,
            tags: Vec::new(),
        }
    }

    /// Set the author
    pub fn with_author(mut self, author: String) -> Self {
        self.author = Some(author);
        self
    }

    /// Add tags
    pub fn with_tags(mut self, tags: Vec<String>) -> Self {
        self.tags = tags;
        self
    }
}

/// Collection of TODO items with metadata
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TodoCollection {
    /// All TODO items found
    pub items: Vec<TodoItem>,

    /// Total count by type
    pub counts_by_type: TodoTypeCounts,

    /// Total count by priority
    pub counts_by_priority: PriorityCounts,

    /// Scan duration in milliseconds
    pub scan_duration_ms: u64,
}

/// Counts of TODO items by type
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct TodoTypeCounts {
    pub todo: u32,
    pub fixme: u32,
    pub hack: u32,
    pub note: u32,
    pub xxx: u32,
    pub bug: u32,
    pub optimize: u32,
    pub review: u32,
}

impl TodoTypeCounts {
    pub fn increment(&mut self, todo_type: &TodoType) {
        match todo_type {
            TodoType::Todo => self.todo += 1,
            TodoType::Fixme => self.fixme += 1,
            TodoType::Hack => self.hack += 1,
            TodoType::Note => self.note += 1,
            TodoType::Xxx => self.xxx += 1,
            TodoType::Bug => self.bug += 1,
            TodoType::Optimize => self.optimize += 1,
            TodoType::Review => self.review += 1,
        }
    }

    pub fn total(&self) -> u32 {
        self.todo + self.fixme + self.hack + self.note + self.xxx + self.bug + self.optimize + self.review
    }
}

/// Counts of TODO items by priority
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct PriorityCounts {
    pub high: u32,
    pub medium: u32,
    pub low: u32,
}

impl PriorityCounts {
    pub fn increment(&mut self, priority: &TodoPriority) {
        match priority {
            TodoPriority::High => self.high += 1,
            TodoPriority::Medium => self.medium += 1,
            TodoPriority::Low => self.low += 1,
        }
    }
}
