import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/manifest_dto.dart';
import '../services/logging_service.dart';
import '../services/retry_interceptor.dart';
import '../services/rate_limit_interceptor.dart';
import '../services/circuit_breaker_interceptor.dart';

/// Manifest Data Source
/// Fetches runtime manifest from CDN/server with resilience
class ManifestDataSource {
  final Dio _dio;
  final String _manifestUrl;
  final LoggingService _logger;

  ManifestDataSource({
    required String manifestUrl,
    Dio? dio,
    LoggingService? logger,
    bool enableRetry = true,
    bool enableRateLimit = true,
    bool enableCircuitBreaker = true,
  })  : _manifestUrl = manifestUrl,
        _logger = logger ?? LoggingService(),
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 30),
              ),
            ) {
    // Add interceptors in order (only if using default Dio client)
    if (dio == null) {
      // 1. Circuit breaker (fail fast if service is down)
      if (enableCircuitBreaker) {
        _dio.interceptors.add(CircuitBreakerInterceptor(
          failureThreshold: 3,
          openDuration: const Duration(seconds: 30),
          logger: _logger,
        ));
      }

      // 2. Rate limiting (prevent overloading server)
      if (enableRateLimit) {
        _dio.interceptors.add(RateLimitInterceptor(
          maxConcurrentRequests: 2,
          minRequestInterval: const Duration(milliseconds: 200),
          logger: _logger,
        ));
      }

      // 3. Retry logic (retry failed requests)
      if (enableRetry) {
        _dio.interceptors.add(RetryInterceptor(
          maxRetries: 3,
          initialDelay: const Duration(seconds: 1),
          logger: _logger,
        ));
      }
    }
  }

  /// Fetch manifest from remote server
  Future<ManifestDto> fetchManifest() async {
    try {
      _logger.info('Fetching manifest from: $_manifestUrl');
      final response = await _dio.get(_manifestUrl);

      if (response.statusCode == 200) {
        _logger.debug('Manifest fetch successful, parsing response');
        final json = response.data is String
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : response.data as Map<String, dynamic>;

        final manifest = ManifestDto.fromJson(json);
        _logger.info('Manifest parsed successfully (version: ${manifest.version}, modules: ${manifest.modules.length})');
        return manifest;
      }

      _logger.error('Failed to fetch manifest: HTTP ${response.statusCode}');
      throw Exception('Failed to fetch manifest: ${response.statusCode}');
    } on DioException catch (e) {
      _logger.error('Network error fetching manifest', e);
      throw Exception('Network error fetching manifest: ${e.message}');
    } catch (e) {
      _logger.error('Failed to fetch manifest', e);
      throw Exception('Failed to fetch manifest: $e');
    }
  }

  /// Check if a new manifest version is available
  Future<bool> hasUpdate(String currentVersion) async {
    try {
      final manifest = await fetchManifest();
      return manifest.version != currentVersion;
    } catch (e) {
      return false;
    }
  }
}
