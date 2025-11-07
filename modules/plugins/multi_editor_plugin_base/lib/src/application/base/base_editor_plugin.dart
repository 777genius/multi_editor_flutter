import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import 'package:flutter/foundation.dart';

/// Simplified base class for editor plugins.
///
/// Provides convenient helper methods while leaving state management
/// and error tracking to PluginManager.
///
/// Key differences from EditorPlugin:
/// - Splits initialize/dispose into onInitialize/onDispose hooks
/// - Provides context caching for easier access
/// - Offers helper methods for common patterns
abstract class BaseEditorPlugin extends EditorPlugin {
  PluginContext? _context;

  /// Cached plugin context (available after initialization)
  @protected
  PluginContext get context {
    if (_context == null) {
      throw StateError(
        'Plugin "${manifest.name}" not initialized. Call initialize() first.',
      );
    }
    return _context!;
  }

  /// Check if plugin has been initialized
  @protected
  bool get isInitialized => _context != null;

  @override
  Future<void> initialize(PluginContext context) async {
    if (_context != null) {
      throw StateError(
        'Plugin "${manifest.name}" already initialized. Cannot initialize twice.',
      );
    }
    _context = context;
    await onInitialize(context);
  }

  @override
  Future<void> dispose() async {
    await onDispose();
    _context = null;
  }

  /// Called when plugin is being initialized.
  /// Override this instead of initialize().
  @protected
  Future<void> onInitialize(PluginContext context);

  /// Called when plugin is being disposed.
  /// Override this instead of dispose().
  @protected
  Future<void> onDispose();

  /// Helper: safely execute a synchronous operation with error logging
  @protected
  void safeExecute(
    String operation,
    void Function() action, {
    void Function(Object error)? onError,
  }) {
    try {
      action();
    } catch (e, stack) {
      debugPrint('[${manifest.name}] $operation failed: $e\n$stack');
      onError?.call(e);
    }
  }

  /// Helper: safely execute an asynchronous operation with error logging
  @protected
  Future<void> safeExecuteAsync(
    String operation,
    Future<void> Function() action, {
    void Function(Object error)? onError,
  }) async {
    try {
      await action();
    } catch (e, stack) {
      debugPrint('[${manifest.name}] $operation failed: $e\n$stack');
      onError?.call(e);
    }
  }
}
