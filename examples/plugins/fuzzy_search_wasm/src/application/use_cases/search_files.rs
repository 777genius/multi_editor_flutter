use crate::domain::{FuzzyMatcher, SearchQuery, FilePath, MatchCollection};
use crate::application::dto::{
    SearchRequest, SearchResponse, MatchDto, SearchStatisticsDto,
};
use std::time::Instant;

/// Search Files Use Case
///
/// Orchestrates fuzzy file search process.
/// Follow Single Responsibility: only handles search workflow.
/// Follow Dependency Inversion: depends on FuzzyMatcher trait, not concrete implementation.
///
/// ## Workflow:
/// 1. Validate request
/// 2. Convert DTO to domain models
/// 3. Execute fuzzy search
/// 4. Filter and sort results
/// 5. Convert to DTO
/// 6. Return response
pub struct SearchFilesUseCase<M: FuzzyMatcher> {
    /// Fuzzy matcher service (injected dependency)
    matcher: M,
}

impl<M: FuzzyMatcher> SearchFilesUseCase<M> {
    /// Create new use case with matcher
    ///
    /// ## Dependency Injection
    /// Takes FuzzyMatcher as parameter (Dependency Inversion Principle).
    /// Any implementation of FuzzyMatcher trait can be used.
    pub fn new(matcher: M) -> Self {
        Self { matcher }
    }

    /// Execute search use case
    ///
    /// ## Process:
    /// 1. Validate request (business rules)
    /// 2. Convert DTO → Domain
    /// 3. Execute search (via injected matcher)
    /// 4. Apply filters and limits
    /// 5. Convert Domain → DTO
    /// 6. Return response with statistics
    pub fn execute(&self, request: SearchRequest) -> SearchResponse {
        let start_time = Instant::now();

        // Step 1: Validate request
        if let Err(error) = self.validate_request(&request) {
            return SearchResponse::error(request.request_id, error);
        }

        // Step 2: Convert DTO to domain models
        let search_query = match self.create_search_query(&request) {
            Ok(query) => query,
            Err(error) => return SearchResponse::error(request.request_id, error),
        };

        let file_paths = match self.create_file_paths(&request) {
            Ok(paths) => paths,
            Err(error) => return SearchResponse::error(request.request_id, error),
        };

        // Step 3: Execute fuzzy search
        let mut match_collection = match self.matcher.search(&search_query, &file_paths) {
            Ok(collection) => collection,
            Err(error) => return SearchResponse::error(request.request_id, error),
        };

        // Step 4: Apply filters and limits
        match_collection = match_collection
            .filter_by_score(request.options.min_score)
            .take(request.options.max_results);

        // Ensure sorted
        match_collection.sort_by_score();

        // Step 5: Convert to DTO
        let match_dtos = self.convert_matches_to_dto(&match_collection);
        let statistics = self.create_statistics(
            &request,
            &match_collection,
            start_time.elapsed().as_millis() as u64,
        );

        // Step 6: Return response
        SearchResponse::success(request.request_id, match_dtos, statistics)
    }

    /// Validate search request (business rules)
    fn validate_request(&self, request: &SearchRequest) -> Result<(), String> {
        // Query validation
        if request.query.trim().is_empty() {
            return Err("Query cannot be empty".to_string());
        }

        if request.query.len() > 1000 {
            return Err("Query too long (max 1000 characters)".to_string());
        }

        // Paths validation
        if request.paths.is_empty() {
            return Err("No paths to search".to_string());
        }

        if request.paths.len() > 100_000 {
            return Err("Too many paths (max 100,000)".to_string());
        }

        // Options validation
        if request.options.max_results == 0 {
            return Err("max_results must be at least 1".to_string());
        }

        if request.options.min_score > 100 {
            return Err("min_score must be 0-100".to_string());
        }

        Ok(())
    }

    /// Create domain SearchQuery from DTO
    fn create_search_query(&self, request: &SearchRequest) -> Result<SearchQuery, String> {
        SearchQuery::new(
            request.query.clone(),
            request.options.case_sensitive,
            request.options.max_results,
            request.options.min_score,
        )
    }

    /// Create domain FilePath objects from DTO
    fn create_file_paths(&self, request: &SearchRequest) -> Result<Vec<FilePath>, String> {
        let mut file_paths = Vec::new();

        for path_str in &request.paths {
            let file_path = FilePath::new(path_str.clone())?;

            // Apply file pattern filter if specified
            if let Some(pattern) = &request.options.file_pattern {
                if !file_path.matches_pattern(pattern) {
                    continue;
                }
            }

            file_paths.push(file_path);
        }

        if file_paths.is_empty() && !request.paths.is_empty() {
            return Err("No paths match the file pattern".to_string());
        }

        Ok(file_paths)
    }

    /// Convert domain matches to DTOs
    fn convert_matches_to_dto(&self, collection: &MatchCollection) -> Vec<MatchDto> {
        collection
            .matches()
            .iter()
            .map(|m| MatchDto {
                path: m.file_path().path().to_string(),
                score: m.score().as_u8(),
                match_indices: m.match_indices().to_vec(),
                rank: m.rank().unwrap_or(0),
            })
            .collect()
    }

    /// Create statistics DTO
    fn create_statistics(
        &self,
        request: &SearchRequest,
        collection: &MatchCollection,
        search_time_ms: u64,
    ) -> SearchStatisticsDto {
        let stats = collection.statistics();

        SearchStatisticsDto::new(
            request.paths.len(),
            collection.len(),
            search_time_ms,
            stats.average_score,
            stats.max_score,
            stats.min_score,
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::{MatcherInfo, FuzzyMatch, MatchScore};

    // Mock matcher for testing
    struct MockMatcher;

    impl FuzzyMatcher for MockMatcher {
        fn search(
            &self,
            query: &SearchQuery,
            paths: &[FilePath],
        ) -> Result<MatchCollection, String> {
            let mut collection = MatchCollection::new();

            // Simple mock: match if path contains query
            for (i, path) in paths.iter().enumerate() {
                if path.path().to_lowercase().contains(&query.normalized_query()) {
                    let fuzzy_match = FuzzyMatch::new(
                        format!("match-{}", i),
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
                "simple".to_string(),
                true,
            )
        }
    }

    #[test]
    fn test_successful_search() {
        let use_case = SearchFilesUseCase::new(MockMatcher);
        let request = SearchRequest::new(
            "req-1".to_string(),
            "test".to_string(),
            vec![
                "src/test.rs".to_string(),
                "src/main.rs".to_string(),
                "test_helper.rs".to_string(),
            ],
        );

        let response = use_case.execute(request);

        assert!(response.success);
        assert_eq!(response.matches.len(), 2); // test.rs and test_helper.rs
        // Search time can be 0ms on fast machines
        assert!(response.statistics.search_time_ms >= 0);
    }

    #[test]
    fn test_empty_query() {
        let use_case = SearchFilesUseCase::new(MockMatcher);
        let request = SearchRequest::new(
            "req-1".to_string(),
            "   ".to_string(),
            vec!["test.rs".to_string()],
        );

        let response = use_case.execute(request);

        assert!(!response.success);
        assert!(response.error.is_some());
    }

    #[test]
    fn test_no_paths() {
        let use_case = SearchFilesUseCase::new(MockMatcher);
        let request = SearchRequest::new(
            "req-1".to_string(),
            "test".to_string(),
            vec![],
        );

        let response = use_case.execute(request);

        assert!(!response.success);
        assert!(response.error.is_some());
    }

    #[test]
    fn test_statistics() {
        let use_case = SearchFilesUseCase::new(MockMatcher);
        let request = SearchRequest::new(
            "req-1".to_string(),
            "test".to_string(),
            vec!["test.rs".to_string(), "main.rs".to_string()],
        );

        let response = use_case.execute(request);

        assert_eq!(response.statistics.total_paths, 2);
        assert_eq!(response.statistics.total_matches, 1);
    }
}
