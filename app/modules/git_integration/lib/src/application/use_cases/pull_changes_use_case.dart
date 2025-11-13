import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart' as fp;
import '../../domain/repositories/i_git_repository.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/value_objects/remote_name.dart';
import '../../domain/value_objects/branch_name.dart';
import '../../domain/failures/git_failures.dart';

/// Progress callback for pull operation
typedef PullProgressCallback = void Function(int current, int total);

/// Use case for pulling changes from remote
@injectable
class PullChangesUseCase {
  final IGitRepository _repository;

  PullChangesUseCase(this._repository);

  /// Pull commits from remote (git pull)
  ///
  /// This will:
  /// 1. Fetch from remote
  /// 2. Merge or rebase with local branch
  /// 3. Handle conflicts if any
  /// 4. Update working directory
  ///
  /// Parameters:
  /// - path: Repository path
  /// - remote: Remote name (default: origin)
  /// - branch: Optional branch name (uses current if not specified)
  /// - rebase: If true, rebase instead of merge
  /// - onProgress: Optional progress callback
  ///
  /// Returns: Unit on success or GitFailure
  Future<Either<GitFailure, Unit>> call({
    required RepositoryPath path,
    String remote = 'origin',
    fp.Option<String>? branch,
    bool rebase = false,
    PullProgressCallback? onProgress,
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
    return _repository.pull(
      path: path,
      remote: remoteName,
      branch: branchName,
      rebase: rebase,
      onProgress: onProgress,
    );
  }
}
