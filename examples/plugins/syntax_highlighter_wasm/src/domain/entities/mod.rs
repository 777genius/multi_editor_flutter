// Domain Layer - Entities
//
// Entities have identity and mutable state.
// Represent core business objects.

pub mod syntax_tree;
pub mod highlight_range;

pub use syntax_tree::SyntaxTree;
pub use highlight_range::{HighlightRange, HighlightCollection};
