use serde::{Deserialize, Serialize};

/// Color Value Object (RGB)
///
/// Immutable, self-validating color representation.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct Color {
    pub r: u8,
    pub g: u8,
    pub b: u8,
}

impl Color {
    pub const fn new(r: u8, g: u8, b: u8) -> Self {
        Self { r, g, b }
    }

    /// Parse from hex string (#RRGGBB)
    pub fn from_hex(hex: &str) -> Result<Self, String> {
        let hex = hex.trim_start_matches('#');
        if hex.len() != 6 {
            return Err("Invalid hex color format".to_string());
        }

        let r = u8::from_str_radix(&hex[0..2], 16)
            .map_err(|_| "Invalid red component")?;
        let g = u8::from_str_radix(&hex[2..4], 16)
            .map_err(|_| "Invalid green component")?;
        let b = u8::from_str_radix(&hex[4..6], 16)
            .map_err(|_| "Invalid blue component")?;

        Ok(Self::new(r, g, b))
    }

    /// Convert to hex string
    pub fn to_hex(&self) -> String {
        format!("#{:02X}{:02X}{:02X}", self.r, self.g, self.b)
    }
}

/// Highlight Style Value Object
///
/// Defines visual style for syntax tokens.
/// Immutable, composable (SOLID: OCP).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct HighlightStyle {
    /// Token type (keyword, string, comment, etc.)
    pub token_type: String,

    /// Foreground color
    pub color: Color,

    /// Optional: bold, italic, underline
    pub bold: bool,
    pub italic: bool,
}

impl HighlightStyle {
    pub fn new(token_type: impl Into<String>, color: Color) -> Self {
        Self {
            token_type: token_type.into(),
            color,
            bold: false,
            italic: false,
        }
    }

    /// Builder pattern for optional attributes
    pub fn with_bold(mut self) -> Self {
        self.bold = true;
        self
    }

    pub fn with_italic(mut self) -> Self {
        self.italic = true;
        self
    }
}

/// Theme Value Object (Aggregate of styles)
///
/// Collection of highlight styles for different token types.
/// Immutable, extensible (DDD: Aggregate Root).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Theme {
    pub name: String,
    pub styles: Vec<HighlightStyle>,
}

impl Theme {
    /// Create default dark theme (VS Code inspired)
    pub fn dark_default() -> Self {
        Self {
            name: "Dark Default".to_string(),
            styles: vec![
                HighlightStyle::new("keyword", Color::new(86, 156, 214)).with_bold(),
                HighlightStyle::new("function", Color::new(220, 220, 170)),
                HighlightStyle::new("string", Color::new(206, 145, 120)),
                HighlightStyle::new("number", Color::new(181, 206, 168)),
                HighlightStyle::new("comment", Color::new(106, 153, 85)).with_italic(),
                HighlightStyle::new("type", Color::new(78, 201, 176)),
                HighlightStyle::new("variable", Color::new(156, 220, 254)),
                HighlightStyle::new("operator", Color::new(212, 212, 212)),
            ],
        }
    }

    /// Get style for token type
    pub fn get_style(&self, token_type: &str) -> Option<&HighlightStyle> {
        self.styles.iter().find(|s| s.token_type == token_type)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_color_hex_conversion() {
        let color = Color::new(255, 128, 64);
        let hex = color.to_hex();
        assert_eq!(hex, "#FF8040");

        let parsed = Color::from_hex(&hex).unwrap();
        assert_eq!(parsed, color);
    }

    #[test]
    fn test_theme_get_style() {
        let theme = Theme::dark_default();
        let keyword_style = theme.get_style("keyword");

        assert!(keyword_style.is_some());
        assert!(keyword_style.unwrap().bold);
    }
}
