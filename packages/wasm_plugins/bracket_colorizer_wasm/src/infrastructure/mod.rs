// Infrastructure Layer - External dependencies and adapters

pub mod memory;

pub use memory::{alloc, dealloc, serialize_and_pack};
