import 'package:flutter_test/flutter_test.dart';
import 'package:editor_core/editor_core.dart';

void main() {
  group('LanguageId', () {
    group('creation', () {
      test('should create with value', () {
        // Act
        const languageId = LanguageId('dart');

        // Assert
        expect(languageId.value, equals('dart'));
      });
    });

    group('predefined language IDs', () {
      test('should have dart', () {
        expect(LanguageId.dart.value, equals('dart'));
      });

      test('should have javascript', () {
        expect(LanguageId.javascript.value, equals('javascript'));
      });

      test('should have typescript', () {
        expect(LanguageId.typescript.value, equals('typescript'));
      });

      test('should have python', () {
        expect(LanguageId.python.value, equals('python'));
      });

      test('should have rust', () {
        expect(LanguageId.rust.value, equals('rust'));
      });

      test('should have multiple languages', () {
        final languages = [
          LanguageId.dart,
          LanguageId.javascript,
          LanguageId.typescript,
          LanguageId.python,
          LanguageId.rust,
          LanguageId.go,
          LanguageId.java,
        ];

        expect(languages.length, equals(7));
      });
    });

    group('fromFileExtension', () {
      test('should detect dart from .dart', () {
        final languageId = LanguageId.fromFileExtension('.dart');

        expect(languageId, equals(LanguageId.dart));
      });

      test('should detect dart without dot', () {
        final languageId = LanguageId.fromFileExtension('dart');

        expect(languageId, equals(LanguageId.dart));
      });

      test('should detect javascript from .js', () {
        final languageId = LanguageId.fromFileExtension('.js');

        expect(languageId, equals(LanguageId.javascript));
      });

      test('should detect typescript from .ts', () {
        final languageId = LanguageId.fromFileExtension('.ts');

        expect(languageId, equals(LanguageId.typescript));
      });

      test('should detect python from .py', () {
        final languageId = LanguageId.fromFileExtension('.py');

        expect(languageId, equals(LanguageId.python));
      });

      test('should detect rust from .rs', () {
        final languageId = LanguageId.fromFileExtension('.rs');

        expect(languageId, equals(LanguageId.rust));
      });

      test('should detect yaml from .yaml', () {
        final languageId = LanguageId.fromFileExtension('.yaml');

        expect(languageId, equals(LanguageId.yaml));
      });

      test('should detect yaml from .yml', () {
        final languageId = LanguageId.fromFileExtension('.yml');

        expect(languageId, equals(LanguageId.yaml));
      });

      test('should detect markdown from .md', () {
        final languageId = LanguageId.fromFileExtension('.md');

        expect(languageId, equals(LanguageId.markdown));
      });

      test('should detect json from .json', () {
        final languageId = LanguageId.fromFileExtension('.json');

        expect(languageId, equals(LanguageId.json));
      });

      test('should detect cpp from .cpp', () {
        final languageId = LanguageId.fromFileExtension('.cpp');

        expect(languageId, equals(LanguageId.cpp));
      });

      test('should detect cpp from .h', () {
        final languageId = LanguageId.fromFileExtension('.h');

        expect(languageId, equals(LanguageId.cpp));
      });

      test('should handle case insensitive', () {
        final languageId1 = LanguageId.fromFileExtension('.DART');
        final languageId2 = LanguageId.fromFileExtension('.Dart');
        final languageId3 = LanguageId.fromFileExtension('.dart');

        expect(languageId1, equals(LanguageId.dart));
        expect(languageId2, equals(LanguageId.dart));
        expect(languageId3, equals(LanguageId.dart));
      });

      test('should return plaintext for unknown extension', () {
        final languageId = LanguageId.fromFileExtension('.unknown');

        expect(languageId, equals(LanguageId.plaintext));
      });
    });

    group('fromFileName', () {
      test('should detect from full file name', () {
        final languageId = LanguageId.fromFileName('main.dart');

        expect(languageId, equals(LanguageId.dart));
      });

      test('should detect from path', () {
        final languageId = LanguageId.fromFileName('lib/main.dart');

        expect(languageId, equals(LanguageId.dart));
      });

      test('should handle file without extension', () {
        final languageId = LanguageId.fromFileName('README');

        expect(languageId, equals(LanguageId.plaintext));
      });

      test('should handle complex paths', () {
        final languageId = LanguageId.fromFileName('/path/to/file.js');

        expect(languageId, equals(LanguageId.javascript));
      });

      test('should handle multiple dots', () {
        final languageId = LanguageId.fromFileName('app.config.json');

        expect(languageId, equals(LanguageId.json));
      });
    });

    group('equality', () {
      test('should be equal with same value', () {
        const lang1 = LanguageId('dart');
        const lang2 = LanguageId('dart');

        expect(lang1, equals(lang2));
        expect(lang1.hashCode, equals(lang2.hashCode));
      });

      test('should not be equal with different values', () {
        const lang1 = LanguageId('dart');
        const lang2 = LanguageId('rust');

        expect(lang1, isNot(equals(lang2)));
      });

      test('should use predefined constants', () {
        final lang1 = LanguageId.dart;
        final lang2 = LanguageId.dart;

        expect(lang1, equals(lang2));
      });
    });

    group('multiple file extensions', () {
      test('should detect javascript from jsx', () {
        final languageId = LanguageId.fromFileExtension('.jsx');

        expect(languageId, equals(LanguageId.javascript));
      });

      test('should detect typescript from tsx', () {
        final languageId = LanguageId.fromFileExtension('.tsx');

        expect(languageId, equals(LanguageId.typescript));
      });

      test('should detect kotlin from kt', () {
        final languageId = LanguageId.fromFileExtension('.kt');

        expect(languageId, equals(LanguageId.kotlin));
      });

      test('should detect shellscript from bash', () {
        final languageId = LanguageId.fromFileExtension('.bash');

        expect(languageId, equals(LanguageId.shellscript));
      });

      test('should detect html from htm', () {
        final languageId = LanguageId.fromFileExtension('.htm');

        expect(languageId, equals(LanguageId.html));
      });

      test('should detect scss from sass', () {
        final languageId = LanguageId.fromFileExtension('.sass');

        expect(languageId, equals(LanguageId.scss));
      });
    });
  });
}
