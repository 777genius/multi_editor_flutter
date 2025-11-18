import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:multi_editor_plugin_file_icons/src/infrastructure/providers/iconify_provider.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('SimpleIconsProvider - Creation', () {
    test('should create with default HTTP client', () {
      // Arrange & Act
      final provider = SimpleIconsProvider();

      // Assert
      expect(provider, isNotNull);
    });

    test('should create with custom HTTP client', () {
      // Arrange
      final mockClient = MockHttpClient();

      // Act
      final provider = SimpleIconsProvider(mockClient);

      // Assert
      expect(provider, isNotNull);
    });

    test('should dispose successfully', () {
      // Arrange
      final provider = SimpleIconsProvider();

      // Act & Assert - should not throw
      provider.dispose();
    });
  });

  group('SimpleIconsProvider - Icon URL Generation', () {
    test('should generate URL for Dart extension', () {
      // Arrange
      final provider = SimpleIconsProvider();

      // Act
      final iconUrl = provider.getIconUrl('dart');

      // Assert
      expect(iconUrl.value, contains('devicons/devicon/icons'));
      expect(iconUrl.value, contains('dart/dart-original.svg'));
    });

    test('should generate URL for JavaScript extension', () {
      // Arrange
      final provider = SimpleIconsProvider();

      // Act
      final iconUrl = provider.getIconUrl('js');

      // Assert
      expect(iconUrl.value, contains('javascript/javascript-original.svg'));
    });

    test('should generate URL for TypeScript extension', () {
      // Arrange
      final provider = SimpleIconsProvider();

      // Act
      final iconUrl = provider.getIconUrl('ts');

      // Assert
      expect(iconUrl.value, contains('typescript/typescript-original.svg'));
    });

    test('should generate URL for Python extension', () {
      // Arrange
      final provider = SimpleIconsProvider();

      // Act
      final iconUrl = provider.getIconUrl('py');

      // Assert
      expect(iconUrl.value, contains('python/python-original.svg'));
    });

    test('should use "file" for unknown extensions', () {
      // Arrange
      final provider = SimpleIconsProvider();

      // Act
      final iconUrl = provider.getIconUrl('unknown');

      // Assert
      expect(iconUrl.value, contains('file/file-original.svg'));
    });

    test('should handle empty extension', () {
      // Arrange
      final provider = SimpleIconsProvider();

      // Act
      final iconUrl = provider.getIconUrl('');

      // Assert
      expect(iconUrl.value, contains('file/file-original.svg'));
    });
  });

  group('SimpleIconsProvider - Programming Languages', () {
    test('should map common programming language extensions', () {
      // Arrange
      final provider = SimpleIconsProvider();

      final testCases = [
        ('dart', 'dart'),
        ('js', 'javascript'),
        ('ts', 'typescript'),
        ('py', 'python'),
        ('java', 'java'),
        ('go', 'go'),
        ('rs', 'rust'),
        ('cpp', 'cplusplus'),
        ('c', 'c'),
        ('cs', 'csharp'),
        ('rb', 'ruby'),
        ('php', 'php'),
        ('swift', 'swift'),
        ('kt', 'kotlin'),
      ];

      // Act & Assert
      for (final (extension, expectedIcon) in testCases) {
        final iconUrl = provider.getIconUrl(extension);
        expect(
          iconUrl.value,
          contains('$expectedIcon/$expectedIcon-original.svg'),
          reason: 'Failed for extension: $extension',
        );
      }
    });

    test('should handle JavaScript variants', () {
      // Arrange
      final provider = SimpleIconsProvider();

      final jsVariants = ['js', 'mjs', 'cjs'];

      // Act & Assert
      for (final variant in jsVariants) {
        final iconUrl = provider.getIconUrl(variant);
        expect(
          iconUrl.value,
          contains('javascript/javascript-original.svg'),
          reason: 'Failed for variant: $variant',
        );
      }
    });

    test('should handle TypeScript variants', () {
      // Arrange
      final provider = SimpleIconsProvider();

      final tsVariants = ['ts', 'tsx'];

      // Act & Assert
      for (final variant in tsVariants) {
        final iconUrl = provider.getIconUrl(variant);
        expect(
          iconUrl.value,
          contains('typescript/typescript-original.svg'),
          reason: 'Failed for variant: $variant',
        );
      }
    });

    test('should map JSX to React icon', () {
      // Arrange
      final provider = SimpleIconsProvider();

      // Act
      final iconUrl = provider.getIconUrl('jsx');

      // Assert
      expect(iconUrl.value, contains('react/react-original.svg'));
    });

    test('should handle C++ extensions', () {
      // Arrange
      final provider = SimpleIconsProvider();

      final cppExtensions = ['cpp', 'cc'];

      // Act & Assert
      for (final ext in cppExtensions) {
        final iconUrl = provider.getIconUrl(ext);
        expect(
          iconUrl.value,
          contains('cplusplus/cplusplus-original.svg'),
          reason: 'Failed for extension: $ext',
        );
      }
    });

    test('should handle Kotlin extensions', () {
      // Arrange
      final provider = SimpleIconsProvider();

      final kotlinExtensions = ['kt', 'kts'];

      // Act & Assert
      for (final ext in kotlinExtensions) {
        final iconUrl = provider.getIconUrl(ext);
        expect(
          iconUrl.value,
          contains('kotlin/kotlin-original.svg'),
          reason: 'Failed for extension: $ext',
        );
      }
    });
  });

  group('SimpleIconsProvider - Web Technologies', () {
    test('should map web technology extensions', () {
      // Arrange
      final provider = SimpleIconsProvider();

      final testCases = [
        ('html', 'html5'),
        ('htm', 'html5'),
        ('css', 'css3'),
        ('scss', 'sass'),
        ('sass', 'sass'),
        ('less', 'less'),
        ('vue', 'vuejs'),
        ('svelte', 'svelte'),
      ];

      // Act & Assert
      for (final (extension, expectedIcon) in testCases) {
        final iconUrl = provider.getIconUrl(extension);
        expect(
          iconUrl.value,
          contains('$expectedIcon/$expectedIcon-original.svg'),
          reason: 'Failed for extension: $extension',
        );
      }
    });
  });

  group('SimpleIconsProvider - Data & Config Formats', () {
    test('should map data and config file extensions', () {
      // Arrange
      final provider = SimpleIconsProvider();

      final testCases = [
        ('json', 'json'),
        ('xml', 'xml'),
        ('yaml', 'yaml'),
        ('yml', 'yaml'),
        ('toml', 'toml'),
      ];

      // Act & Assert
      for (final (extension, expectedIcon) in testCases) {
        final iconUrl = provider.getIconUrl(extension);
        expect(
          iconUrl.value,
          contains('$expectedIcon/$expectedIcon-original.svg'),
          reason: 'Failed for extension: $extension',
        );
      }
    });

    test('should handle YAML variants', () {
      // Arrange
      final provider = SimpleIconsProvider();

      final yamlVariants = ['yaml', 'yml'];

      // Act & Assert
      for (final variant in yamlVariants) {
        final iconUrl = provider.getIconUrl(variant);
        expect(
          iconUrl.value,
          contains('yaml/yaml-original.svg'),
          reason: 'Failed for variant: $variant',
        );
      }
    });
  });

  group('SimpleIconsProvider - Shell & Scripts', () {
    test('should map shell script extensions', () {
      // Arrange
      final provider = SimpleIconsProvider();

      final shellExtensions = ['sh', 'bash'];

      // Act & Assert
      for (final ext in shellExtensions) {
        final iconUrl = provider.getIconUrl(ext);
        expect(
          iconUrl.value,
          contains('bash/bash-original.svg'),
          reason: 'Failed for extension: $ext',
        );
      }
    });
  });

  group('SimpleIconsProvider - Database', () {
    test('should map database extensions', () {
      // Arrange
      final provider = SimpleIconsProvider();

      final testCases = [
        ('sql', 'mysql'),
        ('mysql', 'mysql'),
        ('postgres', 'postgresql'),
        ('postgresql', 'postgresql'),
        ('mongo', 'mongodb'),
        ('mongodb', 'mongodb'),
        ('redis', 'redis'),
      ];

      // Act & Assert
      for (final (extension, expectedIcon) in testCases) {
        final iconUrl = provider.getIconUrl(extension);
        expect(
          iconUrl.value,
          contains('$expectedIcon/$expectedIcon-original.svg'),
          reason: 'Failed for extension: $extension',
        );
      }
    });
  });

  group('SimpleIconsProvider - DevOps & Tools', () {
    test('should map DevOps tool extensions', () {
      // Arrange
      final provider = SimpleIconsProvider();

      final testCases = [
        ('docker', 'docker'),
        ('dockerfile', 'docker'),
        ('nginx', 'nginx'),
        ('git', 'git'),
        ('gitignore', 'git'),
      ];

      // Act & Assert
      for (final (extension, expectedIcon) in testCases) {
        final iconUrl = provider.getIconUrl(extension);
        expect(
          iconUrl.value,
          contains('$expectedIcon/$expectedIcon-original.svg'),
          reason: 'Failed for extension: $extension',
        );
      }
    });
  });

  group('SimpleIconsProvider - Markdown & Docs', () {
    test('should map markdown extension', () {
      // Arrange
      final provider = SimpleIconsProvider();

      // Act
      final iconUrl = provider.getIconUrl('md');

      // Assert
      expect(iconUrl.value, contains('markdown/markdown-original.svg'));
    });
  });

  group('SimpleIconsProvider - Images & Assets', () {
    test('should map SVG extension', () {
      // Arrange
      final provider = SimpleIconsProvider();

      // Act
      final iconUrl = provider.getIconUrl('svg');

      // Assert
      expect(iconUrl.value, contains('svg/svg-original.svg'));
    });
  });

  group('SimpleIconsProvider - Build Tools', () {
    test('should map Gradle extension', () {
      // Arrange
      final provider = SimpleIconsProvider();

      // Act
      final iconUrl = provider.getIconUrl('gradle');

      // Assert
      expect(iconUrl.value, contains('gradle/gradle-original.svg'));
    });
  });

  group('SimpleIconsProvider - Package Managers', () {
    test('should map lock files to npm', () {
      // Arrange
      final provider = SimpleIconsProvider();

      // Act
      final iconUrl = provider.getIconUrl('lock');

      // Assert
      expect(iconUrl.value, contains('npm/npm-original.svg'));
    });
  });

  group('SimpleIconsProvider - Case Sensitivity', () {
    test('should handle lowercase extensions', () {
      // Arrange
      final provider = SimpleIconsProvider();

      // Act
      final iconUrl = provider.getIconUrl('dart');

      // Assert
      expect(iconUrl.value, contains('dart/dart-original.svg'));
    });

    test('should handle uppercase extensions', () {
      // Arrange
      final provider = SimpleIconsProvider();

      // Act
      final iconUrl = provider.getIconUrl('DART');

      // Assert
      expect(iconUrl.value, contains('dart/dart-original.svg'));
    });

    test('should handle mixed case extensions', () {
      // Arrange
      final provider = SimpleIconsProvider();

      // Act
      final iconUrl = provider.getIconUrl('DaRt');

      // Assert
      expect(iconUrl.value, contains('dart/dart-original.svg'));
    });
  });

  group('SimpleIconsProvider - URL Format', () {
    test('should use Devicon CDN base URL', () {
      // Arrange
      final provider = SimpleIconsProvider();

      // Act
      final iconUrl = provider.getIconUrl('dart');

      // Assert
      expect(iconUrl.value, startsWith('https://cdn.jsdelivr.net/gh/devicons/devicon/icons/'));
    });

    test('should use -original.svg variant', () {
      // Arrange
      final provider = SimpleIconsProvider();

      // Act
      final iconUrl = provider.getIconUrl('dart');

      // Assert
      expect(iconUrl.value, endsWith('-original.svg'));
    });

    test('should follow pattern: icons/{name}/{name}-original.svg', () {
      // Arrange
      final provider = SimpleIconsProvider();

      // Act
      final iconUrl = provider.getIconUrl('python');

      // Assert
      expect(iconUrl.value, contains('icons/python/python-original.svg'));
    });
  });

  group('SimpleIconsProvider - Icon Existence Check', () {
    test('should check if icon exists (success case)', () async {
      // Arrange
      final mockClient = MockHttpClient();
      final provider = SimpleIconsProvider(mockClient);

      when(() => mockClient.head(any()))
          .thenAnswer((_) async => http.Response('', 200));

      // Act
      final exists = await provider.iconExists('dart');

      // Assert
      expect(exists, true);
      verify(() => mockClient.head(any())).called(1);
    });

    test('should check if icon exists (not found case)', () async {
      // Arrange
      final mockClient = MockHttpClient();
      final provider = SimpleIconsProvider(mockClient);

      when(() => mockClient.head(any()))
          .thenAnswer((_) async => http.Response('', 404));

      // Act
      final exists = await provider.iconExists('unknown');

      // Assert
      expect(exists, false);
      verify(() => mockClient.head(any())).called(1);
    });

    test('should handle network errors when checking existence', () async {
      // Arrange
      final mockClient = MockHttpClient();
      final provider = SimpleIconsProvider(mockClient);

      when(() => mockClient.head(any())).thenThrow(Exception('Network error'));

      // Act
      final exists = await provider.iconExists('dart');

      // Assert
      expect(exists, false);
    });
  });

  group('SimpleIconsProvider - Use Cases', () {
    test('Use Case: Get icons for typical Dart project files', () {
      // Arrange
      final provider = SimpleIconsProvider();
      final extensions = ['dart', 'yaml', 'json', 'md', 'gitignore'];

      // Act
      final iconUrls = extensions.map((ext) => provider.getIconUrl(ext)).toList();

      // Assert
      expect(iconUrls.length, 5);
      expect(iconUrls.every((url) => url.value.isNotEmpty), true);
      expect(iconUrls.every((url) => url.value.contains('devicon')), true);
    });

    test('Use Case: Get icons for web project files', () {
      // Arrange
      final provider = SimpleIconsProvider();
      final extensions = ['html', 'css', 'js', 'ts', 'jsx', 'json'];

      // Act
      final iconUrls = extensions.map((ext) => provider.getIconUrl(ext)).toList();

      // Assert
      expect(iconUrls.length, 6);
      expect(iconUrls.every((url) => url.value.isNotEmpty), true);
    });

    test('Use Case: Get icons for backend project files', () {
      // Arrange
      final provider = SimpleIconsProvider();
      final extensions = ['py', 'java', 'go', 'rs', 'sql', 'docker'];

      // Act
      final iconUrls = extensions.map((ext) => provider.getIconUrl(ext)).toList();

      // Assert
      expect(iconUrls.length, 6);
      expect(iconUrls.every((url) => url.value.isNotEmpty), true);
    });

    test('Use Case: Handle file tree with mixed file types', () {
      // Arrange
      final provider = SimpleIconsProvider();
      final extensions = ['dart', 'unknown123', 'js', '', 'YAML'];

      // Act
      final iconUrls = extensions.map((ext) => provider.getIconUrl(ext)).toList();

      // Assert
      expect(iconUrls.length, 5);
      expect(iconUrls.every((url) => url.value.isNotEmpty), true);
      // Unknown extensions should default to 'file'
      expect(iconUrls[1].value, contains('file/file-original.svg'));
    });

    test('Use Case: Cleanup provider on plugin disposal', () {
      // Arrange
      final provider = SimpleIconsProvider();

      // Use provider
      provider.getIconUrl('dart');
      provider.getIconUrl('js');

      // Act - Dispose
      provider.dispose();

      // Assert - Should not throw
      expect(provider, isNotNull);
    });
  });

  group('SimpleIconsProvider - Edge Cases', () {
    test('should handle null-like empty string', () {
      // Arrange
      final provider = SimpleIconsProvider();

      // Act
      final iconUrl = provider.getIconUrl('');

      // Assert
      expect(iconUrl.value, contains('file/file-original.svg'));
    });

    test('should handle extensions with whitespace', () {
      // Arrange
      final provider = SimpleIconsProvider();

      // Act
      final iconUrl = provider.getIconUrl('  dart  ');

      // Assert
      expect(iconUrl.value, isNotEmpty);
    });

    test('should handle very long extension names', () {
      // Arrange
      final provider = SimpleIconsProvider();
      final longExtension = 'a' * 100;

      // Act
      final iconUrl = provider.getIconUrl(longExtension);

      // Assert
      expect(iconUrl.value, contains('file/file-original.svg'));
    });

    test('should handle special characters in extension', () {
      // Arrange
      final provider = SimpleIconsProvider();

      // Act
      final iconUrl = provider.getIconUrl('test@#\$');

      // Assert
      expect(iconUrl.value, contains('file/file-original.svg'));
    });

    test('should handle numeric extensions', () {
      // Arrange
      final provider = SimpleIconsProvider();

      // Act
      final iconUrl = provider.getIconUrl('123');

      // Assert
      expect(iconUrl.value, contains('file/file-original.svg'));
    });
  });

  group('SimpleIconsProvider - Comprehensive Language Coverage', () {
    test('should cover functional programming languages', () {
      // Arrange
      final provider = SimpleIconsProvider();

      final testCases = [
        ('hs', 'haskell'),
        ('clj', 'clojure'),
        ('fs', 'fsharp'),
        ('scala', 'scala'),
      ];

      // Act & Assert
      for (final (extension, expectedIcon) in testCases) {
        final iconUrl = provider.getIconUrl(extension);
        expect(
          iconUrl.value,
          contains('$expectedIcon/$expectedIcon-original.svg'),
          reason: 'Failed for extension: $extension',
        );
      }
    });

    test('should cover dynamic/scripting languages', () {
      // Arrange
      final provider = SimpleIconsProvider();

      final testCases = [
        ('rb', 'ruby'),
        ('lua', 'lua'),
        ('pl', 'perl'),
        ('groovy', 'groovy'),
      ];

      // Act & Assert
      for (final (extension, expectedIcon) in testCases) {
        final iconUrl = provider.getIconUrl(extension);
        expect(
          iconUrl.value,
          contains('$expectedIcon/$expectedIcon-original.svg'),
          reason: 'Failed for extension: $extension',
        );
      }
    });

    test('should cover Erlang/Elixir ecosystem', () {
      // Arrange
      final provider = SimpleIconsProvider();

      final testCases = [
        ('ex', 'elixir'),
        ('exs', 'elixir'),
        ('erl', 'erlang'),
      ];

      // Act & Assert
      for (final (extension, expectedIcon) in testCases) {
        final iconUrl = provider.getIconUrl(extension);
        expect(
          iconUrl.value,
          contains('$expectedIcon/$expectedIcon-original.svg'),
          reason: 'Failed for extension: $extension',
        );
      }
    });

    test('should cover statistical languages', () {
      // Arrange
      final provider = SimpleIconsProvider();

      // Act
      final iconUrl = provider.getIconUrl('r');

      // Assert
      expect(iconUrl.value, contains('r/r-original.svg'));
    });
  });
}
