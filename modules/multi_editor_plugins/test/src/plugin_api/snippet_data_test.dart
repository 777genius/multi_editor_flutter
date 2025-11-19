import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugins/src/plugin_api/snippet_data.dart';

void main() {
  group('SnippetData', () {
    group('constructor', () {
      test('should create instance with all required fields', () {
        // Arrange & Act
        const snippet = SnippetData(
          prefix: 'if',
          label: 'if statement',
          body: 'if (\${1:condition}) {\n  \${2:// code}\n}',
          description: 'If statement',
        );

        // Assert
        expect(snippet.prefix, 'if');
        expect(snippet.label, 'if statement');
        expect(snippet.body, 'if (\${1:condition}) {\n  \${2:// code}\n}');
        expect(snippet.description, 'If statement');
      });

      test('should create instance with complex snippet body', () {
        // Arrange & Act
        const snippet = SnippetData(
          prefix: 'stless',
          label: 'Stateless Widget',
          body: 'class \${1:WidgetName} extends StatelessWidget {\n'
              '  const \${1:WidgetName}({Key? key}) : super(key: key);\n\n'
              '  @override\n'
              '  Widget build(BuildContext context) {\n'
              '    return \${2:Container}();\n'
              '  }\n'
              '}\$0',
          description: 'Create a Stateless Widget',
        );

        // Assert
        expect(snippet.prefix, 'stless');
        expect(snippet.label, 'Stateless Widget');
        expect(snippet.body, contains('extends StatelessWidget'));
        expect(snippet.body, contains('\${1:WidgetName}'));
        expect(snippet.body, contains('\${2:Container}'));
        expect(snippet.body, contains('\$0'));
        expect(snippet.description, 'Create a Stateless Widget');
      });

      test('should handle empty strings in fields', () {
        // Arrange & Act
        const snippet = SnippetData(
          prefix: '',
          label: '',
          body: '',
          description: '',
        );

        // Assert
        expect(snippet.prefix, '');
        expect(snippet.label, '');
        expect(snippet.body, '');
        expect(snippet.description, '');
      });

      test('should handle special characters in snippet body', () {
        // Arrange & Act
        const snippet = SnippetData(
          prefix: 'func',
          label: 'function',
          body: r'function ${1:name}(${2:params}) { ${3:// code} }',
          description: 'JavaScript function',
        );

        // Assert
        expect(snippet.body, contains(r'${1:name}'));
        expect(snippet.body, contains(r'${2:params}'));
        expect(snippet.body, contains(r'${3:// code}'));
      });
    });

    group('equality', () {
      test('should be equal when all fields are the same', () {
        // Arrange
        const snippet1 = SnippetData(
          prefix: 'if',
          label: 'if statement',
          body: 'if (\${1:condition}) {}',
          description: 'If statement',
        );
        const snippet2 = SnippetData(
          prefix: 'if',
          label: 'if statement',
          body: 'if (\${1:condition}) {}',
          description: 'If statement',
        );

        // Act & Assert
        expect(snippet1, equals(snippet2));
        expect(snippet1.hashCode, equals(snippet2.hashCode));
      });

      test('should not be equal when prefix differs', () {
        // Arrange
        const snippet1 = SnippetData(
          prefix: 'if',
          label: 'if statement',
          body: 'if (\${1:condition}) {}',
          description: 'If statement',
        );
        const snippet2 = SnippetData(
          prefix: 'iff',
          label: 'if statement',
          body: 'if (\${1:condition}) {}',
          description: 'If statement',
        );

        // Act & Assert
        expect(snippet1, isNot(equals(snippet2)));
      });

      test('should not be equal when label differs', () {
        // Arrange
        const snippet1 = SnippetData(
          prefix: 'if',
          label: 'if statement',
          body: 'if (\${1:condition}) {}',
          description: 'If statement',
        );
        const snippet2 = SnippetData(
          prefix: 'if',
          label: 'if condition',
          body: 'if (\${1:condition}) {}',
          description: 'If statement',
        );

        // Act & Assert
        expect(snippet1, isNot(equals(snippet2)));
      });

      test('should not be equal when body differs', () {
        // Arrange
        const snippet1 = SnippetData(
          prefix: 'if',
          label: 'if statement',
          body: 'if (\${1:condition}) {}',
          description: 'If statement',
        );
        const snippet2 = SnippetData(
          prefix: 'if',
          label: 'if statement',
          body: 'if (\${1:condition}) {\n  \${2}\n}',
          description: 'If statement',
        );

        // Act & Assert
        expect(snippet1, isNot(equals(snippet2)));
      });

      test('should not be equal when description differs', () {
        // Arrange
        const snippet1 = SnippetData(
          prefix: 'if',
          label: 'if statement',
          body: 'if (\${1:condition}) {}',
          description: 'If statement',
        );
        const snippet2 = SnippetData(
          prefix: 'if',
          label: 'if statement',
          body: 'if (\${1:condition}) {}',
          description: 'Conditional statement',
        );

        // Act & Assert
        expect(snippet1, isNot(equals(snippet2)));
      });
    });

    group('copyWith', () {
      test('should copy with new prefix', () {
        // Arrange
        const original = SnippetData(
          prefix: 'if',
          label: 'if statement',
          body: 'if (\${1:condition}) {}',
          description: 'If statement',
        );

        // Act
        final copied = original.copyWith(prefix: 'iff');

        // Assert
        expect(copied.prefix, 'iff');
        expect(copied.label, original.label);
        expect(copied.body, original.body);
        expect(copied.description, original.description);
      });

      test('should copy with new label', () {
        // Arrange
        const original = SnippetData(
          prefix: 'if',
          label: 'if statement',
          body: 'if (\${1:condition}) {}',
          description: 'If statement',
        );

        // Act
        final copied = original.copyWith(label: 'if condition');

        // Assert
        expect(copied.prefix, original.prefix);
        expect(copied.label, 'if condition');
        expect(copied.body, original.body);
        expect(copied.description, original.description);
      });

      test('should copy with new body', () {
        // Arrange
        const original = SnippetData(
          prefix: 'if',
          label: 'if statement',
          body: 'if (\${1:condition}) {}',
          description: 'If statement',
        );

        // Act
        final copied = original.copyWith(
          body: 'if (\${1:condition}) {\n  \${2}\n}',
        );

        // Assert
        expect(copied.prefix, original.prefix);
        expect(copied.label, original.label);
        expect(copied.body, 'if (\${1:condition}) {\n  \${2}\n}');
        expect(copied.description, original.description);
      });

      test('should copy with new description', () {
        // Arrange
        const original = SnippetData(
          prefix: 'if',
          label: 'if statement',
          body: 'if (\${1:condition}) {}',
          description: 'If statement',
        );

        // Act
        final copied = original.copyWith(description: 'Conditional statement');

        // Assert
        expect(copied.prefix, original.prefix);
        expect(copied.label, original.label);
        expect(copied.body, original.body);
        expect(copied.description, 'Conditional statement');
      });

      test('should copy with multiple fields', () {
        // Arrange
        const original = SnippetData(
          prefix: 'if',
          label: 'if statement',
          body: 'if (\${1:condition}) {}',
          description: 'If statement',
        );

        // Act
        final copied = original.copyWith(
          prefix: 'iff',
          label: 'if condition',
          body: 'if (\${1:test}) {\n  \${2:code}\n}',
          description: 'Conditional',
        );

        // Assert
        expect(copied.prefix, 'iff');
        expect(copied.label, 'if condition');
        expect(copied.body, 'if (\${1:test}) {\n  \${2:code}\n}');
        expect(copied.description, 'Conditional');
      });

      test('should return same instance when no changes', () {
        // Arrange
        const original = SnippetData(
          prefix: 'if',
          label: 'if statement',
          body: 'if (\${1:condition}) {}',
          description: 'If statement',
        );

        // Act
        final copied = original.copyWith();

        // Assert
        expect(copied, equals(original));
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON', () {
        // Arrange
        const snippet = SnippetData(
          prefix: 'if',
          label: 'if statement',
          body: 'if (\${1:condition}) {}',
          description: 'If statement',
        );

        // Act
        final json = snippet.toJson();

        // Assert
        expect(json, {
          'prefix': 'if',
          'label': 'if statement',
          'body': 'if (\${1:condition}) {}',
          'description': 'If statement',
        });
      });

      test('should deserialize from JSON', () {
        // Arrange
        final json = {
          'prefix': 'for',
          'label': 'for loop',
          'body': 'for (int i = 0; i < \${1:length}; i++) {\n  \${2}\n}',
          'description': 'For loop',
        };

        // Act
        final snippet = SnippetData.fromJson(json);

        // Assert
        expect(snippet.prefix, 'for');
        expect(snippet.label, 'for loop');
        expect(snippet.body, 'for (int i = 0; i < \${1:length}; i++) {\n  \${2}\n}');
        expect(snippet.description, 'For loop');
      });

      test('should round-trip through JSON', () {
        // Arrange
        const original = SnippetData(
          prefix: 'class',
          label: 'class declaration',
          body: 'class \${1:ClassName} {\n  \${2}\n}',
          description: 'Class declaration',
        );

        // Act
        final json = original.toJson();
        final deserialized = SnippetData.fromJson(json);

        // Assert
        expect(deserialized, equals(original));
      });

      test('should handle complex snippet bodies in JSON', () {
        // Arrange
        const snippet = SnippetData(
          prefix: 'stful',
          label: 'Stateful Widget',
          body: 'class \${1:WidgetName} extends StatefulWidget {\n'
              '  const \${1:WidgetName}({Key? key}) : super(key: key);\n\n'
              '  @override\n'
              '  State<\${1:WidgetName}> createState() => _\${1:WidgetName}State();\n'
              '}\n\n'
              'class _\${1:WidgetName}State extends State<\${1:WidgetName}> {\n'
              '  @override\n'
              '  Widget build(BuildContext context) {\n'
              '    return \${2:Container}();\n'
              '  }\n'
              '}\$0',
          description: 'Create a Stateful Widget',
        );

        // Act
        final json = snippet.toJson();
        final deserialized = SnippetData.fromJson(json);

        // Assert
        expect(deserialized, equals(snippet));
        expect(deserialized.body, contains('StatefulWidget'));
        expect(deserialized.body, contains('createState'));
      });

      test('should handle empty strings in JSON', () {
        // Arrange
        const snippet = SnippetData(
          prefix: '',
          label: '',
          body: '',
          description: '',
        );

        // Act
        final json = snippet.toJson();
        final deserialized = SnippetData.fromJson(json);

        // Assert
        expect(deserialized, equals(snippet));
        expect(deserialized.prefix, '');
        expect(deserialized.label, '');
        expect(deserialized.body, '');
        expect(deserialized.description, '');
      });
    });

    group('edge cases', () {
      test('should handle very long snippet bodies', () {
        // Arrange
        final longBody = 'if (\${1:condition}) {\n' * 100;
        final snippet = SnippetData(
          prefix: 'long',
          label: 'long snippet',
          body: longBody,
          description: 'Very long snippet',
        );

        // Act & Assert
        expect(snippet.body, longBody);
        expect(snippet.body.length, greaterThan(1000));
      });

      test('should handle unicode characters', () {
        // Arrange
        const snippet = SnippetData(
          prefix: 'emoji',
          label: 'Emoji snippet 😀',
          body: 'const text = "\${1:Hello 世界}";',
          description: 'Unicode test 你好',
        );

        // Act & Assert
        expect(snippet.label, contains('😀'));
        expect(snippet.body, contains('世界'));
        expect(snippet.description, contains('你好'));
      });

      test('should handle newlines and tabs', () {
        // Arrange
        const snippet = SnippetData(
          prefix: 'multi',
          label: 'multiline',
          body: 'line1\nline2\n\tindented\n\t\tdouble indent',
          description: 'Test\nnewlines',
        );

        // Act & Assert
        expect(snippet.body, contains('\n'));
        expect(snippet.body, contains('\t'));
        expect(snippet.description, contains('\n'));
      });

      test('should handle special regex characters', () {
        // Arrange
        const snippet = SnippetData(
          prefix: 'regex',
          label: 'regex test',
          body: r'final pattern = RegExp(r"\${1:.*}");',
          description: 'Pattern with . * + ?',
        );

        // Act & Assert
        expect(snippet.body, contains(r'.*'));
        expect(snippet.description, contains('. * + ?'));
      });

      test('should handle JSON special characters', () {
        // Arrange
        const snippet = SnippetData(
          prefix: 'json',
          label: 'JSON "quotes"',
          body: r'''{"key": "${1:value}", "other": "\n\t"}''',
          description: 'Test "quotes" and \\backslashes\\',
        );

        // Act
        final json = snippet.toJson();
        final deserialized = SnippetData.fromJson(json);

        // Assert
        expect(deserialized, equals(snippet));
        expect(deserialized.label, contains('"quotes"'));
        expect(deserialized.description, contains('\\backslashes\\'));
      });
    });

    group('practical examples', () {
      test('should represent a Dart class snippet', () {
        // Arrange & Act
        const snippet = SnippetData(
          prefix: 'class',
          label: 'Dart Class',
          body: 'class \${1:ClassName} {\n'
              '  \${1:ClassName}(\${2});\n\n'
              '  \${3}\n'
              '}\$0',
          description: 'Create a Dart class with constructor',
        );

        // Assert
        expect(snippet.prefix, 'class');
        expect(snippet.body, contains('class'));
        expect(snippet.body, contains('\${1:ClassName}'));
      });

      test('should represent a try-catch snippet', () {
        // Arrange & Act
        const snippet = SnippetData(
          prefix: 'try',
          label: 'try-catch',
          body: 'try {\n'
              '  \${1:// code}\n'
              '} catch (e) {\n'
              '  \${2:// handle error}\n'
              '}\$0',
          description: 'Try-catch block',
        );

        // Assert
        expect(snippet.prefix, 'try');
        expect(snippet.body, contains('try'));
        expect(snippet.body, contains('catch (e)'));
      });

      test('should represent a future builder snippet', () {
        // Arrange & Act
        const snippet = SnippetData(
          prefix: 'futurebuilder',
          label: 'FutureBuilder',
          body: 'FutureBuilder<\${1:Type}>(\n'
              '  future: \${2:future},\n'
              '  builder: (context, snapshot) {\n'
              '    if (snapshot.hasData) {\n'
              '      return \${3:Widget}();\n'
              '    }\n'
              '    return const CircularProgressIndicator();\n'
              '  },\n'
              ')\$0',
          description: 'Create a FutureBuilder widget',
        );

        // Assert
        expect(snippet.prefix, 'futurebuilder');
        expect(snippet.body, contains('FutureBuilder'));
        expect(snippet.body, contains('snapshot.hasData'));
      });
    });
  });
}
