import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  group('GitCommit', () {
    late GitAuthor author;
    late GitAuthor committer;
    late CommitHash hash;
    late CommitMessage message;
    late DateTime now;

    setUp(() {
      now = DateTime.now();
      author = const GitAuthor(
        name: 'John Doe',
        email: 'john@example.com',
      );
      committer = const GitAuthor(
        name: 'John Doe',
        email: 'john@example.com',
      );
      hash = CommitHash.create('a' * 40);
      message = const CommitMessage(
        subject: 'Add new feature',
        body: some('Detailed description of the feature'),
      );
    });

    group('creation', () {
      test('should create commit with required fields', () {
        // Act
        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: now,
          commitDate: now,
        );

        // Assert
        expect(commit.hash, equals(hash));
        expect(commit.author, equals(author));
        expect(commit.message, equals(message));
        expect(commit.changedFiles, isEmpty);
        expect(commit.insertions, equals(0));
        expect(commit.deletions, equals(0));
      });

      test('should create commit with parent hash', () {
        final parentHash = CommitHash.create('b' * 40);

        final commit = GitCommit(
          hash: hash,
          parentHash: some(parentHash),
          author: author,
          committer: committer,
          message: message,
          authorDate: now,
          commitDate: now,
        );

        expect(commit.parentHash, equals(some(parentHash)));
        expect(commit.isInitialCommit, isFalse);
      });

      test('should create commit with changes', () {
        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: now,
          commitDate: now,
          changedFiles: ['file1.dart', 'file2.dart'],
          insertions: 50,
          deletions: 20,
        );

        expect(commit.changedFiles.length, equals(2));
        expect(commit.insertions, equals(50));
        expect(commit.deletions, equals(20));
      });

      test('should create commit with tags', () {
        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: now,
          commitDate: now,
          tags: ['v1.0.0', 'release'],
        );

        expect(commit.tags.length, equals(2));
        expect(commit.hasTags, isTrue);
      });
    });

    group('isMergeCommit', () {
      test('should detect merge commits by message', () {
        final mergeMessage = const CommitMessage(
          subject: 'Merge branch feature into main',
        );

        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: mergeMessage,
          authorDate: now,
          commitDate: now,
        );

        expect(commit.isMergeCommit, isTrue);
      });

      test('should detect merge commits case-insensitive', () {
        final mergeMessage = const CommitMessage(
          subject: 'MERGE pull request #123',
        );

        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: mergeMessage,
          authorDate: now,
          commitDate: now,
        );

        expect(commit.isMergeCommit, isTrue);
      });

      test('should not detect regular commits as merge', () {
        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: now,
          commitDate: now,
        );

        expect(commit.isMergeCommit, isFalse);
      });
    });

    group('isInitialCommit', () {
      test('should detect initial commit with no parent', () {
        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: now,
          commitDate: now,
        );

        expect(commit.isInitialCommit, isTrue);
      });

      test('should not detect commit with parent as initial', () {
        final parentHash = CommitHash.create('b' * 40);

        final commit = GitCommit(
          hash: hash,
          parentHash: some(parentHash),
          author: author,
          committer: committer,
          message: message,
          authorDate: now,
          commitDate: now,
        );

        expect(commit.isInitialCommit, isFalse);
      });
    });

    group('hash display', () {
      test('should return short hash (7 chars)', () {
        final testHash = CommitHash.create('abcdef1234567890' + '0' * 24);

        final commit = GitCommit(
          hash: testHash,
          author: author,
          committer: committer,
          message: message,
          authorDate: now,
          commitDate: now,
        );

        expect(commit.shortHash, equals('abcdef1'));
      });
    });

    group('message properties', () {
      test('should return subject', () {
        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: now,
          commitDate: now,
        );

        expect(commit.subject, equals('Add new feature'));
      });

      test('should return body when present', () {
        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: now,
          commitDate: now,
        );

        expect(commit.body, equals(some('Detailed description of the feature')));
      });

      test('should return none for empty body', () {
        final simpleMessage = const CommitMessage(subject: 'Simple commit');

        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: simpleMessage,
          authorDate: now,
          commitDate: now,
        );

        expect(commit.body, equals(none()));
      });
    });

    group('changes statistics', () {
      test('should calculate total changes', () {
        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: now,
          commitDate: now,
          insertions: 100,
          deletions: 50,
        );

        expect(commit.totalChanges, equals(150));
      });

      test('should count files changed', () {
        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: now,
          commitDate: now,
          changedFiles: ['file1.dart', 'file2.dart', 'file3.dart'],
        );

        expect(commit.filesChanged, equals(3));
      });

      test('should handle no changes', () {
        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: now,
          commitDate: now,
        );

        expect(commit.totalChanges, equals(0));
        expect(commit.filesChanged, equals(0));
      });
    });

    group('tags', () {
      test('should detect when has tags', () {
        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: now,
          commitDate: now,
          tags: ['v1.0.0'],
        );

        expect(commit.hasTags, isTrue);
      });

      test('should detect when has no tags', () {
        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: now,
          commitDate: now,
        );

        expect(commit.hasTags, isFalse);
      });
    });

    group('age and recency', () {
      test('should calculate age', () {
        final pastDate = now.subtract(const Duration(hours: 12));

        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: pastDate,
          commitDate: pastDate,
        );

        expect(commit.age.inHours, greaterThanOrEqualTo(12));
      });

      test('should detect recent commit (within 24 hours)', () {
        final recentDate = now.subtract(const Duration(hours: 6));

        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: recentDate,
          commitDate: recentDate,
        );

        expect(commit.isRecent, isTrue);
      });

      test('should detect old commit (beyond 24 hours)', () {
        final oldDate = now.subtract(const Duration(days: 2));

        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: oldDate,
          commitDate: oldDate,
        );

        expect(commit.isRecent, isFalse);
      });
    });

    group('ageDisplay', () {
      test('should display "just now" for very recent commits', () {
        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: now,
          commitDate: now,
        );

        expect(commit.ageDisplay, equals('just now'));
      });

      test('should display minutes ago', () {
        final pastDate = now.subtract(const Duration(minutes: 30));

        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: pastDate,
          commitDate: pastDate,
        );

        expect(commit.ageDisplay, contains('minutes ago'));
      });

      test('should display hours ago', () {
        final pastDate = now.subtract(const Duration(hours: 5));

        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: pastDate,
          commitDate: pastDate,
        );

        expect(commit.ageDisplay, contains('hours ago'));
      });

      test('should display days ago', () {
        final pastDate = now.subtract(const Duration(days: 3));

        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: pastDate,
          commitDate: pastDate,
        );

        expect(commit.ageDisplay, contains('days ago'));
      });

      test('should display months ago', () {
        final pastDate = now.subtract(const Duration(days: 45));

        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: pastDate,
          commitDate: pastDate,
        );

        expect(commit.ageDisplay, contains('month'));
      });

      test('should display singular for 1 hour', () {
        final pastDate = now.subtract(const Duration(hours: 1));

        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: pastDate,
          commitDate: pastDate,
        );

        expect(commit.ageDisplay, equals('1 hour ago'));
      });
    });

    group('authorship', () {
      test('should detect same author and committer', () {
        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: author,
          message: message,
          authorDate: now,
          commitDate: now,
        );

        expect(commit.isSingleAuthor, isTrue);
      });

      test('should detect different author and committer', () {
        final differentCommitter = const GitAuthor(
          name: 'Jane Smith',
          email: 'jane@example.com',
        );

        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: differentCommitter,
          message: message,
          authorDate: now,
          commitDate: now,
        );

        expect(commit.isSingleAuthor, isFalse);
      });
    });

    group('summary', () {
      test('should generate commit summary', () {
        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: now,
          commitDate: now,
        );

        final summary = commit.summary;

        expect(summary, contains(commit.shortHash));
        expect(summary, contains(author.name));
        expect(summary, contains('Add new feature'));
      });

      test('should truncate long messages in summary', () {
        final longMessage = const CommitMessage(
          subject: 'This is a very long commit message that should be truncated for display purposes',
        );

        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: longMessage,
          authorDate: now,
          commitDate: now,
        );

        final summary = commit.summary;

        expect(summary, isNotNull);
        expect(summary, contains(commit.shortHash));
      });
    });

    group('equality', () {
      test('should be equal with same data', () {
        final commit1 = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: now,
          commitDate: now,
        );

        final commit2 = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: now,
          commitDate: now,
        );

        expect(commit1, equals(commit2));
      });

      test('should not be equal with different hash', () {
        final hash2 = CommitHash.create('b' * 40);

        final commit1 = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: now,
          commitDate: now,
        );

        final commit2 = GitCommit(
          hash: hash2,
          author: author,
          committer: committer,
          message: message,
          authorDate: now,
          commitDate: now,
        );

        expect(commit1, isNot(equals(commit2)));
      });
    });

    group('copyWith', () {
      test('should copy with new tags', () {
        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: now,
          commitDate: now,
        );

        final copied = commit.copyWith(tags: ['v2.0.0']);

        expect(copied.tags, equals(['v2.0.0']));
        expect(commit.tags, isEmpty);
      });

      test('should copy with new message', () {
        final newMessage = const CommitMessage(subject: 'Updated message');

        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: committer,
          message: message,
          authorDate: now,
          commitDate: now,
        );

        final copied = commit.copyWith(message: newMessage);

        expect(copied.message.subject, equals('Updated message'));
        expect(commit.message.subject, equals('Add new feature'));
      });
    });

    group('use cases', () {
      test('should represent typical feature commit', () {
        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: author,
          message: const CommitMessage(
            subject: 'feat: add user authentication',
            body: some('Implemented OAuth2 login flow'),
          ),
          authorDate: now,
          commitDate: now,
          changedFiles: ['auth.dart', 'login_page.dart'],
          insertions: 150,
          deletions: 20,
        );

        expect(commit.isInitialCommit, isTrue);
        expect(commit.isMergeCommit, isFalse);
        expect(commit.filesChanged, equals(2));
        expect(commit.totalChanges, equals(170));
      });

      test('should represent merge commit', () {
        final commit = GitCommit(
          hash: hash,
          parentHash: some(CommitHash.create('b' * 40)),
          author: author,
          committer: author,
          message: const CommitMessage(
            subject: 'Merge branch feature/auth into main',
          ),
          authorDate: now,
          commitDate: now,
        );

        expect(commit.isMergeCommit, isTrue);
        expect(commit.isInitialCommit, isFalse);
      });

      test('should represent tagged release commit', () {
        final commit = GitCommit(
          hash: hash,
          author: author,
          committer: author,
          message: const CommitMessage(subject: 'Release version 1.0.0'),
          authorDate: now,
          commitDate: now,
          tags: ['v1.0.0', 'release'],
        );

        expect(commit.hasTags, isTrue);
        expect(commit.tags.length, equals(2));
      });
    });
  });
}
