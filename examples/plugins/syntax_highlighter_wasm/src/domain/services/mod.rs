// Domain Layer - Services (Ports)
//
// Abstract interfaces for domain operations.
// Follow DIP (Dependency Inversion Principle):
// - Domain defines interfaces
// - Infrastructure implements them
// - Application uses abstractions

pub mod parser;
pub mod highlighter;

pub use parser::{Parser, ParserStatistics};
pub use highlighter::Highlighter;
