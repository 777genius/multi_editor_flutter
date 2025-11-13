import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/diff_hunk.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/failures/git_failures.dart';
import '../use_cases/get_diff_use_case.dart';

/// Service for diff operations
///
/// This service provides high-level diff operations and coordinates
/// with the diff use case. It handles:
/// - Diff caching for performance
/// - Diff formatting and rendering
/// - Side-by-side vs unified diff views
/// - Syntax highlighting integration
@injectable
class DiffService {
  final GetDiffUseCase _getDiffUseCase;

  // Cache of diffs (key -> diff hunks)
  final Map<String, List<DiffHunk>> _diffCache = {};

  DiffService(this._getDiffUseCase);

  // ============================================================================
  // Text Diff Operations (Rust WASM)
  // ============================================================================

  /// Get diff between two text strings
  ///
  /// This uses Rust WASM Myers algorithm for high performance.
  Future<Either<GitFailure, List<DiffHunk>>> getDiff({
    required String oldContent,
    required String newContent,
    int contextLines = 3,
    bool useCache = true,
  }) async {
    // Generate cache key
    final cacheKey = _generateCacheKey(oldContent, newContent, contextLines);

    // Check cache
    if (useCache && _diffCache.containsKey(cacheKey)) {
      return right(_diffCache[cacheKey]!);
    }

    // Get diff
    final result = await _getDiffUseCase.getDiff(
      oldContent: oldContent,
      newContent: newContent,
      contextLines: contextLines,
    );

    // Cache result
    if (useCache) {
      result.fold(
        (_) => null,
        (hunks) => _diffCache[cacheKey] = hunks,
      );
    }

    return result;
  }

  // ============================================================================
  // Git Diff Operations
  // ============================================================================

  /// Get diff between two commits
  Future<Either<GitFailure, Map<String, List<DiffHunk>>>>
      getDiffBetweenCommits({
    required RepositoryPath path,
    required String oldCommit,
    required String newCommit,
  }) async {
    return _getDiffUseCase.getDiffBetweenCommits(
      path: path,
      oldCommit: oldCommit,
      newCommit: newCommit,
    );
  }

  /// Get diff for staged changes
  Future<Either<GitFailure, Map<String, List<DiffHunk>>>> getStagedDiff({
    required RepositoryPath path,
  }) async {
    return _getDiffUseCase.getStagedDiff(path: path);
  }

  /// Get diff for unstaged changes
  Future<Either<GitFailure, Map<String, List<DiffHunk>>>> getUnstagedDiff({
    required RepositoryPath path,
  }) async {
    return _getDiffUseCase.getUnstagedDiff(path: path);
  }

  /// Get diff for specific file
  Future<Either<GitFailure, List<DiffHunk>>> getFileDiff({
    required RepositoryPath path,
    required String filePath,
    bool staged = false,
  }) async {
    return _getDiffUseCase.getFileDiff(
      path: path,
      filePath: filePath,
      staged: staged,
    );
  }

  // ============================================================================
  // Diff Statistics
  // ============================================================================

  /// Get diff statistics
  ///
  /// Returns summary of additions, deletions, and changes.
  DiffStatistics calculateStatistics(List<DiffHunk> hunks) {
    var additions = 0;
    var deletions = 0;
    var context = 0;

    for (final hunk in hunks) {
      for (final line in hunk.lines) {
        line.type.when(
          added: () => additions++,
          removed: () => deletions++,
          context: () => context++,
        );
      }
    }

    return DiffStatistics(
      additions: additions,
      deletions: deletions,
      context: context,
    );
  }

  /// Get diff statistics for file map
  Map<String, DiffStatistics> calculateFileStatistics(
    Map<String, List<DiffHunk>> fileDiffs,
  ) {
    final statistics = <String, DiffStatistics>{};

    for (final entry in fileDiffs.entries) {
      statistics[entry.key] = calculateStatistics(entry.value);
    }

    return statistics;
  }

  // ============================================================================
  // Diff Formatting
  // ============================================================================

  /// Format diff as unified diff string
  ///
  /// This generates the standard unified diff format:
  /// ```
  /// --- a/file.txt
  /// +++ b/file.txt
  /// @@ -1,3 +1,4 @@
  ///  context line
  /// -removed line
  /// +added line
  ///  context line
  /// ```
  String formatUnifiedDiff({
    required String filePath,
    required List<DiffHunk> hunks,
    String oldVersion = 'a',
    String newVersion = 'b',
  }) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('--- $oldVersion/$filePath');
    buffer.writeln('+++ $newVersion/$filePath');

    // Hunks
    for (final hunk in hunks) {
      buffer.writeln(hunk.header);

      for (final line in hunk.lines) {
        buffer.writeln('${line.prefix}${line.content}');
      }
    }

    return buffer.toString();
  }

  /// Format diff as side-by-side view data
  ///
  /// Returns data structure for side-by-side rendering.
  List<SideBySideLine> formatSideBySide({
    required List<DiffHunk> hunks,
  }) {
    final lines = <SideBySideLine>[];

    for (final hunk in hunks) {
      // Add hunk header
      lines.add(SideBySideLine(
        oldLineNumber: null,
        newLineNumber: null,
        oldContent: hunk.header,
        newContent: hunk.header,
        type: DiffLineType.context,
        isHunkHeader: true,
      ));

      // Add diff lines
      for (final line in hunk.lines) {
        lines.add(SideBySideLine(
          oldLineNumber: line.oldLineNumber.toNullable(),
          newLineNumber: line.newLineNumber.toNullable(),
          oldContent: line.isRemoved || line.type == DiffLineType.context
              ? line.content
              : '',
          newContent: line.isAdded || line.type == DiffLineType.context
              ? line.content
              : '',
          type: line.type,
          isHunkHeader: false,
        ));
      }
    }

    return lines;
  }

  /// Apply syntax highlighting to diff
  ///
  /// This integrates with syntax highlighting service to colorize
  /// code in diff hunks based on file extension.
  Future<List<DiffHunk>> applySyntaxHighlighting({
    required List<DiffHunk> hunks,
    required String fileExtension,
  }) async {
    // TODO: Integrate with syntax highlighting service
    // For now, just return original hunks
    return hunks;
  }

  // ============================================================================
  // Cache Management
  // ============================================================================

  /// Generate cache key for diff
  String _generateCacheKey(String oldContent, String newContent, int context) {
    // Use hash codes for performance
    return '${oldContent.hashCode}_${newContent.hashCode}_$context';
  }

  /// Clear diff cache
  void clearCache() {
    _diffCache.clear();
  }

  /// Clear cache for specific diff
  void clearCacheEntry(String oldContent, String newContent, int context) {
    final key = _generateCacheKey(oldContent, newContent, context);
    _diffCache.remove(key);
  }
}

/// Diff statistics
class DiffStatistics {
  final int additions;
  final int deletions;
  final int context;

  DiffStatistics({
    required this.additions,
    required this.deletions,
    required this.context,
  });

  int get total => additions + deletions + context;
  int get changes => additions + deletions;

  double get changeRatio {
    if (changes == 0) return 0.0;
    return (additions - deletions) / changes;
  }

  @override
  String toString() {
    return '+$additions -$deletions (~$context)';
  }
}

/// Line for side-by-side diff view
class SideBySideLine {
  final int? oldLineNumber;
  final int? newLineNumber;
  final String oldContent;
  final String newContent;
  final DiffLineType type;
  final bool isHunkHeader;

  SideBySideLine({
    required this.oldLineNumber,
    required this.newLineNumber,
    required this.oldContent,
    required this.newContent,
    required this.type,
    required this.isHunkHeader,
  });
}
