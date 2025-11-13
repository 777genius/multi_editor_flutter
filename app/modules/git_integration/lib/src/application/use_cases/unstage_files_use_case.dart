import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_git_repository.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/failures/git_failures.dart';

/// Use case for unstaging files
@injectable
class UnstageFilesUseCase {
  final IGitRepository _repository;

  UnstageFilesUseCase(this._repository);

  /// Unstage files (git reset HEAD)
  ///
  /// This will:
  /// 1. Remove files from staging area
  /// 2. Keep modifications in working directory
  /// 3. Update index
  ///
  /// Parameters:
  /// - path: Repository path
  /// - filePaths: List of file paths to unstage
  ///
  /// Returns: Unit on success or GitFailure
  Future<Either<GitFailure, Unit>> call({
    required RepositoryPath path,
    required List<String> filePaths,
  }) async {
    // Validate input
    if (filePaths.isEmpty) {
      return right(unit); // Nothing to do
    }

    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Delegate to repository
    return _repository.unstageFiles(
      path: path,
      filePaths: filePaths,
    );
  }

  /// Unstage all changes (git reset HEAD)
  Future<Either<GitFailure, Unit>> unstageAll({
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
    return _repository.unstageAll(path: path);
  }
}
