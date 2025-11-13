import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_git_repository.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/value_objects/remote_name.dart';
import '../../domain/failures/git_failures.dart';

/// Use case for renaming remotes
@injectable
class RenameRemoteUseCase {
  final IGitRepository _repository;

  RenameRemoteUseCase(this._repository);

  /// Rename a remote (git remote rename)
  ///
  /// This will:
  /// 1. Validate both old and new remote names
  /// 2. Check old remote exists
  /// 3. Check new remote doesn't already exist
  /// 4. Rename the remote configuration
  /// 5. Update all remote-tracking branches
  ///
  /// Parameters:
  /// - path: Repository path
  /// - oldName: Current remote name
  /// - newName: New remote name
  ///
  /// Returns: Unit on success or GitFailure
  Future<Either<GitFailure, Unit>> call({
    required RepositoryPath path,
    required String oldName,
    required String newName,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

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

    // Warn if renaming 'origin'
    if (oldName == 'origin') {
      // Note: In UI, should show confirmation dialog
      // "Are you sure you want to rename the 'origin' remote?"
    }

    // Delegate to repository
    return _repository.renameRemote(
      path: path,
      oldName: oldRemoteName,
      newName: newRemoteName,
    );
  }
}
