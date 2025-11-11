// Application Layer - DTOs (Data Transfer Objects)
//
// DTOs are simple data structures for transferring data between layers.
// They are serializable and have no business logic.

pub mod render_request;
pub mod render_response;

pub use render_request::{RenderRequest, RenderOptionsDto};
pub use render_response::{RenderResponse, ResponseStatistics, DocumentStatsDto};
