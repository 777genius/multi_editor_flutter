// Infrastructure Layer - Pulldown-cmark Integration
//
// Adapter for pulldown-cmark markdown parsing library.
// Implements domain Renderer trait.

pub mod pulldown_renderer;

pub use pulldown_renderer::PulldownRenderer;
