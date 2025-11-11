use crate::domain::{Parser, SyntaxTree, Language};
use crate::domain::services::ParserStatistics;
use syntect::parsing::SyntaxSet;

/// Syntect Parser Adapter
///
/// Implements Parser trait using Syntect library (TextMate grammars).
/// Follow Adapter pattern: adapts external library to domain interface.
pub struct SyntectParser {
    /// Syntax set with all supported languages
    syntax_set: SyntaxSet,

    /// Statistics for monitoring
    stats: ParserStatistics,
}

impl SyntectParser {
    /// Create new Syntect parser with default syntax set
    pub fn new() -> Self {
        Self {
            syntax_set: SyntaxSet::load_defaults_newlines(),
            stats: ParserStatistics::default(),
        }
    }

    /// Get syntax by language
    fn get_syntax_for_language(&self, language: Language) -> Option<&syntect::parsing::SyntaxReference> {
        let extension = language.extension();
        self.syntax_set.find_syntax_by_extension(extension)
    }

    /// Generate unique ID for syntax tree
    fn generate_tree_id(source_code: &str) -> String {
        // Simple hash based on length and first/last chars
        let len = source_code.len();
        let first = source_code.chars().next().unwrap_or('_');
        let last = source_code.chars().last().unwrap_or('_');
        format!("tree_{}_{}_{}", len, first as u32, last as u32)
    }

    /// Parse with Syntect and count tokens
    fn count_tokens(&self, source_code: &str, syntax: &syntect::parsing::SyntaxReference) -> usize {
        use syntect::parsing::ParseState;

        let mut parse_state = ParseState::new(syntax);
        let mut token_count = 0;

        for line in source_code.lines() {
            let ops = parse_state.parse_line(line, &self.syntax_set).unwrap_or_default();
            token_count += ops.len();
        }

        token_count
    }
}

impl Default for SyntectParser {
    fn default() -> Self {
        Self::new()
    }
}

impl Parser for SyntectParser {
    fn parse(&self, language: Language, source_code: &str) -> Result<SyntaxTree, String> {
        // Get syntax for language
        let syntax = self.get_syntax_for_language(language)
            .ok_or_else(|| format!("No syntax found for language: {:?}", language))?;

        // Count tokens (as proxy for node count)
        let token_count = self.count_tokens(source_code, syntax);

        // Syntect doesn't have error recovery, so we assume no errors
        let has_errors = false;

        // Generate tree ID
        let tree_id = Self::generate_tree_id(source_code);

        // Create domain SyntaxTree entity
        Ok(SyntaxTree::new(
            tree_id,
            language,
            source_code.to_string(),
            syntax.name.clone(),
            token_count,
            has_errors,
        ))
    }

    fn supports_language(&self, language: Language) -> bool {
        self.get_syntax_for_language(language).is_some()
    }

    fn get_statistics(&self) -> ParserStatistics {
        self.stats.clone()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rust_parsing() {
        let parser = SyntectParser::new();
        let result = parser.parse(Language::Rust, "fn main() {}");

        assert!(result.is_ok());
        let tree = result.unwrap();
        assert_eq!(tree.language(), Language::Rust);
        assert!(!tree.has_errors());
    }

    #[test]
    fn test_language_support() {
        let parser = SyntectParser::new();

        assert!(parser.supports_language(Language::Rust));
        assert!(parser.supports_language(Language::JavaScript));
        assert!(parser.supports_language(Language::Json));
    }

    #[test]
    fn test_token_counting() {
        let parser = SyntectParser::new();
        let result = parser.parse(Language::Rust, "fn main() {\n    let x = 42;\n}");

        assert!(result.is_ok());
        let tree = result.unwrap();
        let stats = tree.statistics();
        assert!(stats.node_count > 0); // Should have some tokens
    }
}
