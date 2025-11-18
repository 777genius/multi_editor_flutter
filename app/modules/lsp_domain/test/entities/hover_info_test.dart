import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';

void main() {
  group('HoverInfo', () {
    group('creation', () {
      test('should create hover info with contents', () {
        // Act
        const hoverInfo = HoverInfo(
          contents: 'void print(Object? object)',
        );

        // Assert
        expect(hoverInfo.contents, equals('void print(Object? object)'));
        expect(hoverInfo.range, isNull);
      });

      test('should create hover info with range', () {
        // Arrange
        const range = TextSelection(
          start: CursorPosition(line: 5, column: 10),
          end: CursorPosition(line: 5, column: 15),
        );

        // Act
        const hoverInfo = HoverInfo(
          contents: 'Documentation',
          range: range,
        );

        // Assert
        expect(hoverInfo.contents, equals('Documentation'));
        expect(hoverInfo.range, equals(range));
      });

      test('should create empty hover info', () {
        // Act
        const hoverInfo = HoverInfo.empty;

        // Assert
        expect(hoverInfo.contents, equals(''));
        expect(hoverInfo.isEmpty, isTrue);
      });
    });

    group('isEmpty', () {
      test('should return true for empty string', () {
        const hoverInfo = HoverInfo(contents: '');

        expect(hoverInfo.isEmpty, isTrue);
        expect(hoverInfo.isNotEmpty, isFalse);
      });

      test('should return true for whitespace only', () {
        const hoverInfo = HoverInfo(contents: '   \n\t  ');

        expect(hoverInfo.isEmpty, isTrue);
        expect(hoverInfo.isNotEmpty, isFalse);
      });

      test('should return false for non-empty content', () {
        const hoverInfo = HoverInfo(contents: 'Documentation');

        expect(hoverInfo.isEmpty, isFalse);
        expect(hoverInfo.isNotEmpty, isTrue);
      });

      test('should return false for content with surrounding whitespace', () {
        const hoverInfo = HoverInfo(contents: '  Documentation  ');

        expect(hoverInfo.isEmpty, isFalse);
        expect(hoverInfo.isNotEmpty, isTrue);
      });
    });

    group('isNotEmpty', () {
      test('should return true for non-empty content', () {
        const hoverInfo = HoverInfo(contents: 'Some text');

        expect(hoverInfo.isNotEmpty, isTrue);
      });

      test('should return false for empty content', () {
        const hoverInfo = HoverInfo(contents: '');

        expect(hoverInfo.isNotEmpty, isFalse);
      });
    });

    group('equality', () {
      test('should be equal with same contents', () {
        const info1 = HoverInfo(contents: 'Documentation');
        const info2 = HoverInfo(contents: 'Documentation');

        expect(info1, equals(info2));
        expect(info1.hashCode, equals(info2.hashCode));
      });

      test('should be equal with same contents and range', () {
        const range = TextSelection(
          start: CursorPosition(line: 1, column: 0),
          end: CursorPosition(line: 1, column: 5),
        );

        const info1 = HoverInfo(contents: 'Doc', range: range);
        const info2 = HoverInfo(contents: 'Doc', range: range);

        expect(info1, equals(info2));
      });

      test('should not be equal with different contents', () {
        const info1 = HoverInfo(contents: 'Doc1');
        const info2 = HoverInfo(contents: 'Doc2');

        expect(info1, isNot(equals(info2)));
      });

      test('should not be equal with different range', () {
        const info1 = HoverInfo(
          contents: 'Doc',
          range: TextSelection(
            start: CursorPosition(line: 1, column: 0),
            end: CursorPosition(line: 1, column: 5),
          ),
        );

        const info2 = HoverInfo(
          contents: 'Doc',
          range: TextSelection(
            start: CursorPosition(line: 2, column: 0),
            end: CursorPosition(line: 2, column: 5),
          ),
        );

        expect(info1, isNot(equals(info2)));
      });
    });

    group('copyWith', () {
      test('should copy with new contents', () {
        const info = HoverInfo(contents: 'Original');

        final copied = info.copyWith(contents: 'Updated');

        expect(copied.contents, equals('Updated'));
        expect(info.contents, equals('Original'));
      });

      test('should copy with new range', () {
        const info = HoverInfo(contents: 'Doc');
        const newRange = TextSelection(
          start: CursorPosition(line: 5, column: 0),
          end: CursorPosition(line: 5, column: 10),
        );

        final copied = info.copyWith(range: newRange);

        expect(copied.range, equals(newRange));
        expect(info.range, isNull);
      });
    });

    group('markdown content', () {
      test('should handle markdown formatted content', () {
        const markdownContent = '''
```dart
void print(Object? object)
```

Prints an object to the console.
''';

        const hoverInfo = HoverInfo(contents: markdownContent);

        expect(hoverInfo.isNotEmpty, isTrue);
        expect(hoverInfo.contents, contains('```dart'));
        expect(hoverInfo.contents, contains('void print'));
      });

      test('should handle multi-line documentation', () {
        const multiLine = '''
First line
Second line
Third line
''';

        const hoverInfo = HoverInfo(contents: multiLine);

        expect(hoverInfo.isNotEmpty, isTrue);
        expect(hoverInfo.contents, contains('\n'));
      });
    });
  });
}
