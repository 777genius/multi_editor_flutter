import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_git_repository.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/failures/git_failures.dart';

/// Use case for applying stashed changes
@injectable
class ApplyStashUseCase {
  final IGitRepository _repository;

  ApplyStashUseCase(this._repository);

  /// Apply stashed changes (git stash apply)
  ///
  /// This will:
  /// 1. Get stash from stack
  /// 2. Apply changes to working directory
  /// 3. Keep stash in stack (unless pop=true)
  /// 4. Handle conflicts if any
  ///
  /// Parameters:
  /// - path: Repository path
  /// - stashIndex: Stash index to apply (0 = most recent)
  /// - pop: If true, remove stash after applying (git stash pop)
  /// - restoreIndex: If true, restore staged state
  ///
  /// Returns: Unit on success or GitFailure
  Future<Either<GitFailure, Unit>> call({
    required RepositoryPath path,
    int stashIndex = 0,
    bool pop = false,
    bool restoreIndex = false,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Validate stash index
    if (stashIndex < 0) {
      return left(
        GitFailure.unknown(
          message: 'Stash index must be non-negative',
        ),
      );
    }

    // Delegate to repository
    return _repository.applyStash(
      path: path,
      stashIndex: stashIndex,
      pop: pop,
      restoreIndex: restoreIndex,
    );
  }

  /// Pop most recent stash (git stash pop)
  ///
  /// This is a convenience method for the most common use case.
  Future<Either<GitFailure, Unit>> pop({
    required RepositoryPath path,
    bool restoreIndex = false,
  }) async {
    return call(
      path: path,
      stashIndex: 0,
      pop: true,
      restoreIndex: restoreIndex,
    );
  }

  /// Apply most recent stash without removing it
  ///
  /// This allows you to apply the same stash multiple times.
  Future<Either<GitFailure, Unit>> apply({
    required RepositoryPath path,
    bool restoreIndex = false,
  }) async {
    return call(
      path: path,
      stashIndex: 0,
      pop: false,
      restoreIndex: restoreIndex,
    );
  }

  /// Drop a stash without applying it (git stash drop)
  ///
  /// This permanently removes a stash from the stack.
  Future<Either<GitFailure, Unit>> drop({
    required RepositoryPath path,
    int stashIndex = 0,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Validate stash index
    if (stashIndex < 0) {
      return left(
        GitFailure.unknown(
          message: 'Stash index must be non-negative',
        ),
      );
    }

    // Delegate to repository
    return _repository.dropStash(
      path: path,
      stashIndex: stashIndex,
    );
  }

  /// Clear all stashes (git stash clear)
  ///
  /// This permanently removes all stashes from the stack.
  /// Use with caution!
  Future<Either<GitFailure, Unit>> clear({
    required RepositoryPath path,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Note: In UI, should show confirmation dialog
    // "Are you sure you want to clear all stashes? This cannot be undone."

    // Delegate to repository
    return _repository.clearStashes(path: path);
  }

  /// Create a branch from a stash (git stash branch)
  ///
  /// This creates a new branch and applies the stash to it.
  /// Useful when you want to continue work on stashed changes
  /// in a separate branch.
  Future<Either<GitFailure, Unit>> createBranchFromStash({
    required RepositoryPath path,
    required String branchName,
    int stashIndex = 0,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Validate stash index
    if (stashIndex < 0) {
      return left(
        GitFailure.unknown(
          message: 'Stash index must be non-negative',
        ),
      );
    }

    // Validate branch name
    if (branchName.isEmpty) {
      return left(
        GitFailure.unknown(
          message: 'Branch name cannot be empty',
        ),
      );
    }

    // Delegate to repository
    return _repository.createBranchFromStash(
      path: path,
      branchName: branchName,
      stashIndex: stashIndex,
    );
  }
}
