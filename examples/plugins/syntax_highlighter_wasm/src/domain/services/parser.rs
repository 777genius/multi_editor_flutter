use crate::domain::{
    entities::SyntaxTree,
    value_objects::Language,
};

/// Parser Service (Port)
///
/// Defines contract for parsing source code into syntax trees.
/// Domain layer defines interface, Infrastructure implements.
///
/// Follow ISP (Interface Segregation Principle) - minimal interface.
pub trait Parser {
    /// Parse source code into syntax tree
    ///
    /// ## Arguments
    /// * `language` - Programming language
    /// * `source_code` - Source code to parse
    ///
    /// ## Returns
    /// * `Ok(SyntaxTree)` - Successfully parsed tree
    /// * `Err(String)` - Parse error message
    fn parse(&self, language: Language, source_code: &str) -> Result<SyntaxTree, String>;

    /// Check if language is supported
    fn supports_language(&self, language: Language) -> bool;

    /// Get parser statistics (optional, for monitoring)
    fn get_statistics(&self) -> ParserStatistics {
        ParserStatistics::default()
    }
}

/// Parser Statistics
///
/// Metrics about parser performance and usage.
#[derive(Debug, Clone, Default)]
pub struct ParserStatistics {
    pub total_parses: usize,
    pub total_bytes_parsed: usize,
    pub average_parse_time_ms: f64,
}
