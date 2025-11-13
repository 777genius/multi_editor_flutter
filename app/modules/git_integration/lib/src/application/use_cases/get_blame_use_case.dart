import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_git_repository.dart';
import '../../domain/entities/blame_line.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/value_objects/commit_hash.dart';
import '../../domain/failures/git_failures.dart';

/// Use case for getting git blame information
@injectable
class GetBlameUseCase {
  final IGitRepository _repository;

  GetBlameUseCase(this._repository);

  /// Get blame information for a file (git blame)
  ///
  /// This will:
  /// 1. Read file from working directory or specific commit
  /// 2. For each line, find the commit that last modified it
  /// 3. Include author, date, and commit message
  /// 4. Support line range for large files
  ///
  /// Parameters:
  /// - path: Repository path
  /// - filePath: File path relative to repository root
  /// - commit: Optional commit to blame (default: HEAD)
  /// - startLine: Optional start line (1-indexed)
  /// - endLine: Optional end line (1-indexed)
  ///
  /// Returns: List of BlameLine or GitFailure
  Future<Either<GitFailure, List<BlameLine>>> call({
    required RepositoryPath path,
    required String filePath,
    String? commit,
    int? startLine,
    int? endLine,
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

    // Validate commit hash if provided
    CommitHash? commitHash;
    if (commit != null && commit.isNotEmpty) {
      try {
        commitHash = CommitHash.create(commit);
      } catch (e) {
        return left(
          GitFailure.unknown(
            message: 'Invalid commit hash: ${e.toString()}',
            error: e,
          ),
        );
      }
    }

    // Validate line range if provided
    if (startLine != null && startLine < 1) {
      return left(
        GitFailure.unknown(
          message: 'Start line must be >= 1',
        ),
      );
    }

    if (endLine != null && endLine < 1) {
      return left(
        GitFailure.unknown(
          message: 'End line must be >= 1',
        ),
      );
    }

    if (startLine != null && endLine != null && startLine > endLine) {
      return left(
        GitFailure.unknown(
          message: 'Start line must be <= end line',
        ),
      );
    }

    // Delegate to repository
    return _repository.getBlame(
      path: path,
      filePath: filePath,
      commit: commitHash,
      startLine: startLine,
      endLine: endLine,
    );
  }

  /// Get blame for current file (convenience method)
  ///
  /// This is the most common use case - blame for the current
  /// working directory version of a file.
  Future<Either<GitFailure, List<BlameLine>>> getFileBlame({
    required RepositoryPath path,
    required String filePath,
  }) async {
    return call(
      path: path,
      filePath: filePath,
      commit: null,
      startLine: null,
      endLine: null,
    );
  }

  /// Get blame for specific line range
  ///
  /// This is useful for large files where you only need blame
  /// information for visible lines.
  Future<Either<GitFailure, List<BlameLine>>> getLineRangeBlame({
    required RepositoryPath path,
    required String filePath,
    required int startLine,
    required int endLine,
  }) async {
    return call(
      path: path,
      filePath: filePath,
      commit: null,
      startLine: startLine,
      endLine: endLine,
    );
  }

  /// Get blame at specific commit
  ///
  /// This shows who last modified each line as of a specific
  /// commit in history.
  Future<Either<GitFailure, List<BlameLine>>> getHistoricalBlame({
    required RepositoryPath path,
    required String filePath,
    required String commit,
  }) async {
    return call(
      path: path,
      filePath: filePath,
      commit: commit,
      startLine: null,
      endLine: null,
    );
  }

  /// Get blame summary for file
  ///
  /// Returns aggregated information about who contributed to the file.
  Future<Either<GitFailure, Map<String, int>>> getBlameSummary({
    required RepositoryPath path,
    required String filePath,
  }) async {
    // Get full blame
    final blameResult = await getFileBlame(
      path: path,
      filePath: filePath,
    );

    return blameResult.map((blameLines) {
      // Count lines per author
      final summary = <String, int>{};
      for (final line in blameLines) {
        final author = line.commit.author.name;
        summary[author] = (summary[author] ?? 0) + 1;
      }
      return summary;
    });
  }

  /// Get heat map data for file
  ///
  /// Returns age of each line (in days since commit) for visualization.
  /// Useful for showing which parts of file are stale.
  Future<Either<GitFailure, List<int>>> getBlameHeatMap({
    required RepositoryPath path,
    required String filePath,
  }) async {
    // Get full blame
    final blameResult = await getFileBlame(
      path: path,
      filePath: filePath,
    );

    return blameResult.map((blameLines) {
      final now = DateTime.now();
      return blameLines.map((line) {
        final age = now.difference(line.commit.authorDate).inDays;
        return age;
      }).toList();
    });
  }
}
