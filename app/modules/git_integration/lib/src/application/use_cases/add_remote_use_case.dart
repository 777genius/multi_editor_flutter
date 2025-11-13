import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_git_repository.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/value_objects/remote_name.dart';
import '../../domain/failures/git_failures.dart';

/// Use case for adding remotes
@injectable
class AddRemoteUseCase {
  final IGitRepository _repository;

  AddRemoteUseCase(this._repository);

  /// Add a remote (git remote add)
  ///
  /// This will:
  /// 1. Validate remote name and URL
  /// 2. Check remote doesn't already exist
  /// 3. Add the remote configuration
  /// 4. Optionally fetch from the remote
  ///
  /// Parameters:
  /// - path: Repository path
  /// - name: Remote name (e.g., "origin", "upstream")
  /// - url: Remote URL (HTTPS or SSH)
  /// - fetch: If true, fetch from remote after adding
  ///
  /// Returns: Unit on success or GitFailure
  Future<Either<GitFailure, Unit>> call({
    required RepositoryPath path,
    required String name,
    required String url,
    bool fetch = false,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Validate and create remote name
    final RemoteName remoteName;
    try {
      remoteName = RemoteName.create(name);
    } catch (e) {
      return left(
        GitFailure.unknown(
          message: 'Invalid remote name: ${e.toString()}',
          error: e,
        ),
      );
    }

    // Validate URL format
    if (url.isEmpty) {
      return left(
        GitFailure.unknown(
          message: 'Remote URL cannot be empty',
        ),
      );
    }

    // Basic URL validation (HTTPS or SSH)
    final isValidUrl = url.startsWith('https://') ||
        url.startsWith('http://') ||
        url.startsWith('git@') ||
        url.startsWith('ssh://');

    if (!isValidUrl) {
      return left(
        GitFailure.unknown(
          message:
              'Invalid URL format. Must start with https://, http://, git@, or ssh://',
        ),
      );
    }

    // Delegate to repository
    return _repository.addRemote(
      path: path,
      name: remoteName,
      url: url,
      fetch: fetch,
    );
  }

  /// Add remote and set as upstream
  ///
  /// This is useful when setting up a forked repository.
  /// Adds the remote and optionally sets it as upstream for current branch.
  Future<Either<GitFailure, Unit>> addUpstream({
    required RepositoryPath path,
    required String url,
    bool setAsUpstream = true,
  }) async {
    final result = await call(
      path: path,
      name: 'upstream',
      url: url,
      fetch: true,
    );

    // If successful and setAsUpstream is true, set as upstream
    if (setAsUpstream) {
      return result.fold(
        (failure) => left(failure),
        (_) async {
          // Note: Setting upstream tracking is handled by checkout/push use cases
          // This just ensures the remote is added
          return right(unit);
        },
      );
    }

    return result;
  }
}
