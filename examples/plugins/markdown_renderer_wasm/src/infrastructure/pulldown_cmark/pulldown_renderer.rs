use crate::domain::{Renderer, RendererInfo, MarkdownDocument, HtmlOutput};
use pulldown_cmark::{Parser, Options, html};

/// Pulldown-cmark Renderer Adapter
///
/// Implements Renderer trait using pulldown-cmark library.
/// Follow Adapter pattern: adapts external library to domain interface.
pub struct PulldownRenderer {
    /// Renderer metadata
    info: RendererInfo,
}

impl PulldownRenderer {
    /// Create new pulldown-cmark renderer
    pub fn new() -> Self {
        Self {
            info: RendererInfo::new(
                "pulldown-cmark".to_string(),
                env!("CARGO_PKG_VERSION").to_string(),
                true,  // supports GFM
                true,  // supports tables
                true,  // supports footnotes
            ),
        }
    }

    /// Convert domain options to pulldown-cmark options
    fn get_parser_options(&self, document: &MarkdownDocument) -> Options {
        let mut options = Options::empty();

        let doc_options = document.options();

        // Enable GitHub Flavored Markdown extensions
        if doc_options.enable_gfm() {
            options.insert(Options::ENABLE_STRIKETHROUGH);
            options.insert(Options::ENABLE_TASKLISTS);
        }

        // Enable tables
        if doc_options.enable_tables() {
            options.insert(Options::ENABLE_TABLES);
        }

        // Enable strikethrough
        if doc_options.enable_strikethrough() {
            options.insert(Options::ENABLE_STRIKETHROUGH);
        }

        // Enable footnotes
        options.insert(Options::ENABLE_FOOTNOTES);

        // Enable heading attributes
        options.insert(Options::ENABLE_HEADING_ATTRIBUTES);

        options
    }
}

impl Default for PulldownRenderer {
    fn default() -> Self {
        Self::new()
    }
}

impl Renderer for PulldownRenderer {
    fn render(&self, document: &MarkdownDocument) -> Result<HtmlOutput, String> {
        let start = std::time::Instant::now();

        // Get parser options based on document options
        let options = self.get_parser_options(document);

        // Create parser
        let parser = Parser::new_ext(document.content(), options);

        // Count elements (for statistics)
        let parser_clone = Parser::new_ext(document.content(), options);
        let element_count = parser_clone.count();

        // Render to HTML
        let mut html_output = String::new();
        html::push_html(&mut html_output, parser);

        let render_time_ms = start.elapsed().as_millis() as u64;

        Ok(HtmlOutput::new(
            html_output,
            render_time_ms,
            element_count,
            false, // no warnings for now
        ))
    }

    fn supports_github_flavored_markdown(&self) -> bool {
        true
    }

    fn renderer_info(&self) -> RendererInfo {
        self.info.clone()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::MarkdownOptions;

    #[test]
    fn test_render_simple_markdown() {
        let renderer = PulldownRenderer::new();
        let document = MarkdownDocument::new(
            "doc-1".to_string(),
            "# Hello World".to_string(),
            MarkdownOptions::default(),
        );

        let result = renderer.render(&document);
        assert!(result.is_ok());

        let output = result.unwrap();
        assert!(output.html().contains("<h1>"));
        assert!(output.html().contains("Hello World"));
    }

    #[test]
    fn test_render_bold_text() {
        let renderer = PulldownRenderer::new();
        let document = MarkdownDocument::new(
            "doc-2".to_string(),
            "**bold text**".to_string(),
            MarkdownOptions::default(),
        );

        let result = renderer.render(&document);
        assert!(result.is_ok());

        let output = result.unwrap();
        assert!(output.html().contains("<strong>"));
    }

    #[test]
    fn test_render_code_block() {
        let renderer = PulldownRenderer::new();
        let document = MarkdownDocument::new(
            "doc-3".to_string(),
            "```rust\nfn main() {}\n```".to_string(),
            MarkdownOptions::default(),
        );

        let result = renderer.render(&document);
        assert!(result.is_ok());

        let output = result.unwrap();
        assert!(output.html().contains("<pre>"));
        assert!(output.html().contains("<code"));
    }

    #[test]
    fn test_render_table() {
        let renderer = PulldownRenderer::new();
        let markdown = "| Col1 | Col2 |\n|------|------|\n| A    | B    |";
        let document = MarkdownDocument::new(
            "doc-4".to_string(),
            markdown.to_string(),
            MarkdownOptions::default(),
        );

        let result = renderer.render(&document);
        assert!(result.is_ok());

        let output = result.unwrap();
        assert!(output.html().contains("<table>"));
    }

    #[test]
    fn test_render_strikethrough() {
        let renderer = PulldownRenderer::new();
        let document = MarkdownDocument::new(
            "doc-5".to_string(),
            "~~strikethrough~~".to_string(),
            MarkdownOptions::default(),
        );

        let result = renderer.render(&document);
        assert!(result.is_ok());

        let output = result.unwrap();
        assert!(output.html().contains("<del>"));
    }

    #[test]
    fn test_renderer_info() {
        let renderer = PulldownRenderer::new();
        let info = renderer.renderer_info();

        assert_eq!(info.name, "pulldown-cmark");
        assert!(info.supports_gfm);
        assert!(info.supports_tables);
    }
}
