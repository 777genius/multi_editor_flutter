// Domain Layer - Value Objects
//
// Immutable value types with no identity.
// Follow DDD principles: self-validating, immutable, equality by value.

pub mod language;
pub mod position;
pub mod theme;

pub use language::Language;
pub use position::{Position, Range};
pub use theme::{Theme, HighlightStyle, Color};
