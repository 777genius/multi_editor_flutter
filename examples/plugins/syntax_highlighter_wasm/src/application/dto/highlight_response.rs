use serde::{Deserialize, Serialize};

/// Highlight Range DTO
///
/// Simplified highlight range for serialization.
/// Maps from domain HighlightRange entity.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HighlightRangeDto {
    /// Start line (0-indexed)
    pub start_line: u32,

    /// Start column (0-indexed, byte offset)
    pub start_column: u32,

    /// End line (0-indexed)
    pub end_line: u32,

    /// End column (0-indexed, byte offset)
    pub end_column: u32,

    /// Token type (keyword, string, comment, etc.)
    pub token_type: String,

    /// Optional: color in hex format (#RRGGBB)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub color: Option<String>,

    /// Optional: text content
    #[serde(skip_serializing_if = "Option::is_none")]
    pub text: Option<String>,
}

/// Highlight Response DTO
///
/// Output for highlight use case.
/// Contains all highlighted ranges and metadata.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HighlightResponse {
    /// Highlighted ranges (sorted by position)
    pub ranges: Vec<HighlightRangeDto>,

    /// Total number of highlights
    pub total_highlights: usize,

    /// Language that was highlighted
    pub language: String,

    /// Theme name used
    pub theme_name: String,

    /// Whether parse had errors
    pub has_errors: bool,

    /// Statistics
    pub statistics: ResponseStatistics,
}

/// Response Statistics DTO
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResponseStatistics {
    /// Total bytes highlighted
    pub total_bytes: usize,

    /// Total lines in source
    pub total_lines: usize,

    /// Number of nodes in syntax tree
    pub node_count: usize,
}

impl HighlightResponse {
    /// Create success response
    pub fn success(
        ranges: Vec<HighlightRangeDto>,
        language: String,
        theme_name: String,
        has_errors: bool,
        statistics: ResponseStatistics,
    ) -> Self {
        let total_highlights = ranges.len();

        Self {
            ranges,
            total_highlights,
            language,
            theme_name,
            has_errors,
            statistics,
        }
    }
}
