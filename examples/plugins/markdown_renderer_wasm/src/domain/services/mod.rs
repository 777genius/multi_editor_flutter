// Domain Layer - Services
//
// Domain Services represent operations that don't naturally fit within entities.
// They are defined as traits (interfaces) to maintain Dependency Inversion.

pub mod renderer;

pub use renderer::{Renderer, RendererInfo};
