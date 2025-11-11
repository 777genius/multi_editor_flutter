// Domain Layer - Services
//
// Domain Services represent operations that don't naturally fit within entities.
// They are defined as traits (interfaces) to maintain Dependency Inversion.
// Infrastructure layer provides concrete implementations.

pub mod fuzzy_matcher;

pub use fuzzy_matcher::{FuzzyMatcher, MatcherInfo};
