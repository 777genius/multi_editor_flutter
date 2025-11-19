// Application Use Cases - Business logic orchestration

use crate::domain::{BracketAnalyzer, BracketCollection};
use super::dto::{AnalyzeRequest, AnalyzeResponse};

/// Use case for analyzing brackets in source code
pub struct AnalyzeBracketsUseCase<A: BracketAnalyzer> {
    analyzer: A,
}

impl<A: BracketAnalyzer> AnalyzeBracketsUseCase<A> {
    pub fn new(analyzer: A) -> Self {
        Self { analyzer }
    }

    /// Execute the bracket analysis
    pub fn execute(&self, request: AnalyzeRequest) -> AnalyzeResponse {
        // Detect language
        let language = request.detect_language();

        // Analyze brackets
        let collection = self.analyzer.analyze(&request.content, language);

        // Apply max depth filter if specified
        let collection = if let Some(max_depth) = request.max_depth {
            self.filter_by_max_depth(collection, max_depth)
        } else {
            collection
        };

        AnalyzeResponse::success(request.request_id, collection)
    }

    /// Filter brackets by maximum depth
    fn filter_by_max_depth(&self, mut collection: BracketCollection, max_depth: usize) -> BracketCollection {
        collection.pairs.retain(|pair| pair.depth <= max_depth);
        collection.unmatched.retain(|unmatched| unmatched.bracket.depth <= max_depth);

        // Recalculate statistics
        let statistics = crate::domain::BracketStatistics::calculate(&collection.pairs, &collection.unmatched);
        collection.statistics = statistics;

        collection
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::{StackBasedMatcher, ColorScheme, Language};

    #[test]
    fn test_analyze_use_case() {
        let analyzer = StackBasedMatcher::new(ColorScheme::default_rainbow());
        let use_case = AnalyzeBracketsUseCase::new(analyzer);

        let request = AnalyzeRequest::new(
            "test-1".to_string(),
            "function test() { return [1, 2, 3]; }".to_string(),
        );

        let response = use_case.execute(request);

        assert!(response.success);
        assert!(response.data.is_some());

        let data = response.data.unwrap();
        assert_eq!(data.pairs.len(), 3); // (), {}, []
        assert_eq!(data.unmatched.len(), 0);
    }

    #[test]
    fn test_analyze_with_language_detection() {
        let analyzer = StackBasedMatcher::new(ColorScheme::default_rainbow());
        let use_case = AnalyzeBracketsUseCase::new(analyzer);

        let request = AnalyzeRequest::new(
            "test-2".to_string(),
            "class Foo { void bar() {} }".to_string(),
        )
        .with_file_extension("dart".to_string());

        let response = use_case.execute(request);

        assert!(response.success);
        let data = response.data.unwrap();
        assert!(data.pairs.len() > 0);
    }

    #[test]
    fn test_analyze_with_custom_color_scheme() {
        let analyzer = StackBasedMatcher::new(ColorScheme::default_rainbow());
        let use_case = AnalyzeBracketsUseCase::new(analyzer);

        let custom_scheme = ColorScheme {
            colors: vec!["#FF0000".to_string(), "#00FF00".to_string()],
            enabled: true,
            max_depth: 50,
        };

        let request = AnalyzeRequest::new(
            "test-3".to_string(),
            "{ [ ] }".to_string(),
        )
        .with_color_scheme(custom_scheme);

        let response = use_case.execute(request);

        assert!(response.success);
    }

    #[test]
    fn test_analyze_with_max_depth() {
        let analyzer = StackBasedMatcher::new(ColorScheme::default_rainbow());
        let use_case = AnalyzeBracketsUseCase::new(analyzer);

        let mut request = AnalyzeRequest::new(
            "test-4".to_string(),
            "{ [ ( ) ] }".to_string(),
        );
        request.max_depth = Some(1); // Only depth 0 and 1

        let response = use_case.execute(request);

        assert!(response.success);
        let data = response.data.unwrap();
        // Should only include {} and [] (depths 0 and 1), not () (depth 2)
        assert_eq!(data.pairs.len(), 2);
    }

    #[test]
    fn test_analyze_with_errors() {
        let analyzer = StackBasedMatcher::new(ColorScheme::default_rainbow());
        let use_case = AnalyzeBracketsUseCase::new(analyzer);

        let request = AnalyzeRequest::new(
            "test-5".to_string(),
            "{ ( } )".to_string(), // Mismatched
        );

        let response = use_case.execute(request);

        assert!(response.success);
        let data = response.data.unwrap();
        assert!(data.has_errors());
        assert!(data.unmatched.len() > 0);
    }
}
