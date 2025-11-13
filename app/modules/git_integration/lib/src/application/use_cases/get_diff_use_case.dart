import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_diff_repository.dart';
import '../../domain/entities/diff_hunk.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/value_objects/commit_hash.dart';
import '../../domain/failures/git_failures.dart';

/// Use case for getting diff
@injectable
class GetDiffUseCase {
  final IDiffRepository _diffRepository;

  GetDiffUseCase(this._diffRepository);

  /// Get diff for text content (pure algorithm, no git)
  ///
  /// This uses Rust WASM Myers diff algorithm for performance.
  ///
  /// Parameters:
  /// - oldContent: Original content
  /// - newContent: Modified content
  /// - contextLines: Number of context lines (default: 3)
  ///
  /// Returns: List of DiffHunk or GitFailure
  Future<Either<GitFailure, List<DiffHunk>>> getDiff({
    required String oldContent,
    required String newContent,
    int contextLines = 3,
  }) async {
    return _diffRepository.getDiff(
      oldContent: oldContent,
      newContent: newContent,
      contextLines: contextLines,
    );
  }

  /// Get diff between two commits
  Future<Either<GitFailure, Map<String, List<DiffHunk>>>>
      getDiffBetweenCommits({
    required RepositoryPath path,
    required String oldCommit,
    required String newCommit,
  }) async {
    // Validate commit hashes
    final CommitHash oldHash;
    final CommitHash newHash;

    try {
      oldHash = CommitHash.create(oldCommit);
      newHash = CommitHash.create(newCommit);
    } catch (e) {
      return left(
        GitFailure.unknown(
          message: 'Invalid commit hash: ${e.toString()}',
          error: e,
        ),
      );
    }

    return _diffRepository.getDiffBetweenCommits(
      path: path,
      oldCommit: oldHash,
      newCommit: newHash,
    );
  }

  /// Get diff for staged changes
  Future<Either<GitFailure, Map<String, List<DiffHunk>>>> getStagedDiff({
    required RepositoryPath path,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    return _diffRepository.getStagedDiff(path: path);
  }

  /// Get diff for unstaged changes
  Future<Either<GitFailure, Map<String, List<DiffHunk>>>> getUnstagedDiff({
    required RepositoryPath path,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    return _diffRepository.getUnstagedDiff(path: path);
  }

  /// Get diff for specific file
  Future<Either<GitFailure, List<DiffHunk>>> getFileDiff({
    required RepositoryPath path,
    required String filePath,
    bool staged = false,
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

    return _diffRepository.getFileDiff(
      path: path,
      filePath: filePath,
      staged: staged,
    );
  }
}
