import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugin_file_icons/src/domain/entities/icon_theme.dart';
import 'package:multi_editor_plugin_file_icons/src/domain/services/icon_resolution_service.dart';
import 'package:multi_editor_plugin_file_icons/src/domain/value_objects/file_extension.dart';

void main() {
  group('IconResolutionService', () {
    late IconResolutionService service;
    late IconTheme testTheme;

    setUp(() {
      service = IconResolutionService();
      testTheme = const IconTheme(
        id: 'test-theme',
        name: 'Test Theme',
        provider: 'iconify',
        baseUrl: 'https://api.iconify.design',
        priority: 50,
        isActive: true,
        supportedExtensions: ['dart', 'js', 'ts', 'json'],
      );
    });

    group('resolveIconUrl', () {
      test('should resolve icon URL for supported extension', () {
        // Arrange
        const extension = FileExtension(value: 'dart');

        // Act
        final url = service.resolveIconUrl(extension, testTheme);

        // Assert
        expect(
          url.value,
          'https://api.iconify.design/vscode-icons:file-type-dart.svg',
        );
      });

      test('should return generic icon for unsupported extension', () {
        // Arrange
        const extension = FileExtension(value: 'xyz');

        // Act
        final url = service.resolveIconUrl(extension, testTheme);

        // Assert
        expect(
          url.value,
          'https://api.iconify.design/vscode-icons:file-type-default.svg',
        );
      });

      test('should return generic icon for unknown extension', () {
        // Arrange
        const extension = FileExtension(value: 'unknown');

        // Act
        final url = service.resolveIconUrl(extension, testTheme);

        // Assert
        expect(
          url.value,
          'https://api.iconify.design/vscode-icons:file-type-default.svg',
        );
      });

      test('should handle all supported extensions', () {
        // Arrange
        const extensions = ['dart', 'js', 'ts', 'json'];

        // Act & Assert
        for (final ext in extensions) {
          final extension = FileExtension(value: ext);
          final url = service.resolveIconUrl(extension, testTheme);
          expect(
            url.value,
            'https://api.iconify.design/vscode-icons:file-type-$ext.svg',
          );
        }
      });

      test('should handle theme with empty supported extensions (supports all)',
          () {
        // Arrange
        final themeWithAllExtensions = testTheme.copyWith(
          supportedExtensions: [],
        );
        const extension = FileExtension(value: 'py');

        // Act
        final url = service.resolveIconUrl(extension, themeWithAllExtensions);

        // Assert
        expect(
          url.value,
          'https://api.iconify.design/vscode-icons:file-type-py.svg',
        );
      });

      test('should handle different theme providers', () {
        // Arrange - VSCode provider
        final vscodeTheme = testTheme.copyWith(
          provider: 'vscode',
          baseUrl: 'https://cdn.example.com/vscode',
          supportedExtensions: [],
        );
        const extension = FileExtension(value: 'dart');

        // Act
        final url = service.resolveIconUrl(extension, vscodeTheme);

        // Assert
        expect(
          url.value,
          'https://cdn.example.com/vscode/icons/file_type_dart.svg',
        );
      });

      test('should handle material theme provider', () {
        // Arrange
        final materialTheme = testTheme.copyWith(
          provider: 'material',
          baseUrl: 'https://cdn.example.com/material',
          supportedExtensions: [],
        );
        const extension = FileExtension(value: 'js');

        // Act
        final url = service.resolveIconUrl(extension, materialTheme);

        // Assert
        expect(url.value, 'https://cdn.example.com/material/icons/js.svg');
      });

      test('should handle custom theme provider', () {
        // Arrange
        final customTheme = testTheme.copyWith(
          provider: 'custom',
          baseUrl: 'https://custom.cdn.com',
          supportedExtensions: [],
        );
        const extension = FileExtension(value: 'go');

        // Act
        final url = service.resolveIconUrl(extension, customTheme);

        // Assert
        expect(url.value, 'https://custom.cdn.com/go.svg');
      });

      test('should return fallback URL when theme getIconUrl throws', () {
        // Arrange - Create a theme that will cause parsing to fail
        final invalidTheme = testTheme.copyWith(
          baseUrl: 'invalid-url',
          supportedExtensions: [],
        );
        const extension = FileExtension(value: 'dart');

        // Act
        final url = service.resolveIconUrl(extension, invalidTheme);

        // Assert - Should fall back to default generic icon
        expect(
          url.value,
          'https://api.iconify.design/vscode-icons:default-file.svg',
        );
      });
    });

    group('createFileIcon', () {
      test('should create FileIcon with correct properties', () {
        // Arrange
        const extension = FileExtension(value: 'dart');

        // Act
        final icon = service.createFileIcon(extension, testTheme);

        // Assert
        expect(icon.extension, 'dart');
        expect(icon.themeId, 'test-theme');
        expect(icon.format, 'svg');
        expect(icon.size, 18);
        expect(
          icon.url.value,
          'https://api.iconify.design/vscode-icons:file-type-dart.svg',
        );
      });

      test('should create FileIcon with custom size', () {
        // Arrange
        const extension = FileExtension(value: 'js');

        // Act
        final icon = service.createFileIcon(extension, testTheme, size: 24);

        // Assert
        expect(icon.size, 24);
        expect(icon.extension, 'js');
      });

      test('should create FileIcon with default size when not specified', () {
        // Arrange
        const extension = FileExtension(value: 'ts');

        // Act
        final icon = service.createFileIcon(extension, testTheme);

        // Assert
        expect(icon.size, 18);
      });

      test('should create FileIcon for unknown extension', () {
        // Arrange
        const extension = FileExtension(value: 'unknown');

        // Act
        final icon = service.createFileIcon(extension, testTheme);

        // Assert
        expect(icon.extension, 'unknown');
        expect(
          icon.url.value,
          'https://api.iconify.design/vscode-icons:file-type-default.svg',
        );
      });

      test('should create different icons for different extensions', () {
        // Arrange
        const extensions = [
          FileExtension(value: 'dart'),
          FileExtension(value: 'js'),
          FileExtension(value: 'ts'),
        ];

        // Act
        final icons = extensions.map((ext) {
          return service.createFileIcon(ext, testTheme);
        }).toList();

        // Assert
        expect(icons[0].extension, 'dart');
        expect(icons[1].extension, 'js');
        expect(icons[2].extension, 'ts');
        expect(icons[0].url.value, contains('dart'));
        expect(icons[1].url.value, contains('js'));
        expect(icons[2].url.value, contains('ts'));
      });
    });

    group('extractExtension', () {
      test('should extract standard extension', () {
        // Arrange
        const filename = 'test.dart';

        // Act
        final extension = service.extractExtension(filename);

        // Assert
        expect(extension.value, 'dart');
      });

      test('should extract compound extension (test files)', () {
        // Arrange
        const filename = 'widget.test.dart';

        // Act
        final extension = service.extractExtension(filename);

        // Assert
        expect(extension.value, 'test.dart');
      });

      test('should extract compound extension (spec files)', () {
        // Arrange
        const filename = 'component.spec.ts';

        // Act
        final extension = service.extractExtension(filename);

        // Assert
        expect(extension.value, 'spec.ts');
      });

      test('should extract compound extension (stories files)', () {
        // Arrange
        const filename = 'button.stories.js';

        // Act
        final extension = service.extractExtension(filename);

        // Assert
        expect(extension.value, 'stories.js');
      });

      test('should extract compound extension (declaration files)', () {
        // Arrange
        const filename = 'types.d.ts';

        // Act
        final extension = service.extractExtension(filename);

        // Assert
        expect(extension.value, 'd.ts');
      });

      test('should handle special file: dockerfile', () {
        // Arrange
        const filename = 'Dockerfile';

        // Act
        final extension = service.extractExtension(filename);

        // Assert
        expect(extension.value, 'dockerfile');
      });

      test('should handle special file: dockerfile (lowercase)', () {
        // Arrange
        const filename = 'dockerfile';

        // Act
        final extension = service.extractExtension(filename);

        // Assert
        expect(extension.value, 'dockerfile');
      });

      test('should handle special file: makefile', () {
        // Arrange
        const filename = 'Makefile';

        // Act
        final extension = service.extractExtension(filename);

        // Assert
        expect(extension.value, 'makefile');
      });

      test('should handle special file: cmakelists.txt', () {
        // Arrange
        const filename = 'CMakeLists.txt';

        // Act
        final extension = service.extractExtension(filename);

        // Assert
        expect(extension.value, 'cmake');
      });

      test('should handle special file: .gitignore', () {
        // Arrange
        const filename = '.gitignore';

        // Act
        final extension = service.extractExtension(filename);

        // Assert
        expect(extension.value, 'git');
      });

      test('should handle special file: .dockerignore', () {
        // Arrange
        const filename = '.dockerignore';

        // Act
        final extension = service.extractExtension(filename);

        // Assert
        expect(extension.value, 'docker');
      });

      test('should handle special file: .env', () {
        // Arrange
        const filename = '.env';

        // Act
        final extension = service.extractExtension(filename);

        // Assert
        expect(extension.value, 'env');
      });

      test('should return unknown for empty filename', () {
        // Arrange
        const filename = '';

        // Act
        final extension = service.extractExtension(filename);

        // Assert
        expect(extension.value, 'unknown');
      });

      test('should handle filename with multiple dots', () {
        // Arrange
        const filename = 'my.config.json';

        // Act
        final extension = service.extractExtension(filename);

        // Assert
        expect(extension.value, 'json');
      });

      test('should handle uppercase extension', () {
        // Arrange
        const filename = 'README.MD';

        // Act
        final extension = service.extractExtension(filename);

        // Assert
        expect(extension.value, 'md');
      });

      test('should handle filename without extension', () {
        // Arrange
        const filename = 'README';

        // Act
        final extension = service.extractExtension(filename);

        // Assert
        expect(extension.value, 'unknown');
      });

      test('should handle hidden file without extension', () {
        // Arrange
        const filename = '.hidden';

        // Act
        final extension = service.extractExtension(filename);

        // Assert
        expect(extension.value, 'hidden');
      });
    });

    group('getIconPriority', () {
      test('should return theme priority', () {
        // Arrange
        final theme = testTheme.copyWith(priority: 100);

        // Act
        final priority = service.getIconPriority(theme);

        // Assert
        expect(priority, 100);
      });

      test('should handle different priority values', () {
        // Arrange
        final themes = [
          testTheme.copyWith(priority: 1),
          testTheme.copyWith(priority: 50),
          testTheme.copyWith(priority: 100),
        ];

        // Act & Assert
        expect(service.getIconPriority(themes[0]), 1);
        expect(service.getIconPriority(themes[1]), 50);
        expect(service.getIconPriority(themes[2]), 100);
      });

      test('should handle zero priority', () {
        // Arrange
        final theme = testTheme.copyWith(priority: 0);

        // Act
        final priority = service.getIconPriority(theme);

        // Assert
        expect(priority, 0);
      });
    });

    group('shouldLoadEagerly', () {
      test('should load common extensions eagerly', () {
        // Arrange
        const eagerExtensions = [
          'dart',
          'js',
          'ts',
          'json',
          'md',
          'yaml',
          'yml',
          'html',
          'css',
          'scss',
          'py',
          'java',
          'go',
          'rs',
        ];

        // Act & Assert
        for (final ext in eagerExtensions) {
          final extension = FileExtension(value: ext);
          expect(
            service.shouldLoadEagerly(extension),
            true,
            reason: '$ext should be loaded eagerly',
          );
        }
      });

      test('should load uncommon extensions lazily', () {
        // Arrange
        const lazyExtensions = [
          'txt',
          'pdf',
          'exe',
          'zip',
          'tar',
          'unknown',
        ];

        // Act & Assert
        for (final ext in lazyExtensions) {
          final extension = FileExtension(value: ext);
          expect(
            service.shouldLoadEagerly(extension),
            false,
            reason: '$ext should be loaded lazily',
          );
        }
      });

      test('should handle unknown extension', () {
        // Arrange
        const extension = FileExtension(value: 'unknown');

        // Act
        final shouldLoad = service.shouldLoadEagerly(extension);

        // Assert
        expect(shouldLoad, false);
      });

      test('should handle all common web extensions', () {
        // Arrange
        const webExtensions = ['html', 'css', 'scss', 'js', 'ts'];

        // Act & Assert
        for (final ext in webExtensions) {
          final extension = FileExtension(value: ext);
          expect(service.shouldLoadEagerly(extension), true);
        }
      });
    });

    group('integration tests', () {
      test('should handle complete workflow for common file', () {
        // Arrange
        const filename = 'main.dart';

        // Act
        final extension = service.extractExtension(filename);
        final shouldLoadEager = service.shouldLoadEagerly(extension);
        final url = service.resolveIconUrl(extension, testTheme);
        final icon = service.createFileIcon(extension, testTheme);

        // Assert
        expect(extension.value, 'dart');
        expect(shouldLoadEager, true);
        expect(url.value, contains('dart'));
        expect(icon.extension, 'dart');
        expect(icon.themeId, 'test-theme');
      });

      test('should handle complete workflow for test file', () {
        // Arrange
        const filename = 'widget.test.dart';

        // Act
        final extension = service.extractExtension(filename);
        final url = service.resolveIconUrl(extension, testTheme);
        final icon = service.createFileIcon(extension, testTheme, size: 20);

        // Assert
        expect(extension.value, 'test.dart');
        expect(icon.extension, 'test.dart');
        expect(icon.size, 20);
      });

      test('should handle complete workflow for special file', () {
        // Arrange
        const filename = 'Dockerfile';

        // Act
        final extension = service.extractExtension(filename);
        final shouldLoadEager = service.shouldLoadEagerly(extension);
        final icon = service.createFileIcon(extension, testTheme);

        // Assert
        expect(extension.value, 'dockerfile');
        expect(shouldLoadEager, false);
        expect(icon.extension, 'dockerfile');
      });

      test('should handle complete workflow for config file', () {
        // Arrange
        const filename = '.gitignore';

        // Act
        final extension = service.extractExtension(filename);
        final url = service.resolveIconUrl(extension, testTheme);

        // Assert
        expect(extension.value, 'git');
        expect(url.value, isNotEmpty);
      });

      test('should compare priorities across multiple themes', () {
        // Arrange
        final themes = [
          testTheme.copyWith(id: 'theme1', priority: 100),
          testTheme.copyWith(id: 'theme2', priority: 50),
          testTheme.copyWith(id: 'theme3', priority: 1),
        ];

        // Act
        final priorities = themes.map((t) => service.getIconPriority(t)).toList();

        // Assert
        expect(priorities, [100, 50, 1]);
        expect(priorities[2] < priorities[1], true); // Lower value = higher priority
        expect(priorities[1] < priorities[0], true);
      });
    });
  });
}
