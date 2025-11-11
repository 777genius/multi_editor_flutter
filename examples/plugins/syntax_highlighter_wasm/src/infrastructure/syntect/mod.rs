// Infrastructure Layer - Syntect Integration
//
// Implements domain services using Syntect library (TextMate grammars).
// Adapter pattern: adapts Syntect API to domain interfaces.

pub mod syntect_parser;
pub mod syntect_highlighter;

pub use syntect_parser::SyntectParser;
pub use syntect_highlighter::SyntectHighlighter;
