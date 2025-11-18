import 'package:flutter_test/flutter_test.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';

void main() {
  group('InlayHint', () {
    group('Construction', () {
      test('should create with string label', () {
        // Act
        final hint = InlayHint(
          position: const CursorPosition(line: 10, column: 5),
          label: const InlayHintLabel.string(': i32'),
        );

        // Assert
        expect(hint.position.line, equals(10));
        expect(hint.position.column, equals(5));
        hint.label.when(
          string: (value) => expect(value, equals(': i32')),
          parts: (_) => fail('Should be string'),
        );
      });

      test('should create with label parts', () {
        // Arrange
        const parts = [
          InlayHintLabelPart(value: 'enabled'),
          InlayHintLabelPart(value: ': '),
        ];

        // Act
        final hint = InlayHint(
          position: const CursorPosition(line: 5, column: 10),
          label: const InlayHintLabel.parts(parts),
        );

        // Assert
        hint.label.when(
          string: (_) => fail('Should be parts'),
          parts: (p) => expect(p.length, equals(2)),
        );
      });

      test('should create with all optional parameters', () {
        // Act
        final hint = InlayHint(
          position: const CursorPosition(line: 0, column: 0),
          label: const InlayHintLabel.string('test'),
          kind: InlayHintKind.type,
          tooltip: 'Type annotation',
          paddingLeft: true,
          paddingRight: true,
          data: {'custom': 'data'},
        );

        // Assert
        expect(hint.kind, equals(InlayHintKind.type));
        expect(hint.tooltip, equals('Type annotation'));
        expect(hint.paddingLeft, isTrue);
        expect(hint.paddingRight, isTrue);
        expect(hint.data, isNotNull);
      });

      test('should default padding to false', () {
        // Act
        final hint = InlayHint(
          position: const CursorPosition(line: 0, column: 0),
          label: const InlayHintLabel.string('test'),
        );

        // Assert
        expect(hint.paddingLeft, isFalse);
        expect(hint.paddingRight, isFalse);
      });
    });

    group('InlayHintKind', () {
      test('should have type kind', () {
        // Act
        final hint = InlayHint(
          position: const CursorPosition(line: 0, column: 0),
          label: const InlayHintLabel.string(': string'),
          kind: InlayHintKind.type,
        );

        // Assert
        expect(hint.kind, equals(InlayHintKind.type));
      });

      test('should have parameter kind', () {
        // Act
        final hint = InlayHint(
          position: const CursorPosition(line: 0, column: 0),
          label: const InlayHintLabel.string('enabled:'),
          kind: InlayHintKind.parameter,
        );

        // Assert
        expect(hint.kind, equals(InlayHintKind.parameter));
      });

      test('should have other kind', () {
        // Act
        final hint = InlayHint(
          position: const CursorPosition(line: 0, column: 0),
          label: const InlayHintLabel.string('hint'),
          kind: InlayHintKind.other,
        );

        // Assert
        expect(hint.kind, equals(InlayHintKind.other));
      });

      test('should support null kind', () {
        // Act
        final hint = InlayHint(
          position: const CursorPosition(line: 0, column: 0),
          label: const InlayHintLabel.string('hint'),
          kind: null,
        );

        // Assert
        expect(hint.kind, isNull);
      });
    });

    group('InlayHintLabel', () {
      test('should create string label', () {
        // Act
        const label = InlayHintLabel.string(': number');

        // Assert
        label.when(
          string: (value) => expect(value, equals(': number')),
          parts: (_) => fail('Should be string'),
        );
      });

      test('should create parts label', () {
        // Arrange
        const parts = [
          InlayHintLabelPart(value: 'param'),
          InlayHintLabelPart(value: ': '),
        ];

        // Act
        const label = InlayHintLabel.parts(parts);

        // Assert
        label.when(
          string: (_) => fail('Should be parts'),
          parts: (p) {
            expect(p.length, equals(2));
            expect(p[0].value, equals('param'));
            expect(p[1].value, equals(': '));
          },
        );
      });

      test('should differentiate between string and parts', () {
        // Arrange
        const stringLabel = InlayHintLabel.string('test');
        const partsLabel = InlayHintLabel.parts([
          InlayHintLabelPart(value: 'test'),
        ]);

        // Assert
        expect(stringLabel, isNot(equals(partsLabel)));
      });
    });

    group('InlayHintLabelPart', () {
      test('should create with just value', () {
        // Act
        const part = InlayHintLabelPart(value: 'enabled');

        // Assert
        expect(part.value, equals('enabled'));
        expect(part.tooltip, isNull);
        expect(part.location, isNull);
      });

      test('should create with tooltip', () {
        // Act
        const part = InlayHintLabelPart(
          value: 'x',
          tooltip: 'Variable x of type number',
        );

        // Assert
        expect(part.value, equals('x'));
        expect(part.tooltip, equals('Variable x of type number'));
      });

      test('should create with location', () {
        // Arrange
        final location = Location(
          uri: DocumentUri.fromFilePath('/test.dart'),
          range: TextSelection(
            start: const CursorPosition(line: 0, column: 0),
            end: const CursorPosition(line: 0, column: 10),
          ),
        );

        // Act
        final part = InlayHintLabelPart(
          value: 'MyType',
          location: location,
        );

        // Assert
        expect(part.value, equals('MyType'));
        expect(part.location, equals(location));
      });

      test('should create with all parameters', () {
        // Arrange
        final location = Location(
          uri: DocumentUri.fromFilePath('/test.dart'),
          range: TextSelection(
            start: const CursorPosition(line: 5, column: 0),
            end: const CursorPosition(line: 5, column: 10),
          ),
        );

        // Act
        final part = InlayHintLabelPart(
          value: 'Point',
          tooltip: 'struct Point',
          location: location,
        );

        // Assert
        expect(part.value, equals('Point'));
        expect(part.tooltip, equals('struct Point'));
        expect(part.location, isNotNull);
      });
    });

    group('Use Cases', () {
      group('Type Annotations', () {
        test('should represent Rust type hint', () {
          // Act - `let x = 5` → `let x: i32 = 5`
          final hint = InlayHint(
            position: const CursorPosition(line: 10, column: 9),
            label: const InlayHintLabel.string(': i32'),
            kind: InlayHintKind.type,
          );

          // Assert
          expect(hint.kind, equals(InlayHintKind.type));
          hint.label.when(
            string: (value) => expect(value, contains('i32')),
            parts: (_) => fail('Should be string'),
          );
        });

        test('should represent TypeScript type hint', () {
          // Act - `const x = getValue()` → `const x: string = getValue()`
          final hint = InlayHint(
            position: const CursorPosition(line: 5, column: 8),
            label: const InlayHintLabel.string(': string'),
            kind: InlayHintKind.type,
            tooltip: 'Inferred type',
          );

          // Assert
          expect(hint.kind, equals(InlayHintKind.type));
        });

        test('should represent complex type with parts', () {
          // Act - Type with clickable parts
          final hint = InlayHint(
            position: const CursorPosition(line: 0, column: 0),
            label: const InlayHintLabel.parts([
              InlayHintLabelPart(value: ': '),
              InlayHintLabelPart(
                value: 'Result',
                tooltip: 'enum Result<T, E>',
              ),
              InlayHintLabelPart(value: '<'),
              InlayHintLabelPart(value: 'i32'),
              InlayHintLabelPart(value: ', '),
              InlayHintLabelPart(value: 'Error'),
              InlayHintLabelPart(value: '>'),
            ]),
            kind: InlayHintKind.type,
          );

          // Assert
          hint.label.when(
            string: (_) => fail('Should be parts'),
            parts: (p) => expect(p.length, equals(7)),
          );
        });
      });

      group('Parameter Names', () {
        test('should represent parameter name hint', () {
          // Act - `foo(true, 42)` → `foo(enabled: true, count: 42)`
          final hint = InlayHint(
            position: const CursorPosition(line: 20, column: 8),
            label: const InlayHintLabel.string('enabled:'),
            kind: InlayHintKind.parameter,
            paddingRight: true,
          );

          // Assert
          expect(hint.kind, equals(InlayHintKind.parameter));
          expect(hint.paddingRight, isTrue);
        });

        test('should represent multiple parameter hints', () {
          // Arrange - Multiple hints for same call
          final hints = [
            InlayHint(
              position: const CursorPosition(line: 10, column: 10),
              label: const InlayHintLabel.string('x:'),
              kind: InlayHintKind.parameter,
            ),
            InlayHint(
              position: const CursorPosition(line: 10, column: 15),
              label: const InlayHintLabel.string('y:'),
              kind: InlayHintKind.parameter,
            ),
          ];

          // Assert
          expect(hints.length, equals(2));
          expect(hints.every((h) => h.kind == InlayHintKind.parameter), isTrue);
        });
      });

      group('Other Hints', () {
        test('should represent closure parameter types', () {
          // Act - `|x, y| x + y` → `|x: i32, y: i32| x + y`
          final hint = InlayHint(
            position: const CursorPosition(line: 5, column: 3),
            label: const InlayHintLabel.string(': i32'),
            kind: InlayHintKind.type,
          );

          // Assert
          expect(hint.kind, equals(InlayHintKind.type));
        });

        test('should represent chain hints', () {
          // Act - Method chain intermediate types
          final hint = InlayHint(
            position: const CursorPosition(line: 10, column: 0),
            label: const InlayHintLabel.string('Vec<String>'),
            kind: InlayHintKind.type,
            tooltip: 'Intermediate type in chain',
          );

          // Assert
          expect(hint.tooltip, contains('chain'));
        });
      });
    });

    group('Padding', () {
      test('should support left padding only', () {
        // Act
        final hint = InlayHint(
          position: const CursorPosition(line: 0, column: 0),
          label: const InlayHintLabel.string('hint'),
          paddingLeft: true,
          paddingRight: false,
        );

        // Assert
        expect(hint.paddingLeft, isTrue);
        expect(hint.paddingRight, isFalse);
      });

      test('should support right padding only', () {
        // Act
        final hint = InlayHint(
          position: const CursorPosition(line: 0, column: 0),
          label: const InlayHintLabel.string('hint'),
          paddingLeft: false,
          paddingRight: true,
        );

        // Assert
        expect(hint.paddingLeft, isFalse);
        expect(hint.paddingRight, isTrue);
      });

      test('should support both paddings', () {
        // Act
        final hint = InlayHint(
          position: const CursorPosition(line: 0, column: 0),
          label: const InlayHintLabel.string('hint'),
          paddingLeft: true,
          paddingRight: true,
        );

        // Assert
        expect(hint.paddingLeft, isTrue);
        expect(hint.paddingRight, isTrue);
      });

      test('should support no padding', () {
        // Act
        final hint = InlayHint(
          position: const CursorPosition(line: 0, column: 0),
          label: const InlayHintLabel.string('hint'),
        );

        // Assert
        expect(hint.paddingLeft, isFalse);
        expect(hint.paddingRight, isFalse);
      });
    });

    group('Equality', () {
      test('should be equal with same values', () {
        // Arrange
        final hint1 = InlayHint(
          position: const CursorPosition(line: 10, column: 5),
          label: const InlayHintLabel.string(': i32'),
          kind: InlayHintKind.type,
        );
        final hint2 = InlayHint(
          position: const CursorPosition(line: 10, column: 5),
          label: const InlayHintLabel.string(': i32'),
          kind: InlayHintKind.type,
        );

        // Assert
        expect(hint1, equals(hint2));
      });

      test('should not be equal with different positions', () {
        // Arrange
        final hint1 = InlayHint(
          position: const CursorPosition(line: 10, column: 5),
          label: const InlayHintLabel.string(': i32'),
        );
        final hint2 = InlayHint(
          position: const CursorPosition(line: 10, column: 6),
          label: const InlayHintLabel.string(': i32'),
        );

        // Assert
        expect(hint1, isNot(equals(hint2)));
      });

      test('should not be equal with different labels', () {
        // Arrange
        final hint1 = InlayHint(
          position: const CursorPosition(line: 10, column: 5),
          label: const InlayHintLabel.string(': i32'),
        );
        final hint2 = InlayHint(
          position: const CursorPosition(line: 10, column: 5),
          label: const InlayHintLabel.string(': string'),
        );

        // Assert
        expect(hint1, isNot(equals(hint2)));
      });
    });
  });
}
