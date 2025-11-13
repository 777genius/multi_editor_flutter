import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_git_repository.dart';
import '../../domain/entities/git_stash.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/failures/git_failures.dart';

/// Use case for stashing changes
@injectable
class StashChangesUseCase {
  final IGitRepository _repository;

  StashChangesUseCase(this._repository);

  /// Stash current changes (git stash push)
  ///
  /// This will:
  /// 1. Save all uncommitted changes (staged and unstaged)
  /// 2. Optionally save untracked files
  /// 3. Restore working directory to clean state
  /// 4. Store changes in stash stack
  ///
  /// Parameters:
  /// - path: Repository path
  /// - message: Optional stash message
  /// - includeUntracked: If true, stash untracked files too
  /// - keepIndex: If true, keep staged changes in index
  ///
  /// Returns: GitStash on success or GitFailure
  Future<Either<GitFailure, GitStash>> call({
    required RepositoryPath path,
    String? message,
    bool includeUntracked = false,
    bool keepIndex = false,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Validate message if provided
    if (message != null && message.trim().isEmpty) {
      return left(
        GitFailure.unknown(
          message: 'Stash message cannot be empty',
        ),
      );
    }

    // Delegate to repository
    return _repository.stash(
      path: path,
      message: message,
      includeUntracked: includeUntracked,
      keepIndex: keepIndex,
    );
  }

  /// Quick stash with default settings
  ///
  /// This is a convenience method for the most common stash use case.
  Future<Either<GitFailure, GitStash>> quickStash({
    required RepositoryPath path,
  }) async {
    return call(
      path: path,
      message: null,
      includeUntracked: false,
      keepIndex: false,
    );
  }

  /// Stash only specific files
  ///
  /// This allows selective stashing of changes.
  Future<Either<GitFailure, GitStash>> stashFiles({
    required RepositoryPath path,
    required List<String> filePaths,
    String? message,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Validate file paths
    if (filePaths.isEmpty) {
      return left(
        GitFailure.unknown(
          message: 'File paths cannot be empty',
        ),
      );
    }

    // Delegate to repository
    return _repository.stashFiles(
      path: path,
      filePaths: filePaths,
      message: message,
    );
  }

  /// Get list of all stashes
  ///
  /// Returns the stash stack with most recent first.
  Future<Either<GitFailure, List<GitStash>>> getStashes({
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
    return _repository.getStashes(path: path);
  }

  /// Show stash diff
  ///
  /// Returns the changes in a specific stash.
  Future<Either<GitFailure, String>> showStash({
    required RepositoryPath path,
    required int stashIndex,
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
    return _repository.showStash(
      path: path,
      stashIndex: stashIndex,
    );
  }
}
