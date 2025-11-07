/// Represents the current activation state of a plugin in PluginManager
enum PluginActivationState {
  /// Plugin is registered but not activated
  idle,

  /// Plugin is currently being activated
  activating,

  /// Plugin is active and running
  active,

  /// Plugin encountered an error
  error,

  /// Plugin is disabled (manually or after repeated errors)
  disabled,
}

/// Information about a plugin's current status
class PluginStatus {
  final String pluginId;
  final PluginActivationState state;
  final DateTime? lastStateChange;
  final Object? lastError;
  final StackTrace? lastErrorStackTrace;
  final int errorCount;
  final DateTime? lastErrorTime;

  const PluginStatus({
    required this.pluginId,
    required this.state,
    this.lastStateChange,
    this.lastError,
    this.lastErrorStackTrace,
    this.errorCount = 0,
    this.lastErrorTime,
  });

  PluginStatus copyWith({
    PluginActivationState? state,
    DateTime? lastStateChange,
    Object? lastError,
    StackTrace? lastErrorStackTrace,
    int? errorCount,
    DateTime? lastErrorTime,
  }) {
    return PluginStatus(
      pluginId: pluginId,
      state: state ?? this.state,
      lastStateChange: lastStateChange ?? this.lastStateChange,
      lastError: lastError ?? this.lastError,
      lastErrorStackTrace: lastErrorStackTrace ?? this.lastErrorStackTrace,
      errorCount: errorCount ?? this.errorCount,
      lastErrorTime: lastErrorTime ?? this.lastErrorTime,
    );
  }

  bool get isActive => state == PluginActivationState.active;
  bool get isError => state == PluginActivationState.error;
  bool get isDisabled => state == PluginActivationState.disabled;
  bool get canRetry => state == PluginActivationState.error && errorCount < 3;
}
