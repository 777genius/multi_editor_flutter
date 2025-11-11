// Domain Layer
//
// Pure business logic with no external dependencies.
// Follow Clean Architecture: this layer doesn't know about
// databases, UI, frameworks, or external libraries.

pub mod entities;
pub mod value_objects;
pub mod services;

// Re-export main types for convenience
pub use entities::{MarkdownDocument, DocumentStatistics, HtmlElement, HtmlElementCollection};
pub use value_objects::{MarkdownOptions, HtmlOutput};
pub use services::{Renderer, RendererInfo};
