// Domain Value Objects - Immutable domain primitives

use serde::{Deserialize, Serialize};

/// Type of TODO marker
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
#[serde(rename_all = "UPPERCASE")]
pub enum TodoType {
    Todo,
    Fixme,
    Hack,
    Note,
    Xxx,
    Bug,
    Optimize,
    Review,
}

impl TodoType {
    /// Get all supported TODO types
    pub fn all() -> Vec<TodoType> {
        vec![
            TodoType::Todo,
            TodoType::Fixme,
            TodoType::Hack,
            TodoType::Note,
            TodoType::Xxx,
            TodoType::Bug,
            TodoType::Optimize,
            TodoType::Review,
        ]
    }

    /// Get regex pattern for this TODO type
    pub fn pattern(&self) -> &str {
        match self {
            TodoType::Todo => r"(?i)TODO",
            TodoType::Fixme => r"(?i)FIXME",
            TodoType::Hack => r"(?i)HACK",
            TodoType::Note => r"(?i)NOTE",
            TodoType::Xxx => r"XXX",
            TodoType::Bug => r"(?i)BUG",
            TodoType::Optimize => r"(?i)OPTIMIZE",
            TodoType::Review => r"(?i)REVIEW",
        }
    }

    /// Get display name
    pub fn display_name(&self) -> &str {
        match self {
            TodoType::Todo => "TODO",
            TodoType::Fixme => "FIXME",
            TodoType::Hack => "HACK",
            TodoType::Note => "NOTE",
            TodoType::Xxx => "XXX",
            TodoType::Bug => "BUG",
            TodoType::Optimize => "OPTIMIZE",
            TodoType::Review => "REVIEW",
        }
    }

    /// Get default priority for this TODO type
    pub fn default_priority(&self) -> TodoPriority {
        match self {
            TodoType::Fixme | TodoType::Bug => TodoPriority::High,
            TodoType::Todo | TodoType::Hack | TodoType::Optimize | TodoType::Review => TodoPriority::Medium,
            TodoType::Note | TodoType::Xxx => TodoPriority::Low,
        }
    }
}

/// Priority level of a TODO item
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub enum TodoPriority {
    High = 3,
    Medium = 2,
    Low = 1,
}

impl TodoPriority {
    pub fn as_str(&self) -> &str {
        match self {
            TodoPriority::High => "high",
            TodoPriority::Medium => "medium",
            TodoPriority::Low => "low",
        }
    }
}

/// Position in source code
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct Position {
    pub line: u32,
    pub column: u32,
}

impl Position {
    pub fn new(line: u32, column: u32) -> Self {
        Self { line, column }
    }
}

/// Language type (for language-specific comment parsing)
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum Language {
    Dart,
    JavaScript,
    TypeScript,
    Python,
    Rust,
    Go,
    Java,
    CSharp,
    Cpp,
    C,
    Ruby,
    PHP,
    Swift,
    Kotlin,
    Unknown,
}

impl Language {
    /// Detect language from file extension
    pub fn from_extension(ext: &str) -> Self {
        match ext.to_lowercase().as_str() {
            "dart" => Language::Dart,
            "js" | "jsx" | "mjs" | "cjs" => Language::JavaScript,
            "ts" | "tsx" => Language::TypeScript,
            "py" | "pyw" => Language::Python,
            "rs" => Language::Rust,
            "go" => Language::Go,
            "java" => Language::Java,
            "cs" => Language::CSharp,
            "cpp" | "cc" | "cxx" | "hpp" | "hxx" => Language::Cpp,
            "c" | "h" => Language::C,
            "rb" => Language::Ruby,
            "php" => Language::PHP,
            "swift" => Language::Swift,
            "kt" | "kts" => Language::Kotlin,
            _ => Language::Unknown,
        }
    }

    /// Get comment patterns for this language
    pub fn comment_patterns(&self) -> CommentPatterns {
        match self {
            Language::Dart
            | Language::JavaScript
            | Language::TypeScript
            | Language::Rust
            | Language::Go
            | Language::Java
            | Language::CSharp
            | Language::Cpp
            | Language::C
            | Language::Swift
            | Language::Kotlin
            | Language::PHP => CommentPatterns {
                single_line: vec!["//"],
                multi_line_start: vec!["/*"],
                multi_line_end: vec!["*/"],
            },
            Language::Python | Language::Ruby => CommentPatterns {
                single_line: vec!["#"],
                multi_line_start: vec!["\"\"\"", "'''"],
                multi_line_end: vec!["\"\"\"", "'''"],
            },
            Language::Unknown => CommentPatterns {
                single_line: vec!["//", "#"],
                multi_line_start: vec!["/*"],
                multi_line_end: vec!["*/"],
            },
        }
    }
}

/// Comment patterns for a language
#[derive(Debug, Clone)]
pub struct CommentPatterns {
    pub single_line: Vec<&'static str>,
    pub multi_line_start: Vec<&'static str>,
    pub multi_line_end: Vec<&'static str>,
}
