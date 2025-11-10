import 'package:injectable/injectable.dart';
import 'package:editor_core/editor_core.dart';
import '../repository/native_editor_repository.dart';

/// Dependency Injection module for Editor FFI (Rust Native Editor).
///
/// This module registers the Rust native editor implementation
/// with the dependency injection container.
///
/// Architecture:
/// - Native editor repository is a lazy singleton
///
/// Usage:
/// ```dart
/// // In main.dart:
/// configureDependencies();
///
/// // Then inject anywhere:
/// final editorRepository = getIt<ICodeEditorRepository>(
///   instanceName: 'native',
/// );
/// ```
@module
abstract class EditorFfiModule {
  // ================================================================
  // Native Editor Repository (Lazy Singleton)
  // ================================================================

  /// Provides Rust native implementation of ICodeEditorRepository.
  ///
  /// This is a lazy singleton because:
  /// 1. FFI initialization is expensive
  /// 2. Only one native editor instance per app
  /// 3. Created only when first requested
  ///
  /// Named 'native' to distinguish from Monaco implementation.
  ///
  /// Benefits of Rust native editor:
  /// - **4-10x faster** text operations (ropey data structure)
  /// - **50-70% less memory** usage
  /// - **Native performance** without WebView overhead
  /// - **Offline syntax highlighting** via tree-sitter
  @lazySingleton
  @Named('native')
  ICodeEditorRepository provideNativeEditorRepository() {
    return NativeEditorRepository();
  }
}
