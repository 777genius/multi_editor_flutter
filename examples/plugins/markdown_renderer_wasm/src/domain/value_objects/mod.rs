// Domain Layer - Value Objects
//
// Value Objects are immutable objects defined by their values, not identity.
// They are self-validating and have no side effects.

pub mod markdown_options;
pub mod html_output;

pub use markdown_options::MarkdownOptions;
pub use html_output::HtmlOutput;
