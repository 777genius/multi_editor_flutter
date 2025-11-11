use serde::{Deserialize, Serialize};

/// Search Request DTO
///
/// Input data transfer object for fuzzy file search.
/// Serializable for WASM communication.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchRequest {
    /// Unique request ID (for tracking)
    pub request_id: String,

    /// Search query string
    pub query: String,

    /// List of file paths to search
    pub paths: Vec<String>,

    /// Search options
    #[serde(default)]
    pub options: SearchOptionsDto,
}

/// Search Options DTO
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchOptionsDto {
    /// Case-sensitive search
    #[serde(default)]
    pub case_sensitive: bool,

    /// Maximum number of results
    #[serde(default = "default_max_results")]
    pub max_results: usize,

    /// Minimum score threshold (0-100)
    #[serde(default)]
    pub min_score: u8,

    /// File pattern filter (e.g., "*.rs")
    #[serde(default)]
    pub file_pattern: Option<String>,
}

fn default_max_results() -> usize {
    100
}

impl Default for SearchOptionsDto {
    fn default() -> Self {
        Self {
            case_sensitive: false,
            max_results: 100,
            min_score: 0,
            file_pattern: None,
        }
    }
}

impl SearchRequest {
    /// Create new search request
    pub fn new(request_id: String, query: String, paths: Vec<String>) -> Self {
        Self {
            request_id,
            query,
            paths,
            options: SearchOptionsDto::default(),
        }
    }

    /// Create with custom options
    pub fn with_options(
        request_id: String,
        query: String,
        paths: Vec<String>,
        options: SearchOptionsDto,
    ) -> Self {
        Self {
            request_id,
            query,
            paths,
            options,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_search_request_creation() {
        let req = SearchRequest::new(
            "req-1".to_string(),
            "test".to_string(),
            vec!["file1.rs".to_string()],
        );

        assert_eq!(req.request_id, "req-1");
        assert_eq!(req.query, "test");
        assert_eq!(req.paths.len(), 1);
        assert!(!req.options.case_sensitive);
    }

    #[test]
    fn test_serde() {
        let req = SearchRequest::new(
            "req-1".to_string(),
            "test".to_string(),
            vec!["file1.rs".to_string(), "file2.rs".to_string()],
        );

        let json = serde_json::to_string(&req).unwrap();
        let deserialized: SearchRequest = serde_json::from_str(&json).unwrap();

        assert_eq!(deserialized.request_id, req.request_id);
        assert_eq!(deserialized.query, req.query);
        assert_eq!(deserialized.paths, req.paths);
    }

    #[test]
    fn test_default_options() {
        let opts = SearchOptionsDto::default();
        assert_eq!(opts.max_results, 100);
        assert_eq!(opts.min_score, 0);
        assert!(!opts.case_sensitive);
    }
}
