import 'package:flutter_test/flutter_test.dart';
import 'package:editor_core/editor_core.dart';

void main() {
  group('CursorPosition', () {
    group('creation', () {
      test('should create position with line and column', () {
        // Act
        const position = CursorPosition(line: 10, column: 5);

        // Assert
        expect(position.line, equals(10));
        expect(position.column, equals(5));
      });

      test('should create position at origin', () {
        // Act
        const position = CursorPosition(line: 0, column: 0);

        // Assert
        expect(position.line, equals(0));
        expect(position.column, equals(0));
      });

      test('should create position using factory method', () {
        // Act
        final position = CursorPosition.create(line: 5, column: 10);

        // Assert
        expect(position.line, equals(5));
        expect(position.column, equals(10));
      });
    });

    group('validation', () {
      test('should throw for negative line', () {
        // Act & Assert
        expect(
          () => CursorPosition.create(line: -1, column: 0),
          throwsA(isA<EditorFailure>()),
        );
      });

      test('should throw for negative column', () {
        // Act & Assert
        expect(
          () => CursorPosition.create(line: 0, column: -1),
          throwsA(isA<EditorFailure>()),
        );
      });

      test('should throw with descriptive message for invalid line', () {
        // Act & Assert
        expect(
          () => CursorPosition.create(line: -5, column: 0),
          throwsA(
            isA<EditorFailure>().having(
              (e) => e.toString(),
              'message',
              contains('Line must be >= 0'),
            ),
          ),
        );
      });

      test('should throw with descriptive message for invalid column', () {
        // Act & Assert
        expect(
          () => CursorPosition.create(line: 0, column: -10),
          throwsA(
            isA<EditorFailure>().having(
              (e) => e.toString(),
              'message',
              contains('Column must be >= 0'),
            ),
          ),
        );
      });

      test('should allow valid positions', () {
        // Act
        final positions = [
          CursorPosition.create(line: 0, column: 0),
          CursorPosition.create(line: 100, column: 50),
          CursorPosition.create(line: 1000, column: 500),
        ];

        // Assert
        for (final position in positions) {
          expect(position.line, greaterThanOrEqualTo(0));
          expect(position.column, greaterThanOrEqualTo(0));
        }
      });
    });

    group('isBefore', () {
      test('should return true when line is before', () {
        const pos1 = CursorPosition(line: 5, column: 10);
        const pos2 = CursorPosition(line: 10, column: 5);

        expect(pos1.isBefore(pos2), isTrue);
      });

      test('should return true when line is same and column is before', () {
        const pos1 = CursorPosition(line: 5, column: 5);
        const pos2 = CursorPosition(line: 5, column: 10);

        expect(pos1.isBefore(pos2), isTrue);
      });

      test('should return false when line is after', () {
        const pos1 = CursorPosition(line: 10, column: 5);
        const pos2 = CursorPosition(line: 5, column: 10);

        expect(pos1.isBefore(pos2), isFalse);
      });

      test('should return false when line is same and column is after', () {
        const pos1 = CursorPosition(line: 5, column: 10);
        const pos2 = CursorPosition(line: 5, column: 5);

        expect(pos1.isBefore(pos2), isFalse);
      });

      test('should return false when positions are equal', () {
        const pos1 = CursorPosition(line: 5, column: 10);
        const pos2 = CursorPosition(line: 5, column: 10);

        expect(pos1.isBefore(pos2), isFalse);
      });
    });

    group('isAfter', () {
      test('should return true when line is after', () {
        const pos1 = CursorPosition(line: 10, column: 5);
        const pos2 = CursorPosition(line: 5, column: 10);

        expect(pos1.isAfter(pos2), isTrue);
      });

      test('should return true when line is same and column is after', () {
        const pos1 = CursorPosition(line: 5, column: 10);
        const pos2 = CursorPosition(line: 5, column: 5);

        expect(pos1.isAfter(pos2), isTrue);
      });

      test('should return false when line is before', () {
        const pos1 = CursorPosition(line: 5, column: 10);
        const pos2 = CursorPosition(line: 10, column: 5);

        expect(pos1.isAfter(pos2), isFalse);
      });

      test('should return false when positions are equal', () {
        const pos1 = CursorPosition(line: 5, column: 10);
        const pos2 = CursorPosition(line: 5, column: 10);

        expect(pos1.isAfter(pos2), isFalse);
      });
    });

    group('isEqual', () {
      test('should return true for same position', () {
        const pos1 = CursorPosition(line: 5, column: 10);
        const pos2 = CursorPosition(line: 5, column: 10);

        expect(pos1.isEqual(pos2), isTrue);
      });

      test('should return false for different line', () {
        const pos1 = CursorPosition(line: 5, column: 10);
        const pos2 = CursorPosition(line: 10, column: 10);

        expect(pos1.isEqual(pos2), isFalse);
      });

      test('should return false for different column', () {
        const pos1 = CursorPosition(line: 5, column: 10);
        const pos2 = CursorPosition(line: 5, column: 15);

        expect(pos1.isEqual(pos2), isFalse);
      });
    });

    group('offset', () {
      test('should offset by lines', () {
        const position = CursorPosition(line: 5, column: 10);

        final offset = position.offset(lines: 3);

        expect(offset.line, equals(8));
        expect(offset.column, equals(10));
      });

      test('should offset by columns', () {
        const position = CursorPosition(line: 5, column: 10);

        final offset = position.offset(columns: 5);

        expect(offset.line, equals(5));
        expect(offset.column, equals(15));
      });

      test('should offset by both lines and columns', () {
        const position = CursorPosition(line: 5, column: 10);

        final offset = position.offset(lines: 2, columns: 3);

        expect(offset.line, equals(7));
        expect(offset.column, equals(13));
      });

      test('should offset by negative values', () {
        const position = CursorPosition(line: 10, column: 20);

        final offset = position.offset(lines: -3, columns: -5);

        expect(offset.line, equals(7));
        expect(offset.column, equals(15));
      });

      test('should return same position when no offset', () {
        const position = CursorPosition(line: 5, column: 10);

        final offset = position.offset();

        expect(offset.line, equals(5));
        expect(offset.column, equals(10));
      });

      test('should throw when offset results in negative line', () {
        const position = CursorPosition(line: 2, column: 5);

        expect(
          () => position.offset(lines: -5),
          throwsA(isA<EditorFailure>()),
        );
      });

      test('should throw when offset results in negative column', () {
        const position = CursorPosition(line: 5, column: 3);

        expect(
          () => position.offset(columns: -10),
          throwsA(isA<EditorFailure>()),
        );
      });
    });

    group('equality', () {
      test('should be equal with same line and column', () {
        const pos1 = CursorPosition(line: 5, column: 10);
        const pos2 = CursorPosition(line: 5, column: 10);

        expect(pos1, equals(pos2));
        expect(pos1.hashCode, equals(pos2.hashCode));
      });

      test('should not be equal with different line', () {
        const pos1 = CursorPosition(line: 5, column: 10);
        const pos2 = CursorPosition(line: 6, column: 10);

        expect(pos1, isNot(equals(pos2)));
      });

      test('should not be equal with different column', () {
        const pos1 = CursorPosition(line: 5, column: 10);
        const pos2 = CursorPosition(line: 5, column: 11);

        expect(pos1, isNot(equals(pos2)));
      });
    });

    group('sorting', () {
      test('should be sortable', () {
        final positions = [
          const CursorPosition(line: 10, column: 5),
          const CursorPosition(line: 5, column: 20),
          const CursorPosition(line: 5, column: 10),
          const CursorPosition(line: 1, column: 0),
        ];

        positions.sort((a, b) {
          if (a.line != b.line) return a.line.compareTo(b.line);
          return a.column.compareTo(b.column);
        });

        expect(positions[0].line, equals(1));
        expect(positions[1].line, equals(5));
        expect(positions[1].column, equals(10));
        expect(positions[2].line, equals(5));
        expect(positions[2].column, equals(20));
        expect(positions[3].line, equals(10));
      });
    });

    group('immutability', () {
      test('should be immutable', () {
        const position = CursorPosition(line: 5, column: 10);

        expect(position.line, equals(5));
        expect(position.column, equals(10));
        // Attempting to change would cause compile error
      });

      test('should create new instance on offset', () {
        const position = CursorPosition(line: 5, column: 10);

        final offset = position.offset(lines: 1);

        expect(offset, isNot(same(position)));
        expect(position.line, equals(5)); // unchanged
      });
    });
  });
}
