// Infrastructure Layer
//
// External library adapters and concrete implementations.
// Depends on Domain layer (implements interfaces).
// Provides concrete implementations of domain services.

pub mod syntect;
pub mod memory;

// Re-export for convenience
pub use syntect::{SyntectParser, SyntectHighlighter};
pub use memory::{alloc, dealloc, serialize_and_pack};
