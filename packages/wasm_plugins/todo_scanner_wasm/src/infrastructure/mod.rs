// Infrastructure Layer - External dependencies and adapters

pub mod scanner;
pub mod memory;

pub use scanner::RegexTodoScanner;
pub use memory::{alloc, dealloc, serialize_and_pack};
