import 'package:flutter_test/flutter_test.dart';
import 'package:editor_core/editor_core.dart';

void main() {
  group('TextSelection', () {
    late CursorPosition start;
    late CursorPosition end;

    setUp(() {
      start = const CursorPosition(line: 5, column: 10);
      end = const CursorPosition(line: 10, column: 20);
    });

    group('creation', () {
      test('should create selection with start and end', () {
        // Act
        final selection = TextSelection(start: start, end: end);

        // Assert
        expect(selection.start, equals(start));
        expect(selection.end, equals(end));
      });

      test('should create collapsed selection', () {
        // Arrange
        const position = CursorPosition(line: 5, column: 10);

        // Act
        final selection = TextSelection.collapsed(position);

        // Assert
        expect(selection.start, equals(position));
        expect(selection.end, equals(position));
        expect(selection.isEmpty, isTrue);
      });
    });

    group('isEmpty', () {
      test('should return true for collapsed selection', () {
        // Arrange
        const position = CursorPosition(line: 5, column: 10);

        // Act
        final selection = TextSelection.collapsed(position);

        // Assert
        expect(selection.isEmpty, isTrue);
      });

      test('should return false for non-collapsed selection', () {
        // Arrange
        const start = CursorPosition(line: 5, column: 10);
        const end = CursorPosition(line: 5, column: 15);

        // Act
        const selection = TextSelection(start: start, end: end);

        // Assert
        expect(selection.isEmpty, isFalse);
      });

      test('should return true when start equals end', () {
        // Arrange
        const position = CursorPosition(line: 10, column: 20);

        // Act
        const selection = TextSelection(start: position, end: position);

        // Assert
        expect(selection.isEmpty, isTrue);
      });
    });

    group('isNotEmpty', () {
      test('should return true for non-collapsed selection', () {
        // Arrange
        const selection = TextSelection(
          start: CursorPosition(line: 1, column: 0),
          end: CursorPosition(line: 1, column: 10),
        );

        // Assert
        expect(selection.isNotEmpty, isTrue);
      });

      test('should return false for collapsed selection', () {
        // Arrange
        final selection = TextSelection.collapsed(
          const CursorPosition(line: 5, column: 10),
        );

        // Assert
        expect(selection.isNotEmpty, isFalse);
      });
    });

    group('normalized', () {
      test('should return same selection when start is before end', () {
        // Arrange
        const selection = TextSelection(
          start: CursorPosition(line: 5, column: 10),
          end: CursorPosition(line: 10, column: 20),
        );

        // Act
        final normalized = selection.normalized;

        // Assert
        expect(normalized.start, equals(selection.start));
        expect(normalized.end, equals(selection.end));
      });

      test('should swap start and end when end is before start', () {
        // Arrange
        const selection = TextSelection(
          start: CursorPosition(line: 10, column: 20),
          end: CursorPosition(line: 5, column: 10),
        );

        // Act
        final normalized = selection.normalized;

        // Assert
        expect(normalized.start, equals(const CursorPosition(line: 5, column: 10)));
        expect(normalized.end, equals(const CursorPosition(line: 10, column: 20)));
      });

      test('should handle reverse selection on same line', () {
        // Arrange
        const selection = TextSelection(
          start: CursorPosition(line: 5, column: 20),
          end: CursorPosition(line: 5, column: 10),
        );

        // Act
        final normalized = selection.normalized;

        // Assert
        expect(normalized.start.column, equals(10));
        expect(normalized.end.column, equals(20));
      });

      test('should not modify collapsed selection', () {
        // Arrange
        final selection = TextSelection.collapsed(
          const CursorPosition(line: 5, column: 10),
        );

        // Act
        final normalized = selection.normalized;

        // Assert
        expect(normalized.start, equals(selection.start));
        expect(normalized.end, equals(selection.end));
      });
    });

    group('contains', () {
      test('should return true for position at start', () {
        // Arrange
        const selection = TextSelection(
          start: CursorPosition(line: 5, column: 10),
          end: CursorPosition(line: 10, column: 20),
        );

        // Act & Assert
        expect(
          selection.contains(const CursorPosition(line: 5, column: 10)),
          isTrue,
        );
      });

      test('should return true for position at end', () {
        // Arrange
        const selection = TextSelection(
          start: CursorPosition(line: 5, column: 10),
          end: CursorPosition(line: 10, column: 20),
        );

        // Act & Assert
        expect(
          selection.contains(const CursorPosition(line: 10, column: 20)),
          isTrue,
        );
      });

      test('should return true for position inside selection', () {
        // Arrange
        const selection = TextSelection(
          start: CursorPosition(line: 5, column: 10),
          end: CursorPosition(line: 10, column: 20),
        );

        // Act & Assert
        expect(
          selection.contains(const CursorPosition(line: 7, column: 15)),
          isTrue,
        );
      });

      test('should return false for position before selection', () {
        // Arrange
        const selection = TextSelection(
          start: CursorPosition(line: 5, column: 10),
          end: CursorPosition(line: 10, column: 20),
        );

        // Act & Assert
        expect(
          selection.contains(const CursorPosition(line: 3, column: 5)),
          isFalse,
        );
      });

      test('should return false for position after selection', () {
        // Arrange
        const selection = TextSelection(
          start: CursorPosition(line: 5, column: 10),
          end: CursorPosition(line: 10, column: 20),
        );

        // Act & Assert
        expect(
          selection.contains(const CursorPosition(line: 15, column: 0)),
          isFalse,
        );
      });

      test('should work with reverse selection', () {
        // Arrange
        const selection = TextSelection(
          start: CursorPosition(line: 10, column: 20),
          end: CursorPosition(line: 5, column: 10),
        );

        // Act & Assert
        expect(
          selection.contains(const CursorPosition(line: 7, column: 15)),
          isTrue,
        );
      });

      test('should return true for collapsed selection at position', () {
        // Arrange
        final selection = TextSelection.collapsed(
          const CursorPosition(line: 5, column: 10),
        );

        // Act & Assert
        expect(
          selection.contains(const CursorPosition(line: 5, column: 10)),
          isTrue,
        );
      });

      test('should handle same line selection', () {
        // Arrange
        const selection = TextSelection(
          start: CursorPosition(line: 5, column: 10),
          end: CursorPosition(line: 5, column: 20),
        );

        // Act & Assert
        expect(
          selection.contains(const CursorPosition(line: 5, column: 15)),
          isTrue,
        );
        expect(
          selection.contains(const CursorPosition(line: 5, column: 25)),
          isFalse,
        );
      });
    });

    group('equality', () {
      test('should be equal with same start and end', () {
        const selection1 = TextSelection(
          start: CursorPosition(line: 5, column: 10),
          end: CursorPosition(line: 10, column: 20),
        );

        const selection2 = TextSelection(
          start: CursorPosition(line: 5, column: 10),
          end: CursorPosition(line: 10, column: 20),
        );

        expect(selection1, equals(selection2));
        expect(selection1.hashCode, equals(selection2.hashCode));
      });

      test('should not be equal with different start', () {
        const selection1 = TextSelection(
          start: CursorPosition(line: 5, column: 10),
          end: CursorPosition(line: 10, column: 20),
        );

        const selection2 = TextSelection(
          start: CursorPosition(line: 6, column: 10),
          end: CursorPosition(line: 10, column: 20),
        );

        expect(selection1, isNot(equals(selection2)));
      });

      test('should not be equal with different end', () {
        const selection1 = TextSelection(
          start: CursorPosition(line: 5, column: 10),
          end: CursorPosition(line: 10, column: 20),
        );

        const selection2 = TextSelection(
          start: CursorPosition(line: 5, column: 10),
          end: CursorPosition(line: 10, column: 21),
        );

        expect(selection1, isNot(equals(selection2)));
      });
    });

    group('immutability', () {
      test('should be immutable', () {
        const selection = TextSelection(
          start: CursorPosition(line: 5, column: 10),
          end: CursorPosition(line: 10, column: 20),
        );

        expect(selection.start, equals(const CursorPosition(line: 5, column: 10)));
        expect(selection.end, equals(const CursorPosition(line: 10, column: 20)));
        // Attempting to change would cause compile error
      });

      test('should create new instance on normalize', () {
        const selection = TextSelection(
          start: CursorPosition(line: 10, column: 20),
          end: CursorPosition(line: 5, column: 10),
        );

        final normalized = selection.normalized;

        expect(normalized, isNot(same(selection)));
      });
    });

    group('use cases', () {
      test('should represent word selection', () {
        const selection = TextSelection(
          start: CursorPosition(line: 5, column: 10),
          end: CursorPosition(line: 5, column: 15),
        );

        expect(selection.isNotEmpty, isTrue);
        expect(selection.start.line, equals(selection.end.line));
      });

      test('should represent line selection', () {
        const selection = TextSelection(
          start: CursorPosition(line: 5, column: 0),
          end: CursorPosition(line: 6, column: 0),
        );

        expect(selection.isNotEmpty, isTrue);
      });

      test('should represent multi-line selection', () {
        const selection = TextSelection(
          start: CursorPosition(line: 5, column: 10),
          end: CursorPosition(line: 15, column: 20),
        );

        expect(selection.isNotEmpty, isTrue);
        expect(selection.end.line - selection.start.line, equals(10));
      });

      test('should represent cursor position (no selection)', () {
        final selection = TextSelection.collapsed(
          const CursorPosition(line: 5, column: 10),
        );

        expect(selection.isEmpty, isTrue);
      });
    });
  });
}
