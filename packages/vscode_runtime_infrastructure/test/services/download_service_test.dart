import 'dart:io';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart' as dio;
import 'package:vscode_runtime_core/vscode_runtime_core.dart';
import 'package:vscode_runtime_infrastructure/src/services/download_service.dart';
import 'package:vscode_runtime_infrastructure/src/services/logging_service.dart';

class MockDio extends Mock implements dio.Dio {}
class MockLoggingService extends Mock implements LoggingService {}
class FakeRequestOptions extends Fake implements dio.RequestOptions {}

void main() {
  late MockDio mockDio;
  late MockLoggingService mockLogger;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  setUp(() {
    mockDio = MockDio();
    mockLogger = MockLoggingService();

    when(() => mockLogger.info(any())).thenReturn(null);
    when(() => mockLogger.debug(any())).thenReturn(null);
    when(() => mockLogger.warning(any(), any())).thenReturn(null);
    when(() => mockLogger.error(any(), any(), any())).thenReturn(null);
  });

  group('DownloadService', () {
    test('should download file successfully', () async {
      // Arrange
      final service = DownloadService(
        dioClient: mockDio,
        downloadDir: '/tmp/test',
        logger: mockLogger,
        enableRetry: false,
        enableRateLimit: false,
        enableCircuitBreaker: false,
      );

      final url = DownloadUrl('https://example.com/file.zip');
      final expectedSize = ByteSize(1000);

      when(() => mockDio.download(
        any(),
        any(),
        onReceiveProgress: any(named: 'onReceiveProgress'),
        cancelToken: any(named: 'cancelToken'),
        options: any(named: 'options'),
      )).thenAnswer((_) async {
        // Simulate successful download
        return dio.Response(
          requestOptions: dio.RequestOptions(path: url.value),
          statusCode: 200,
        );
      });

      // Act
      final result = await service.download(
        url: url,
        expectedSize: expectedSize,
      );

      // Assert
      expect(result.isRight(), isTrue);
      verify(() => mockLogger.info(any())).called(greaterThan(0));
    });

    test('should handle download cancellation', () async {
      // Arrange
      final service = DownloadService(
        dioClient: mockDio,
        downloadDir: '/tmp/test',
        logger: mockLogger,
        enableRetry: false,
        enableRateLimit: false,
        enableCircuitBreaker: false,
      );

      final url = DownloadUrl('https://example.com/file.zip');
      final expectedSize = ByteSize(1000);

      when(() => mockDio.download(
        any(),
        any(),
        onReceiveProgress: any(named: 'onReceiveProgress'),
        cancelToken: any(named: 'cancelToken'),
        options: any(named: 'options'),
      )).thenThrow(
        dio.DioException(
          requestOptions: dio.RequestOptions(path: url.value),
          type: dio.DioExceptionType.cancel,
        ),
      );

      // Act
      final result = await service.download(
        url: url,
        expectedSize: expectedSize,
      );

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error.message, contains('cancelled')),
        (_) => fail('Should return error'),
      );
      verify(() => mockLogger.warning(any(), any())).called(greaterThan(0));
    });

    test('should handle network errors', () async {
      // Arrange
      final service = DownloadService(
        dioClient: mockDio,
        downloadDir: '/tmp/test',
        logger: mockLogger,
        enableRetry: false,
        enableRateLimit: false,
        enableCircuitBreaker: false,
      );

      final url = DownloadUrl('https://example.com/file.zip');
      final expectedSize = ByteSize(1000);

      when(() => mockDio.download(
        any(),
        any(),
        onReceiveProgress: any(named: 'onReceiveProgress'),
        cancelToken: any(named: 'cancelToken'),
        options: any(named: 'options'),
      )).thenThrow(
        dio.DioException(
          requestOptions: dio.RequestOptions(path: url.value),
          type: dio.DioExceptionType.connectionTimeout,
          message: 'Connection timeout',
        ),
      );

      // Act
      final result = await service.download(
        url: url,
        expectedSize: expectedSize,
      );

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (error) => expect(error.message, contains('Download failed')),
        (_) => fail('Should return error'),
      );
      verify(() => mockLogger.error(any(), any(), any())).called(greaterThan(0));
    });

    test('should verify file size after download', () async {
      // Arrange  
      final service = DownloadService(
        dioClient: mockDio,
        downloadDir: '/tmp/test',
        logger: mockLogger,
        enableRetry: false,
        enableRateLimit: false,
        enableCircuitBreaker: false,
      );

      final url = DownloadUrl('https://example.com/file.zip');
      final expectedSize = ByteSize(1000);

      // Mock returns success but file won't exist for size verification
      when(() => mockDio.download(
        any(),
        any(),
        onReceiveProgress: any(named: 'onReceiveProgress'),
        cancelToken: any(named: 'cancelToken'),
        options: any(named: 'options'),
      )).thenAnswer((_) async {
        return dio.Response(
          requestOptions: dio.RequestOptions(path: url.value),
          statusCode: 200,
        );
      });

      // Act
      final result = await service.download(
        url: url,
        expectedSize: expectedSize,
      );

      // Assert - will fail because file doesn't exist for verification
      expect(result.isLeft(), isTrue);
    });
  });
}
