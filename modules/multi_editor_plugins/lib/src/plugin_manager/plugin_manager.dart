import 'dart:async';

import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:flutter/foundation.dart';
import '../plugin_api/editor_plugin.dart';
import '../plugin_api/plugin_context.dart';
import '../plugin_api/plugin_manifest.dart';
import '../plugin_api/plugin_config_schema.dart';
import '../events/plugin_event_dispatcher.dart';
import '../messaging/plugin_message_bus.dart';
import '../error_tracking/error_tracker.dart';
import '../error_tracking/plugin_error.dart';
import '../ui/file_icon_descriptor.dart';
import 'plugin_state.dart';
import 'plugin_registry.dart';
import 'dependency_validator.dart';

typedef PluginErrorCallback =
    void Function(String pluginId, Object error, StackTrace stackTrace);

class PluginManager {
  final PluginContext _context;
  final Map<String, EditorPlugin> _plugins = {};
  final Map<String, bool> _activatedPlugins = {};
  final Map<String, List<StreamSubscription>> _subscriptions = {};
  final Map<String, PluginStatus> _pluginStatus = {};
  final PluginErrorCallback? _onPluginError;
  late final PluginEventDispatcher _eventDispatcher;
  late final PluginRegistry _registry;
  late final PluginMessageBus _messageBus;
  final ErrorTracker? _errorTracker;

  PluginManager(
    this._context, {
    PluginErrorCallback? onPluginError,
    PluginRegistry? registry,
    PluginMessageBus? messageBus,
    ErrorTracker? errorTracker,
  }) : _onPluginError = onPluginError,
       _errorTracker = errorTracker {
    _registry = registry ?? PluginRegistry();
    _messageBus = messageBus ?? PluginMessageBus();
    _eventDispatcher = PluginEventDispatcher(_context.events);
    _initializeEventDispatcher();
  }

  /// Initialize event dispatcher subscriptions
  void _initializeEventDispatcher() {
    _eventDispatcher.subscribeToEventBus<FileOpened>();
    _eventDispatcher.subscribeToEventBus<FileClosed>();
    _eventDispatcher.subscribeToEventBus<FileSaved>();
    _eventDispatcher.subscribeToEventBus<FileContentChanged>();
    _eventDispatcher.subscribeToEventBus<FileCreated>();
    _eventDispatcher.subscribeToEventBus<FileDeleted>();
    _eventDispatcher.subscribeToEventBus<FolderCreated>();
    _eventDispatcher.subscribeToEventBus<FolderDeleted>();
  }

  Future<void> registerPlugin(EditorPlugin plugin) async {
    final manifest = plugin.manifest;

    if (_plugins.containsKey(manifest.id)) {
      throw PluginException('Plugin "${manifest.id}" is already registered');
    }

    _validateDependencies(plugin);

    // Phase 1: Register (add to map but don't activate yet)
    _plugins[manifest.id] = plugin;
    _activatedPlugins[manifest.id] = false;
    _pluginStatus[manifest.id] = PluginStatus(
      pluginId: manifest.id,
      state: PluginActivationState.idle,
      lastStateChange: DateTime.now(),
    );

    // Phase 2: Activate in dependency order
    await _activateAllPending();
  }

  Future<void> _activateAllPending() async {
    final sorted = _topologicalSort();

    for (final pluginId in sorted) {
      if (_activatedPlugins[pluginId] == false) {
        final plugin = _plugins[pluginId];
        if (plugin != null) {
          try {
            await _activatePlugin(plugin);
          } catch (e, stackTrace) {
            // Record error but continue with other plugins
            _activatedPlugins[pluginId] = false;
            _recordPluginError(
              pluginId,
              e,
              stackTrace,
              errorType: PluginErrorType.initialization,
              operation: 'plugin activation',
            );
            debugPrint(
              '[PluginManager] Failed to activate plugin "$pluginId": $e',
            );
            // Don't rethrow - allow other plugins to activate
          }
        }
      }
    }
  }

  List<String> _topologicalSort() {
    final visited = <String>{};
    final result = <String>[];
    final visiting = <String>{};

    void visit(String pluginId) {
      if (visited.contains(pluginId)) return;

      if (visiting.contains(pluginId)) {
        throw PluginException(
          'Circular dependency detected involving plugin "$pluginId"',
        );
      }

      visiting.add(pluginId);

      final plugin = _plugins[pluginId];
      if (plugin != null) {
        for (final depId in plugin.manifest.dependencies) {
          visit(depId);
        }
      }

      visiting.remove(pluginId);
      visited.add(pluginId);
      result.add(pluginId);
    }

    for (final pluginId in _plugins.keys) {
      visit(pluginId);
    }

    return result;
  }

  Future<void> _activatePlugin(EditorPlugin plugin) async {
    final manifest = plugin.manifest;

    if (_activatedPlugins[manifest.id] == true) {
      return;
    }

    // Update status to activating
    _updatePluginStatus(manifest.id, PluginActivationState.activating);

    try {
      // Dependencies are guaranteed to be activated by topological sort
      await plugin.initialize(_context);
      _activatedPlugins[manifest.id] = true;

      // Update status to active
      _updatePluginStatus(manifest.id, PluginActivationState.active);

      _subscribeToEvents(plugin);
    } catch (e, _) {
      // Update status to error
      _updatePluginStatus(manifest.id, PluginActivationState.error);
      rethrow;
    }
  }

  void _subscribeToEvents(EditorPlugin plugin) {
    final pluginId = plugin.manifest.id;

    // Register handlers using the event dispatcher with safe execution
    _eventDispatcher.registerHandler<FileOpened>(
      pluginId: pluginId,
      handler: (context) =>
          _safeExecute(pluginId, () => plugin.onFileOpen(context.event.file)),
    );

    _eventDispatcher.registerHandler<FileClosed>(
      pluginId: pluginId,
      handler: (context) => _safeExecute(
        pluginId,
        () => plugin.onFileClose(context.event.fileId),
      ),
    );

    _eventDispatcher.registerHandler<FileSaved>(
      pluginId: pluginId,
      handler: (context) =>
          _safeExecute(pluginId, () => plugin.onFileSave(context.event.file)),
    );

    _eventDispatcher.registerHandler<FileContentChanged>(
      pluginId: pluginId,
      handler: (context) => _safeExecute(
        pluginId,
        () => plugin.onFileContentChange(
          context.event.fileId,
          context.event.content,
        ),
      ),
    );

    _eventDispatcher.registerHandler<FileCreated>(
      pluginId: pluginId,
      handler: (context) =>
          _safeExecute(pluginId, () => plugin.onFileCreate(context.event.file)),
    );

    _eventDispatcher.registerHandler<FileDeleted>(
      pluginId: pluginId,
      handler: (context) => _safeExecute(
        pluginId,
        () => plugin.onFileDelete(context.event.fileId),
      ),
    );

    _eventDispatcher.registerHandler<FolderCreated>(
      pluginId: pluginId,
      handler: (context) => _safeExecute(
        pluginId,
        () => plugin.onFolderCreate(context.event.folder),
      ),
    );

    _eventDispatcher.registerHandler<FolderDeleted>(
      pluginId: pluginId,
      handler: (context) => _safeExecute(
        pluginId,
        () => plugin.onFolderDelete(context.event.folderId),
      ),
    );
  }

  Future<void> _unsubscribeEvents(String pluginId) async {
    // Remove all event handlers for this plugin
    _eventDispatcher.removeHandlers(pluginId);
    // Remove all message bus subscriptions for this plugin
    _messageBus.unsubscribe(pluginId);
  }

  void _validateDependencies(EditorPlugin plugin) {
    final manifest = plugin.manifest;
    for (final depId in manifest.dependencies) {
      if (!_plugins.containsKey(depId)) {
        throw PluginException(
          'Plugin "${manifest.id}" has unmet dependency: "$depId"',
        );
      }
    }
  }

  Future<void> unregisterPlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) {
      return;
    }

    for (final otherPlugin in _plugins.values) {
      if (otherPlugin.manifest.dependencies.contains(pluginId)) {
        throw PluginException(
          'Cannot unregister plugin "$pluginId" because it is required by "${otherPlugin.manifest.id}"',
        );
      }
    }

    if (_activatedPlugins[pluginId] == true) {
      await _unsubscribeEvents(pluginId);
      await plugin.dispose();
    }

    _plugins.remove(pluginId);
    _activatedPlugins.remove(pluginId);
  }

  /// Safely execute a plugin method with error handling
  void _safeExecute(String pluginId, void Function() action) {
    try {
      action();
    } catch (e, stackTrace) {
      _recordPluginError(pluginId, e, stackTrace);
      debugPrint('[PluginManager] Error in plugin "$pluginId": $e');
    }
  }

  /// Record a plugin error and update status
  void _recordPluginError(
    String pluginId,
    Object error,
    StackTrace stackTrace, {
    PluginErrorType errorType = PluginErrorType.runtime,
    String? operation,
    Map<String, dynamic>? additionalContext,
  }) {
    final currentStatus = _pluginStatus[pluginId];
    if (currentStatus == null) return;

    final plugin = _plugins[pluginId];
    final pluginName = plugin?.manifest.name ?? pluginId;

    // Record in ErrorTracker
    if (_errorTracker != null) {
      final pluginError = PluginError(
        pluginId: pluginId,
        pluginName: pluginName,
        type: errorType,
        message: error.toString(),
        timestamp: DateTime.now(),
        stackTrace: stackTrace,
        context: {
          'state': currentStatus.state.toString(),
          'errorCount': currentStatus.errorCount + 1,
          if (operation != null) 'operation': operation,
          ...?additionalContext,
        },
      );
      _errorTracker.recordError(pluginError);
    }

    final errorCount = currentStatus.errorCount + 1;
    final newStatus = currentStatus.copyWith(
      state: PluginActivationState.error,
      lastError: error,
      lastErrorStackTrace: stackTrace,
      lastStateChange: DateTime.now(),
      errorCount: errorCount,
      lastErrorTime: DateTime.now(),
    );

    _pluginStatus[pluginId] = newStatus;

    // Call error callback if provided
    _onPluginError?.call(pluginId, error, stackTrace);

    // Auto-disable plugin after 3 errors
    if (errorCount >= 3) {
      debugPrint(
        '[PluginManager] Plugin "$pluginId" disabled after $errorCount errors',
      );
      _updatePluginStatus(pluginId, PluginActivationState.disabled);
    }
  }

  /// Update plugin status
  void _updatePluginStatus(String pluginId, PluginActivationState newState) {
    final currentStatus = _pluginStatus[pluginId];
    if (currentStatus == null) return;

    _pluginStatus[pluginId] = currentStatus.copyWith(
      state: newState,
      lastStateChange: DateTime.now(),
    );
  }

  /// Retry activating a failed plugin
  Future<bool> retryPlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    final status = _pluginStatus[pluginId];

    if (plugin == null || status == null) {
      return false;
    }

    if (!status.canRetry) {
      debugPrint(
        '[PluginManager] Cannot retry plugin "$pluginId" - too many errors or wrong state',
      );
      return false;
    }

    try {
      debugPrint('[PluginManager] Retrying plugin "$pluginId"...');
      await _activatePlugin(plugin);
      debugPrint('[PluginManager] Plugin "$pluginId" activated successfully');
      return true;
    } catch (e, stackTrace) {
      _recordPluginError(
        pluginId,
        e,
        stackTrace,
        errorType: PluginErrorType.initialization,
        operation: 'plugin retry',
      );
      debugPrint('[PluginManager] Failed to retry plugin "$pluginId": $e');
      return false;
    }
  }

  /// Get status of a specific plugin
  PluginStatus? getPluginStatus(String pluginId) => _pluginStatus[pluginId];

  /// Get status of all plugins
  Map<String, PluginStatus> getAllPluginStatus() =>
      Map.unmodifiable(_pluginStatus);

  EditorPlugin? getPlugin(String pluginId) => _plugins[pluginId];

  bool isPluginRegistered(String pluginId) => _plugins.containsKey(pluginId);

  bool isPluginActivated(String pluginId) =>
      _activatedPlugins[pluginId] ?? false;

  List<PluginManifest> get allPlugins =>
      _plugins.values.map((p) => p.manifest).toList();

  /// Get all registered plugins
  List<EditorPlugin> get plugins => _plugins.values.toList();

  List<EditorPlugin> getPluginsForLanguage(String language) {
    return _plugins.values.where((p) => p.supportsLanguage(language)).toList();
  }

  /// Validate all plugin dependencies
  List<DependencyValidationError> validateDependencies() {
    final manifests = <String, PluginManifest>{};
    for (final entry in _plugins.entries) {
      manifests[entry.key] = entry.value.manifest;
    }

    final validator = DependencyValidator(manifests);
    final errors = validator.validateAll();

    if (errors.isNotEmpty) {
      debugPrint(
        '[PluginManager] Dependency validation found ${errors.length} errors:',
      );
      for (final error in errors) {
        debugPrint('[PluginManager]   $error');
      }
    }

    return errors;
  }

  /// Get the dependency graph for debugging/visualization
  Map<String, List<String>> getDependencyGraph() {
    final manifests = <String, PluginManifest>{};
    for (final entry in _plugins.entries) {
      manifests[entry.key] = entry.value.manifest;
    }

    final validator = DependencyValidator(manifests);
    return validator.buildDependencyGraph();
  }

  /// Get plugins that have no dependencies
  List<String> getLeafPlugins() {
    final manifests = <String, PluginManifest>{};
    for (final entry in _plugins.entries) {
      manifests[entry.key] = entry.value.manifest;
    }

    final validator = DependencyValidator(manifests);
    return validator.getLeafPlugins();
  }

  /// Get plugins that depend on a specific plugin
  List<String> getDependents(String pluginId) {
    final manifests = <String, PluginManifest>{};
    for (final entry in _plugins.entries) {
      manifests[entry.key] = entry.value.manifest;
    }

    final validator = DependencyValidator(manifests);
    return validator.getDependents(pluginId);
  }

  /// Get dependency depth for a plugin
  int getDependencyDepth(String pluginId) {
    final manifests = <String, PluginManifest>{};
    for (final entry in _plugins.entries) {
      manifests[entry.key] = entry.value.manifest;
    }

    final validator = DependencyValidator(manifests);
    return validator.getDependencyDepth(pluginId);
  }

  // ==================== File Icon API ====================

  /// Get file icon descriptor for a file tree node.
  ///
  /// Queries all active plugins for icon descriptors and returns the one
  /// with the highest priority (lowest priority value).
  ///
  /// Returns null if no plugin provides an icon for this node.
  ///
  /// ## Priority System:
  /// - Lower priority value = higher priority
  /// - Default priority: 100
  /// - Multiple plugins can provide icons; highest priority wins
  ///
  /// ## Example:
  /// ```dart
  /// final descriptor = pluginManager.getFileIconDescriptor(fileNode);
  /// if (descriptor != null) {
  ///   // Render custom icon based on descriptor
  /// } else {
  ///   // Use default icon
  /// }
  /// ```
  FileIconDescriptor? getFileIconDescriptor(FileTreeNode node) {
    FileIconDescriptor? bestDescriptor;
    int bestPriority = 999999;

    // Query all active plugins
    for (final entry in _plugins.entries) {
      final pluginId = entry.key;
      final plugin = entry.value;

      // Skip inactive plugins
      if (_activatedPlugins[pluginId] != true) continue;

      // Skip plugins in error/disabled state
      final status = _pluginStatus[pluginId];
      if (status?.state == PluginActivationState.error ||
          status?.state == PluginActivationState.disabled) {
        continue;
      }

      try {
        final descriptor = plugin.getFileIconDescriptor(node);
        if (descriptor != null) {
          // Select descriptor with lowest priority (highest priority)
          if (descriptor.priority < bestPriority) {
            bestDescriptor = descriptor;
            bestPriority = descriptor.priority;
          }
        }
      } catch (e, stackTrace) {
        // Log error but continue with other plugins
        _recordPluginError(
          pluginId,
          e,
          stackTrace,
          errorType: PluginErrorType.runtime,
          operation: 'getFileIconDescriptor',
          additionalContext: {
            'nodeId': node.id,
            'nodeName': node.name,
            'nodeType': node.type.toString(),
          },
        );
        debugPrint(
          '[PluginManager] Error getting file icon from plugin "$pluginId": $e',
        );
      }
    }

    return bestDescriptor;
  }

  /// Get file icon descriptor by filename only.
  ///
  /// Convenience method that creates a temporary FileTreeNode from filename.
  /// Useful for displaying icons when you only have the filename available.
  ///
  /// ## Example:
  /// ```dart
  /// final descriptor = pluginManager.getFileIconDescriptorByName('main.dart');
  /// ```
  FileIconDescriptor? getFileIconDescriptorByName(String fileName) {
    // Create temporary FileTreeNode for icon resolution
    final tempNode = FileTreeNode(
      id: 'temp-$fileName',
      name: fileName,
      type: FileTreeNodeType.file,
    );
    return getFileIconDescriptor(tempNode);
  }

  /// Validate plugin configuration against its schema
  /// Returns validation result with errors if invalid
  ConfigValidationResult? validatePluginConfig(String pluginId) {
    final plugin = _plugins[pluginId];
    if (plugin == null) {
      return ConfigValidationResult(
        isValid: false,
        errors: ['Plugin "$pluginId" not found'],
      );
    }

    final schema = plugin.configSchema;
    if (schema == null) {
      // No schema defined, configuration is valid
      return null;
    }

    final config = _context.getConfiguration(pluginId);
    final result = schema.validate(config);

    if (!result.isValid) {
      debugPrint(
        '[PluginManager] Configuration validation failed for "$pluginId":',
      );
      for (final error in result.errors) {
        debugPrint('[PluginManager]   $error');
      }
    }

    return result;
  }

  /// Get default configuration for a plugin
  Map<String, dynamic>? getPluginDefaultConfig(String pluginId) {
    final plugin = _plugins[pluginId];
    return plugin?.configSchema?.getDefaults();
  }

  /// Get the event dispatcher for custom event registration
  PluginEventDispatcher get eventDispatcher => _eventDispatcher;

  /// Get the error tracker for monitoring plugin errors
  ErrorTracker? get errorTracker => _errorTracker;

  /// Dispatch a custom event to plugins
  Future<PluginEventContext<T>> dispatchEvent<T extends EditorEvent>(
    T event,
  ) async {
    return await _eventDispatcher.dispatch<T>(event);
  }

  /// Get handlers registered for a specific event type (for debugging)
  List<String> getEventHandlers<T extends EditorEvent>() {
    return _eventDispatcher.getHandlersForEvent<T>();
  }

  /// Get all registered event types
  List<Type> getRegisteredEventTypes() {
    return _eventDispatcher.getRegisteredEventTypes();
  }

  // ==================== Plugin Registry API ====================

  /// Get the plugin registry
  PluginRegistry get registry => _registry;

  /// Register a plugin in the registry (makes it available but doesn't activate it)
  void registerInRegistry({
    required PluginManifest manifest,
    required PluginFactory factory,
    bool autoLoad = false,
  }) {
    _registry.register(
      manifest: manifest,
      factory: factory,
      autoLoad: autoLoad,
    );
  }

  /// Load and activate a plugin from the registry
  Future<void> loadPlugin(String pluginId) async {
    // Get instance from registry
    final plugin = await _registry.getInstance(pluginId);

    // Register and activate it
    await registerPlugin(plugin);
  }

  /// Load and activate all auto-load plugins from the registry
  Future<void> loadAutoLoadPlugins() async {
    final entries = _registry.autoLoadEntries;

    for (final entry in entries) {
      try {
        await loadPlugin(entry.id);
        debugPrint('[PluginManager] Auto-loaded plugin "${entry.id}"');
      } catch (e, stackTrace) {
        debugPrint(
          '[PluginManager] Failed to auto-load plugin "${entry.id}": $e',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  /// Query available plugins in the registry
  List<PluginRegistryEntry> queryAvailablePlugins({
    String? namePattern,
    String? author,
    List<String>? tags,
    bool? autoLoad,
  }) {
    return _registry.query(
      namePattern: namePattern,
      author: author,
      tags: tags,
      autoLoad: autoLoad,
    );
  }

  /// Get registry statistics
  RegistryStatistics get registryStatistics => _registry.statistics;

  // ==================== Plugin Messaging API ====================

  /// Get the message bus for inter-plugin communication
  PluginMessageBus get messageBus => _messageBus;

  /// Publish a message to other plugins
  Future<void> publishMessage(PluginMessage message) async {
    return await _messageBus.publish(message);
  }

  /// Send a request and wait for response
  Future<PluginResponse<TRes>> sendRequest<
    TReq extends PluginRequest<TRes>,
    TRes
  >(TReq request, {Duration timeout = const Duration(seconds: 5)}) async {
    return await _messageBus.request<TReq, TRes>(request, timeout: timeout);
  }

  /// Get message bus statistics
  MessageBusStatistics get messageBusStatistics => _messageBus.statistics;

  // ==================== Plugin Activation/Deactivation API ====================

  /// Activate a registered plugin
  Future<bool> activatePlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) {
      debugPrint(
        '[PluginManager] Cannot activate: Plugin "$pluginId" not registered',
      );
      return false;
    }

    if (_activatedPlugins[pluginId] == true) {
      debugPrint('[PluginManager] Plugin "$pluginId" is already activated');
      return true;
    }

    try {
      await _activatePlugin(plugin);
      debugPrint('[PluginManager] Plugin "$pluginId" activated successfully');
      return true;
    } catch (e, stackTrace) {
      _recordPluginError(
        pluginId,
        e,
        stackTrace,
        errorType: PluginErrorType.initialization,
        operation: 'plugin activation',
      );
      debugPrint('[PluginManager] Failed to activate plugin "$pluginId": $e');
      return false;
    }
  }

  /// Deactivate an active plugin
  Future<bool> deactivatePlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) {
      debugPrint(
        '[PluginManager] Cannot deactivate: Plugin "$pluginId" not registered',
      );
      return false;
    }

    if (_activatedPlugins[pluginId] != true) {
      debugPrint('[PluginManager] Plugin "$pluginId" is not activated');
      return true;
    }

    // Check if other plugins depend on this one
    final dependents = getDependents(pluginId);
    final activeDependents = dependents
        .where((id) => _activatedPlugins[id] == true)
        .toList();

    if (activeDependents.isNotEmpty) {
      debugPrint(
        '[PluginManager] Cannot deactivate "$pluginId": Required by active plugins: ${activeDependents.join(", ")}',
      );
      return false;
    }

    try {
      _updatePluginStatus(pluginId, PluginActivationState.idle);
      await _unsubscribeEvents(pluginId);
      await plugin.dispose();
      _activatedPlugins[pluginId] = false;
      debugPrint('[PluginManager] Plugin "$pluginId" deactivated successfully');
      return true;
    } catch (e, stackTrace) {
      debugPrint('[PluginManager] Error deactivating plugin "$pluginId": $e');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  /// Reload a plugin (deactivate then activate)
  Future<bool> reloadPlugin(String pluginId) async {
    final plugin = _plugins[pluginId];
    if (plugin == null) {
      debugPrint(
        '[PluginManager] Cannot reload: Plugin "$pluginId" not registered',
      );
      return false;
    }

    final wasActivated = _activatedPlugins[pluginId] == true;

    if (wasActivated) {
      final deactivated = await deactivatePlugin(pluginId);
      if (!deactivated) {
        return false;
      }
    }

    return await activatePlugin(pluginId);
  }

  /// Activate multiple plugins
  Future<Map<String, bool>> activatePlugins(List<String> pluginIds) async {
    final results = <String, bool>{};

    // Sort by dependency order
    final sorted = _topologicalSortSubset(pluginIds);

    for (final pluginId in sorted) {
      results[pluginId] = await activatePlugin(pluginId);
    }

    return results;
  }

  /// Deactivate multiple plugins
  Future<Map<String, bool>> deactivatePlugins(List<String> pluginIds) async {
    final results = <String, bool>{};

    // Sort in reverse dependency order (dependents first)
    final sorted = _topologicalSortSubset(pluginIds).reversed.toList();

    for (final pluginId in sorted) {
      results[pluginId] = await deactivatePlugin(pluginId);
    }

    return results;
  }

  /// Topological sort for a subset of plugins
  List<String> _topologicalSortSubset(List<String> pluginIds) {
    final subset = pluginIds.toSet();
    final visited = <String>{};
    final result = <String>[];
    final visiting = <String>{};

    void visit(String pluginId) {
      if (visited.contains(pluginId)) return;
      if (!subset.contains(pluginId)) return;

      if (visiting.contains(pluginId)) {
        throw PluginException(
          'Circular dependency detected involving plugin "$pluginId"',
        );
      }

      visiting.add(pluginId);

      final plugin = _plugins[pluginId];
      if (plugin != null) {
        for (final depId in plugin.manifest.dependencies) {
          if (subset.contains(depId)) {
            visit(depId);
          }
        }
      }

      visiting.remove(pluginId);
      visited.add(pluginId);
      result.add(pluginId);
    }

    for (final pluginId in pluginIds) {
      visit(pluginId);
    }

    return result;
  }

  /// Enable a disabled plugin (reset error state)
  Future<bool> enablePlugin(String pluginId) async {
    final status = _pluginStatus[pluginId];
    if (status == null) {
      debugPrint('[PluginManager] Cannot enable: Plugin "$pluginId" not found');
      return false;
    }

    if (status.state != PluginActivationState.disabled) {
      debugPrint('[PluginManager] Plugin "$pluginId" is not disabled');
      return false;
    }

    // Reset error state
    _pluginStatus[pluginId] = status.copyWith(
      state: PluginActivationState.idle,
      errorCount: 0,
      lastError: null,
      lastErrorStackTrace: null,
    );

    // Try to activate
    return await activatePlugin(pluginId);
  }

  Future<void> disposeAll() async {
    for (final plugin in _plugins.values) {
      final pluginId = plugin.manifest.id;
      if (_activatedPlugins[pluginId] == true) {
        await _unsubscribeEvents(pluginId);
        await plugin.dispose();
      }
    }
    _plugins.clear();
    _activatedPlugins.clear();
    _subscriptions.clear();
    _pluginStatus.clear();
    await _eventDispatcher.dispose();
    _registry.dispose();
    _messageBus.dispose();
  }
}

class PluginException implements Exception {
  final String message;

  PluginException(this.message);

  @override
  String toString() => 'PluginException: $message';
}
