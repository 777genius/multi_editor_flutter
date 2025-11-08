import 'package:injectable/injectable.dart';
import 'package:editor_core/editor_core.dart';
import '../repository/monaco_editor_repository.dart';

/// Dependency Injection module for Editor Monaco.
///
/// This module registers Monaco editor implementation
/// with the dependency injection container.
///
/// Architecture:
/// - Monaco repository is a lazy singleton (created on first use)
///
/// Usage:
/// ```dart
/// // In main.dart:
/// configureDependencies();
///
/// // Then inject anywhere:
/// final editorRepository = getIt<ICodeEditorRepository>(
///   instanceName: 'monaco',
/// );
/// ```
@module
abstract class EditorMonacoModule {
  // ================================================================
  // Monaco Editor Repository (Lazy Singleton)
  // ================================================================

  /// Provides Monaco implementation of ICodeEditorRepository.
  ///
  /// This is a lazy singleton because:
  /// 1. Monaco controller initialization is expensive
  /// 2. Only one Monaco editor instance per app
  /// 3. Created only when first requested
  ///
  /// Named 'monaco' to distinguish from other editor implementations
  /// (e.g., 'native' for Rust editor).
  @lazySingleton
  @Named('monaco')
  ICodeEditorRepository provideMonacoEditorRepository() {
    return MonacoEditorRepository();
  }
}
