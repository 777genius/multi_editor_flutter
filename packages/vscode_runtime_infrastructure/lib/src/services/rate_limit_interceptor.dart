import 'dart:async';
import 'package:dio/dio.dart';
import 'logging_service.dart';

/// Rate Limiting Interceptor
/// Limits number of concurrent requests and request rate
class RateLimitInterceptor extends Interceptor {
  final int maxConcurrentRequests;
  final Duration minRequestInterval;
  final LoggingService _logger;

  int _activeRequests = 0;
  DateTime? _lastRequestTime;
  final _queue = <Completer<void>>[];

  RateLimitInterceptor({
    this.maxConcurrentRequests = 3,
    this.minRequestInterval = const Duration(milliseconds: 100),
    LoggingService? logger,
  }) : _logger = logger ?? LoggingService();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Wait if too many concurrent requests
    while (_activeRequests >= maxConcurrentRequests) {
      _logger.debug(
        'Rate limit: waiting for slot ($_activeRequests/$maxConcurrentRequests active)',
      );

      final completer = Completer<void>();
      _queue.add(completer);
      await completer.future;
    }

    // Wait if requests are too frequent
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < minRequestInterval) {
        final waitTime = minRequestInterval - timeSinceLastRequest;
        _logger.debug('Rate limit: waiting ${waitTime.inMilliseconds}ms between requests');
        await Future.delayed(waitTime);
      }
    }

    _activeRequests++;
    _lastRequestTime = DateTime.now();

    _logger.debug(
      'Request started: ${options.uri} ($_activeRequests/$maxConcurrentRequests active)',
    );

    return handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    _releaseSlot();
    _logger.debug(
      'Request completed: ${response.requestOptions.uri} ($_activeRequests/$maxConcurrentRequests active)',
    );
    return handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    _releaseSlot();
    _logger.debug(
      'Request error: ${err.requestOptions.uri} ($_activeRequests/$maxConcurrentRequests active)',
    );
    return handler.next(err);
  }

  /// Release a request slot and notify waiting requests
  void _releaseSlot() {
    _activeRequests--;

    // Notify next waiting request
    if (_queue.isNotEmpty) {
      final completer = _queue.removeAt(0);
      completer.complete();
    }
  }

  /// Get current rate limit stats
  Map<String, dynamic> getStats() {
    return {
      'activeRequests': _activeRequests,
      'queuedRequests': _queue.length,
      'maxConcurrent': maxConcurrentRequests,
      'lastRequestTime': _lastRequestTime?.toIso8601String(),
    };
  }
}
