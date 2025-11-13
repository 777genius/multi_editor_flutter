import 'package:fpdart/fpdart.dart';
import '../value_objects/repository_path.dart';
import '../entities/merge_conflict.dart';

/// Domain service for detecting merge conflicts
class ConflictDetector {
  const ConflictDetector();

  /// Detect merge conflicts in repository
  Option<MergeConflict> detectConflicts({
    required RepositoryPath path,
    required String sourceBranch,
    required String targetBranch,
  }) {
    // Check for conflicted files
    // Note: In real implementation, this would:
    // 1. Check for files with conflict markers (<<<<<<, =======, >>>>>>>)
    // 2. Parse .git/MERGE_HEAD to get merge info
    // 3. Read conflicted file contents

    final conflictedFiles = _findConflictedFiles(path);

    if (conflictedFiles.isEmpty) {
      return none();
    }

    return some(
      MergeConflict(
        sourceBranch: sourceBranch,
        targetBranch: targetBranch,
        conflictedFiles: conflictedFiles,
        detectedAt: DateTime.now(),
      ),
    );
  }

  /// Find files with conflicts
  /// Note: Simplified implementation
  List<ConflictedFile> _findConflictedFiles(RepositoryPath path) {
    // In real implementation, would:
    // 1. Run: git diff --name-only --diff-filter=U
    // 2. For each file, read content and parse conflict markers
    // 3. Extract "ours", "theirs", and "base" content

    // Placeholder: return empty list
    // Infrastructure layer will implement actual detection
    return [];
  }

  /// Parse conflict markers in file content
  List<ConflictMarker> parseConflictMarkers(String content) {
    final markers = <ConflictMarker>[];
    final lines = content.split('\n');

    int? startLine;
    int? middleLine;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('<<<<<<<')) {
        // Start of conflict (ours)
        startLine = i;
      } else if (line.startsWith('=======')) {
        // Middle of conflict (separator)
        middleLine = i;
      } else if (line.startsWith('>>>>>>>')) {
        // End of conflict (theirs)
        if (startLine != null && middleLine != null) {
          markers.add(
            ConflictMarker(
              startLine: startLine,
              middleLine: middleLine,
              endLine: i,
            ),
          );
          startLine = null;
          middleLine = null;
        }
      }
    }

    return markers;
  }

  /// Extract "ours" content from conflict marker
  String extractOursContent(String content, ConflictMarker marker) {
    final lines = content.split('\n');
    final start = marker.startLine + 1; // Skip <<<<<< line
    final end = marker.middleLine;      // Before ====== line

    if (start >= end || end > lines.length) {
      return '';
    }

    return lines.sublist(start, end).join('\n');
  }

  /// Extract "theirs" content from conflict marker
  String extractTheirsContent(String content, ConflictMarker marker) {
    final lines = content.split('\n');
    final start = marker.middleLine + 1; // After ====== line
    final end = marker.endLine;          // Before >>>>>> line

    if (start >= end || end > lines.length) {
      return '';
    }

    return lines.sublist(start, end).join('\n');
  }

  /// Count total conflicts in content
  int countConflicts(String content) {
    return parseConflictMarkers(content).length;
  }

  /// Check if content has conflicts
  bool hasConflicts(String content) {
    return content.contains('<<<<<<<') &&
           content.contains('=======') &&
           content.contains('>>>>>>>');
  }
}
