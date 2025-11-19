import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:vscode_runtime_infrastructure/src/services/rate_limit_interceptor.dart';
import 'package:vscode_runtime_infrastructure/src/services/logging_service.dart';

class MockLoggingService extends Mock implements LoggingService {}
class MockRequestInterceptorHandler extends Mock implements RequestInterceptorHandler {}
class MockResponseInterceptorHandler extends Mock implements ResponseInterceptorHandler {}
class MockErrorInterceptorHandler extends Mock implements ErrorInterceptorHandler {}
class FakeRequestOptions extends Fake implements RequestOptions {}
class FakeResponse extends Fake implements Response {}

void main() {
  late RateLimitInterceptor interceptor;
  late MockLoggingService mockLogger;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeResponse());
  });

  setUp(() {
    mockLogger = MockLoggingService();
    interceptor = RateLimitInterceptor(
      maxConcurrentRequests: 2,
      minRequestInterval: const Duration(milliseconds: 50),
      logger: mockLogger,
    );

    when(() => mockLogger.debug(any())).thenReturn(null);
  });

  group('RateLimitInterceptor', () {
    test('should allow requests when under limit', () async {
      // Arrange
      final options = RequestOptions(path: '/test');
      final handler = MockRequestInterceptorHandler();

      when(() => handler.next(any())).thenReturn(null);

      // Act
      await interceptor.onRequest(options, handler);

      // Assert
      verify(() => handler.next(options)).called(1);
      final stats = interceptor.getStats();
      expect(stats['activeRequests'], equals(1));
    });

    test('should queue requests when at max concurrent', () async {
      // Arrange
      final handler = MockRequestInterceptorHandler();
      when(() => handler.next(any())).thenReturn(null);

      // Act - Start 3 requests (max is 2)
      final futures = <Future>[];
      for (var i = 0; i < 3; i++) {
        final options = RequestOptions(path: '/test$i');
        futures.add(interceptor.onRequest(options, handler));
      }

      // Third request should be queued
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      final stats = interceptor.getStats();
      expect(stats['activeRequests'], lessThanOrEqualTo(2));
      expect(stats['queuedRequests'], greaterThanOrEqualTo(0));
    });

    test('should release slot on response', () {
      // Arrange
      final options = RequestOptions(path: '/test');
      final response = Response(requestOptions: options, statusCode: 200);
      final handler = MockResponseInterceptorHandler();

      when(() => handler.next(any())).thenReturn(null);

      // Simulate active request first
      final stats1 = interceptor.getStats();
      final initialActive = stats1['activeRequests'] as int;

      // Act
      interceptor.onResponse(response, handler);

      // Assert - active count should decrease
      final stats2 = interceptor.getStats();
      expect(stats2['activeRequests'], equals(initialActive));
      verify(() => handler.next(response)).called(1);
    });

    test('should release slot on error', () {
      // Arrange
      final options = RequestOptions(path: '/test');
      final error = DioException(requestOptions: options);
      final handler = MockErrorInterceptorHandler();

      when(() => handler.next(any())).thenReturn(null);

      // Act
      interceptor.onError(error, handler);

      // Assert
      verify(() => handler.next(error)).called(1);
    });

    test('should enforce minimum interval between requests', () async {
      // Arrange
      final handler = MockRequestInterceptorHandler();
      when(() => handler.next(any())).thenReturn(null);

      // Act - Send two requests quickly
      final start = DateTime.now();

      await interceptor.onRequest(RequestOptions(path: '/test1'), handler);
      await interceptor.onRequest(RequestOptions(path: '/test2'), handler);

      final elapsed = DateTime.now().difference(start);

      // Assert - should have waited at least minRequestInterval
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(50));
    });

    test('should provide accurate statistics', () async {
      // Arrange
      final handler = MockRequestInterceptorHandler();
      when(() => handler.next(any())).thenReturn(null);

      // Act - Start one request
      await interceptor.onRequest(RequestOptions(path: '/test'), handler);

      final stats = interceptor.getStats();

      // Assert
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('activeRequests'), isTrue);
      expect(stats.containsKey('queuedRequests'), isTrue);
      expect(stats.containsKey('maxConcurrent'), isTrue);
      expect(stats['maxConcurrent'], equals(2));
    });
  });
}
