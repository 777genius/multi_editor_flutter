use crate::domain::{
    entities::{SyntaxTree, HighlightCollection},
    value_objects::Theme,
};

/// Highlighter Service (Port)
///
/// Defines contract for generating syntax highlights from syntax trees.
/// Domain layer defines interface, Infrastructure implements.
///
/// Follow SRP (Single Responsibility Principle) - only highlighting.
pub trait Highlighter {
    /// Generate highlights for syntax tree
    ///
    /// ## Arguments
    /// * `tree` - Parsed syntax tree
    /// * `theme` - Color theme for highlighting
    ///
    /// ## Returns
    /// * `Ok(HighlightCollection)` - Collection of highlighted ranges
    /// * `Err(String)` - Highlighting error
    fn highlight(
        &self,
        tree: &SyntaxTree,
        theme: &Theme,
    ) -> Result<HighlightCollection, String>;

    /// Get supported token types for introspection
    fn supported_token_types(&self) -> Vec<String> {
        vec![]
    }
}
