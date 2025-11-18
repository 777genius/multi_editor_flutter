import 'package:flutter_test/flutter_test.dart';
import 'package:editor_monaco/editor_monaco.dart';
import 'package:editor_core/editor_core.dart';

void main() {
  group('MonacoMappers - Position Mapping (0-indexed ↔ 1-indexed)', () {
    group('toMonacoPosition', () {
      test('should convert 0-indexed to 1-indexed', () {
        // Arrange - Domain uses 0-indexed
        const position = CursorPosition(line: 0, column: 0);

        // Act - Monaco uses 1-indexed
        final result = MonacoMappers.toMonacoPosition(position);

        // Assert
        expect(result['lineNumber'], equals(1));
        expect(result['column'], equals(1));
      });

      test('should convert regular position correctly', () {
        // Arrange
        const position = CursorPosition(line: 10, column: 5);

        // Act
        final result = MonacoMappers.toMonacoPosition(position);

        // Assert
        expect(result['lineNumber'], equals(11)); // 10 + 1
        expect(result['column'], equals(6));      // 5 + 1
      });

      test('should handle line 0 column 0 (start of document)', () {
        // Arrange
        const position = CursorPosition(line: 0, column: 0);

        // Act
        final result = MonacoMappers.toMonacoPosition(position);

        // Assert
        expect(result['lineNumber'], equals(1));
        expect(result['column'], equals(1));
      });

      test('should handle large line numbers', () {
        // Arrange
        const position = CursorPosition(line: 9999, column: 500);

        // Act
        final result = MonacoMappers.toMonacoPosition(position);

        // Assert
        expect(result['lineNumber'], equals(10000)); // 9999 + 1
        expect(result['column'], equals(501));       // 500 + 1
      });

      test('should handle mid-line positions', () {
        // Arrange
        const position = CursorPosition(line: 25, column: 42);

        // Act
        final result = MonacoMappers.toMonacoPosition(position);

        // Assert
        expect(result['lineNumber'], equals(26));
        expect(result['column'], equals(43));
      });

      test('should produce correct map structure', () {
        // Arrange
        const position = CursorPosition(line: 5, column: 10);

        // Act
        final result = MonacoMappers.toMonacoPosition(position);

        // Assert
        expect(result, isA<Map<String, int>>());
        expect(result.keys, containsAll(['lineNumber', 'column']));
        expect(result.length, equals(2));
      });

      test('should increment both line and column by 1', () {
        // Test multiple positions to ensure consistent +1 offset
        final testCases = [
          (const CursorPosition(line: 0, column: 0), 1, 1),
          (const CursorPosition(line: 1, column: 1), 2, 2),
          (const CursorPosition(line: 5, column: 10), 6, 11),
          (const CursorPosition(line: 100, column: 50), 101, 51),
        ];

        for (final (position, expectedLine, expectedCol) in testCases) {
          // Act
          final result = MonacoMappers.toMonacoPosition(position);

          // Assert
          expect(
            result['lineNumber'],
            equals(expectedLine),
            reason: 'Line mismatch for ${position.line}',
          );
          expect(
            result['column'],
            equals(expectedCol),
            reason: 'Column mismatch for ${position.column}',
          );
        }
      });
    });

    group('fromMonacoPosition', () {
      test('should convert 1-indexed to 0-indexed', () {
        // Arrange - Monaco uses 1-indexed
        final monacoPosition = {
          'lineNumber': 1,
          'column': 1,
        };

        // Act - Domain uses 0-indexed
        final result = MonacoMappers.fromMonacoPosition(monacoPosition);

        // Assert
        expect(result.line, equals(0));
        expect(result.column, equals(0));
      });

      test('should convert regular position correctly', () {
        // Arrange
        final monacoPosition = {
          'lineNumber': 11,
          'column': 6,
        };

        // Act
        final result = MonacoMappers.fromMonacoPosition(monacoPosition);

        // Assert
        expect(result.line, equals(10));  // 11 - 1
        expect(result.column, equals(5)); // 6 - 1
      });

      test('should handle start of document (1,1)', () {
        // Arrange
        final monacoPosition = {
          'lineNumber': 1,
          'column': 1,
        };

        // Act
        final result = MonacoMappers.fromMonacoPosition(monacoPosition);

        // Assert
        expect(result.line, equals(0));
        expect(result.column, equals(0));
      });

      test('should handle large line numbers', () {
        // Arrange
        final monacoPosition = {
          'lineNumber': 10000,
          'column': 501,
        };

        // Act
        final result = MonacoMappers.fromMonacoPosition(monacoPosition);

        // Assert
        expect(result.line, equals(9999));  // 10000 - 1
        expect(result.column, equals(500)); // 501 - 1
      });

      test('should decrement both line and column by 1', () {
        // Test multiple positions to ensure consistent -1 offset
        final testCases = [
          ({'lineNumber': 1, 'column': 1}, 0, 0),
          ({'lineNumber': 2, 'column': 2}, 1, 1),
          ({'lineNumber': 6, 'column': 11}, 5, 10),
          ({'lineNumber': 101, 'column': 51}, 100, 50),
        ];

        for (final (monacoPos, expectedLine, expectedCol) in testCases) {
          // Act
          final result = MonacoMappers.fromMonacoPosition(monacoPos);

          // Assert
          expect(
            result.line,
            equals(expectedLine),
            reason: 'Line mismatch for ${monacoPos['lineNumber']}',
          );
          expect(
            result.column,
            equals(expectedCol),
            reason: 'Column mismatch for ${monacoPos['column']}',
          );
        }
      });
    });

    group('position roundtrip', () {
      test('should roundtrip position correctly', () {
        // Arrange
        const original = CursorPosition(line: 42, column: 15);

        // Act
        final monacoPos = MonacoMappers.toMonacoPosition(original);
        final roundtrip = MonacoMappers.fromMonacoPosition(monacoPos);

        // Assert
        expect(roundtrip, equals(original));
        expect(roundtrip.line, equals(42));
        expect(roundtrip.column, equals(15));
      });

      test('should roundtrip (0,0) position', () {
        // Arrange
        const original = CursorPosition(line: 0, column: 0);

        // Act
        final monacoPos = MonacoMappers.toMonacoPosition(original);
        final roundtrip = MonacoMappers.fromMonacoPosition(monacoPos);

        // Assert
        expect(roundtrip, equals(original));
      });

      test('should roundtrip multiple positions', () {
        // Arrange
        final positions = [
          const CursorPosition(line: 0, column: 0),
          const CursorPosition(line: 1, column: 0),
          const CursorPosition(line: 0, column: 1),
          const CursorPosition(line: 10, column: 20),
          const CursorPosition(line: 100, column: 200),
        ];

        // Act & Assert
        for (final original in positions) {
          final monacoPos = MonacoMappers.toMonacoPosition(original);
          final roundtrip = MonacoMappers.fromMonacoPosition(monacoPos);
          expect(
            roundtrip,
            equals(original),
            reason: 'Roundtrip failed for (${original.line}, ${original.column})',
          );
        }
      });
    });
  });

  group('MonacoMappers - Range Mapping', () {
    group('toMonacoRange', () {
      test('should convert domain selection to Monaco range', () {
        // Arrange
        final selection = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 0, column: 10),
        );

        // Act
        final result = MonacoMappers.toMonacoRange(selection);

        // Assert
        expect(result['startLineNumber'], equals(1));
        expect(result['startColumn'], equals(1));
        expect(result['endLineNumber'], equals(1));
        expect(result['endColumn'], equals(11));
      });

      test('should handle multi-line selection', () {
        // Arrange
        final selection = TextSelection(
          start: const CursorPosition(line: 5, column: 10),
          end: const CursorPosition(line: 15, column: 20),
        );

        // Act
        final result = MonacoMappers.toMonacoRange(selection);

        // Assert
        expect(result['startLineNumber'], equals(6));   // 5 + 1
        expect(result['startColumn'], equals(11));      // 10 + 1
        expect(result['endLineNumber'], equals(16));    // 15 + 1
        expect(result['endColumn'], equals(21));        // 20 + 1
      });

      test('should normalize reversed selection', () {
        // Arrange - end before start (reversed selection)
        final selection = TextSelection(
          start: const CursorPosition(line: 10, column: 20),
          end: const CursorPosition(line: 5, column: 10),
        );

        // Act
        final result = MonacoMappers.toMonacoRange(selection);

        // Assert - should be normalized (start before end)
        expect(result['startLineNumber'], lessThan(result['endLineNumber']));
      });

      test('should handle single-character selection', () {
        // Arrange
        final selection = TextSelection(
          start: const CursorPosition(line: 10, column: 5),
          end: const CursorPosition(line: 10, column: 6),
        );

        // Act
        final result = MonacoMappers.toMonacoRange(selection);

        // Assert
        expect(result['startLineNumber'], equals(11));
        expect(result['startColumn'], equals(6));
        expect(result['endLineNumber'], equals(11));
        expect(result['endColumn'], equals(7));
      });

      test('should handle collapsed selection (cursor position)', () {
        // Arrange - start equals end
        final selection = TextSelection(
          start: const CursorPosition(line: 5, column: 10),
          end: const CursorPosition(line: 5, column: 10),
        );

        // Act
        final result = MonacoMappers.toMonacoRange(selection);

        // Assert
        expect(result['startLineNumber'], equals(result['endLineNumber']));
        expect(result['startColumn'], equals(result['endColumn']));
        expect(result['startLineNumber'], equals(6));
        expect(result['startColumn'], equals(11));
      });

      test('should produce correct map structure', () {
        // Arrange
        final selection = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 1, column: 1),
        );

        // Act
        final result = MonacoMappers.toMonacoRange(selection);

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result.keys, containsAll([
          'startLineNumber',
          'startColumn',
          'endLineNumber',
          'endColumn',
        ]));
      });
    });

    group('fromMonacoRange', () {
      test('should convert Monaco range to domain selection', () {
        // Arrange
        final monacoRange = {
          'startLineNumber': 1,
          'startColumn': 1,
          'endLineNumber': 1,
          'endColumn': 11,
        };

        // Act
        final result = MonacoMappers.fromMonacoRange(monacoRange);

        // Assert
        expect(result.start.line, equals(0));
        expect(result.start.column, equals(0));
        expect(result.end.line, equals(0));
        expect(result.end.column, equals(10));
      });

      test('should handle multi-line range', () {
        // Arrange
        final monacoRange = {
          'startLineNumber': 6,
          'startColumn': 11,
          'endLineNumber': 16,
          'endColumn': 21,
        };

        // Act
        final result = MonacoMappers.fromMonacoRange(monacoRange);

        // Assert
        expect(result.start.line, equals(5));   // 6 - 1
        expect(result.start.column, equals(10)); // 11 - 1
        expect(result.end.line, equals(15));    // 16 - 1
        expect(result.end.column, equals(20));  // 21 - 1
      });

      test('should create valid TextSelection', () {
        // Arrange
        final monacoRange = {
          'startLineNumber': 10,
          'startColumn': 5,
          'endLineNumber': 20,
          'endColumn': 15,
        };

        // Act
        final result = MonacoMappers.fromMonacoRange(monacoRange);

        // Assert
        expect(result, isA<TextSelection>());
        expect(result.start.line, lessThanOrEqualTo(result.end.line));
      });
    });

    group('range roundtrip', () {
      test('should roundtrip simple range correctly', () {
        // Arrange
        final original = TextSelection(
          start: const CursorPosition(line: 10, column: 5),
          end: const CursorPosition(line: 10, column: 15),
        );

        // Act
        final monacoRange = MonacoMappers.toMonacoRange(original);
        final roundtrip = MonacoMappers.fromMonacoRange(monacoRange);

        // Assert
        expect(roundtrip.start, equals(original.start));
        expect(roundtrip.end, equals(original.end));
      });

      test('should roundtrip multi-line range', () {
        // Arrange
        final original = TextSelection(
          start: const CursorPosition(line: 5, column: 0),
          end: const CursorPosition(line: 10, column: 20),
        );

        // Act
        final monacoRange = MonacoMappers.toMonacoRange(original);
        final roundtrip = MonacoMappers.fromMonacoRange(monacoRange);

        // Assert
        expect(roundtrip.start, equals(original.start));
        expect(roundtrip.end, equals(original.end));
      });

      test('should roundtrip collapsed range', () {
        // Arrange
        final original = TextSelection(
          start: const CursorPosition(line: 15, column: 25),
          end: const CursorPosition(line: 15, column: 25),
        );

        // Act
        final monacoRange = MonacoMappers.toMonacoRange(original);
        final roundtrip = MonacoMappers.fromMonacoRange(monacoRange);

        // Assert
        expect(roundtrip.isEmpty, isTrue);
        expect(roundtrip.start, equals(roundtrip.end));
      });
    });

    group('edge cases', () {
      test('should handle zero-width selection at document start', () {
        // Arrange
        final selection = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 0, column: 0),
        );

        // Act
        final monacoRange = MonacoMappers.toMonacoRange(selection);
        final roundtrip = MonacoMappers.fromMonacoRange(monacoRange);

        // Assert
        expect(roundtrip.start.line, equals(0));
        expect(roundtrip.start.column, equals(0));
        expect(roundtrip.isEmpty, isTrue);
      });

      test('should handle large line and column numbers', () {
        // Arrange
        final selection = TextSelection(
          start: const CursorPosition(line: 10000, column: 5000),
          end: const CursorPosition(line: 10001, column: 5001),
        );

        // Act
        final monacoRange = MonacoMappers.toMonacoRange(selection);
        final roundtrip = MonacoMappers.fromMonacoRange(monacoRange);

        // Assert
        expect(roundtrip.start, equals(selection.start));
        expect(roundtrip.end, equals(selection.end));
      });

      test('should handle full-line selection', () {
        // Arrange - selecting line 10 from column 0 to end
        final selection = TextSelection(
          start: const CursorPosition(line: 10, column: 0),
          end: const CursorPosition(line: 11, column: 0),
        );

        // Act
        final monacoRange = MonacoMappers.toMonacoRange(selection);
        final roundtrip = MonacoMappers.fromMonacoRange(monacoRange);

        // Assert
        expect(roundtrip.start, equals(selection.start));
        expect(roundtrip.end, equals(selection.end));
      });
    });
  });

  group('Index Conversion Validation', () {
    test('should always add 1 when converting to Monaco', () {
      // This test validates the core indexing difference
      const domainPos = CursorPosition(line: 42, column: 15);
      final monacoPos = MonacoMappers.toMonacoPosition(domainPos);

      expect(monacoPos['lineNumber'], equals(domainPos.line + 1));
      expect(monacoPos['column'], equals(domainPos.column + 1));
    });

    test('should always subtract 1 when converting from Monaco', () {
      // This test validates the core indexing difference
      final monacoPos = {'lineNumber': 43, 'column': 16};
      final domainPos = MonacoMappers.fromMonacoPosition(monacoPos);

      expect(domainPos.line, equals(monacoPos['lineNumber']! - 1));
      expect(domainPos.column, equals(monacoPos['column']! - 1));
    });
  });
}
