import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart' as fp;
import '../../domain/repositories/i_git_repository.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/value_objects/remote_name.dart';
import '../../domain/value_objects/branch_name.dart';
import '../../domain/failures/git_failures.dart';

/// Progress callback for push operation
typedef PushProgressCallback = void Function(int current, int total);

/// Use case for pushing changes to remote
@injectable
class PushChangesUseCase {
  final IGitRepository _repository;

  PushChangesUseCase(this._repository);

  /// Push commits to remote (git push)
  ///
  /// This will:
  /// 1. Validate remote exists
  /// 2. Check network connectivity
  /// 3. Authenticate if needed
  /// 4. Push commits
  /// 5. Update remote tracking
  ///
  /// Parameters:
  /// - path: Repository path
  /// - remote: Remote name (default: origin)
  /// - branch: Branch name to push
  /// - force: If true, force push (overwrites remote)
  /// - setUpstream: If true, sets upstream tracking
  /// - onProgress: Optional progress callback
  ///
  /// Returns: Unit on success or GitFailure
  Future<Either<GitFailure, Unit>> call({
    required RepositoryPath path,
    String remote = 'origin',
    required String branch,
    bool force = false,
    bool setUpstream = false,
    PushProgressCallback? onProgress,
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
      remoteName = RemoteName.create(remote);
    } catch (e) {
      return left(
        GitFailure.unknown(
          message: 'Invalid remote name: ${e.toString()}',
          error: e,
        ),
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

    // Warn about force push to main/master
    if (force && branchName.isMainBranch) {
      // Note: In UI, should show confirmation dialog
      // For now, just log warning
    }

    // Delegate to repository
    return _repository.push(
      path: path,
      remote: remoteName,
      branch: branchName,
      force: force,
      setUpstream: setUpstream,
      onProgress: onProgress,
    );
  }
}
