import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

part 'merge_conflict.freezed.dart';

/// Conflict marker value object
@freezed
class ConflictMarker with _$ConflictMarker {
  const factory ConflictMarker({
    required int startLine,
    required int middleLine,
    required int endLine,
  }) = _ConflictMarker;

  const ConflictMarker._();

  /// Domain logic: Get conflict line count
  int get lineCount => endLine - startLine + 1;

  /// Domain logic: Get "ours" line count
  int get oursLineCount => middleLine - startLine - 1;

  /// Domain logic: Get "theirs" line count
  int get theirsLineCount => endLine - middleLine - 1;
}

/// File with conflict
@freezed
class ConflictedFile with _$ConflictedFile {
  const ConflictedFile._();

  const factory ConflictedFile({
    required String filePath,
    required String theirContent,
    required String ourContent,
    required String baseContent, // Common ancestor
    required List<ConflictMarker> markers,
    required bool isResolved,
    Option<String>? resolvedContent,
  }) = _ConflictedFile;

  /// Domain logic: Has conflict markers?
  bool get hasConflictMarkers => markers.isNotEmpty;

  /// Domain logic: Conflict count
  int get conflictCount => markers.length;

  /// Domain logic: Can be auto-merged? (no overlapping changes)
  bool get canAutoMerge => markers.isEmpty;

  /// Domain logic: Get file name
  String get fileName {
    final parts = filePath.split('/');
    return parts.last;
  }

  /// Domain logic: Get content for resolution
  String get contentToResolve {
    return (resolvedContent ?? none()).fold(
      () => ourContent, // Default to our content if not resolved
      (resolved) => resolved,
    );
  }
}

/// Represents a merge conflict entity
@freezed
class MergeConflict with _$MergeConflict {
  const MergeConflict._();

  const factory MergeConflict({
    required String sourceBranch,
    required String targetBranch,
    required List<ConflictedFile> conflictedFiles,
    required DateTime detectedAt,
  }) = _MergeConflict;

  /// Domain logic: All conflicts resolved?
  bool get isResolved {
    return conflictedFiles.every((file) => file.isResolved);
  }

  /// Domain logic: Count unresolved conflicts
  int get unresolvedCount {
    return conflictedFiles.where((file) => !file.isResolved).length;
  }

  /// Domain logic: Count resolved conflicts
  int get resolvedCount {
    return conflictedFiles.where((file) => file.isResolved).length;
  }

  /// Domain logic: Total files with conflicts
  int get totalFilesCount => conflictedFiles.length;

  /// Domain logic: Total conflict markers across all files
  int get totalConflictMarkersCount {
    return conflictedFiles.fold(
      0,
      (sum, file) => sum + file.conflictCount,
    );
  }

  /// Domain logic: Get resolution progress (0.0 to 1.0)
  double get resolutionProgress {
    if (conflictedFiles.isEmpty) return 1.0;
    return resolvedCount / conflictedFiles.length;
  }

  /// Domain logic: Has been detected recently? (within last hour)
  bool get isRecent {
    final age = DateTime.now().difference(detectedAt);
    return age.inMinutes < 60;
  }

  /// Domain logic: Summary for display
  String get summary {
    final sb = StringBuffer();
    sb.write('Merge ');
    sb.write(sourceBranch);
    sb.write(' → ');
    sb.write(targetBranch);
    sb.write(': ');
    sb.write('$totalFilesCount ${totalFilesCount == 1 ? "file" : "files"}');
    sb.write(', ');
    sb.write('$totalConflictMarkersCount ${totalConflictMarkersCount == 1 ? "conflict" : "conflicts"}');

    if (isResolved) {
      sb.write(' (Resolved)');
    } else if (resolvedCount > 0) {
      sb.write(' ($resolvedCount/$totalFilesCount resolved)');
    }

    return sb.toString();
  }
}
