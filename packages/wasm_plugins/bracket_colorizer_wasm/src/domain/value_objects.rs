// Domain Value Objects - Immutable domain primitives

use serde::{Deserialize, Serialize};

/// Type of bracket
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum BracketType {
    /// Round brackets ()
    Round,
    /// Curly brackets {}
    Curly,
    /// Square brackets []
    Square,
    /// Angle brackets <>
    Angle,
}

impl BracketType {
    /// Get all supported bracket types
    pub fn all() -> Vec<BracketType> {
        vec![
            BracketType::Round,
            BracketType::Curly,
            BracketType::Square,
            BracketType::Angle,
        ]
    }

    /// Get opening character
    pub fn opening_char(&self) -> char {
        match self {
            BracketType::Round => '(',
            BracketType::Curly => '{',
            BracketType::Square => '[',
            BracketType::Angle => '<',
        }
    }

    /// Get closing character
    pub fn closing_char(&self) -> char {
        match self {
            BracketType::Round => ')',
            BracketType::Curly => '}',
            BracketType::Square => ']',
            BracketType::Angle => '>',
        }
    }

    /// Check if character is opening bracket of this type
    pub fn is_opening(&self, ch: char) -> bool {
        ch == self.opening_char()
    }

    /// Check if character is closing bracket of this type
    pub fn is_closing(&self, ch: char) -> bool {
        ch == self.closing_char()
    }

    /// Detect bracket type from character
    pub fn from_char(ch: char) -> Option<(BracketType, BracketSide)> {
        match ch {
            '(' => Some((BracketType::Round, BracketSide::Opening)),
            ')' => Some((BracketType::Round, BracketSide::Closing)),
            '{' => Some((BracketType::Curly, BracketSide::Opening)),
            '}' => Some((BracketType::Curly, BracketSide::Closing)),
            '[' => Some((BracketType::Square, BracketSide::Opening)),
            ']' => Some((BracketType::Square, BracketSide::Closing)),
            '<' => Some((BracketType::Angle, BracketSide::Opening)),
            '>' => Some((BracketType::Angle, BracketSide::Closing)),
            _ => None,
        }
    }

    /// Display name
    pub fn display_name(&self) -> &str {
        match self {
            BracketType::Round => "Round ()",
            BracketType::Curly => "Curly {}",
            BracketType::Square => "Square []",
            BracketType::Angle => "Angle <>",
        }
    }
}

/// Side of bracket (opening or closing)
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum BracketSide {
    Opening,
    Closing,
}

/// Position in source code
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct Position {
    /// Line number (0-indexed)
    pub line: u32,
    /// Column number (0-indexed)
    pub column: u32,
    /// Byte offset from start of file
    pub offset: u32,
}

impl Position {
    pub fn new(line: u32, column: u32, offset: u32) -> Self {
        Self {
            line,
            column,
            offset,
        }
    }

    /// Create from byte offset (simplified version)
    pub fn from_offset(offset: u32) -> Self {
        Self {
            line: 0,
            column: 0,
            offset,
        }
    }
}

impl PartialOrd for Position {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for Position {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        self.offset.cmp(&other.offset)
    }
}

/// Color level (depth-based color assignment)
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct ColorLevel(pub u8);

impl ColorLevel {
    pub fn new(level: u8) -> Self {
        Self(level)
    }

    /// Get color level from nesting depth
    /// Cycles through colors (e.g., 6 colors: levels 0-5, then repeats)
    pub fn from_depth(depth: usize, max_colors: usize) -> Self {
        Self((depth % max_colors) as u8)
    }

    /// Get the level value
    pub fn value(&self) -> u8 {
        self.0
    }
}

/// Rainbow color scheme
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ColorScheme {
    /// List of colors in hex format (#RRGGBB)
    pub colors: Vec<String>,
    /// Whether to enable rainbow colors
    pub enabled: bool,
    /// Maximum nesting depth to highlight
    pub max_depth: usize,
}

impl ColorScheme {
    /// Default rainbow colors
    pub fn default_rainbow() -> Self {
        Self {
            colors: vec![
                "#FFD700".to_string(), // Gold
                "#DA70D6".to_string(), // Orchid
                "#179FFF".to_string(), // Sky Blue
                "#FF6347".to_string(), // Tomato
                "#3CB371".to_string(), // Medium Sea Green
                "#FF8C00".to_string(), // Dark Orange
            ],
            enabled: true,
            max_depth: 100,
        }
    }

    /// Monochrome scheme (single color)
    pub fn monochrome(color: String) -> Self {
        Self {
            colors: vec![color],
            enabled: true,
            max_depth: 100,
        }
    }

    /// Get color for a given depth level
    pub fn color_for_level(&self, level: ColorLevel) -> &str {
        if self.colors.is_empty() {
            return "#FFFFFF"; // Fallback white
        }
        let index = (level.value() as usize) % self.colors.len();
        &self.colors[index]
    }

    /// Number of colors in scheme
    pub fn color_count(&self) -> usize {
        self.colors.len()
    }
}

impl Default for ColorScheme {
    fn default() -> Self {
        Self::default_rainbow()
    }
}

/// Language type for context-aware parsing
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
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
    Generic,
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
            _ => Language::Generic,
        }
    }

    /// Check if language uses angle brackets as operators (not brackets)
    /// e.g., Rust: Vec<T>, C++: std::vector<int>
    pub fn uses_angle_brackets_as_generics(&self) -> bool {
        matches!(
            self,
            Language::Rust | Language::Cpp | Language::Java | Language::TypeScript | Language::CSharp
        )
    }

    /// Check if language has significant whitespace in strings
    pub fn has_significant_whitespace(&self) -> bool {
        matches!(self, Language::Python)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_bracket_type_detection() {
        assert_eq!(
            BracketType::from_char('('),
            Some((BracketType::Round, BracketSide::Opening))
        );
        assert_eq!(
            BracketType::from_char(')'),
            Some((BracketType::Round, BracketSide::Closing))
        );
        assert_eq!(
            BracketType::from_char('{'),
            Some((BracketType::Curly, BracketSide::Opening))
        );
        assert_eq!(BracketType::from_char('x'), None);
    }

    #[test]
    fn test_color_level_cycling() {
        let level0 = ColorLevel::from_depth(0, 6);
        let level6 = ColorLevel::from_depth(6, 6);
        let level7 = ColorLevel::from_depth(7, 6);

        assert_eq!(level0.value(), 0);
        assert_eq!(level6.value(), 0); // Cycles back
        assert_eq!(level7.value(), 1);
    }

    #[test]
    fn test_color_scheme() {
        let scheme = ColorScheme::default_rainbow();
        assert_eq!(scheme.colors.len(), 6);
        assert_eq!(scheme.color_for_level(ColorLevel::new(0)), "#FFD700");
        assert_eq!(scheme.color_for_level(ColorLevel::new(1)), "#DA70D6");
    }

    #[test]
    fn test_position_ordering() {
        let pos1 = Position::new(0, 0, 0);
        let pos2 = Position::new(0, 5, 5);
        let pos3 = Position::new(1, 0, 10);

        assert!(pos1 < pos2);
        assert!(pos2 < pos3);
    }

    #[test]
    fn test_language_detection() {
        assert_eq!(Language::from_extension("rs"), Language::Rust);
        assert_eq!(Language::from_extension("dart"), Language::Dart);
        assert_eq!(Language::from_extension("unknown"), Language::Generic);
    }
}
