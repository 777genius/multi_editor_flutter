// Domain Layer - Value Objects
//
// Value Objects are immutable objects defined by their values, not identity.
// They are self-validating and have no side effects.
// Follow DDD principles.

pub mod search_query;
pub mod match_score;
pub mod file_path;

pub use search_query::SearchQuery;
pub use match_score::MatchScore;
pub use file_path::FilePath;
