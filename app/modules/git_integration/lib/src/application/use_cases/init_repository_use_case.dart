import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_git_repository.dart';
import '../../domain/entities/git_repository.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/failures/git_failures.dart';

/// Use case for initializing a new Git repository
@injectable
class InitRepositoryUseCase {
  final IGitRepository _repository;

  InitRepositoryUseCase(this._repository);

  /// Initialize a new Git repository at the given path
  ///
  /// This will:
  /// 1. Create .git directory structure
  /// 2. Initialize default branch (main/master)
  /// 3. Create initial configuration
  ///
  /// Returns: GitRepository entity or GitFailure
  Future<Either<GitFailure, GitRepository>> call({
    required RepositoryPath path,
  }) async {
    // Validate path exists (directory should exist before init)
    final pathExists = await path.exists();
    if (pathExists) {
      // Path has .git already - not allowed to reinitialize
      return left(
        GitFailure.notARepository(path: path),
      );
    }

    // Delegate to repository
    return _repository.init(path: path);
  }
}
