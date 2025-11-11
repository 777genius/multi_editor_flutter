import 'dart:async';
import 'package:meta/meta.dart';

/// Plugin error
///
/// Represents an error that occurred in a plugin.
@immutable
class PluginError {
  /// Plugin ID
  final String pluginId;

  /// Error message
  final String message;

  /// Stack trace (if available)
  final StackTrace? stackTrace;

  /// Timestamp
  final DateTime timestamp;

  /// Error severity
  final ErrorSeverity severity;

  /// Additional context
  final Map<String, dynamic>? context;

  const PluginError({
    required this.pluginId,
    required this.message,
    this.stackTrace,
    required this.timestamp,
    this.severity = ErrorSeverity.error,
    this.context,
  });

  /// Create from exception
  factory PluginError.fromException(
    String pluginId,
    Object error,
    StackTrace? stackTrace, {
    ErrorSeverity severity = ErrorSeverity.error,
    Map<String, dynamic>? context,
  }) {
    return PluginError(
      pluginId: pluginId,
      message: error.toString(),
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
      severity: severity,
      context: context,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PluginError &&
          runtimeType == other.runtimeType &&
          pluginId == other.pluginId &&
          message == other.message &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(pluginId, message, timestamp);

  @override
  String toString() =>
      'PluginError($pluginId, $severity): $message at ${timestamp.toIso8601String()}';
}

/// Error severity
enum ErrorSeverity {
  /// Debug-level error (lowest severity)
  debug,

  /// Info-level error
  info,

  /// Warning-level error
  warning,

  /// Error-level error
  error,

  /// Fatal error (highest severity)
  fatal,
}

/// Error tracker
///
/// Tracks plugin errors with history, streaming, and statistics.
/// Implements the Error Tracking pattern from architecture document (lines 1003-1052).
///
/// ## Design Principles
///
/// - **Single Responsibility**: Only tracks and reports errors
/// - **Observer Pattern**: Streams errors to subscribers
/// - **Bounded History**: Limits history per plugin to prevent memory leaks
///
/// ## Concurrency
///
/// **IMPORTANT**: This class is NOT thread-safe. All operations should be
/// called from the same isolate. Flutter applications typically run in a
/// single isolate, so this is not a concern for most use cases.
///
/// ## Example
///
/// ```dart
/// final tracker = ErrorTracker(maxErrorsPerPlugin: 100);
///
/// // Track error
/// tracker.trackError(
///   'plugin.file-icons',
///   exception,
///   stackTrace,
/// );
///
/// // Subscribe to errors
/// tracker.errors.listen((error) {
///   print('[Plugin Error] ${error.pluginId}: ${error.message}');
/// });
///
/// // Get error history
/// final errors = tracker.getErrors('plugin.file-icons');
///
/// // Get statistics
/// final stats = tracker.getStatistics();
/// print('Total errors: ${stats['total_errors']}');
/// ```
class ErrorTracker {
  final StreamController<PluginError> _errorStream =
      StreamController.broadcast();

  final Map<String, List<PluginError>> _errorHistory = {};
  final int maxErrorsPerPlugin;

  /// Create error tracker
  ///
  /// ## Parameters
  ///
  /// - `maxErrorsPerPlugin`: Maximum number of errors to keep per plugin (default: 100)
  ErrorTracker({this.maxErrorsPerPlugin = 100});

  /// Track error
  ///
  /// Records an error for a plugin and notifies subscribers.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  /// - `error`: Error object
  /// - `stackTrace`: Stack trace (optional)
  /// - `severity`: Error severity (default: error)
  /// - `context`: Additional context (optional)
  ///
  /// ## Example
  ///
  /// ```dart
  /// try {
  ///   await plugin.handleEvent(event);
  /// } catch (e, stack) {
  ///   tracker.trackError('plugin.example', e, stack);
  /// }
  /// ```
  void trackError(
    String pluginId,
    Object error,
    StackTrace? stackTrace, {
    ErrorSeverity severity = ErrorSeverity.error,
    Map<String, dynamic>? context,
  }) {
    final pluginError = PluginError.fromException(
      pluginId,
      error,
      stackTrace,
      severity: severity,
      context: context,
    );

    // Add to history
    _errorHistory.putIfAbsent(pluginId, () => []);
    final history = _errorHistory[pluginId]!;
    history.add(pluginError);

    // Limit size
    if (history.length > maxErrorsPerPlugin) {
      history.removeAt(0);
    }

    // Dispatch event
    _errorStream.add(pluginError);

    // Log
    _logError(pluginError);
  }

  /// Track custom error
  ///
  /// Records a custom PluginError.
  ///
  /// ## Parameters
  ///
  /// - `error`: Plugin error to track
  void trackCustomError(PluginError error) {
    // Add to history
    _errorHistory.putIfAbsent(error.pluginId, () => []);
    final history = _errorHistory[error.pluginId]!;
    history.add(error);

    // Limit size
    if (history.length > maxErrorsPerPlugin) {
      history.removeAt(0);
    }

    // Dispatch event
    _errorStream.add(error);

    // Log
    _logError(error);
  }

  /// Get errors for plugin
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  ///
  /// ## Returns
  ///
  /// List of errors for this plugin (most recent last)
  List<PluginError> getErrors(String pluginId) {
    return List.from(_errorHistory[pluginId] ?? []);
  }

  /// Get recent errors for plugin
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  /// - `count`: Number of recent errors to return
  ///
  /// ## Returns
  ///
  /// List of recent errors (most recent last)
  List<PluginError> getRecentErrors(String pluginId, {int count = 10}) {
    final errors = _errorHistory[pluginId] ?? [];
    final startIndex = errors.length > count ? errors.length - count : 0;
    return errors.sublist(startIndex);
  }

  /// Get all errors
  ///
  /// ## Returns
  ///
  /// Map of pluginId → error list
  Map<String, List<PluginError>> getAllErrors() {
    return Map.fromEntries(
      _errorHistory.entries.map(
        (entry) => MapEntry(entry.key, List.from(entry.value)),
      ),
    );
  }

  /// Get errors by severity
  ///
  /// ## Parameters
  ///
  /// - `severity`: Severity level to filter
  ///
  /// ## Returns
  ///
  /// List of errors with given severity
  List<PluginError> getErrorsBySeverity(ErrorSeverity severity) {
    final allErrors = <PluginError>[];
    for (final errors in _errorHistory.values) {
      allErrors.addAll(errors.where((e) => e.severity == severity));
    }
    return allErrors;
  }

  /// Check if plugin has errors
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  ///
  /// ## Returns
  ///
  /// `true` if plugin has any errors
  bool hasErrors(String pluginId) {
    return _errorHistory[pluginId]?.isNotEmpty ?? false;
  }

  /// Get error count for plugin
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  ///
  /// ## Returns
  ///
  /// Number of errors for this plugin
  int getErrorCount(String pluginId) {
    return _errorHistory[pluginId]?.length ?? 0;
  }

  /// Get total error count
  ///
  /// ## Returns
  ///
  /// Total number of tracked errors
  int getTotalErrorCount() {
    return _errorHistory.values.fold<int>(
      0,
      (sum, errors) => sum + errors.length,
    );
  }

  /// Clear errors for plugin
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  void clearErrors(String pluginId) {
    _errorHistory[pluginId]?.clear();
  }

  /// Clear all errors
  void clearAllErrors() {
    _errorHistory.clear();
  }

  /// Stream of all errors
  ///
  /// Subscribe to receive notifications when errors are tracked.
  Stream<PluginError> get errors => _errorStream.stream;

  /// Stream of errors for specific plugin
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  ///
  /// ## Returns
  ///
  /// Stream of errors for this plugin
  Stream<PluginError> errorsFor(String pluginId) {
    return _errorStream.stream.where((error) => error.pluginId == pluginId);
  }

  /// Stream of errors by severity
  ///
  /// ## Parameters
  ///
  /// - `severity`: Severity level to filter
  ///
  /// ## Returns
  ///
  /// Stream of errors with given severity
  Stream<PluginError> errorsBySeverity(ErrorSeverity severity) {
    return _errorStream.stream.where((error) => error.severity == severity);
  }

  /// Get statistics
  ///
  /// ## Returns
  ///
  /// Map with error statistics:
  /// - `total_errors`: Total number of errors
  /// - `plugins_with_errors`: Number of plugins that have errors
  /// - `most_errors_plugin`: Plugin with most errors
  /// - `most_errors_count`: Error count for plugin with most errors
  /// - `by_severity`: Breakdown by severity
  Map<String, dynamic> getStatistics() {
    // Find plugin with most errors
    String? mostErrorsPlugin;
    int maxErrors = 0;
    for (final entry in _errorHistory.entries) {
      if (entry.value.length > maxErrors) {
        maxErrors = entry.value.length;
        mostErrorsPlugin = entry.key;
      }
    }

    // Count by severity
    final bySeverity = <String, int>{};
    for (final errors in _errorHistory.values) {
      for (final error in errors) {
        final severity = error.severity.name;
        bySeverity[severity] = (bySeverity[severity] ?? 0) + 1;
      }
    }

    return {
      'total_errors': getTotalErrorCount(),
      'plugins_with_errors': _errorHistory.length,
      if (mostErrorsPlugin != null) 'most_errors_plugin': mostErrorsPlugin,
      if (mostErrorsPlugin != null) 'most_errors_count': maxErrors,
      'by_severity': bySeverity,
    };
  }

  /// Log error (internal)
  void _logError(PluginError error) {
    final severity = error.severity.name.toUpperCase();
    print('[$severity] Plugin ${error.pluginId}: ${error.message}');
    if (error.stackTrace != null) {
      print('Stack trace:\n${error.stackTrace}');
    }
  }

  /// Dispose tracker
  ///
  /// Closes the error stream.
  Future<void> dispose() async {
    await _errorStream.close();
  }

  @override
  String toString() {
    final stats = getStatistics();
    return 'ErrorTracker(${stats['total_errors']} errors, ${stats['plugins_with_errors']} plugins)';
  }
}
