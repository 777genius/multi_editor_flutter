import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_git_repository.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/value_objects/branch_name.dart';
import '../../domain/failures/git_failures.dart';

/// Use case for checking out branches
@injectable
class CheckoutBranchUseCase {
  final IGitRepository _repository;

  CheckoutBranchUseCase(this._repository);

  /// Checkout a branch (git checkout)
  ///
  /// This will:
  /// 1. Validate branch exists
  /// 2. Check for uncommitted changes (unless forced)
  /// 3. Switch working directory to branch
  /// 4. Update HEAD
  ///
  /// Parameters:
  /// - path: Repository path
  /// - branch: Branch name to checkout
  /// - force: If true, discard local changes
  ///
  /// Returns: Unit on success or GitFailure
  Future<Either<GitFailure, Unit>> call({
    required RepositoryPath path,
    required String branch,
    bool force = false,
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
    return _repository.checkout(
      path: path,
      branch: branchName,
      force: force,
    );
  }
}
