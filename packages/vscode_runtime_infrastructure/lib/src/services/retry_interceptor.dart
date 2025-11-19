import 'dart:math';
import 'package:dio/dio.dart';
import 'logging_service.dart';

/// Retry Interceptor with Exponential Backoff
/// Automatically retries failed requests with configurable delay
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final LoggingService _logger;

  RetryInterceptor({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    LoggingService? logger,
  }) : _logger = logger ?? LoggingService();

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final retryCount = request.extra['retry_count'] as int? ?? 0;

    // Don't retry if:
    // 1. Max retries exceeded
    // 2. Request was cancelled
    // 3. Client error (4xx) - these won't succeed on retry
    if (retryCount >= maxRetries ||
        err.type == DioExceptionType.cancel ||
        _isClientError(err)) {
      _logger.warning(
        'Not retrying request to ${request.path}: '
        'retries=$retryCount, type=${err.type}, status=${err.response?.statusCode}',
      );
      return handler.next(err);
    }

    // Retry on network errors, timeouts, and server errors (5xx)
    if (_shouldRetry(err)) {
      final delay = _calculateDelay(retryCount);

      _logger.info(
        'Retrying request to ${request.path} (attempt ${retryCount + 1}/$maxRetries) after ${delay.inMilliseconds}ms',
      );

      await Future.delayed(delay);

      // Increment retry count
      request.extra['retry_count'] = retryCount + 1;

      try {
        // Retry the request
        final response = await Dio().fetch(request);
        return handler.resolve(response);
      } on DioException catch (e) {
        // If retry fails, pass the error to next handler
        return super.onError(e, handler);
      }
    }

    return handler.next(err);
  }

  /// Check if request should be retried
  bool _shouldRetry(DioException err) {
    // Retry on connection errors
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    // Retry on 5xx server errors
    final statusCode = err.response?.statusCode;
    if (statusCode != null && statusCode >= 500 && statusCode < 600) {
      return true;
    }

    // Retry on 429 (rate limit) with backoff
    if (statusCode == 429) {
      return true;
    }

    return false;
  }

  /// Check if error is a client error (4xx)
  bool _isClientError(DioException err) {
    final statusCode = err.response?.statusCode;
    return statusCode != null && statusCode >= 400 && statusCode < 500 && statusCode != 429;
  }

  /// Calculate delay with exponential backoff and jitter
  Duration _calculateDelay(int retryCount) {
    // Exponential backoff: initialDelay * (backoffMultiplier ^ retryCount)
    final delayMs = initialDelay.inMilliseconds *
        pow(backoffMultiplier, retryCount).toInt();

    // Add jitter (±20%) to avoid thundering herd
    final jitter = (delayMs * 0.2 * (Random().nextDouble() - 0.5)).toInt();

    return Duration(milliseconds: delayMs + jitter);
  }
}
