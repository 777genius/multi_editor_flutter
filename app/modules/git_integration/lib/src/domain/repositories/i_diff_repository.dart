import 'package:dartz/dartz.dart';
import '../entities/diff_hunk.dart';
import '../value_objects/repository_path.dart';
import '../value_objects/commit_hash.dart';
import '../failures/git_failures.dart';

/// Diff algorithm types
enum DiffAlgorithm {
  myers,     // Default git diff algorithm
  patience,  // Better for code with moved blocks
  minimal,   // Minimal diff
  histogram, // Variation of patience
}

/// Diff calculations repository interface (uses Rust WASM for performance)
abstract class IDiffRepository {
  /// Get diff for text content (pure algorithm, no git)
  Future<Either<GitFailure, List<DiffHunk>>> getDiff({
    required String oldContent,
    required String newContent,
    DiffAlgorithm algorithm = DiffAlgorithm.myers,
    int contextLines = 3,
  });

  /// Get diff between commits
  Future<Either<GitFailure, Map<String, List<DiffHunk>>>>
      getDiffBetweenCommits({
    required RepositoryPath path,
    required CommitHash oldCommit,
    required CommitHash newCommit,
    DiffAlgorithm algorithm = DiffAlgorithm.myers,
  });

  /// Get diff for staged changes
  Future<Either<GitFailure, Map<String, List<DiffHunk>>>> getStagedDiff({
    required RepositoryPath path,
    DiffAlgorithm algorithm = DiffAlgorithm.myers,
  });

  /// Get diff for unstaged changes
  Future<Either<GitFailure, Map<String, List<DiffHunk>>>> getUnstagedDiff({
    required RepositoryPath path,
    DiffAlgorithm algorithm = DiffAlgorithm.myers,
  });

  /// Get diff for specific file
  Future<Either<GitFailure, List<DiffHunk>>> getFileDiff({
    required RepositoryPath path,
    required String filePath,
    bool staged = false,
    DiffAlgorithm algorithm = DiffAlgorithm.myers,
  });
}
