import 'dart:async';
import 'package:dio/dio.dart';
import 'logging_service.dart';

/// Circuit Breaker State
enum CircuitBreakerState {
  closed, // Normal operation
  open, // Failing, rejecting requests
  halfOpen, // Testing if service recovered
}

/// Circuit Breaker Interceptor
/// Prevents cascading failures by stopping requests to failing services
class CircuitBreakerInterceptor extends Interceptor {
  final int failureThreshold;
  final Duration openDuration;
  final Duration halfOpenTimeout;
  final LoggingService _logger;

  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  int _successCount = 0;
  DateTime? _lastFailureTime;
  Timer? _resetTimer;

  CircuitBreakerInterceptor({
    this.failureThreshold = 5,
    this.openDuration = const Duration(seconds: 60),
    this.halfOpenTimeout = const Duration(seconds: 30),
    LoggingService? logger,
  }) : _logger = logger ?? LoggingService();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Check if circuit should transition to half-open
    if (_state == CircuitBreakerState.open) {
      final timeSinceFailure = DateTime.now().difference(_lastFailureTime!);

      if (timeSinceFailure >= openDuration) {
        _transitionToHalfOpen();
      } else {
        _logger.warning(
          'Circuit breaker OPEN: rejecting request to ${options.uri} '
          '(${(openDuration - timeSinceFailure).inSeconds}s until retry)',
        );
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            error: 'Circuit breaker is OPEN - service unavailable',
          ),
        );
      }
    }

    return handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    _recordSuccess();
    return handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    // Only count network/server errors, not client errors
    if (_shouldCountFailure(err)) {
      _recordFailure();
    }

    return handler.next(err);
  }

  /// Check if error should count towards circuit breaker
  bool _shouldCountFailure(DioException err) {
    // Count network errors
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    // Count 5xx server errors
    final statusCode = err.response?.statusCode;
    if (statusCode != null && statusCode >= 500) {
      return true;
    }

    return false;
  }

  /// Record successful request
  void _recordSuccess() {
    if (_state == CircuitBreakerState.halfOpen) {
      _successCount++;
      _logger.info('Circuit breaker: success in half-open state ($_successCount successes)');

      // If enough successes, close the circuit
      if (_successCount >= 3) {
        _transitionToClosed();
      }
    }

    // Reset failure count on success in closed state
    if (_state == CircuitBreakerState.closed) {
      _failureCount = 0;
    }
  }

  /// Record failed request
  void _recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    _logger.warning(
      'Circuit breaker: failure recorded ($_failureCount/$failureThreshold) - state: ${_state.name}',
    );

    if (_state == CircuitBreakerState.closed &&
        _failureCount >= failureThreshold) {
      _transitionToOpen();
    } else if (_state == CircuitBreakerState.halfOpen) {
      // Failed in half-open, go back to open
      _transitionToOpen();
    }
  }

  /// Transition to OPEN state (circuit is open, rejecting requests)
  void _transitionToOpen() {
    _state = CircuitBreakerState.open;
    _successCount = 0;

    _logger.error(
      'Circuit breaker: OPENED after $_failureCount failures. '
      'Requests will be rejected for ${openDuration.inSeconds}s',
    );

    // Schedule transition to half-open
    _resetTimer?.cancel();
    _resetTimer = Timer(openDuration, () {
      _transitionToHalfOpen();
    });
  }

  /// Transition to HALF_OPEN state (testing if service recovered)
  void _transitionToHalfOpen() {
    _state = CircuitBreakerState.halfOpen;
    _failureCount = 0;
    _successCount = 0;

    _logger.info('Circuit breaker: transitioning to HALF_OPEN (testing service recovery)');

    // Set timeout for half-open state
    _resetTimer?.cancel();
    _resetTimer = Timer(halfOpenTimeout, () {
      if (_state == CircuitBreakerState.halfOpen) {
        // If still half-open after timeout, go back to open
        _logger.warning('Circuit breaker: half-open timeout, reopening circuit');
        _transitionToOpen();
      }
    });
  }

  /// Transition to CLOSED state (normal operation)
  void _transitionToClosed() {
    _state = CircuitBreakerState.closed;
    _failureCount = 0;
    _successCount = 0;

    _logger.info('Circuit breaker: CLOSED (service recovered, normal operation resumed)');

    _resetTimer?.cancel();
  }

  /// Get current circuit breaker status
  Map<String, dynamic> getStatus() {
    return {
      'state': _state.name,
      'failureCount': _failureCount,
      'successCount': _successCount,
      'failureThreshold': failureThreshold,
      'lastFailureTime': _lastFailureTime?.toIso8601String(),
    };
  }

  /// Manually reset circuit breaker
  void reset() {
    _logger.info('Circuit breaker: manual reset');
    _transitionToClosed();
  }

  /// Dispose resources
  void dispose() {
    _resetTimer?.cancel();
  }
}
