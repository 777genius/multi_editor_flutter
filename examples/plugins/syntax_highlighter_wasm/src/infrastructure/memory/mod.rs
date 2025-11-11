// Infrastructure Layer - Memory Management
//
// WASM linear memory allocator.
// Follow Linear Memory Pattern from architecture docs.

pub mod allocator;

pub use allocator::{alloc, dealloc, serialize_and_pack};
