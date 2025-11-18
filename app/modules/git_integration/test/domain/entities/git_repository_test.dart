import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:fpdart/fpdart.dart';
import 'package:dartz/dartz.dart' as dartz;

void main() {
  group('GitRepository', () {
    late RepositoryPath path;
    late GitBranch mainBranch;
    late GitRemote originRemote;
    late FileChange fileChange;
    late GitCommit headCommit;

    setUp(() {
      path = RepositoryPath.create('/test/repo');
      mainBranch = GitBranch(
        name: BranchName.create('main'),
        isCurrentBranch: true,
        lastCommitHash: CommitHash.create('a' * 40),
        lastCommitMessage: 'Initial commit',
        aheadCount: 0,
        behindCount: 0,
      );
      originRemote = GitRemote(
        name: RemoteName.create('origin'),
        url: 'https://github.com/user/repo.git',
      );
      fileChange = const FileChange(
        filePath: 'lib/main.dart',
        status: FileStatus.modified(),
        isStaged: false,
      );
      headCommit = GitCommit(
        hash: CommitHash.create('a' * 40),
        author: const GitAuthor(name: 'Test', email: 'test@example.com'),
        committer: const GitAuthor(name: 'Test', email: 'test@example.com'),
        message: const CommitMessage(value: 'Initial commit'),
        authorDate: DateTime.now(),
        commitDate: DateTime.now(),
      );
    });

    group('creation', () {
      test('should create clean repository', () {
        // Arrange & Act
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: [originRemote],
          state: GitRepositoryState.clean,
          changes: const [],
          stagedChanges: const [],
          headCommit: some(headCommit),
          stashes: const [],
          activeConflict: none(),
        );

        // Assert
        expect(repo.state, equals(GitRepositoryState.clean));
        expect(repo.hasUncommittedChanges, isFalse);
      });

      test('should create repository with unstaged changes', () {
        // Arrange & Act
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: [originRemote],
          state: GitRepositoryState.modified,
          changes: [fileChange],
          stagedChanges: const [],
          headCommit: some(headCommit),
          stashes: const [],
          activeConflict: none(),
        );

        // Assert
        expect(repo.state, equals(GitRepositoryState.modified));
        expect(repo.hasUnstagedChanges, isTrue);
        expect(repo.hasStagedChanges, isFalse);
      });

      test('should create repository with staged changes', () {
        // Arrange & Act
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: [originRemote],
          state: GitRepositoryState.staged,
          changes: const [],
          stagedChanges: [fileChange.copyWith(isStaged: true)],
          headCommit: some(headCommit),
          stashes: const [],
          activeConflict: none(),
        );

        // Assert
        expect(repo.state, equals(GitRepositoryState.staged));
        expect(repo.hasStagedChanges, isTrue);
        expect(repo.hasUnstagedChanges, isFalse);
      });
    });

    group('canCheckoutBranch', () {
      test('should allow checkout when repository is clean', () {
        // Arrange
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: const [],
          state: GitRepositoryState.clean,
          changes: const [],
          stagedChanges: const [],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act & Assert
        expect(repo.canCheckoutBranch(), isTrue);
      });

      test('should not allow checkout when repository has changes', () {
        // Arrange
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: const [],
          state: GitRepositoryState.modified,
          changes: [fileChange],
          stagedChanges: const [],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act & Assert
        expect(repo.canCheckoutBranch(), isFalse);
      });

      test('should not allow checkout during merge', () {
        // Arrange
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: const [],
          state: GitRepositoryState.merging,
          changes: const [],
          stagedChanges: const [],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act & Assert
        expect(repo.canCheckoutBranch(), isFalse);
      });
    });

    group('canCommit', () {
      test('should allow commit when has staged changes', () {
        // Arrange
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: const [],
          state: GitRepositoryState.staged,
          changes: const [],
          stagedChanges: [fileChange.copyWith(isStaged: true)],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act & Assert
        expect(repo.canCommit(), isTrue);
      });

      test('should not allow commit without staged changes', () {
        // Arrange
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: const [],
          state: GitRepositoryState.clean,
          changes: const [],
          stagedChanges: const [],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act & Assert
        expect(repo.canCommit(), isFalse);
      });

      test('should not allow commit during merge', () {
        // Arrange
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: const [],
          state: GitRepositoryState.merging,
          changes: const [],
          stagedChanges: [fileChange.copyWith(isStaged: true)],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act & Assert
        expect(repo.canCommit(), isFalse);
      });
    });

    group('stageFile', () {
      test('should stage unstaged file', () {
        // Arrange
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: const [],
          state: GitRepositoryState.modified,
          changes: [fileChange],
          stagedChanges: const [],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act
        final result = repo.stageFile('lib/main.dart');

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should succeed'),
          (updatedRepo) {
            expect(updatedRepo.changes.length, equals(0));
            expect(updatedRepo.stagedChanges.length, equals(1));
            expect(updatedRepo.state, equals(GitRepositoryState.staged));
          },
        );
      });

      test('should fail to stage non-existent file', () {
        // Arrange
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: const [],
          state: GitRepositoryState.clean,
          changes: const [],
          stagedChanges: const [],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act
        final result = repo.stageFile('non-existent.dart');

        // Assert
        expect(result.isLeft(), isTrue);
      });
    });

    group('stageAll', () {
      test('should stage all changes', () {
        // Arrange
        final change1 = fileChange;
        final change2 = const FileChange(
          filePath: 'lib/utils.dart',
          status: FileStatus.added(),
          isStaged: false,
        );
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: const [],
          state: GitRepositoryState.modified,
          changes: [change1, change2],
          stagedChanges: const [],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act
        final result = repo.stageAll();

        // Assert
        result.fold(
          (_) => fail('Should succeed'),
          (updatedRepo) {
            expect(updatedRepo.changes.length, equals(0));
            expect(updatedRepo.stagedChanges.length, equals(2));
            expect(updatedRepo.state, equals(GitRepositoryState.staged));
          },
        );
      });

      test('should do nothing when no changes to stage', () {
        // Arrange
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: const [],
          state: GitRepositoryState.clean,
          changes: const [],
          stagedChanges: const [],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act
        final result = repo.stageAll();

        // Assert
        result.fold(
          (_) => fail('Should succeed'),
          (updatedRepo) {
            expect(updatedRepo, equals(repo));
          },
        );
      });
    });

    group('unstageFile', () {
      test('should unstage staged file', () {
        // Arrange
        final stagedFile = fileChange.copyWith(isStaged: true);
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: const [],
          state: GitRepositoryState.staged,
          changes: const [],
          stagedChanges: [stagedFile],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act
        final result = repo.unstageFile('lib/main.dart');

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should succeed'),
          (updatedRepo) {
            expect(updatedRepo.stagedChanges.length, equals(0));
            expect(updatedRepo.changes.length, equals(1));
            expect(updatedRepo.state, equals(GitRepositoryState.modified));
          },
        );
      });

      test('should fail to unstage non-staged file', () {
        // Arrange
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: const [],
          state: GitRepositoryState.clean,
          changes: const [],
          stagedChanges: const [],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act
        final result = repo.unstageFile('lib/main.dart');

        // Assert
        expect(result.isLeft(), isTrue);
      });
    });

    group('unstageAll', () {
      test('should unstage all changes', () {
        // Arrange
        final staged1 = fileChange.copyWith(isStaged: true);
        final staged2 = const FileChange(
          filePath: 'lib/utils.dart',
          status: FileStatus.added(),
          isStaged: true,
        );
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: const [],
          state: GitRepositoryState.staged,
          changes: const [],
          stagedChanges: [staged1, staged2],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act
        final result = repo.unstageAll();

        // Assert
        result.fold(
          (_) => fail('Should succeed'),
          (updatedRepo) {
            expect(updatedRepo.stagedChanges.length, equals(0));
            expect(updatedRepo.changes.length, equals(2));
            expect(updatedRepo.state, equals(GitRepositoryState.modified));
          },
        );
      });
    });

    group('canPush', () {
      test('should allow push with current branch and remote', () {
        // Arrange
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: [originRemote],
          state: GitRepositoryState.clean,
          changes: const [],
          stagedChanges: const [],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act & Assert
        expect(repo.canPush(), isTrue);
      });

      test('should not allow push without current branch', () {
        // Arrange
        final repo = GitRepository(
          path: path,
          currentBranch: none(),
          localBranches: const [],
          remoteBranches: const [],
          remotes: [originRemote],
          state: GitRepositoryState.clean,
          changes: const [],
          stagedChanges: const [],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act & Assert
        expect(repo.canPush(), isFalse);
      });

      test('should not allow push without remotes', () {
        // Arrange
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: const [],
          state: GitRepositoryState.clean,
          changes: const [],
          stagedChanges: const [],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act & Assert
        expect(repo.canPush(), isFalse);
      });

      test('should not allow push during merge', () {
        // Arrange
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: [originRemote],
          state: GitRepositoryState.merging,
          changes: const [],
          stagedChanges: const [],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act & Assert
        expect(repo.canPush(), isFalse);
      });
    });

    group('canPull', () {
      test('should allow pull with current branch and remote', () {
        // Arrange
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: [originRemote],
          state: GitRepositoryState.clean,
          changes: const [],
          stagedChanges: const [],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act & Assert
        expect(repo.canPull(), isTrue);
      });

      test('should not allow pull without remote', () {
        // Arrange
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: const [],
          state: GitRepositoryState.clean,
          changes: const [],
          stagedChanges: const [],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act & Assert
        expect(repo.canPull(), isFalse);
      });
    });

    group('getBranchByName', () {
      test('should find local branch', () {
        // Arrange
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: const [],
          state: GitRepositoryState.clean,
          changes: const [],
          stagedChanges: const [],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act
        final result = repo.getBranchByName('main');

        // Assert
        expect(result.isSome(), isTrue);
      });

      test('should return none for non-existent branch', () {
        // Arrange
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: const [],
          state: GitRepositoryState.clean,
          changes: const [],
          stagedChanges: const [],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act
        final result = repo.getBranchByName('feature');

        // Assert
        expect(result.isNone(), isTrue);
      });
    });

    group('use cases', () {
      test('should handle typical clean repository workflow', () {
        // Arrange & Act
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: [originRemote],
          state: GitRepositoryState.clean,
          changes: const [],
          stagedChanges: const [],
          headCommit: some(headCommit),
          stashes: const [],
          activeConflict: none(),
        );

        // Assert
        expect(repo.canCheckoutBranch(), isTrue);
        expect(repo.canCommit(), isFalse);
        expect(repo.canPush(), isTrue);
        expect(repo.canPull(), isTrue);
        expect(repo.hasUncommittedChanges, isFalse);
      });

      test('should handle repository with uncommitted changes', () {
        // Arrange & Act
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: [originRemote],
          state: GitRepositoryState.modified,
          changes: [fileChange],
          stagedChanges: const [],
          headCommit: some(headCommit),
          stashes: const [],
          activeConflict: none(),
        );

        // Assert
        expect(repo.hasUncommittedChanges, isTrue);
        expect(repo.canCheckoutBranch(), isFalse);
        expect(repo.canCommit(), isFalse);
      });

      test('should handle repository ready for commit', () {
        // Arrange & Act
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: [originRemote],
          state: GitRepositoryState.staged,
          changes: const [],
          stagedChanges: [fileChange.copyWith(isStaged: true)],
          headCommit: some(headCommit),
          stashes: const [],
          activeConflict: none(),
        );

        // Assert
        expect(repo.canCommit(), isTrue);
        expect(repo.hasStagedChanges, isTrue);
      });
    });
  });
}
