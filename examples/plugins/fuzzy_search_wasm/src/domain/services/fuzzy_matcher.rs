use crate::domain::{
    entities::{FuzzyMatch, MatchCollection},
    value_objects::{SearchQuery, FilePath},
};

/// Fuzzy Matcher Service (Port)
///
/// Defines contract for fuzzy matching implementation.
/// Domain layer defines interface, Infrastructure implements.
///
/// Follow ISP (Interface Segregation Principle) - minimal interface.
/// Follow DIP (Dependency Inversion) - depend on abstraction, not concrete.
pub trait FuzzyMatcher {
    /// Search for matches in file paths
    ///
    /// ## Arguments
    /// * `query` - Search query with options
    /// * `paths` - List of file paths to search
    ///
    /// ## Returns
    /// * `Ok(MatchCollection)` - Collection of matches
    /// * `Err(String)` - Search error
    fn search(
        &self,
        query: &SearchQuery,
        paths: &[FilePath],
    ) -> Result<MatchCollection, String>;

    /// Get matcher information (for debugging)
    fn matcher_info(&self) -> MatcherInfo {
        MatcherInfo::default()
    }

    /// Check if matcher supports case-sensitive search
    fn supports_case_sensitive(&self) -> bool {
        true
    }
}

/// Matcher Information (Value Object)
#[derive(Debug, Clone, Default)]
pub struct MatcherInfo {
    pub name: String,
    pub version: String,
    pub algorithm: String,
    pub supports_unicode: bool,
}

impl MatcherInfo {
    pub fn new(
        name: String,
        version: String,
        algorithm: String,
        supports_unicode: bool,
    ) -> Self {
        Self {
            name,
            version,
            algorithm,
            supports_unicode,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::value_objects::MatchScore;
    use crate::domain::entities::FuzzyMatch;

    // Mock implementation for testing
    struct MockMatcher;

    impl FuzzyMatcher for MockMatcher {
        fn search(
            &self,
            query: &SearchQuery,
            paths: &[FilePath],
        ) -> Result<MatchCollection, String> {
            let mut collection = MatchCollection::new();

            // Simple mock: match if path contains query
            for path in paths {
                if path.path().contains(query.query()) {
                    let fuzzy_match = FuzzyMatch::new(
                        format!("match-{}", path.path()),
                        path.clone(),
                        MatchScore::new(80).unwrap(),
                        vec![],
                    );
                    collection.add(fuzzy_match);
                }
            }

            Ok(collection)
        }

        fn matcher_info(&self) -> MatcherInfo {
            MatcherInfo::new(
                "MockMatcher".to_string(),
                "1.0.0".to_string(),
                "simple-contains".to_string(),
                true,
            )
        }
    }

    #[test]
    fn test_mock_matcher() {
        let matcher = MockMatcher;
        let query = SearchQuery::simple("test".to_string()).unwrap();
        let paths = vec![
            FilePath::new("test.rs".to_string()).unwrap(),
            FilePath::new("main.rs".to_string()).unwrap(),
            FilePath::new("test_helper.rs".to_string()).unwrap(),
        ];

        let result = matcher.search(&query, &paths).unwrap();
        assert_eq!(result.len(), 2); // test.rs and test_helper.rs
    }

    #[test]
    fn test_matcher_info() {
        let matcher = MockMatcher;
        let info = matcher.matcher_info();
        assert_eq!(info.name, "MockMatcher");
        assert!(info.supports_unicode);
    }
}
