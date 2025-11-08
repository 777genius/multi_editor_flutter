//! Native Rust Code Editor
//!
//! High-performance text editor built with:
//! - ropey: Rope data structure for O(log n) text operations
//! - tree-sitter: Fast incremental parsing and syntax highlighting
//! - cosmic-text: Advanced text layout and shaping
//! - wgpu: Cross-platform GPU rendering
//!
//! This module provides a C FFI interface for Flutter integration.

pub mod editor;
pub mod renderer;
pub mod ffi;

pub use editor::Editor;
pub use renderer::TextRenderer;
