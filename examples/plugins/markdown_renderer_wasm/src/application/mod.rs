// Application Layer
//
// Contains application-specific business rules.
// Orchestrates data flow between domain and infrastructure.

pub mod dto;
pub mod use_cases;

// Re-export for convenience
pub use dto::{RenderRequest, RenderResponse, RenderOptionsDto, ResponseStatistics, DocumentStatsDto};
pub use use_cases::RenderMarkdownUseCase;
