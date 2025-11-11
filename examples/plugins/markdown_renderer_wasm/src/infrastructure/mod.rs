// Infrastructure Layer
//
// Contains implementations of interfaces defined in domain layer.
// Adapts external libraries and frameworks to domain contracts.

pub mod pulldown_cmark;
pub mod memory;

pub use pulldown_cmark::PulldownRenderer;
pub use memory::{alloc, dealloc, serialize_and_pack};
