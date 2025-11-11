// Infrastructure Layer
//
// Contains implementations of interfaces defined in domain layer.
// Adapts external libraries and frameworks to domain contracts.
//
// Follow Clean Architecture:
// - Implements domain service traits (FuzzyMatcher)
// - Depends on domain layer (inward dependency)
// - Contains framework-specific code (nucleo, WASM memory)

pub mod nucleo;
pub mod memory;

pub use nucleo::NucleoMatcher;
pub use memory::{alloc, dealloc, serialize_and_pack};
