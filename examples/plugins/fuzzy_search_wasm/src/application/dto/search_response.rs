use serde::{Deserialize, Serialize};

/// Search Response DTO
///
/// Output data transfer object for fuzzy file search.
/// Serializable for WASM communication.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchResponse {
    /// Request ID (matches request)
    pub request_id: String,

    /// Search matches
    pub matches: Vec<MatchDto>,

    /// Search statistics
    pub statistics: SearchStatisticsDto,

    /// Success flag
    pub success: bool,

    /// Error message (if failed)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
}

/// Match DTO
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MatchDto {
    /// File path
    pub path: String,

    /// Match score (0-100)
    pub score: u8,

    /// Character indices that matched
    pub match_indices: Vec<usize>,

    /// Rank position (1-based)
    pub rank: usize,
}

/// Search Statistics DTO
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchStatisticsDto {
    /// Total number of paths searched
    pub total_paths: usize,

    /// Number of matches found
    pub total_matches: usize,

    /// Search time in milliseconds
    pub search_time_ms: u64,

    /// Average match score
    pub average_score: f32,

    /// Highest match score
    pub max_score: u8,

    /// Lowest match score
    pub min_score: u8,
}

impl SearchResponse {
    /// Create successful response
    pub fn success(
        request_id: String,
        matches: Vec<MatchDto>,
        statistics: SearchStatisticsDto,
    ) -> Self {
        Self {
            request_id,
            matches,
            statistics,
            success: true,
            error: None,
        }
    }

    /// Create error response
    pub fn error(request_id: String, error: String) -> Self {
        Self {
            request_id,
            matches: Vec::new(),
            statistics: SearchStatisticsDto::empty(),
            success: false,
            error: Some(error),
        }
    }
}

impl SearchStatisticsDto {
    /// Create new statistics
    pub fn new(
        total_paths: usize,
        total_matches: usize,
        search_time_ms: u64,
        average_score: f32,
        max_score: u8,
        min_score: u8,
    ) -> Self {
        Self {
            total_paths,
            total_matches,
            search_time_ms,
            average_score,
            max_score,
            min_score,
        }
    }

    /// Create empty statistics
    pub fn empty() -> Self {
        Self {
            total_paths: 0,
            total_matches: 0,
            search_time_ms: 0,
            average_score: 0.0,
            max_score: 0,
            min_score: 0,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_success_response() {
        let matches = vec![MatchDto {
            path: "test.rs".to_string(),
            score: 85,
            match_indices: vec![0, 1],
            rank: 1,
        }];

        let stats = SearchStatisticsDto::new(100, 1, 50, 85.0, 85, 85);
        let resp = SearchResponse::success("req-1".to_string(), matches, stats);

        assert!(resp.success);
        assert!(resp.error.is_none());
        assert_eq!(resp.matches.len(), 1);
    }

    #[test]
    fn test_error_response() {
        let resp = SearchResponse::error(
            "req-1".to_string(),
            "Query too short".to_string(),
        );

        assert!(!resp.success);
        assert!(resp.error.is_some());
        assert_eq!(resp.matches.len(), 0);
    }

    #[test]
    fn test_serde() {
        let resp = SearchResponse::success(
            "req-1".to_string(),
            vec![],
            SearchStatisticsDto::empty(),
        );

        let json = serde_json::to_string(&resp).unwrap();
        let deserialized: SearchResponse = serde_json::from_str(&json).unwrap();

        assert_eq!(deserialized.request_id, resp.request_id);
        assert_eq!(deserialized.success, resp.success);
    }
}
