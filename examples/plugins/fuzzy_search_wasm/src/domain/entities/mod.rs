// Domain Layer - Entities
//
// Entities are objects with identity and lifecycle.
// They are mutable and have business logic.
// Follow DDD principles.

pub mod fuzzy_match;
pub mod match_collection;

pub use fuzzy_match::FuzzyMatch;
pub use match_collection::{MatchCollection, CollectionStatistics};
