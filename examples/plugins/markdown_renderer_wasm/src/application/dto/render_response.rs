use serde::{Deserialize, Serialize};

/// Render Response DTO
///
/// Output data transfer object for markdown rendering.
/// Serializable for WASM communication.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RenderResponse {
    /// Request ID (matches request)
    pub request_id: String,

    /// Rendered HTML content
    pub html: String,

    /// Rendering statistics
    pub statistics: ResponseStatistics,

    /// Success flag
    pub success: bool,

    /// Error message (if failed)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,

    /// Warnings (non-fatal issues)
    #[serde(default)]
    pub warnings: Vec<String>,
}

/// Response Statistics DTO
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResponseStatistics {
    /// Render time in milliseconds
    pub render_time_ms: u64,

    /// Number of Markdown elements processed
    pub element_count: usize,

    /// Input size in bytes
    pub input_size_bytes: usize,

    /// Output size in bytes
    pub output_size_bytes: usize,

    /// Document statistics
    pub document_stats: DocumentStatsDto,
}

/// Document Statistics DTO
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DocumentStatsDto {
    /// Character count
    pub char_count: usize,

    /// Line count
    pub line_count: usize,

    /// Word count
    pub word_count: usize,

    /// Code block count
    pub code_block_count: usize,

    /// Link count
    pub link_count: usize,
}

impl RenderResponse {
    /// Create successful response
    pub fn success(
        request_id: String,
        html: String,
        statistics: ResponseStatistics,
    ) -> Self {
        Self {
            request_id,
            html,
            statistics,
            success: true,
            error: None,
            warnings: Vec::new(),
        }
    }

    /// Create error response
    pub fn error(request_id: String, error: String) -> Self {
        Self {
            request_id,
            html: String::new(),
            statistics: ResponseStatistics::empty(),
            success: false,
            error: Some(error),
            warnings: Vec::new(),
        }
    }

    /// Add warning to response
    pub fn with_warning(mut self, warning: String) -> Self {
        self.warnings.push(warning);
        self
    }
}

impl ResponseStatistics {
    /// Create new statistics
    pub fn new(
        render_time_ms: u64,
        element_count: usize,
        input_size_bytes: usize,
        output_size_bytes: usize,
        document_stats: DocumentStatsDto,
    ) -> Self {
        Self {
            render_time_ms,
            element_count,
            input_size_bytes,
            output_size_bytes,
            document_stats,
        }
    }

    /// Create empty statistics
    pub fn empty() -> Self {
        Self {
            render_time_ms: 0,
            element_count: 0,
            input_size_bytes: 0,
            output_size_bytes: 0,
            document_stats: DocumentStatsDto::empty(),
        }
    }
}

impl DocumentStatsDto {
    /// Create empty document stats
    pub fn empty() -> Self {
        Self {
            char_count: 0,
            line_count: 0,
            word_count: 0,
            code_block_count: 0,
            link_count: 0,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_success_response() {
        let resp = RenderResponse::success(
            "req-1".to_string(),
            "<p>test</p>".to_string(),
            ResponseStatistics::empty(),
        );

        assert!(resp.success);
        assert!(resp.error.is_none());
    }

    #[test]
    fn test_error_response() {
        let resp = RenderResponse::error(
            "req-1".to_string(),
            "Parse error".to_string(),
        );

        assert!(!resp.success);
        assert!(resp.error.is_some());
    }

    #[test]
    fn test_serde() {
        let resp = RenderResponse::success(
            "req-1".to_string(),
            "<p>test</p>".to_string(),
            ResponseStatistics::empty(),
        );

        let json = serde_json::to_string(&resp).unwrap();
        let deserialized: RenderResponse = serde_json::from_str(&json).unwrap();

        assert_eq!(deserialized.request_id, resp.request_id);
        assert_eq!(deserialized.html, resp.html);
    }
}
