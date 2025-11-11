// Domain Layer
//
// Pure business logic with no external dependencies.
// Follow Clean Architecture: this layer doesn't know about
// databases, UI, frameworks, or external libraries.
//
// Follow DDD (Domain-Driven Design):
// - Entities: Objects with identity and lifecycle
// - Value Objects: Immutable objects defined by their values
// - Aggregates: Clusters of entities and value objects
// - Services: Operations that don't belong to entities

pub mod entities;
pub mod value_objects;
pub mod services;

// Re-export main types for convenience
pub use entities::{FuzzyMatch, MatchCollection, CollectionStatistics};
pub use value_objects::{SearchQuery, MatchScore, FilePath};
pub use services::{FuzzyMatcher, MatcherInfo};
