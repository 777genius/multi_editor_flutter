import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';
import '../value_objects/file_status.dart';

part 'file_change.freezed.dart';

/// Represents a changed file entity
@freezed
class FileChange with _$FileChange {
  const FileChange._();

  const factory FileChange({
    required String filePath,
    required FileStatus status,
    Option<String>? oldPath, // For renamed files
    @Default(0) int insertions,
    @Default(0) int deletions,
    @Default(false) bool isStaged,
  }) = _FileChange;

  /// Domain logic: Is renamed?
  bool get isRenamed {
    return status is _Renamed && (oldPath ?? none()).isSome();
  }

  /// Domain logic: Is new file?
  bool get isNew => status is _Added || status is _Untracked;

  /// Domain logic: Is deleted?
  bool get isDeleted => status is _Deleted;

  /// Domain logic: Is modified?
  bool get isModified => status is _Modified;

  /// Domain logic: Has conflict?
  bool get hasConflict => status is _Conflicted;

  /// Domain logic: Is tracked?
  bool get isTracked => status.isTracked;

  /// Domain logic: Can be staged?
  bool get canBeStaged => status.canBeStaged && !isStaged;

  /// Domain logic: Can be unstaged?
  bool get canBeUnstaged => status.canBeUnstaged && isStaged;

  /// Domain logic: Total changes count
  int get totalChanges => insertions + deletions;

  /// Domain logic: Has line changes?
  bool get hasLineChanges => totalChanges > 0;

  /// Domain logic: Change ratio (-1 to 1, negative = more deletions)
  double get changeRatio {
    final total = totalChanges;
    if (total == 0) return 0.0;
    return (insertions - deletions) / total;
  }

  /// Domain logic: Is mostly additions?
  bool get isMostlyAdditions => changeRatio > 0.5;

  /// Domain logic: Is mostly deletions?
  bool get isMostlyDeletions => changeRatio < -0.5;

  /// Domain logic: Get file name (without path)
  String get fileName {
    final parts = filePath.split('/');
    return parts.last;
  }

  /// Domain logic: Get directory path
  String get directory {
    final parts = filePath.split('/');
    if (parts.length <= 1) return '';
    return parts.sublist(0, parts.length - 1).join('/');
  }

  /// Domain logic: Get file extension
  String get extension {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot == -1) return '';
    return fileName.substring(lastDot + 1);
  }

  /// Domain logic: Get display path (for renamed files)
  String get displayPath {
    if (isRenamed && (oldPath ?? none()).isSome()) {
      return (oldPath ?? none()).fold(
        () => filePath,
        (old) => '$old → $filePath',
      );
    }
    return filePath;
  }

  /// Domain logic: Get status icon
  String get statusIcon {
    return status.shortDisplay;
  }

  /// Domain logic: Get status display name
  String get statusDisplay {
    return status.displayName;
  }

  /// Domain logic: Summary for display
  String get summary {
    final sb = StringBuffer();
    sb.write(statusIcon);
    sb.write(' ');
    sb.write(displayPath);

    if (hasLineChanges) {
      sb.write(' (+$insertions, -$deletions)');
    }

    return sb.toString();
  }
}
