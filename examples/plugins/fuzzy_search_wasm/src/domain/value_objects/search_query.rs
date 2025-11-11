/// Search Query (Value Object)
///
/// Represents a fuzzy search query with options.
/// Immutable and self-validating (DDD pattern).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SearchQuery {
    /// Query string to search for
    query: String,

    /// Case sensitivity option
    case_sensitive: bool,

    /// Maximum number of results
    max_results: usize,

    /// Minimum score threshold (0-100)
    min_score: u8,
}

impl SearchQuery {
    /// Create new search query with validation
    pub fn new(
        query: String,
        case_sensitive: bool,
        max_results: usize,
        min_score: u8,
    ) -> Result<Self, String> {
        // Validate query is not empty
        if query.trim().is_empty() {
            return Err("Query cannot be empty".to_string());
        }

        // Validate max_results is reasonable
        if max_results == 0 {
            return Err("max_results must be at least 1".to_string());
        }

        if max_results > 10_000 {
            return Err("max_results cannot exceed 10,000".to_string());
        }

        // Validate min_score is 0-100
        if min_score > 100 {
            return Err("min_score must be 0-100".to_string());
        }

        Ok(Self {
            query,
            case_sensitive,
            max_results,
            min_score,
        })
    }

    /// Create default query (case-insensitive, 100 results, score >= 0)
    pub fn simple(query: String) -> Result<Self, String> {
        Self::new(query, false, 100, 0)
    }

    // Getters (immutable)
    pub fn query(&self) -> &str {
        &self.query
    }

    pub fn case_sensitive(&self) -> bool {
        self.case_sensitive
    }

    pub fn max_results(&self) -> usize {
        self.max_results
    }

    pub fn min_score(&self) -> u8 {
        self.min_score
    }

    /// Get normalized query (lowercase if case-insensitive)
    pub fn normalized_query(&self) -> String {
        if self.case_sensitive {
            self.query.clone()
        } else {
            self.query.to_lowercase()
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_valid_query() {
        let query = SearchQuery::new("test".to_string(), false, 50, 10);
        assert!(query.is_ok());

        let q = query.unwrap();
        assert_eq!(q.query(), "test");
        assert!(!q.case_sensitive());
        assert_eq!(q.max_results(), 50);
        assert_eq!(q.min_score(), 10);
    }

    #[test]
    fn test_empty_query() {
        let query = SearchQuery::new("   ".to_string(), false, 50, 10);
        assert!(query.is_err());
    }

    #[test]
    fn test_invalid_max_results() {
        let query = SearchQuery::new("test".to_string(), false, 0, 10);
        assert!(query.is_err());

        let query = SearchQuery::new("test".to_string(), false, 20_000, 10);
        assert!(query.is_err());
    }

    #[test]
    fn test_invalid_min_score() {
        let query = SearchQuery::new("test".to_string(), false, 50, 150);
        assert!(query.is_err());
    }

    #[test]
    fn test_normalized_query() {
        let query = SearchQuery::new("TeSt".to_string(), false, 50, 10).unwrap();
        assert_eq!(query.normalized_query(), "test");

        let query = SearchQuery::new("TeSt".to_string(), true, 50, 10).unwrap();
        assert_eq!(query.normalized_query(), "TeSt");
    }

    #[test]
    fn test_simple_query() {
        let query = SearchQuery::simple("test".to_string()).unwrap();
        assert_eq!(query.max_results(), 100);
        assert_eq!(query.min_score(), 0);
    }
}
