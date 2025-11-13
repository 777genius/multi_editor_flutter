import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:dartz/dartz.dart' as dartz;
import '../value_objects/repository_path.dart';
import '../value_objects/file_status.dart';
import '../failures/git_failures.dart';
import 'git_branch.dart';
import 'git_remote.dart';
import 'git_commit.dart';
import 'git_stash.dart';
import 'file_change.dart';
import 'merge_conflict.dart';

part 'git_repository.freezed.dart';

/// Repository lifecycle states
enum GitRepositoryState {
  noRepository,      // No .git directory
  clean,            // No changes
  modified,         // Has uncommitted changes
  staged,           // Has staged changes
  merging,          // In merge state
  rebasing,         // In rebase state
  cherryPicking,    // In cherry-pick state
  reverting,        // In revert state
  bisecting,        // In bisect state
}

/// Aggregate root representing a Git repository
/// Invariants:
/// - Repository must have a valid .git directory
/// - Cannot have uncommitted changes when checking out branch (unless forced)
/// - HEAD must point to valid branch or commit
@freezed
class GitRepository with _$GitRepository {
  const GitRepository._();

  const factory GitRepository({
    required RepositoryPath path,
    Option<GitBranch>? currentBranch, // None if detached HEAD
    required List<GitBranch> localBranches,
    required List<GitBranch> remoteBranches,
    required List<GitRemote> remotes,
    required GitRepositoryState state,
    required List<FileChange> changes,
    required List<FileChange> stagedChanges,
    Option<GitCommit>? headCommit,
    required List<GitStash> stashes,
    Option<MergeConflict>? activeConflict,
  }) = _GitRepository;

  /// Domain logic: Can checkout branch?
  bool canCheckoutBranch() {
    return state == GitRepositoryState.clean ||
           state == GitRepositoryState.noRepository;
  }

  /// Domain logic: Has uncommitted changes?
  bool get hasUncommittedChanges {
    return changes.isNotEmpty || stagedChanges.isNotEmpty;
  }

  /// Domain logic: Has unstaged changes?
  bool get hasUnstagedChanges => changes.isNotEmpty;

  /// Domain logic: Has staged changes?
  bool get hasStagedChanges => stagedChanges.isNotEmpty;

  /// Domain logic: Can commit?
  bool canCommit() {
    return stagedChanges.isNotEmpty && state != GitRepositoryState.merging;
  }

  /// Domain logic: Is merging?
  bool get isMerging => state == GitRepositoryState.merging;

  /// Domain logic: Is rebasing?
  bool get isRebasing => state == GitRepositoryState.rebasing;

  /// Domain logic: Is in special state? (merge, rebase, etc.)
  bool get isInSpecialState {
    return state != GitRepositoryState.clean &&
           state != GitRepositoryState.modified &&
           state != GitRepositoryState.staged &&
           state != GitRepositoryState.noRepository;
  }

  /// Domain logic: Get file status
  FileStatus getFileStatus(String filePath) {
    // Check staged first (higher priority)
    final staged = stagedChanges.firstWhereOrNull(
      (change) => change.filePath == filePath,
    );
    if (staged != null) return staged.status;

    // Then check unstaged
    final unstaged = changes.firstWhereOrNull(
      (change) => change.filePath == filePath,
    );
    if (unstaged != null) return unstaged.status;

    return const FileStatus.unmodified();
  }

  /// Domain logic: Is file staged?
  bool isFileStaged(String filePath) {
    return stagedChanges.any((change) => change.filePath == filePath);
  }

  /// Domain logic: Is file modified?
  bool isFileModified(String filePath) {
    return changes.any((change) => change.filePath == filePath) ||
           stagedChanges.any((change) => change.filePath == filePath);
  }

  /// Domain logic: Stage file
  dartz.Either<GitFailure, GitRepository> stageFile(String filePath) {
    // Find file in changes
    final change = changes.firstWhereOrNull(
      (c) => c.filePath == filePath,
    );

    if (change == null) {
      return dartz.left(
        GitFailure.fileNotChanged(filePath: filePath),
      );
    }

    // Move to staged
    return dartz.right(
      copyWith(
        changes: changes.where((c) => c.filePath != filePath).toList(),
        stagedChanges: [
          ...stagedChanges,
          change.copyWith(isStaged: true),
        ],
        state: GitRepositoryState.staged,
      ),
    );
  }

  /// Domain logic: Stage multiple files
  dartz.Either<GitFailure, GitRepository> stageFiles(List<String> filePaths) {
    var result = this;

    for (final filePath in filePaths) {
      final stageResult = result.stageFile(filePath);

      result = stageResult.fold(
        (failure) => result, // Skip failures, continue with next
        (updated) => updated,
      );
    }

    return dartz.right(result);
  }

  /// Domain logic: Stage all changes
  dartz.Either<GitFailure, GitRepository> stageAll() {
    if (changes.isEmpty) {
      return dartz.right(this);
    }

    return dartz.right(
      copyWith(
        stagedChanges: [
          ...stagedChanges,
          ...changes.map((c) => c.copyWith(isStaged: true)),
        ],
        changes: [],
        state: GitRepositoryState.staged,
      ),
    );
  }

  /// Domain logic: Unstage file
  dartz.Either<GitFailure, GitRepository> unstageFile(String filePath) {
    final change = stagedChanges.firstWhereOrNull(
      (c) => c.filePath == filePath,
    );

    if (change == null) {
      return dartz.left(
        GitFailure.fileNotStaged(filePath: filePath),
      );
    }

    final newStagedChanges =
        stagedChanges.where((c) => c.filePath != filePath).toList();

    return dartz.right(
      copyWith(
        stagedChanges: newStagedChanges,
        changes: [
          ...changes,
          change.copyWith(isStaged: false),
        ],
        state: newStagedChanges.isEmpty
            ? (changes.isEmpty
                ? GitRepositoryState.clean
                : GitRepositoryState.modified)
            : GitRepositoryState.staged,
      ),
    );
  }

  /// Domain logic: Unstage all files
  dartz.Either<GitFailure, GitRepository> unstageAll() {
    if (stagedChanges.isEmpty) {
      return dartz.right(this);
    }

    return dartz.right(
      copyWith(
        changes: [
          ...changes,
          ...stagedChanges.map((c) => c.copyWith(isStaged: false)),
        ],
        stagedChanges: [],
        state: changes.isEmpty
            ? GitRepositoryState.clean
            : GitRepositoryState.modified,
      ),
    );
  }

  /// Domain logic: Can push?
  bool canPush() {
    return (currentBranch ?? none()).isSome() &&
           remotes.isNotEmpty &&
           state != GitRepositoryState.merging;
  }

  /// Domain logic: Can pull?
  bool canPull() {
    return (currentBranch ?? none()).isSome() &&
           remotes.isNotEmpty;
  }

  /// Domain logic: Get current branch or detached HEAD
  String getCurrentBranchDisplay() {
    return (currentBranch ?? none()).fold(
      () => 'Detached HEAD',
      (branch) => branch.displayName,
    );
  }

  /// Domain logic: Has active conflict?
  bool get hasActiveConflict => (activeConflict ?? none()).isSome();

  /// Domain logic: Get conflict count
  int get conflictCount {
    return (activeConflict ?? none()).fold(
      () => 0,
      (conflict) => conflict.totalFilesCount,
    );
  }

  /// Domain logic: Get branch by name
  Option<GitBranch> getBranchByName(String name) {
    final allBranches = [...localBranches, ...remoteBranches];
    final branch = allBranches.firstWhereOrNull(
      (b) => b.name.value == name,
    );
    return branch != null ? some(branch) : none();
  }

  /// Domain logic: Get remote by name
  Option<GitRemote> getRemoteByName(String name) {
    final remote = remotes.firstWhereOrNull(
      (r) => r.name.value == name,
    );
    return remote != null ? some(remote) : none();
  }

  /// Domain logic: Has remote?
  bool hasRemote(String name) {
    return remotes.any((r) => r.name.value == name);
  }

  /// Domain logic: Get default remote (origin)
  Option<GitRemote> get defaultRemote {
    final origin = remotes.firstWhereOrNull((r) => r.isOrigin);
    return origin != null ? some(origin) : none();
  }

  /// Domain logic: Total changes count
  int get totalChangesCount => changes.length + stagedChanges.length;

  /// Domain logic: Get changes summary
  String get changesSummary {
    final sb = StringBuffer();

    if (changes.isEmpty && stagedChanges.isEmpty) {
      return 'No changes';
    }

    if (stagedChanges.isNotEmpty) {
      sb.write('${stagedChanges.length} staged');
    }

    if (changes.isNotEmpty) {
      if (sb.isNotEmpty) sb.write(', ');
      sb.write('${changes.length} unstaged');
    }

    return sb.toString();
  }

  /// Domain logic: Repository status summary
  String get statusSummary {
    final sb = StringBuffer();

    sb.write(getCurrentBranchDisplay());

    if (hasUncommittedChanges) {
      sb.write(' (');
      sb.write(changesSummary);
      sb.write(')');
    }

    if (isInSpecialState) {
      sb.write(' [');
      sb.write(state.name.toUpperCase());
      sb.write(']');
    }

    return sb.toString();
  }
}

/// Extension for nullable operations
extension GitRepositoryX on GitRepository {
  /// Helper to find first where or null
  T? firstWhereOrNull<T>(Iterable<T> iterable, bool Function(T) test) {
    try {
      return iterable.firstWhere(test);
    } catch (_) {
      return null;
    }
  }
}
