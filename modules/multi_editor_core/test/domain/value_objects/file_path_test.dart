import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_core/src/domain/value_objects/file_path.dart';
import 'package:multi_editor_core/src/domain/failures/domain_failure.dart';

void main() {
  group('FilePath', () {
    group('create', () {
      test('should create valid file path', () {
        // Arrange
        const input = '/home/user/document.txt';

        // Act
        final result = FilePath.create(input);

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right.value, equals(input));
      });

      test('should trim whitespace', () {
        // Arrange
        const input = '  /home/user/file.dart  ';

        // Act
        final result = FilePath.create(input);

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right.value, equals('/home/user/file.dart'));
      });

      test('should reject empty path', () {
        // Arrange
        const input = '';

        // Act
        final result = FilePath.create(input);

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left.field, equals('filePath'));
        expect(result.left.reason, contains('cannot be empty'));
      });

      test('should reject whitespace-only path', () {
        // Arrange
        const input = '   ';

        // Act
        final result = FilePath.create(input);

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left.field, equals('filePath'));
      });

      test('should reject path exceeding max length', () {
        // Arrange
        final input = 'a' * (FilePath.maxLength + 1);

        // Act
        final result = FilePath.create(input);

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left.field, equals('filePath'));
        expect(result.left.reason, contains('cannot exceed'));
      });

      test('should accept path at max length', () {
        // Arrange
        final input = '/' + 'a' * (FilePath.maxLength - 1);

        // Act
        final result = FilePath.create(input);

        // Assert
        expect(result.isRight, isTrue);
      });

      test('should reject path with control characters', () {
        // Arrange
        const input = '/home/user/file\x00.txt';

        // Act
        final result = FilePath.create(input);

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left.reason, contains('invalid control characters'));
      });

      test('should reject path with parent directory reference', () {
        // Arrange
        const input = '/home/user/../etc/passwd';

        // Act
        final result = FilePath.create(input);

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left.reason, contains('..'));
      });

      test('should reject path with consecutive slashes', () {
        // Arrange
        const input = '/home//user/file.txt';

        // Act
        final result = FilePath.create(input);

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left.reason, contains('consecutive slashes'));
      });

      test('should reject path with platform-specific invalid characters', () {
        // Arrange
        const input = '/home/user/file<>.txt';

        // Act
        final result = FilePath.create(input);

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left.reason, contains('invalid characters'));
      });

      test('should allow Windows drive path', () {
        // Arrange
        const input = 'C:\\Users\\Documents\\file.txt';

        // Act
        final result = FilePath.create(input);

        // Assert
        expect(result.isRight, isTrue);
      });

      test('should support Unicode characters', () {
        // Arrange
        const input = '/home/пользователь/文件.txt';

        // Act
        final result = FilePath.create(input);

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right.value, equals(input));
      });
    });

    group('segments', () {
      test('should split path into segments', () {
        // Arrange
        final path = FilePath.create('/home/user/documents/file.txt').right;

        // Act
        final segments = path.segments;

        // Assert
        expect(segments, equals(['home', 'user', 'documents', 'file.txt']));
      });

      test('should filter out empty segments', () {
        // Arrange
        final path = FilePath.create('/home/user').right;

        // Act
        final segments = path.segments;

        // Assert
        expect(segments, equals(['home', 'user']));
        expect(segments, isNot(contains('')));
      });
    });

    group('fileName', () {
      test('should extract file name from path', () {
        // Arrange
        final path = FilePath.create('/home/user/documents/file.txt').right;

        // Act
        final fileName = path.fileName;

        // Assert
        expect(fileName, equals('file.txt'));
      });

      test('should return empty string for empty path', () {
        // Arrange
        final path = FilePath.create('/').right;

        // Act
        final fileName = path.fileName;

        // Assert
        expect(fileName, equals(''));
      });
    });

    group('directory', () {
      test('should extract directory from path', () {
        // Arrange
        final path = FilePath.create('/home/user/documents/file.txt').right;

        // Act
        final directory = path.directory;

        // Assert
        expect(directory, equals('/home/user/documents'));
      });

      test('should return root for single-level path', () {
        // Arrange
        final path = FilePath.create('/file.txt').right;

        // Act
        final directory = path.directory;

        // Assert
        expect(directory, equals('/'));
      });

      test('should return root for root path', () {
        // Arrange
        final path = FilePath.create('/').right;

        // Act
        final directory = path.directory;

        // Assert
        expect(directory, equals('/'));
      });
    });

    group('depth', () {
      test('should calculate path depth', () {
        // Arrange
        final path = FilePath.create('/home/user/documents/file.txt').right;

        // Act
        final depth = path.depth;

        // Assert
        expect(depth, equals(4));
      });

      test('should return 0 for root path', () {
        // Arrange
        final path = FilePath.create('/').right;

        // Act
        final depth = path.depth;

        // Assert
        expect(depth, equals(0));
      });
    });

    group('isRoot', () {
      test('should detect root path with slash', () {
        // Arrange
        final path = FilePath.create('/').right;

        // Act & Assert
        expect(path.isRoot, isTrue);
      });

      test('should not detect non-root as root', () {
        // Arrange
        final path = FilePath.create('/home').right;

        // Act & Assert
        expect(path.isRoot, isFalse);
      });
    });

    group('parent', () {
      test('should get parent directory', () {
        // Arrange
        final path = FilePath.create('/home/user/file.txt').right;

        // Act
        final parent = path.parent;

        // Assert
        expect(parent.value, equals('/home/user'));
      });

      test('should get parent of parent', () {
        // Arrange
        final path = FilePath.create('/home/user/documents').right;

        // Act
        final parent = path.parent.parent;

        // Assert
        expect(parent.value, equals('/home'));
      });

      test('should return root for single-level path', () {
        // Arrange
        final path = FilePath.create('/home').right;

        // Act
        final parent = path.parent;

        // Assert
        expect(parent.value, equals('/'));
      });

      test('should return itself for root path', () {
        // Arrange
        final path = FilePath.create('/').right;

        // Act
        final parent = path.parent;

        // Assert
        expect(parent.value, equals('/'));
        expect(parent, equals(path));
      });
    });

    group('join', () {
      test('should join segment to path', () {
        // Arrange
        final path = FilePath.create('/home/user').right;

        // Act
        final joined = path.join('documents');

        // Assert
        expect(joined.value, equals('/home/user/documents'));
      });

      test('should join segment to root', () {
        // Arrange
        final path = FilePath.create('/').right;

        // Act
        final joined = path.join('home');

        // Assert
        expect(joined.value, equals('/home'));
      });
    });

    group('equality', () {
      test('should be equal with same value', () {
        // Arrange
        final path1 = FilePath.create('/home/user/file.txt').right;
        final path2 = FilePath.create('/home/user/file.txt').right;

        // Act & Assert
        expect(path1, equals(path2));
        expect(path1.hashCode, equals(path2.hashCode));
      });

      test('should not be equal with different values', () {
        // Arrange
        final path1 = FilePath.create('/home/user/file1.txt').right;
        final path2 = FilePath.create('/home/user/file2.txt').right;

        // Act & Assert
        expect(path1, isNot(equals(path2)));
      });
    });

    group('toString', () {
      test('should return string value', () {
        // Arrange
        const value = '/home/user/file.txt';
        final path = FilePath.create(value).right;

        // Act & Assert
        expect(path.toString(), equals(value));
      });
    });

    group('use cases', () {
      test('should traverse up directory tree until root', () {
        // Arrange
        var current = FilePath.create('/home/user/documents/file.txt').right;
        final visited = <String>[];

        // Act
        while (!current.isRoot) {
          visited.add(current.value);
          current = current.parent;
        }

        // Assert
        expect(visited, equals([
          '/home/user/documents/file.txt',
          '/home/user/documents',
          '/home/user',
          '/home',
        ]));
      });

      test('should build nested path', () {
        // Arrange
        var path = FilePath.create('/').right;

        // Act
        path = path.join('home');
        path = path.join('user');
        path = path.join('documents');

        // Assert
        expect(path.value, equals('/home/user/documents'));
      });
    });
  });
}

extension on Either<DomainFailure, FilePath> {
  bool get isLeft => fold((_) => true, (_) => false);
  bool get isRight => fold((_) => false, (_) => true);
  DomainFailure get left => fold((l) => l, (_) => throw StateError('Right'));
  FilePath get right => fold((_) => throw StateError('Left'), (r) => r);
}
