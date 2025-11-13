import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_git_repository.dart';
import '../../domain/entities/git_repository.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/failures/git_failures.dart';

/// Use case for getting repository status
@injectable
class GetRepositoryStatusUseCase {
  final IGitRepository _repository;

  GetRepositoryStatusUseCase(this._repository);

  /// Get comprehensive repository status
  ///
  /// This will:
  /// 1. Get current branch
  /// 2. List all changed files (staged and unstaged)
  /// 3. Check for conflicts
  /// 4. Get ahead/behind counts
  ///
  /// Parameters:
  /// - path: Repository path
  /// - fullScan: If true, performs full scan. If false, quick refresh
  ///
  /// Returns: GitRepository entity with current state or GitFailure
  Future<Either<GitFailure, GitRepository>> call({
    required RepositoryPath path,
    bool fullScan = true,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Get status (full scan or quick refresh)
    if (fullScan) {
      return _repository.getStatus(path: path);
    } else {
      return _repository.refreshStatus(path: path);
    }
  }
}
