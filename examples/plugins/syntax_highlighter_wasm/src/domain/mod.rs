// Domain Layer
//
// Core business logic, entities, and abstractions.
// No dependencies on external libraries (except serde for serialization).
//
// Follows Clean Architecture principles:
// - Innermost layer
// - Defines contracts (traits) for services
// - Contains pure business logic

pub mod entities;
pub mod value_objects;
pub mod services;

// Re-export commonly used types
pub use entities::{SyntaxTree, HighlightRange, HighlightCollection};
pub use value_objects::{Language, Position, Range, Theme, Color, HighlightStyle};
pub use services::{Parser, Highlighter};
