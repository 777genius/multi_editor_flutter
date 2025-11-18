import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'dart:io';

void main() {
  group('RepositoryPath', () {
    group('creation with validation', () {
      test('should create valid repository path', () {
        // Arrange & Act
        final path = RepositoryPath.create('/home/user/project');

        // Assert
        expect(path.path, isNotEmpty);
      });

      test('should normalize path', () {
        // Arrange & Act
        final path = RepositoryPath.create('/home/user//project/');

        // Assert
        expect(path.path, isNot(contains('//')));
      });

      test('should create path from relative path', () {
        // Arrange & Act
        final path = RepositoryPath.create('./project');

        // Assert
        expect(path.path, isNotEmpty);
      });

      test('should create path from current directory', () {
        // Arrange & Act
        final path = RepositoryPath.create('.');

        // Assert
        expect(path.path, isNotEmpty);
      });
    });

    group('validation errors', () {
      test('should throw error for empty path', () {
        // Act & Assert
        expect(
          () => RepositoryPath.create(''),
          throwsA(isA<RepositoryPathValidationException>()),
        );
      });
    });

    group('gitDirPath', () {
      test('should return correct .git directory path', () {
        // Arrange
        final path = RepositoryPath.create('/home/user/project');

        // Act
        final gitDir = path.gitDirPath;

        // Assert
        expect(gitDir, endsWith('.git'));
        expect(gitDir, contains('project'));
      });

      test('should handle path with trailing slash', () {
        // Arrange
        final path = RepositoryPath.create('/home/user/project/');

        // Act
        final gitDir = path.gitDirPath;

        // Assert
        expect(gitDir, endsWith('.git'));
      });
    });

    group('absolute', () {
      test('should return absolute path', () {
        // Arrange
        final path = RepositoryPath.create('.');

        // Act
        final absolute = path.absolute;

        // Assert
        expect(absolute, isNotEmpty);
        // Absolute paths start with / on Unix or drive letter on Windows
        expect(
          absolute.startsWith('/') || absolute.contains(':'),
          isTrue,
        );
      });

      test('should keep absolute path unchanged', () {
        // Arrange
        final path = RepositoryPath.create('/home/user/project');

        // Act
        final absolute = path.absolute;

        // Assert
        expect(absolute, contains('project'));
      });
    });

    group('name', () {
      test('should extract directory name', () {
        // Arrange
        final path = RepositoryPath.create('/home/user/my-project');

        // Act
        final name = path.name;

        // Assert
        expect(name, equals('my-project'));
      });

      test('should extract name from nested path', () {
        // Arrange
        final path = RepositoryPath.create('/home/user/projects/my-app');

        // Act
        final name = path.name;

        // Assert
        expect(name, equals('my-app'));
      });

      test('should handle single directory name', () {
        // Arrange
        final path = RepositoryPath.create('project');

        // Act
        final name = path.name;

        // Assert
        expect(name, equals('project'));
      });
    });

    group('exists', () {
      test('should return false for non-existent repository', () async {
        // Arrange
        final path = RepositoryPath.create('/non/existent/path');

        // Act
        final exists = await path.exists();

        // Assert
        expect(exists, isFalse);
      });

      test('should return false when no .git directory exists', () async {
        // Arrange
        final tempDir = Directory.systemTemp.createTempSync('repo_test');
        final path = RepositoryPath.create(tempDir.path);

        try {
          // Act
          final exists = await path.exists();

          // Assert
          expect(exists, isFalse);
        } finally {
          // Cleanup
          tempDir.deleteSync(recursive: true);
        }
      });

      test('should return true when .git directory exists', () async {
        // Arrange
        final tempDir = Directory.systemTemp.createTempSync('repo_test');
        final gitDir = Directory('${tempDir.path}/.git');
        await gitDir.create();
        final path = RepositoryPath.create(tempDir.path);

        try {
          // Act
          final exists = await path.exists();

          // Assert
          expect(exists, isTrue);
        } finally {
          // Cleanup
          tempDir.deleteSync(recursive: true);
        }
      });
    });

    group('equality', () {
      test('should be equal with same normalized path', () {
        // Arrange
        final path1 = RepositoryPath.create('/home/user/project');
        final path2 = RepositoryPath.create('/home/user/project');

        // Act & Assert
        expect(path1, equals(path2));
      });

      test('should be equal after normalization', () {
        // Arrange
        final path1 = RepositoryPath.create('/home/user/project');
        final path2 = RepositoryPath.create('/home/user//project/');

        // Act & Assert
        expect(path1, equals(path2));
      });

      test('should not be equal with different paths', () {
        // Arrange
        final path1 = RepositoryPath.create('/home/user/project1');
        final path2 = RepositoryPath.create('/home/user/project2');

        // Act & Assert
        expect(path1, isNot(equals(path2)));
      });
    });

    group('use cases', () {
      test('should handle typical project path', () {
        // Arrange & Act
        final path = RepositoryPath.create('/home/user/my-flutter-app');

        // Assert
        expect(path.name, equals('my-flutter-app'));
        expect(path.gitDirPath, contains('.git'));
      });

      test('should handle workspace subdirectory', () {
        // Arrange & Act
        final path = RepositoryPath.create('/workspace/projects/app/backend');

        // Assert
        expect(path.name, equals('backend'));
        expect(path.path, contains('workspace'));
      });

      test('should handle user home directory project', () {
        // Arrange & Act
        final path = RepositoryPath.create('~/projects/my-app');

        // Assert
        expect(path.path, isNotEmpty);
      });

      test('should handle temporary directory', () async {
        // Arrange
        final tempDir = Directory.systemTemp.createTempSync('git_test');

        try {
          // Act
          final path = RepositoryPath.create(tempDir.path);

          // Assert
          expect(path.path, isNotEmpty);
          expect(path.name, startsWith('git_test'));
        } finally {
          // Cleanup
          tempDir.deleteSync(recursive: true);
        }
      });

      test('should handle Windows-style path on Windows', () {
        // Arrange & Act
        // This test will work on both Unix and Windows
        final path = RepositoryPath.create(r'C:\Users\user\project');

        // Assert
        expect(path.path, isNotEmpty);
      });
    });

    group('RepositoryPathValidationException', () {
      test('should have descriptive string representation', () {
        // Arrange
        final exception = RepositoryPathValidationException('Test error');

        // Act & Assert
        expect(
          exception.toString(),
          contains('RepositoryPathValidationException'),
        );
        expect(exception.toString(), contains('Test error'));
      });

      test('should preserve error message', () {
        // Arrange
        final message = 'Invalid path';
        final exception = RepositoryPathValidationException(message);

        // Act & Assert
        expect(exception.message, equals(message));
      });
    });
  });
}
