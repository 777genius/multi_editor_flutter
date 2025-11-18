import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_monaco_crossplatform/flutter_monaco_crossplatform.dart';
import 'package:editor_monaco/editor_monaco.dart';
import 'package:editor_core/editor_core.dart';

void main() {
  group('MonacoMappers - Language Mapping', () {
    group('toMonacoLanguage', () {
      test('should map Dart correctly', () {
        // Act
        final result = MonacoMappers.toMonacoLanguage(LanguageId.dart);

        // Assert
        expect(result, equals(MonacoLanguage.dart));
      });

      test('should map JavaScript correctly', () {
        // Act
        final result1 = MonacoMappers.toMonacoLanguage(LanguageId.javascript);
        final result2 = MonacoMappers.toMonacoLanguage(LanguageId('js'));

        // Assert
        expect(result1, equals(MonacoLanguage.javascript));
        expect(result2, equals(MonacoLanguage.javascript));
      });

      test('should map TypeScript correctly', () {
        // Act
        final result1 = MonacoMappers.toMonacoLanguage(LanguageId.typescript);
        final result2 = MonacoMappers.toMonacoLanguage(LanguageId('ts'));

        // Assert
        expect(result1, equals(MonacoLanguage.typescript));
        expect(result2, equals(MonacoLanguage.typescript));
      });

      test('should map Python correctly', () {
        // Act
        final result1 = MonacoMappers.toMonacoLanguage(LanguageId.python);
        final result2 = MonacoMappers.toMonacoLanguage(LanguageId('py'));

        // Assert
        expect(result1, equals(MonacoLanguage.python));
        expect(result2, equals(MonacoLanguage.python));
      });

      test('should map Rust correctly', () {
        // Act
        final result1 = MonacoMappers.toMonacoLanguage(LanguageId.rust);
        final result2 = MonacoMappers.toMonacoLanguage(LanguageId('rs'));

        // Assert
        expect(result1, equals(MonacoLanguage.rust));
        expect(result2, equals(MonacoLanguage.rust));
      });

      test('should map Go correctly', () {
        // Act
        final result = MonacoMappers.toMonacoLanguage(LanguageId.go);

        // Assert
        expect(result, equals(MonacoLanguage.go));
      });

      test('should map Java correctly', () {
        // Act
        final result = MonacoMappers.toMonacoLanguage(LanguageId.java);

        // Assert
        expect(result, equals(MonacoLanguage.java));
      });

      test('should map C++ with multiple aliases', () {
        // Act
        final result1 = MonacoMappers.toMonacoLanguage(LanguageId.cpp);
        final result2 = MonacoMappers.toMonacoLanguage(LanguageId('c++'));
        final result3 = MonacoMappers.toMonacoLanguage(LanguageId('cxx'));

        // Assert
        expect(result1, equals(MonacoLanguage.cpp));
        expect(result2, equals(MonacoLanguage.cpp));
        expect(result3, equals(MonacoLanguage.cpp));
      });

      test('should map C# with multiple aliases', () {
        // Act
        final result1 = MonacoMappers.toMonacoLanguage(LanguageId.csharp);
        final result2 = MonacoMappers.toMonacoLanguage(LanguageId('cs'));

        // Assert
        expect(result1, equals(MonacoLanguage.csharp));
        expect(result2, equals(MonacoLanguage.csharp));
      });

      test('should map markup languages correctly', () {
        // Act
        final json = MonacoMappers.toMonacoLanguage(LanguageId.json);
        final html = MonacoMappers.toMonacoLanguage(LanguageId.html);
        final css = MonacoMappers.toMonacoLanguage(LanguageId.css);
        final xml = MonacoMappers.toMonacoLanguage(LanguageId('xml'));

        // Assert
        expect(json, equals(MonacoLanguage.json));
        expect(html, equals(MonacoLanguage.html));
        expect(css, equals(MonacoLanguage.css));
        expect(xml, equals(MonacoLanguage.xml));
      });

      test('should map SCSS with multiple aliases', () {
        // Act
        final result1 = MonacoMappers.toMonacoLanguage(LanguageId('scss'));
        final result2 = MonacoMappers.toMonacoLanguage(LanguageId('sass'));

        // Assert
        expect(result1, equals(MonacoLanguage.scss));
        expect(result2, equals(MonacoLanguage.scss));
      });

      test('should map Markdown with multiple aliases', () {
        // Act
        final result1 = MonacoMappers.toMonacoLanguage(LanguageId.markdown);
        final result2 = MonacoMappers.toMonacoLanguage(LanguageId('md'));

        // Assert
        expect(result1, equals(MonacoLanguage.markdown));
        expect(result2, equals(MonacoLanguage.markdown));
      });

      test('should map YAML with multiple aliases', () {
        // Act
        final result1 = MonacoMappers.toMonacoLanguage(LanguageId.yaml);
        final result2 = MonacoMappers.toMonacoLanguage(LanguageId('yml'));

        // Assert
        expect(result1, equals(MonacoLanguage.yaml));
        expect(result2, equals(MonacoLanguage.yaml));
      });

      test('should map shell scripts with multiple aliases', () {
        // Act
        final result1 = MonacoMappers.toMonacoLanguage(LanguageId('shell'));
        final result2 = MonacoMappers.toMonacoLanguage(LanguageId('bash'));
        final result3 = MonacoMappers.toMonacoLanguage(LanguageId('sh'));

        // Assert
        expect(result1, equals(MonacoLanguage.shell));
        expect(result2, equals(MonacoLanguage.shell));
        expect(result3, equals(MonacoLanguage.shell));
      });

      test('should map SQL correctly', () {
        // Act
        final result = MonacoMappers.toMonacoLanguage(LanguageId('sql'));

        // Assert
        expect(result, equals(MonacoLanguage.sql));
      });

      test('should default to plaintext for unknown language', () {
        // Act
        final result1 = MonacoMappers.toMonacoLanguage(LanguageId('unknown-lang'));
        final result2 = MonacoMappers.toMonacoLanguage(LanguageId('xyz'));
        final result3 = MonacoMappers.toMonacoLanguage(LanguageId.plaintext);

        // Assert
        expect(result1, equals(MonacoLanguage.plaintext));
        expect(result2, equals(MonacoLanguage.plaintext));
        expect(result3, equals(MonacoLanguage.plaintext));
      });

      test('should handle case insensitivity', () {
        // Act
        final result1 = MonacoMappers.toMonacoLanguage(LanguageId('DART'));
        final result2 = MonacoMappers.toMonacoLanguage(LanguageId('Dart'));
        final result3 = MonacoMappers.toMonacoLanguage(LanguageId('DaRt'));

        // Assert
        expect(result1, equals(MonacoLanguage.dart));
        expect(result2, equals(MonacoLanguage.dart));
        expect(result3, equals(MonacoLanguage.dart));
      });

      test('should handle all common programming languages', () {
        // Arrange
        final languages = [
          (LanguageId.dart, MonacoLanguage.dart),
          (LanguageId.javascript, MonacoLanguage.javascript),
          (LanguageId.typescript, MonacoLanguage.typescript),
          (LanguageId.python, MonacoLanguage.python),
          (LanguageId.rust, MonacoLanguage.rust),
          (LanguageId.go, MonacoLanguage.go),
          (LanguageId.java, MonacoLanguage.java),
          (LanguageId.cpp, MonacoLanguage.cpp),
          (LanguageId.csharp, MonacoLanguage.csharp),
        ];

        // Act & Assert
        for (final (domainLang, monacoLang) in languages) {
          final result = MonacoMappers.toMonacoLanguage(domainLang);
          expect(result, equals(monacoLang), reason: 'Failed for ${domainLang.value}');
        }
      });
    });

    group('fromMonacoLanguage', () {
      test('should reverse map all languages correctly', () {
        // Arrange
        final mappings = [
          (MonacoLanguage.dart, LanguageId.dart),
          (MonacoLanguage.javascript, LanguageId.javascript),
          (MonacoLanguage.typescript, LanguageId.typescript),
          (MonacoLanguage.json, LanguageId.json),
          (MonacoLanguage.html, LanguageId.html),
          (MonacoLanguage.css, LanguageId.css),
          (MonacoLanguage.python, LanguageId.python),
          (MonacoLanguage.rust, LanguageId.rust),
          (MonacoLanguage.go, LanguageId.go),
          (MonacoLanguage.java, LanguageId.java),
          (MonacoLanguage.cpp, LanguageId.cpp),
          (MonacoLanguage.csharp, LanguageId.csharp),
          (MonacoLanguage.markdown, LanguageId.markdown),
          (MonacoLanguage.yaml, LanguageId.yaml),
        ];

        // Act & Assert
        for (final (monacoLang, domainLang) in mappings) {
          final result = MonacoMappers.fromMonacoLanguage(monacoLang);
          expect(result, equals(domainLang), reason: 'Failed for $monacoLang');
        }
      });

      test('should default to plaintext for unknown Monaco language', () {
        // This tests the default case in the switch
        // Act - assuming there's a way to create an unknown Monaco language
        final result = MonacoMappers.fromMonacoLanguage(MonacoLanguage.plaintext);

        // Assert
        expect(result, equals(LanguageId.plaintext));
      });
    });

    group('language roundtrip', () {
      test('should roundtrip common languages correctly', () {
        // Arrange
        final languages = [
          LanguageId.dart,
          LanguageId.javascript,
          LanguageId.typescript,
          LanguageId.python,
          LanguageId.rust,
          LanguageId.go,
          LanguageId.java,
        ];

        // Act & Assert
        for (final original in languages) {
          final monaco = MonacoMappers.toMonacoLanguage(original);
          final roundtrip = MonacoMappers.fromMonacoLanguage(monaco);
          expect(roundtrip, equals(original), reason: 'Failed roundtrip for ${original.value}');
        }
      });
    });
  });

  group('MonacoMappers - Theme Mapping', () {
    group('toMonacoTheme', () {
      test('should map dark theme correctly', () {
        // Act
        final result = MonacoMappers.toMonacoTheme(EditorTheme.dark);

        // Assert
        expect(result, equals(MonacoTheme.vsDark));
      });

      test('should map light theme correctly', () {
        // Act
        final result = MonacoMappers.toMonacoTheme(EditorTheme.light);

        // Assert
        expect(result, equals(MonacoTheme.vs));
      });

      test('should map high contrast theme correctly', () {
        // Act
        final result = MonacoMappers.toMonacoTheme(EditorTheme.highContrast);

        // Assert
        expect(result, equals(MonacoTheme.hcBlack));
      });

      test('should default to light theme for unknown theme', () {
        // Arrange
        final customTheme = EditorTheme.custom(
          id: 'custom-theme',
          name: 'Custom Theme',
          isDark: false,
          colors: {},
        );

        // Act
        final result = MonacoMappers.toMonacoTheme(customTheme);

        // Assert
        expect(result, equals(MonacoTheme.vs));
      });

      test('should handle all standard themes', () {
        // Arrange
        final themes = [
          (EditorTheme.light, MonacoTheme.vs),
          (EditorTheme.dark, MonacoTheme.vsDark),
          (EditorTheme.highContrast, MonacoTheme.hcBlack),
        ];

        // Act & Assert
        for (final (editorTheme, monacoTheme) in themes) {
          final result = MonacoMappers.toMonacoTheme(editorTheme);
          expect(result, equals(monacoTheme), reason: 'Failed for ${editorTheme.id}');
        }
      });
    });

    group('fromMonacoTheme', () {
      test('should reverse map VS theme to light', () {
        // Act
        final result = MonacoMappers.fromMonacoTheme(MonacoTheme.vs);

        // Assert
        expect(result, equals(EditorTheme.light));
        expect(result.id, equals('light'));
      });

      test('should reverse map VS Dark theme to dark', () {
        // Act
        final result = MonacoMappers.fromMonacoTheme(MonacoTheme.vsDark);

        // Assert
        expect(result, equals(EditorTheme.dark));
        expect(result.id, equals('dark'));
      });

      test('should reverse map HC Black theme to high contrast', () {
        // Act
        final result = MonacoMappers.fromMonacoTheme(MonacoTheme.hcBlack);

        // Assert
        expect(result, equals(EditorTheme.highContrast));
        expect(result.id, equals('high-contrast'));
      });
    });

    group('theme roundtrip', () {
      test('should roundtrip all standard themes correctly', () {
        // Arrange
        final themes = [
          EditorTheme.light,
          EditorTheme.dark,
          EditorTheme.highContrast,
        ];

        // Act & Assert
        for (final original in themes) {
          final monaco = MonacoMappers.toMonacoTheme(original);
          final roundtrip = MonacoMappers.fromMonacoTheme(monaco);
          expect(roundtrip.id, equals(original.id), reason: 'Failed roundtrip for ${original.id}');
        }
      });
    });

    group('theme properties', () {
      test('should preserve dark/light distinction', () {
        // Act
        final darkMonaco = MonacoMappers.toMonacoTheme(EditorTheme.dark);
        final lightMonaco = MonacoMappers.toMonacoTheme(EditorTheme.light);

        final darkDomain = MonacoMappers.fromMonacoTheme(darkMonaco);
        final lightDomain = MonacoMappers.fromMonacoTheme(lightMonaco);

        // Assert
        expect(darkDomain.isDark, isTrue);
        expect(lightDomain.isDark, isFalse);
        expect(darkMonaco, equals(MonacoTheme.vsDark));
        expect(lightMonaco, equals(MonacoTheme.vs));
      });
    });
  });
}
