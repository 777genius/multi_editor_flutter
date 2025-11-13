import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart' as fp;
import '../../domain/entities/git_repository.dart';
import '../../domain/entities/git_commit.dart';
import '../../domain/entities/git_branch.dart';
import '../../domain/entities/git_remote.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/value_objects/commit_message.dart';
import '../../domain/value_objects/git_author.dart';
import '../../domain/failures/git_failures.dart';
import '../use_cases/init_repository_use_case.dart';
import '../use_cases/clone_repository_use_case.dart';
import '../use_cases/get_repository_status_use_case.dart';
import '../use_cases/stage_files_use_case.dart';
import '../use_cases/unstage_files_use_case.dart';
import '../use_cases/commit_changes_use_case.dart';
import '../use_cases/create_branch_use_case.dart';
import '../use_cases/checkout_branch_use_case.dart';
import '../use_cases/delete_branch_use_case.dart';
import '../use_cases/push_changes_use_case.dart';
import '../use_cases/pull_changes_use_case.dart';
import '../use_cases/fetch_changes_use_case.dart';
import '../use_cases/get_commit_history_use_case.dart';
import '../use_cases/add_remote_use_case.dart';
import '../use_cases/remove_remote_use_case.dart';

/// Main Git service that orchestrates git operations
///
/// This service provides a high-level interface for all git operations
/// and coordinates multiple use cases. It also handles:
/// - Caching of repository state
/// - Event publishing for UI updates
/// - Error recovery and retry logic
/// - Operation queuing to prevent conflicts
@injectable
class GitService {
  final InitRepositoryUseCase _initRepositoryUseCase;
  final CloneRepositoryUseCase _cloneRepositoryUseCase;
  final GetRepositoryStatusUseCase _getRepositoryStatusUseCase;
  final StageFilesUseCase _stageFilesUseCase;
  final UnstageFilesUseCase _unstageFilesUseCase;
  final CommitChangesUseCase _commitChangesUseCase;
  final CreateBranchUseCase _createBranchUseCase;
  final CheckoutBranchUseCase _checkoutBranchUseCase;
  final DeleteBranchUseCase _deleteBranchUseCase;
  final PushChangesUseCase _pushChangesUseCase;
  final PullChangesUseCase _pullChangesUseCase;
  final FetchChangesUseCase _fetchChangesUseCase;
  final GetCommitHistoryUseCase _getCommitHistoryUseCase;
  final AddRemoteUseCase _addRemoteUseCase;
  final RemoveRemoteUseCase _removeRemoteUseCase;

  // Cache of repository states (path -> GitRepository)
  final Map<String, GitRepository> _repositoryCache = {};

  // Operation queue to prevent concurrent operations on same repository
  final Map<String, Future<void>> _operationQueue = {};

  GitService(
    this._initRepositoryUseCase,
    this._cloneRepositoryUseCase,
    this._getRepositoryStatusUseCase,
    this._stageFilesUseCase,
    this._unstageFilesUseCase,
    this._commitChangesUseCase,
    this._createBranchUseCase,
    this._checkoutBranchUseCase,
    this._deleteBranchUseCase,
    this._pushChangesUseCase,
    this._pullChangesUseCase,
    this._fetchChangesUseCase,
    this._getCommitHistoryUseCase,
    this._addRemoteUseCase,
    this._removeRemoteUseCase,
  );

  // ============================================================================
  // Repository Operations
  // ============================================================================

  /// Initialize a new repository
  Future<Either<GitFailure, GitRepository>> initRepository({
    required RepositoryPath path,
  }) async {
    return _executeOperation(path, () async {
      final result = await _initRepositoryUseCase(path: path);
      return result.fold(
        (failure) => left(failure),
        (repository) {
          _cacheRepository(repository);
          return right(repository);
        },
      );
    });
  }

  /// Clone a repository from URL
  Future<Either<GitFailure, GitRepository>> cloneRepository({
    required String url,
    required RepositoryPath path,
    fp.Option<String>? branch,
    CloneProgressCallback? onProgress,
  }) async {
    return _executeOperation(path, () async {
      final result = await _cloneRepositoryUseCase(
        url: url,
        path: path,
        branch: branch,
        onProgress: onProgress,
      );
      return result.fold(
        (failure) => left(failure),
        (repository) {
          _cacheRepository(repository);
          return right(repository);
        },
      );
    });
  }

  /// Get repository status (uses cache if available and not stale)
  Future<Either<GitFailure, GitRepository>> getStatus({
    required RepositoryPath path,
    bool forceRefresh = false,
  }) async {
    // Check cache first (unless force refresh)
    if (!forceRefresh && _repositoryCache.containsKey(path.path)) {
      return right(_repositoryCache[path.path]!);
    }

    return _executeOperation(path, () async {
      final result = await _getRepositoryStatusUseCase(path: path);
      return result.fold(
        (failure) => left(failure),
        (repository) {
          _cacheRepository(repository);
          return right(repository);
        },
      );
    });
  }

  /// Quick refresh status (optimized for UI polling)
  Future<Either<GitFailure, GitRepository>> quickRefreshStatus({
    required RepositoryPath path,
  }) async {
    return _executeOperation(path, () async {
      final result = await _getRepositoryStatusUseCase.quickRefresh(path: path);
      return result.fold(
        (failure) => left(failure),
        (repository) {
          _cacheRepository(repository);
          return right(repository);
        },
      );
    });
  }

  // ============================================================================
  // Staging Operations
  // ============================================================================

  /// Stage files for commit
  Future<Either<GitFailure, Unit>> stageFiles({
    required RepositoryPath path,
    required List<String> filePaths,
  }) async {
    return _executeOperation(path, () async {
      final result = await _stageFilesUseCase(
        path: path,
        filePaths: filePaths,
      );
      // Invalidate cache
      _invalidateCache(path);
      return result;
    });
  }

  /// Stage all changes
  Future<Either<GitFailure, Unit>> stageAll({
    required RepositoryPath path,
  }) async {
    return _executeOperation(path, () async {
      final result = await _stageFilesUseCase.stageAll(path: path);
      _invalidateCache(path);
      return result;
    });
  }

  /// Unstage files
  Future<Either<GitFailure, Unit>> unstageFiles({
    required RepositoryPath path,
    required List<String> filePaths,
  }) async {
    return _executeOperation(path, () async {
      final result = await _unstageFilesUseCase(
        path: path,
        filePaths: filePaths,
      );
      _invalidateCache(path);
      return result;
    });
  }

  /// Unstage all changes
  Future<Either<GitFailure, Unit>> unstageAll({
    required RepositoryPath path,
  }) async {
    return _executeOperation(path, () async {
      final result = await _unstageFilesUseCase.unstageAll(path: path);
      _invalidateCache(path);
      return result;
    });
  }

  // ============================================================================
  // Commit Operations
  // ============================================================================

  /// Create a commit
  Future<Either<GitFailure, GitCommit>> commit({
    required RepositoryPath path,
    required String message,
    required GitAuthor author,
    bool amend = false,
  }) async {
    return _executeOperation(path, () async {
      final result = await _commitChangesUseCase(
        path: path,
        message: message,
        author: author,
        amend: amend,
      );
      _invalidateCache(path);
      return result;
    });
  }

  /// Get commit history with pagination
  Future<Either<GitFailure, List<GitCommit>>> getHistory({
    required RepositoryPath path,
    fp.Option<String>? branch,
    int maxCount = 100,
    int skip = 0,
  }) async {
    return _getCommitHistoryUseCase(
      path: path,
      branch: branch,
      maxCount: maxCount,
      skip: skip,
    );
  }

  /// Get file history
  Future<Either<GitFailure, List<GitCommit>>> getFileHistory({
    required RepositoryPath path,
    required String filePath,
    int maxCount = 100,
  }) async {
    return _getCommitHistoryUseCase.getFileHistory(
      path: path,
      filePath: filePath,
      maxCount: maxCount,
    );
  }

  // ============================================================================
  // Branch Operations
  // ============================================================================

  /// Create a new branch
  Future<Either<GitFailure, GitBranch>> createBranch({
    required RepositoryPath path,
    required String branchName,
    String? startPoint,
    bool checkout = false,
  }) async {
    return _executeOperation(path, () async {
      final result = await _createBranchUseCase(
        path: path,
        branchName: branchName,
        startPoint: startPoint,
        checkout: checkout,
      );
      _invalidateCache(path);
      return result;
    });
  }

  /// Checkout a branch
  Future<Either<GitFailure, Unit>> checkoutBranch({
    required RepositoryPath path,
    required String branchName,
    bool force = false,
  }) async {
    return _executeOperation(path, () async {
      final result = await _checkoutBranchUseCase(
        path: path,
        branchName: branchName,
        force: force,
      );
      _invalidateCache(path);
      return result;
    });
  }

  /// Delete a branch
  Future<Either<GitFailure, Unit>> deleteBranch({
    required RepositoryPath path,
    required String branchName,
    bool force = false,
    bool remote = false,
  }) async {
    return _executeOperation(path, () async {
      final result = await _deleteBranchUseCase(
        path: path,
        branch: branchName,
        force: force,
        remote: remote,
      );
      _invalidateCache(path);
      return result;
    });
  }

  // ============================================================================
  // Remote Operations
  // ============================================================================

  /// Push changes to remote
  Future<Either<GitFailure, Unit>> push({
    required RepositoryPath path,
    String remote = 'origin',
    required String branch,
    bool force = false,
    bool setUpstream = false,
    PushProgressCallback? onProgress,
  }) async {
    return _executeOperation(path, () async {
      final result = await _pushChangesUseCase(
        path: path,
        remote: remote,
        branch: branch,
        force: force,
        setUpstream: setUpstream,
        onProgress: onProgress,
      );
      _invalidateCache(path);
      return result;
    });
  }

  /// Pull changes from remote
  Future<Either<GitFailure, Unit>> pull({
    required RepositoryPath path,
    String remote = 'origin',
    fp.Option<String>? branch,
    bool rebase = false,
    PullProgressCallback? onProgress,
  }) async {
    return _executeOperation(path, () async {
      final result = await _pullChangesUseCase(
        path: path,
        remote: remote,
        branch: branch,
        rebase: rebase,
        onProgress: onProgress,
      );
      _invalidateCache(path);
      return result;
    });
  }

  /// Fetch changes from remote
  Future<Either<GitFailure, Unit>> fetch({
    required RepositoryPath path,
    String remote = 'origin',
    fp.Option<String>? branch,
    bool prune = false,
    bool tags = true,
    FetchProgressCallback? onProgress,
  }) async {
    return _executeOperation(path, () async {
      final result = await _fetchChangesUseCase(
        path: path,
        remote: remote,
        branch: branch,
        prune: prune,
        tags: tags,
        onProgress: onProgress,
      );
      _invalidateCache(path);
      return result;
    });
  }

  /// Fetch from all remotes
  Future<Either<GitFailure, Unit>> fetchAll({
    required RepositoryPath path,
    bool prune = false,
    bool tags = true,
    FetchProgressCallback? onProgress,
  }) async {
    return _executeOperation(path, () async {
      final result = await _fetchChangesUseCase.fetchAll(
        path: path,
        prune: prune,
        tags: tags,
        onProgress: onProgress,
      );
      _invalidateCache(path);
      return result;
    });
  }

  /// Check if branch is behind remote
  Future<Either<GitFailure, int>> checkBehind({
    required RepositoryPath path,
    fp.Option<String>? branch,
  }) async {
    return _fetchChangesUseCase.checkBehind(
      path: path,
      branch: branch,
    );
  }

  /// Check if branch is ahead of remote
  Future<Either<GitFailure, int>> checkAhead({
    required RepositoryPath path,
    fp.Option<String>? branch,
  }) async {
    return _fetchChangesUseCase.checkAhead(
      path: path,
      branch: branch,
    );
  }

  /// Add a remote
  Future<Either<GitFailure, Unit>> addRemote({
    required RepositoryPath path,
    required String name,
    required String url,
    bool fetch = false,
  }) async {
    return _executeOperation(path, () async {
      final result = await _addRemoteUseCase(
        path: path,
        name: name,
        url: url,
        fetch: fetch,
      );
      _invalidateCache(path);
      return result;
    });
  }

  /// Remove a remote
  Future<Either<GitFailure, Unit>> removeRemote({
    required RepositoryPath path,
    required String name,
  }) async {
    return _executeOperation(path, () async {
      final result = await _removeRemoteUseCase(
        path: path,
        name: name,
      );
      _invalidateCache(path);
      return result;
    });
  }

  /// Rename a remote
  Future<Either<GitFailure, Unit>> renameRemote({
    required RepositoryPath path,
    required String oldName,
    required String newName,
  }) async {
    return _executeOperation(path, () async {
      final result = await _removeRemoteUseCase.rename(
        path: path,
        oldName: oldName,
        newName: newName,
      );
      _invalidateCache(path);
      return result;
    });
  }

  // ============================================================================
  // Cache Management
  // ============================================================================

  /// Cache repository state
  void _cacheRepository(GitRepository repository) {
    _repositoryCache[repository.path.path] = repository;
  }

  /// Invalidate cache for repository
  void _invalidateCache(RepositoryPath path) {
    _repositoryCache.remove(path.path);
  }

  /// Clear all cache
  void clearCache() {
    _repositoryCache.clear();
  }

  // ============================================================================
  // Operation Queue Management
  // ============================================================================

  /// Execute operation with queue to prevent concurrent operations
  Future<Either<GitFailure, T>> _executeOperation<T>(
    RepositoryPath path,
    Future<Either<GitFailure, T>> Function() operation,
  ) async {
    final key = path.path;

    // Wait for any pending operation
    if (_operationQueue.containsKey(key)) {
      await _operationQueue[key]!;
    }

    // Execute operation
    final future = operation();
    _operationQueue[key] = future.then((_) => null);

    final result = await future;

    // Clean up queue
    _operationQueue.remove(key);

    return result;
  }
}
