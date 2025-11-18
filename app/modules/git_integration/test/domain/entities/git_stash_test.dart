import 'package:flutter_test.dart';
import 'package:git_integration/git_integration.dart';

void main() {
  group('GitStash', () {
    late CommitHash hash;
    late BranchName branch;
    late DateTime now;
    late DateTime pastDate;

    setUp(() {
      now = DateTime.now();
      pastDate = now.subtract(const Duration(hours: 5));
      hash = CommitHash.create('a' * 40);
      branch = BranchName.create('main');
    });

    group('creation', () {
      test('should create stash with required fields', () {
        // Arrange & Act
        final stash = GitStash(
          index: 0,
          hash: hash,
          description: 'WIP on main: Add feature',
          branch: branch,
          timestamp: now,
        );

        // Assert
        expect(stash.index, equals(0));
        expect(stash.hash, equals(hash));
        expect(stash.description, equals('WIP on main: Add feature'));
        expect(stash.branch, equals(branch));
        expect(stash.timestamp, equals(now));
        expect(stash.changedFiles, isEmpty);
      });

      test('should create stash with changed files', () {
        // Arrange & Act
        final stash = GitStash(
          index: 0,
          hash: hash,
          description: 'WIP on main: Add feature',
          branch: branch,
          timestamp: now,
          changedFiles: ['lib/main.dart', 'lib/utils.dart'],
        );

        // Assert
        expect(stash.changedFiles.length, equals(2));
        expect(stash.hasFiles, isTrue);
        expect(stash.filesCount, equals(2));
      });
    });

    group('reference', () {
      test('should return correct stash reference for index 0', () {
        // Arrange
        final stash = GitStash(
          index: 0,
          hash: hash,
          description: 'WIP on main',
          branch: branch,
          timestamp: now,
        );

        // Act
        final reference = stash.reference;

        // Assert
        expect(reference, equals('stash@{0}'));
      });

      test('should return correct stash reference for index 5', () {
        // Arrange
        final stash = GitStash(
          index: 5,
          hash: hash,
          description: 'WIP on main',
          branch: branch,
          timestamp: now,
        );

        // Act
        final reference = stash.reference;

        // Assert
        expect(reference, equals('stash@{5}'));
      });
    });

    group('shortHash', () {
      test('should return 7-character short hash', () {
        // Arrange
        final testHash = CommitHash.create('abcdef1234567890' + '0' * 24);
        final stash = GitStash(
          index: 0,
          hash: testHash,
          description: 'WIP on main',
          branch: branch,
          timestamp: now,
        );

        // Act
        final shortHash = stash.shortHash;

        // Assert
        expect(shortHash, equals('abcdef1'));
        expect(shortHash.length, equals(7));
      });
    });

    group('age', () {
      test('should calculate age correctly', () {
        // Arrange
        final oldDate = now.subtract(const Duration(hours: 12));
        final stash = GitStash(
          index: 0,
          hash: hash,
          description: 'WIP on main',
          branch: branch,
          timestamp: oldDate,
        );

        // Act
        final age = stash.age;

        // Assert
        expect(age.inHours, greaterThanOrEqualTo(11));
      });

      test('should have zero age for current timestamp', () {
        // Arrange
        final stash = GitStash(
          index: 0,
          hash: hash,
          description: 'WIP on main',
          branch: branch,
          timestamp: now,
        );

        // Act
        final age = stash.age;

        // Assert
        expect(age.inSeconds, lessThan(2));
      });
    });

    group('isRecent', () {
      test('should detect recent stash within 24 hours', () {
        // Arrange
        final recentDate = now.subtract(const Duration(hours: 6));
        final stash = GitStash(
          index: 0,
          hash: hash,
          description: 'WIP on main',
          branch: branch,
          timestamp: recentDate,
        );

        // Act & Assert
        expect(stash.isRecent, isTrue);
      });

      test('should not detect old stash beyond 24 hours', () {
        // Arrange
        final oldDate = now.subtract(const Duration(days: 2));
        final stash = GitStash(
          index: 0,
          hash: hash,
          description: 'WIP on main',
          branch: branch,
          timestamp: oldDate,
        );

        // Act & Assert
        expect(stash.isRecent, isFalse);
      });
    });

    group('relativeTime', () {
      test('should display just now for very recent stash', () {
        // Arrange
        final stash = GitStash(
          index: 0,
          hash: hash,
          description: 'WIP on main',
          branch: branch,
          timestamp: now,
        );

        // Act
        final relativeTime = stash.relativeTime;

        // Assert
        expect(relativeTime, equals('just now'));
      });

      test('should display minutes ago', () {
        // Arrange
        final date = now.subtract(const Duration(minutes: 30));
        final stash = GitStash(
          index: 0,
          hash: hash,
          description: 'WIP on main',
          branch: branch,
          timestamp: date,
        );

        // Act
        final relativeTime = stash.relativeTime;

        // Assert
        expect(relativeTime, contains('minute'));
        expect(relativeTime, contains('ago'));
      });

      test('should display hours ago', () {
        // Arrange
        final date = now.subtract(const Duration(hours: 5));
        final stash = GitStash(
          index: 0,
          hash: hash,
          description: 'WIP on main',
          branch: branch,
          timestamp: date,
        );

        // Act
        final relativeTime = stash.relativeTime;

        // Assert
        expect(relativeTime, contains('hour'));
        expect(relativeTime, contains('ago'));
      });

      test('should display days ago', () {
        // Arrange
        final date = now.subtract(const Duration(days: 3));
        final stash = GitStash(
          index: 0,
          hash: hash,
          description: 'WIP on main',
          branch: branch,
          timestamp: date,
        );

        // Act
        final relativeTime = stash.relativeTime;

        // Assert
        expect(relativeTime, contains('day'));
        expect(relativeTime, contains('ago'));
      });

      test('should display months ago', () {
        // Arrange
        final date = now.subtract(const Duration(days: 45));
        final stash = GitStash(
          index: 0,
          hash: hash,
          description: 'WIP on main',
          branch: branch,
          timestamp: date,
        );

        // Act
        final relativeTime = stash.relativeTime;

        // Assert
        expect(relativeTime, contains('month'));
        expect(relativeTime, contains('ago'));
      });

      test('should display years ago', () {
        // Arrange
        final date = now.subtract(const Duration(days: 400));
        final stash = GitStash(
          index: 0,
          hash: hash,
          description: 'WIP on main',
          branch: branch,
          timestamp: date,
        );

        // Act
        final relativeTime = stash.relativeTime;

        // Assert
        expect(relativeTime, contains('year'));
        expect(relativeTime, contains('ago'));
      });

      test('should use singular for 1 hour', () {
        // Arrange
        final date = now.subtract(const Duration(hours: 1, minutes: 30));
        final stash = GitStash(
          index: 0,
          hash: hash,
          description: 'WIP on main',
          branch: branch,
          timestamp: date,
        );

        // Act
        final relativeTime = stash.relativeTime;

        // Assert
        expect(relativeTime, equals('1 hour ago'));
      });
    });

    group('hasFiles', () {
      test('should return true when has changed files', () {
        // Arrange
        final stash = GitStash(
          index: 0,
          hash: hash,
          description: 'WIP on main',
          branch: branch,
          timestamp: now,
          changedFiles: ['lib/main.dart'],
        );

        // Act & Assert
        expect(stash.hasFiles, isTrue);
      });

      test('should return false when no changed files', () {
        // Arrange
        final stash = GitStash(
          index: 0,
          hash: hash,
          description: 'WIP on main',
          branch: branch,
          timestamp: now,
        );

        // Act & Assert
        expect(stash.hasFiles, isFalse);
      });
    });

    group('filesCount', () {
      test('should return correct count of changed files', () {
        // Arrange
        final stash = GitStash(
          index: 0,
          hash: hash,
          description: 'WIP on main',
          branch: branch,
          timestamp: now,
          changedFiles: ['file1.dart', 'file2.dart', 'file3.dart'],
        );

        // Act
        final count = stash.filesCount;

        // Assert
        expect(count, equals(3));
      });

      test('should return 0 for no changed files', () {
        // Arrange
        final stash = GitStash(
          index: 0,
          hash: hash,
          description: 'WIP on main',
          branch: branch,
          timestamp: now,
        );

        // Act
        final count = stash.filesCount;

        // Assert
        expect(count, equals(0));
      });
    });

    group('displayName', () {
      test('should format WIP stash correctly', () {
        // Arrange
        final stash = GitStash(
          index: 0,
          hash: hash,
          description: 'WIP on main: Add new feature',
          branch: branch,
          timestamp: now,
        );

        // Act
        final display = stash.displayName;

        // Assert
        expect(display, contains('stash@{0}'));
        expect(display, contains('WIP on main: Add new feature'));
      });

      test('should format On stash correctly', () {
        // Arrange
        final stash = GitStash(
          index: 1,
          hash: hash,
          description: 'On feature: Working on auth',
          branch: branch,
          timestamp: now,
        );

        // Act
        final display = stash.displayName;

        // Assert
        expect(display, contains('stash@{1}'));
        expect(display, contains('On feature: Working on auth'));
      });
    });

    group('summary', () {
      test('should generate summary with all info', () {
        // Arrange
        final stash = GitStash(
          index: 0,
          hash: hash,
          description: 'WIP on main: Add new feature',
          branch: branch,
          timestamp: pastDate,
        );

        // Act
        final summary = stash.summary;

        // Assert
        expect(summary, contains('stash@{0}'));
        expect(summary, contains('main'));
        expect(summary, contains('hour'));
        expect(summary, contains('ago'));
        expect(summary, contains('WIP on main: Add new feature'));
      });

      test('should truncate long descriptions', () {
        // Arrange
        final longDesc = 'WIP on main: ' + 'Very long description ' * 10;
        final stash = GitStash(
          index: 0,
          hash: hash,
          description: longDesc,
          branch: branch,
          timestamp: now,
        );

        // Act
        final summary = stash.summary;

        // Assert
        expect(summary.length, lessThan(longDesc.length));
        expect(summary, endsWith('...'));
      });

      test('should not truncate short descriptions', () {
        // Arrange
        final shortDesc = 'WIP on main: Fix bug';
        final stash = GitStash(
          index: 0,
          hash: hash,
          description: shortDesc,
          branch: branch,
          timestamp: now,
        );

        // Act
        final summary = stash.summary;

        // Assert
        expect(summary, contains(shortDesc));
        expect(summary, isNot(endsWith('...')));
      });
    });

    group('equality', () {
      test('should be equal with same data', () {
        // Arrange
        final stash1 = GitStash(
          index: 0,
          hash: hash,
          description: 'WIP on main',
          branch: branch,
          timestamp: now,
        );

        final stash2 = GitStash(
          index: 0,
          hash: hash,
          description: 'WIP on main',
          branch: branch,
          timestamp: now,
        );

        // Act & Assert
        expect(stash1, equals(stash2));
      });

      test('should not be equal with different index', () {
        // Arrange
        final stash1 = GitStash(
          index: 0,
          hash: hash,
          description: 'WIP on main',
          branch: branch,
          timestamp: now,
        );

        final stash2 = GitStash(
          index: 1,
          hash: hash,
          description: 'WIP on main',
          branch: branch,
          timestamp: now,
        );

        // Act & Assert
        expect(stash1, isNot(equals(stash2)));
      });
    });

    group('use cases', () {
      test('should represent typical WIP stash', () {
        // Arrange & Act
        final stash = GitStash(
          index: 0,
          hash: hash,
          description: 'WIP on feature/auth: Working on login',
          branch: BranchName.create('feature/auth'),
          timestamp: now.subtract(const Duration(hours: 2)),
          changedFiles: ['lib/auth/login.dart', 'lib/auth/service.dart'],
        );

        // Assert
        expect(stash.reference, equals('stash@{0}'));
        expect(stash.hasFiles, isTrue);
        expect(stash.filesCount, equals(2));
        expect(stash.isRecent, isTrue);
      });

      test('should represent old stash', () {
        // Arrange & Act
        final oldDate = now.subtract(const Duration(days: 30));
        final stash = GitStash(
          index: 5,
          hash: hash,
          description: 'WIP on old-feature: Abandoned work',
          branch: BranchName.create('old-feature'),
          timestamp: oldDate,
        );

        // Assert
        expect(stash.isRecent, isFalse);
        expect(stash.relativeTime, contains('month'));
      });

      test('should represent stash without files info', () {
        // Arrange & Act
        final stash = GitStash(
          index: 0,
          hash: hash,
          description: 'On main: Quick save',
          branch: branch,
          timestamp: now,
        );

        // Assert
        expect(stash.hasFiles, isFalse);
        expect(stash.filesCount, equals(0));
      });
    });
  });
}
