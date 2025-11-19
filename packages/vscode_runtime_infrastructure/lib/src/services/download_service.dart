import 'dart:io';
import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart' as dio;
import 'package:path/path.dart' as path;
import 'package:vscode_runtime_core/vscode_runtime_core.dart';
import 'logging_service.dart';
import 'retry_interceptor.dart';
import 'rate_limit_interceptor.dart';
import 'circuit_breaker_interceptor.dart';

/// Download Service Implementation
/// Handles file downloads with progress tracking, cancellation, and resilience
class DownloadService implements IDownloadService {
  final dio.Dio _dio;
  final String _downloadDir;
  final LoggingService _logger;
  final Map<CancelToken, StreamController<DownloadProgress>> _progressControllers = {};

  // Memory leak prevention: limit max concurrent downloads
  static const _maxProgressControllers = 10;

  DownloadService({
    dio.Dio? dioClient,
    String? downloadDir,
    LoggingService? logger,
    bool enableRetry = true,
    bool enableRateLimit = true,
    bool enableCircuitBreaker = true,
  })  : _logger = logger ?? LoggingService(),
        _dio = dioClient ??
            dio.Dio(
              dio.BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(minutes: 10),
                followRedirects: true,
                maxRedirects: 5,
              ),
            ),
        _downloadDir = downloadDir ?? '/tmp/vscode_runtime_downloads' {
    // Add interceptors in order (only if using default Dio client)
    if (dioClient == null) {
      // 1. Circuit breaker (fail fast if service is down)
      if (enableCircuitBreaker) {
        _dio.interceptors.add(CircuitBreakerInterceptor(
          failureThreshold: 5,
          openDuration: const Duration(seconds: 60),
          logger: _logger,
        ));
      }

      // 2. Rate limiting (prevent overloading server)
      if (enableRateLimit) {
        _dio.interceptors.add(RateLimitInterceptor(
          maxConcurrentRequests: 3,
          minRequestInterval: const Duration(milliseconds: 100),
          logger: _logger,
        ));
      }

      // 3. Retry logic (retry failed requests)
      if (enableRetry) {
        _dio.interceptors.add(RetryInterceptor(
          maxRetries: 3,
          initialDelay: const Duration(seconds: 2),
          logger: _logger,
        ));
      }
    }
  }

  @override
  Future<Either<DomainException, File>> download({
    required DownloadUrl url,
    required ByteSize expectedSize,
    void Function(ByteSize received, ByteSize total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      _logger.info('Starting download: ${url.value} (expected size: ${expectedSize.bytes} bytes)');

      // Generate target path from URL filename
      final filename = url.filename;
      final targetPath = path.join(_downloadDir, filename);
      final targetFile = File(targetPath);

      _logger.debug('Download target path: $targetPath');

      // Ensure download directory exists
      await Directory(_downloadDir).create(recursive: true);
      _logger.debug('Download directory ensured: $_downloadDir');

      // Map domain CancelToken to Dio CancelToken
      dio.CancelToken? dioCancelToken;
      if (cancelToken != null) {
        dioCancelToken = dio.CancelToken();
        // If domain token is cancelled, cancel dio token
        if (cancelToken.isCancelled) {
          dioCancelToken.cancel();
        }
      }

      // Download with progress tracking
      await _dio.download(
        url.value,
        targetPath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final downloadedSize = ByteSize(received);
            final totalSize = ByteSize(total);

            // Call progress callback
            onProgress?.call(downloadedSize, totalSize);

            // Emit to stream if exists
            if (cancelToken != null && _progressControllers.containsKey(cancelToken)) {
              _progressControllers[cancelToken]?.add(
                DownloadProgress.fromBytes(received, total),
              );
            }
          }
        },
        cancelToken: dioCancelToken,
        options: dio.Options(
          responseType: dio.ResponseType.bytes,
          followRedirects: true,
        ),
      );

      if (!await targetFile.exists()) {
        _logger.error('Download completed but file not found: $targetPath');
        return left(
          const DomainException('Download completed but file not found'),
        );
      }

      // Verify size matches expected
      final actualSize = await targetFile.length();
      if (actualSize != expectedSize.bytes) {
        _logger.error(
          'Downloaded file size mismatch: expected ${expectedSize.bytes}, got $actualSize',
        );
        return left(
          DomainException(
            'Downloaded file size mismatch: expected ${expectedSize.bytes}, got $actualSize',
          ),
        );
      }

      _logger.info('Download completed successfully: ${url.filename} (${actualSize} bytes)');
      return right(targetFile);
    } on dio.DioException catch (e, stackTrace) {
      if (e.type == dio.DioExceptionType.cancel) {
        _logger.warning('Download cancelled: ${url.value}');
        return left(const DomainException('Download cancelled'));
      }
      _logger.error('Download failed: ${url.value}', e, stackTrace);
      return left(
        DomainException('Download failed: ${e.message}'),
      );
    } catch (e, stackTrace) {
      _logger.error('Unexpected download error: ${url.value}', e, stackTrace);
      return left(
        DomainException('Download error: ${e.toString()}'),
      );
    } finally {
      // Cleanup: ensure progress controller is closed and removed
      if (cancelToken != null && _progressControllers.containsKey(cancelToken)) {
        await _progressControllers[cancelToken]?.close();
        _progressControllers.remove(cancelToken);
        _logger.debug('Cleaned up progress controller for download');
      }

      // Memory leak prevention: if too many controllers, clean up old ones
      if (_progressControllers.length > _maxProgressControllers) {
        final oldestKey = _progressControllers.keys.first;
        await _progressControllers[oldestKey]?.close();
        _progressControllers.remove(oldestKey);
        _logger.warning('Removed oldest progress controller due to max limit');
      }
    }
  }

  @override
  Future<Either<DomainException, Unit>> cancelDownload(CancelToken token) async {
    try {
      // Domain CancelToken doesn't have cancel method in current implementation
      // Mark as cancelled
      token.cancel();

      // Close progress stream if exists
      if (_progressControllers.containsKey(token)) {
        await _progressControllers[token]?.close();
        _progressControllers.remove(token);
      }

      return right(unit);
    } catch (e) {
      return left(
        DomainException('Failed to cancel download: ${e.toString()}'),
      );
    }
  }

  @override
  Stream<DownloadProgress> getProgressStream(CancelToken token) {
    if (!_progressControllers.containsKey(token)) {
      _progressControllers[token] = StreamController<DownloadProgress>.broadcast();
    }
    return _progressControllers[token]!.stream;
  }

  /// Cleanup progress controllers
  void dispose() {
    for (final controller in _progressControllers.values) {
      controller.close();
    }
    _progressControllers.clear();
  }
}
