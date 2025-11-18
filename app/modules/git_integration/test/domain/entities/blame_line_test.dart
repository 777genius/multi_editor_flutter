import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';

void main() {
  group('BlameLine', () {
    late CommitHash hash;
    late GitAuthor author;
    late DateTime now;

    setUp(() {
      now = DateTime.now();
      hash = CommitHash.create('a' * 40);
      author = const GitAuthor(
        name: 'John Doe',
        email: 'john@example.com',
      );
    });

    group('creation', () {
      test('should create blame line with all fields', () {
        // Arrange & Act
        final line = BlameLine(
          lineNumber: 10,
          content: 'final result = compute();',
          commitHash: hash,
          author: author,
          timestamp: now,
          commitMessage: 'Add computation logic',
        );

        // Assert
        expect(line.lineNumber, equals(10));
        expect(line.content, equals('final result = compute();'));
        expect(line.commitHash, equals(hash));
        expect(line.author, equals(author));
        expect(line.timestamp, equals(now));
        expect(line.commitMessage, equals('Add computation logic'));
      });
    });

    group('shortHash', () {
      test('should return 7-character short hash', () {
        // Arrange
        final testHash = CommitHash.create('abcdef1234567890' + '0' * 24);
        final line = BlameLine(
          lineNumber: 1,
          content: 'code',
          commitHash: testHash,
          author: author,
          timestamp: now,
          commitMessage: 'message',
        );

        // Act
        final shortHash = line.shortHash;

        // Assert
        expect(shortHash, equals('abcdef1'));
        expect(shortHash.length, equals(7));
      });
    });

    group('age', () {
      test('should calculate age correctly', () {
        // Arrange
        final oldDate = now.subtract(const Duration(hours: 12));
        final line = BlameLine(
          lineNumber: 1,
          content: 'code',
          commitHash: hash,
          author: author,
          timestamp: oldDate,
          commitMessage: 'message',
        );

        // Act
        final age = line.age;

        // Assert
        expect(age.inHours, greaterThanOrEqualTo(11));
      });

      test('should have zero age for current timestamp', () {
        // Arrange
        final line = BlameLine(
          lineNumber: 1,
          content: 'code',
          commitHash: hash,
          author: author,
          timestamp: now,
          commitMessage: 'message',
        );

        // Act
        final age = line.age;

        // Assert
        expect(age.inSeconds, lessThan(2));
      });
    });

    group('isRecent', () {
      test('should detect recent line within 7 days', () {
        // Arrange
        final recentDate = now.subtract(const Duration(days: 3));
        final line = BlameLine(
          lineNumber: 1,
          content: 'code',
          commitHash: hash,
          author: author,
          timestamp: recentDate,
          commitMessage: 'message',
        );

        // Act & Assert
        expect(line.isRecent, isTrue);
      });

      test('should not detect old line beyond 7 days', () {
        // Arrange
        final oldDate = now.subtract(const Duration(days: 10));
        final line = BlameLine(
          lineNumber: 1,
          content: 'code',
          commitHash: hash,
          author: author,
          timestamp: oldDate,
          commitMessage: 'message',
        );

        // Act & Assert
        expect(line.isRecent, isFalse);
      });
    });

    group('isOld', () {
      test('should detect old line beyond 1 year', () {
        // Arrange
        final oldDate = now.subtract(const Duration(days: 400));
        final line = BlameLine(
          lineNumber: 1,
          content: 'code',
          commitHash: hash,
          author: author,
          timestamp: oldDate,
          commitMessage: 'message',
        );

        // Act & Assert
        expect(line.isOld, isTrue);
      });

      test('should not detect recent line as old', () {
        // Arrange
        final recentDate = now.subtract(const Duration(days: 100));
        final line = BlameLine(
          lineNumber: 1,
          content: 'code',
          commitHash: hash,
          author: author,
          timestamp: recentDate,
          commitMessage: 'message',
        );

        // Act & Assert
        expect(line.isOld, isFalse);
      });
    });

    group('relativeTime', () {
      test('should display just now for very recent line', () {
        // Arrange
        final line = BlameLine(
          lineNumber: 1,
          content: 'code',
          commitHash: hash,
          author: author,
          timestamp: now,
          commitMessage: 'message',
        );

        // Act
        final relativeTime = line.relativeTime;

        // Assert
        expect(relativeTime, equals('just now'));
      });

      test('should display minutes ago', () {
        // Arrange
        final date = now.subtract(const Duration(minutes: 30));
        final line = BlameLine(
          lineNumber: 1,
          content: 'code',
          commitHash: hash,
          author: author,
          timestamp: date,
          commitMessage: 'message',
        );

        // Act
        final relativeTime = line.relativeTime;

        // Assert
        expect(relativeTime, contains('minute'));
        expect(relativeTime, contains('ago'));
      });

      test('should display hours ago', () {
        // Arrange
        final date = now.subtract(const Duration(hours: 5));
        final line = BlameLine(
          lineNumber: 1,
          content: 'code',
          commitHash: hash,
          author: author,
          timestamp: date,
          commitMessage: 'message',
        );

        // Act
        final relativeTime = line.relativeTime;

        // Assert
        expect(relativeTime, contains('hour'));
        expect(relativeTime, contains('ago'));
      });

      test('should display days ago', () {
        // Arrange
        final date = now.subtract(const Duration(days: 3));
        final line = BlameLine(
          lineNumber: 1,
          content: 'code',
          commitHash: hash,
          author: author,
          timestamp: date,
          commitMessage: 'message',
        );

        // Act
        final relativeTime = line.relativeTime;

        // Assert
        expect(relativeTime, contains('day'));
        expect(relativeTime, contains('ago'));
      });

      test('should display months ago', () {
        // Arrange
        final date = now.subtract(const Duration(days: 45));
        final line = BlameLine(
          lineNumber: 1,
          content: 'code',
          commitHash: hash,
          author: author,
          timestamp: date,
          commitMessage: 'message',
        );

        // Act
        final relativeTime = line.relativeTime;

        // Assert
        expect(relativeTime, contains('month'));
        expect(relativeTime, contains('ago'));
      });

      test('should display years ago', () {
        // Arrange
        final date = now.subtract(const Duration(days: 400));
        final line = BlameLine(
          lineNumber: 1,
          content: 'code',
          commitHash: hash,
          author: author,
          timestamp: date,
          commitMessage: 'message',
        );

        // Act
        final relativeTime = line.relativeTime;

        // Assert
        expect(relativeTime, contains('year'));
        expect(relativeTime, contains('ago'));
      });
    });

    group('formatCompact', () {
      test('should format compact display', () {
        // Arrange
        final date = now.subtract(const Duration(hours: 2));
        final line = BlameLine(
          lineNumber: 1,
          content: 'code',
          commitHash: hash,
          author: author,
          timestamp: date,
          commitMessage: 'message',
        );

        // Act
        final formatted = line.formatCompact();

        // Assert
        expect(formatted, contains(line.shortHash));
        expect(formatted, contains('John Doe'));
        expect(formatted, contains('ago'));
      });
    });

    group('formatFull', () {
      test('should format full display with all details', () {
        // Arrange
        final line = BlameLine(
          lineNumber: 1,
          content: 'code',
          commitHash: hash,
          author: author,
          timestamp: now,
          commitMessage: 'Add new feature\n\nDetailed description',
        );

        // Act
        final formatted = line.formatFull();

        // Assert
        expect(formatted, contains(line.shortHash));
        expect(formatted, contains('john@example.com'));
        expect(formatted, contains('Add new feature'));
        expect(formatted, isNot(contains('Detailed description')));
      });

      test('should only include first line of commit message', () {
        // Arrange
        final multilineMessage = 'First line\nSecond line\nThird line';
        final line = BlameLine(
          lineNumber: 1,
          content: 'code',
          commitHash: hash,
          author: author,
          timestamp: now,
          commitMessage: multilineMessage,
        );

        // Act
        final formatted = line.formatFull();

        // Assert
        expect(formatted, contains('First line'));
        expect(formatted, isNot(contains('Second line')));
      });
    });

    group('colorIntensity', () {
      test('should return 1.0 for today', () {
        // Arrange
        final line = BlameLine(
          lineNumber: 1,
          content: 'code',
          commitHash: hash,
          author: author,
          timestamp: now,
          commitMessage: 'message',
        );

        // Act
        final intensity = line.colorIntensity;

        // Assert
        expect(intensity, equals(1.0));
      });

      test('should return 0.9 for less than 7 days', () {
        // Arrange
        final date = now.subtract(const Duration(days: 3));
        final line = BlameLine(
          lineNumber: 1,
          content: 'code',
          commitHash: hash,
          author: author,
          timestamp: date,
          commitMessage: 'message',
        );

        // Act
        final intensity = line.colorIntensity;

        // Assert
        expect(intensity, equals(0.9));
      });

      test('should return 0.7 for less than 30 days', () {
        // Arrange
        final date = now.subtract(const Duration(days: 15));
        final line = BlameLine(
          lineNumber: 1,
          content: 'code',
          commitHash: hash,
          author: author,
          timestamp: date,
          commitMessage: 'message',
        );

        // Act
        final intensity = line.colorIntensity;

        // Assert
        expect(intensity, equals(0.7));
      });

      test('should return 0.5 for less than 90 days', () {
        // Arrange
        final date = now.subtract(const Duration(days: 60));
        final line = BlameLine(
          lineNumber: 1,
          content: 'code',
          commitHash: hash,
          author: author,
          timestamp: date,
          commitMessage: 'message',
        );

        // Act
        final intensity = line.colorIntensity;

        // Assert
        expect(intensity, equals(0.5));
      });

      test('should return 0.3 for less than 365 days', () {
        // Arrange
        final date = now.subtract(const Duration(days: 200));
        final line = BlameLine(
          lineNumber: 1,
          content: 'code',
          commitHash: hash,
          author: author,
          timestamp: date,
          commitMessage: 'message',
        );

        // Act
        final intensity = line.colorIntensity;

        // Assert
        expect(intensity, equals(0.3));
      });

      test('should return 0.1 for over 365 days', () {
        // Arrange
        final date = now.subtract(const Duration(days: 400));
        final line = BlameLine(
          lineNumber: 1,
          content: 'code',
          commitHash: hash,
          author: author,
          timestamp: date,
          commitMessage: 'message',
        );

        // Act
        final intensity = line.colorIntensity;

        // Assert
        expect(intensity, equals(0.1));
      });
    });

    group('equality', () {
      test('should be equal with same data', () {
        // Arrange
        final line1 = BlameLine(
          lineNumber: 1,
          content: 'code',
          commitHash: hash,
          author: author,
          timestamp: now,
          commitMessage: 'message',
        );

        final line2 = BlameLine(
          lineNumber: 1,
          content: 'code',
          commitHash: hash,
          author: author,
          timestamp: now,
          commitMessage: 'message',
        );

        // Act & Assert
        expect(line1, equals(line2));
      });

      test('should not be equal with different line numbers', () {
        // Arrange
        final line1 = BlameLine(
          lineNumber: 1,
          content: 'code',
          commitHash: hash,
          author: author,
          timestamp: now,
          commitMessage: 'message',
        );

        final line2 = BlameLine(
          lineNumber: 2,
          content: 'code',
          commitHash: hash,
          author: author,
          timestamp: now,
          commitMessage: 'message',
        );

        // Act & Assert
        expect(line1, isNot(equals(line2)));
      });
    });

    group('use cases', () {
      test('should represent recently modified line', () {
        // Arrange & Act
        final recentDate = now.subtract(const Duration(hours: 2));
        final line = BlameLine(
          lineNumber: 42,
          content: 'final value = compute();',
          commitHash: hash,
          author: author,
          timestamp: recentDate,
          commitMessage: 'refactor: improve computation',
        );

        // Assert
        expect(line.isRecent, isTrue);
        expect(line.isOld, isFalse);
        expect(line.colorIntensity, equals(1.0));
      });

      test('should represent old legacy code', () {
        // Arrange & Act
        final oldDate = now.subtract(const Duration(days: 730));
        final oldAuthor = const GitAuthor(
          name: 'Legacy Developer',
          email: 'legacy@example.com',
        );
        final line = BlameLine(
          lineNumber: 10,
          content: '// TODO: refactor this',
          commitHash: hash,
          author: oldAuthor,
          timestamp: oldDate,
          commitMessage: 'Initial commit',
        );

        // Assert
        expect(line.isRecent, isFalse);
        expect(line.isOld, isTrue);
        expect(line.colorIntensity, equals(0.1));
      });

      test('should handle multiline commit in formatting', () {
        // Arrange & Act
        final line = BlameLine(
          lineNumber: 1,
          content: 'code',
          commitHash: hash,
          author: author,
          timestamp: now,
          commitMessage: 'feat: add authentication\n\nImplemented OAuth2',
        );

        // Assert
        final formatted = line.formatFull();
        expect(formatted, contains('feat: add authentication'));
        expect(formatted, isNot(contains('Implemented OAuth2')));
      });
    });
  });
}
