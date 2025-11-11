use crate::domain::value_objects::MarkdownOptions;

/// Markdown Document (Entity)
///
/// Aggregate Root representing a markdown document.
/// Has identity (document_id) and lifecycle.
#[derive(Debug, Clone)]
pub struct MarkdownDocument {
    /// Unique document identifier
    document_id: String,

    /// Raw markdown content
    content: String,

    /// Rendering options
    options: MarkdownOptions,

    /// Document statistics
    statistics: DocumentStatistics,
}

/// Document Statistics (Value Object within Aggregate)
#[derive(Debug, Clone, Default)]
pub struct DocumentStatistics {
    /// Total character count
    pub char_count: usize,

    /// Total line count
    pub line_count: usize,

    /// Estimated word count
    pub word_count: usize,

    /// Number of code blocks
    pub code_block_count: usize,

    /// Number of links
    pub link_count: usize,
}

impl MarkdownDocument {
    /// Create new markdown document
    pub fn new(
        document_id: String,
        content: String,
        options: MarkdownOptions,
    ) -> Self {
        let statistics = Self::calculate_statistics(&content);

        Self {
            document_id,
            content,
            options,
            statistics,
        }
    }

    /// Calculate document statistics
    fn calculate_statistics(content: &str) -> DocumentStatistics {
        let char_count = content.chars().count();
        let line_count = content.lines().count();
        let word_count = content.split_whitespace().count();

        // Count code blocks (```)
        let code_block_count = content.matches("```").count() / 2;

        // Count markdown links [text](url)
        let link_count = content.matches("](").count();

        DocumentStatistics {
            char_count,
            line_count,
            word_count,
            code_block_count,
            link_count,
        }
    }

    // Getters
    pub fn document_id(&self) -> &str {
        &self.document_id
    }

    pub fn content(&self) -> &str {
        &self.content
    }

    pub fn options(&self) -> &MarkdownOptions {
        &self.options
    }

    pub fn statistics(&self) -> &DocumentStatistics {
        &self.statistics
    }

    /// Check if document is empty
    pub fn is_empty(&self) -> bool {
        self.content.trim().is_empty()
    }

    /// Get content length in bytes
    pub fn byte_length(&self) -> usize {
        self.content.len()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_document_creation() {
        let doc = MarkdownDocument::new(
            "doc-1".to_string(),
            "# Hello\nWorld".to_string(),
            MarkdownOptions::default(),
        );

        assert_eq!(doc.document_id(), "doc-1");
        assert_eq!(doc.statistics().line_count, 2);
        assert!(!doc.is_empty());
    }

    #[test]
    fn test_statistics() {
        let content = "# Title\n\n```rust\nfn main() {}\n```\n\n[link](url)";
        let doc = MarkdownDocument::new(
            "doc-2".to_string(),
            content.to_string(),
            MarkdownOptions::default(),
        );

        let stats = doc.statistics();
        assert_eq!(stats.code_block_count, 1);
        assert_eq!(stats.link_count, 1);
        assert!(stats.word_count > 0);
    }

    #[test]
    fn test_empty_document() {
        let doc = MarkdownDocument::new(
            "doc-3".to_string(),
            "   \n  ".to_string(),
            MarkdownOptions::default(),
        );

        assert!(doc.is_empty());
    }
}
