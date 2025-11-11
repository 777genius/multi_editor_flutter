// Application Layer - Use Cases
//
// Use Cases contain application-specific business rules.
// They orchestrate the flow of data to and from entities,
// and direct entities to use their business rules.
//
// Follow Clean Architecture: Use cases depend on domain abstractions (traits),
// not concrete implementations (Dependency Inversion Principle).

pub mod search_files;

pub use search_files::SearchFilesUseCase;
