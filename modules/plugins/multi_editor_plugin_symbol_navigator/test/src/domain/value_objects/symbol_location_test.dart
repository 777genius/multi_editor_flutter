import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugin_symbol_navigator/src/domain/value_objects/symbol_location.dart';

void main() {
  group('SymbolLocation', () {
    group('constructor', () {
      test('should create instance with all required fields', () {
        // Arrange & Act
        const location = SymbolLocation(
          startLine: 10,
          startColumn: 5,
          endLine: 15,
          endColumn: 20,
          startOffset: 100,
          endOffset: 200,
        );

        // Assert
        expect(location.startLine, 10);
        expect(location.startColumn, 5);
        expect(location.endLine, 15);
        expect(location.endColumn, 20);
        expect(location.startOffset, 100);
        expect(location.endOffset, 200);
      });

      test('should create instance for single line', () {
        // Arrange & Act
        const location = SymbolLocation(
          startLine: 5,
          startColumn: 0,
          endLine: 5,
          endColumn: 10,
          startOffset: 50,
          endOffset: 60,
        );

        // Assert
        expect(location.startLine, 5);
        expect(location.endLine, 5);
        expect(location.lineCount, 1);
      });

      test('should create instance with zero values', () {
        // Arrange & Act
        const location = SymbolLocation(
          startLine: 0,
          startColumn: 0,
          endLine: 0,
          endColumn: 0,
          startOffset: 0,
          endOffset: 0,
        );

        // Assert
        expect(location.startLine, 0);
        expect(location.startColumn, 0);
        expect(location.endLine, 0);
        expect(location.endColumn, 0);
        expect(location.startOffset, 0);
        expect(location.endOffset, 0);
      });

      test('should create instance with large values', () {
        // Arrange & Act
        const location = SymbolLocation(
          startLine: 10000,
          startColumn: 500,
          endLine: 10100,
          endColumn: 600,
          startOffset: 500000,
          endOffset: 550000,
        );

        // Assert
        expect(location.startLine, 10000);
        expect(location.endLine, 10100);
        expect(location.startOffset, 500000);
        expect(location.endOffset, 550000);
      });
    });

    group('fromTreeSitter factory', () {
      test('should create instance from tree-sitter data', () {
        // Arrange & Act
        final location = SymbolLocation.fromTreeSitter(
          startRow: 10,
          startCol: 5,
          endRow: 15,
          endCol: 20,
          startByte: 100,
          endByte: 200,
        );

        // Assert
        expect(location.startLine, 10);
        expect(location.startColumn, 5);
        expect(location.endLine, 15);
        expect(location.endColumn, 20);
        expect(location.startOffset, 100);
        expect(location.endOffset, 200);
      });

      test('should map tree-sitter fields correctly', () {
        // Arrange & Act
        final location = SymbolLocation.fromTreeSitter(
          startRow: 0,
          startCol: 0,
          endRow: 1,
          endCol: 10,
          startByte: 0,
          endByte: 25,
        );

        // Assert
        expect(location.startLine, 0);
        expect(location.startColumn, 0);
        expect(location.endLine, 1);
        expect(location.endColumn, 10);
        expect(location.startOffset, 0);
        expect(location.endOffset, 25);
      });
    });

    group('lineCount getter', () {
      test('should return 1 for single line symbol', () {
        // Arrange
        const location = SymbolLocation(
          startLine: 5,
          startColumn: 0,
          endLine: 5,
          endColumn: 10,
          startOffset: 50,
          endOffset: 60,
        );

        // Act & Assert
        expect(location.lineCount, 1);
      });

      test('should return correct count for multi-line symbol', () {
        // Arrange
        const location = SymbolLocation(
          startLine: 10,
          startColumn: 0,
          endLine: 15,
          endColumn: 10,
          startOffset: 100,
          endOffset: 200,
        );

        // Act & Assert
        expect(location.lineCount, 6); // 15 - 10 + 1
      });

      test('should return 2 for two-line symbol', () {
        // Arrange
        const location = SymbolLocation(
          startLine: 0,
          startColumn: 0,
          endLine: 1,
          endColumn: 0,
          startOffset: 0,
          endOffset: 20,
        );

        // Act & Assert
        expect(location.lineCount, 2);
      });

      test('should handle large line spans', () {
        // Arrange
        const location = SymbolLocation(
          startLine: 0,
          startColumn: 0,
          endLine: 999,
          endColumn: 0,
          startOffset: 0,
          endOffset: 50000,
        );

        // Act & Assert
        expect(location.lineCount, 1000);
      });
    });

    group('containsLine', () {
      test('should return true for line within range', () {
        // Arrange
        const location = SymbolLocation(
          startLine: 10,
          startColumn: 0,
          endLine: 20,
          endColumn: 0,
          startOffset: 100,
          endOffset: 200,
        );

        // Act & Assert
        expect(location.containsLine(15), true);
      });

      test('should return true for start line', () {
        // Arrange
        const location = SymbolLocation(
          startLine: 10,
          startColumn: 0,
          endLine: 20,
          endColumn: 0,
          startOffset: 100,
          endOffset: 200,
        );

        // Act & Assert
        expect(location.containsLine(10), true);
      });

      test('should return true for end line', () {
        // Arrange
        const location = SymbolLocation(
          startLine: 10,
          startColumn: 0,
          endLine: 20,
          endColumn: 0,
          startOffset: 100,
          endOffset: 200,
        );

        // Act & Assert
        expect(location.containsLine(20), true);
      });

      test('should return false for line before range', () {
        // Arrange
        const location = SymbolLocation(
          startLine: 10,
          startColumn: 0,
          endLine: 20,
          endColumn: 0,
          startOffset: 100,
          endOffset: 200,
        );

        // Act & Assert
        expect(location.containsLine(9), false);
      });

      test('should return false for line after range', () {
        // Arrange
        const location = SymbolLocation(
          startLine: 10,
          startColumn: 0,
          endLine: 20,
          endColumn: 0,
          startOffset: 100,
          endOffset: 200,
        );

        // Act & Assert
        expect(location.containsLine(21), false);
      });

      test('should handle single line location', () {
        // Arrange
        const location = SymbolLocation(
          startLine: 15,
          startColumn: 0,
          endLine: 15,
          endColumn: 20,
          startOffset: 150,
          endOffset: 170,
        );

        // Act & Assert
        expect(location.containsLine(15), true);
        expect(location.containsLine(14), false);
        expect(location.containsLine(16), false);
      });

      test('should handle line 0', () {
        // Arrange
        const location = SymbolLocation(
          startLine: 0,
          startColumn: 0,
          endLine: 5,
          endColumn: 0,
          startOffset: 0,
          endOffset: 50,
        );

        // Act & Assert
        expect(location.containsLine(0), true);
      });
    });

    group('containsOffset', () {
      test('should return true for offset within range', () {
        // Arrange
        const location = SymbolLocation(
          startLine: 10,
          startColumn: 0,
          endLine: 20,
          endColumn: 0,
          startOffset: 100,
          endOffset: 200,
        );

        // Act & Assert
        expect(location.containsOffset(150), true);
      });

      test('should return true for start offset', () {
        // Arrange
        const location = SymbolLocation(
          startLine: 10,
          startColumn: 0,
          endLine: 20,
          endColumn: 0,
          startOffset: 100,
          endOffset: 200,
        );

        // Act & Assert
        expect(location.containsOffset(100), true);
      });

      test('should return true for end offset', () {
        // Arrange
        const location = SymbolLocation(
          startLine: 10,
          startColumn: 0,
          endLine: 20,
          endColumn: 0,
          startOffset: 100,
          endOffset: 200,
        );

        // Act & Assert
        expect(location.containsOffset(200), true);
      });

      test('should return false for offset before range', () {
        // Arrange
        const location = SymbolLocation(
          startLine: 10,
          startColumn: 0,
          endLine: 20,
          endColumn: 0,
          startOffset: 100,
          endOffset: 200,
        );

        // Act & Assert
        expect(location.containsOffset(99), false);
      });

      test('should return false for offset after range', () {
        // Arrange
        const location = SymbolLocation(
          startLine: 10,
          startColumn: 0,
          endLine: 20,
          endColumn: 0,
          startOffset: 100,
          endOffset: 200,
        );

        // Act & Assert
        expect(location.containsOffset(201), false);
      });

      test('should handle offset 0', () {
        // Arrange
        const location = SymbolLocation(
          startLine: 0,
          startColumn: 0,
          endLine: 5,
          endColumn: 0,
          startOffset: 0,
          endOffset: 50,
        );

        // Act & Assert
        expect(location.containsOffset(0), true);
      });

      test('should handle large offsets', () {
        // Arrange
        const location = SymbolLocation(
          startLine: 0,
          startColumn: 0,
          endLine: 1000,
          endColumn: 0,
          startOffset: 0,
          endOffset: 1000000,
        );

        // Act & Assert
        expect(location.containsOffset(500000), true);
        expect(location.containsOffset(1000000), true);
        expect(location.containsOffset(1000001), false);
      });
    });

    group('equality', () {
      test('should be equal when all fields are the same', () {
        // Arrange
        const location1 = SymbolLocation(
          startLine: 10,
          startColumn: 5,
          endLine: 15,
          endColumn: 20,
          startOffset: 100,
          endOffset: 200,
        );
        const location2 = SymbolLocation(
          startLine: 10,
          startColumn: 5,
          endLine: 15,
          endColumn: 20,
          startOffset: 100,
          endOffset: 200,
        );

        // Act & Assert
        expect(location1, equals(location2));
        expect(location1.hashCode, equals(location2.hashCode));
      });

      test('should not be equal when startLine differs', () {
        // Arrange
        const location1 = SymbolLocation(
          startLine: 10,
          startColumn: 5,
          endLine: 15,
          endColumn: 20,
          startOffset: 100,
          endOffset: 200,
        );
        const location2 = SymbolLocation(
          startLine: 11,
          startColumn: 5,
          endLine: 15,
          endColumn: 20,
          startOffset: 100,
          endOffset: 200,
        );

        // Act & Assert
        expect(location1, isNot(equals(location2)));
      });

      test('should not be equal when endLine differs', () {
        // Arrange
        const location1 = SymbolLocation(
          startLine: 10,
          startColumn: 5,
          endLine: 15,
          endColumn: 20,
          startOffset: 100,
          endOffset: 200,
        );
        const location2 = SymbolLocation(
          startLine: 10,
          startColumn: 5,
          endLine: 16,
          endColumn: 20,
          startOffset: 100,
          endOffset: 200,
        );

        // Act & Assert
        expect(location1, isNot(equals(location2)));
      });

      test('should not be equal when offset differs', () {
        // Arrange
        const location1 = SymbolLocation(
          startLine: 10,
          startColumn: 5,
          endLine: 15,
          endColumn: 20,
          startOffset: 100,
          endOffset: 200,
        );
        const location2 = SymbolLocation(
          startLine: 10,
          startColumn: 5,
          endLine: 15,
          endColumn: 20,
          startOffset: 100,
          endOffset: 201,
        );

        // Act & Assert
        expect(location1, isNot(equals(location2)));
      });
    });

    group('copyWith', () {
      test('should copy with new startLine', () {
        // Arrange
        const original = SymbolLocation(
          startLine: 10,
          startColumn: 5,
          endLine: 15,
          endColumn: 20,
          startOffset: 100,
          endOffset: 200,
        );

        // Act
        final copied = original.copyWith(startLine: 12);

        // Assert
        expect(copied.startLine, 12);
        expect(copied.startColumn, original.startColumn);
        expect(original.startLine, 10);
      });

      test('should copy with new endLine', () {
        // Arrange
        const original = SymbolLocation(
          startLine: 10,
          startColumn: 5,
          endLine: 15,
          endColumn: 20,
          startOffset: 100,
          endOffset: 200,
        );

        // Act
        final copied = original.copyWith(endLine: 20);

        // Assert
        expect(copied.endLine, 20);
        expect(original.endLine, 15);
      });

      test('should copy with new startOffset', () {
        // Arrange
        const original = SymbolLocation(
          startLine: 10,
          startColumn: 5,
          endLine: 15,
          endColumn: 20,
          startOffset: 100,
          endOffset: 200,
        );

        // Act
        final copied = original.copyWith(startOffset: 150);

        // Assert
        expect(copied.startOffset, 150);
        expect(original.startOffset, 100);
      });

      test('should copy multiple fields at once', () {
        // Arrange
        const original = SymbolLocation(
          startLine: 10,
          startColumn: 5,
          endLine: 15,
          endColumn: 20,
          startOffset: 100,
          endOffset: 200,
        );

        // Act
        final copied = original.copyWith(
          startLine: 12,
          endLine: 18,
          startOffset: 120,
          endOffset: 220,
        );

        // Assert
        expect(copied.startLine, 12);
        expect(copied.endLine, 18);
        expect(copied.startOffset, 120);
        expect(copied.endOffset, 220);
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON', () {
        // Arrange
        const location = SymbolLocation(
          startLine: 10,
          startColumn: 5,
          endLine: 15,
          endColumn: 20,
          startOffset: 100,
          endOffset: 200,
        );

        // Act
        final json = location.toJson();

        // Assert
        expect(json, {
          'startLine': 10,
          'startColumn': 5,
          'endLine': 15,
          'endColumn': 20,
          'startOffset': 100,
          'endOffset': 200,
        });
      });

      test('should deserialize from JSON', () {
        // Arrange
        final json = {
          'startLine': 10,
          'startColumn': 5,
          'endLine': 15,
          'endColumn': 20,
          'startOffset': 100,
          'endOffset': 200,
        };

        // Act
        final location = SymbolLocation.fromJson(json);

        // Assert
        expect(location.startLine, 10);
        expect(location.startColumn, 5);
        expect(location.endLine, 15);
        expect(location.endColumn, 20);
        expect(location.startOffset, 100);
        expect(location.endOffset, 200);
      });

      test('should round-trip through JSON', () {
        // Arrange
        const original = SymbolLocation(
          startLine: 42,
          startColumn: 15,
          endLine: 50,
          endColumn: 25,
          startOffset: 420,
          endOffset: 550,
        );

        // Act
        final json = original.toJson();
        final deserialized = SymbolLocation.fromJson(json);

        // Assert
        expect(deserialized, equals(original));
      });
    });

    group('practical examples', () {
      test('should represent a function declaration location', () {
        // Arrange & Act
        final location = SymbolLocation.fromTreeSitter(
          startRow: 10,
          startCol: 0,
          endRow: 15,
          endCol: 1,
          startByte: 250,
          endByte: 380,
        );

        // Assert
        expect(location.lineCount, 6);
        expect(location.containsLine(12), true);
        expect(location.containsOffset(300), true);
      });

      test('should represent a single line variable declaration', () {
        // Arrange & Act
        const location = SymbolLocation(
          startLine: 5,
          startColumn: 2,
          endLine: 5,
          endColumn: 20,
          startOffset: 52,
          endOffset: 70,
        );

        // Assert
        expect(location.lineCount, 1);
        expect(location.containsLine(5), true);
        expect(location.containsLine(6), false);
      });

      test('should represent a class declaration spanning multiple lines', () {
        // Arrange & Act
        const location = SymbolLocation(
          startLine: 20,
          startColumn: 0,
          endLine: 100,
          endColumn: 1,
          startOffset: 1000,
          endOffset: 5000,
        );

        // Assert
        expect(location.lineCount, 81);
        expect(location.containsLine(50), true);
        expect(location.containsOffset(3000), true);
      });

      test('should represent a method at the beginning of file', () {
        // Arrange & Act
        const location = SymbolLocation(
          startLine: 0,
          startColumn: 0,
          endLine: 5,
          endColumn: 10,
          startOffset: 0,
          endOffset: 120,
        );

        // Assert
        expect(location.startLine, 0);
        expect(location.startOffset, 0);
        expect(location.containsLine(0), true);
        expect(location.containsOffset(0), true);
      });
    });
  });
}
