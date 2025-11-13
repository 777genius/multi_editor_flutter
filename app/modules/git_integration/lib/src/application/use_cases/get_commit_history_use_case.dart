import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart' as fp;
import '../../domain/repositories/i_git_repository.dart';
import '../../domain/entities/git_commit.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/value_objects/branch_name.dart';
import '../../domain/failures/git_failures.dart';

/// Use case for getting commit history
@injectable
class GetCommitHistoryUseCase {
  final IGitRepository _repository;

  GetCommitHistoryUseCase(this._repository);

  /// Get commit history (git log)
  ///
  /// This will:
  /// 1. Get commits from specified branch (or current)
  /// 2. Support pagination with maxCount and skip
  /// 3. Include commit metadata (author, message, files)
  ///
  /// Parameters:
  /// - path: Repository path
  /// - branch: Optional branch name (uses current if not specified)
  /// - maxCount: Maximum number of commits to return
  /// - skip: Number of commits to skip (for pagination)
  ///
  /// Returns: List of GitCommit or GitFailure
  Future<Either<GitFailure, List<GitCommit>>> call({
    required RepositoryPath path,
    fp.Option<String>? branch,
    int maxCount = 100,
    int skip = 0,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Validate pagination parameters
    if (maxCount <= 0) {
      return left(
        GitFailure.unknown(
          message: 'maxCount must be positive',
        ),
      );
    }

    if (skip < 0) {
      return left(
        GitFailure.unknown(
          message: 'skip must be non-negative',
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
    return _repository.getHistory(
      path: path,
      branch: branchName,
      maxCount: maxCount,
      skip: skip,
    );
  }

  /// Get file history (git log -- file)
  Future<Either<GitFailure, List<GitCommit>>> getFileHistory({
    required RepositoryPath path,
    required String filePath,
    int maxCount = 100,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Validate file path
    if (filePath.isEmpty) {
      return left(
        GitFailure.unknown(
          message: 'File path cannot be empty',
        ),
      );
    }

    // Delegate to repository
    return _repository.getFileHistory(
      path: path,
      filePath: filePath,
      maxCount: maxCount,
    );
  }
}
