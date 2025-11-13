import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_git_repository.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/value_objects/remote_name.dart';
import '../../domain/failures/git_failures.dart';

/// Use case for removing remotes
@injectable
class RemoveRemoteUseCase {
  final IGitRepository _repository;

  RemoveRemoteUseCase(this._repository);

  /// Remove a remote (git remote remove)
  ///
  /// This will:
  /// 1. Validate remote name
  /// 2. Check remote exists
  /// 3. Remove the remote configuration
  /// 4. Clean up remote tracking branches
  ///
  /// Parameters:
  /// - path: Repository path
  /// - name: Remote name to remove
  ///
  /// Returns: Unit on success or GitFailure
  Future<Either<GitFailure, Unit>> call({
    required RepositoryPath path,
    required String name,
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

    // Warn if trying to remove 'origin'
    if (name == 'origin') {
      // Note: In UI, should show confirmation dialog
      // "Are you sure you want to remove the 'origin' remote?"
    }

    // Delegate to repository
    return _repository.removeRemote(
      path: path,
      name: remoteName,
    );
  }

  /// Rename a remote (git remote rename)
  ///
  /// This is a convenience method that removes the old remote
  /// and adds a new one with the same URL.
  Future<Either<GitFailure, Unit>> rename({
    required RepositoryPath path,
    required String oldName,
    required String newName,
  }) async {
    // Validate both names
    final RemoteName oldRemoteName;
    final RemoteName newRemoteName;

    try {
      oldRemoteName = RemoteName.create(oldName);
      newRemoteName = RemoteName.create(newName);
    } catch (e) {
      return left(
        GitFailure.unknown(
          message: 'Invalid remote name: ${e.toString()}',
          error: e,
        ),
      );
    }

    // Delegate to repository
    return _repository.renameRemote(
      path: path,
      oldName: oldRemoteName,
      newName: newRemoteName,
    );
  }
}
