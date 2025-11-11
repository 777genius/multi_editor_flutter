// Application Layer
//
// Business logic and use cases.
// Orchestrates domain operations.
//
// Depends on:
// - Domain layer (entities, services)
// Does NOT depend on:
// - Infrastructure (Tree-sitter, memory management)
// - Presentation (WASM exports)

pub mod use_cases;
pub mod dto;

// Re-export for convenience
pub use use_cases::HighlightCodeUseCase;
pub use dto::{ParseRequest, HighlightResponse, HighlightRangeDto};
