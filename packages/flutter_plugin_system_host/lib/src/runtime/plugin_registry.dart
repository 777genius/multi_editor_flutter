import 'package:flutter_plugin_system_core/flutter_plugin_system_core.dart';
import 'package:meta/meta.dart';

/// Plugin registry entry
///
/// Internal structure for tracking plugin with its context and state.
@immutable
class PluginEntry {
  /// Plugin instance
  final IPlugin plugin;

  /// Plugin context
  final PluginContext context;

  /// Current state
  final PluginState state;

  /// Load timestamp
  final DateTime loadedAt;

  /// Ready timestamp (when initialized)
  final DateTime? readyAt;

  const PluginEntry({
    required this.plugin,
    required this.context,
    required this.state,
    required this.loadedAt,
    this.readyAt,
  });

  /// Copy with new state
  PluginEntry copyWith({
    PluginState? state,
    DateTime? readyAt,
  }) {
    return PluginEntry(
      plugin: plugin,
      context: context,
      state: state ?? this.state,
      loadedAt: loadedAt,
      readyAt: readyAt ?? this.readyAt,
    );
  }

  /// Get load duration
  Duration? get loadDuration {
    if (readyAt == null) return null;
    return readyAt!.difference(loadedAt);
  }
}

/// Plugin registry
///
/// Central registry for managing loaded plugins with their contexts and states.
///
/// ## Design Principles
///
/// - **Single Responsibility**: Only manages plugin storage and retrieval
/// - **Immutability**: Uses immutable PluginEntry internally
///
/// ## Concurrency
///
/// **IMPORTANT**: This class is NOT thread-safe. All operations should be
/// called from the same isolate. For multi-isolate use, wrap calls in a
/// single isolate and use message passing for communication.
///
/// Flutter applications typically run in a single isolate, so this is not
/// a concern for most use cases
///
/// ## Example
///
/// ```dart
/// final registry = PluginRegistry();
///
/// // Register plugin
/// registry.register('plugin.file-icons', plugin, context);
///
/// // Update state
/// registry.updateState('plugin.file-icons', PluginState.ready);
///
/// // Get plugin
/// final plugin = registry.getPlugin('plugin.file-icons');
///
/// // Check if loaded
/// if (registry.isLoaded('plugin.file-icons')) {
///   // Use plugin
/// }
///
/// // Unregister
/// registry.unregister('plugin.file-icons');
/// ```
class PluginRegistry {
  final Map<String, PluginEntry> _plugins = {};

  /// Register plugin with initial LOADED state
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Unique plugin identifier
  /// - `plugin`: Plugin instance
  /// - `context`: Plugin execution context
  /// - `state`: Initial state (default: loaded)
  ///
  /// ## Throws
  ///
  /// [StateError] if plugin with this ID is already registered
  void register(
    String pluginId,
    IPlugin plugin,
    PluginContext context, {
    PluginState state = PluginState.loaded,
  }) {
    if (_plugins.containsKey(pluginId)) {
      throw StateError('Plugin already registered: $pluginId');
    }

    _plugins[pluginId] = PluginEntry(
      plugin: plugin,
      context: context,
      state: state,
      loadedAt: DateTime.now(),
      readyAt: state == PluginState.ready ? DateTime.now() : null,
    );
  }

  /// Unregister plugin
  ///
  /// Removes plugin from registry. Plugin should be disposed before unregistering.
  ///
  /// ## Returns
  ///
  /// `true` if plugin was removed, `false` if plugin was not found
  bool unregister(String pluginId) {
    return _plugins.remove(pluginId) != null;
  }

  /// Update plugin state
  ///
  /// Updates the state of a registered plugin.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  /// - `state`: New state
  ///
  /// ## Throws
  ///
  /// [StateError] if plugin is not registered
  void updateState(String pluginId, PluginState state) {
    final entry = _plugins[pluginId];
    if (entry == null) {
      throw StateError('Plugin not found: $pluginId');
    }

    _plugins[pluginId] = entry.copyWith(
      state: state,
      readyAt: state == PluginState.ready ? DateTime.now() : entry.readyAt,
    );
  }

  /// Get plugin instance
  ///
  /// ## Returns
  ///
  /// Plugin instance or `null` if not registered
  IPlugin? getPlugin(String pluginId) {
    return _plugins[pluginId]?.plugin;
  }

  /// Get plugin context
  ///
  /// ## Returns
  ///
  /// Plugin context or `null` if not registered
  PluginContext? getContext(String pluginId) {
    return _plugins[pluginId]?.context;
  }

  /// Get plugin state
  ///
  /// ## Returns
  ///
  /// Current state or `null` if not registered
  PluginState? getState(String pluginId) {
    return _plugins[pluginId]?.state;
  }

  /// Get plugin entry
  ///
  /// ## Returns
  ///
  /// Full plugin entry or `null` if not registered
  PluginEntry? getEntry(String pluginId) {
    return _plugins[pluginId];
  }

  /// Get all plugin instances
  ///
  /// ## Returns
  ///
  /// Map of pluginId → plugin instances
  Map<String, IPlugin> getAllPlugins() {
    return Map.fromEntries(
      _plugins.entries.map((entry) => MapEntry(entry.key, entry.value.plugin)),
    );
  }

  /// Get all plugin IDs
  ///
  /// ## Returns
  ///
  /// List of all registered plugin IDs
  List<String> getAllPluginIds() {
    return _plugins.keys.toList();
  }

  /// Get plugins by state
  ///
  /// ## Parameters
  ///
  /// - `state`: Filter by this state
  ///
  /// ## Returns
  ///
  /// Map of pluginId → plugin for plugins in given state
  Map<String, IPlugin> getPluginsByState(PluginState state) {
    return Map.fromEntries(
      _plugins.entries
          .where((entry) => entry.value.state == state)
          .map((entry) => MapEntry(entry.key, entry.value.plugin)),
    );
  }

  /// Check if plugin is registered
  ///
  /// ## Returns
  ///
  /// `true` if plugin is registered, `false` otherwise
  bool isLoaded(String pluginId) {
    return _plugins.containsKey(pluginId);
  }

  /// Check if plugin is in specific state
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  /// - `state`: State to check
  ///
  /// ## Returns
  ///
  /// `true` if plugin is in given state, `false` otherwise
  bool isInState(String pluginId, PluginState state) {
    return _plugins[pluginId]?.state == state;
  }

  /// Get number of registered plugins
  int get count => _plugins.length;

  /// Check if registry is empty
  bool get isEmpty => _plugins.isEmpty;

  /// Check if registry has plugins
  bool get isNotEmpty => _plugins.isNotEmpty;

  /// Clear all plugins
  ///
  /// Removes all plugins from registry.
  /// Plugins should be disposed before clearing.
  ///
  /// **Warning**: This does not call dispose() on plugins!
  void clear() {
    _plugins.clear();
  }

  /// Get registry statistics
  ///
  /// ## Returns
  ///
  /// Map with registry statistics:
  /// - `total`: Total number of plugins
  /// - `ready`: Number of ready plugins
  /// - `error`: Number of plugins in error state
  /// - `loading`: Number of plugins currently loading
  Map<String, int> getStatistics() {
    final stats = <String, int>{
      'total': _plugins.length,
      'ready': 0,
      'error': 0,
      'loading': 0,
      'initializing': 0,
    };

    for (final entry in _plugins.values) {
      switch (entry.state) {
        case PluginState.ready:
          stats['ready'] = stats['ready']! + 1;
          break;
        case PluginState.error:
          stats['error'] = stats['error']! + 1;
          break;
        case PluginState.loading:
          stats['loading'] = stats['loading']! + 1;
          break;
        case PluginState.initializing:
          stats['initializing'] = stats['initializing']! + 1;
          break;
        default:
          break;
      }
    }

    return stats;
  }

  @override
  String toString() {
    final stats = getStatistics();
    return 'PluginRegistry(${stats['total']} plugins: ${stats['ready']} ready, ${stats['error']} errors)';
  }
}
