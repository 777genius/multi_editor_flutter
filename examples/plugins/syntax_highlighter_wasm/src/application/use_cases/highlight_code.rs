use crate::{
    domain::{Parser, Highlighter, Language, Theme},
    application::dto::{ParseRequest, HighlightResponse, HighlightRangeDto, ResponseStatistics},
};

/// Highlight Code Use Case
///
/// Orchestrates parsing and highlighting operations.
/// Follow SRP - single responsibility: highlight source code.
/// Follow DIP - depends on abstractions (Parser, Highlighter traits).
pub struct HighlightCodeUseCase<P, H>
where
    P: Parser,
    H: Highlighter,
{
    parser: P,
    highlighter: H,
}

impl<P, H> HighlightCodeUseCase<P, H>
where
    P: Parser,
    H: Highlighter,
{
    /// Create new use case with dependencies (DI)
    pub fn new(parser: P, highlighter: H) -> Self {
        Self { parser, highlighter }
    }

    /// Execute use case: parse and highlight code
    ///
    /// ## Arguments
    /// * `request` - Parse request with source code and language
    /// * `theme` - Color theme for highlighting
    ///
    /// ## Returns
    /// * `Ok(HighlightResponse)` - Successfully highlighted code
    /// * `Err(String)` - Error message
    pub fn execute(
        &self,
        request: &ParseRequest,
        theme: &Theme,
    ) -> Result<HighlightResponse, String> {
        // 1. Validate request
        request.validate()?;

        // 2. Parse language
        let language = Language::from_str(&request.language);
        if !language.is_supported() {
            return Err(format!("Unsupported language: {}", request.language));
        }

        // 3. Check if parser supports language
        if !self.parser.supports_language(language) {
            return Err(format!(
                "Parser does not support language: {}",
                request.language
            ));
        }

        // 4. Parse source code into syntax tree
        let syntax_tree = self.parser
            .parse(language, &request.source_code)
            .map_err(|e| format!("Parse error: {}", e))?;

        // 5. Generate highlights from syntax tree
        let mut highlights = self.highlighter
            .highlight(&syntax_tree, theme)
            .map_err(|e| format!("Highlight error: {}", e))?;

        // 6. Sort highlights by position (for efficient rendering)
        highlights.sort_by_position();

        // 7. Convert domain entities to DTOs
        let range_dtos: Vec<HighlightRangeDto> = highlights
            .ranges()
            .iter()
            .map(|range| {
                let color = theme.get_style(range.token_type())
                    .map(|style| style.color.to_hex());

                HighlightRangeDto {
                    start_line: range.range().start.line,
                    start_column: range.range().start.column,
                    end_line: range.range().end.line,
                    end_column: range.range().end.column,
                    token_type: range.token_type().to_string(),
                    color,
                    text: range.text().map(|t| t.to_string()),
                }
            })
            .collect();

        // 8. Collect statistics
        let tree_stats = syntax_tree.statistics();
        let statistics = ResponseStatistics {
            total_bytes: tree_stats.byte_count,
            total_lines: tree_stats.line_count,
            node_count: tree_stats.node_count,
        };

        // 9. Build response
        Ok(HighlightResponse::success(
            range_dtos,
            request.language.clone(),
            theme.name.clone(),
            syntax_tree.has_errors(),
            statistics,
        ))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::{SyntaxTree, HighlightCollection};

    // Mock parser for testing
    struct MockParser;

    impl Parser for MockParser {
        fn parse(&self, language: Language, source_code: &str) -> Result<SyntaxTree, String> {
            Ok(SyntaxTree::new(
                "test".to_string(),
                language,
                source_code.to_string(),
                "source_file".to_string(),
                10,
                false,
            ))
        }

        fn supports_language(&self, _language: Language) -> bool {
            true
        }
    }

    // Mock highlighter for testing
    struct MockHighlighter;

    impl Highlighter for MockHighlighter {
        fn highlight(
            &self,
            _tree: &SyntaxTree,
            _theme: &Theme,
        ) -> Result<HighlightCollection, String> {
            Ok(HighlightCollection::new())
        }
    }

    #[test]
    fn test_use_case_execution() {
        let use_case = HighlightCodeUseCase::new(MockParser, MockHighlighter);

        let request = ParseRequest {
            language: "rust".to_string(),
            source_code: "fn main() {}".to_string(),
            incremental: false,
        };

        let theme = Theme::dark_default();

        let result = use_case.execute(&request, &theme);
        assert!(result.is_ok());

        let response = result.unwrap();
        assert_eq!(response.language, "rust");
        assert!(!response.has_errors);
    }

    #[test]
    fn test_use_case_validation() {
        let use_case = HighlightCodeUseCase::new(MockParser, MockHighlighter);

        let invalid_request = ParseRequest {
            language: "rust".to_string(),
            source_code: "".to_string(), // Empty - should fail
            incremental: false,
        };

        let theme = Theme::dark_default();

        let result = use_case.execute(&invalid_request, &theme);
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("empty"));
    }
}
