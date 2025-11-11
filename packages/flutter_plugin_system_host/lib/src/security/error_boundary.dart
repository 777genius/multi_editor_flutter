import 'error_tracker.dart';

/// Error boundary
///
/// Provides error isolation for plugin execution.
/// Implements the Error Isolation pattern from architecture document (lines 1057-1081).
///
/// ## Design Principles
///
/// - **Error Isolation**: Plugin errors don't crash host
/// - **Graceful Fallback**: Provides fallback values on error
/// - **Error Tracking**: Integrates with ErrorTracker
///
/// ## Example
///
/// ```dart
/// final boundary = ErrorBoundary(tracker);
///
/// // Execute with error isolation
/// final result = await boundary.execute<String>(
///   'plugin.example',
///   () => plugin.handleEvent(event),
///   fallback: (error) => 'default_value',
/// );
///
/// // Execute without fallback (rethrows)
/// await boundary.execute(
///   'plugin.example',
///   () => plugin.initialize(context),
/// );
/// ```
class ErrorBoundary {
  final ErrorTracker _tracker;

  /// Create error boundary
  ///
  /// ## Parameters
  ///
  /// - `tracker`: Error tracker for logging errors
  ErrorBoundary(this._tracker);

  /// Execute function with error isolation
  ///
  /// Wraps function execution in try/catch, tracks errors, and provides fallback.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  /// - `fn`: Function to execute
  /// - `fallback`: Optional fallback function (called on error)
  /// - `severity`: Error severity for tracking (default: error)
  /// - `context`: Additional error context (optional)
  ///
  /// ## Returns
  ///
  /// Function result or fallback value
  ///
  /// ## Throws
  ///
  /// Rethrows exception if no fallback is provided
  ///
  /// ## Example
  ///
  /// ```dart
  /// // With fallback
  /// final icon = await boundary.execute<String>(
  ///   'plugin.file-icons',
  ///   () => plugin.resolveIcon('main.dart'),
  ///   fallback: (error) => 'default_icon.svg',
  /// );
  ///
  /// // Without fallback (rethrows on error)
  /// await boundary.execute(
  ///   'plugin.formatter',
  ///   () => plugin.formatDocument(doc),
  /// );
  /// ```
  Future<T> execute<T>(
    String pluginId,
    Future<T> Function() fn, {
    T Function(Object error)? fallback,
    ErrorSeverity severity = ErrorSeverity.error,
    Map<String, dynamic>? context,
  }) async {
    try {
      return await fn();
    } catch (e, stack) {
      // Track error
      _tracker.trackError(
        pluginId,
        e,
        stack,
        severity: severity,
        context: context,
      );

      // Return fallback or rethrow
      if (fallback != null) {
        return fallback(e);
      } else {
        rethrow;
      }
    }
  }

  /// Execute synchronous function with error isolation
  ///
  /// Synchronous version of [execute].
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  /// - `fn`: Function to execute
  /// - `fallback`: Optional fallback function (called on error)
  /// - `severity`: Error severity for tracking (default: error)
  /// - `context`: Additional error context (optional)
  ///
  /// ## Returns
  ///
  /// Function result or fallback value
  ///
  /// ## Throws
  ///
  /// Rethrows exception if no fallback is provided
  T executeSync<T>(
    String pluginId,
    T Function() fn, {
    T Function(Object error)? fallback,
    ErrorSeverity severity = ErrorSeverity.error,
    Map<String, dynamic>? context,
  }) {
    try {
      return fn();
    } catch (e, stack) {
      // Track error
      _tracker.trackError(
        pluginId,
        e,
        stack,
        severity: severity,
        context: context,
      );

      // Return fallback or rethrow
      if (fallback != null) {
        return fallback(e);
      } else {
        rethrow;
      }
    }
  }

  /// Execute with timeout and error isolation
  ///
  /// Combines timeout with error isolation.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  /// - `fn`: Function to execute
  /// - `timeout`: Timeout duration
  /// - `fallback`: Optional fallback function (called on error or timeout)
  /// - `severity`: Error severity for tracking (default: error)
  /// - `context`: Additional error context (optional)
  ///
  /// ## Returns
  ///
  /// Function result or fallback value
  ///
  /// ## Throws
  ///
  /// - [TimeoutException] if function times out (when no fallback)
  /// - Rethrows exception if no fallback is provided
  ///
  /// ## Example
  ///
  /// ```dart
  /// final result = await boundary.executeWithTimeout(
  ///   'plugin.slow',
  ///   () => plugin.processLargeFile(file),
  ///   timeout: Duration(seconds: 5),
  ///   fallback: (error) => null,
  /// );
  /// ```
  Future<T> executeWithTimeout<T>(
    String pluginId,
    Future<T> Function() fn, {
    required Duration timeout,
    T Function(Object error)? fallback,
    ErrorSeverity severity = ErrorSeverity.error,
    Map<String, dynamic>? context,
  }) async {
    return execute(
      pluginId,
      () => fn().timeout(timeout),
      fallback: fallback,
      severity: severity,
      context: context,
    );
  }

  /// Execute multiple functions in parallel with error isolation
  ///
  /// Executes functions in parallel, isolating errors for each.
  ///
  /// ## Parameters
  ///
  /// - `executions`: Map of pluginId → function
  /// - `fallback`: Optional fallback function (called on error for each)
  /// - `severity`: Error severity for tracking (default: error)
  ///
  /// ## Returns
  ///
  /// Map of pluginId → result (or fallback value)
  ///
  /// ## Example
  ///
  /// ```dart
  /// final results = await boundary.executeAll({
  ///   'plugin1': () => plugin1.process(),
  ///   'plugin2': () => plugin2.process(),
  ///   'plugin3': () => plugin3.process(),
  /// }, fallback: (error) => null);
  /// ```
  Future<Map<String, T>> executeAll<T>(
    Map<String, Future<T> Function()> executions, {
    T Function(Object error)? fallback,
    ErrorSeverity severity = ErrorSeverity.error,
  }) async {
    final results = <String, T>{};

    await Future.wait(
      executions.entries.map((entry) async {
        final result = await execute(
          entry.key,
          entry.value,
          fallback: fallback,
          severity: severity,
        );
        results[entry.key] = result;
      }),
    );

    return results;
  }

  /// Execute with retry on failure
  ///
  /// Retries function execution on failure.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  /// - `fn`: Function to execute
  /// - `maxRetries`: Maximum number of retries (default: 3)
  /// - `retryDelay`: Delay between retries (default: 1 second)
  /// - `fallback`: Optional fallback function (called after all retries fail)
  /// - `severity`: Error severity for tracking (default: error)
  ///
  /// ## Returns
  ///
  /// Function result or fallback value
  ///
  /// ## Throws
  ///
  /// Rethrows last exception if no fallback is provided
  ///
  /// ## Example
  ///
  /// ```dart
  /// final result = await boundary.executeWithRetry(
  ///   'plugin.network',
  ///   () => plugin.fetchRemoteData(),
  ///   maxRetries: 3,
  ///   retryDelay: Duration(seconds: 2),
  ///   fallback: (error) => null,
  /// );
  /// ```
  Future<T> executeWithRetry<T>(
    String pluginId,
    Future<T> Function() fn, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
    T Function(Object error)? fallback,
    ErrorSeverity severity = ErrorSeverity.error,
  }) async {
    Object? lastError;
    StackTrace? lastStack;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await fn();
      } catch (e, stack) {
        lastError = e;
        lastStack = stack;

        // Track error
        _tracker.trackError(
          pluginId,
          e,
          stack,
          severity: attempt < maxRetries
              ? ErrorSeverity.warning
              : severity,
          context: {'attempt': attempt + 1, 'max_retries': maxRetries},
        );

        // Delay before retry (except on last attempt)
        if (attempt < maxRetries) {
          await Future.delayed(retryDelay);
        }
      }
    }

    // All retries failed
    if (fallback != null && lastError != null) {
      return fallback(lastError);
    } else if (lastError != null) {
      // Rethrow last error
      Error.throwWithStackTrace(lastError, lastStack!);
    }

    // Should never reach here
    throw StateError('executeWithRetry: unexpected state');
  }
}
