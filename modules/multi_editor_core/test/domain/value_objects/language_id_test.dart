import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_core/src/domain/value_objects/language_id.dart';
import 'package:multi_editor_core/src/domain/failures/domain_failure.dart';

void main() {
  group('LanguageId', () {
    group('create', () {
      test('should create valid language ID', () {
        // Arrange
        const input = 'dart';

        // Act
        final result = LanguageId.create(input);

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right.value, equals('dart'));
      });

      test('should normalize to lowercase', () {
        // Arrange
        const input = 'DaRt';

        // Act
        final result = LanguageId.create(input);

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right.value, equals('dart'));
      });

      test('should trim whitespace', () {
        // Arrange
        const input = '  javascript  ';

        // Act
        final result = LanguageId.create(input);

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right.value, equals('javascript'));
      });

      test('should default to plaintext for empty input', () {
        // Arrange
        const input = '';

        // Act
        final result = LanguageId.create(input);

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right.value, equals('plaintext'));
      });

      test('should default to plaintext for whitespace-only input', () {
        // Arrange
        const input = '   ';

        // Act
        final result = LanguageId.create(input);

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right.value, equals('plaintext'));
      });

      test('should reject unsupported language', () {
        // Arrange
        const input = 'cobol';

        // Act
        final result = LanguageId.create(input);

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left.field, equals('languageId'));
        expect(result.left.reason, contains('Unsupported language'));
      });

      test('should accept all supported languages', () {
        // Arrange
        const supportedLanguages = [
          'dart',
          'javascript',
          'typescript',
          'python',
          'rust',
          'go',
          'java',
          'kotlin',
          'swift',
          'c',
          'cpp',
          'csharp',
          'ruby',
          'php',
          'html',
          'css',
          'scss',
          'json',
          'yaml',
          'xml',
          'markdown',
          'plaintext',
        ];

        for (final lang in supportedLanguages) {
          // Act
          final result = LanguageId.create(lang);

          // Assert
          expect(result.isRight, isTrue, reason: '$lang should be supported');
          expect(result.right.value, equals(lang));
        }
      });
    });

    group('fromFileExtension', () {
      test('should detect Dart files', () {
        // Arrange & Act
        final languageId = LanguageId.fromFileExtension('dart');

        // Assert
        expect(languageId.value, equals('dart'));
      });

      test('should detect JavaScript files', () {
        // Arrange & Act
        final jsId = LanguageId.fromFileExtension('js');
        final mjsId = LanguageId.fromFileExtension('mjs');
        final cjsId = LanguageId.fromFileExtension('cjs');

        // Assert
        expect(jsId.value, equals('javascript'));
        expect(mjsId.value, equals('javascript'));
        expect(cjsId.value, equals('javascript'));
      });

      test('should detect TypeScript files', () {
        // Arrange & Act
        final tsId = LanguageId.fromFileExtension('ts');
        final tsxId = LanguageId.fromFileExtension('tsx');

        // Assert
        expect(tsId.value, equals('typescript'));
        expect(tsxId.value, equals('typescript'));
      });

      test('should detect Python files', () {
        // Arrange & Act
        final languageId = LanguageId.fromFileExtension('py');

        // Assert
        expect(languageId.value, equals('python'));
      });

      test('should detect Rust files', () {
        // Arrange & Act
        final languageId = LanguageId.fromFileExtension('rs');

        // Assert
        expect(languageId.value, equals('rust'));
      });

      test('should detect C/C++ files', () {
        // Arrange & Act
        final cId = LanguageId.fromFileExtension('c');
        final hId = LanguageId.fromFileExtension('h');
        final cppId = LanguageId.fromFileExtension('cpp');
        final ccId = LanguageId.fromFileExtension('cc');
        final cxxId = LanguageId.fromFileExtension('cxx');
        final hppId = LanguageId.fromFileExtension('hpp');

        // Assert
        expect(cId.value, equals('c'));
        expect(hId.value, equals('c'));
        expect(cppId.value, equals('cpp'));
        expect(ccId.value, equals('cpp'));
        expect(cxxId.value, equals('cpp'));
        expect(hppId.value, equals('cpp'));
      });

      test('should detect Kotlin files', () {
        // Arrange & Act
        final ktId = LanguageId.fromFileExtension('kt');
        final ktsId = LanguageId.fromFileExtension('kts');

        // Assert
        expect(ktId.value, equals('kotlin'));
        expect(ktsId.value, equals('kotlin'));
      });

      test('should detect markup files', () {
        // Arrange & Act
        final htmlId = LanguageId.fromFileExtension('html');
        final htmId = LanguageId.fromFileExtension('htm');
        final xmlId = LanguageId.fromFileExtension('xml');
        final mdId = LanguageId.fromFileExtension('md');

        // Assert
        expect(htmlId.value, equals('html'));
        expect(htmId.value, equals('html'));
        expect(xmlId.value, equals('xml'));
        expect(mdId.value, equals('markdown'));
      });

      test('should detect stylesheet files', () {
        // Arrange & Act
        final cssId = LanguageId.fromFileExtension('css');
        final scssId = LanguageId.fromFileExtension('scss');
        final sassId = LanguageId.fromFileExtension('sass');

        // Assert
        expect(cssId.value, equals('css'));
        expect(scssId.value, equals('scss'));
        expect(sassId.value, equals('scss'));
      });

      test('should detect config files', () {
        // Arrange & Act
        final jsonId = LanguageId.fromFileExtension('json');
        final yamlId = LanguageId.fromFileExtension('yaml');
        final ymlId = LanguageId.fromFileExtension('yml');

        // Assert
        expect(jsonId.value, equals('json'));
        expect(yamlId.value, equals('yaml'));
        expect(ymlId.value, equals('yaml'));
      });

      test('should default to plaintext for unknown extension', () {
        // Arrange & Act
        final languageId = LanguageId.fromFileExtension('xyz');

        // Assert
        expect(languageId.value, equals('plaintext'));
      });

      test('should normalize extension case', () {
        // Arrange & Act
        final languageId = LanguageId.fromFileExtension('DART');

        // Assert
        expect(languageId.value, equals('dart'));
      });

      test('should trim extension whitespace', () {
        // Arrange & Act
        final languageId = LanguageId.fromFileExtension('  js  ');

        // Assert
        expect(languageId.value, equals('javascript'));
      });
    });

    group('plaintext', () {
      test('should create plaintext language ID', () {
        // Arrange & Act
        final languageId = LanguageId.plaintext;

        // Assert
        expect(languageId.value, equals('plaintext'));
      });
    });

    group('isSupported', () {
      test('should detect supported language', () {
        // Arrange
        final languageId = LanguageId.create('dart').right;

        // Act & Assert
        expect(languageId.isSupported, isTrue);
      });

      test('should detect plaintext as supported', () {
        // Arrange
        final languageId = LanguageId.plaintext;

        // Act & Assert
        expect(languageId.isSupported, isTrue);
      });
    });

    group('displayName', () {
      test('should capitalize first letter', () {
        // Arrange
        final languageId = LanguageId.create('dart').right;

        // Act
        final displayName = languageId.displayName;

        // Assert
        expect(displayName, equals('Dart'));
      });

      test('should handle uppercase language ID', () {
        // Arrange
        final languageId = LanguageId.create('PYTHON').right;

        // Act
        final displayName = languageId.displayName;

        // Assert
        expect(displayName, equals('Python'));
      });

      test('should capitalize plaintext', () {
        // Arrange
        final languageId = LanguageId.plaintext;

        // Act
        final displayName = languageId.displayName;

        // Assert
        expect(displayName, equals('Plaintext'));
      });
    });

    group('equality', () {
      test('should be equal with same language', () {
        // Arrange
        final lang1 = LanguageId.create('dart').right;
        final lang2 = LanguageId.create('dart').right;

        // Act & Assert
        expect(lang1, equals(lang2));
        expect(lang1.hashCode, equals(lang2.hashCode));
      });

      test('should be equal regardless of case', () {
        // Arrange
        final lang1 = LanguageId.create('dart').right;
        final lang2 = LanguageId.create('DART').right;

        // Act & Assert
        expect(lang1, equals(lang2));
      });

      test('should not be equal with different languages', () {
        // Arrange
        final lang1 = LanguageId.create('dart').right;
        final lang2 = LanguageId.create('javascript').right;

        // Act & Assert
        expect(lang1, isNot(equals(lang2)));
      });
    });

    group('toString', () {
      test('should return string value', () {
        // Arrange
        final languageId = LanguageId.create('dart').right;

        // Act & Assert
        expect(languageId.toString(), equals('dart'));
      });
    });

    group('use cases', () {
      test('should detect language from file extension', () {
        // Arrange
        const testCases = {
          'main.dart': 'dart',
          'app.js': 'javascript',
          'component.tsx': 'typescript',
          'script.py': 'python',
          'main.rs': 'rust',
          'README.md': 'markdown',
          'config.json': 'json',
          'docker-compose.yml': 'yaml',
          'index.html': 'html',
          'styles.scss': 'scss',
          'unknown.xyz': 'plaintext',
        };

        for (final entry in testCases.entries) {
          // Act
          final fileName = entry.key;
          final extension = fileName.split('.').last;
          final languageId = LanguageId.fromFileExtension(extension);

          // Assert
          expect(languageId.value, equals(entry.value),
              reason: '$fileName should be detected as ${entry.value}');
        }
      });

      test('should handle typical development workflow', () {
        // Arrange
        final dartFile = LanguageId.fromFileExtension('dart');
        final testFile = LanguageId.fromFileExtension('dart');
        final readmeFile = LanguageId.fromFileExtension('md');

        // Assert
        expect(dartFile, equals(testFile));
        expect(dartFile, isNot(equals(readmeFile)));
        expect(dartFile.displayName, equals('Dart'));
        expect(readmeFile.displayName, equals('Markdown'));
      });
    });
  });
}

extension on Either<DomainFailure, LanguageId> {
  bool get isLeft => fold((_) => true, (_) => false);
  bool get isRight => fold((_) => false, (_) => true);
  DomainFailure get left => fold((l) => l, (_) => throw StateError('Right'));
  LanguageId get right => fold((_) => throw StateError('Left'), (r) => r);
}
