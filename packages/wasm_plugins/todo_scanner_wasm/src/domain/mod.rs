// Domain Layer - Business Logic and Entities
//
// Pure business logic with no external dependencies.
// Defines what a TODO item is and how to work with it.

pub mod entities;
pub mod value_objects;
pub mod services;

pub use entities::*;
pub use value_objects::*;
