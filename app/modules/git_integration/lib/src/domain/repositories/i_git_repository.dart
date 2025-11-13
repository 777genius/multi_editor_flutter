import 'package:dartz/dartz.dart';
import '../entities/git_repository.dart';
import '../entities/git_commit.dart';
import '../entities/git_branch.dart';
import '../entities/git_remote.dart';
import '../entities/git_stash.dart';
import '../value_objects/repository_path.dart';
import '../value_objects/commit_message.dart';
import '../value_objects/git_author.dart';
import '../value_objects/branch_name.dart';
import '../value_objects/remote_name.dart';
import '../value_objects/commit_hash.dart';
import '../failures/git_failures.dart';

/// Progress callback for long-running operations
typedef ProgressCallback = void Function(int current, int total);

/// Main git operations repository interface
abstract class IGitRepository {
  // ===== Repository Operations =====

  /// Initialize new repository
  Future<Either<GitFailure, GitRepository>> init({
    required RepositoryPath path,
  });

  /// Clone repository
  Future<Either<GitFailure, GitRepository>> clone({
    required String url,
    required RepositoryPath path,
    Option<String>? branch,
    ProgressCallback? onProgress,
  });

  /// Open existing repository
  Future<Either<GitFailure, GitRepository>> open({
    required RepositoryPath path,
  });

  // ===== Status Operations =====

  /// Get repository status (full scan)
  Future<Either<GitFailure, GitRepository>> getStatus({
    required RepositoryPath path,
  });

  /// Refresh status (fast update)
  Future<Either<GitFailure, GitRepository>> refreshStatus({
    required RepositoryPath path,
  });

  // ===== Staging Operations =====

  /// Stage files
  Future<Either<GitFailure, Unit>> stageFiles({
    required RepositoryPath path,
    required List<String> filePaths,
  });

  /// Unstage files
  Future<Either<GitFailure, Unit>> unstageFiles({
    required RepositoryPath path,
    required List<String> filePaths,
  });

  /// Stage all changes
  Future<Either<GitFailure, Unit>> stageAll({
    required RepositoryPath path,
  });

  /// Unstage all changes
  Future<Either<GitFailure, Unit>> unstageAll({
    required RepositoryPath path,
  });

  // ===== Commit Operations =====

  /// Create commit
  Future<Either<GitFailure, GitCommit>> commit({
    required RepositoryPath path,
    required CommitMessage message,
    required GitAuthor author,
    bool amend = false,
  });

  /// Amend last commit
  Future<Either<GitFailure, GitCommit>> amendCommit({
    required RepositoryPath path,
    Option<CommitMessage>? newMessage,
  });

  // ===== Branch Operations =====

  /// Get all branches
  Future<Either<GitFailure, List<GitBranch>>> getBranches({
    required RepositoryPath path,
    bool includeRemote = true,
  });

  /// Create branch
  Future<Either<GitFailure, GitBranch>> createBranch({
    required RepositoryPath path,
    required BranchName name,
    Option<CommitHash>? startPoint,
  });

  /// Delete branch
  Future<Either<GitFailure, Unit>> deleteBranch({
    required RepositoryPath path,
    required BranchName name,
    bool force = false,
  });

  /// Checkout branch
  Future<Either<GitFailure, Unit>> checkout({
    required RepositoryPath path,
    required BranchName branch,
    bool force = false,
  });

  /// Merge branch
  Future<Either<GitFailure, Unit>> merge({
    required RepositoryPath path,
    required BranchName branch,
    bool noFastForward = false,
  });

  /// Rebase branch
  Future<Either<GitFailure, Unit>> rebase({
    required RepositoryPath path,
    required BranchName targetBranch,
  });

  // ===== Remote Operations =====

  /// Get remotes
  Future<Either<GitFailure, List<GitRemote>>> getRemotes({
    required RepositoryPath path,
  });

  /// Add remote
  Future<Either<GitFailure, GitRemote>> addRemote({
    required RepositoryPath path,
    required RemoteName name,
    required String url,
  });

  /// Remove remote
  Future<Either<GitFailure, Unit>> removeRemote({
    required RepositoryPath path,
    required RemoteName name,
  });

  /// Fetch from remote
  Future<Either<GitFailure, Unit>> fetch({
    required RepositoryPath path,
    required RemoteName remote,
    Option<BranchName>? branch,
    ProgressCallback? onProgress,
  });

  /// Pull from remote
  Future<Either<GitFailure, Unit>> pull({
    required RepositoryPath path,
    required RemoteName remote,
    Option<BranchName>? branch,
    bool rebase = false,
    ProgressCallback? onProgress,
  });

  /// Push to remote
  Future<Either<GitFailure, Unit>> push({
    required RepositoryPath path,
    required RemoteName remote,
    required BranchName branch,
    bool force = false,
    bool setUpstream = false,
    ProgressCallback? onProgress,
  });

  // ===== History Operations =====

  /// Get commit history
  Future<Either<GitFailure, List<GitCommit>>> getHistory({
    required RepositoryPath path,
    Option<BranchName>? branch,
    int maxCount = 100,
    int skip = 0,
  });

  /// Get file history
  Future<Either<GitFailure, List<GitCommit>>> getFileHistory({
    required RepositoryPath path,
    required String filePath,
    int maxCount = 100,
  });

  // ===== Stash Operations =====

  /// Get stashes
  Future<Either<GitFailure, List<GitStash>>> getStashes({
    required RepositoryPath path,
  });

  /// Create stash
  Future<Either<GitFailure, GitStash>> stash({
    required RepositoryPath path,
    Option<String>? message,
    bool includeUntracked = false,
  });

  /// Apply stash
  Future<Either<GitFailure, Unit>> applyStash({
    required RepositoryPath path,
    required int stashIndex,
    bool pop = false,
  });

  /// Drop stash
  Future<Either<GitFailure, Unit>> dropStash({
    required RepositoryPath path,
    required int stashIndex,
  });
}
