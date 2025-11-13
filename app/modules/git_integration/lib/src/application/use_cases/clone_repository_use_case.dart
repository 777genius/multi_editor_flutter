import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart' as fp;
import '../../domain/repositories/i_git_repository.dart';
import '../../domain/entities/git_repository.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/failures/git_failures.dart';

/// Progress callback for clone operation
typedef CloneProgressCallback = void Function(int current, int total);

/// Use case for cloning a Git repository
@injectable
class CloneRepositoryUseCase {
  final IGitRepository _repository;

  CloneRepositoryUseCase(this._repository);

  /// Clone a Git repository from URL to local path
  ///
  /// This will:
  /// 1. Validate URL format
  /// 2. Clone repository with all history
  /// 3. Setup remote tracking
  /// 4. Checkout specified branch (or default)
  ///
  /// Parameters:
  /// - url: Remote repository URL (HTTPS, SSH, or local path)
  /// - path: Local destination path
  /// - branch: Optional specific branch to checkout
  /// - onProgress: Optional progress callback
  ///
  /// Returns: GitRepository entity or GitFailure
  Future<Either<GitFailure, GitRepository>> call({
    required String url,
    required RepositoryPath path,
    fp.Option<String>? branch,
    CloneProgressCallback? onProgress,
  }) async {
    // Validate URL format
    if (!_isValidGitUrl(url)) {
      return left(
        GitFailure.invalidUrl(url: url),
      );
    }

    // Check if target path already exists
    final pathExists = await path.exists();
    if (pathExists) {
      return left(
        GitFailure.notARepository(path: path),
      );
    }

    // Delegate to repository
    return _repository.clone(
      url: url,
      path: path,
      branch: branch,
      onProgress: onProgress,
    );
  }

  /// Validate Git URL format
  bool _isValidGitUrl(String url) {
    // SSH format: git@github.com:user/repo.git
    final sshPattern = RegExp(r'^git@[\w\.-]+:[\w\-]+/[\w\-]+\.git$');
    if (sshPattern.hasMatch(url)) return true;

    // HTTPS format: https://github.com/user/repo.git
    final httpsPattern = RegExp(
      r'^https?://[\w\.-]+/[\w\-]+/[\w\-]+\.git$',
    );
    if (httpsPattern.hasMatch(url)) return true;

    // Local path: /path/to/repo or file:///path/to/repo
    if (url.startsWith('/') || url.startsWith('file://')) {
      return true;
    }

    return false;
  }
}
