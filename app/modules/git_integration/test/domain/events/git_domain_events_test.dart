import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:git_integration/src/domain/events/git_domain_events.dart';
import 'package:git_integration/src/domain/value_objects/repository_path.dart';
import 'package:git_integration/src/domain/value_objects/branch_name.dart';
import 'package:git_integration/src/domain/value_objects/remote_name.dart';
import 'package:git_integration/src/domain/value_objects/commit_hash.dart';
import 'package:git_integration/src/domain/value_objects/commit_message.dart';
import 'package:git_integration/src/domain/value_objects/git_author.dart';
import 'package:git_integration/src/domain/entities/git_commit.dart';
import 'package:git_integration/src/domain/entities/git_branch.dart';
import 'package:git_integration/src/domain/entities/merge_conflict.dart';

void main() {
  group('Git Domain Events', () {
    late RepositoryPath testPath;
    late DateTime testTime;

    setUp(() {
      testPath = RepositoryPath('/test/repo');
      testTime = DateTime(2024, 1, 15, 10, 30, 0);
    });

    group('RepositoryInitializedDomainEvent', () {
      test('should create event with required fields', () {
        // Arrange & Act
        final event = RepositoryInitializedDomainEvent(
          path: testPath,
          occurredAt: testTime,
        );

        // Assert
        expect(event.path, equals(testPath));
        expect(event.occurredAt, equals(testTime));
      });

      test('should be a GitDomainEvent', () {
        // Arrange & Act
        final event = RepositoryInitializedDomainEvent(
          path: testPath,
          occurredAt: testTime,
        );

        // Assert
        expect(event, isA<GitDomainEvent>());
      });

      test('should support equality comparison', () {
        // Arrange
        final event1 = RepositoryInitializedDomainEvent(
          path: testPath,
          occurredAt: testTime,
        );
        final event2 = RepositoryInitializedDomainEvent(
          path: testPath,
          occurredAt: testTime,
        );

        // Act & Assert
        expect(event1, equals(event2));
      });

      test('should not be equal with different paths', () {
        // Arrange
        final event1 = RepositoryInitializedDomainEvent(
          path: testPath,
          occurredAt: testTime,
        );
        final event2 = RepositoryInitializedDomainEvent(
          path: RepositoryPath('/different/repo'),
          occurredAt: testTime,
        );

        // Act & Assert
        expect(event1, isNot(equals(event2)));
      });
    });

    group('RepositoryOpenedDomainEvent', () {
      test('should create event with required fields', () {
        // Arrange & Act
        final event = RepositoryOpenedDomainEvent(
          path: testPath,
          occurredAt: testTime,
        );

        // Assert
        expect(event.path, equals(testPath));
        expect(event.occurredAt, equals(testTime));
      });

      test('should be a GitDomainEvent', () {
        // Arrange & Act
        final event = RepositoryOpenedDomainEvent(
          path: testPath,
          occurredAt: testTime,
        );

        // Assert
        expect(event, isA<GitDomainEvent>());
      });

      test('should support equality comparison', () {
        // Arrange
        final event1 = RepositoryOpenedDomainEvent(
          path: testPath,
          occurredAt: testTime,
        );
        final event2 = RepositoryOpenedDomainEvent(
          path: testPath,
          occurredAt: testTime,
        );

        // Act & Assert
        expect(event1, equals(event2));
      });
    });

    group('FilesStagedDomainEvent', () {
      test('should create event with file paths', () {
        // Arrange
        final filePaths = ['file1.dart', 'file2.dart', 'file3.dart'];

        // Act
        final event = FilesStagedDomainEvent(
          path: testPath,
          filePaths: filePaths,
          occurredAt: testTime,
        );

        // Assert
        expect(event.path, equals(testPath));
        expect(event.filePaths, equals(filePaths));
        expect(event.filePaths.length, 3);
        expect(event.occurredAt, equals(testTime));
      });

      test('should handle empty file paths list', () {
        // Arrange & Act
        final event = FilesStagedDomainEvent(
          path: testPath,
          filePaths: [],
          occurredAt: testTime,
        );

        // Assert
        expect(event.filePaths, isEmpty);
      });

      test('should handle single file', () {
        // Arrange & Act
        final event = FilesStagedDomainEvent(
          path: testPath,
          filePaths: ['single.dart'],
          occurredAt: testTime,
        );

        // Assert
        expect(event.filePaths.length, 1);
        expect(event.filePaths.first, 'single.dart');
      });

      test('should be a GitDomainEvent', () {
        // Arrange & Act
        final event = FilesStagedDomainEvent(
          path: testPath,
          filePaths: ['file.dart'],
          occurredAt: testTime,
        );

        // Assert
        expect(event, isA<GitDomainEvent>());
      });
    });

    group('FilesUnstagedDomainEvent', () {
      test('should create event with file paths', () {
        // Arrange
        final filePaths = ['unstaged1.dart', 'unstaged2.dart'];

        // Act
        final event = FilesUnstagedDomainEvent(
          path: testPath,
          filePaths: filePaths,
          occurredAt: testTime,
        );

        // Assert
        expect(event.path, equals(testPath));
        expect(event.filePaths, equals(filePaths));
        expect(event.occurredAt, equals(testTime));
      });

      test('should handle empty file paths', () {
        // Arrange & Act
        final event = FilesUnstagedDomainEvent(
          path: testPath,
          filePaths: [],
          occurredAt: testTime,
        );

        // Assert
        expect(event.filePaths, isEmpty);
      });
    });

    group('CommitCreatedDomainEvent', () {
      test('should create event with commit', () {
        // Arrange
        final commit = GitCommit(
          hash: CommitHash.create('a' * 40),
          author: const GitAuthor(name: 'John Doe', email: 'john@test.com'),
          committer: const GitAuthor(name: 'John Doe', email: 'john@test.com'),
          message: CommitMessage.create('Test commit'),
          authorDate: testTime,
          commitDate: testTime,
        );

        // Act
        final event = CommitCreatedDomainEvent(
          path: testPath,
          commit: commit,
          occurredAt: testTime,
        );

        // Assert
        expect(event.path, equals(testPath));
        expect(event.commit, equals(commit));
        expect(event.occurredAt, equals(testTime));
      });

      test('should preserve commit details', () {
        // Arrange
        final commit = GitCommit(
          hash: CommitHash.create('abc123def456' + '0' * 28),
          author: const GitAuthor(name: 'Jane Doe', email: 'jane@test.com'),
          committer: const GitAuthor(name: 'Jane Doe', email: 'jane@test.com'),
          message: CommitMessage.create('Add feature'),
          authorDate: testTime,
          commitDate: testTime,
        );

        // Act
        final event = CommitCreatedDomainEvent(
          path: testPath,
          commit: commit,
          occurredAt: testTime,
        );

        // Assert
        expect(event.commit.author.name, 'Jane Doe');
        expect(event.commit.message.subject, 'Add feature');
      });

      test('should be a GitDomainEvent', () {
        // Arrange
        final commit = GitCommit(
          hash: CommitHash.create('a' * 40),
          author: const GitAuthor(name: 'Test', email: 'test@test.com'),
          committer: const GitAuthor(name: 'Test', email: 'test@test.com'),
          message: CommitMessage.create('Test'),
          authorDate: testTime,
          commitDate: testTime,
        );

        // Act
        final event = CommitCreatedDomainEvent(
          path: testPath,
          commit: commit,
          occurredAt: testTime,
        );

        // Assert
        expect(event, isA<GitDomainEvent>());
      });
    });

    group('BranchCreatedDomainEvent', () {
      test('should create event with branch', () {
        // Arrange
        final branch = GitBranch(
          name: BranchName.create('feature/new-feature'),
          isCurrentBranch: false,
          commitHash: CommitHash.create('a' * 40),
          upstream: none(),
        );

        // Act
        final event = BranchCreatedDomainEvent(
          path: testPath,
          branch: branch,
          occurredAt: testTime,
        );

        // Assert
        expect(event.path, equals(testPath));
        expect(event.branch, equals(branch));
        expect(event.occurredAt, equals(testTime));
      });

      test('should preserve branch details', () {
        // Arrange
        final branch = GitBranch(
          name: BranchName.create('bugfix/issue-123'),
          isCurrentBranch: true,
          commitHash: CommitHash.create('b' * 40),
          upstream: some('origin/bugfix/issue-123'),
        );

        // Act
        final event = BranchCreatedDomainEvent(
          path: testPath,
          branch: branch,
          occurredAt: testTime,
        );

        // Assert
        expect(event.branch.name.value, 'bugfix/issue-123');
        expect(event.branch.isCurrentBranch, true);
      });
    });

    group('BranchDeletedDomainEvent', () {
      test('should create event with branch name', () {
        // Arrange
        final branchName = BranchName.create('old-feature');

        // Act
        final event = BranchDeletedDomainEvent(
          path: testPath,
          branchName: branchName,
          occurredAt: testTime,
        );

        // Assert
        expect(event.path, equals(testPath));
        expect(event.branchName, equals(branchName));
        expect(event.occurredAt, equals(testTime));
      });

      test('should handle various branch name formats', () {
        // Arrange
        final branchName = BranchName.create('feature/complex-name-123');

        // Act
        final event = BranchDeletedDomainEvent(
          path: testPath,
          branchName: branchName,
          occurredAt: testTime,
        );

        // Assert
        expect(event.branchName.value, 'feature/complex-name-123');
      });
    });

    group('BranchCheckedOutDomainEvent', () {
      test('should create event with branch name', () {
        // Arrange
        final branch = BranchName.create('develop');

        // Act
        final event = BranchCheckedOutDomainEvent(
          path: testPath,
          branch: branch,
          occurredAt: testTime,
        );

        // Assert
        expect(event.path, equals(testPath));
        expect(event.branch, equals(branch));
        expect(event.occurredAt, equals(testTime));
      });

      test('should handle main branch', () {
        // Arrange
        final branch = BranchName.create('main');

        // Act
        final event = BranchCheckedOutDomainEvent(
          path: testPath,
          branch: branch,
          occurredAt: testTime,
        );

        // Assert
        expect(event.branch.value, 'main');
      });
    });

    group('ChangesPushedDomainEvent', () {
      test('should create event with push details', () {
        // Arrange
        final remote = RemoteName.create('origin');
        final branch = BranchName.create('main');

        // Act
        final event = ChangesPushedDomainEvent(
          path: testPath,
          remote: remote,
          branch: branch,
          commitCount: 3,
          occurredAt: testTime,
        );

        // Assert
        expect(event.path, equals(testPath));
        expect(event.remote, equals(remote));
        expect(event.branch, equals(branch));
        expect(event.commitCount, 3);
        expect(event.occurredAt, equals(testTime));
      });

      test('should handle zero commit count', () {
        // Arrange
        final remote = RemoteName.create('origin');
        final branch = BranchName.create('main');

        // Act
        final event = ChangesPushedDomainEvent(
          path: testPath,
          remote: remote,
          branch: branch,
          commitCount: 0,
          occurredAt: testTime,
        );

        // Assert
        expect(event.commitCount, 0);
      });

      test('should handle large commit count', () {
        // Arrange
        final remote = RemoteName.create('origin');
        final branch = BranchName.create('feature');

        // Act
        final event = ChangesPushedDomainEvent(
          path: testPath,
          remote: remote,
          branch: branch,
          commitCount: 100,
          occurredAt: testTime,
        );

        // Assert
        expect(event.commitCount, 100);
      });
    });

    group('ChangesPulledDomainEvent', () {
      test('should create event with pull details', () {
        // Arrange
        final remote = RemoteName.create('origin');
        final branch = BranchName.create('main');
        final changedFiles = ['file1.dart', 'file2.dart'];

        // Act
        final event = ChangesPulledDomainEvent(
          path: testPath,
          remote: remote,
          branch: branch,
          commitCount: 5,
          changedFiles: changedFiles,
          occurredAt: testTime,
        );

        // Assert
        expect(event.path, equals(testPath));
        expect(event.remote, equals(remote));
        expect(event.branch, equals(branch));
        expect(event.commitCount, 5);
        expect(event.changedFiles, equals(changedFiles));
        expect(event.occurredAt, equals(testTime));
      });

      test('should handle empty changed files list', () {
        // Arrange
        final remote = RemoteName.create('origin');
        final branch = BranchName.create('main');

        // Act
        final event = ChangesPulledDomainEvent(
          path: testPath,
          remote: remote,
          branch: branch,
          commitCount: 1,
          changedFiles: [],
          occurredAt: testTime,
        );

        // Assert
        expect(event.changedFiles, isEmpty);
      });

      test('should handle many changed files', () {
        // Arrange
        final remote = RemoteName.create('origin');
        final branch = BranchName.create('develop');
        final changedFiles = List.generate(50, (i) => 'file$i.dart');

        // Act
        final event = ChangesPulledDomainEvent(
          path: testPath,
          remote: remote,
          branch: branch,
          commitCount: 10,
          changedFiles: changedFiles,
          occurredAt: testTime,
        );

        // Assert
        expect(event.changedFiles.length, 50);
      });
    });

    group('MergeConflictDomainEvent', () {
      test('should create event with conflict details', () {
        // Arrange
        final conflict = MergeConflict(
          filePath: 'lib/main.dart',
          status: ConflictStatus.both_modified,
          content: none(),
          markers: none(),
        );

        // Act
        final event = MergeConflictDomainEvent(
          path: testPath,
          conflict: conflict,
          occurredAt: testTime,
        );

        // Assert
        expect(event.path, equals(testPath));
        expect(event.conflict, equals(conflict));
        expect(event.occurredAt, equals(testTime));
      });

      test('should preserve conflict details', () {
        // Arrange
        final conflict = MergeConflict(
          filePath: 'src/feature.dart',
          status: ConflictStatus.both_added,
          content: some('conflicted content'),
          markers: none(),
        );

        // Act
        final event = MergeConflictDomainEvent(
          path: testPath,
          conflict: conflict,
          occurredAt: testTime,
        );

        // Assert
        expect(event.conflict.filePath, 'src/feature.dart');
        expect(event.conflict.status, ConflictStatus.both_added);
      });

      test('should be a GitDomainEvent', () {
        // Arrange
        final conflict = MergeConflict(
          filePath: 'test.dart',
          status: ConflictStatus.both_modified,
          content: none(),
          markers: none(),
        );

        // Act
        final event = MergeConflictDomainEvent(
          path: testPath,
          conflict: conflict,
          occurredAt: testTime,
        );

        // Assert
        expect(event, isA<GitDomainEvent>());
      });
    });

    group('ConflictResolvedDomainEvent', () {
      test('should create event with file path', () {
        // Arrange
        const filePath = 'lib/resolved.dart';

        // Act
        final event = ConflictResolvedDomainEvent(
          path: testPath,
          filePath: filePath,
          occurredAt: testTime,
        );

        // Assert
        expect(event.path, equals(testPath));
        expect(event.filePath, equals(filePath));
        expect(event.occurredAt, equals(testTime));
      });

      test('should handle nested file paths', () {
        // Arrange
        const filePath = 'lib/src/features/auth/login.dart';

        // Act
        final event = ConflictResolvedDomainEvent(
          path: testPath,
          filePath: filePath,
          occurredAt: testTime,
        );

        // Assert
        expect(event.filePath, filePath);
      });
    });

    group('RemoteAddedDomainEvent', () {
      test('should create event with remote details', () {
        // Arrange
        final remoteName = RemoteName.create('upstream');
        const url = 'https://github.com/user/repo.git';

        // Act
        final event = RemoteAddedDomainEvent(
          path: testPath,
          remoteName: remoteName,
          url: url,
          occurredAt: testTime,
        );

        // Assert
        expect(event.path, equals(testPath));
        expect(event.remoteName, equals(remoteName));
        expect(event.url, equals(url));
        expect(event.occurredAt, equals(testTime));
      });

      test('should handle SSH URLs', () {
        // Arrange
        final remoteName = RemoteName.create('origin');
        const url = 'git@github.com:user/repo.git';

        // Act
        final event = RemoteAddedDomainEvent(
          path: testPath,
          remoteName: remoteName,
          url: url,
          occurredAt: testTime,
        );

        // Assert
        expect(event.url, url);
      });

      test('should handle local paths', () {
        // Arrange
        final remoteName = RemoteName.create('local');
        const url = '/path/to/local/repo';

        // Act
        final event = RemoteAddedDomainEvent(
          path: testPath,
          remoteName: remoteName,
          url: url,
          occurredAt: testTime,
        );

        // Assert
        expect(event.url, url);
      });
    });

    group('RemoteRemovedDomainEvent', () {
      test('should create event with remote name', () {
        // Arrange
        final remoteName = RemoteName.create('old-remote');

        // Act
        final event = RemoteRemovedDomainEvent(
          path: testPath,
          remoteName: remoteName,
          occurredAt: testTime,
        );

        // Assert
        expect(event.path, equals(testPath));
        expect(event.remoteName, equals(remoteName));
        expect(event.occurredAt, equals(testTime));
      });

      test('should handle origin remote', () {
        // Arrange
        final remoteName = RemoteName.create('origin');

        // Act
        final event = RemoteRemovedDomainEvent(
          path: testPath,
          remoteName: remoteName,
          occurredAt: testTime,
        );

        // Assert
        expect(event.remoteName.value, 'origin');
      });
    });

    group('StashCreatedDomainEvent', () {
      test('should create event with stash index', () {
        // Arrange
        const stashIndex = 0;

        // Act
        final event = StashCreatedDomainEvent(
          path: testPath,
          stashIndex: stashIndex,
          occurredAt: testTime,
        );

        // Assert
        expect(event.path, equals(testPath));
        expect(event.stashIndex, equals(stashIndex));
        expect(event.occurredAt, equals(testTime));
      });

      test('should create event with message', () {
        // Arrange
        const stashIndex = 0;
        final message = some('WIP: working on feature');

        // Act
        final event = StashCreatedDomainEvent(
          path: testPath,
          stashIndex: stashIndex,
          message: message,
          occurredAt: testTime,
        );

        // Assert
        expect(event.stashIndex, 0);
        expect(event.message?.isSome(), true);
        event.message?.fold(
          () => fail('Message should exist'),
          (msg) => expect(msg, 'WIP: working on feature'),
        );
      });

      test('should handle stash without message', () {
        // Arrange
        const stashIndex = 1;

        // Act
        final event = StashCreatedDomainEvent(
          path: testPath,
          stashIndex: stashIndex,
          message: none(),
          occurredAt: testTime,
        );

        // Assert
        expect(event.message?.isNone(), true);
      });

      test('should handle multiple stash indices', () {
        // Arrange & Act
        final event1 = StashCreatedDomainEvent(
          path: testPath,
          stashIndex: 0,
          occurredAt: testTime,
        );
        final event2 = StashCreatedDomainEvent(
          path: testPath,
          stashIndex: 5,
          occurredAt: testTime,
        );

        // Assert
        expect(event1.stashIndex, 0);
        expect(event2.stashIndex, 5);
      });
    });

    group('StashAppliedDomainEvent', () {
      test('should create event with apply details', () {
        // Arrange
        const stashIndex = 0;
        const popped = false;

        // Act
        final event = StashAppliedDomainEvent(
          path: testPath,
          stashIndex: stashIndex,
          popped: popped,
          occurredAt: testTime,
        );

        // Assert
        expect(event.path, equals(testPath));
        expect(event.stashIndex, equals(stashIndex));
        expect(event.popped, equals(popped));
        expect(event.occurredAt, equals(testTime));
      });

      test('should handle stash pop (popped=true)', () {
        // Arrange
        const stashIndex = 0;
        const popped = true;

        // Act
        final event = StashAppliedDomainEvent(
          path: testPath,
          stashIndex: stashIndex,
          popped: popped,
          occurredAt: testTime,
        );

        // Assert
        expect(event.popped, true);
      });

      test('should handle stash apply (popped=false)', () {
        // Arrange
        const stashIndex = 1;
        const popped = false;

        // Act
        final event = StashAppliedDomainEvent(
          path: testPath,
          stashIndex: stashIndex,
          popped: popped,
          occurredAt: testTime,
        );

        // Assert
        expect(event.popped, false);
      });

      test('should be a GitDomainEvent', () {
        // Arrange & Act
        final event = StashAppliedDomainEvent(
          path: testPath,
          stashIndex: 0,
          popped: false,
          occurredAt: testTime,
        );

        // Assert
        expect(event, isA<GitDomainEvent>());
      });
    });

    group('Event Equality and Immutability', () {
      test('events with same data should be equal', () {
        // Arrange
        final event1 = RepositoryInitializedDomainEvent(
          path: testPath,
          occurredAt: testTime,
        );
        final event2 = RepositoryInitializedDomainEvent(
          path: testPath,
          occurredAt: testTime,
        );

        // Act & Assert
        expect(event1, equals(event2));
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('events with different data should not be equal', () {
        // Arrange
        final event1 = RepositoryInitializedDomainEvent(
          path: testPath,
          occurredAt: testTime,
        );
        final event2 = RepositoryInitializedDomainEvent(
          path: RepositoryPath('/different/path'),
          occurredAt: testTime,
        );

        // Act & Assert
        expect(event1, isNot(equals(event2)));
      });

      test('events of different types should not be equal', () {
        // Arrange
        final event1 = RepositoryInitializedDomainEvent(
          path: testPath,
          occurredAt: testTime,
        );
        final event2 = RepositoryOpenedDomainEvent(
          path: testPath,
          occurredAt: testTime,
        );

        // Act & Assert
        expect(event1, isNot(equals(event2)));
      });
    });

    group('Event Timestamps', () {
      test('all events should have occurredAt timestamp', () {
        // Arrange & Act
        final events = <GitDomainEvent>[
          RepositoryInitializedDomainEvent(
            path: testPath,
            occurredAt: testTime,
          ),
          RepositoryOpenedDomainEvent(
            path: testPath,
            occurredAt: testTime,
          ),
          FilesStagedDomainEvent(
            path: testPath,
            filePaths: ['file.dart'],
            occurredAt: testTime,
          ),
        ];

        // Assert
        for (final event in events) {
          expect(event.occurredAt, equals(testTime));
        }
      });

      test('events should preserve exact timestamp', () {
        // Arrange
        final preciseTime = DateTime(2024, 3, 15, 14, 30, 45, 123, 456);

        // Act
        final event = RepositoryInitializedDomainEvent(
          path: testPath,
          occurredAt: preciseTime,
        );

        // Assert
        expect(event.occurredAt, equals(preciseTime));
        expect(event.occurredAt.millisecond, 123);
        expect(event.occurredAt.microsecond, 456);
      });
    });

    group('Complex Event Scenarios', () {
      test('should create sequence of events for typical workflow', () {
        // Arrange & Act - Typical git workflow
        final events = <GitDomainEvent>[
          // 1. Open repository
          RepositoryOpenedDomainEvent(
            path: testPath,
            occurredAt: testTime,
          ),
          // 2. Stage files
          FilesStagedDomainEvent(
            path: testPath,
            filePaths: ['lib/feature.dart', 'test/feature_test.dart'],
            occurredAt: testTime.add(const Duration(minutes: 5)),
          ),
          // 3. Create commit
          CommitCreatedDomainEvent(
            path: testPath,
            commit: GitCommit(
              hash: CommitHash.create('a' * 40),
              author: const GitAuthor(name: 'Dev', email: 'dev@test.com'),
              committer: const GitAuthor(name: 'Dev', email: 'dev@test.com'),
              message: CommitMessage.create('Add new feature'),
              authorDate: testTime,
              commitDate: testTime,
            ),
            occurredAt: testTime.add(const Duration(minutes: 10)),
          ),
          // 4. Push changes
          ChangesPushedDomainEvent(
            path: testPath,
            remote: RemoteName.create('origin'),
            branch: BranchName.create('main'),
            commitCount: 1,
            occurredAt: testTime.add(const Duration(minutes: 15)),
          ),
        ];

        // Assert
        expect(events.length, 4);
        expect(events[0], isA<RepositoryOpenedDomainEvent>());
        expect(events[1], isA<FilesStagedDomainEvent>());
        expect(events[2], isA<CommitCreatedDomainEvent>());
        expect(events[3], isA<ChangesPushedDomainEvent>());
      });

      test('should create events for merge conflict resolution', () {
        // Arrange
        final conflict = MergeConflict(
          filePath: 'lib/conflict.dart',
          status: ConflictStatus.both_modified,
          content: some('conflicted content'),
          markers: none(),
        );

        // Act
        final events = <GitDomainEvent>[
          // 1. Conflict detected
          MergeConflictDomainEvent(
            path: testPath,
            conflict: conflict,
            occurredAt: testTime,
          ),
          // 2. Conflict resolved
          ConflictResolvedDomainEvent(
            path: testPath,
            filePath: 'lib/conflict.dart',
            occurredAt: testTime.add(const Duration(minutes: 30)),
          ),
        ];

        // Assert
        expect(events.length, 2);
        expect(events[0], isA<MergeConflictDomainEvent>());
        expect(events[1], isA<ConflictResolvedDomainEvent>());
      });

      test('should create events for stash workflow', () {
        // Arrange & Act
        final events = <GitDomainEvent>[
          // 1. Create stash
          StashCreatedDomainEvent(
            path: testPath,
            stashIndex: 0,
            message: some('WIP: feature in progress'),
            occurredAt: testTime,
          ),
          // 2. Apply stash later
          StashAppliedDomainEvent(
            path: testPath,
            stashIndex: 0,
            popped: true,
            occurredAt: testTime.add(const Duration(hours: 2)),
          ),
        ];

        // Assert
        expect(events.length, 2);
        expect(events[0], isA<StashCreatedDomainEvent>());
        expect(events[1], isA<StashAppliedDomainEvent>());
      });
    });
  });
}
