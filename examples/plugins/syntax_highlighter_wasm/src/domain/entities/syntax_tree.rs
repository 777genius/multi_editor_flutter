use crate::domain::value_objects::{Language, Position, Range};
use serde::{Deserialize, Serialize};

/// Syntax Tree Entity
///
/// Represents parsed code structure (Abstract Syntax Tree).
/// Has identity (source code hash), mutable state (can be reparsed).
/// Aggregate Root in DDD terms.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyntaxTree {
    /// Unique identifier (hash of source code)
    id: String,

    /// Programming language
    language: Language,

    /// Source code that was parsed
    source_code: String,

    /// Root node information (serialized, Tree-sitter nodes are not serializable)
    root_node_kind: String,

    /// Number of nodes in tree
    node_count: usize,

    /// Whether parse was successful
    has_errors: bool,
}

impl SyntaxTree {
    /// Create new syntax tree (called after parsing)
    ///
    /// This is a factory method - actual parsing happens in Infrastructure layer.
    pub fn new(
        id: String,
        language: Language,
        source_code: String,
        root_node_kind: String,
        node_count: usize,
        has_errors: bool,
    ) -> Self {
        Self {
            id,
            language,
            source_code,
            root_node_kind,
            node_count,
            has_errors,
        }
    }

    /// Get tree ID (entity identity)
    pub fn id(&self) -> &str {
        &self.id
    }

    /// Get language
    pub fn language(&self) -> Language {
        self.language
    }

    /// Get source code
    pub fn source_code(&self) -> &str {
        &self.source_code
    }

    /// Check if parse had errors
    pub fn has_errors(&self) -> bool {
        self.has_errors
    }

    /// Get tree statistics
    pub fn statistics(&self) -> TreeStatistics {
        TreeStatistics {
            node_count: self.node_count,
            byte_count: self.source_code.len(),
            line_count: self.source_code.lines().count(),
            has_errors: self.has_errors,
        }
    }

    /// Check if this tree can be incrementally updated
    ///
    /// Incremental parsing is more efficient for large files.
    pub fn supports_incremental_update(&self) -> bool {
        // Tree-sitter supports incremental parsing for all languages
        !self.has_errors
    }
}

/// Tree Statistics Value Object
///
/// Immutable snapshot of tree metrics.
#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub struct TreeStatistics {
    pub node_count: usize,
    pub byte_count: usize,
    pub line_count: usize,
    pub has_errors: bool,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_syntax_tree_creation() {
        let tree = SyntaxTree::new(
            "abc123".to_string(),
            Language::Rust,
            "fn main() {}".to_string(),
            "source_file".to_string(),
            10,
            false,
        );

        assert_eq!(tree.language(), Language::Rust);
        assert!(!tree.has_errors());
        assert!(tree.supports_incremental_update());
    }

    #[test]
    fn test_tree_statistics() {
        let tree = SyntaxTree::new(
            "test".to_string(),
            Language::Rust,
            "line1\nline2\nline3".to_string(),
            "source_file".to_string(),
            5,
            false,
        );

        let stats = tree.statistics();
        assert_eq!(stats.line_count, 3);
        assert_eq!(stats.node_count, 5);
    }
}
