/// HTML Output (Value Object)
///
/// Represents rendered HTML with metadata.
/// Immutable once created.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HtmlOutput {
    /// Rendered HTML content
    html: String,

    /// Estimated render time in milliseconds
    render_time_ms: u64,

    /// Number of Markdown elements processed
    element_count: usize,

    /// Whether any errors occurred during rendering
    has_warnings: bool,
}

impl HtmlOutput {
    /// Create new HTML output
    pub fn new(
        html: String,
        render_time_ms: u64,
        element_count: usize,
        has_warnings: bool,
    ) -> Self {
        Self {
            html,
            render_time_ms,
            element_count,
            has_warnings,
        }
    }

    /// Create empty output
    pub fn empty() -> Self {
        Self {
            html: String::new(),
            render_time_ms: 0,
            element_count: 0,
            has_warnings: false,
        }
    }

    // Getters
    pub fn html(&self) -> &str {
        &self.html
    }

    pub fn render_time_ms(&self) -> u64 {
        self.render_time_ms
    }

    pub fn element_count(&self) -> usize {
        self.element_count
    }

    pub fn has_warnings(&self) -> bool {
        self.has_warnings
    }

    /// Get HTML length in bytes
    pub fn byte_length(&self) -> usize {
        self.html.len()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_html_output() {
        let output = HtmlOutput::new(
            "<p>Hello</p>".to_string(),
            10,
            1,
            false,
        );

        assert_eq!(output.html(), "<p>Hello</p>");
        assert_eq!(output.render_time_ms(), 10);
        assert_eq!(output.element_count(), 1);
        assert!(!output.has_warnings());
    }

    #[test]
    fn test_empty_output() {
        let output = HtmlOutput::empty();
        assert_eq!(output.html(), "");
        assert_eq!(output.byte_length(), 0);
    }
}
