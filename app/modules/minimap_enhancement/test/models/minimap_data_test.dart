import 'package:flutter_test.dart';
import 'package:minimap_enhancement/minimap_enhancement.dart';

void main() {
  group('MinimapLine', () {
    test('should create MinimapLine from constructor', () {
      // Act
      const line = MinimapLine(
        indent: 2,
        length: 50,
        isComment: false,
        isEmpty: false,
        density: 75,
      );

      // Assert
      expect(line.indent, equals(2));
      expect(line.length, equals(50));
      expect(line.isComment, isFalse);
      expect(line.isEmpty, isFalse);
      expect(line.density, equals(75));
    });

    test('should parse MinimapLine from JSON', () {
      // Arrange
      final json = {
        'indent': 4,
        'length': 80,
        'is_comment': true,
        'is_empty': false,
        'density': 60,
      };

      // Act
      final line = MinimapLine.fromJson(json);

      // Assert
      expect(line.indent, equals(4));
      expect(line.length, equals(80));
      expect(line.isComment, isTrue);
      expect(line.isEmpty, isFalse);
      expect(line.density, equals(60));
    });

    test('should handle empty line', () {
      // Arrange
      const line = MinimapLine(
        indent: 0,
        length: 0,
        isComment: false,
        isEmpty: true,
        density: 0,
      );

      // Assert
      expect(line.isEmpty, isTrue);
      expect(line.length, equals(0));
      expect(line.density, equals(0));
    });

    test('should handle comment line', () {
      // Arrange
      const line = MinimapLine(
        indent: 0,
        length: 30,
        isComment: true,
        isEmpty: false,
        density: 50,
      );

      // Assert
      expect(line.isComment, isTrue);
      expect(line.isEmpty, isFalse);
    });

    test('should handle highly indented line', () {
      // Arrange
      const line = MinimapLine(
        indent: 12,
        length: 40,
        isComment: false,
        isEmpty: false,
        density: 70,
      );

      // Assert
      expect(line.indent, equals(12));
      expect(line.length, equals(40));
    });
  });

  group('MinimapData', () {
    test('should create MinimapData from constructor', () {
      // Arrange
      final lines = [
        const MinimapLine(
          indent: 0,
          length: 50,
          isComment: false,
          isEmpty: false,
          density: 80,
        ),
        const MinimapLine(
          indent: 2,
          length: 60,
          isComment: false,
          isEmpty: false,
          density: 75,
        ),
      ];

      // Act
      final data = MinimapData(
        lines: lines,
        totalLines: 2,
        maxLength: 60,
        fileSize: 1024,
      );

      // Assert
      expect(data.lines.length, equals(2));
      expect(data.totalLines, equals(2));
      expect(data.maxLength, equals(60));
      expect(data.fileSize, equals(1024));
    });

    test('should parse MinimapData from JSON', () {
      // Arrange
      final json = {
        'lines': [
          {
            'indent': 0,
            'length': 40,
            'is_comment': false,
            'is_empty': false,
            'density': 70,
          },
          {
            'indent': 2,
            'length': 45,
            'is_comment': true,
            'is_empty': false,
            'density': 50,
          },
        ],
        'total_lines': 2,
        'max_length': 45,
        'file_size': 2048,
      };

      // Act
      final data = MinimapData.fromJson(json);

      // Assert
      expect(data.lines.length, equals(2));
      expect(data.totalLines, equals(2));
      expect(data.maxLength, equals(45));
      expect(data.fileSize, equals(2048));
      expect(data.lines[0].indent, equals(0));
      expect(data.lines[1].isComment, isTrue);
    });

    test('should provide empty MinimapData', () {
      // Act
      const data = MinimapData.empty;

      // Assert
      expect(data.lines, isEmpty);
      expect(data.totalLines, equals(0));
      expect(data.maxLength, equals(0));
      expect(data.fileSize, equals(0));
    });

    test('should handle large file with many lines', () {
      // Arrange
      final lines = List.generate(
        1000,
        (i) => MinimapLine(
          indent: i % 8,
          length: 50 + (i % 30),
          isComment: i % 10 == 0,
          isEmpty: i % 20 == 0,
          density: 50 + (i % 50),
        ),
      );

      // Act
      final data = MinimapData(
        lines: lines,
        totalLines: 1000,
        maxLength: 80,
        fileSize: 50000,
      );

      // Assert
      expect(data.lines.length, equals(1000));
      expect(data.totalLines, equals(1000));
    });

    test('should handle file with mixed content', () {
      // Arrange
      final lines = [
        const MinimapLine(
          indent: 0,
          length: 0,
          isComment: false,
          isEmpty: true,
          density: 0,
        ),
        const MinimapLine(
          indent: 0,
          length: 30,
          isComment: true,
          isEmpty: false,
          density: 50,
        ),
        const MinimapLine(
          indent: 2,
          length: 60,
          isComment: false,
          isEmpty: false,
          density: 85,
        ),
      ];

      // Act
      final data = MinimapData(
        lines: lines,
        totalLines: 3,
        maxLength: 60,
        fileSize: 500,
      );

      // Assert
      expect(data.lines[0].isEmpty, isTrue);
      expect(data.lines[1].isComment, isTrue);
      expect(data.lines[2].density, equals(85));
    });
  });
}
