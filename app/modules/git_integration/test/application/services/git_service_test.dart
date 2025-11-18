import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:fpdart/fpdart.dart' as fp;

// Mock classes
class MockInitRepositoryUseCase extends Mock implements InitRepositoryUseCase {}

class MockGetRepositoryStatusUseCase extends Mock
    implements GetRepositoryStatusUseCase {}

class MockStageFilesUseCase extends Mock implements StageFilesUseCase {}

class MockUnstageFilesUseCase extends Mock implements UnstageFilesUseCase {}

class MockCommitChangesUseCase extends Mock implements CommitChangesUseCase {}

class MockCreateBranchUseCase extends Mock implements CreateBranchUseCase {}

class MockCheckoutBranchUseCase extends Mock implements CheckoutBranchUseCase {}

class MockDeleteBranchUseCase extends Mock implements DeleteBranchUseCase {}

class MockPushChangesUseCase extends Mock implements PushChangesUseCase {}

class MockPullChangesUseCase extends Mock implements PullChangesUseCase {}

class MockFetchChangesUseCase extends Mock implements FetchChangesUseCase {}

class MockGetCommitHistoryUseCase extends Mock
    implements GetCommitHistoryUseCase {}

class MockAddRemoteUseCase extends Mock implements AddRemoteUseCase {}

class MockRemoveRemoteUseCase extends Mock implements RemoveRemoteUseCase {}

class MockRenameRemoteUseCase extends Mock implements RenameRemoteUseCase {}

class MockCloneRepositoryUseCase extends Mock
    implements CloneRepositoryUseCase {}

void main() {
  group('GitService', () {
    late GitService service;
    late MockInitRepositoryUseCase mockInitRepository;
    late MockGetRepositoryStatusUseCase mockGetStatus;
    late MockStageFilesUseCase mockStageFiles;
    late MockUnstageFilesUseCase mockUnstageFiles;
    late MockCommitChangesUseCase mockCommit;
    late MockCreateBranchUseCase mockCreateBranch;
    late MockCheckoutBranchUseCase mockCheckoutBranch;
    late MockDeleteBranchUseCase mockDeleteBranch;
    late MockPushChangesUseCase mockPush;
    late MockPullChangesUseCase mockPull;
    late MockFetchChangesUseCase mockFetch;
    late MockGetCommitHistoryUseCase mockGetHistory;
    late MockAddRemoteUseCase mockAddRemote;
    late MockRemoveRemoteUseCase mockRemoveRemote;
    late MockRenameRemoteUseCase mockRenameRemote;
    late MockCloneRepositoryUseCase mockClone;

    late RepositoryPath path;
    late GitRepository repository;

    setUp(() {
      mockInitRepository = MockInitRepositoryUseCase();
      mockGetStatus = MockGetRepositoryStatusUseCase();
      mockStageFiles = MockStageFilesUseCase();
      mockUnstageFiles = MockUnstageFilesUseCase();
      mockCommit = MockCommitChangesUseCase();
      mockCreateBranch = MockCreateBranchUseCase();
      mockCheckoutBranch = MockCheckoutBranchUseCase();
      mockDeleteBranch = MockDeleteBranchUseCase();
      mockPush = MockPushChangesUseCase();
      mockPull = MockPullChangesUseCase();
      mockFetch = MockFetchChangesUseCase();
      mockGetHistory = MockGetCommitHistoryUseCase();
      mockAddRemote = MockAddRemoteUseCase();
      mockRemoveRemote = MockRemoveRemoteUseCase();
      mockRenameRemote = MockRenameRemoteUseCase();
      mockClone = MockCloneRepositoryUseCase();

      service = GitService(
        mockInitRepository,
        mockClone,
        mockGetStatus,
        mockStageFiles,
        mockUnstageFiles,
        mockCommit,
        mockCreateBranch,
        mockCheckoutBranch,
        mockDeleteBranch,
        mockPush,
        mockPull,
        mockFetch,
        mockGetHistory,
        mockAddRemote,
        mockRemoveRemote,
        mockRenameRemote,
      );

      path = RepositoryPath.create('/test/repo');
      repository = GitRepository(
        path: path,
        currentBranch: fp.some(GitBranch(
          name: BranchName.create('main'),
          isCurrentBranch: true,
          lastCommitHash: CommitHash.create('a' * 40),
          lastCommitMessage: 'Initial',
          aheadCount: 0,
          behindCount: 0,
        )),
        localBranches: const [],
        remoteBranches: const [],
        remotes: const [],
        state: GitRepositoryState.clean,
        changes: const [],
        stagedChanges: const [],
        headCommit: fp.none(),
        stashes: const [],
        activeConflict: fp.none(),
      );
    });

    group('initRepository', () {
      test('should initialize repository successfully', () async {
        // Arrange
        when(() => mockInitRepository(path: path))
            .thenAnswer((_) async => right(repository));

        // Act
        final result = await service.initRepository(path: path);

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockInitRepository(path: path)).called(1);
      });

      test('should cache repository after initialization', () async {
        // Arrange
        when(() => mockInitRepository(path: path))
            .thenAnswer((_) async => right(repository));

        // Act
        await service.initRepository(path: path);
        final result = await service.getStatus(path: path);

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockInitRepository(path: path)).called(1);
        verifyNever(() => mockGetStatus(path: path));
      });

      test('should return failure on error', () async {
        // Arrange
        final failure = GitFailure.commandFailed(
          command: 'git init',
          exitCode: 1,
          stderr: 'Error',
        );
        when(() => mockInitRepository(path: path))
            .thenAnswer((_) async => left(failure));

        // Act
        final result = await service.initRepository(path: path);

        // Assert
        expect(result.isLeft(), isTrue);
      });
    });

    group('getStatus', () {
      test('should get repository status', () async {
        // Arrange
        when(() => mockGetStatus(path: path))
            .thenAnswer((_) async => right(repository));

        // Act
        final result = await service.getStatus(path: path);

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockGetStatus(path: path)).called(1);
      });

      test('should use cache when available', () async {
        // Arrange
        when(() => mockGetStatus(path: path))
            .thenAnswer((_) async => right(repository));

        // Act
        await service.getStatus(path: path);
        final result = await service.getStatus(path: path);

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockGetStatus(path: path)).called(1);
      });

      test('should force refresh when requested', () async {
        // Arrange
        when(() => mockGetStatus(path: path))
            .thenAnswer((_) async => right(repository));

        // Act
        await service.getStatus(path: path);
        final result = await service.getStatus(path: path, forceRefresh: true);

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockGetStatus(path: path)).called(2);
      });
    });

    group('stageFiles', () {
      test('should stage files successfully', () async {
        // Arrange
        final filePaths = ['lib/main.dart', 'lib/utils.dart'];
        when(() => mockStageFiles(path: path, filePaths: filePaths))
            .thenAnswer((_) async => right(unit));

        // Act
        final result = await service.stageFiles(
          path: path,
          filePaths: filePaths,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockStageFiles(path: path, filePaths: filePaths))
            .called(1);
      });

      test('should invalidate cache after staging', () async {
        // Arrange
        when(() => mockGetStatus(path: path))
            .thenAnswer((_) async => right(repository));
        when(() => mockStageFiles(path: path, filePaths: any(named: 'filePaths')))
            .thenAnswer((_) async => right(unit));

        // Act
        await service.getStatus(path: path);
        await service.stageFiles(path: path, filePaths: ['file.dart']);
        await service.getStatus(path: path);

        // Assert
        verify(() => mockGetStatus(path: path)).called(2);
      });

      test('should stage all files', () async {
        // Arrange
        when(() => mockStageFiles.stageAll(path: path))
            .thenAnswer((_) async => right(unit));

        // Act
        final result = await service.stageAll(path: path);

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockStageFiles.stageAll(path: path)).called(1);
      });
    });

    group('unstageFiles', () {
      test('should unstage files successfully', () async {
        // Arrange
        final filePaths = ['lib/main.dart'];
        when(() => mockUnstageFiles(path: path, filePaths: filePaths))
            .thenAnswer((_) async => right(unit));

        // Act
        final result = await service.unstageFiles(
          path: path,
          filePaths: filePaths,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockUnstageFiles(path: path, filePaths: filePaths))
            .called(1);
      });

      test('should unstage all files', () async {
        // Arrange
        when(() => mockUnstageFiles.unstageAll(path: path))
            .thenAnswer((_) async => right(unit));

        // Act
        final result = await service.unstageAll(path: path);

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockUnstageFiles.unstageAll(path: path)).called(1);
      });
    });

    group('commit', () {
      test('should create commit successfully', () async {
        // Arrange
        final author = const GitAuthor(name: 'Test', email: 'test@example.com');
        final commit = GitCommit(
          hash: CommitHash.create('a' * 40),
          author: author,
          committer: author,
          message: const CommitMessage(value: 'Test commit'),
          authorDate: DateTime.now(),
          commitDate: DateTime.now(),
        );

        when(() => mockCommit(
              path: path,
              message: 'Test commit',
              author: author,
              amend: false,
            )).thenAnswer((_) async => right(commit));

        // Act
        final result = await service.commit(
          path: path,
          message: 'Test commit',
          author: author,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockCommit(
              path: path,
              message: 'Test commit',
              author: author,
              amend: false,
            )).called(1);
      });

      test('should invalidate cache after commit', () async {
        // Arrange
        final author = const GitAuthor(name: 'Test', email: 'test@example.com');
        final commit = GitCommit(
          hash: CommitHash.create('a' * 40),
          author: author,
          committer: author,
          message: const CommitMessage(value: 'Test'),
          authorDate: DateTime.now(),
          commitDate: DateTime.now(),
        );

        when(() => mockGetStatus(path: path))
            .thenAnswer((_) async => right(repository));
        when(() => mockCommit(
              path: path,
              message: any(named: 'message'),
              author: any(named: 'author'),
              amend: any(named: 'amend'),
            )).thenAnswer((_) async => right(commit));

        // Act
        await service.getStatus(path: path);
        await service.commit(path: path, message: 'Test', author: author);
        await service.getStatus(path: path);

        // Assert
        verify(() => mockGetStatus(path: path)).called(2);
      });
    });

    group('createBranch', () {
      test('should create branch successfully', () async {
        // Arrange
        final branch = GitBranch(
          name: BranchName.create('feature'),
          isCurrentBranch: false,
          lastCommitHash: CommitHash.create('a' * 40),
          lastCommitMessage: 'Initial',
          aheadCount: 0,
          behindCount: 0,
        );

        when(() => mockCreateBranch(
              path: path,
              branchName: 'feature',
              startPoint: null,
              checkout: false,
            )).thenAnswer((_) async => right(branch));

        // Act
        final result = await service.createBranch(
          path: path,
          branchName: 'feature',
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockCreateBranch(
              path: path,
              branchName: 'feature',
              startPoint: null,
              checkout: false,
            )).called(1);
      });
    });

    group('checkoutBranch', () {
      test('should checkout branch successfully', () async {
        // Arrange
        when(() => mockCheckoutBranch(
              path: path,
              branchName: 'feature',
              force: false,
            )).thenAnswer((_) async => right(unit));

        // Act
        final result = await service.checkoutBranch(
          path: path,
          branchName: 'feature',
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockCheckoutBranch(
              path: path,
              branchName: 'feature',
              force: false,
            )).called(1);
      });
    });

    group('push', () {
      test('should push changes successfully', () async {
        // Arrange
        when(() => mockPush(
              path: path,
              remote: 'origin',
              branch: 'main',
              force: false,
              setUpstream: false,
              onProgress: null,
            )).thenAnswer((_) async => right(unit));

        // Act
        final result = await service.push(
          path: path,
          branch: 'main',
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockPush(
              path: path,
              remote: 'origin',
              branch: 'main',
              force: false,
              setUpstream: false,
              onProgress: null,
            )).called(1);
      });
    });

    group('pull', () {
      test('should pull changes successfully', () async {
        // Arrange
        when(() => mockPull(
              path: path,
              remote: 'origin',
              branch: fp.none(),
              rebase: false,
              onProgress: null,
            )).thenAnswer((_) async => right(unit));

        // Act
        final result = await service.pull(path: path);

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockPull(
              path: path,
              remote: 'origin',
              branch: fp.none(),
              rebase: false,
              onProgress: null,
            )).called(1);
      });
    });

    group('cache management', () {
      test('should clear all cache', () async {
        // Arrange
        when(() => mockGetStatus(path: path))
            .thenAnswer((_) async => right(repository));

        // Act
        await service.getStatus(path: path);
        service.clearCache();
        await service.getStatus(path: path);

        // Assert
        verify(() => mockGetStatus(path: path)).called(2);
      });
    });

    group('use cases', () {
      test('should handle complete workflow: init -> stage -> commit -> push',
          () async {
        // Arrange
        final author = const GitAuthor(name: 'Dev', email: 'dev@example.com');
        final commit = GitCommit(
          hash: CommitHash.create('a' * 40),
          author: author,
          committer: author,
          message: const CommitMessage(value: 'Initial'),
          authorDate: DateTime.now(),
          commitDate: DateTime.now(),
        );

        when(() => mockInitRepository(path: path))
            .thenAnswer((_) async => right(repository));
        when(() => mockStageFiles(path: path, filePaths: any(named: 'filePaths')))
            .thenAnswer((_) async => right(unit));
        when(() => mockCommit(
              path: path,
              message: any(named: 'message'),
              author: any(named: 'author'),
              amend: any(named: 'amend'),
            )).thenAnswer((_) async => right(commit));
        when(() => mockPush(
              path: path,
              remote: any(named: 'remote'),
              branch: any(named: 'branch'),
              force: any(named: 'force'),
              setUpstream: any(named: 'setUpstream'),
              onProgress: any(named: 'onProgress'),
            )).thenAnswer((_) async => right(unit));

        // Act
        await service.initRepository(path: path);
        await service.stageFiles(path: path, filePaths: ['README.md']);
        await service.commit(path: path, message: 'Initial', author: author);
        await service.push(path: path, branch: 'main', setUpstream: true);

        // Assert
        verify(() => mockInitRepository(path: path)).called(1);
        verify(() => mockStageFiles(path: path, filePaths: ['README.md']))
            .called(1);
        verify(() => mockCommit(
              path: path,
              message: 'Initial',
              author: author,
              amend: false,
            )).called(1);
      });
    });
  });
}
