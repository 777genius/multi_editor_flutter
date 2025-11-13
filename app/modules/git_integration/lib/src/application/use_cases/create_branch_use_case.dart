import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart' as fp;
import '../../domain/repositories/i_git_repository.dart';
import '../../domain/entities/git_branch.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/value_objects/branch_name.dart';
import '../../domain/value_objects/commit_hash.dart';
import '../../domain/failures/git_failures.dart';

/// Use case for creating branches
@injectable
class CreateBranchUseCase {
  final IGitRepository _repository;

  CreateBranchUseCase(this._repository);

  /// Create a new branch (git branch)
  ///
  /// This will:
  /// 1. Validate branch name follows git rules
  /// 2. Check branch doesn't already exist
  /// 3. Create branch at specified commit (or HEAD)
  ///
  /// Parameters:
  /// - path: Repository path
  /// - name: Branch name (will be validated)
  /// - startPoint: Optional commit hash to start from (default: HEAD)
  ///
  /// Returns: Created GitBranch or GitFailure
  Future<Either<GitFailure, GitBranch>> call({
    required RepositoryPath path,
    required String name,
    fp.Option<CommitHash>? startPoint,
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
      branchName = BranchName.create(name);
    } catch (e) {
      return left(
        GitFailure.unknown(
          message: 'Invalid branch name: ${e.toString()}',
          error: e,
        ),
      );
    }

    // Delegate to repository
    return _repository.createBranch(
      path: path,
      name: branchName,
      startPoint: startPoint,
    );
  }
}
