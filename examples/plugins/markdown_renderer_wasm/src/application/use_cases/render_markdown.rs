use crate::domain::{Renderer, MarkdownDocument, MarkdownOptions, DocumentStatistics};
use crate::application::dto::{
    RenderRequest, RenderResponse, ResponseStatistics, DocumentStatsDto, RenderOptionsDto,
};
use std::time::Instant;

/// Render Markdown Use Case
///
/// Orchestrates markdown rendering process.
/// Follow Single Responsibility: only handles rendering workflow.
/// Follow Dependency Inversion: depends on Renderer trait, not concrete implementation.
pub struct RenderMarkdownUseCase<R: Renderer> {
    renderer: R,
}

impl<R: Renderer> RenderMarkdownUseCase<R> {
    /// Create new use case with renderer
    pub fn new(renderer: R) -> Self {
        Self { renderer }
    }

    /// Execute use case
    ///
    /// ## Workflow
    /// 1. Validate request
    /// 2. Convert DTO to domain model
    /// 3. Render markdown
    /// 4. Convert result to DTO
    /// 5. Return response
    pub fn execute(&self, request: RenderRequest) -> RenderResponse {
        let start_time = Instant::now();

        // Step 1: Validate request
        if let Err(error) = self.validate_request(&request) {
            return RenderResponse::error(request.request_id, error);
        }

        // Step 2: Convert DTO to domain model
        let options = match self.convert_options(&request.options) {
            Ok(opts) => opts,
            Err(error) => return RenderResponse::error(request.request_id, error),
        };

        let document = MarkdownDocument::new(
            request.request_id.clone(),
            request.markdown.clone(),
            options,
        );

        // Step 3: Render markdown
        let html_output = match self.renderer.render(&document) {
            Ok(output) => output,
            Err(error) => return RenderResponse::error(request.request_id, error),
        };

        // Step 4: Calculate statistics
        let render_time_ms = start_time.elapsed().as_millis() as u64;
        let statistics = self.create_statistics(
            &document,
            html_output.html(),
            render_time_ms,
            html_output.element_count(),
        );

        // Step 5: Create response
        RenderResponse::success(
            request.request_id,
            html_output.html().to_string(),
            statistics,
        )
    }

    /// Validate render request
    fn validate_request(&self, request: &RenderRequest) -> Result<(), String> {
        if request.request_id.is_empty() {
            return Err("request_id cannot be empty".to_string());
        }

        if request.markdown.len() > 10_000_000 {
            return Err("Markdown content too large (max 10MB)".to_string());
        }

        Ok(())
    }

    /// Convert DTO options to domain options
    fn convert_options(&self, dto: &RenderOptionsDto) -> Result<MarkdownOptions, String> {
        MarkdownOptions::new(
            dto.enable_gfm,
            dto.enable_syntax_highlighting,
            dto.enable_tables,
            dto.enable_strikethrough,
            dto.enable_task_lists,
            dto.max_heading_level,
        )
    }

    /// Create response statistics
    fn create_statistics(
        &self,
        document: &MarkdownDocument,
        html: &str,
        render_time_ms: u64,
        element_count: usize,
    ) -> ResponseStatistics {
        let doc_stats = document.statistics();

        ResponseStatistics::new(
            render_time_ms,
            element_count,
            document.byte_length(),
            html.len(),
            Self::convert_doc_stats(doc_stats),
        )
    }

    /// Convert domain statistics to DTO
    fn convert_doc_stats(stats: &DocumentStatistics) -> DocumentStatsDto {
        DocumentStatsDto {
            char_count: stats.char_count,
            line_count: stats.line_count,
            word_count: stats.word_count,
            code_block_count: stats.code_block_count,
            link_count: stats.link_count,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::{HtmlOutput, RendererInfo};

    // Mock renderer for testing
    struct MockRenderer;

    impl Renderer for MockRenderer {
        fn render(&self, document: &MarkdownDocument) -> Result<HtmlOutput, String> {
            let html = format!("<p>{}</p>", document.content());
            Ok(HtmlOutput::new(html, 10, 1, false))
        }

        fn renderer_info(&self) -> RendererInfo {
            RendererInfo::new(
                "MockRenderer".to_string(),
                "1.0.0".to_string(),
                true,
                true,
                false,
            )
        }
    }

    #[test]
    fn test_successful_render() {
        let use_case = RenderMarkdownUseCase::new(MockRenderer);
        let request = RenderRequest::new(
            "req-1".to_string(),
            "# Hello".to_string(),
        );

        let response = use_case.execute(request);

        assert!(response.success);
        assert!(response.html.contains("<p>"));
    }

    #[test]
    fn test_empty_request_id() {
        let use_case = RenderMarkdownUseCase::new(MockRenderer);
        let request = RenderRequest::new(
            "".to_string(),
            "# Hello".to_string(),
        );

        let response = use_case.execute(request);

        assert!(!response.success);
        assert!(response.error.is_some());
    }

    #[test]
    fn test_statistics() {
        let use_case = RenderMarkdownUseCase::new(MockRenderer);
        let request = RenderRequest::new(
            "req-1".to_string(),
            "# Title\n\nSome text".to_string(),
        );

        let response = use_case.execute(request);

        assert!(response.success);
        assert!(response.statistics.render_time_ms > 0);
        assert_eq!(response.statistics.element_count, 1);
    }
}
