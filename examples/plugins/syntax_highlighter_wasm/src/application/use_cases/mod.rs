// Application Layer - Use Cases
//
// Business logic orchestration.
// Use domain services to perform operations.
// Follow SRP - each use case does one thing.

pub mod highlight_code;

pub use highlight_code::HighlightCodeUseCase;
