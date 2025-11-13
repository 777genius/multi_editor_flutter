import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_git_repository.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/value_objects/branch_name.dart';
import '../../domain/failures/git_failures.dart';

/// Use case for merging branches
@injectable
class MergeBranchUseCase {
  final IGitRepository _repository;

  MergeBranchUseCase(this._repository);

  /// Merge a branch into current branch (git merge)
  ///
  /// This will:
  /// 1. Validate both branches exist
  /// 2. Check for uncommitted changes
  /// 3. Perform merge (fast-forward or 3-way)
  /// 4. Handle conflicts if any
  ///
  /// Parameters:
  /// - path: Repository path
  /// - branch: Branch name to merge into current branch
  /// - noFastForward: If true, always create merge commit
  ///
  /// Returns: Unit on success or GitFailure (including merge conflicts)
  Future<Either<GitFailure, Unit>> call({
    required RepositoryPath path,
    required String branch,
    bool noFastForward = false,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Validate and create branch name
    final BranchName branchName;
    try {
      branchName = BranchName.create(branch);
    } catch (e) {
      return left(
        GitFailure.unknown(
          message: 'Invalid branch name: ${e.toString()}',
          error: e,
        ),
      );
    }

    // Delegate to repository
    // Note: If merge conflicts occur, repository will return
    // GitFailure.mergeConflict which caller can handle
    return _repository.merge(
      path: path,
      branch: branchName,
      noFastForward: noFastForward,
    );
  }
}
