import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_core/src/domain/value_objects/file_content.dart';
import 'package:multi_editor_core/src/domain/value_objects/file_name.dart';
import 'package:multi_editor_core/src/domain/failures/domain_failure.dart';

void main() {
  group('FileContent', () {
    group('create', () {
      test('should create valid file content', () {
        // Arrange
        const input = 'Hello, World!';

        // Act
        final result = FileContent.create(input);

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right.value, equals(input));
      });

      test('should accept empty content', () {
        // Arrange
        const input = '';

        // Act
        final result = FileContent.create(input);

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right.value, equals(''));
      });

      test('should accept whitespace content', () {
        // Arrange
        const input = '   \n\t  ';

        // Act
        final result = FileContent.create(input);

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right.value, equals(input));
      });

      test('should accept content at max size', () {
        // Arrange
        final input = 'a' * FileContent.maxSizeInBytes;

        // Act
        final result = FileContent.create(input);

        // Assert
        expect(result.isRight, isTrue);
      });

      test('should reject content exceeding max size', () {
        // Arrange
        final input = 'a' * (FileContent.maxSizeInBytes + 1);

        // Act
        final result = FileContent.create(input);

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left.field, equals('fileContent'));
        expect(result.left.reason, contains('exceeds maximum size'));
      });

      test('should accept multiline content', () {
        // Arrange
        const input = '''
void main() {
  print('Hello, World!');
}
''';

        // Act
        final result = FileContent.create(input);

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right.value, equals(input));
      });

      test('should accept Unicode content', () {
        // Arrange
        const input = 'Привет, мир! 你好世界! 🚀';

        // Act
        final result = FileContent.create(input);

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right.value, equals(input));
      });
    });

    group('isEmpty', () {
      test('should detect empty content', () {
        // Arrange
        final content = FileContent.create('').right;

        // Act & Assert
        expect(content.isEmpty, isTrue);
      });

      test('should detect whitespace-only as empty', () {
        // Arrange
        final content = FileContent.create('   \n\t  ').right;

        // Act & Assert
        expect(content.isEmpty, isTrue);
      });

      test('should detect non-empty content', () {
        // Arrange
        final content = FileContent.create('Hello').right;

        // Act & Assert
        expect(content.isEmpty, isFalse);
      });
    });

    group('isNotEmpty', () {
      test('should detect non-empty content', () {
        // Arrange
        final content = FileContent.create('Hello').right;

        // Act & Assert
        expect(content.isNotEmpty, isTrue);
      });

      test('should detect empty content', () {
        // Arrange
        final content = FileContent.create('').right;

        // Act & Assert
        expect(content.isNotEmpty, isFalse);
      });
    });

    group('sizeInBytes', () {
      test('should calculate size for ASCII content', () {
        // Arrange
        final content = FileContent.create('Hello').right;

        // Act
        final size = content.sizeInBytes;

        // Assert
        expect(size, equals(5));
      });

      test('should return 0 for empty content', () {
        // Arrange
        final content = FileContent.create('').right;

        // Act
        final size = content.sizeInBytes;

        // Assert
        expect(size, equals(0));
      });

      test('should calculate size for multiline content', () {
        // Arrange
        final content = FileContent.create('Line1\nLine2\nLine3').right;

        // Act
        final size = content.sizeInBytes;

        // Assert
        expect(size, equals(17));
      });
    });

    group('sizeInKilobytes', () {
      test('should convert bytes to kilobytes', () {
        // Arrange
        final content = FileContent.create('a' * 2048).right;

        // Act
        final sizeKB = content.sizeInKilobytes;

        // Assert
        expect(sizeKB, equals(2));
      });

      test('should round down kilobytes', () {
        // Arrange
        final content = FileContent.create('a' * 1500).right;

        // Act
        final sizeKB = content.sizeInKilobytes;

        // Assert
        expect(sizeKB, equals(1));
      });

      test('should return 0 for content less than 1KB', () {
        // Arrange
        final content = FileContent.create('a' * 500).right;

        // Act
        final sizeKB = content.sizeInKilobytes;

        // Assert
        expect(sizeKB, equals(0));
      });
    });

    group('lineCount', () {
      test('should count single line', () {
        // Arrange
        final content = FileContent.create('Hello, World!').right;

        // Act
        final count = content.lineCount;

        // Assert
        expect(count, equals(1));
      });

      test('should count multiple lines', () {
        // Arrange
        final content = FileContent.create('Line 1\nLine 2\nLine 3').right;

        // Act
        final count = content.lineCount;

        // Assert
        expect(count, equals(3));
      });

      test('should count empty file as one line', () {
        // Arrange
        final content = FileContent.create('').right;

        // Act
        final count = content.lineCount;

        // Assert
        expect(count, equals(1));
      });

      test('should count trailing newline', () {
        // Arrange
        final content = FileContent.create('Line 1\nLine 2\n').right;

        // Act
        final count = content.lineCount;

        // Assert
        expect(count, equals(3));
      });
    });

    group('preview', () {
      test('should return full content if short', () {
        // Arrange
        const input = 'Short content';
        final content = FileContent.create(input).right;

        // Act
        final preview = content.preview;

        // Assert
        expect(preview, equals(input));
      });

      test('should truncate long content', () {
        // Arrange
        final input = 'a' * 200;
        final content = FileContent.create(input).right;

        // Act
        final preview = content.preview;

        // Assert
        expect(preview.length, equals(103)); // 100 chars + '...'
        expect(preview.endsWith('...'), isTrue);
        expect(preview.startsWith('aaa'), isTrue);
      });

      test('should preview at exactly 100 characters', () {
        // Arrange
        final input = 'a' * 100;
        final content = FileContent.create(input).right;

        // Act
        final preview = content.preview;

        // Assert
        expect(preview, equals(input));
        expect(preview.endsWith('...'), isFalse);
      });

      test('should truncate multiline content', () {
        // Arrange
        final input = 'Line\n' * 50; // 250 characters
        final content = FileContent.create(input).right;

        // Act
        final preview = content.preview;

        // Assert
        expect(preview.length, equals(103));
        expect(preview.endsWith('...'), isTrue);
      });
    });

    group('equality', () {
      test('should be equal with same content', () {
        // Arrange
        final content1 = FileContent.create('Hello').right;
        final content2 = FileContent.create('Hello').right;

        // Act & Assert
        expect(content1, equals(content2));
        expect(content1.hashCode, equals(content2.hashCode));
      });

      test('should not be equal with different content', () {
        // Arrange
        final content1 = FileContent.create('Hello').right;
        final content2 = FileContent.create('World').right;

        // Act & Assert
        expect(content1, isNot(equals(content2)));
      });
    });

    group('toString', () {
      test('should return string value', () {
        // Arrange
        const value = 'Hello, World!';
        final content = FileContent.create(value).right;

        // Act & Assert
        expect(content.toString(), equals(value));
      });
    });

    group('use cases', () {
      test('should handle typical source code file', () {
        // Arrange
        const sourceCode = '''
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Scaffold(
        body: Center(
          child: Text('Hello, World!'),
        ),
      ),
    );
  }
}
''';

        // Act
        final result = FileContent.create(sourceCode);

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right.lineCount, greaterThan(1));
        expect(result.right.sizeInBytes, greaterThan(0));
        expect(result.right.isNotEmpty, isTrue);
      });

      test('should handle empty newly created file', () {
        // Arrange
        const emptyContent = '';

        // Act
        final result = FileContent.create(emptyContent);

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right.isEmpty, isTrue);
        expect(result.right.sizeInBytes, equals(0));
        expect(result.right.lineCount, equals(1));
      });

      test('should handle JSON file', () {
        // Arrange
        const jsonContent = '''
{
  "name": "my_app",
  "version": "1.0.0",
  "dependencies": {
    "flutter": "^3.0.0"
  }
}
''';

        // Act
        final result = FileContent.create(jsonContent);

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right.value, contains('"name"'));
        expect(result.right.lineCount, equals(8));
      });

      test('should reject very large file', () {
        // Arrange
        final largeContent = 'x' * (11 * 1024 * 1024); // 11MB

        // Act
        final result = FileContent.create(largeContent);

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left.reason, contains('exceeds maximum size'));
      });
    });
  });
}

extension on Either<DomainFailure, FileContent> {
  bool get isLeft => fold((_) => true, (_) => false);
  bool get isRight => fold((_) => false, (_) => true);
  DomainFailure get left => fold((l) => l, (_) => throw StateError('Right'));
  FileContent get right => fold((_) => throw StateError('Left'), (r) => r);
}
