import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

part 'diff_hunk.freezed.dart';

/// Diff line type enum
enum DiffLineType {
  added,
  removed,
  context,
}

/// Represents a single diff line
@freezed
class DiffLine with _$DiffLine {
  const DiffLine._();

  const factory DiffLine({
    required DiffLineType type,
    required String content,
    Option<int>? oldLineNumber,
    Option<int>? newLineNumber,
  }) = _DiffLine;

  /// Domain logic: Is added line?
  bool get isAdded => type == DiffLineType.added;

  /// Domain logic: Is removed line?
  bool get isRemoved => type == DiffLineType.removed;

  /// Domain logic: Is context line?
  bool get isContext => type == DiffLineType.context;

  /// Domain logic: Has old line number?
  bool get hasOldLineNumber => (oldLineNumber ?? none()).isSome();

  /// Domain logic: Has new line number?
  bool get hasNewLineNumber => (newLineNumber ?? none()).isSome();

  /// Domain logic: Get prefix for display (+ for added, - for removed, space for context)
  String get prefix {
    switch (type) {
      case DiffLineType.added:
        return '+';
      case DiffLineType.removed:
        return '-';
      case DiffLineType.context:
        return ' ';
    }
  }

  /// Domain logic: Format for display
  String formatForDisplay() {
    return '$prefix$content';
  }
}

/// Represents a diff hunk (continuous block of changes)
@freezed
class DiffHunk with _$DiffHunk {
  const DiffHunk._();

  const factory DiffHunk({
    required int oldStart,
    required int oldCount,
    required int newStart,
    required int newCount,
    required List<DiffLine> lines,
    required String header,
  }) = _DiffHunk;

  /// Domain logic: Get added lines count
  int get addedLinesCount {
    return lines.where((line) => line.isAdded).length;
  }

  /// Domain logic: Get removed lines count
  int get removedLinesCount {
    return lines.where((line) => line.isRemoved).length;
  }

  /// Domain logic: Get context lines count
  int get contextLinesCount {
    return lines.where((line) => line.isContext).length;
  }

  /// Domain logic: Total lines count
  int get totalLinesCount => lines.length;

  /// Domain logic: Has changes?
  bool get hasChanges => addedLinesCount > 0 || removedLinesCount > 0;

  /// Domain logic: Only additions?
  bool get onlyAdditions => addedLinesCount > 0 && removedLinesCount == 0;

  /// Domain logic: Only deletions?
  bool get onlyDeletions => removedLinesCount > 0 && addedLinesCount == 0;

  /// Domain logic: Mixed changes?
  bool get mixedChanges => addedLinesCount > 0 && removedLinesCount > 0;

  /// Domain logic: Get change ratio (-1 to 1)
  double get changeRatio {
    final total = addedLinesCount + removedLinesCount;
    if (total == 0) return 0.0;
    return (addedLinesCount - removedLinesCount) / total;
  }

  /// Domain logic: Get hunk size (old + new lines)
  int get hunkSize => oldCount + newCount;

  /// Domain logic: Get old range (start-end)
  String get oldRange => '$oldStart,${oldStart + oldCount - 1}';

  /// Domain logic: Get new range (start-end)
  String get newRange => '$newStart,${newStart + newCount - 1}';

  /// Domain logic: Format header for display
  String get formattedHeader {
    return '@@ -$oldStart,$oldCount +$newStart,$newCount @@ $header';
  }

  /// Domain logic: Summary
  String get summary {
    final sb = StringBuffer();
    sb.write('Hunk @$oldStart,$oldCount → @$newStart,$newCount: ');
    sb.write('+$addedLinesCount, -$removedLinesCount');
    return sb.toString();
  }
}
