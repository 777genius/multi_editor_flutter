/// Base plugin exception
///
/// All plugin-related exceptions extend from this class.
/// Provides structured error information for debugging and recovery.
class PluginException implements Exception {
  /// Error message
  final String message;

  /// Plugin ID (if applicable)
  final String? pluginId;

  /// Additional context
  final Map<String, dynamic>? context;

  /// Original error (if wrapping another exception)
  final Object? originalError;

  /// Stack trace
  final StackTrace? stackTrace;

  const PluginException(
    this.message, {
    this.pluginId,
    this.context,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer('PluginException: $message');
    if (pluginId != null) {
      buffer.write(' (plugin: $pluginId)');
    }
    if (originalError != null) {
      buffer.write('\nCaused by: $originalError');
    }
    if (context != null && context!.isNotEmpty) {
      buffer.write('\nContext: $context');
    }
    return buffer.toString();
  }
}

// ============================================================================
// Load Exceptions
// ============================================================================

/// Plugin load exception
///
/// Thrown when plugin cannot be loaded.
class PluginLoadException extends PluginException {
  const PluginLoadException(
    super.message, {
    super.pluginId,
    super.context,
    super.originalError,
    super.stackTrace,
  });
}

/// Plugin not found exception
///
/// Thrown when requested plugin does not exist.
class PluginNotFoundException extends PluginLoadException {
  const PluginNotFoundException(String pluginId)
      : super(
          'Plugin not found: $pluginId',
          pluginId: pluginId,
        );
}

/// Invalid manifest exception
///
/// Thrown when plugin manifest is malformed or invalid.
class InvalidManifestException extends PluginLoadException {
  const InvalidManifestException(
    super.message, {
    super.pluginId,
    super.context,
  });
}

/// Runtime not available exception
///
/// Thrown when required runtime is not available.
class RuntimeNotAvailableException extends PluginLoadException {
  /// Runtime type that was requested
  final String requestedRuntime;

  RuntimeNotAvailableException(this.requestedRuntime)
      : super('Runtime not available: $requestedRuntime');
}

// ============================================================================
// Initialization Exceptions
// ============================================================================

/// Plugin initialization exception
///
/// Thrown when plugin fails to initialize.
class PluginInitializationException extends PluginException {
  const PluginInitializationException(
    super.message, {
    super.pluginId,
    super.context,
    super.originalError,
    super.stackTrace,
  });
}

/// Dependency not met exception
///
/// Thrown when plugin dependency is missing or incompatible.
class DependencyNotMetException extends PluginInitializationException {
  /// Required dependency ID
  final String dependencyId;

  /// Required version (if specified)
  final String? requiredVersion;

  DependencyNotMetException(
    this.dependencyId, {
    this.requiredVersion,
    String? pluginId,
  }) : super(
          'Dependency not met: $dependencyId'
          '${requiredVersion != null ? ' (required: $requiredVersion)' : ''}',
          pluginId: pluginId,
        );
}

/// Permission denied exception
///
/// Thrown when plugin lacks required permission.
class PermissionDeniedException extends PluginInitializationException {
  /// Permission that was denied
  final String permission;

  PermissionDeniedException(
    this.permission, {
    String? pluginId,
  }) : super(
          'Permission denied: $permission',
          pluginId: pluginId,
        );
}

// ============================================================================
// Execution Exceptions
// ============================================================================

/// Plugin execution exception
///
/// Thrown when plugin encounters error during execution.
class PluginExecutionException extends PluginException {
  const PluginExecutionException(
    super.message, {
    super.pluginId,
    super.context,
    super.originalError,
    super.stackTrace,
  });
}

/// Plugin timeout exception
///
/// Thrown when plugin exceeds execution time limit.
class PluginTimeoutException extends PluginExecutionException {
  /// Timeout duration
  final Duration timeout;

  PluginTimeoutException(
    String pluginId,
    this.timeout,
  ) : super(
          'Plugin exceeded timeout: ${timeout.inMilliseconds}ms',
          pluginId: pluginId,
        );
}

/// Plugin memory limit exception
///
/// Thrown when plugin exceeds memory allocation limit.
class PluginMemoryLimitException extends PluginExecutionException {
  /// Memory used (bytes)
  final int usedBytes;

  /// Memory limit (bytes)
  final int limitBytes;

  PluginMemoryLimitException(
    String pluginId,
    this.usedBytes,
    this.limitBytes,
  ) : super(
          'Plugin exceeded memory limit: ${usedBytes} bytes (limit: ${limitBytes})',
          pluginId: pluginId,
        );
}

/// Host function exception
///
/// Thrown when host function fails.
class HostFunctionException extends PluginExecutionException {
  /// Host function name
  final String functionName;

  const HostFunctionException(
    this.functionName,
    super.message, {
    super.pluginId,
    super.originalError,
    super.stackTrace,
  });
}

/// Host function not found exception
///
/// Thrown when plugin tries to call non-existent host function.
class HostFunctionNotFoundException extends HostFunctionException {
  HostFunctionNotFoundException(String functionName)
      : super(
          functionName,
          'Host function not found: $functionName',
        );
}

// ============================================================================
// Communication Exceptions
// ============================================================================

/// Plugin communication exception
///
/// Thrown when plugin communication fails.
class PluginCommunicationException extends PluginException {
  const PluginCommunicationException(
    super.message, {
    super.pluginId,
    super.originalError,
    super.stackTrace,
  });
}

/// Serialization exception
///
/// Thrown when data serialization fails.
class SerializationException extends PluginCommunicationException {
  const SerializationException(
    super.message, {
    super.pluginId,
    super.originalError,
  });
}

/// Deserialization exception
///
/// Thrown when data deserialization fails.
class DeserializationException extends PluginCommunicationException {
  const DeserializationException(
    super.message, {
    super.pluginId,
    super.originalError,
  });
}
