import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/blame_line.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/failures/git_failures.dart';
import '../use_cases/get_blame_use_case.dart';

/// Service for git blame operations
///
/// This service provides high-level blame operations and coordinates
/// with the blame use case. It handles:
/// - Blame caching for performance
/// - Blame annotations and tooltips
/// - Author statistics and heat maps
/// - Integration with commit history
@injectable
class BlameService {
  final GetBlameUseCase _getBlameUseCase;

  // Cache of blame data (filePath -> blame lines)
  final Map<String, List<BlameLine>> _blameCache = {};

  BlameService(this._getBlameUseCase);

  // ============================================================================
  // Blame Operations
  // ============================================================================

  /// Get blame for file
  Future<Either<GitFailure, List<BlameLine>>> getBlame({
    required RepositoryPath path,
    required String filePath,
    String? commit,
    int? startLine,
    int? endLine,
    bool useCache = true,
  }) async {
    // Generate cache key
    final cacheKey = _generateCacheKey(filePath, commit, startLine, endLine);

    // Check cache
    if (useCache && _blameCache.containsKey(cacheKey)) {
      return right(_blameCache[cacheKey]!);
    }

    // Get blame
    final result = await _getBlameUseCase(
      path: path,
      filePath: filePath,
      commit: commit,
      startLine: startLine,
      endLine: endLine,
    );

    // Cache result
    if (useCache) {
      result.fold(
        (_) => null,
        (blameLines) => _blameCache[cacheKey] = blameLines,
      );
    }

    return result;
  }

  /// Get blame for current file
  Future<Either<GitFailure, List<BlameLine>>> getFileBlame({
    required RepositoryPath path,
    required String filePath,
    bool useCache = true,
  }) async {
    return getBlame(
      path: path,
      filePath: filePath,
      useCache: useCache,
    );
  }

  /// Get blame for line range
  Future<Either<GitFailure, List<BlameLine>>> getLineRangeBlame({
    required RepositoryPath path,
    required String filePath,
    required int startLine,
    required int endLine,
    bool useCache = true,
  }) async {
    return getBlame(
      path: path,
      filePath: filePath,
      startLine: startLine,
      endLine: endLine,
      useCache: useCache,
    );
  }

  /// Get historical blame
  Future<Either<GitFailure, List<BlameLine>>> getHistoricalBlame({
    required RepositoryPath path,
    required String filePath,
    required String commit,
    bool useCache = true,
  }) async {
    return getBlame(
      path: path,
      filePath: filePath,
      commit: commit,
      useCache: useCache,
    );
  }

  // ============================================================================
  // Blame Statistics
  // ============================================================================

  /// Get blame summary
  ///
  /// Returns statistics about who contributed to the file.
  Future<Either<GitFailure, Map<String, int>>> getBlameSummary({
    required RepositoryPath path,
    required String filePath,
  }) async {
    return _getBlameUseCase.getBlameSummary(
      path: path,
      filePath: filePath,
    );
  }

  /// Get blame heat map
  ///
  /// Returns age of each line for visualization.
  Future<Either<GitFailure, List<int>>> getBlameHeatMap({
    required RepositoryPath path,
    required String filePath,
  }) async {
    return _getBlameUseCase.getBlameHeatMap(
      path: path,
      filePath: filePath,
    );
  }

  /// Calculate author contribution percentage
  Future<Either<GitFailure, Map<String, double>>> getAuthorContribution({
    required RepositoryPath path,
    required String filePath,
  }) async {
    final summaryResult = await getBlameSummary(
      path: path,
      filePath: filePath,
    );

    return summaryResult.map((summary) {
      final total = summary.values.fold(0, (sum, count) => sum + count);
      if (total == 0) return <String, double>{};

      final contribution = <String, double>{};
      for (final entry in summary.entries) {
        contribution[entry.key] = (entry.value / total) * 100;
      }
      return contribution;
    });
  }

  // ============================================================================
  // Blame Annotations
  // ============================================================================

  /// Get blame annotation for specific line
  ///
  /// Returns formatted annotation string for displaying in gutter or tooltip.
  Future<Either<GitFailure, String>> getLineAnnotation({
    required RepositoryPath path,
    required String filePath,
    required int lineNumber,
  }) async {
    final blameResult = await getLineRangeBlame(
      path: path,
      filePath: filePath,
      startLine: lineNumber,
      endLine: lineNumber,
    );

    return blameResult.map((blameLines) {
      if (blameLines.isEmpty) return 'No blame information';

      final line = blameLines.first;
      final commit = line.commit;
      final author = commit.author;
      final age = commit.ageDisplay;

      return '${author.name} • ${age} • ${commit.shortHash}';
    });
  }

  /// Get blame tooltip content
  ///
  /// Returns rich tooltip content with commit details.
  Future<Either<GitFailure, BlameTooltip>> getLineTooltip({
    required RepositoryPath path,
    required String filePath,
    required int lineNumber,
  }) async {
    final blameResult = await getLineRangeBlame(
      path: path,
      filePath: filePath,
      startLine: lineNumber,
      endLine: lineNumber,
    );

    return blameResult.map((blameLines) {
      if (blameLines.isEmpty) {
        return BlameTooltip(
          author: 'Unknown',
          date: DateTime.now(),
          commitHash: '',
          commitMessage: 'No blame information',
          lineContent: '',
        );
      }

      final line = blameLines.first;
      final commit = line.commit;

      return BlameTooltip(
        author: commit.author.name,
        date: commit.authorDate,
        commitHash: commit.hash.short,
        commitMessage: commit.message.subject,
        lineContent: line.content,
      );
    });
  }

  // ============================================================================
  // Blame Formatting
  // ============================================================================

  /// Format blame as text
  ///
  /// Returns formatted blame output similar to `git blame` command.
  String formatBlameText(List<BlameLine> blameLines) {
    final buffer = StringBuffer();

    for (final line in blameLines) {
      final commit = line.commit;
      final hash = commit.hash.short;
      final author = commit.author.name.padRight(20);
      final date = commit.authorDate.toIso8601String().substring(0, 10);
      final lineNum = line.lineNumber.toString().padLeft(4);
      final content = line.content;

      buffer.writeln('$hash $author $date $lineNum) $content');
    }

    return buffer.toString();
  }

  /// Group blame lines by commit
  ///
  /// Returns blame lines grouped by commit for compact display.
  Map<String, List<BlameLine>> groupByCommit(List<BlameLine> blameLines) {
    final groups = <String, List<BlameLine>>{};

    for (final line in blameLines) {
      final hash = line.commit.hash.value;
      if (!groups.containsKey(hash)) {
        groups[hash] = [];
      }
      groups[hash]!.add(line);
    }

    return groups;
  }

  /// Group blame lines by author
  ///
  /// Returns blame lines grouped by author.
  Map<String, List<BlameLine>> groupByAuthor(List<BlameLine> blameLines) {
    final groups = <String, List<BlameLine>>{};

    for (final line in blameLines) {
      final author = line.commit.author.name;
      if (!groups.containsKey(author)) {
        groups[author] = [];
      }
      groups[author]!.add(line);
    }

    return groups;
  }

  // ============================================================================
  // Cache Management
  // ============================================================================

  /// Generate cache key for blame
  String _generateCacheKey(
    String filePath,
    String? commit,
    int? startLine,
    int? endLine,
  ) {
    return '${filePath}_${commit ?? "HEAD"}_${startLine ?? "all"}_${endLine ?? "all"}';
  }

  /// Clear blame cache
  void clearCache() {
    _blameCache.clear();
  }

  /// Clear cache for specific file
  void clearFileCache(String filePath) {
    _blameCache.removeWhere((key, _) => key.startsWith(filePath));
  }

  /// Invalidate cache when file changes
  void invalidateFileCache(String filePath) {
    clearFileCache(filePath);
  }
}

/// Blame tooltip content
class BlameTooltip {
  final String author;
  final DateTime date;
  final String commitHash;
  final String commitMessage;
  final String lineContent;

  BlameTooltip({
    required this.author,
    required this.date,
    required this.commitHash,
    required this.commitMessage,
    required this.lineContent,
  });

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? "year" : "years"} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? "month" : "months"} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? "day" : "days"} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? "hour" : "hours"} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? "minute" : "minutes"} ago';
    } else {
      return 'just now';
    }
  }
}
