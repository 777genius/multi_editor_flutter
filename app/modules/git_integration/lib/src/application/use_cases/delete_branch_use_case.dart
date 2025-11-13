import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_git_repository.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/value_objects/branch_name.dart';
import '../../domain/failures/git_failures.dart';

/// Use case for deleting branches
@injectable
class DeleteBranchUseCase {
  final IGitRepository _repository;

  DeleteBranchUseCase(this._repository);

  /// Delete a branch (git branch -d/-D)
  ///
  /// This will:
  /// 1. Validate branch exists
  /// 2. Check if branch is current (cannot delete current branch)
  /// 3. Check if branch is fully merged (unless force=true)
  /// 4. Delete the branch
  ///
  /// Parameters:
  /// - path: Repository path
  /// - branch: Branch name to delete
  /// - force: If true, force delete unmerged branch (-D)
  /// - remote: If true, delete remote branch instead of local
  ///
  /// Returns: Unit on success or GitFailure
  Future<Either<GitFailure, Unit>> call({
    required RepositoryPath path,
    required String branch,
    bool force = false,
    bool remote = false,
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

    // Check if trying to delete main branch
    if (branchName.isMainBranch && !force) {
      return left(
        GitFailure.unknown(
          message: 'Cannot delete main branch without force flag',
        ),
      );
    }

    // Delegate to repository
    return _repository.deleteBranch(
      path: path,
      branch: branchName,
      force: force,
      remote: remote,
    );
  }

  /// Delete multiple branches at once
  ///
  /// This is useful for cleaning up merged feature branches.
  /// Will skip any branches that fail to delete and continue with others.
  ///
  /// Returns: Map of branch names to results (success or failure)
  Future<Map<String, Either<GitFailure, Unit>>> deleteMultiple({
    required RepositoryPath path,
    required List<String> branches,
    bool force = false,
  }) async {
    final results = <String, Either<GitFailure, Unit>>{};

    for (final branch in branches) {
      final result = await call(
        path: path,
        branch: branch,
        force: force,
      );
      results[branch] = result;
    }

    return results;
  }
}
