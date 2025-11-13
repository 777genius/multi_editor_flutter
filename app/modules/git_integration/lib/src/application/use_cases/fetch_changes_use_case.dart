import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart' as fp;
import '../../domain/repositories/i_git_repository.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/value_objects/remote_name.dart';
import '../../domain/value_objects/branch_name.dart';
import '../../domain/failures/git_failures.dart';

/// Progress callback for fetch operation
typedef FetchProgressCallback = void Function(int current, int total);

/// Use case for fetching changes from remote
@injectable
class FetchChangesUseCase {
  final IGitRepository _repository;

  FetchChangesUseCase(this._repository);

  /// Fetch commits from remote (git fetch)
  ///
  /// This will:
  /// 1. Connect to remote repository
  /// 2. Download new commits and objects
  /// 3. Update remote tracking branches
  /// 4. Does NOT merge changes (unlike pull)
  ///
  /// Parameters:
  /// - path: Repository path
  /// - remote: Remote name (default: origin)
  /// - branch: Optional branch name (fetches all if not specified)
  /// - prune: If true, remove remote tracking branches that no longer exist
  /// - tags: If true, fetch tags as well
  /// - onProgress: Optional progress callback
  ///
  /// Returns: Unit on success or GitFailure
  Future<Either<GitFailure, Unit>> call({
    required RepositoryPath path,
    String remote = 'origin',
    fp.Option<String>? branch,
    bool prune = false,
    bool tags = true,
    FetchProgressCallback? onProgress,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Validate and create remote name
    final RemoteName remoteName;
    try {
      remoteName = RemoteName.create(remote);
    } catch (e) {
      return left(
        GitFailure.unknown(
          message: 'Invalid remote name: ${e.toString()}',
          error: e,
        ),
      );
    }

    // Validate and create branch name if provided
    fp.Option<BranchName>? branchName;
    if (branch != null && branch is fp.Some<String>) {
      final branchStr = (branch as fp.Some<String>).value;
      try {
        branchName = fp.some(BranchName.create(branchStr));
      } catch (e) {
        return left(
          GitFailure.unknown(
            message: 'Invalid branch name: ${e.toString()}',
            error: e,
          ),
        );
      }
    }

    // Delegate to repository
    return _repository.fetch(
      path: path,
      remote: remoteName,
      branch: branchName,
      prune: prune,
      tags: tags,
      onProgress: onProgress,
    );
  }

  /// Fetch from all remotes
  ///
  /// This is useful for keeping up-to-date with multiple remotes
  /// (e.g., origin and upstream in a fork workflow).
  Future<Either<GitFailure, Unit>> fetchAll({
    required RepositoryPath path,
    bool prune = false,
    bool tags = true,
    FetchProgressCallback? onProgress,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Delegate to repository
    return _repository.fetchAll(
      path: path,
      prune: prune,
      tags: tags,
      onProgress: onProgress,
    );
  }

  /// Check if local branch is behind remote
  ///
  /// This compares the local branch with its remote tracking branch
  /// to determine if there are new commits to pull.
  ///
  /// Returns: Number of commits behind (0 if up-to-date)
  Future<Either<GitFailure, int>> checkBehind({
    required RepositoryPath path,
    fp.Option<String>? branch,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Validate and create branch name if provided
    fp.Option<BranchName>? branchName;
    if (branch != null && branch is fp.Some<String>) {
      final branchStr = (branch as fp.Some<String>).value;
      try {
        branchName = fp.some(BranchName.create(branchStr));
      } catch (e) {
        return left(
          GitFailure.unknown(
            message: 'Invalid branch name: ${e.toString()}',
            error: e,
          ),
        );
      }
    }

    // Delegate to repository
    return _repository.checkBehind(
      path: path,
      branch: branchName,
    );
  }

  /// Check if local branch is ahead of remote
  ///
  /// This compares the local branch with its remote tracking branch
  /// to determine if there are local commits to push.
  ///
  /// Returns: Number of commits ahead (0 if nothing to push)
  Future<Either<GitFailure, int>> checkAhead({
    required RepositoryPath path,
    fp.Option<String>? branch,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Validate and create branch name if provided
    fp.Option<BranchName>? branchName;
    if (branch != null && branch is fp.Some<String>) {
      final branchStr = (branch as fp.Some<String>).value;
      try {
        branchName = fp.some(BranchName.create(branchStr));
      } catch (e) {
        return left(
          GitFailure.unknown(
            message: 'Invalid branch name: ${e.toString()}',
            error: e,
          ),
        );
      }
    }

    // Delegate to repository
    return _repository.checkAhead(
      path: path,
      branch: branchName,
    );
  }
}
