import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:multi_editor_plugin_file_icons/src/infrastructure/providers/iconify_provider.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('SimpleIconsProvider', () {
    late MockHttpClient mockClient;
    late SimpleIconsProvider provider;

    setUp(() {
      mockClient = MockHttpClient();
      provider = SimpleIconsProvider(mockClient);
    });

    tearDown(() {
      provider.dispose();
    });

    group('getIconUrl', () {
      test('should return correct URL for dart extension', () {
        // Arrange
        const extension = 'dart';

        // Act
        final url = provider.getIconUrl(extension);

        // Assert
        expect(
          url.value,
          'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/dart/dart-original.svg',
        );
      });

      test('should return correct URL for javascript extensions', () {
        // Arrange
        const extensions = ['js', 'mjs', 'cjs'];

        // Act & Assert
        for (final ext in extensions) {
          final url = provider.getIconUrl(ext);
          expect(
            url.value,
            'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/javascript/javascript-original.svg',
            reason: '$ext should map to javascript icon',
          );
        }
      });

      test('should return correct URL for typescript extensions', () {
        // Arrange
        const extensions = ['ts', 'tsx'];

        // Act & Assert
        for (final ext in extensions) {
          final url = provider.getIconUrl(ext);
          expect(
            url.value,
            'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/typescript/typescript-original.svg',
            reason: '$ext should map to typescript icon',
          );
        }
      });

      test('should return correct URL for python', () {
        // Arrange
        const extension = 'py';

        // Act
        final url = provider.getIconUrl(extension);

        // Assert
        expect(
          url.value,
          'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/python/python-original.svg',
        );
      });

      test('should return correct URL for java', () {
        // Arrange
        const extension = 'java';

        // Act
        final url = provider.getIconUrl(extension);

        // Assert
        expect(
          url.value,
          'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/java/java-original.svg',
        );
      });

      test('should return correct URL for go', () {
        // Arrange
        const extension = 'go';

        // Act
        final url = provider.getIconUrl(extension);

        // Assert
        expect(
          url.value,
          'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/go/go-original.svg',
        );
      });

      test('should return correct URL for rust', () {
        // Arrange
        const extension = 'rs';

        // Act
        final url = provider.getIconUrl(extension);

        // Assert
        expect(
          url.value,
          'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/rust/rust-original.svg',
        );
      });

      test('should handle C++ extensions', () {
        // Arrange
        const extensions = ['cpp', 'cc'];

        // Act & Assert
        for (final ext in extensions) {
          final url = provider.getIconUrl(ext);
          expect(
            url.value,
            'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/cplusplus/cplusplus-original.svg',
            reason: '$ext should map to cplusplus icon',
          );
        }
      });

      test('should return correct URL for C', () {
        // Arrange
        const extension = 'c';

        // Act
        final url = provider.getIconUrl(extension);

        // Assert
        expect(
          url.value,
          'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/c/c-original.svg',
        );
      });

      test('should return correct URL for C#', () {
        // Arrange
        const extension = 'cs';

        // Act
        final url = provider.getIconUrl(extension);

        // Assert
        expect(
          url.value,
          'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/csharp/csharp-original.svg',
        );
      });

      test('should handle web technology extensions', () {
        // Arrange & Act & Assert
        final webExtensions = {
          'html': 'html5',
          'htm': 'html5',
          'css': 'css3',
          'scss': 'sass',
          'sass': 'sass',
          'less': 'less',
          'vue': 'vuejs',
          'svelte': 'svelte',
        };

        for (final entry in webExtensions.entries) {
          final url = provider.getIconUrl(entry.key);
          expect(
            url.value,
            'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/${entry.value}/${entry.value}-original.svg',
            reason: '${entry.key} should map to ${entry.value}',
          );
        }
      });

      test('should handle data and config file extensions', () {
        // Arrange & Act & Assert
        final dataExtensions = {
          'json': 'json',
          'xml': 'xml',
          'yaml': 'yaml',
          'yml': 'yaml',
          'toml': 'toml',
        };

        for (final entry in dataExtensions.entries) {
          final url = provider.getIconUrl(entry.key);
          expect(
            url.value,
            'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/${entry.value}/${entry.value}-original.svg',
            reason: '${entry.key} should map to ${entry.value}',
          );
        }
      });

      test('should return correct URL for markdown', () {
        // Arrange
        const extension = 'md';

        // Act
        final url = provider.getIconUrl(extension);

        // Assert
        expect(
          url.value,
          'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/markdown/markdown-original.svg',
        );
      });

      test('should handle shell script extensions', () {
        // Arrange
        const extensions = ['sh', 'bash'];

        // Act & Assert
        for (final ext in extensions) {
          final url = provider.getIconUrl(ext);
          expect(
            url.value,
            'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/bash/bash-original.svg',
            reason: '$ext should map to bash icon',
          );
        }
      });

      test('should handle docker files', () {
        // Arrange
        const extensions = ['docker', 'dockerfile'];

        // Act & Assert
        for (final ext in extensions) {
          final url = provider.getIconUrl(ext);
          expect(
            url.value,
            'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/docker/docker-original.svg',
            reason: '$ext should map to docker icon',
          );
        }
      });

      test('should handle git files', () {
        // Arrange
        const extensions = ['git', 'gitignore'];

        // Act & Assert
        for (final ext in extensions) {
          final url = provider.getIconUrl(ext);
          expect(
            url.value,
            'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/git/git-original.svg',
            reason: '$ext should map to git icon',
          );
        }
      });

      test('should handle Kotlin extensions', () {
        // Arrange
        const extensions = ['kt', 'kts'];

        // Act & Assert
        for (final ext in extensions) {
          final url = provider.getIconUrl(ext);
          expect(
            url.value,
            'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/kotlin/kotlin-original.svg',
            reason: '$ext should map to kotlin icon',
          );
        }
      });

      test('should handle Elixir extensions', () {
        // Arrange
        const extensions = ['ex', 'exs'];

        // Act & Assert
        for (final ext in extensions) {
          final url = provider.getIconUrl(ext);
          expect(
            url.value,
            'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/elixir/elixir-original.svg',
            reason: '$ext should map to elixir icon',
          );
        }
      });

      test('should return file icon for unknown extension', () {
        // Arrange
        const extension = 'xyz';

        // Act
        final url = provider.getIconUrl(extension);

        // Assert
        expect(
          url.value,
          'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/file/file-original.svg',
        );
      });

      test('should handle uppercase extension', () {
        // Arrange
        const extension = 'DART';

        // Act
        final url = provider.getIconUrl(extension);

        // Assert
        expect(
          url.value,
          'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/dart/dart-original.svg',
        );
      });

      test('should handle mixed case extension', () {
        // Arrange
        const extension = 'JavaScript';

        // Act
        final url = provider.getIconUrl(extension);

        // Assert
        expect(
          url.value,
          contains('javascript'),
        );
      });

      test('should handle all programming language extensions', () {
        // Arrange
        final langExtensions = {
          'php': 'php',
          'rb': 'ruby',
          'swift': 'swift',
          'r': 'r',
          'lua': 'lua',
          'pl': 'perl',
          'scala': 'scala',
          'groovy': 'groovy',
          'erl': 'erlang',
          'hs': 'haskell',
          'clj': 'clojure',
          'fs': 'fsharp',
        };

        // Act & Assert
        for (final entry in langExtensions.entries) {
          final url = provider.getIconUrl(entry.key);
          expect(
            url.value,
            contains(entry.value),
            reason: '${entry.key} should map to ${entry.value}',
          );
        }
      });

      test('should handle database extensions', () {
        // Arrange
        final dbExtensions = {
          'sql': 'mysql',
          'mysql': 'mysql',
          'postgres': 'postgresql',
          'postgresql': 'postgresql',
          'mongo': 'mongodb',
          'mongodb': 'mongodb',
          'redis': 'redis',
        };

        // Act & Assert
        for (final entry in dbExtensions.entries) {
          final url = provider.getIconUrl(entry.key);
          expect(
            url.value,
            contains(entry.value),
            reason: '${entry.key} should map to ${entry.value}',
          );
        }
      });

      test('should handle nginx extension', () {
        // Arrange
        const extension = 'nginx';

        // Act
        final url = provider.getIconUrl(extension);

        // Assert
        expect(url.value, contains('nginx'));
      });

      test('should handle gradle extension', () {
        // Arrange
        const extension = 'gradle';

        // Act
        final url = provider.getIconUrl(extension);

        // Assert
        expect(url.value, contains('gradle'));
      });

      test('should handle lock files', () {
        // Arrange
        const extension = 'lock';

        // Act
        final url = provider.getIconUrl(extension);

        // Assert
        expect(url.value, contains('npm'));
      });

      test('should handle svg extension', () {
        // Arrange
        const extension = 'svg';

        // Act
        final url = provider.getIconUrl(extension);

        // Assert
        expect(url.value, contains('svg'));
      });

      test('should handle jsx extension', () {
        // Arrange
        const extension = 'jsx';

        // Act
        final url = provider.getIconUrl(extension);

        // Assert
        expect(url.value, contains('react'));
      });
    });

    group('iconExists', () {
      setUp(() {
        registerFallbackValue(Uri.parse('https://example.com'));
      });

      test('should return true when icon exists (HTTP 200)', () async {
        // Arrange
        const extension = 'dart';
        when(() => mockClient.head(any())).thenAnswer(
          (_) async => http.Response('', 200),
        );

        // Act
        final exists = await provider.iconExists(extension);

        // Assert
        expect(exists, true);
        verify(() => mockClient.head(any())).called(1);
      });

      test('should return false when icon does not exist (HTTP 404)', () async {
        // Arrange
        const extension = 'xyz';
        when(() => mockClient.head(any())).thenAnswer(
          (_) async => http.Response('', 404),
        );

        // Act
        final exists = await provider.iconExists(extension);

        // Assert
        expect(exists, false);
        verify(() => mockClient.head(any())).called(1);
      });

      test('should return false when HTTP request throws exception', () async {
        // Arrange
        const extension = 'dart';
        when(() => mockClient.head(any())).thenThrow(
          Exception('Network error'),
        );

        // Act
        final exists = await provider.iconExists(extension);

        // Assert
        expect(exists, false);
        verify(() => mockClient.head(any())).called(1);
      });

      test('should call correct URL when checking icon existence', () async {
        // Arrange
        const extension = 'dart';
        Uri? capturedUri;
        when(() => mockClient.head(any())).thenAnswer((invocation) async {
          capturedUri = invocation.positionalArguments[0] as Uri;
          return http.Response('', 200);
        });

        // Act
        await provider.iconExists(extension);

        // Assert
        expect(
          capturedUri?.toString(),
          'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/dart/dart-original.svg',
        );
      });

      test('should handle multiple existence checks', () async {
        // Arrange
        const extensions = ['dart', 'js', 'py'];
        when(() => mockClient.head(any())).thenAnswer(
          (_) async => http.Response('', 200),
        );

        // Act
        final results = <bool>[];
        for (final ext in extensions) {
          results.add(await provider.iconExists(ext));
        }

        // Assert
        expect(results, [true, true, true]);
        verify(() => mockClient.head(any())).called(3);
      });

      test('should return false for HTTP 500 error', () async {
        // Arrange
        const extension = 'dart';
        when(() => mockClient.head(any())).thenAnswer(
          (_) async => http.Response('', 500),
        );

        // Act
        final exists = await provider.iconExists(extension);

        // Assert
        expect(exists, false);
      });

      test('should return false for timeout exception', () async {
        // Arrange
        const extension = 'dart';
        when(() => mockClient.head(any())).thenThrow(
          TimeoutException('Request timeout'),
        );

        // Act
        final exists = await provider.iconExists(extension);

        // Assert
        expect(exists, false);
      });
    });

    group('dispose', () {
      test('should close HTTP client on dispose', () {
        // Arrange
        when(() => mockClient.close()).thenReturn(null);

        // Act
        provider.dispose();

        // Assert
        verify(() => mockClient.close()).called(1);
      });

      test('should not throw when dispose is called multiple times', () {
        // Arrange
        when(() => mockClient.close()).thenReturn(null);

        // Act & Assert
        expect(() {
          provider.dispose();
          provider.dispose();
        }, returnsNormally);
      });
    });

    group('integration tests', () {
      test('should handle complete workflow for known extension', () async {
        // Arrange
        const extension = 'dart';
        when(() => mockClient.head(any())).thenAnswer(
          (_) async => http.Response('', 200),
        );

        // Act
        final url = provider.getIconUrl(extension);
        final exists = await provider.iconExists(extension);

        // Assert
        expect(url.value, contains('dart'));
        expect(exists, true);
      });

      test('should handle complete workflow for unknown extension', () async {
        // Arrange
        const extension = 'unknownext';
        when(() => mockClient.head(any())).thenAnswer(
          (_) async => http.Response('', 404),
        );

        // Act
        final url = provider.getIconUrl(extension);
        final exists = await provider.iconExists(extension);

        // Assert
        expect(url.value, contains('file'));
        expect(exists, false);
      });

      test('should handle batch icon URL generation', () {
        // Arrange
        const extensions = ['dart', 'js', 'py', 'java', 'go'];

        // Act
        final urls = extensions.map((ext) => provider.getIconUrl(ext)).toList();

        // Assert
        expect(urls.length, 5);
        expect(urls[0].value, contains('dart'));
        expect(urls[1].value, contains('javascript'));
        expect(urls[2].value, contains('python'));
        expect(urls[3].value, contains('java'));
        expect(urls[4].value, contains('go'));
      });
    });

    group('edge cases', () {
      test('should handle empty string extension', () {
        // Arrange
        const extension = '';

        // Act
        final url = provider.getIconUrl(extension);

        // Assert
        expect(url.value, contains('file'));
      });

      test('should handle very long extension', () {
        // Arrange
        const extension = 'verylongextensionname';

        // Act
        final url = provider.getIconUrl(extension);

        // Assert
        expect(url.value, contains('file'));
      });

      test('should handle extension with special characters', () {
        // Arrange
        const extension = 'ext-name';

        // Act
        final url = provider.getIconUrl(extension);

        // Assert
        expect(url.value, isNotEmpty);
      });
    });
  });
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
}
