import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_status.freezed.dart';

/// File status value object representing git file states
@freezed
class FileStatus with _$FileStatus {
  const factory FileStatus.unmodified() = _Unmodified;
  const factory FileStatus.added() = _Added;
  const factory FileStatus.modified() = _Modified;
  const factory FileStatus.deleted() = _Deleted;
  const factory FileStatus.renamed() = _Renamed;
  const factory FileStatus.copied() = _Copied;
  const factory FileStatus.untracked() = _Untracked;
  const factory FileStatus.ignored() = _Ignored;
  const factory FileStatus.conflicted() = _Conflicted;

  const FileStatus._();

  /// Parse from git status --porcelain=v2 format
  factory FileStatus.fromGitStatusCode(String code) {
    // Git status codes: XY (staged, unstaged)
    // A = added, M = modified, D = deleted, R = renamed, C = copied
    // ? = untracked, ! = ignored
    switch (code) {
      case 'A':
      case '.A':
        return const FileStatus.added();
      case 'M':
      case '.M':
        return const FileStatus.modified();
      case 'D':
      case '.D':
        return const FileStatus.deleted();
      case 'R':
      case '.R':
        return const FileStatus.renamed();
      case 'C':
      case '.C':
        return const FileStatus.copied();
      case '?':
      case '??':
        return const FileStatus.untracked();
      case '!':
      case '!!':
        return const FileStatus.ignored();
      case 'U':
      case 'UU':
      case 'AA':
      case 'DD':
        return const FileStatus.conflicted();
      default:
        return const FileStatus.unmodified();
    }
  }

  /// Domain logic: Is tracked?
  bool get isTracked => when(
        unmodified: () => true,
        added: () => true,
        modified: () => true,
        deleted: () => true,
        renamed: () => true,
        copied: () => true,
        untracked: () => false,
        ignored: () => false,
        conflicted: () => true,
      );

  /// Domain logic: Has changes?
  bool get hasChanges => when(
        unmodified: () => false,
        added: () => true,
        modified: () => true,
        deleted: () => true,
        renamed: () => true,
        copied: () => true,
        untracked: () => true,
        ignored: () => false,
        conflicted: () => true,
      );

  /// Domain logic: Can be staged?
  bool get canBeStaged => when(
        unmodified: () => false,
        added: () => false, // Already staged
        modified: () => true,
        deleted: () => true,
        renamed: () => true,
        copied: () => true,
        untracked: () => true,
        ignored: () => false,
        conflicted: () => false, // Must resolve first
      );

  /// Domain logic: Can be unstaged?
  bool get canBeUnstaged => when(
        unmodified: () => false,
        added: () => true,
        modified: () => false, // Unstaged by default
        deleted: () => false,
        renamed: () => true,
        copied: () => true,
        untracked: () => false,
        ignored: () => false,
        conflicted: () => false,
      );

  /// Domain logic: Needs conflict resolution?
  bool get needsResolution => when(
        unmodified: () => false,
        added: () => false,
        modified: () => false,
        deleted: () => false,
        renamed: () => false,
        copied: () => false,
        untracked: () => false,
        ignored: () => false,
        conflicted: () => true,
      );

  /// Domain logic: Display name
  String get displayName => when(
        unmodified: () => 'Unmodified',
        added: () => 'Added',
        modified: () => 'Modified',
        deleted: () => 'Deleted',
        renamed: () => 'Renamed',
        copied: () => 'Copied',
        untracked: () => 'Untracked',
        ignored: () => 'Ignored',
        conflicted: () => 'Conflicted',
      );

  /// Domain logic: Short display (for UI)
  String get shortDisplay => when(
        unmodified: () => 'U',
        added: () => 'A',
        modified: () => 'M',
        deleted: () => 'D',
        renamed: () => 'R',
        copied: () => 'C',
        untracked: () => '?',
        ignored: () => '!',
        conflicted: () => 'C',
      );
}
