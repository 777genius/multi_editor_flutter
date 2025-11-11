use crate::domain::{
    FuzzyMatcher, MatcherInfo, SearchQuery, FilePath,
    MatchCollection, FuzzyMatch, MatchScore,
};
use fuzzy_matcher::FuzzyMatcher as FuzzyMatcherTrait;
use fuzzy_matcher::skim::SkimMatcherV2;

/// Fuzzy Matcher Adapter
///
/// Implements FuzzyMatcher trait using fuzzy-matcher library (SkimMatcherV2).
/// Based on Sublime Text's algorithm, 50-100x faster than Dart alternatives.
///
/// Follow Adapter pattern: adapts external library to domain interface.
/// Follow Dependency Inversion: implements domain trait, domain doesn't know about fuzzy-matcher.
pub struct NucleoMatcher {
    /// Skim matcher instance (V2 - optimized version)
    matcher: SkimMatcherV2,

    /// Matcher metadata
    info: MatcherInfo,
}

impl NucleoMatcher {
    /// Create new matcher with default configuration
    pub fn new() -> Self {
        Self {
            matcher: SkimMatcherV2::default(),
            info: MatcherInfo::new(
                "fuzzy-matcher (SkimV2)".to_string(),
                env!("CARGO_PKG_VERSION").to_string(),
                "Sublime Text algorithm (fzf-like)".to_string(),
                true,
            ),
        }
    }
}

impl Default for NucleoMatcher {
    fn default() -> Self {
        Self::new()
    }
}

impl FuzzyMatcher for NucleoMatcher {
    fn search(
        &self,
        query: &SearchQuery,
        paths: &[FilePath],
    ) -> Result<MatchCollection, String> {
        let mut collection = MatchCollection::new();

        let needle = query.normalized_query();

        // Search all paths
        for (i, path) in paths.iter().enumerate() {
            let haystack = path.path();

            // Perform fuzzy matching
            if let Some((score, indices)) = self.matcher.fuzzy_indices(haystack, &needle) {
                // Convert i64 score to u16 (fuzzy-matcher uses i64)
                let score_u16 = score.max(0).min(10000) as u16;
                let match_score = MatchScore::from_raw(score_u16);

                // Create FuzzyMatch entity
                let fuzzy_match = FuzzyMatch::new(
                    format!("match-{}", i),
                    path.clone(),
                    match_score,
                    indices,
                );

                collection.add(fuzzy_match);
            }
        }

        Ok(collection)
    }

    fn matcher_info(&self) -> MatcherInfo {
        self.info.clone()
    }

    fn supports_case_sensitive(&self) -> bool {
        true
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn create_paths(paths: &[&str]) -> Vec<FilePath> {
        paths
            .iter()
            .map(|p| FilePath::new(p.to_string()).unwrap())
            .collect()
    }

    #[test]
    fn test_matcher_creation() {
        let matcher = NucleoMatcher::new();
        let info = matcher.matcher_info();

        assert!(info.name.contains("fuzzy-matcher"));
        assert!(info.supports_unicode);
    }

    #[test]
    fn test_simple_match() {
        let matcher = NucleoMatcher::new();
        let query = SearchQuery::simple("test".to_string()).unwrap();
        let paths = create_paths(&["test.rs", "main.rs", "test_helper.rs"]);

        let result = matcher.search(&query, &paths).unwrap();

        // Should match "test.rs" and "test_helper.rs"
        assert_eq!(result.len(), 2);
    }

    #[test]
    fn test_fuzzy_match() {
        let matcher = NucleoMatcher::new();
        // Fuzzy query: "mdrn" should match "markdown_renderer.rs"
        let query = SearchQuery::simple("mdrn".to_string()).unwrap();
        let paths = create_paths(&[
            "src/markdown_renderer.rs",
            "src/main.rs",
            "src/model_data.rs",
        ]);

        let result = matcher.search(&query, &paths).unwrap();

        // Should find fuzzy matches
        assert!(!result.is_empty());

        // markdown_renderer.rs should match (contains m-d-r-n)
        let found = result
            .matches()
            .iter()
            .any(|m| m.file_path().path().contains("markdown_renderer"));
        assert!(found);
    }

    #[test]
    fn test_case_insensitive() {
        let matcher = NucleoMatcher::new();
        let query = SearchQuery::simple("TEST".to_string()).unwrap(); // Uppercase
        let paths = create_paths(&["test.rs"]); // Lowercase

        let result = matcher.search(&query, &paths).unwrap();

        // Should match despite case difference
        assert_eq!(result.len(), 1);
    }

    #[test]
    fn test_no_match() {
        let matcher = NucleoMatcher::new();
        let query = SearchQuery::simple("xyz".to_string()).unwrap();
        let paths = create_paths(&["test.rs", "main.rs"]);

        let result = matcher.search(&query, &paths).unwrap();

        assert_eq!(result.len(), 0);
    }

    #[test]
    fn test_match_indices() {
        let matcher = NucleoMatcher::new();
        let query = SearchQuery::simple("tst".to_string()).unwrap();
        let paths = create_paths(&["test.rs"]);

        let result = matcher.search(&query, &paths).unwrap();

        assert!(!result.is_empty());
        let first_match = &result.matches()[0];

        // Should have match indices
        assert!(!first_match.match_indices().is_empty());
    }

    #[test]
    fn test_performance_hint() {
        // This test demonstrates that fuzzy-matcher is designed for performance
        let matcher = NucleoMatcher::new();

        // Simulate large file list
        let mut paths = Vec::new();
        for i in 0..1000 {
            paths.push(FilePath::new(format!("src/file_{}.rs", i)).unwrap());
        }
        paths.push(FilePath::new("src/markdown_renderer.rs".to_string()).unwrap());

        let query = SearchQuery::simple("mdrn".to_string()).unwrap();

        // This should be fast
        let start = std::time::Instant::now();
        let result = matcher.search(&query, &paths).unwrap();
        let elapsed = start.elapsed();

        // Should find the match
        assert!(!result.is_empty());

        // Performance assertion (lenient for test environment)
        assert!(
            elapsed.as_millis() < 1000,
            "Search took {}ms (expected < 1000ms)",
            elapsed.as_millis()
        );
    }
}
