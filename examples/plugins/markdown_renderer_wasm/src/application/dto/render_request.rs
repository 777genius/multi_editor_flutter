use serde::{Deserialize, Serialize};

/// Render Request DTO
///
/// Input data transfer object for markdown rendering.
/// Serializable for WASM communication.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RenderRequest {
    /// Unique request ID (for tracking)
    pub request_id: String,

    /// Markdown content to render
    pub markdown: String,

    /// Rendering options
    pub options: RenderOptionsDto,
}

/// Render Options DTO
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RenderOptionsDto {
    /// Enable GitHub Flavored Markdown
    #[serde(default = "default_true")]
    pub enable_gfm: bool,

    /// Enable syntax highlighting for code blocks
    #[serde(default = "default_true")]
    pub enable_syntax_highlighting: bool,

    /// Enable table support
    #[serde(default = "default_true")]
    pub enable_tables: bool,

    /// Enable strikethrough support
    #[serde(default = "default_true")]
    pub enable_strikethrough: bool,

    /// Enable task lists
    #[serde(default = "default_true")]
    pub enable_task_lists: bool,

    /// Maximum heading level (1-6)
    #[serde(default = "default_max_heading")]
    pub max_heading_level: u8,
}

fn default_true() -> bool {
    true
}

fn default_max_heading() -> u8 {
    6
}

impl Default for RenderOptionsDto {
    fn default() -> Self {
        Self {
            enable_gfm: true,
            enable_syntax_highlighting: true,
            enable_tables: true,
            enable_strikethrough: true,
            enable_task_lists: true,
            max_heading_level: 6,
        }
    }
}

impl RenderRequest {
    /// Create new render request
    pub fn new(request_id: String, markdown: String) -> Self {
        Self {
            request_id,
            markdown,
            options: RenderOptionsDto::default(),
        }
    }

    /// Create with custom options
    pub fn with_options(
        request_id: String,
        markdown: String,
        options: RenderOptionsDto,
    ) -> Self {
        Self {
            request_id,
            markdown,
            options,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_render_request_creation() {
        let req = RenderRequest::new(
            "req-1".to_string(),
            "# Hello".to_string(),
        );

        assert_eq!(req.request_id, "req-1");
        assert!(req.options.enable_gfm);
    }

    #[test]
    fn test_serde() {
        let req = RenderRequest::new(
            "req-2".to_string(),
            "**bold**".to_string(),
        );

        let json = serde_json::to_string(&req).unwrap();
        let deserialized: RenderRequest = serde_json::from_str(&json).unwrap();

        assert_eq!(deserialized.request_id, req.request_id);
        assert_eq!(deserialized.markdown, req.markdown);
    }
}
