// Application DTOs - Data Transfer Objects

use serde::{Deserialize, Serialize};
use crate::domain::{TodoCollection, Language};

/// Request to scan source code for TODOs
#[derive(Debug, Deserialize)]
pub struct ScanRequest {
    /// Unique request ID for tracking
    pub request_id: String,

    /// Source code content to scan
    pub content: String,

    /// Programming language (optional, will be detected if not provided)
    pub language: Option<String>,

    /// File extension (optional, for language detection)
    pub file_extension: Option<String>,
}

impl ScanRequest {
    pub fn new(request_id: String, content: String) -> Self {
        Self {
            request_id,
            content,
            language: None,
            file_extension: None,
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
                "ruby" | "rb" => Language::Ruby,
                "php" => Language::PHP,
                "swift" => Language::Swift,
                "kotlin" | "kt" => Language::Kotlin,
                _ => Language::Unknown,
            };
        }

        // Try to detect from file extension
        if let Some(ref ext) = self.file_extension {
            return Language::from_extension(ext);
        }

        Language::Unknown
    }
}

/// Response containing scanned TODOs
#[derive(Debug, Serialize)]
pub struct ScanResponse {
    /// Request ID for tracking
    pub request_id: String,

    /// Success flag
    pub success: bool,

    /// Error message if failed
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,

    /// Scanned TODOs
    #[serde(skip_serializing_if = "Option::is_none")]
    pub data: Option<TodoCollection>,
}

impl ScanResponse {
    pub fn success(request_id: String, data: TodoCollection) -> Self {
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
