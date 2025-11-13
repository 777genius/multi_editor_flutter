import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_diff_repository.dart';
import '../../domain/entities/diff_hunk.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/value_objects/commit_hash.dart';
import '../../domain/failures/git_failures.dart';
import '../adapters/git_command_adapter.dart';

/// Diff repository implementation
///
/// This implements IDiffRepository using:
/// - Rust WASM Myers diff algorithm for text diff (high performance)
/// - Git CLI for repository diff operations
@LazySingleton(as: IDiffRepository)
class DiffRepositoryImpl implements IDiffRepository {
  final GitCommandAdapter _commandAdapter;

  DiffRepositoryImpl(this._commandAdapter);

  // ============================================================================
  // Text Diff (Rust WASM)
  // ============================================================================

  @override
  Future<Either<GitFailure, List<DiffHunk>>> getDiff({
    required String oldContent,
    required String newContent,
    int contextLines = 3,
  }) async {
    // TODO: Call Rust WASM Myers diff algorithm
    // For now, return empty list (will be implemented with Rust WASM module)

    // This will be implemented as:
    // 1. Load Rust WASM module
    // 2. Call myers_diff(oldContent, newContent, contextLines)
    // 3. Parse WASM result into List<DiffHunk>

    return right(_fallbackDiff(oldContent, newContent, contextLines));
  }

  /// Fallback pure Dart diff implementation
  ///
  /// This is a simple line-by-line diff for cases where WASM is not available.
  /// Not as sophisticated as Myers algorithm but works as fallback.
  List<DiffHunk> _fallbackDiff(
    String oldContent,
    String newContent,
    int contextLines,
  ) {
    final oldLines = oldContent.split('\n');
    final newLines = newContent.split('\n');

    // Simple line-by-line comparison
    final diffLines = <DiffLine>[];
    var oldIndex = 0;
    var newIndex = 0;

    while (oldIndex < oldLines.length || newIndex < newLines.length) {
      if (oldIndex >= oldLines.length) {
        // Added line
        diffLines.add(DiffLine(
          type: DiffLineType.added,
          content: newLines[newIndex],
          oldLineNumber: fp.none(),
          newLineNumber: fp.some(newIndex + 1),
        ));
        newIndex++;
      } else if (newIndex >= newLines.length) {
        // Removed line
        diffLines.add(DiffLine(
          type: DiffLineType.removed,
          content: oldLines[oldIndex],
          oldLineNumber: fp.some(oldIndex + 1),
          newLineNumber: fp.none(),
        ));
        oldIndex++;
      } else if (oldLines[oldIndex] == newLines[newIndex]) {
        // Context line (unchanged)
        diffLines.add(DiffLine(
          type: DiffLineType.context,
          content: oldLines[oldIndex],
          oldLineNumber: fp.some(oldIndex + 1),
          newLineNumber: fp.some(newIndex + 1),
        ));
        oldIndex++;
        newIndex++;
      } else {
        // Changed line (remove old, add new)
        diffLines.add(DiffLine(
          type: DiffLineType.removed,
          content: oldLines[oldIndex],
          oldLineNumber: fp.some(oldIndex + 1),
          newLineNumber: fp.none(),
        ));
        diffLines.add(DiffLine(
          type: DiffLineType.added,
          content: newLines[newIndex],
          oldLineNumber: fp.none(),
          newLineNumber: fp.some(newIndex + 1),
        ));
        oldIndex++;
        newIndex++;
      }
    }

    // Group lines into hunks
    final hunks = <DiffHunk>[];
    if (diffLines.isNotEmpty) {
      hunks.add(DiffHunk(
        oldStart: 1,
        oldCount: oldLines.length,
        newStart: 1,
        newCount: newLines.length,
        lines: diffLines,
        header: '@@ -1,${oldLines.length} +1,${newLines.length} @@',
      ));
    }

    return hunks;
  }

  // ============================================================================
  // Repository Diff (Git CLI)
  // ============================================================================

  @override
  Future<Either<GitFailure, Map<String, List<DiffHunk>>>>
      getDiffBetweenCommits({
    required RepositoryPath path,
    required CommitHash oldCommit,
    required CommitHash newCommit,
  }) async {
    // Get list of changed files
    final filesResult = await _commandAdapter.executeAndGetOutput(
      args: [
        'diff',
        '--name-only',
        oldCommit.value,
        newCommit.value,
      ],
      workingDirectory: path.path,
    );

    return filesResult.flatMap((filesOutput) async {
      final files = filesOutput.split('\n').where((f) => f.isNotEmpty).toList();
      final fileDiffs = <String, List<DiffHunk>>{};

      // Get diff for each file
      for (final file in files) {
        final diffResult = await _getFileDiffBetweenCommits(
          path: path,
          filePath: file,
          oldCommit: oldCommit,
          newCommit: newCommit,
        );

        diffResult.fold(
          (_) => null, // Skip files with errors
          (hunks) => fileDiffs[file] = hunks,
        );
      }

      return right(fileDiffs);
    });
  }

  @override
  Future<Either<GitFailure, Map<String, List<DiffHunk>>>> getStagedDiff({
    required RepositoryPath path,
  }) async {
    // Get list of staged files
    final filesResult = await _commandAdapter.executeAndGetOutput(
      args: ['diff', '--staged', '--name-only'],
      workingDirectory: path.path,
    );

    return filesResult.flatMap((filesOutput) async {
      final files = filesOutput.split('\n').where((f) => f.isNotEmpty).toList();
      final fileDiffs = <String, List<DiffHunk>>{};

      // Get diff for each file
      for (final file in files) {
        final diffResult = await getFileDiff(
          path: path,
          filePath: file,
          staged: true,
        );

        diffResult.fold(
          (_) => null, // Skip files with errors
          (hunks) => fileDiffs[file] = hunks,
        );
      }

      return right(fileDiffs);
    });
  }

  @override
  Future<Either<GitFailure, Map<String, List<DiffHunk>>>> getUnstagedDiff({
    required RepositoryPath path,
  }) async {
    // Get list of unstaged files
    final filesResult = await _commandAdapter.executeAndGetOutput(
      args: ['diff', '--name-only'],
      workingDirectory: path.path,
    );

    return filesResult.flatMap((filesOutput) async {
      final files = filesOutput.split('\n').where((f) => f.isNotEmpty).toList();
      final fileDiffs = <String, List<DiffHunk>>{};

      // Get diff for each file
      for (final file in files) {
        final diffResult = await getFileDiff(
          path: path,
          filePath: file,
          staged: false,
        );

        diffResult.fold(
          (_) => null, // Skip files with errors
          (hunks) => fileDiffs[file] = hunks,
        );
      }

      return right(fileDiffs);
    });
  }

  @override
  Future<Either<GitFailure, List<DiffHunk>>> getFileDiff({
    required RepositoryPath path,
    required String filePath,
    bool staged = false,
  }) async {
    // Get diff for file
    final diffResult = await _commandAdapter.executeAndGetOutput(
      args: [
        'diff',
        if (staged) '--staged',
        '--',
        filePath,
      ],
      workingDirectory: path.path,
    );

    return diffResult.map((output) => _parseDiffOutput(output));
  }

  /// Get diff for file between commits
  Future<Either<GitFailure, List<DiffHunk>>> _getFileDiffBetweenCommits({
    required RepositoryPath path,
    required String filePath,
    required CommitHash oldCommit,
    required CommitHash newCommit,
  }) async {
    final diffResult = await _commandAdapter.executeAndGetOutput(
      args: [
        'diff',
        oldCommit.value,
        newCommit.value,
        '--',
        filePath,
      ],
      workingDirectory: path.path,
    );

    return diffResult.map((output) => _parseDiffOutput(output));
  }

  // ============================================================================
  // Diff Parsing
  // ============================================================================

  /// Parse git diff output into DiffHunks
  ///
  /// Format:
  /// ```
  /// diff --git a/file.txt b/file.txt
  /// index abc123..def456 100644
  /// --- a/file.txt
  /// +++ b/file.txt
  /// @@ -1,3 +1,4 @@
  ///  context line
  /// -removed line
  /// +added line
  ///  context line
  /// ```
  List<DiffHunk> _parseDiffOutput(String output) {
    if (output.isEmpty) return [];

    final lines = output.split('\n');
    final hunks = <DiffHunk>[];
    DiffHunk? currentHunk;
    final currentLines = <DiffLine>[];

    for (final line in lines) {
      // Hunk header: @@ -1,3 +1,4 @@
      if (line.startsWith('@@')) {
        // Save previous hunk if exists
        if (currentHunk != null) {
          hunks.add(currentHunk.copyWith(lines: List.from(currentLines)));
          currentLines.clear();
        }

        // Parse hunk header
        final match = RegExp(r'@@ -(\d+),(\d+) \+(\d+),(\d+) @@').firstMatch(line);
        if (match != null) {
          currentHunk = DiffHunk(
            oldStart: int.parse(match.group(1)!),
            oldCount: int.parse(match.group(2)!),
            newStart: int.parse(match.group(3)!),
            newCount: int.parse(match.group(4)!),
            lines: [],
            header: line,
          );
        }
      }
      // Skip file headers
      else if (line.startsWith('diff ') ||
          line.startsWith('index ') ||
          line.startsWith('--- ') ||
          line.startsWith('+++ ')) {
        continue;
      }
      // Added line
      else if (line.startsWith('+')) {
        currentLines.add(DiffLine(
          type: DiffLineType.added,
          content: line.substring(1),
          oldLineNumber: fp.none(),
          newLineNumber: fp.some(currentLines.length + 1),
        ));
      }
      // Removed line
      else if (line.startsWith('-')) {
        currentLines.add(DiffLine(
          type: DiffLineType.removed,
          content: line.substring(1),
          oldLineNumber: fp.some(currentLines.length + 1),
          newLineNumber: fp.none(),
        ));
      }
      // Context line
      else if (line.startsWith(' ') || line.isEmpty) {
        currentLines.add(DiffLine(
          type: DiffLineType.context,
          content: line.isEmpty ? '' : line.substring(1),
          oldLineNumber: fp.some(currentLines.length + 1),
          newLineNumber: fp.some(currentLines.length + 1),
        ));
      }
    }

    // Save last hunk
    if (currentHunk != null) {
      hunks.add(currentHunk.copyWith(lines: List.from(currentLines)));
    }

    return hunks;
  }
}
