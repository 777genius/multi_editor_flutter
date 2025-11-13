import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_git_repository.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/value_objects/branch_name.dart';
import '../../domain/failures/git_failures.dart';

/// Use case for rebasing branches
@injectable
class RebaseBranchUseCase {
  final IGitRepository _repository;

  RebaseBranchUseCase(this._repository);

  /// Rebase current branch onto another branch (git rebase)
  ///
  /// This will:
  /// 1. Validate both branches exist
  /// 2. Check for uncommitted changes
  /// 3. Find common ancestor
  /// 4. Replay commits from current branch onto target branch
  /// 5. Handle conflicts if any
  ///
  /// Parameters:
  /// - path: Repository path
  /// - onto: Branch name to rebase onto
  /// - interactive: If true, start interactive rebase
  ///
  /// Returns: Unit on success or GitFailure (including rebase conflicts)
  Future<Either<GitFailure, Unit>> call({
    required RepositoryPath path,
    required String onto,
    bool interactive = false,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Validate and create branch name
    final BranchName ontoBranch;
    try {
      ontoBranch = BranchName.create(onto);
    } catch (e) {
      return left(
        GitFailure.unknown(
          message: 'Invalid branch name: ${e.toString()}',
          error: e,
        ),
      );
    }

    // Delegate to repository
    // Note: If rebase conflicts occur, repository will return
    // GitFailure.rebaseConflict which caller can handle
    return _repository.rebase(
      path: path,
      onto: ontoBranch,
      interactive: interactive,
    );
  }

  /// Continue rebase after resolving conflicts (git rebase --continue)
  ///
  /// This is called after user has resolved conflicts during a rebase.
  Future<Either<GitFailure, Unit>> continue_({
    required RepositoryPath path,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Delegate to repository
    return _repository.rebaseContinue(path: path);
  }

  /// Skip current commit during rebase (git rebase --skip)
  ///
  /// This skips the current commit that is causing conflicts.
  /// Use when you want to discard the problematic commit.
  Future<Either<GitFailure, Unit>> skip({
    required RepositoryPath path,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Delegate to repository
    return _repository.rebaseSkip(path: path);
  }

  /// Abort rebase and return to original state (git rebase --abort)
  ///
  /// This cancels the rebase and restores the branch to its
  /// state before the rebase started.
  Future<Either<GitFailure, Unit>> abort({
    required RepositoryPath path,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Delegate to repository
    return _repository.rebaseAbort(path: path);
  }

  /// Check if repository is currently in rebase state
  ///
  /// Returns true if a rebase is in progress and needs to be
  /// continued, skipped, or aborted.
  Future<Either<GitFailure, bool>> isRebaseInProgress({
    required RepositoryPath path,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Delegate to repository
    return _repository.isRebaseInProgress(path: path);
  }

  /// Interactive rebase with specific commit range
  ///
  /// This allows you to reorder, squash, edit, or drop commits
  /// in the specified range.
  ///
  /// Parameters:
  /// - path: Repository path
  /// - fromCommit: Start of commit range (exclusive)
  /// - toCommit: End of commit range (inclusive, default: HEAD)
  Future<Either<GitFailure, Unit>> interactiveRange({
    required RepositoryPath path,
    required String fromCommit,
    String toCommit = 'HEAD',
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Validate commit references
    if (fromCommit.isEmpty || toCommit.isEmpty) {
      return left(
        GitFailure.unknown(
          message: 'Commit references cannot be empty',
        ),
      );
    }

    // Delegate to repository
    return _repository.rebaseInteractiveRange(
      path: path,
      fromCommit: fromCommit,
      toCommit: toCommit,
    );
  }
}
