import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_git_repository.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/failures/git_failures.dart';

/// Use case for staging files
@injectable
class StageFilesUseCase {
  final IGitRepository _repository;

  StageFilesUseCase(this._repository);

  /// Stage files for commit (git add)
  ///
  /// This will:
  /// 1. Validate files exist and have changes
  /// 2. Add files to staging area
  /// 3. Update index
  ///
  /// Parameters:
  /// - path: Repository path
  /// - filePaths: List of file paths to stage (relative to repo root)
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
    return _repository.stageFiles(
      path: path,
      filePaths: filePaths,
    );
  }

  /// Stage all changes (git add .)
  Future<Either<GitFailure, Unit>> stageAll({
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
    return _repository.stageAll(path: path);
  }
}
