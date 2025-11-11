use serde::{Deserialize, Serialize};

/// Language Value Object
///
/// Represents a programming language with validation.
/// Immutable, self-validating (SOLID: SRP).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Language {
    Rust,
    Dart,
    JavaScript,
    TypeScript,
    Json,
    Markdown,
    Unknown,
}

impl Language {
    /// Parse language from string (factory method)
    pub fn from_str(s: &str) -> Self {
        match s.to_lowercase().as_str() {
            "rust" | "rs" => Language::Rust,
            "dart" => Language::Dart,
            "javascript" | "js" => Language::JavaScript,
            "typescript" | "ts" => Language::TypeScript,
            "json" => Language::Json,
            "markdown" | "md" => Language::Markdown,
            _ => Language::Unknown,
        }
    }

    /// Get file extension
    pub fn extension(&self) -> &'static str {
        match self {
            Language::Rust => "rs",
            Language::Dart => "dart",
            Language::JavaScript => "js",
            Language::TypeScript => "ts",
            Language::Json => "json",
            Language::Markdown => "md",
            Language::Unknown => "txt",
        }
    }

    /// Check if language is supported for syntax highlighting
    pub fn is_supported(&self) -> bool {
        !matches!(self, Language::Unknown)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_language_parsing() {
        assert_eq!(Language::from_str("rust"), Language::Rust);
        assert_eq!(Language::from_str("RS"), Language::Rust);
        assert_eq!(Language::from_str("unknown"), Language::Unknown);
    }

    #[test]
    fn test_is_supported() {
        assert!(Language::Rust.is_supported());
        assert!(!Language::Unknown.is_supported());
    }
}
