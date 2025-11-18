import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugin_file_stats/src/domain/entities/file_statistics.dart';

void main() {
  group('FileStatistics - Creation', () {
    test('should create with required fields', () {
      // Arrange
      final now = DateTime.now();

      // Act
      final stats = FileStatistics(
        fileId: 'file-1',
        lines: 10,
        characters: 100,
        words: 20,
        bytes: 100,
        calculatedAt: now,
      );

      // Assert
      expect(stats.fileId, 'file-1');
      expect(stats.lines, 10);
      expect(stats.characters, 100);
      expect(stats.words, 20);
      expect(stats.bytes, 100);
      expect(stats.calculatedAt, now);
    });
  });

  group('FileStatistics - Calculate Method', () {
    test('should calculate statistics for simple content', () {
      // Arrange
      const content = 'Hello World';

      // Act
      final stats = FileStatistics.calculate('file-1', content);

      // Assert
      expect(stats.fileId, 'file-1');
      expect(stats.lines, 1);
      expect(stats.characters, 11);
      expect(stats.words, 2);
      expect(stats.bytes, 11);
    });

    test('should calculate lines correctly', () {
      // Arrange
      const content = 'Line 1\nLine 2\nLine 3';

      // Act
      final stats = FileStatistics.calculate('file-1', content);

      // Assert
      expect(stats.lines, 3);
    });

    test('should calculate characters correctly', () {
      // Arrange
      const content = 'Hello World!';

      // Act
      final stats = FileStatistics.calculate('file-1', content);

      // Assert
      expect(stats.characters, 12);
    });

    test('should calculate words correctly', () {
      // Arrange
      const content = 'The quick brown fox jumps';

      // Act
      final stats = FileStatistics.calculate('file-1', content);

      // Assert
      expect(stats.words, 5);
    });

    test('should handle empty content', () {
      // Arrange
      const content = '';

      // Act
      final stats = FileStatistics.calculate('file-1', content);

      // Assert
      expect(stats.lines, 1); // Empty string split by newline gives 1 line
      expect(stats.characters, 0);
      expect(stats.words, 0);
      expect(stats.bytes, 0);
      expect(stats.isEmpty, true);
    });

    test('should handle single word', () {
      // Arrange
      const content = 'Hello';

      // Act
      final stats = FileStatistics.calculate('file-1', content);

      // Assert
      expect(stats.words, 1);
    });

    test('should handle multiple spaces between words', () {
      // Arrange
      const content = 'Hello    World';

      // Act
      final stats = FileStatistics.calculate('file-1', content);

      // Assert
      expect(stats.words, 2);
    });

    test('should handle tabs and newlines in word counting', () {
      // Arrange
      const content = 'Hello\tWorld\nFoo\tBar';

      // Act
      final stats = FileStatistics.calculate('file-1', content);

      // Assert
      expect(stats.words, 4);
    });

    test('should handle content with only whitespace', () {
      // Arrange
      const content = '   \t\n  ';

      // Act
      final stats = FileStatistics.calculate('file-1', content);

      // Assert
      expect(stats.words, 0);
      expect(stats.isEmpty, false); // Has characters
    });

    test('should handle single line content', () {
      // Arrange
      const content = 'Single line without newline';

      // Act
      final stats = FileStatistics.calculate('file-1', content);

      // Assert
      expect(stats.lines, 1);
      expect(stats.words, 4);
    });

    test('should handle multiple consecutive newlines', () {
      // Arrange
      const content = 'Line 1\n\n\nLine 2';

      // Act
      final stats = FileStatistics.calculate('file-1', content);

      // Assert
      expect(stats.lines, 4);
    });

    test('should handle trailing newline', () {
      // Arrange
      const content = 'Line 1\nLine 2\n';

      // Act
      final stats = FileStatistics.calculate('file-1', content);

      // Assert
      expect(stats.lines, 3);
    });

    test('should set calculatedAt to current time', () {
      // Arrange
      const content = 'Test content';
      final before = DateTime.now();

      // Act
      final stats = FileStatistics.calculate('file-1', content);
      final after = DateTime.now();

      // Assert
      expect(stats.calculatedAt.isAfter(before) || stats.calculatedAt.isAtSameMomentAs(before), true);
      expect(stats.calculatedAt.isBefore(after) || stats.calculatedAt.isAtSameMomentAs(after), true);
    });
  });

  group('FileStatistics - Display Text', () {
    test('should provide readable display text', () {
      // Arrange
      final stats = FileStatistics.calculate('file-1', 'Hello World\nLine 2');

      // Act
      final displayText = stats.displayText;

      // Assert
      expect(displayText, contains('lines'));
      expect(displayText, contains('chars'));
      expect(displayText, contains('words'));
      expect(displayText, contains('2')); // lines
    });

    test('should format numbers correctly in display text', () {
      // Arrange
      final stats = FileStatistics(
        fileId: 'file-1',
        lines: 100,
        characters: 5000,
        words: 800,
        bytes: 5000,
        calculatedAt: DateTime.now(),
      );

      // Act
      final displayText = stats.displayText;

      // Assert
      expect(displayText, contains('100 lines'));
      expect(displayText, contains('5000 chars'));
      expect(displayText, contains('800 words'));
    });
  });

  group('FileStatistics - isEmpty Property', () {
    test('should be empty for zero lines and characters', () {
      // Arrange
      final stats = FileStatistics(
        fileId: 'file-1',
        lines: 0,
        characters: 0,
        words: 0,
        bytes: 0,
        calculatedAt: DateTime.now(),
      );

      // Act & Assert
      expect(stats.isEmpty, true);
    });

    test('should not be empty for content with lines', () {
      // Arrange
      final stats = FileStatistics.calculate('file-1', 'Hello');

      // Act & Assert
      expect(stats.isEmpty, false);
    });

    test('should not be empty for content with characters', () {
      // Arrange
      final stats = FileStatistics.calculate('file-1', 'a');

      // Act & Assert
      expect(stats.isEmpty, false);
    });
  });

  group('FileStatistics - JSON Serialization', () {
    test('should serialize to JSON', () {
      // Arrange
      final stats = FileStatistics(
        fileId: 'file-1',
        lines: 10,
        characters: 100,
        words: 20,
        bytes: 100,
        calculatedAt: DateTime(2024, 1, 1, 12, 0),
      );

      // Act
      final json = stats.toJson();

      // Assert
      expect(json['fileId'], 'file-1');
      expect(json['lines'], 10);
      expect(json['characters'], 100);
      expect(json['words'], 20);
      expect(json['bytes'], 100);
      expect(json['calculatedAt'], isA<String>());
    });

    test('should deserialize from JSON', () {
      // Arrange
      final json = {
        'fileId': 'file-1',
        'lines': 15,
        'characters': 150,
        'words': 30,
        'bytes': 150,
        'calculatedAt': DateTime(2024, 1, 1, 12, 0).toIso8601String(),
      };

      // Act
      final stats = FileStatistics.fromJson(json);

      // Assert
      expect(stats.fileId, 'file-1');
      expect(stats.lines, 15);
      expect(stats.characters, 150);
      expect(stats.words, 30);
      expect(stats.bytes, 150);
    });

    test('should roundtrip through JSON', () {
      // Arrange
      final original = FileStatistics.calculate(
        'file-1',
        'Hello World\nLine 2\nLine 3',
      );

      // Act
      final json = original.toJson();
      final restored = FileStatistics.fromJson(json);

      // Assert
      expect(restored.fileId, original.fileId);
      expect(restored.lines, original.lines);
      expect(restored.characters, original.characters);
      expect(restored.words, original.words);
      expect(restored.bytes, original.bytes);
    });
  });

  group('FileStatistics - Equality', () {
    test('should be equal for same values', () {
      // Arrange
      final now = DateTime(2024, 1, 1);
      final stats1 = FileStatistics(
        fileId: 'file-1',
        lines: 10,
        characters: 100,
        words: 20,
        bytes: 100,
        calculatedAt: now,
      );
      final stats2 = FileStatistics(
        fileId: 'file-1',
        lines: 10,
        characters: 100,
        words: 20,
        bytes: 100,
        calculatedAt: now,
      );

      // Act & Assert
      expect(stats1, equals(stats2));
      expect(stats1.hashCode, equals(stats2.hashCode));
    });

    test('should not be equal for different values', () {
      // Arrange
      final stats1 = FileStatistics.calculate('file-1', 'Hello');
      final stats2 = FileStatistics.calculate('file-1', 'Hello World');

      // Act & Assert
      expect(stats1, isNot(equals(stats2)));
    });
  });

  group('FileStatistics - Real Content Examples', () {
    test('should calculate for Dart code', () {
      // Arrange
      const dartCode = '''
void main() {
  print("Hello, World!");
}
''';

      // Act
      final stats = FileStatistics.calculate('main.dart', dartCode);

      // Assert
      expect(stats.lines, 4);
      expect(stats.words, greaterThan(3));
      expect(stats.characters, greaterThan(30));
    });

    test('should calculate for JSON content', () {
      // Arrange
      const jsonContent = '''
{
  "name": "test",
  "version": "1.0.0"
}
''';

      // Act
      final stats = FileStatistics.calculate('config.json', jsonContent);

      // Assert
      expect(stats.lines, 5);
      expect(stats.characters, greaterThan(30));
    });

    test('should calculate for markdown content', () {
      // Arrange
      const markdown = '''
# Title

This is a paragraph with **bold** and *italic* text.

- List item 1
- List item 2
''';

      // Act
      final stats = FileStatistics.calculate('README.md', markdown);

      // Assert
      expect(stats.lines, greaterThan(5));
      expect(stats.words, greaterThan(10));
    });

    test('should calculate for empty file', () {
      // Arrange
      const emptyContent = '';

      // Act
      final stats = FileStatistics.calculate('empty.txt', emptyContent);

      // Assert
      expect(stats.isEmpty, true);
      expect(stats.lines, 1);
      expect(stats.characters, 0);
      expect(stats.words, 0);
    });

    test('should calculate for very long line', () {
      // Arrange
      final longLine = 'word ' * 1000; // 1000 words on one line

      // Act
      final stats = FileStatistics.calculate('long.txt', longLine);

      // Assert
      expect(stats.lines, 1);
      expect(stats.words, 1000);
      expect(stats.characters, greaterThan(4000));
    });
  });

  group('FileStatistics - Use Cases', () {
    test('Use Case: Track file growth over time', () {
      // Arrange
      const initialContent = 'void main() {}';
      const updatedContent = '''
void main() {
  print("Hello");
  print("World");
}
''';

      // Act
      final initialStats = FileStatistics.calculate('file.dart', initialContent);
      final updatedStats = FileStatistics.calculate('file.dart', updatedContent);

      // Assert
      expect(updatedStats.lines, greaterThan(initialStats.lines));
      expect(updatedStats.characters, greaterThan(initialStats.characters));
      expect(updatedStats.words, greaterThan(initialStats.words));
    });

    test('Use Case: Display file info in status bar', () {
      // Arrange
      const content = 'Hello World\nLine 2\nLine 3';

      // Act
      final stats = FileStatistics.calculate('file.txt', content);
      final display = stats.displayText;

      // Assert
      expect(display, isNotEmpty);
      expect(display, contains('3 lines'));
    });

    test('Use Case: Validate file size before saving', () {
      // Arrange
      final largeContent = 'x' * 1000000; // 1MB

      // Act
      final stats = FileStatistics.calculate('large.txt', largeContent);

      // Assert
      expect(stats.bytes, 1000000);
      expect(stats.characters, 1000000);
    });

    test('Use Case: Compare statistics between files', () {
      // Arrange
      const file1Content = 'Short content';
      const file2Content = 'This is a much longer content with many more words';

      // Act
      final stats1 = FileStatistics.calculate('file1.txt', file1Content);
      final stats2 = FileStatistics.calculate('file2.txt', file2Content);

      // Assert
      expect(stats2.words, greaterThan(stats1.words));
      expect(stats2.characters, greaterThan(stats1.characters));
    });

    test('Use Case: Detect empty files', () {
      // Arrange
      const emptyFile = '';
      const nonEmptyFile = ' ';

      // Act
      final emptyStats = FileStatistics.calculate('empty.txt', emptyFile);
      final nonEmptyStats = FileStatistics.calculate('space.txt', nonEmptyFile);

      // Assert
      expect(emptyStats.isEmpty, true);
      expect(nonEmptyStats.isEmpty, false);
    });

    test('Use Case: Calculate statistics for code review', () {
      // Arrange
      const codeToReview = '''
class Calculator {
  int add(int a, int b) => a + b;
  int subtract(int a, int b) => a - b;
}
''';

      // Act
      final stats = FileStatistics.calculate('calculator.dart', codeToReview);

      // Assert
      expect(stats.lines, 5);
      expect(stats.words, greaterThan(10));
    });
  });

  group('FileStatistics - Edge Cases', () {
    test('should handle null bytes (should equal characters)', () {
      // Arrange
      const content = 'Test';

      // Act
      final stats = FileStatistics.calculate('file.txt', content);

      // Assert
      expect(stats.bytes, stats.characters);
    });

    test('should handle unicode characters', () {
      // Arrange
      const content = 'Hello 世界 🌍';

      // Act
      final stats = FileStatistics.calculate('unicode.txt', content);

      // Assert
      expect(stats.characters, greaterThan(0));
      expect(stats.words, 3);
    });

    test('should handle special whitespace characters', () {
      // Arrange
      const content = 'Word1\tWord2\rWord3\nWord4';

      // Act
      final stats = FileStatistics.calculate('whitespace.txt', content);

      // Assert
      expect(stats.words, 4);
    });

    test('should handle very large numbers', () {
      // Arrange
      final hugeContent = 'word\n' * 1000000; // 1 million lines

      // Act
      final stats = FileStatistics.calculate('huge.txt', hugeContent);

      // Assert
      expect(stats.lines, 1000000);
      expect(stats.words, 1000000);
    });

    test('should handle content with no words (only punctuation)', () {
      // Arrange
      const content = '!@#\$%^&*()';

      // Act
      final stats = FileStatistics.calculate('punct.txt', content);

      // Assert
      expect(stats.words, 1); // Punctuation counts as a word
      expect(stats.characters, 11);
    });

    test('should handle Windows-style line endings', () {
      // Arrange
      const content = 'Line 1\r\nLine 2\r\nLine 3';

      // Act
      final stats = FileStatistics.calculate('windows.txt', content);

      // Assert
      expect(stats.lines, 3);
    });

    test('should handle mixed line endings', () {
      // Arrange
      const content = 'Line 1\nLine 2\r\nLine 3\rLine 4';

      // Act
      final stats = FileStatistics.calculate('mixed.txt', content);

      // Assert
      expect(stats.lines, 4);
    });

    test('should handle file with only newlines', () {
      // Arrange
      const content = '\n\n\n';

      // Act
      final stats = FileStatistics.calculate('newlines.txt', content);

      // Assert
      expect(stats.lines, 4);
      expect(stats.words, 0);
    });
  });

  group('FileStatistics - toString', () {
    test('should have readable toString representation', () {
      // Arrange
      final stats = FileStatistics.calculate('file.txt', 'Hello World');

      // Act
      final str = stats.toString();

      // Assert
      expect(str, contains('FileStatistics'));
      expect(str, contains('fileId'));
    });
  });
}
