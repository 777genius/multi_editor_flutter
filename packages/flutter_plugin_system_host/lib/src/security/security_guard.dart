import 'package:flutter_plugin_system_core/flutter_plugin_system_core.dart';
import 'permission_system.dart';

/// Security guard
///
/// Enforces security policies and runtime limits for plugins.
/// Implements the Security Guard pattern from architecture document (lines 833-863).
///
/// ## Design Principles
///
/// - **Defense in Depth**: Multiple security layers
/// - **Fail-Safe Defaults**: Deny access when in doubt
/// - **Runtime Enforcement**: Check permissions at every boundary
///
/// ## Example
///
/// ```dart
/// final permissionSystem = PermissionSystem();
/// final securityGuard = SecurityGuard(permissionSystem);
///
/// // Check host function permission
/// if (securityGuard.canCallHostFunction('plugin.example', 'get_file_content')) {
///   // Allow the call
/// } else {
///   // Deny the call
/// }
///
/// // Execute with timeout
/// final result = await securityGuard.executeWithTimeout(
///   'plugin.example',
///   () => plugin.handleEvent(event),
/// );
/// ```
class SecurityGuard {
  final PermissionSystem _permissions;

  /// Create security guard
  ///
  /// ## Parameters
  ///
  /// - `permissions`: Permission system for checking permissions
  SecurityGuard(this._permissions);

  /// Check if plugin can call host function
  ///
  /// Checks if the plugin has permission to call the specified host function.
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
  /// if (securityGuard.canCallHostFunction('plugin.example', 'log_info')) {
  ///   await hostFunction.call(args);
  /// } else {
  ///   throw PermissionDeniedException('log_info', pluginId: 'plugin.example');
  /// }
  /// ```
  bool canCallHostFunction(String pluginId, String functionName) {
    return _permissions.canCallHostFunction(pluginId, functionName);
  }

  /// Enforce host function permission
  ///
  /// Throws [PermissionDeniedException] if plugin cannot call the host function.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  /// - `functionName`: Host function name
  ///
  /// ## Throws
  ///
  /// - [PermissionDeniedException] if permission denied
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Throws if permission denied
  /// securityGuard.enforceHostFunctionPermission('plugin.example', 'log_info');
  /// await hostFunction.call(args);
  /// ```
  void enforceHostFunctionPermission(String pluginId, String functionName) {
    if (!canCallHostFunction(pluginId, functionName)) {
      throw PermissionDeniedException(
        'host_function:$functionName',
        pluginId: pluginId,
      );
    }
  }

  /// Execute with timeout
  ///
  /// Executes function with timeout based on plugin's permission settings.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  /// - `fn`: Function to execute
  ///
  /// ## Returns
  ///
  /// Function result
  ///
  /// ## Throws
  ///
  /// - [PluginTimeoutException] if function exceeds timeout
  ///
  /// ## Example
  ///
  /// ```dart
  /// final result = await securityGuard.executeWithTimeout(
  ///   'plugin.slow',
  ///   () => plugin.processLargeFile(file),
  /// );
  /// ```
  Future<T> executeWithTimeout<T>(
    String pluginId,
    Future<T> Function() fn,
  ) async {
    final permissions = _permissions.getPermissions(pluginId);
    final timeout = permissions.maxExecutionTime;

    try {
      return await fn().timeout(
        timeout,
        onTimeout: () => throw PluginTimeoutException(pluginId, timeout),
      );
    } catch (e) {
      // Re-throw timeout exception as-is
      if (e is PluginTimeoutException) {
        rethrow;
      }
      // Wrap other errors
      throw PluginExecutionException(
        'Execution failed: $e',
        pluginId: pluginId,
        originalError: e,
      );
    }
  }

  /// Check memory limit
  ///
  /// Checks if memory usage is within the plugin's limit.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  /// - `usedBytes`: Current memory usage in bytes
  ///
  /// ## Throws
  ///
  /// - [PluginMemoryLimitException] if memory limit exceeded
  ///
  /// ## Example
  ///
  /// ```dart
  /// final usedMemory = runtime.getMemoryUsage(pluginId);
  /// securityGuard.checkMemoryLimit('plugin.example', usedMemory);
  /// ```
  void checkMemoryLimit(String pluginId, int usedBytes) {
    final permissions = _permissions.getPermissions(pluginId);
    final limit = permissions.maxMemoryBytes;

    if (usedBytes > limit) {
      throw PluginMemoryLimitException(pluginId, usedBytes, limit);
    }
  }

  /// Enforce memory limit
  ///
  /// Alias for [checkMemoryLimit] for consistency with other enforce methods.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  /// - `usedBytes`: Current memory usage in bytes
  ///
  /// ## Throws
  ///
  /// - [PluginMemoryLimitException] if memory limit exceeded
  void enforceMemoryLimit(String pluginId, int usedBytes) {
    checkMemoryLimit(pluginId, usedBytes);
  }

  /// Check network permission
  ///
  /// Returns true if plugin has network access permission.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  ///
  /// ## Returns
  ///
  /// `true` if allowed, `false` otherwise
  ///
  /// ## Example
  ///
  /// ```dart
  /// if (securityGuard.canAccessNetwork('plugin.example')) {
  ///   await http.get(url);
  /// }
  /// ```
  bool canAccessNetwork(String pluginId) {
    final permissions = _permissions.getPermissions(pluginId);
    return permissions.canAccessNetwork;
  }

  /// Enforce network permission
  ///
  /// Throws [PermissionDeniedException] if plugin cannot access network.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  ///
  /// ## Throws
  ///
  /// - [PermissionDeniedException] if permission denied
  ///
  /// ## Example
  ///
  /// ```dart
  /// securityGuard.enforceNetworkPermission('plugin.example');
  /// await http.get(url);
  /// ```
  void enforceNetworkPermission(String pluginId) {
    if (!canAccessNetwork(pluginId)) {
      throw PermissionDeniedException(
        'network',
        pluginId: pluginId,
      );
    }
  }

  /// Get filesystem access level
  ///
  /// Returns the filesystem access level for the plugin.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  ///
  /// ## Returns
  ///
  /// Filesystem access level
  ///
  /// ## Example
  ///
  /// ```dart
  /// final level = securityGuard.getFilesystemAccess('plugin.example');
  /// if (level == FilesystemAccessLevel.readOnly) {
  ///   // Allow read operations only
  /// }
  /// ```
  FilesystemAccessLevel getFilesystemAccess(String pluginId) {
    final permissions = _permissions.getPermissions(pluginId);
    return permissions.filesystemAccess;
  }

  /// Check filesystem permission
  ///
  /// Checks if plugin has the specified filesystem access level.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  /// - `requiredLevel`: Required access level
  ///
  /// ## Returns
  ///
  /// `true` if allowed, `false` otherwise
  ///
  /// ## Example
  ///
  /// ```dart
  /// if (securityGuard.canAccessFilesystem('plugin.example', FilesystemAccessLevel.readOnly)) {
  ///   await file.readAsString();
  /// }
  /// ```
  bool canAccessFilesystem(
    String pluginId,
    FilesystemAccessLevel requiredLevel,
  ) {
    final currentLevel = getFilesystemAccess(pluginId);

    // Define access level hierarchy
    final hierarchy = [
      FilesystemAccessLevel.none,
      FilesystemAccessLevel.readOnly,
      FilesystemAccessLevel.readWrite,
      FilesystemAccessLevel.full,
    ];

    final currentIndex = hierarchy.indexOf(currentLevel);
    final requiredIndex = hierarchy.indexOf(requiredLevel);

    return currentIndex >= requiredIndex;
  }

  /// Enforce filesystem permission
  ///
  /// Throws [PermissionDeniedException] if plugin doesn't have required filesystem access.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  /// - `requiredLevel`: Required access level
  ///
  /// ## Throws
  ///
  /// - [PermissionDeniedException] if permission denied
  ///
  /// ## Example
  ///
  /// ```dart
  /// securityGuard.enforceFilesystemPermission(
  ///   'plugin.example',
  ///   FilesystemAccessLevel.readWrite,
  /// );
  /// await file.writeAsString(content);
  /// ```
  void enforceFilesystemPermission(
    String pluginId,
    FilesystemAccessLevel requiredLevel,
  ) {
    if (!canAccessFilesystem(pluginId, requiredLevel)) {
      throw PermissionDeniedException(
        'filesystem:${requiredLevel.name}',
        pluginId: pluginId,
      );
    }
  }

  /// Get maximum execution time
  ///
  /// Returns the maximum execution time for the plugin.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  ///
  /// ## Returns
  ///
  /// Maximum execution time duration
  Duration getMaxExecutionTime(String pluginId) {
    final permissions = _permissions.getPermissions(pluginId);
    return permissions.maxExecutionTime;
  }

  /// Get maximum memory bytes
  ///
  /// Returns the maximum memory allocation for the plugin.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  ///
  /// ## Returns
  ///
  /// Maximum memory in bytes
  int getMaxMemoryBytes(String pluginId) {
    final permissions = _permissions.getPermissions(pluginId);
    return permissions.maxMemoryBytes;
  }

  /// Get maximum call depth
  ///
  /// Returns the maximum call stack depth for the plugin.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  ///
  /// ## Returns
  ///
  /// Maximum call depth
  int getMaxCallDepth(String pluginId) {
    final permissions = _permissions.getPermissions(pluginId);
    return permissions.maxCallDepth;
  }

  /// Get security summary for plugin
  ///
  /// Returns a summary of all security settings for the plugin.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  ///
  /// ## Returns
  ///
  /// Map with security summary:
  /// - `allowed_host_functions`: List of allowed host function names
  /// - `max_execution_time_ms`: Maximum execution time in milliseconds
  /// - `max_memory_bytes`: Maximum memory in bytes
  /// - `max_call_depth`: Maximum call depth
  /// - `can_access_network`: Network access permission
  /// - `filesystem_access`: Filesystem access level
  ///
  /// ## Example
  ///
  /// ```dart
  /// final summary = securityGuard.getSecuritySummary('plugin.example');
  /// print('Allowed host functions: ${summary['allowed_host_functions']}');
  /// print('Max execution time: ${summary['max_execution_time_ms']}ms');
  /// ```
  Map<String, dynamic> getSecuritySummary(String pluginId) {
    final permissions = _permissions.getPermissions(pluginId);

    return {
      'plugin_id': pluginId,
      'allowed_host_functions': permissions.allowedHostFunctions,
      'max_execution_time_ms': permissions.maxExecutionTime.inMilliseconds,
      'max_memory_bytes': permissions.maxMemoryBytes,
      'max_call_depth': permissions.maxCallDepth,
      'can_access_network': permissions.canAccessNetwork,
      'filesystem_access': permissions.filesystemAccess.name,
      'custom_limits': permissions.customLimits ?? {},
    };
  }
}
