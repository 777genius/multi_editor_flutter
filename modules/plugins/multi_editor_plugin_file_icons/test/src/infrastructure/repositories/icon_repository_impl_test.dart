import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_editor_plugin_file_icons/src/domain/entities/file_icon.dart';
import 'package:multi_editor_plugin_file_icons/src/domain/repositories/icon_repository.dart';
import 'package:multi_editor_plugin_file_icons/src/domain/value_objects/file_extension.dart';
import 'package:multi_editor_plugin_file_icons/src/domain/value_objects/icon_url.dart';
import 'package:multi_editor_plugin_file_icons/src/infrastructure/repositories/icon_repository_impl.dart';
import 'package:multi_editor_plugin_file_icons/src/infrastructure/services/icon_cache_service.dart';

class MockIconCacheService extends Mock implements IconCacheService {}

void main() {
  group('IconRepositoryImpl', () {
    late MockIconCacheService mockCache;
    late IconRepositoryImpl repository;

    setUp(() {
      mockCache = MockIconCacheService();
      repository = IconRepositoryImpl(mockCache);
    });

    group('getIcon', () {
      test('should return icon from cache when available', () async {
        // Arrange
        const extension = FileExtension(value: 'dart');
        const expectedIcon = FileIcon(
          url: IconUrl(value: 'https://example.com/dart.svg'),
          extension: 'dart',
          themeId: 'test-theme',
          format: 'svg',
          size: 18,
        );
        when(() => mockCache.get(extension)).thenReturn(expectedIcon);

        // Act
        final result = await repository.getIcon(extension);

        // Assert
        expect(result, expectedIcon);
        verify(() => mockCache.get(extension)).called(1);
      });

      test('should return null when icon not in cache', () async {
        // Arrange
        const extension = FileExtension(value: 'unknown');
        when(() => mockCache.get(extension)).thenReturn(null);

        // Act
        final result = await repository.getIcon(extension);

        // Assert
        expect(result, isNull);
        verify(() => mockCache.get(extension)).called(1);
      });

      test('should handle multiple get calls for same extension', () async {
        // Arrange
        const extension = FileExtension(value: 'js');
        const icon = FileIcon(
          url: IconUrl(value: 'https://example.com/js.svg'),
          extension: 'js',
          themeId: 'test-theme',
        );
        when(() => mockCache.get(extension)).thenReturn(icon);

        // Act
        final result1 = await repository.getIcon(extension);
        final result2 = await repository.getIcon(extension);

        // Assert
        expect(result1, icon);
        expect(result2, icon);
        verify(() => mockCache.get(extension)).called(2);
      });

      test('should handle different extensions', () async {
        // Arrange
        const dartExt = FileExtension(value: 'dart');
        const jsExt = FileExtension(value: 'js');
        const dartIcon = FileIcon(
          url: IconUrl(value: 'https://example.com/dart.svg'),
          extension: 'dart',
          themeId: 'test-theme',
        );
        const jsIcon = FileIcon(
          url: IconUrl(value: 'https://example.com/js.svg'),
          extension: 'js',
          themeId: 'test-theme',
        );
        when(() => mockCache.get(dartExt)).thenReturn(dartIcon);
        when(() => mockCache.get(jsExt)).thenReturn(jsIcon);

        // Act
        final dartResult = await repository.getIcon(dartExt);
        final jsResult = await repository.getIcon(jsExt);

        // Assert
        expect(dartResult, dartIcon);
        expect(jsResult, jsIcon);
        verify(() => mockCache.get(dartExt)).called(1);
        verify(() => mockCache.get(jsExt)).called(1);
      });
    });

    group('getIcons', () {
      test('should return icons for all extensions in cache', () async {
        // Arrange
        const extensions = [
          FileExtension(value: 'dart'),
          FileExtension(value: 'js'),
          FileExtension(value: 'ts'),
        ];
        const dartIcon = FileIcon(
          url: IconUrl(value: 'https://example.com/dart.svg'),
          extension: 'dart',
          themeId: 'test-theme',
        );
        const jsIcon = FileIcon(
          url: IconUrl(value: 'https://example.com/js.svg'),
          extension: 'js',
          themeId: 'test-theme',
        );
        const tsIcon = FileIcon(
          url: IconUrl(value: 'https://example.com/ts.svg'),
          extension: 'ts',
          themeId: 'test-theme',
        );
        when(() => mockCache.get(extensions[0])).thenReturn(dartIcon);
        when(() => mockCache.get(extensions[1])).thenReturn(jsIcon);
        when(() => mockCache.get(extensions[2])).thenReturn(tsIcon);

        // Act
        final result = await repository.getIcons(extensions);

        // Assert
        expect(result.length, 3);
        expect(result[extensions[0]], dartIcon);
        expect(result[extensions[1]], jsIcon);
        expect(result[extensions[2]], tsIcon);
        verify(() => mockCache.get(extensions[0])).called(1);
        verify(() => mockCache.get(extensions[1])).called(1);
        verify(() => mockCache.get(extensions[2])).called(1);
      });

      test('should skip extensions not in cache', () async {
        // Arrange
        const extensions = [
          FileExtension(value: 'dart'),
          FileExtension(value: 'unknown'),
          FileExtension(value: 'js'),
        ];
        const dartIcon = FileIcon(
          url: IconUrl(value: 'https://example.com/dart.svg'),
          extension: 'dart',
          themeId: 'test-theme',
        );
        const jsIcon = FileIcon(
          url: IconUrl(value: 'https://example.com/js.svg'),
          extension: 'js',
          themeId: 'test-theme',
        );
        when(() => mockCache.get(extensions[0])).thenReturn(dartIcon);
        when(() => mockCache.get(extensions[1])).thenReturn(null);
        when(() => mockCache.get(extensions[2])).thenReturn(jsIcon);

        // Act
        final result = await repository.getIcons(extensions);

        // Assert
        expect(result.length, 2);
        expect(result[extensions[0]], dartIcon);
        expect(result[extensions[2]], jsIcon);
        expect(result.containsKey(extensions[1]), false);
        verify(() => mockCache.get(extensions[0])).called(1);
        verify(() => mockCache.get(extensions[1])).called(1);
        verify(() => mockCache.get(extensions[2])).called(1);
      });

      test('should return empty map when no extensions provided', () async {
        // Arrange
        const extensions = <FileExtension>[];

        // Act
        final result = await repository.getIcons(extensions);

        // Assert
        expect(result, isEmpty);
        verifyNever(() => mockCache.get(any()));
      });

      test('should return empty map when no icons in cache', () async {
        // Arrange
        const extensions = [
          FileExtension(value: 'unknown1'),
          FileExtension(value: 'unknown2'),
        ];
        when(() => mockCache.get(any())).thenReturn(null);

        // Act
        final result = await repository.getIcons(extensions);

        // Assert
        expect(result, isEmpty);
        verify(() => mockCache.get(extensions[0])).called(1);
        verify(() => mockCache.get(extensions[1])).called(1);
      });

      test('should handle single extension', () async {
        // Arrange
        const extensions = [FileExtension(value: 'dart')];
        const dartIcon = FileIcon(
          url: IconUrl(value: 'https://example.com/dart.svg'),
          extension: 'dart',
          themeId: 'test-theme',
        );
        when(() => mockCache.get(extensions[0])).thenReturn(dartIcon);

        // Act
        final result = await repository.getIcons(extensions);

        // Assert
        expect(result.length, 1);
        expect(result[extensions[0]], dartIcon);
      });

      test('should handle large batch of extensions', () async {
        // Arrange
        final extensions = List.generate(
          100,
          (i) => FileExtension(value: 'ext$i'),
        );
        for (final ext in extensions) {
          when(() => mockCache.get(ext)).thenReturn(
            FileIcon(
              url: IconUrl(value: 'https://example.com/${ext.value}.svg'),
              extension: ext.value,
              themeId: 'test-theme',
            ),
          );
        }

        // Act
        final result = await repository.getIcons(extensions);

        // Assert
        expect(result.length, 100);
        for (final ext in extensions) {
          expect(result.containsKey(ext), true);
          verify(() => mockCache.get(ext)).called(1);
        }
      });
    });

    group('hasIcon', () {
      test('should return true when icon is in cache', () async {
        // Arrange
        const extension = FileExtension(value: 'dart');
        when(() => mockCache.has(extension)).thenReturn(true);

        // Act
        final result = await repository.hasIcon(extension);

        // Assert
        expect(result, true);
        verify(() => mockCache.has(extension)).called(1);
      });

      test('should return false when icon is not in cache', () async {
        // Arrange
        const extension = FileExtension(value: 'unknown');
        when(() => mockCache.has(extension)).thenReturn(false);

        // Act
        final result = await repository.hasIcon(extension);

        // Assert
        expect(result, false);
        verify(() => mockCache.has(extension)).called(1);
      });

      test('should handle multiple hasIcon calls', () async {
        // Arrange
        const extension = FileExtension(value: 'js');
        when(() => mockCache.has(extension)).thenReturn(true);

        // Act
        final result1 = await repository.hasIcon(extension);
        final result2 = await repository.hasIcon(extension);

        // Assert
        expect(result1, true);
        expect(result2, true);
        verify(() => mockCache.has(extension)).called(2);
      });

      test('should handle different extensions', () async {
        // Arrange
        const dartExt = FileExtension(value: 'dart');
        const unknownExt = FileExtension(value: 'unknown');
        when(() => mockCache.has(dartExt)).thenReturn(true);
        when(() => mockCache.has(unknownExt)).thenReturn(false);

        // Act
        final dartResult = await repository.hasIcon(dartExt);
        final unknownResult = await repository.hasIcon(unknownExt);

        // Assert
        expect(dartResult, true);
        expect(unknownResult, false);
        verify(() => mockCache.has(dartExt)).called(1);
        verify(() => mockCache.has(unknownExt)).called(1);
      });
    });

    group('clearCache', () {
      test('should clear cache when called', () async {
        // Arrange
        when(() => mockCache.clear()).thenReturn(null);

        // Act
        await repository.clearCache();

        // Assert
        verify(() => mockCache.clear()).called(1);
      });

      test('should handle multiple clear calls', () async {
        // Arrange
        when(() => mockCache.clear()).thenReturn(null);

        // Act
        await repository.clearCache();
        await repository.clearCache();

        // Assert
        verify(() => mockCache.clear()).called(2);
      });

      test('should not throw when cache is already empty', () async {
        // Arrange
        when(() => mockCache.clear()).thenReturn(null);

        // Act & Assert
        expect(() => repository.clearCache(), returnsNormally);
      });
    });

    group('getStats', () {
      test('should return stats with cache size', () async {
        // Arrange
        when(() => mockCache.size).thenReturn(42);

        // Act
        final stats = await repository.getStats();

        // Assert
        expect(stats.cachedIconsCount, 42);
        expect(stats.totalRequests, 0);
        expect(stats.cacheHits, 0);
        expect(stats.cacheMisses, 0);
        expect(stats.failedRequests, 0);
        verify(() => mockCache.size).called(1);
      });

      test('should return stats when cache is empty', () async {
        // Arrange
        when(() => mockCache.size).thenReturn(0);

        // Act
        final stats = await repository.getStats();

        // Assert
        expect(stats.cachedIconsCount, 0);
        expect(stats.totalRequests, 0);
        expect(stats.cacheHits, 0);
        expect(stats.cacheMisses, 0);
        expect(stats.failedRequests, 0);
      });

      test('should return stats with large cache size', () async {
        // Arrange
        when(() => mockCache.size).thenReturn(1000);

        // Act
        final stats = await repository.getStats();

        // Assert
        expect(stats.cachedIconsCount, 1000);
      });

      test('should handle multiple getStats calls', () async {
        // Arrange
        when(() => mockCache.size).thenReturn(50);

        // Act
        final stats1 = await repository.getStats();
        final stats2 = await repository.getStats();

        // Assert
        expect(stats1.cachedIconsCount, 50);
        expect(stats2.cachedIconsCount, 50);
        verify(() => mockCache.size).called(2);
      });

      test('should return current cache size at time of call', () async {
        // Arrange
        when(() => mockCache.size).thenReturn(10);

        // Act
        final stats1 = await repository.getStats();

        // Change cache size
        when(() => mockCache.size).thenReturn(20);

        // Act
        final stats2 = await repository.getStats();

        // Assert
        expect(stats1.cachedIconsCount, 10);
        expect(stats2.cachedIconsCount, 20);
      });
    });

    group('integration tests', () {
      test('should handle complete workflow: get, check, clear', () async {
        // Arrange
        const extension = FileExtension(value: 'dart');
        const icon = FileIcon(
          url: IconUrl(value: 'https://example.com/dart.svg'),
          extension: 'dart',
          themeId: 'test-theme',
        );
        when(() => mockCache.get(extension)).thenReturn(icon);
        when(() => mockCache.has(extension)).thenReturn(true);
        when(() => mockCache.clear()).thenReturn(null);
        when(() => mockCache.size).thenReturn(1);

        // Act
        final hasIcon = await repository.hasIcon(extension);
        final retrievedIcon = await repository.getIcon(extension);
        final stats = await repository.getStats();
        await repository.clearCache();

        // Assert
        expect(hasIcon, true);
        expect(retrievedIcon, icon);
        expect(stats.cachedIconsCount, 1);
        verify(() => mockCache.has(extension)).called(1);
        verify(() => mockCache.get(extension)).called(1);
        verify(() => mockCache.size).called(1);
        verify(() => mockCache.clear()).called(1);
      });

      test('should handle workflow with multiple extensions', () async {
        // Arrange
        const extensions = [
          FileExtension(value: 'dart'),
          FileExtension(value: 'js'),
          FileExtension(value: 'ts'),
        ];
        for (final ext in extensions) {
          when(() => mockCache.get(ext)).thenReturn(
            FileIcon(
              url: IconUrl(value: 'https://example.com/${ext.value}.svg'),
              extension: ext.value,
              themeId: 'test-theme',
            ),
          );
          when(() => mockCache.has(ext)).thenReturn(true);
        }
        when(() => mockCache.size).thenReturn(3);

        // Act
        final icons = await repository.getIcons(extensions);
        final allPresent = await Future.wait(
          extensions.map((ext) => repository.hasIcon(ext)),
        );
        final stats = await repository.getStats();

        // Assert
        expect(icons.length, 3);
        expect(allPresent.every((present) => present), true);
        expect(stats.cachedIconsCount, 3);
      });

      test('should handle workflow with cache miss', () async {
        // Arrange
        const extension = FileExtension(value: 'unknown');
        when(() => mockCache.get(extension)).thenReturn(null);
        when(() => mockCache.has(extension)).thenReturn(false);

        // Act
        final hasIcon = await repository.hasIcon(extension);
        final icon = await repository.getIcon(extension);

        // Assert
        expect(hasIcon, false);
        expect(icon, isNull);
      });
    });

    group('error handling', () {
      test('should propagate cache exceptions', () {
        // Arrange
        const extension = FileExtension(value: 'dart');
        when(() => mockCache.get(extension)).thenThrow(
          Exception('Cache error'),
        );

        // Act & Assert
        expect(
          () => repository.getIcon(extension),
          throwsException,
        );
      });

      test('should handle cache has exception', () {
        // Arrange
        const extension = FileExtension(value: 'dart');
        when(() => mockCache.has(extension)).thenThrow(
          Exception('Cache error'),
        );

        // Act & Assert
        expect(
          () => repository.hasIcon(extension),
          throwsException,
        );
      });

      test('should handle cache clear exception', () {
        // Arrange
        when(() => mockCache.clear()).thenThrow(
          Exception('Clear failed'),
        );

        // Act & Assert
        expect(
          () => repository.clearCache(),
          throwsException,
        );
      });

      test('should handle cache size exception', () {
        // Arrange
        when(() => mockCache.size).thenThrow(
          Exception('Size error'),
        );

        // Act & Assert
        expect(
          () => repository.getStats(),
          throwsException,
        );
      });
    });
  });
}
