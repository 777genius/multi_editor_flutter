/// Monaco Editor adapter for the editor_core domain.
///
/// This package provides a Monaco-based implementation of [ICodeEditorRepository].
/// It translates domain operations to Monaco-specific calls, allowing the domain
/// layer to remain platform-agnostic.
///
/// Key benefits:
/// - Easy to swap Monaco with a native Rust+Flutter editor
/// - Domain logic remains pure and testable
/// - Monaco complexity is isolated
library editor_monaco;

export 'src/adapters/monaco_editor_repository.dart';
export 'src/mappers/monaco_mappers.dart';

// Dependency Injection
export 'src/di/editor_monaco_module.dart';
