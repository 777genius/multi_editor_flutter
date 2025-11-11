/// Markdown Rendering Options (Value Object)
///
/// Immutable configuration for markdown rendering.
/// Follow DDD: Value Objects are immutable and self-validating.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct MarkdownOptions {
    /// Enable GitHub Flavored Markdown extensions
    enable_gfm: bool,

    /// Enable syntax highlighting for code blocks
    enable_syntax_highlighting: bool,

    /// Enable table support
    enable_tables: bool,

    /// Enable strikethrough support
    enable_strikethrough: bool,

    /// Enable task lists (- [ ] and - [x])
    enable_task_lists: bool,

    /// Maximum heading level to render (1-6)
    max_heading_level: u8,
}

impl MarkdownOptions {
    /// Create new options with validation
    pub fn new(
        enable_gfm: bool,
        enable_syntax_highlighting: bool,
        enable_tables: bool,
        enable_strikethrough: bool,
        enable_task_lists: bool,
        max_heading_level: u8,
    ) -> Result<Self, String> {
        // Validate max_heading_level
        if max_heading_level < 1 || max_heading_level > 6 {
            return Err(format!(
                "max_heading_level must be 1-6, got: {}",
                max_heading_level
            ));
        }

        Ok(Self {
            enable_gfm,
            enable_syntax_highlighting,
            enable_tables,
            enable_strikethrough,
            enable_task_lists,
            max_heading_level,
        })
    }

    /// Create default options
    pub fn default_options() -> Self {
        Self {
            enable_gfm: true,
            enable_syntax_highlighting: true,
            enable_tables: true,
            enable_strikethrough: true,
            enable_task_lists: true,
            max_heading_level: 6,
        }
    }

    /// Create minimal options (CommonMark only)
    pub fn minimal() -> Self {
        Self {
            enable_gfm: false,
            enable_syntax_highlighting: false,
            enable_tables: false,
            enable_strikethrough: false,
            enable_task_lists: false,
            max_heading_level: 6,
        }
    }

    // Getters
    pub fn enable_gfm(&self) -> bool {
        self.enable_gfm
    }

    pub fn enable_syntax_highlighting(&self) -> bool {
        self.enable_syntax_highlighting
    }

    pub fn enable_tables(&self) -> bool {
        self.enable_tables
    }

    pub fn enable_strikethrough(&self) -> bool {
        self.enable_strikethrough
    }

    pub fn enable_task_lists(&self) -> bool {
        self.enable_task_lists
    }

    pub fn max_heading_level(&self) -> u8 {
        self.max_heading_level
    }
}

impl Default for MarkdownOptions {
    fn default() -> Self {
        Self::default_options()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_valid_options() {
        let opts = MarkdownOptions::new(true, true, true, true, true, 3);
        assert!(opts.is_ok());
    }

    #[test]
    fn test_invalid_heading_level() {
        let opts = MarkdownOptions::new(true, true, true, true, true, 0);
        assert!(opts.is_err());

        let opts = MarkdownOptions::new(true, true, true, true, true, 7);
        assert!(opts.is_err());
    }

    #[test]
    fn test_default_options() {
        let opts = MarkdownOptions::default();
        assert!(opts.enable_gfm());
        assert_eq!(opts.max_heading_level(), 6);
    }
}
