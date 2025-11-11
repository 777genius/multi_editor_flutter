// Application Layer - DTOs (Data Transfer Objects)
//
// DTOs are simple data structures for transferring data between layers.
// They are serializable and have no business logic.

pub mod search_request;
pub mod search_response;

pub use search_request::{SearchRequest, SearchOptionsDto};
pub use search_response::{SearchResponse, MatchDto, SearchStatisticsDto};
