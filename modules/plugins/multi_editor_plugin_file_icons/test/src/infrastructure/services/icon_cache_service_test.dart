import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugin_file_icons/src/domain/entities/file_icon.dart';
import 'package:multi_editor_plugin_file_icons/src/domain/value_objects/file_extension.dart';
import 'package:multi_editor_plugin_file_icons/src/domain/value_objects/icon_url.dart';
import 'package:multi_editor_plugin_file_icons/src/infrastructure/services/icon_cache_service.dart';

void main() {
  group('IconCacheService', () {
    late IconCacheService cache;

    setUp(() {
      cache = IconCacheService(maxSize: 3);
    });

    group('constructor', () {
      test('should create cache with default max size', () {
        // Act
        final defaultCache = IconCacheService();

        // Assert
        expect(defaultCache.size, 0);
      });

      test('should create cache with custom max size', () {
        // Act
        final customCache = IconCacheService(maxSize: 50);

        // Assert
        expect(customCache.size, 0);
      });
    });

    group('get', () {
      test('should return null for non-existent key', () {
        // Arrange
        const extension = FileExtension(value: 'dart');

        // Act
        final result = cache.get(extension);

        // Assert
        expect(result, isNull);
      });

      test('should return icon when key exists', () {
        // Arrange
        const extension = FileExtension(value: 'dart');
        const icon = FileIcon(
          url: IconUrl(value: 'https://example.com/dart.svg'),
          extension: 'dart',
          themeId: 'test-theme',
        );
        cache.put(extension, icon);

        // Act
        final result = cache.get(extension);

        // Assert
        expect(result, icon);
      });

      test('should return correct icon for different extensions', () {
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
        cache.put(dartExt, dartIcon);
        cache.put(jsExt, jsIcon);

        // Act
        final dartResult = cache.get(dartExt);
        final jsResult = cache.get(jsExt);

        // Assert
        expect(dartResult, dartIcon);
        expect(jsResult, jsIcon);
      });

      test('should update access order on get', () {
        // Arrange - Fill cache to max
        const ext1 = FileExtension(value: 'ext1');
        const ext2 = FileExtension(value: 'ext2');
        const ext3 = FileExtension(value: 'ext3');
        const ext4 = FileExtension(value: 'ext4');

        cache.put(ext1, _createIcon('ext1'));
        cache.put(ext2, _createIcon('ext2'));
        cache.put(ext3, _createIcon('ext3'));

        // Act - Access ext1 to move it to end of LRU
        cache.get(ext1);

        // Add ext4 which should evict ext2 (oldest unused)
        cache.put(ext4, _createIcon('ext4'));

        // Assert
        expect(cache.has(ext1), true); // Still in cache (recently accessed)
        expect(cache.has(ext2), false); // Evicted (oldest)
        expect(cache.has(ext3), true); // Still in cache
        expect(cache.has(ext4), true); // Just added
      });

      test('should handle multiple gets of same extension', () {
        // Arrange
        const extension = FileExtension(value: 'dart');
        const icon = FileIcon(
          url: IconUrl(value: 'https://example.com/dart.svg'),
          extension: 'dart',
          themeId: 'test-theme',
        );
        cache.put(extension, icon);

        // Act
        final result1 = cache.get(extension);
        final result2 = cache.get(extension);
        final result3 = cache.get(extension);

        // Assert
        expect(result1, icon);
        expect(result2, icon);
        expect(result3, icon);
      });
    });

    group('put', () {
      test('should add icon to cache', () {
        // Arrange
        const extension = FileExtension(value: 'dart');
        const icon = FileIcon(
          url: IconUrl(value: 'https://example.com/dart.svg'),
          extension: 'dart',
          themeId: 'test-theme',
        );

        // Act
        cache.put(extension, icon);

        // Assert
        expect(cache.get(extension), icon);
        expect(cache.size, 1);
      });

      test('should update existing icon', () {
        // Arrange
        const extension = FileExtension(value: 'dart');
        const icon1 = FileIcon(
          url: IconUrl(value: 'https://example.com/dart1.svg'),
          extension: 'dart',
          themeId: 'theme1',
        );
        const icon2 = FileIcon(
          url: IconUrl(value: 'https://example.com/dart2.svg'),
          extension: 'dart',
          themeId: 'theme2',
        );

        // Act
        cache.put(extension, icon1);
        final sizeAfterFirst = cache.size;
        cache.put(extension, icon2);
        final sizeAfterSecond = cache.size;

        // Assert
        expect(cache.get(extension), icon2);
        expect(sizeAfterFirst, 1);
        expect(sizeAfterSecond, 1); // Size shouldn't increase
      });

      test('should add multiple different icons', () {
        // Arrange
        const extensions = [
          FileExtension(value: 'dart'),
          FileExtension(value: 'js'),
          FileExtension(value: 'ts'),
        ];

        // Act
        for (final ext in extensions) {
          cache.put(ext, _createIcon(ext.value));
        }

        // Assert
        expect(cache.size, 3);
        for (final ext in extensions) {
          expect(cache.has(ext), true);
        }
      });

      test('should evict oldest when at capacity', () {
        // Arrange - Fill to capacity
        const ext1 = FileExtension(value: 'ext1');
        const ext2 = FileExtension(value: 'ext2');
        const ext3 = FileExtension(value: 'ext3');
        const ext4 = FileExtension(value: 'ext4');

        cache.put(ext1, _createIcon('ext1'));
        cache.put(ext2, _createIcon('ext2'));
        cache.put(ext3, _createIcon('ext3'));

        // Act - Add one more to trigger eviction
        cache.put(ext4, _createIcon('ext4'));

        // Assert
        expect(cache.size, 3);
        expect(cache.has(ext1), false); // Oldest, should be evicted
        expect(cache.has(ext2), true);
        expect(cache.has(ext3), true);
        expect(cache.has(ext4), true);
      });

      test('should not evict when updating existing entry', () {
        // Arrange
        const ext1 = FileExtension(value: 'ext1');
        const ext2 = FileExtension(value: 'ext2');
        const ext3 = FileExtension(value: 'ext3');

        cache.put(ext1, _createIcon('ext1-v1'));
        cache.put(ext2, _createIcon('ext2'));
        cache.put(ext3, _createIcon('ext3'));

        // Act - Update ext1 (should not evict anything)
        cache.put(ext1, _createIcon('ext1-v2'));

        // Assert
        expect(cache.size, 3);
        expect(cache.has(ext1), true);
        expect(cache.has(ext2), true);
        expect(cache.has(ext3), true);
      });

      test('should update access order on put', () {
        // Arrange
        const ext1 = FileExtension(value: 'ext1');
        const ext2 = FileExtension(value: 'ext2');
        const ext3 = FileExtension(value: 'ext3');

        cache.put(ext1, _createIcon('ext1'));
        cache.put(ext2, _createIcon('ext2'));
        cache.put(ext3, _createIcon('ext3'));

        // Act - Update ext1, moving it to most recently used
        cache.put(ext1, _createIcon('ext1-updated'));

        // Add another to trigger eviction
        const ext4 = FileExtension(value: 'ext4');
        cache.put(ext4, _createIcon('ext4'));

        // Assert - ext2 should be evicted (oldest), not ext1
        expect(cache.has(ext1), true);
        expect(cache.has(ext2), false); // Evicted
        expect(cache.has(ext3), true);
        expect(cache.has(ext4), true);
      });
    });

    group('has', () {
      test('should return true when icon is in cache', () {
        // Arrange
        const extension = FileExtension(value: 'dart');
        cache.put(extension, _createIcon('dart'));

        // Act
        final result = cache.has(extension);

        // Assert
        expect(result, true);
      });

      test('should return false when icon is not in cache', () {
        // Arrange
        const extension = FileExtension(value: 'unknown');

        // Act
        final result = cache.has(extension);

        // Assert
        expect(result, false);
      });

      test('should return false after eviction', () {
        // Arrange - Fill cache and trigger eviction
        const ext1 = FileExtension(value: 'ext1');
        cache.put(ext1, _createIcon('ext1'));
        cache.put(const FileExtension(value: 'ext2'), _createIcon('ext2'));
        cache.put(const FileExtension(value: 'ext3'), _createIcon('ext3'));
        cache.put(const FileExtension(value: 'ext4'), _createIcon('ext4'));

        // Act
        final result = cache.has(ext1);

        // Assert
        expect(result, false);
      });

      test('should handle multiple has calls', () {
        // Arrange
        const extension = FileExtension(value: 'dart');
        cache.put(extension, _createIcon('dart'));

        // Act & Assert
        expect(cache.has(extension), true);
        expect(cache.has(extension), true);
        expect(cache.has(extension), true);
      });

      test('should check different extensions correctly', () {
        // Arrange
        const ext1 = FileExtension(value: 'dart');
        const ext2 = FileExtension(value: 'js');
        const ext3 = FileExtension(value: 'ts');
        cache.put(ext1, _createIcon('dart'));
        cache.put(ext3, _createIcon('ts'));

        // Act & Assert
        expect(cache.has(ext1), true);
        expect(cache.has(ext2), false);
        expect(cache.has(ext3), true);
      });
    });

    group('clear', () {
      test('should remove all items from cache', () {
        // Arrange
        cache.put(const FileExtension(value: 'ext1'), _createIcon('ext1'));
        cache.put(const FileExtension(value: 'ext2'), _createIcon('ext2'));
        cache.put(const FileExtension(value: 'ext3'), _createIcon('ext3'));

        // Act
        cache.clear();

        // Assert
        expect(cache.size, 0);
        expect(cache.has(const FileExtension(value: 'ext1')), false);
        expect(cache.has(const FileExtension(value: 'ext2')), false);
        expect(cache.has(const FileExtension(value: 'ext3')), false);
      });

      test('should work on empty cache', () {
        // Act & Assert
        expect(() => cache.clear(), returnsNormally);
        expect(cache.size, 0);
      });

      test('should allow adding items after clear', () {
        // Arrange
        cache.put(const FileExtension(value: 'ext1'), _createIcon('ext1'));
        cache.clear();

        // Act
        const newExt = FileExtension(value: 'new');
        cache.put(newExt, _createIcon('new'));

        // Assert
        expect(cache.size, 1);
        expect(cache.has(newExt), true);
      });

      test('should handle multiple clear calls', () {
        // Arrange
        cache.put(const FileExtension(value: 'ext1'), _createIcon('ext1'));

        // Act & Assert
        cache.clear();
        expect(cache.size, 0);
        cache.clear();
        expect(cache.size, 0);
        cache.clear();
        expect(cache.size, 0);
      });
    });

    group('size', () {
      test('should return 0 for empty cache', () {
        // Assert
        expect(cache.size, 0);
      });

      test('should return correct size after adding items', () {
        // Arrange & Act & Assert
        expect(cache.size, 0);

        cache.put(const FileExtension(value: 'ext1'), _createIcon('ext1'));
        expect(cache.size, 1);

        cache.put(const FileExtension(value: 'ext2'), _createIcon('ext2'));
        expect(cache.size, 2);

        cache.put(const FileExtension(value: 'ext3'), _createIcon('ext3'));
        expect(cache.size, 3);
      });

      test('should not exceed max size', () {
        // Arrange
        for (var i = 0; i < 10; i++) {
          cache.put(FileExtension(value: 'ext$i'), _createIcon('ext$i'));
        }

        // Act & Assert
        expect(cache.size, 3); // Max size
      });

      test('should decrease after clear', () {
        // Arrange
        cache.put(const FileExtension(value: 'ext1'), _createIcon('ext1'));
        cache.put(const FileExtension(value: 'ext2'), _createIcon('ext2'));
        expect(cache.size, 2);

        // Act
        cache.clear();

        // Assert
        expect(cache.size, 0);
      });

      test('should not change when updating existing entry', () {
        // Arrange
        const extension = FileExtension(value: 'dart');
        cache.put(extension, _createIcon('dart-v1'));
        final sizeAfterFirst = cache.size;

        // Act
        cache.put(extension, _createIcon('dart-v2'));
        final sizeAfterUpdate = cache.size;

        // Assert
        expect(sizeAfterFirst, 1);
        expect(sizeAfterUpdate, 1);
      });
    });

    group('LRU eviction policy', () {
      test('should evict least recently used item', () {
        // Arrange
        const ext1 = FileExtension(value: 'ext1');
        const ext2 = FileExtension(value: 'ext2');
        const ext3 = FileExtension(value: 'ext3');
        const ext4 = FileExtension(value: 'ext4');

        // Fill cache
        cache.put(ext1, _createIcon('ext1'));
        cache.put(ext2, _createIcon('ext2'));
        cache.put(ext3, _createIcon('ext3'));

        // Act - Add new item to trigger eviction
        cache.put(ext4, _createIcon('ext4'));

        // Assert - ext1 should be evicted (oldest)
        expect(cache.has(ext1), false);
        expect(cache.has(ext2), true);
        expect(cache.has(ext3), true);
        expect(cache.has(ext4), true);
      });

      test('should not evict recently accessed items', () {
        // Arrange
        const ext1 = FileExtension(value: 'ext1');
        const ext2 = FileExtension(value: 'ext2');
        const ext3 = FileExtension(value: 'ext3');
        const ext4 = FileExtension(value: 'ext4');

        cache.put(ext1, _createIcon('ext1'));
        cache.put(ext2, _createIcon('ext2'));
        cache.put(ext3, _createIcon('ext3'));

        // Act - Access ext1 to make it recently used
        cache.get(ext1);

        // Add new item
        cache.put(ext4, _createIcon('ext4'));

        // Assert - ext2 should be evicted (now oldest), not ext1
        expect(cache.has(ext1), true); // Kept (recently accessed)
        expect(cache.has(ext2), false); // Evicted
        expect(cache.has(ext3), true);
        expect(cache.has(ext4), true);
      });

      test('should handle complex access pattern', () {
        // Arrange
        const ext1 = FileExtension(value: 'ext1');
        const ext2 = FileExtension(value: 'ext2');
        const ext3 = FileExtension(value: 'ext3');
        const ext4 = FileExtension(value: 'ext4');
        const ext5 = FileExtension(value: 'ext5');

        cache.put(ext1, _createIcon('ext1'));
        cache.put(ext2, _createIcon('ext2'));
        cache.put(ext3, _createIcon('ext3'));

        // Act - Complex access pattern
        cache.get(ext1); // ext1 is now most recent
        cache.get(ext2); // ext2 is now most recent
        // ext3 is now least recent

        cache.put(ext4, _createIcon('ext4')); // Should evict ext3
        expect(cache.has(ext3), false);

        cache.get(ext1); // ext1 touched again
        // Access order: ext2 (oldest), ext4, ext1 (newest)

        cache.put(ext5, _createIcon('ext5')); // Should evict ext2

        // Assert
        expect(cache.has(ext1), true);
        expect(cache.has(ext2), false);
        expect(cache.has(ext3), false);
        expect(cache.has(ext4), true);
        expect(cache.has(ext5), true);
      });

      test('should handle sequential evictions correctly', () {
        // Arrange
        final extensions = List.generate(
          10,
          (i) => FileExtension(value: 'ext$i'),
        );

        // Act - Add 10 items to cache with max size 3
        for (final ext in extensions) {
          cache.put(ext, _createIcon(ext.value));
        }

        // Assert - Only last 3 should remain
        expect(cache.size, 3);
        expect(cache.has(extensions[7]), true); // ext7
        expect(cache.has(extensions[8]), true); // ext8
        expect(cache.has(extensions[9]), true); // ext9
        expect(cache.has(extensions[0]), false);
        expect(cache.has(extensions[1]), false);
      });
    });

    group('integration tests', () {
      test('should handle realistic usage pattern', () {
        // Arrange
        final largeCache = IconCacheService(maxSize: 100);
        final extensions = List.generate(
          50,
          (i) => FileExtension(value: 'ext$i'),
        );

        // Act - Add all items
        for (final ext in extensions) {
          largeCache.put(ext, _createIcon(ext.value));
        }

        // Assert - All should fit
        expect(largeCache.size, 50);
        for (final ext in extensions) {
          expect(largeCache.has(ext), true);
        }

        // Access some items
        for (var i = 0; i < 10; i++) {
          largeCache.get(extensions[i]);
        }

        // Clear and verify
        largeCache.clear();
        expect(largeCache.size, 0);
      });

      test('should handle get-put-has workflow', () {
        // Arrange
        const extension = FileExtension(value: 'dart');
        const icon = FileIcon(
          url: IconUrl(value: 'https://example.com/dart.svg'),
          extension: 'dart',
          themeId: 'test-theme',
        );

        // Act & Assert - Not in cache initially
        expect(cache.has(extension), false);
        expect(cache.get(extension), isNull);

        // Put in cache
        cache.put(extension, icon);
        expect(cache.has(extension), true);
        expect(cache.get(extension), icon);

        // Clear
        cache.clear();
        expect(cache.has(extension), false);
        expect(cache.get(extension), isNull);
      });

      test('should maintain cache integrity during evictions', () {
        // Arrange
        final extensions = List.generate(
          20,
          (i) => FileExtension(value: 'ext$i'),
        );

        // Act - Add many items
        for (final ext in extensions) {
          cache.put(ext, _createIcon(ext.value));

          // Verify size never exceeds max
          expect(cache.size, lessThanOrEqualTo(3));

          // Verify all items in cache can be retrieved
          final currentSize = cache.size;
          var retrievableCount = 0;
          for (final e in extensions) {
            if (cache.get(e) != null) {
              retrievableCount++;
            }
          }
          expect(retrievableCount, currentSize);
        }
      });
    });

    group('edge cases', () {
      test('should handle cache size of 1', () {
        // Arrange
        final tinyCache = IconCacheService(maxSize: 1);
        const ext1 = FileExtension(value: 'ext1');
        const ext2 = FileExtension(value: 'ext2');

        // Act
        tinyCache.put(ext1, _createIcon('ext1'));
        tinyCache.put(ext2, _createIcon('ext2'));

        // Assert
        expect(tinyCache.size, 1);
        expect(tinyCache.has(ext1), false);
        expect(tinyCache.has(ext2), true);
      });

      test('should handle very large cache', () {
        // Arrange
        final bigCache = IconCacheService(maxSize: 10000);

        // Act
        for (var i = 0; i < 1000; i++) {
          bigCache.put(
            FileExtension(value: 'ext$i'),
            _createIcon('ext$i'),
          );
        }

        // Assert
        expect(bigCache.size, 1000);
      });

      test('should handle putting same icon repeatedly', () {
        // Arrange
        const extension = FileExtension(value: 'dart');
        const icon = FileIcon(
          url: IconUrl(value: 'https://example.com/dart.svg'),
          extension: 'dart',
          themeId: 'test-theme',
        );

        // Act
        for (var i = 0; i < 100; i++) {
          cache.put(extension, icon);
        }

        // Assert
        expect(cache.size, 1);
        expect(cache.get(extension), icon);
      });

      test('should handle extension with same value but different instance', () {
        // Arrange
        const ext1 = FileExtension(value: 'dart');
        const ext2 = FileExtension(value: 'dart');
        const icon1 = FileIcon(
          url: IconUrl(value: 'https://example.com/dart1.svg'),
          extension: 'dart',
          themeId: 'theme1',
        );
        const icon2 = FileIcon(
          url: IconUrl(value: 'https://example.com/dart2.svg'),
          extension: 'dart',
          themeId: 'theme2',
        );

        // Act
        cache.put(ext1, icon1);
        cache.put(ext2, icon2);

        // Assert - Should treat as same key
        expect(cache.size, 1);
        expect(cache.get(ext1), icon2);
        expect(cache.get(ext2), icon2);
      });
    });
  });
}

/// Helper function to create test icons
FileIcon _createIcon(String extension) {
  return FileIcon(
    url: IconUrl(value: 'https://example.com/$extension.svg'),
    extension: extension,
    themeId: 'test-theme',
  );
}
