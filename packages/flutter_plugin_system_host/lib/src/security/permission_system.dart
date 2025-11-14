import 'package:flutter_plugin_system_core/flutter_plugin_system_core.dart';

/// Permission system
///
/// Manages and enforces plugin permissions based on manifests.
/// Implements the Permission System pattern from architecture document (lines 812-830).
///
/// ## Design Principles
///
/// - **Least Privilege**: Plugins only get explicitly requested permissions
/// - **Deny by Default**: Unlisted permissions are denied
/// - **Immutable Permissions**: Permissions cannot change after plugin load
///
/// ## Example
///
/// ```dart
/// final permissionSystem = PermissionSystem();
///
/// // Register plugin permissions from manifest
/// permissionSystem.registerPlugin(
///   manifest.id,
///   PluginPermissions(
///     allowedHostFunctions: manifest.requiredHostFunctions,
///     maxExecutionTime: Duration(seconds: 5),
///     maxMemoryBytes: 50 * 1024 * 1024, // 50 MB
///   ),
/// );
///
/// // Check permissions at runtime
/// final permissions = permissionSystem.getPermissions('plugin.example');
/// if (permissions.allowedHostFunctions.contains('get_file_content')) {
///   // Call host function
/// }
/// ```
class PermissionSystem {
  final Map<String, PluginPermissions> _permissions = {};

  /// Register plugin permissions
  ///
  /// Registers permissions for a plugin. Should be called during plugin load.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  /// - `permissions`: Plugin permissions
  ///
  /// ## Throws
  ///
  /// - [ArgumentError] if plugin already registered
  ///
  /// ## Example
  ///
  /// ```dart
  /// permissionSystem.registerPlugin(
  ///   'plugin.example',
  ///   PluginPermissions(
  ///     allowedHostFunctions: ['log_info', 'get_file_content'],
  ///     maxExecutionTime: Duration(seconds: 10),
  ///     filesystemAccess: FilesystemAccessLevel.readOnly,
  ///   ),
  /// );
  /// ```
  void registerPlugin(String pluginId, PluginPermissions permissions) {
    if (_permissions.containsKey(pluginId)) {
      throw ArgumentError('Plugin already registered: $pluginId');
    }
    _permissions[pluginId] = permissions;
  }

  /// Unregister plugin permissions
  ///
  /// Removes permissions for a plugin. Should be called during plugin unload.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  void unregisterPlugin(String pluginId) {
    _permissions.remove(pluginId);
  }

  /// Get plugin permissions
  ///
  /// Returns permissions for the specified plugin.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  ///
  /// ## Returns
  ///
  /// Plugin permissions, or default restrictive permissions if not registered
  ///
  /// ## Example
  ///
  /// ```dart
  /// final permissions = permissionSystem.getPermissions('plugin.example');
  /// print('Max execution time: ${permissions.maxExecutionTime}');
  /// print('Max memory: ${permissions.maxMemoryBytes} bytes');
  /// ```
  PluginPermissions getPermissions(String pluginId) {
    return _permissions[pluginId] ?? const PluginPermissions();
  }

  /// Check if plugin has permission to call host function
  ///
  /// Returns true if the plugin is allowed to call the specified host function.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  /// - `functionName`: Host function name
  ///
  /// ## Returns
  ///
  /// `true` if allowed, `false` otherwise
  ///
  /// ## Example
  ///
  /// ```dart
  /// if (permissionSystem.canCallHostFunction('plugin.example', 'get_file_content')) {
  ///   // Allow the call
  /// } else {
  ///   throw PermissionDeniedException('get_file_content', pluginId: 'plugin.example');
  /// }
  /// ```
  bool canCallHostFunction(String pluginId, String functionName) {
    final permissions = getPermissions(pluginId);
    return permissions.allowedHostFunctions.contains(functionName);
  }

  /// Check if plugin is registered
  ///
  /// Returns true if permissions are registered for the plugin.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  ///
  /// ## Returns
  ///
  /// `true` if registered, `false` otherwise
  bool isRegistered(String pluginId) {
    return _permissions.containsKey(pluginId);
  }

  /// Update plugin permissions
  ///
  /// Updates permissions for a plugin. Use with caution.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  /// - `permissions`: New permissions
  ///
  /// ## Throws
  ///
  /// - [ArgumentError] if plugin not registered
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Update permissions (e.g., after plugin upgrade)
  /// permissionSystem.updatePermissions(
  ///   'plugin.example',
  ///   permissions.copyWith(
  ///     allowedHostFunctions: [...permissions.allowedHostFunctions, 'new_function'],
  ///   ),
  /// );
  /// ```
  void updatePermissions(String pluginId, PluginPermissions permissions) {
    if (!_permissions.containsKey(pluginId)) {
      throw ArgumentError('Plugin not registered: $pluginId');
    }
    _permissions[pluginId] = permissions;
  }

  /// Get all registered plugin IDs
  ///
  /// Returns a list of all plugin IDs with registered permissions.
  ///
  /// ## Returns
  ///
  /// List of plugin IDs
  List<String> getRegisteredPlugins() {
    return _permissions.keys.toList();
  }

  /// Get statistics about permission system
  ///
  /// Returns statistics about registered plugins and their permissions.
  ///
  /// ## Returns
  ///
  /// Map with statistics:
  /// - `total_plugins`: Total number of registered plugins
  /// - `avg_host_functions`: Average number of allowed host functions per plugin
  /// - `plugins_with_network`: Number of plugins with network access
  /// - `plugins_with_filesystem`: Number of plugins with filesystem access
  ///
  /// ## Example
  ///
  /// ```dart
  /// final stats = permissionSystem.getStatistics();
  /// print('Total plugins: ${stats['total_plugins']}');
  /// print('Avg host functions: ${stats['avg_host_functions']}');
  /// ```
  Map<String, dynamic> getStatistics() {
    if (_permissions.isEmpty) {
      return {
        'total_plugins': 0,
        'avg_host_functions': 0.0,
        'plugins_with_network': 0,
        'plugins_with_filesystem': 0,
      };
    }

    // Use fold instead of reduce to safely handle edge cases
    final totalHostFunctions = _permissions.values
        .map((p) => p.allowedHostFunctions.length)
        .fold<int>(0, (a, b) => a + b);

    final pluginsWithNetwork =
        _permissions.values.where((p) => p.canAccessNetwork).length;

    final pluginsWithFilesystem = _permissions.values
        .where((p) => p.filesystemAccess != FilesystemAccessLevel.none)
        .length;

    // CRITICAL: Check for division by zero when no permissions registered
    final avgHostFunctions = _permissions.isEmpty
        ? 0.0
        : totalHostFunctions / _permissions.length;

    return {
      'total_plugins': _permissions.length,
      'avg_host_functions': avgHostFunctions,
      'plugins_with_network': pluginsWithNetwork,
      'plugins_with_filesystem': pluginsWithFilesystem,
    };
  }

  /// Clear all permissions
  ///
  /// Removes all registered permissions. Use with caution.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Clear all permissions (e.g., during shutdown)
  /// permissionSystem.clear();
  /// ```
  void clear() {
    _permissions.clear();
  }
}
