// Domain Layer - Entities
//
// Entities are objects with identity and lifecycle.
// They are mutable and have business logic.

pub mod markdown_document;
pub mod html_element;

pub use markdown_document::{MarkdownDocument, DocumentStatistics};
pub use html_element::{HtmlElement, HtmlElementCollection};
