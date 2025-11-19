import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugin_file_icons/src/domain/entities/file_icon.dart';
import 'package:multi_editor_plugin_file_icons/src/domain/value_objects/icon_url.dart';

void main() {
  group('FileIcon', () {
    group('constructor', () {
      test('should create instance with required fields', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');

        // Act
        final icon = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
        );

        // Assert
        expect(icon.url, url);
        expect(icon.extension, 'dart');
        expect(icon.themeId, 'vscode-icons');
        expect(icon.format, 'svg');
        expect(icon.size, 18);
        expect(icon.isLoaded, false);
        expect(icon.errorMessage, isNull);
      });

      test('should create instance with all fields', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.png');

        // Act
        final icon = FileIcon(
          url: url,
          extension: 'js',
          themeId: 'material-icons',
          format: 'png',
          size: 24,
          isLoaded: true,
          errorMessage: null,
        );

        // Assert
        expect(icon.url, url);
        expect(icon.extension, 'js');
        expect(icon.themeId, 'material-icons');
        expect(icon.format, 'png');
        expect(icon.size, 24);
        expect(icon.isLoaded, true);
        expect(icon.errorMessage, isNull);
      });

      test('should create instance with error', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/missing.svg');

        // Act
        final icon = FileIcon(
          url: url,
          extension: 'unknown',
          themeId: 'vscode-icons',
          isLoaded: false,
          errorMessage: 'Failed to load icon',
        );

        // Assert
        expect(icon.url, url);
        expect(icon.extension, 'unknown');
        expect(icon.isLoaded, false);
        expect(icon.errorMessage, 'Failed to load icon');
      });

      test('should handle different file extensions', () {
        // Arrange
        final extensions = ['dart', 'js', 'ts', 'json', 'yaml', 'md', 'html'];

        // Act & Assert
        for (final ext in extensions) {
          final url = IconUrl.parse('https://cdn.example.com/$ext.svg');
          final icon = FileIcon(
            url: url,
            extension: ext,
            themeId: 'vscode-icons',
          );
          expect(icon.extension, ext);
        }
      });

      test('should handle different theme IDs', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');
        final themes = ['vscode-icons', 'material-icons', 'custom-theme'];

        // Act & Assert
        for (final themeId in themes) {
          final icon = FileIcon(
            url: url,
            extension: 'dart',
            themeId: themeId,
          );
          expect(icon.themeId, themeId);
        }
      });

      test('should handle different icon formats', () {
        // Arrange
        final formats = ['svg', 'png', 'jpg', 'webp'];

        // Act & Assert
        for (final format in formats) {
          final url = IconUrl.parse('https://cdn.example.com/icon.$format');
          final icon = FileIcon(
            url: url,
            extension: 'dart',
            themeId: 'vscode-icons',
            format: format,
          );
          expect(icon.format, format);
        }
      });

      test('should handle different icon sizes', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');
        final sizes = [16, 18, 24, 32, 48, 64];

        // Act & Assert
        for (final size in sizes) {
          final icon = FileIcon(
            url: url,
            extension: 'dart',
            themeId: 'vscode-icons',
            size: size,
          );
          expect(icon.size, size);
        }
      });
    });

    group('isAvailable getter', () {
      test('should return true when loaded and no error', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');
        final icon = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
          isLoaded: true,
          errorMessage: null,
        );

        // Act & Assert
        expect(icon.isAvailable, true);
      });

      test('should return false when not loaded', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');
        final icon = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
          isLoaded: false,
          errorMessage: null,
        );

        // Act & Assert
        expect(icon.isAvailable, false);
      });

      test('should return false when error exists', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');
        final icon = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
          isLoaded: true,
          errorMessage: 'Failed to load',
        );

        // Act & Assert
        expect(icon.isAvailable, false);
      });

      test('should return false when not loaded and has error', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');
        final icon = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
          isLoaded: false,
          errorMessage: 'Network error',
        );

        // Act & Assert
        expect(icon.isAvailable, false);
      });
    });

    group('hasFailed getter', () {
      test('should return true when error message exists', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');
        final icon = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
          errorMessage: 'Failed to load',
        );

        // Act & Assert
        expect(icon.hasFailed, true);
      });

      test('should return false when no error message', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');
        final icon = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
          errorMessage: null,
        );

        // Act & Assert
        expect(icon.hasFailed, false);
      });

      test('should return true for empty error message', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');
        final icon = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
          errorMessage: '',
        );

        // Act & Assert
        expect(icon.hasFailed, true);
      });
    });

    group('equality', () {
      test('should be equal when all fields are the same', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');
        final icon1 = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
          format: 'svg',
          size: 18,
          isLoaded: true,
        );
        final icon2 = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
          format: 'svg',
          size: 18,
          isLoaded: true,
        );

        // Act & Assert
        expect(icon1, equals(icon2));
        expect(icon1.hashCode, equals(icon2.hashCode));
      });

      test('should not be equal when extension differs', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');
        final icon1 = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
        );
        final icon2 = FileIcon(
          url: url,
          extension: 'js',
          themeId: 'vscode-icons',
        );

        // Act & Assert
        expect(icon1, isNot(equals(icon2)));
      });

      test('should not be equal when URL differs', () {
        // Arrange
        final url1 = IconUrl.parse('https://cdn.example.com/icon1.svg');
        final url2 = IconUrl.parse('https://cdn.example.com/icon2.svg');
        final icon1 = FileIcon(
          url: url1,
          extension: 'dart',
          themeId: 'vscode-icons',
        );
        final icon2 = FileIcon(
          url: url2,
          extension: 'dart',
          themeId: 'vscode-icons',
        );

        // Act & Assert
        expect(icon1, isNot(equals(icon2)));
      });

      test('should not be equal when theme ID differs', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');
        final icon1 = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
        );
        final icon2 = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'material-icons',
        );

        // Act & Assert
        expect(icon1, isNot(equals(icon2)));
      });

      test('should not be equal when size differs', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');
        final icon1 = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
          size: 18,
        );
        final icon2 = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
          size: 24,
        );

        // Act & Assert
        expect(icon1, isNot(equals(icon2)));
      });

      test('should not be equal when isLoaded differs', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');
        final icon1 = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
          isLoaded: true,
        );
        final icon2 = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
          isLoaded: false,
        );

        // Act & Assert
        expect(icon1, isNot(equals(icon2)));
      });
    });

    group('copyWith', () {
      test('should copy with new URL', () {
        // Arrange
        final url1 = IconUrl.parse('https://cdn.example.com/icon1.svg');
        final url2 = IconUrl.parse('https://cdn.example.com/icon2.svg');
        final original = FileIcon(
          url: url1,
          extension: 'dart',
          themeId: 'vscode-icons',
        );

        // Act
        final copied = original.copyWith(url: url2);

        // Assert
        expect(copied.url, url2);
        expect(copied.extension, original.extension);
        expect(original.url, url1);
      });

      test('should copy with new extension', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');
        final original = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
        );

        // Act
        final copied = original.copyWith(extension: 'js');

        // Assert
        expect(copied.extension, 'js');
        expect(original.extension, 'dart');
      });

      test('should copy with new theme ID', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');
        final original = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
        );

        // Act
        final copied = original.copyWith(themeId: 'material-icons');

        // Assert
        expect(copied.themeId, 'material-icons');
        expect(original.themeId, 'vscode-icons');
      });

      test('should copy with new format', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');
        final original = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
          format: 'svg',
        );

        // Act
        final copied = original.copyWith(format: 'png');

        // Assert
        expect(copied.format, 'png');
        expect(original.format, 'svg');
      });

      test('should copy with new size', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');
        final original = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
          size: 18,
        );

        // Act
        final copied = original.copyWith(size: 24);

        // Assert
        expect(copied.size, 24);
        expect(original.size, 18);
      });

      test('should copy with new isLoaded', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');
        final original = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
          isLoaded: false,
        );

        // Act
        final copied = original.copyWith(isLoaded: true);

        // Assert
        expect(copied.isLoaded, true);
        expect(original.isLoaded, false);
      });

      test('should copy with new error message', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');
        final original = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
        );

        // Act
        final copied = original.copyWith(errorMessage: 'Network error');

        // Assert
        expect(copied.errorMessage, 'Network error');
        expect(original.errorMessage, isNull);
      });

      test('should copy multiple fields at once', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');
        final original = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
          isLoaded: false,
        );

        // Act
        final copied = original.copyWith(
          extension: 'js',
          size: 24,
          isLoaded: true,
          format: 'png',
        );

        // Assert
        expect(copied.extension, 'js');
        expect(copied.size, 24);
        expect(copied.isLoaded, true);
        expect(copied.format, 'png');
      });
    });

    group('edge cases', () {
      test('should handle empty extension', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');

        // Act
        final icon = FileIcon(
          url: url,
          extension: '',
          themeId: 'vscode-icons',
        );

        // Assert
        expect(icon.extension, '');
      });

      test('should handle empty theme ID', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');

        // Act
        final icon = FileIcon(
          url: url,
          extension: 'dart',
          themeId: '',
        );

        // Assert
        expect(icon.themeId, '');
      });

      test('should handle zero size', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');

        // Act
        final icon = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
          size: 0,
        );

        // Assert
        expect(icon.size, 0);
      });

      test('should handle very large size', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');

        // Act
        final icon = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
          size: 1024,
        );

        // Assert
        expect(icon.size, 1024);
      });

      test('should handle long error messages', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');
        final longError = 'Error: ' * 100;

        // Act
        final icon = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
          errorMessage: longError,
        );

        // Assert
        expect(icon.errorMessage, longError);
        expect(icon.hasFailed, true);
      });

      test('should handle unicode in extension', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');

        // Act
        final icon = FileIcon(
          url: url,
          extension: 'dart文件',
          themeId: 'vscode-icons',
        );

        // Assert
        expect(icon.extension, 'dart文件');
      });

      test('should handle special characters in extension', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/icon.svg');

        // Act
        final icon = FileIcon(
          url: url,
          extension: 'file.backup.tar.gz',
          themeId: 'vscode-icons',
        );

        // Assert
        expect(icon.extension, 'file.backup.tar.gz');
      });
    });

    group('practical examples', () {
      test('should represent a loading icon state', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.jsdelivr.net/npm/vscode-icons/icons/file_type_dart.svg');

        // Act
        final icon = FileIcon(
          url: url,
          extension: 'dart',
          themeId: 'vscode-icons',
          format: 'svg',
          size: 18,
          isLoaded: false,
        );

        // Assert
        expect(icon.isLoaded, false);
        expect(icon.isAvailable, false);
        expect(icon.hasFailed, false);
      });

      test('should represent a successfully loaded icon', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.jsdelivr.net/npm/vscode-icons/icons/file_type_js.svg');

        // Act
        final icon = FileIcon(
          url: url,
          extension: 'js',
          themeId: 'vscode-icons',
          format: 'svg',
          size: 18,
          isLoaded: true,
        );

        // Assert
        expect(icon.isLoaded, true);
        expect(icon.isAvailable, true);
        expect(icon.hasFailed, false);
      });

      test('should represent a failed icon load', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/missing.svg');

        // Act
        final icon = FileIcon(
          url: url,
          extension: 'unknown',
          themeId: 'vscode-icons',
          format: 'svg',
          size: 18,
          isLoaded: false,
          errorMessage: '404 Not Found',
        );

        // Assert
        expect(icon.isLoaded, false);
        expect(icon.isAvailable, false);
        expect(icon.hasFailed, true);
        expect(icon.errorMessage, '404 Not Found');
      });

      test('should represent icon with custom theme and size', () {
        // Arrange
        final url = IconUrl.parse('https://cdn.example.com/custom-theme/typescript.svg');

        // Act
        final icon = FileIcon(
          url: url,
          extension: 'ts',
          themeId: 'custom-theme',
          format: 'svg',
          size: 24,
          isLoaded: true,
        );

        // Assert
        expect(icon.themeId, 'custom-theme');
        expect(icon.size, 24);
        expect(icon.extension, 'ts');
      });
    });
  });
}
