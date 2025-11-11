// Application Layer - DTOs (Data Transfer Objects)
//
// Simple data containers for request/response.
// Separate from domain entities (decoupling).

pub mod parse_request;
pub mod highlight_response;

pub use parse_request::ParseRequest;
pub use highlight_response::{HighlightResponse, HighlightRangeDto, ResponseStatistics};
