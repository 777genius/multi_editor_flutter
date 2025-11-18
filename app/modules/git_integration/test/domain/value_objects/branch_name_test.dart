import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  group('BranchName', () {
    group('creation with validation', () {
      test('should create valid branch name', () {
        // Arrange & Act
        final branchName = BranchName.create('feature/new-feature');

        // Assert
        expect(branchName.value, equals('feature/new-feature'));
      });

      test('should create simple branch name', () {
        // Arrange & Act
        final branchName = BranchName.create('main');

        // Assert
        expect(branchName.value, equals('main'));
      });

      test('should create branch with hyphens and underscores', () {
        // Arrange & Act
        final branchName = BranchName.create('feature_branch-123');

        // Assert
        expect(branchName.value, equals('feature_branch-123'));
      });
    });

    group('validation errors', () {
      test('should throw error for empty name', () {
        // Act & Assert
        expect(
          () => BranchName.create(''),
          throwsA(isA<BranchNameValidationException>()),
        );
      });

      test('should throw error for name with double dots', () {
        // Act & Assert
        expect(
          () => BranchName.create('feature..branch'),
          throwsA(isA<BranchNameValidationException>()),
        );
      });

      test('should throw error for name with spaces', () {
        // Act & Assert
        expect(
          () => BranchName.create('feature branch'),
          throwsA(isA<BranchNameValidationException>()),
        );
      });

      test('should throw error for name starting with slash', () {
        // Act & Assert
        expect(
          () => BranchName.create('/feature'),
          throwsA(isA<BranchNameValidationException>()),
        );
      });

      test('should throw error for name ending with slash', () {
        // Act & Assert
        expect(
          () => BranchName.create('feature/'),
          throwsA(isA<BranchNameValidationException>()),
        );
      });

      test('should throw error for name ending with .lock', () {
        // Act & Assert
        expect(
          () => BranchName.create('feature.lock'),
          throwsA(isA<BranchNameValidationException>()),
        );
      });

      test('should throw error for name with tilde', () {
        // Act & Assert
        expect(
          () => BranchName.create('feature~1'),
          throwsA(isA<BranchNameValidationException>()),
        );
      });

      test('should throw error for name with caret', () {
        // Act & Assert
        expect(
          () => BranchName.create('feature^2'),
          throwsA(isA<BranchNameValidationException>()),
        );
      });

      test('should throw error for name with colon', () {
        // Act & Assert
        expect(
          () => BranchName.create('feature:branch'),
          throwsA(isA<BranchNameValidationException>()),
        );
      });

      test('should throw error for name with backslash', () {
        // Act & Assert
        expect(
          () => BranchName.create('feature\\branch'),
          throwsA(isA<BranchNameValidationException>()),
        );
      });

      test('should throw error for name with asterisk', () {
        // Act & Assert
        expect(
          () => BranchName.create('feature*'),
          throwsA(isA<BranchNameValidationException>()),
        );
      });

      test('should throw error for name with question mark', () {
        // Act & Assert
        expect(
          () => BranchName.create('feature?'),
          throwsA(isA<BranchNameValidationException>()),
        );
      });

      test('should throw error for name with square bracket', () {
        // Act & Assert
        expect(
          () => BranchName.create('feature[1]'),
          throwsA(isA<BranchNameValidationException>()),
        );
      });
    });

    group('isRemote', () {
      test('should detect remote branch', () {
        // Arrange
        final branchName = BranchName.create('origin/main');

        // Act & Assert
        expect(branchName.isRemote, isTrue);
      });

      test('should detect local branch', () {
        // Arrange
        final branchName = BranchName.create('main');

        // Act & Assert
        expect(branchName.isRemote, isFalse);
      });

      test('should detect nested remote branch', () {
        // Arrange
        final branchName = BranchName.create('origin/feature/auth');

        // Act & Assert
        expect(branchName.isRemote, isTrue);
      });
    });

    group('remoteName', () {
      test('should extract remote name from remote branch', () {
        // Arrange
        final branchName = BranchName.create('origin/main');

        // Act
        final remoteName = branchName.remoteName;

        // Assert
        expect(remoteName, equals(some('origin')));
      });

      test('should return none for local branch', () {
        // Arrange
        final branchName = BranchName.create('main');

        // Act
        final remoteName = branchName.remoteName;

        // Assert
        expect(remoteName, equals(none()));
      });

      test('should extract remote name from nested branch', () {
        // Arrange
        final branchName = BranchName.create('upstream/feature/auth');

        // Act
        final remoteName = branchName.remoteName;

        // Assert
        expect(remoteName, equals(some('upstream')));
      });
    });

    group('shortName', () {
      test('should return full name for local branch', () {
        // Arrange
        final branchName = BranchName.create('main');

        // Act
        final shortName = branchName.shortName;

        // Assert
        expect(shortName, equals('main'));
      });

      test('should remove remote prefix from remote branch', () {
        // Arrange
        final branchName = BranchName.create('origin/main');

        // Act
        final shortName = branchName.shortName;

        // Assert
        expect(shortName, equals('main'));
      });

      test('should handle nested remote branch', () {
        // Arrange
        final branchName = BranchName.create('origin/feature/auth');

        // Act
        final shortName = branchName.shortName;

        // Assert
        expect(shortName, equals('feature/auth'));
      });
    });

    group('getRemoteTrackingName', () {
      test('should add remote prefix to local branch', () {
        // Arrange
        final branchName = BranchName.create('main');

        // Act
        final tracking = branchName.getRemoteTrackingName('origin');

        // Assert
        expect(tracking, equals('origin/main'));
      });

      test('should add remote prefix to feature branch', () {
        // Arrange
        final branchName = BranchName.create('feature/auth');

        // Act
        final tracking = branchName.getRemoteTrackingName('upstream');

        // Assert
        expect(tracking, equals('upstream/feature/auth'));
      });
    });

    group('isMainBranch', () {
      test('should detect main branch', () {
        // Arrange
        final branchName = BranchName.create('main');

        // Act & Assert
        expect(branchName.isMainBranch, isTrue);
      });

      test('should detect master branch', () {
        // Arrange
        final branchName = BranchName.create('master');

        // Act & Assert
        expect(branchName.isMainBranch, isTrue);
      });

      test('should not detect feature branch as main', () {
        // Arrange
        final branchName = BranchName.create('feature/auth');

        // Act & Assert
        expect(branchName.isMainBranch, isFalse);
      });

      test('should not detect develop branch as main', () {
        // Arrange
        final branchName = BranchName.create('develop');

        // Act & Assert
        expect(branchName.isMainBranch, isFalse);
      });
    });

    group('equality', () {
      test('should be equal with same value', () {
        // Arrange
        final branch1 = BranchName.create('main');
        final branch2 = BranchName.create('main');

        // Act & Assert
        expect(branch1, equals(branch2));
      });

      test('should not be equal with different values', () {
        // Arrange
        final branch1 = BranchName.create('main');
        final branch2 = BranchName.create('develop');

        // Act & Assert
        expect(branch1, isNot(equals(branch2)));
      });
    });

    group('use cases', () {
      test('should handle typical feature branch', () {
        // Arrange & Act
        final branch = BranchName.create('feature/user-authentication');

        // Assert
        expect(branch.isRemote, isFalse);
        expect(branch.isMainBranch, isFalse);
        expect(branch.shortName, equals('feature/user-authentication'));
      });

      test('should handle remote tracking branch', () {
        // Arrange & Act
        final branch = BranchName.create('origin/feature/new-ui');

        // Assert
        expect(branch.isRemote, isTrue);
        expect(branch.remoteName, equals(some('origin')));
        expect(branch.shortName, equals('feature/new-ui'));
      });

      test('should handle release branch', () {
        // Arrange & Act
        final branch = BranchName.create('release/v1.0.0');

        // Assert
        expect(branch.isMainBranch, isFalse);
        expect(branch.value, equals('release/v1.0.0'));
      });

      test('should handle hotfix branch', () {
        // Arrange & Act
        final branch = BranchName.create('hotfix/critical-bug');

        // Assert
        expect(branch.isMainBranch, isFalse);
        expect(branch.value, equals('hotfix/critical-bug'));
      });

      test('should handle upstream remote branch', () {
        // Arrange & Act
        final branch = BranchName.create('upstream/main');

        // Assert
        expect(branch.isRemote, isTrue);
        expect(branch.remoteName, equals(some('upstream')));
        expect(branch.shortName, equals('main'));
      });
    });

    group('BranchNameValidationException', () {
      test('should have descriptive string representation', () {
        // Arrange
        final exception = BranchNameValidationException('Test error');

        // Act & Assert
        expect(exception.toString(), contains('BranchNameValidationException'));
        expect(exception.toString(), contains('Test error'));
      });

      test('should preserve error message', () {
        // Arrange
        final message = 'Invalid branch name';
        final exception = BranchNameValidationException(message);

        // Act & Assert
        expect(exception.message, equals(message));
      });
    });
  });
}
