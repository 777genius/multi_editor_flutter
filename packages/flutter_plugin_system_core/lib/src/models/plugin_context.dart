import 'package:meta/meta.dart';
import '../contracts/i_plugin_host.dart';
import 'plugin_config.dart';

/// Plugin context
///
/// Provides an isolated execution context for a plugin.
/// Contains the plugin's unique ID, configuration, and access to the host system.
///
/// ## Design Principles
///
/// - **Isolation**: Each plugin gets its own isolated context
/// - **Capability-based**: Plugin can only access what the host provides
/// - **Immutable ID**: Plugin ID cannot be changed after creation
///
/// ## Example
///
/// ```dart
/// // Host creates context for plugin
/// final context = PluginContext(
///   pluginId: 'plugin.file-icons',
///   host: myHost,
///   config: PluginConfig.fromManifest(manifest),
/// );
///
/// // Plugin initializes with context
/// await plugin.initialize(context);
///
/// // Plugin calls host function
/// final file = await context.callHost<FileDocument>('get_current_file');
/// ```
///
/// **Note**: This class is NOT immutable despite containing immutable fields,
/// because it maintains a mutable service registry that can be modified
/// through [registerService], [removeService], and [clearServices] methods.
class PluginContext {
  /// Unique plugin identifier
  final String pluginId;

  /// Host system interface
  final IPluginHost host;

  /// Plugin configuration
  final PluginConfig config;

  /// Plugin-specific services registry
  final Map<Type, dynamic> _services;

  /// Create plugin context
  PluginContext({
    required this.pluginId,
    required this.host,
    required this.config,
  }) : _services = {};

  /// Call host function
  ///
  /// This is the primary way plugins interact with the host system.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Get current file
  /// final file = await context.callHost<FileDocument>('get_current_file');
  ///
  /// // Open file
  /// await context.callHost('open_file', ['/path/to/file.txt']);
  ///
  /// // Get LSP completions
  /// final completions = await context.callHost<List<CompletionItem>>(
  ///   'lsp_get_completions',
  ///   ['file123', 10, 5],
  /// );
  /// ```
  Future<T> callHost<T>(String functionName, [List<dynamic>? args]) {
    return host.callHostFunction<T>(functionName, args ?? []);
  }

  /// Register plugin-specific service
  ///
  /// Services are scoped to this plugin's context and not shared with other plugins.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Register cache service
  /// context.registerService<IconCache>(IconCache());
  ///
  /// // Later retrieve
  /// final cache = context.getService<IconCache>();
  /// ```
  void registerService<T>(T service) {
    _services[T] = service;
  }

  /// Get plugin-specific service
  T? getService<T>() {
    return _services[T] as T?;
  }

  /// Check if service is registered
  bool hasService<T>() {
    return _services.containsKey(T);
  }

  /// Remove service
  void removeService<T>() {
    _services.remove(T);
  }

  /// Clear all services
  void clearServices() {
    _services.clear();
  }

  /// Get all registered service types
  Iterable<Type> get registeredServiceTypes => _services.keys;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PluginContext &&
          runtimeType == other.runtimeType &&
          pluginId == other.pluginId;

  @override
  int get hashCode => pluginId.hashCode;

  @override
  String toString() => 'PluginContext(pluginId: $pluginId)';
}
