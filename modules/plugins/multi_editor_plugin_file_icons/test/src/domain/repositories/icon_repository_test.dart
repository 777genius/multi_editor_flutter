import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugin_file_icons/src/domain/repositories/icon_repository.dart';

void main() {
  group('IconRepositoryStats', () {
    group('constructor', () {
      test('should create stats with all properties', () {
        // Arrange & Act
        const stats = IconRepositoryStats(
          cachedIconsCount: 50,
          totalRequests: 100,
          cacheHits: 80,
          cacheMisses: 20,
          failedRequests: 5,
        );

        // Assert
        expect(stats.cachedIconsCount, 50);
        expect(stats.totalRequests, 100);
        expect(stats.cacheHits, 80);
        expect(stats.cacheMisses, 20);
        expect(stats.failedRequests, 5);
      });

      test('should create stats with zero values', () {
        // Arrange & Act
        const stats = IconRepositoryStats(
          cachedIconsCount: 0,
          totalRequests: 0,
          cacheHits: 0,
          cacheMisses: 0,
          failedRequests: 0,
        );

        // Assert
        expect(stats.cachedIconsCount, 0);
        expect(stats.totalRequests, 0);
        expect(stats.cacheHits, 0);
        expect(stats.cacheMisses, 0);
        expect(stats.failedRequests, 0);
      });
    });

    group('cacheHitRate', () {
      test('should calculate correct cache hit rate', () {
        // Arrange
        const stats = IconRepositoryStats(
          cachedIconsCount: 50,
          totalRequests: 100,
          cacheHits: 80,
          cacheMisses: 20,
          failedRequests: 0,
        );

        // Act
        final hitRate = stats.cacheHitRate;

        // Assert
        expect(hitRate, 0.8);
      });

      test('should return 0.0 when totalRequests is 0', () {
        // Arrange
        const stats = IconRepositoryStats(
          cachedIconsCount: 0,
          totalRequests: 0,
          cacheHits: 0,
          cacheMisses: 0,
          failedRequests: 0,
        );

        // Act
        final hitRate = stats.cacheHitRate;

        // Assert
        expect(hitRate, 0.0);
      });

      test('should return 1.0 when all requests are cache hits', () {
        // Arrange
        const stats = IconRepositoryStats(
          cachedIconsCount: 100,
          totalRequests: 100,
          cacheHits: 100,
          cacheMisses: 0,
          failedRequests: 0,
        );

        // Act
        final hitRate = stats.cacheHitRate;

        // Assert
        expect(hitRate, 1.0);
      });

      test('should return 0.0 when no cache hits', () {
        // Arrange
        const stats = IconRepositoryStats(
          cachedIconsCount: 0,
          totalRequests: 100,
          cacheHits: 0,
          cacheMisses: 100,
          failedRequests: 0,
        );

        // Act
        final hitRate = stats.cacheHitRate;

        // Assert
        expect(hitRate, 0.0);
      });

      test('should handle partial cache hits correctly', () {
        // Arrange
        const stats = IconRepositoryStats(
          cachedIconsCount: 25,
          totalRequests: 50,
          cacheHits: 25,
          cacheMisses: 25,
          failedRequests: 0,
        );

        // Act
        final hitRate = stats.cacheHitRate;

        // Assert
        expect(hitRate, 0.5);
      });
    });

    group('failureRate', () {
      test('should calculate correct failure rate', () {
        // Arrange
        const stats = IconRepositoryStats(
          cachedIconsCount: 50,
          totalRequests: 100,
          cacheHits: 80,
          cacheMisses: 15,
          failedRequests: 5,
        );

        // Act
        final failRate = stats.failureRate;

        // Assert
        expect(failRate, 0.05);
      });

      test('should return 0.0 when totalRequests is 0', () {
        // Arrange
        const stats = IconRepositoryStats(
          cachedIconsCount: 0,
          totalRequests: 0,
          cacheHits: 0,
          cacheMisses: 0,
          failedRequests: 0,
        );

        // Act
        final failRate = stats.failureRate;

        // Assert
        expect(failRate, 0.0);
      });

      test('should return 0.0 when no failures', () {
        // Arrange
        const stats = IconRepositoryStats(
          cachedIconsCount: 100,
          totalRequests: 100,
          cacheHits: 100,
          cacheMisses: 0,
          failedRequests: 0,
        );

        // Act
        final failRate = stats.failureRate;

        // Assert
        expect(failRate, 0.0);
      });

      test('should return 1.0 when all requests failed', () {
        // Arrange
        const stats = IconRepositoryStats(
          cachedIconsCount: 0,
          totalRequests: 100,
          cacheHits: 0,
          cacheMisses: 0,
          failedRequests: 100,
        );

        // Act
        final failRate = stats.failureRate;

        // Assert
        expect(failRate, 1.0);
      });

      test('should handle partial failures correctly', () {
        // Arrange
        const stats = IconRepositoryStats(
          cachedIconsCount: 25,
          totalRequests: 100,
          cacheHits: 75,
          cacheMisses: 15,
          failedRequests: 10,
        );

        // Act
        final failRate = stats.failureRate;

        // Assert
        expect(failRate, 0.1);
      });
    });

    group('edge cases', () {
      test('should handle very large numbers', () {
        // Arrange
        const stats = IconRepositoryStats(
          cachedIconsCount: 1000000,
          totalRequests: 10000000,
          cacheHits: 9000000,
          cacheMisses: 900000,
          failedRequests: 100000,
        );

        // Act & Assert
        expect(stats.cacheHitRate, 0.9);
        expect(stats.failureRate, 0.01);
      });

      test('should handle all metrics together', () {
        // Arrange
        const stats = IconRepositoryStats(
          cachedIconsCount: 42,
          totalRequests: 200,
          cacheHits: 150,
          cacheMisses: 40,
          failedRequests: 10,
        );

        // Act & Assert
        expect(stats.cachedIconsCount, 42);
        expect(stats.totalRequests, 200);
        expect(stats.cacheHits, 150);
        expect(stats.cacheMisses, 40);
        expect(stats.failedRequests, 10);
        expect(stats.cacheHitRate, 0.75);
        expect(stats.failureRate, 0.05);
      });
    });
  });
}
