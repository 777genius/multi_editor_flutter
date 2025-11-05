import 'package:editor_plugins/editor_plugins.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/plugin_state.dart';

abstract class BaseEditorPlugin extends EditorPlugin {
  final ValueNotifier<PluginState> state = ValueNotifier(PluginState.uninitialized);
  PluginContext? _context;

  PluginContext get context {
    if (_context == null) {
      throw StateError('Plugin not initialized. Call initialize() first.');
    }
    return _context!;
  }

  bool get isInitialized => state.value.isReady;
  bool get canInitialize => state.value.canInitialize;

  @override
  Future<void> initialize(PluginContext context) async {
    if (!canInitialize) {
      throw StateError('Plugin cannot be initialized in state: ${state.value}');
    }

    state.value = PluginState.initializing;
    _context = context;

    try {
      await onInitialize(context);
      state.value = PluginState.ready;
    } catch (e) {
      state.value = PluginState.error;
      debugPrint('[${manifest.name}] Initialization failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    if (!state.value.canDispose) {
      debugPrint('[${manifest.name}] Cannot dispose in state: ${state.value}');
      return;
    }

    try {
      await onDispose();
      state.value = PluginState.disposed;
      _context = null;
    } catch (e) {
      debugPrint('[${manifest.name}] Disposal failed: $e');
      state.value = PluginState.error;
    }
  }

  @protected
  Future<void> onInitialize(PluginContext context);

  @protected
  Future<void> onDispose();

  @protected
  void safeExecute(
    String operation,
    void Function() action, {
    void Function(Object error)? onError,
  }) {
    try {
      action();
    } catch (e) {
      debugPrint('[${manifest.name}] $operation failed: $e');
      onError?.call(e);
    }
  }

  @protected
  Future<void> safeExecuteAsync(
    String operation,
    Future<void> Function() action, {
    void Function(Object error)? onError,
  }) async {
    try {
      await action();
    } catch (e) {
      debugPrint('[${manifest.name}] $operation failed: $e');
      onError?.call(e);
    }
  }
}
