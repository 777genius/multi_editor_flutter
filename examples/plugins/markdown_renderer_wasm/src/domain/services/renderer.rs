use crate::domain::{
    entities::MarkdownDocument,
    value_objects::HtmlOutput,
};

/// Renderer Service (Port)
///
/// Defines contract for rendering markdown to HTML.
/// Domain layer defines interface, Infrastructure implements.
///
/// Follow ISP (Interface Segregation Principle) - minimal interface.
pub trait Renderer {
    /// Render markdown document to HTML
    ///
    /// ## Arguments
    /// * `document` - Markdown document to render
    ///
    /// ## Returns
    /// * `Ok(HtmlOutput)` - Successfully rendered HTML
    /// * `Err(String)` - Render error message
    fn render(&self, document: &MarkdownDocument) -> Result<HtmlOutput, String>;

    /// Check if renderer supports given markdown features
    fn supports_github_flavored_markdown(&self) -> bool {
        true
    }

    /// Get renderer name/version (for debugging)
    fn renderer_info(&self) -> RendererInfo {
        RendererInfo::default()
    }
}

/// Renderer Information (Value Object)
#[derive(Debug, Clone, Default)]
pub struct RendererInfo {
    pub name: String,
    pub version: String,
    pub supports_gfm: bool,
    pub supports_tables: bool,
    pub supports_footnotes: bool,
}

impl RendererInfo {
    pub fn new(
        name: String,
        version: String,
        supports_gfm: bool,
        supports_tables: bool,
        supports_footnotes: bool,
    ) -> Self {
        Self {
            name,
            version,
            supports_gfm,
            supports_tables,
            supports_footnotes,
        }
    }
}
