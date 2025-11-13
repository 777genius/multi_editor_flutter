import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';
import '../value_objects/branch_name.dart';
import '../value_objects/commit_hash.dart';

part 'git_branch.freezed.dart';

/// Branch type enum
enum BranchType {
  local,
  remote,
}

/// Represents a Git branch entity
@freezed
class GitBranch with _$GitBranch {
  const GitBranch._();

  const factory GitBranch({
    required BranchName name,
    required CommitHash headCommit,
    required BranchType type,
    Option<BranchName>? upstream, // Tracking branch
    required bool isCurrent,
    @Default(0) int aheadCount,   // Commits ahead of upstream
    @Default(0) int behindCount,  // Commits behind upstream
    @Default(0) int commitCount,  // Total commits in branch
    Option<DateTime>? lastCommitDate,
  }) = _GitBranch;

  /// Domain logic: Is local branch?
  bool get isLocal => type == BranchType.local;

  /// Domain logic: Is remote branch?
  bool get isRemote => type == BranchType.remote;

  /// Domain logic: Has upstream tracking?
  bool get hasUpstream => (upstream ?? none()).isSome();

  /// Domain logic: Is tracking?
  bool get isTracking => hasUpstream;

  /// Domain logic: Needs push? (has commits ahead)
  bool get needsPush => aheadCount > 0;

  /// Domain logic: Needs pull? (commits behind upstream)
  bool get needsPull => behindCount > 0;

  /// Domain logic: Is synced with upstream?
  bool get isSynced => aheadCount == 0 && behindCount == 0;

  /// Domain logic: Has diverged? (both ahead and behind)
  bool get hasDiverged => aheadCount > 0 && behindCount > 0;

  /// Domain logic: Get sync status display
  String get syncStatus {
    if (!hasUpstream) return 'No upstream';
    if (isSynced) return 'Up to date';
    if (hasDiverged) return 'Diverged ($aheadCount ahead, $behindCount behind)';
    if (needsPush) return '$aheadCount ahead';
    if (needsPull) return '$behindCount behind';
    return 'Unknown';
  }

  /// Domain logic: Get upstream display name
  String get upstreamDisplay {
    return (upstream ?? none()).fold(
      () => 'No upstream',
      (up) => up.value,
    );
  }

  /// Domain logic: Is main/master branch?
  bool get isMainBranch => name.isMainBranch;

  /// Domain logic: Can be deleted? (not current, not main)
  bool get canBeDeleted => !isCurrent && !isMainBranch;

  /// Domain logic: Display name (short for remote branches)
  String get displayName => name.isRemote ? name.shortName : name.value;

  /// Domain logic: Full qualified name
  String get fullName => name.value;
}
