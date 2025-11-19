// Application DTOs - Data Transfer Objects

use serde::{Deserialize, Serialize};
use crate::domain::{BracketCollection, ColorScheme, Language};

/// Request to analyze brackets in source code
#[derive(Debug, Deserialize)]
pub struct AnalyzeRequest {
    /// Unique request ID for tracking
    pub request_id: String,

    /// Source code content to analyze
    pub content: String,

    /// Programming language (optional, will be detected if not provided)
    pub language: Option<String>,

    /// File extension (optional, for language detection)
    pub file_extension: Option<String>,

    /// Color scheme (optional, uses default rainbow if not provided)
    pub color_scheme: Option<ColorScheme>,

    /// Maximum depth to analyze (optional, default 100)
    pub max_depth: Option<usize>,
}

impl AnalyzeRequest {
    pub fn new(request_id: String, content: String) -> Self {
        Self {
            request_id,
            content,
            language: None,
            file_extension: None,
            color_scheme: None,
            max_depth: None,
        }
    }

    pub fn with_language(mut self, language: String) -> Self {
        self.language = Some(language);
        self
    }

    pub fn with_file_extension(mut self, ext: String) -> Self {
        self.file_extension = Some(ext);
        self
    }

    pub fn with_color_scheme(mut self, scheme: ColorScheme) -> Self {
        self.color_scheme = Some(scheme);
        self
    }

    /// Detect language from request data
    pub fn detect_language(&self) -> Language {
        // If language is explicitly provided, use it
        if let Some(ref lang) = self.language {
            return match lang.to_lowercase().as_str() {
                "dart" => Language::Dart,
                "javascript" | "js" => Language::JavaScript,
                "typescript" | "ts" => Language::TypeScript,
                "python" | "py" => Language::Python,
                "rust" | "rs" => Language::Rust,
                "go" => Language::Go,
                "java" => Language::Java,
                "csharp" | "cs" => Language::CSharp,
                "cpp" | "c++" => Language::Cpp,
                "c" => Language::C,
                _ => Language::Generic,
            };
        }

        // Try to detect from file extension
        if let Some(ref ext) = self.file_extension {
            return Language::from_extension(ext);
        }

        Language::Generic
    }

    /// Get color scheme or default
    pub fn get_color_scheme(&self) -> ColorScheme {
        self.color_scheme
            .clone()
            .unwrap_or_else(ColorScheme::default_rainbow)
    }
}

/// Response containing bracket analysis
#[derive(Debug, Serialize)]
pub struct AnalyzeResponse {
    /// Request ID for tracking
    pub request_id: String,

    /// Success flag
    pub success: bool,

    /// Error message if failed
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,

    /// Bracket analysis result
    #[serde(skip_serializing_if = "Option::is_none")]
    pub data: Option<BracketCollection>,
}

impl AnalyzeResponse {
    pub fn success(request_id: String, data: BracketCollection) -> Self {
        Self {
            request_id,
            success: true,
            error: None,
            data: Some(data),
        }
    }

    pub fn error(request_id: String, error: String) -> Self {
        Self {
            request_id,
            success: false,
            error: Some(error),
            data: None,
        }
    }
}

/// Request to get color for a specific position
#[derive(Debug, Deserialize)]
pub struct GetColorRequest {
    pub request_id: String,
    pub line: u32,
    pub column: u32,
}

/// Response with color information
#[derive(Debug, Serialize)]
pub struct GetColorResponse {
    pub request_id: String,
    pub success: bool,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub color: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub depth: Option<usize>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub bracket_type: Option<String>,
}
