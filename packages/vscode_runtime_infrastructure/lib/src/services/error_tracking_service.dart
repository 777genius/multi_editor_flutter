import 'package:sentry/sentry.dart';

/// Error Tracking Service
/// Integrates with Sentry for error monitoring and tracking
class ErrorTrackingService {
  final SentryClient _sentry;
  final bool _enabled;

  ErrorTrackingService({
    required String dsn,
    String environment = 'production',
    bool enabled = true,
    double sampleRate = 1.0,
  })  : _enabled = enabled,
        _sentry = SentryClient(
          SentryOptions(dsn: dsn)
            ..environment = environment
            ..tracesSampleRate = sampleRate
            ..sendDefaultPii = false
            ..attachStacktrace = true
            ..diagnosticLevel = SentryLevel.warning,
        );

  /// Capture exception with context
  Future<void> captureException(
    dynamic exception, {
    StackTrace? stackTrace,
    String? message,
    Map<String, dynamic>? extra,
    SentryLevel level = SentryLevel.error,
  }) async {
    if (!_enabled) return;

    try {
      final event = SentryEvent(
        exception: exception,
        level: level,
        message: message != null ? SentryMessage(message) : null,
        timestamp: DateTime.now().toUtc(),
      );

      final scope = Scope(SentryOptions(dsn: ''));
      if (extra != null) {
        scope.setContexts('extra', extra);
      }

      await _sentry.captureEvent(
        event,
        stackTrace: stackTrace,
        scope: scope,
      );
    } catch (e) {
      // Don't let error tracking failures break the app
      print('Failed to capture exception: $e');
    }
  }

  /// Capture message with context
  Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extra,
  }) async {
    if (!_enabled) return;

    try {
      final event = SentryEvent(
        message: SentryMessage(message),
        level: level,
        timestamp: DateTime.now().toUtc(),
      );

      final scope = Scope(SentryOptions(dsn: ''));
      if (extra != null) {
        scope.setContexts('extra', extra);
      }

      await _sentry.captureEvent(event, scope: scope);
    } catch (e) {
      print('Failed to capture message: $e');
    }
  }

  /// Add breadcrumb for context
  void addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
    SentryLevel level = SentryLevel.info,
  }) {
    if (!_enabled) return;

    try {
      final breadcrumb = Breadcrumb(
        message: message,
        category: category,
        data: data,
        level: level,
        timestamp: DateTime.now().toUtc(),
      );

      _sentry.addBreadcrumb(breadcrumb);
    } catch (e) {
      print('Failed to add breadcrumb: $e');
    }
  }

  /// Set user context
  void setUser({
    String? id,
    String? email,
    String? username,
    Map<String, dynamic>? extra,
  }) {
    if (!_enabled) return;

    try {
      final user = SentryUser(
        id: id,
        email: email,
        username: username,
        data: extra,
      );

      _sentry.configureScope((scope) async => scope.setUser(user));
    } catch (e) {
      print('Failed to set user: $e');
    }
  }

  /// Set custom tags
  void setTag(String key, String value) {
    if (!_enabled) return;

    try {
      _sentry.configureScope((scope) async => scope.setTag(key, value));
    } catch (e) {
      print('Failed to set tag: $e');
    }
  }

  /// Set custom context
  void setContext(String key, Map<String, dynamic> context) {
    if (!_enabled) return;

    try {
      _sentry.configureScope((scope) async => scope.setContexts(key, context));
    } catch (e) {
      print('Failed to set context: $e');
    }
  }

  /// Close and cleanup
  Future<void> close() async {
    await _sentry.close();
  }
}
