// Application Layer
//
// Contains application-specific business rules.
// Orchestrates data flow between domain and infrastructure.
//
// Follow Clean Architecture:
// - Depends on domain layer (inward)
// - Infrastructure depends on this layer (outward)
// - Independent of frameworks and external concerns

pub mod dto;
pub mod use_cases;

// Re-export for convenience
pub use dto::{SearchRequest, SearchResponse, SearchOptionsDto, MatchDto, SearchStatisticsDto};
pub use use_cases::SearchFilesUseCase;
