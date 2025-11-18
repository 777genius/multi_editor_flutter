import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';

void main() {
  group('FileStatus', () {
    group('creation', () {
      test('should create unmodified status', () {
        // Arrange & Act
        const status = FileStatus.unmodified();

        // Assert
        expect(status, isA<FileStatus>());
      });

      test('should create added status', () {
        // Arrange & Act
        const status = FileStatus.added();

        // Assert
        expect(status, isA<FileStatus>());
      });

      test('should create modified status', () {
        // Arrange & Act
        const status = FileStatus.modified();

        // Assert
        expect(status, isA<FileStatus>());
      });

      test('should create deleted status', () {
        // Arrange & Act
        const status = FileStatus.deleted();

        // Assert
        expect(status, isA<FileStatus>());
      });

      test('should create renamed status', () {
        // Arrange & Act
        const status = FileStatus.renamed();

        // Assert
        expect(status, isA<FileStatus>());
      });

      test('should create copied status', () {
        // Arrange & Act
        const status = FileStatus.copied();

        // Assert
        expect(status, isA<FileStatus>());
      });

      test('should create untracked status', () {
        // Arrange & Act
        const status = FileStatus.untracked();

        // Assert
        expect(status, isA<FileStatus>());
      });

      test('should create ignored status', () {
        // Arrange & Act
        const status = FileStatus.ignored();

        // Assert
        expect(status, isA<FileStatus>());
      });

      test('should create conflicted status', () {
        // Arrange & Act
        const status = FileStatus.conflicted();

        // Assert
        expect(status, isA<FileStatus>());
      });
    });

    group('fromGitStatusCode', () {
      test('should parse added status code', () {
        // Arrange & Act
        final status = FileStatus.fromGitStatusCode('A');

        // Assert
        expect(status, equals(const FileStatus.added()));
      });

      test('should parse staged added status code', () {
        // Arrange & Act
        final status = FileStatus.fromGitStatusCode('.A');

        // Assert
        expect(status, equals(const FileStatus.added()));
      });

      test('should parse modified status code', () {
        // Arrange & Act
        final status = FileStatus.fromGitStatusCode('M');

        // Assert
        expect(status, equals(const FileStatus.modified()));
      });

      test('should parse staged modified status code', () {
        // Arrange & Act
        final status = FileStatus.fromGitStatusCode('.M');

        // Assert
        expect(status, equals(const FileStatus.modified()));
      });

      test('should parse deleted status code', () {
        // Arrange & Act
        final status = FileStatus.fromGitStatusCode('D');

        // Assert
        expect(status, equals(const FileStatus.deleted()));
      });

      test('should parse renamed status code', () {
        // Arrange & Act
        final status = FileStatus.fromGitStatusCode('R');

        // Assert
        expect(status, equals(const FileStatus.renamed()));
      });

      test('should parse copied status code', () {
        // Arrange & Act
        final status = FileStatus.fromGitStatusCode('C');

        // Assert
        expect(status, equals(const FileStatus.copied()));
      });

      test('should parse untracked status code', () {
        // Arrange & Act
        final status = FileStatus.fromGitStatusCode('?');

        // Assert
        expect(status, equals(const FileStatus.untracked()));
      });

      test('should parse double question mark untracked code', () {
        // Arrange & Act
        final status = FileStatus.fromGitStatusCode('??');

        // Assert
        expect(status, equals(const FileStatus.untracked()));
      });

      test('should parse ignored status code', () {
        // Arrange & Act
        final status = FileStatus.fromGitStatusCode('!');

        // Assert
        expect(status, equals(const FileStatus.ignored()));
      });

      test('should parse double exclamation ignored code', () {
        // Arrange & Act
        final status = FileStatus.fromGitStatusCode('!!');

        // Assert
        expect(status, equals(const FileStatus.ignored()));
      });

      test('should parse unmerged status code U', () {
        // Arrange & Act
        final status = FileStatus.fromGitStatusCode('U');

        // Assert
        expect(status, equals(const FileStatus.conflicted()));
      });

      test('should parse unmerged status code UU', () {
        // Arrange & Act
        final status = FileStatus.fromGitStatusCode('UU');

        // Assert
        expect(status, equals(const FileStatus.conflicted()));
      });

      test('should parse added by both status code AA', () {
        // Arrange & Act
        final status = FileStatus.fromGitStatusCode('AA');

        // Assert
        expect(status, equals(const FileStatus.conflicted()));
      });

      test('should parse deleted by both status code DD', () {
        // Arrange & Act
        final status = FileStatus.fromGitStatusCode('DD');

        // Assert
        expect(status, equals(const FileStatus.conflicted()));
      });

      test('should parse unknown code as unmodified', () {
        // Arrange & Act
        final status = FileStatus.fromGitStatusCode('X');

        // Assert
        expect(status, equals(const FileStatus.unmodified()));
      });
    });

    group('isTracked', () {
      test('should return true for modified files', () {
        // Arrange
        const status = FileStatus.modified();

        // Act & Assert
        expect(status.isTracked, isTrue);
      });

      test('should return true for added files', () {
        // Arrange
        const status = FileStatus.added();

        // Act & Assert
        expect(status.isTracked, isTrue);
      });

      test('should return true for deleted files', () {
        // Arrange
        const status = FileStatus.deleted();

        // Act & Assert
        expect(status.isTracked, isTrue);
      });

      test('should return false for untracked files', () {
        // Arrange
        const status = FileStatus.untracked();

        // Act & Assert
        expect(status.isTracked, isFalse);
      });

      test('should return false for ignored files', () {
        // Arrange
        const status = FileStatus.ignored();

        // Act & Assert
        expect(status.isTracked, isFalse);
      });

      test('should return true for conflicted files', () {
        // Arrange
        const status = FileStatus.conflicted();

        // Act & Assert
        expect(status.isTracked, isTrue);
      });
    });

    group('hasChanges', () {
      test('should return false for unmodified files', () {
        // Arrange
        const status = FileStatus.unmodified();

        // Act & Assert
        expect(status.hasChanges, isFalse);
      });

      test('should return true for modified files', () {
        // Arrange
        const status = FileStatus.modified();

        // Act & Assert
        expect(status.hasChanges, isTrue);
      });

      test('should return true for added files', () {
        // Arrange
        const status = FileStatus.added();

        // Act & Assert
        expect(status.hasChanges, isTrue);
      });

      test('should return true for deleted files', () {
        // Arrange
        const status = FileStatus.deleted();

        // Act & Assert
        expect(status.hasChanges, isTrue);
      });

      test('should return true for untracked files', () {
        // Arrange
        const status = FileStatus.untracked();

        // Act & Assert
        expect(status.hasChanges, isTrue);
      });

      test('should return false for ignored files', () {
        // Arrange
        const status = FileStatus.ignored();

        // Act & Assert
        expect(status.hasChanges, isFalse);
      });

      test('should return true for conflicted files', () {
        // Arrange
        const status = FileStatus.conflicted();

        // Act & Assert
        expect(status.hasChanges, isTrue);
      });
    });

    group('canBeStaged', () {
      test('should return false for unmodified files', () {
        // Arrange
        const status = FileStatus.unmodified();

        // Act & Assert
        expect(status.canBeStaged, isFalse);
      });

      test('should return false for already added files', () {
        // Arrange
        const status = FileStatus.added();

        // Act & Assert
        expect(status.canBeStaged, isFalse);
      });

      test('should return true for modified files', () {
        // Arrange
        const status = FileStatus.modified();

        // Act & Assert
        expect(status.canBeStaged, isTrue);
      });

      test('should return true for deleted files', () {
        // Arrange
        const status = FileStatus.deleted();

        // Act & Assert
        expect(status.canBeStaged, isTrue);
      });

      test('should return true for untracked files', () {
        // Arrange
        const status = FileStatus.untracked();

        // Act & Assert
        expect(status.canBeStaged, isTrue);
      });

      test('should return false for ignored files', () {
        // Arrange
        const status = FileStatus.ignored();

        // Act & Assert
        expect(status.canBeStaged, isFalse);
      });

      test('should return false for conflicted files', () {
        // Arrange
        const status = FileStatus.conflicted();

        // Act & Assert
        expect(status.canBeStaged, isFalse);
      });
    });

    group('canBeUnstaged', () {
      test('should return false for unmodified files', () {
        // Arrange
        const status = FileStatus.unmodified();

        // Act & Assert
        expect(status.canBeUnstaged, isFalse);
      });

      test('should return true for added files', () {
        // Arrange
        const status = FileStatus.added();

        // Act & Assert
        expect(status.canBeUnstaged, isTrue);
      });

      test('should return false for modified files', () {
        // Arrange
        const status = FileStatus.modified();

        // Act & Assert
        expect(status.canBeUnstaged, isFalse);
      });

      test('should return true for renamed files', () {
        // Arrange
        const status = FileStatus.renamed();

        // Act & Assert
        expect(status.canBeUnstaged, isTrue);
      });

      test('should return true for copied files', () {
        // Arrange
        const status = FileStatus.copied();

        // Act & Assert
        expect(status.canBeUnstaged, isTrue);
      });

      test('should return false for conflicted files', () {
        // Arrange
        const status = FileStatus.conflicted();

        // Act & Assert
        expect(status.canBeUnstaged, isFalse);
      });
    });

    group('needsResolution', () {
      test('should return false for unmodified files', () {
        // Arrange
        const status = FileStatus.unmodified();

        // Act & Assert
        expect(status.needsResolution, isFalse);
      });

      test('should return false for modified files', () {
        // Arrange
        const status = FileStatus.modified();

        // Act & Assert
        expect(status.needsResolution, isFalse);
      });

      test('should return true for conflicted files', () {
        // Arrange
        const status = FileStatus.conflicted();

        // Act & Assert
        expect(status.needsResolution, isTrue);
      });
    });

    group('displayName', () {
      test('should return correct display name for unmodified', () {
        // Arrange
        const status = FileStatus.unmodified();

        // Act & Assert
        expect(status.displayName, equals('Unmodified'));
      });

      test('should return correct display name for added', () {
        // Arrange
        const status = FileStatus.added();

        // Act & Assert
        expect(status.displayName, equals('Added'));
      });

      test('should return correct display name for modified', () {
        // Arrange
        const status = FileStatus.modified();

        // Act & Assert
        expect(status.displayName, equals('Modified'));
      });

      test('should return correct display name for deleted', () {
        // Arrange
        const status = FileStatus.deleted();

        // Act & Assert
        expect(status.displayName, equals('Deleted'));
      });

      test('should return correct display name for renamed', () {
        // Arrange
        const status = FileStatus.renamed();

        // Act & Assert
        expect(status.displayName, equals('Renamed'));
      });

      test('should return correct display name for copied', () {
        // Arrange
        const status = FileStatus.copied();

        // Act & Assert
        expect(status.displayName, equals('Copied'));
      });

      test('should return correct display name for untracked', () {
        // Arrange
        const status = FileStatus.untracked();

        // Act & Assert
        expect(status.displayName, equals('Untracked'));
      });

      test('should return correct display name for ignored', () {
        // Arrange
        const status = FileStatus.ignored();

        // Act & Assert
        expect(status.displayName, equals('Ignored'));
      });

      test('should return correct display name for conflicted', () {
        // Arrange
        const status = FileStatus.conflicted();

        // Act & Assert
        expect(status.displayName, equals('Conflicted'));
      });
    });

    group('shortDisplay', () {
      test('should return correct short display for modified', () {
        // Arrange
        const status = FileStatus.modified();

        // Act & Assert
        expect(status.shortDisplay, equals('M'));
      });

      test('should return correct short display for added', () {
        // Arrange
        const status = FileStatus.added();

        // Act & Assert
        expect(status.shortDisplay, equals('A'));
      });

      test('should return correct short display for deleted', () {
        // Arrange
        const status = FileStatus.deleted();

        // Act & Assert
        expect(status.shortDisplay, equals('D'));
      });

      test('should return correct short display for untracked', () {
        // Arrange
        const status = FileStatus.untracked();

        // Act & Assert
        expect(status.shortDisplay, equals('?'));
      });

      test('should return correct short display for conflicted', () {
        // Arrange
        const status = FileStatus.conflicted();

        // Act & Assert
        expect(status.shortDisplay, equals('C'));
      });
    });

    group('equality', () {
      test('should be equal with same type', () {
        // Arrange
        const status1 = FileStatus.modified();
        const status2 = FileStatus.modified();

        // Act & Assert
        expect(status1, equals(status2));
      });

      test('should not be equal with different types', () {
        // Arrange
        const status1 = FileStatus.modified();
        const status2 = FileStatus.added();

        // Act & Assert
        expect(status1, isNot(equals(status2)));
      });
    });

    group('use cases', () {
      test('should handle new file workflow', () {
        // Arrange - File is untracked
        const status = FileStatus.untracked();

        // Assert
        expect(status.isTracked, isFalse);
        expect(status.hasChanges, isTrue);
        expect(status.canBeStaged, isTrue);
        expect(status.displayName, equals('Untracked'));
      });

      test('should handle modified file workflow', () {
        // Arrange - File is modified
        const status = FileStatus.modified();

        // Assert
        expect(status.isTracked, isTrue);
        expect(status.hasChanges, isTrue);
        expect(status.canBeStaged, isTrue);
        expect(status.canBeUnstaged, isFalse);
      });

      test('should handle staged file workflow', () {
        // Arrange - File is added (staged)
        const status = FileStatus.added();

        // Assert
        expect(status.isTracked, isTrue);
        expect(status.hasChanges, isTrue);
        expect(status.canBeStaged, isFalse);
        expect(status.canBeUnstaged, isTrue);
      });

      test('should handle conflicted file workflow', () {
        // Arrange - File has conflicts
        const status = FileStatus.conflicted();

        // Assert
        expect(status.isTracked, isTrue);
        expect(status.hasChanges, isTrue);
        expect(status.canBeStaged, isFalse);
        expect(status.needsResolution, isTrue);
      });

      test('should handle deleted file workflow', () {
        // Arrange - File is deleted
        const status = FileStatus.deleted();

        // Assert
        expect(status.isTracked, isTrue);
        expect(status.hasChanges, isTrue);
        expect(status.canBeStaged, isTrue);
      });

      test('should handle ignored file workflow', () {
        // Arrange - File is ignored
        const status = FileStatus.ignored();

        // Assert
        expect(status.isTracked, isFalse);
        expect(status.hasChanges, isFalse);
        expect(status.canBeStaged, isFalse);
      });
    });
  });
}
