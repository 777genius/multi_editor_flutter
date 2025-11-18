import 'package:flutter_test/flutter_test.dart';
import 'package:editor_core/editor_core.dart';

void main() {
  group('DocumentUri', () {
    group('creation', () {
      test('should create with value', () {
        // Act
        const uri = DocumentUri('file:///path/to/file.dart');

        // Assert
        expect(uri.value, equals('file:///path/to/file.dart'));
      });

      test('should create from file path', () {
        // Act
        final uri = DocumentUri.fromFilePath('/path/to/file.dart');

        // Assert
        expect(uri.value, equals('file:///path/to/file.dart'));
      });

      test('should handle Windows paths', () {
        // Act
        final uri = DocumentUri.fromFilePath('C:\\path\\to\\file.dart');

        // Assert
        expect(uri.value, contains('C:/path/to/file.dart'));
      });

      test('should preserve file:// prefix', () {
        // Act
        final uri = DocumentUri.fromFilePath('file:///already/prefixed.dart');

        // Assert
        expect(uri.value, equals('file:///already/prefixed.dart'));
      });

      test('should normalize path separators', () {
        // Act
        final uri = DocumentUri.fromFilePath('path\\to\\file.dart');

        // Assert
        expect(uri.value, contains('/'));
        expect(uri.value, isNot(contains('\\')));
      });
    });

    group('toFilePath', () {
      test('should convert URI to file path', () {
        // Arrange
        const uri = DocumentUri('file:///path/to/file.dart');

        // Act
        final path = uri.toFilePath();

        // Assert
        expect(path, equals('path/to/file.dart'));
      });

      test('should handle path alias', () {
        // Arrange
        const uri = DocumentUri('file:///path/to/file.dart');

        // Act & Assert
        expect(uri.path, equals(uri.toFilePath()));
      });
    });

    group('fileName', () {
      test('should extract file name', () {
        // Arrange
        const uri = DocumentUri('file:///path/to/main.dart');

        // Assert
        expect(uri.fileName, equals('main.dart'));
      });

      test('should extract file name from root', () {
        // Arrange
        const uri = DocumentUri('file:///file.dart');

        // Assert
        expect(uri.fileName, equals('file.dart'));
      });

      test('should return empty for directory URI', () {
        // Arrange
        const uri = DocumentUri('file:///path/to/directory/');

        // Assert
        expect(uri.fileName, equals(''));
      });
    });

    group('directoryPath', () {
      test('should extract directory path', () {
        // Arrange
        const uri = DocumentUri('file:///path/to/file.dart');

        // Assert
        expect(uri.directoryPath, equals('path/to'));
      });

      test('should return empty for file in root', () {
        // Arrange
        const uri = DocumentUri('file:///file.dart');

        // Assert
        expect(uri.directoryPath, equals(''));
      });

      test('should handle nested directories', () {
        // Arrange
        const uri = DocumentUri('file:///a/b/c/d/file.dart');

        // Assert
        expect(uri.directoryPath, equals('a/b/c/d'));
      });
    });

    group('extension', () {
      test('should extract file extension', () {
        // Arrange
        const uri = DocumentUri('file:///path/to/file.dart');

        // Assert
        expect(uri.extension, equals('dart'));
      });

      test('should handle file without extension', () {
        // Arrange
        const uri = DocumentUri('file:///path/to/README');

        // Assert
        expect(uri.extension, equals(''));
      });

      test('should handle multiple dots', () {
        // Arrange
        const uri = DocumentUri('file:///file.test.dart');

        // Assert
        expect(uri.extension, equals('dart'));
      });

      test('should handle hidden files', () {
        // Arrange
        const uri = DocumentUri('file:///.gitignore');

        // Assert
        expect(uri.extension, equals('gitignore'));
      });
    });

    group('equality', () {
      test('should be equal with same value', () {
        const uri1 = DocumentUri('file:///path/to/file.dart');
        const uri2 = DocumentUri('file:///path/to/file.dart');

        expect(uri1, equals(uri2));
        expect(uri1.hashCode, equals(uri2.hashCode));
      });

      test('should not be equal with different paths', () {
        const uri1 = DocumentUri('file:///path/to/file1.dart');
        const uri2 = DocumentUri('file:///path/to/file2.dart');

        expect(uri1, isNot(equals(uri2)));
      });
    });

    group('use cases', () {
      test('should represent local file', () {
        final uri = DocumentUri.fromFilePath('/home/user/project/lib/main.dart');

        expect(uri.fileName, equals('main.dart'));
        expect(uri.extension, equals('dart'));
        expect(uri.directoryPath, contains('project/lib'));
      });

      test('should represent nested file', () {
        final uri = DocumentUri.fromFilePath('/project/lib/src/core/utils.dart');

        expect(uri.fileName, equals('utils.dart'));
        expect(uri.directoryPath, contains('src/core'));
      });

      test('should handle special characters in path', () {
        final uri = DocumentUri.fromFilePath('/path/with spaces/file.dart');

        expect(uri.value, contains('with spaces'));
        expect(uri.fileName, equals('file.dart'));
      });
    });

    group('path manipulation', () {
      test('should preserve path structure', () {
        const uri = DocumentUri('file:///a/b/c/file.dart');

        final path = uri.toFilePath();
        final parts = path.split('/');

        expect(parts, contains('a'));
        expect(parts, contains('b'));
        expect(parts, contains('c'));
        expect(parts.last, equals('file.dart'));
      });

      test('should handle relative-like paths', () {
        final uri = DocumentUri.fromFilePath('lib/main.dart');

        expect(uri.fileName, equals('main.dart'));
        expect(uri.extension, equals('dart'));
      });
    });

    group('immutability', () {
      test('should be immutable', () {
        const uri = DocumentUri('file:///test.dart');

        expect(uri.value, equals('file:///test.dart'));
        // Attempting to change would cause compile error
      });
    });
  });
}
