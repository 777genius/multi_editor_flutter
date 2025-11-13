import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';
import '../value_objects/repository_path.dart';
import '../value_objects/branch_name.dart';
import '../value_objects/remote_name.dart';
import '../entities/git_commit.dart';
import '../entities/git_branch.dart';
import '../entities/merge_conflict.dart';

part 'git_domain_events.freezed.dart';

/// Base class for all git domain events
abstract class GitDomainEvent {
  const GitDomainEvent();

  DateTime get occurredAt;
}

/// Repository initialized event
@freezed
class RepositoryInitializedDomainEvent extends GitDomainEvent
    with _$RepositoryInitializedDomainEvent {
  const factory RepositoryInitializedDomainEvent({
    required RepositoryPath path,
    required DateTime occurredAt,
  }) = _RepositoryInitializedDomainEvent;
}

/// Repository opened event
@freezed
class RepositoryOpenedDomainEvent extends GitDomainEvent
    with _$RepositoryOpenedDomainEvent {
  const factory RepositoryOpenedDomainEvent({
    required RepositoryPath path,
    required DateTime occurredAt,
  }) = _RepositoryOpenedDomainEvent;
}

/// Files staged event
@freezed
class FilesStagedDomainEvent extends GitDomainEvent
    with _$FilesStagedDomainEvent {
  const factory FilesStagedDomainEvent({
    required RepositoryPath path,
    required List<String> filePaths,
    required DateTime occurredAt,
  }) = _FilesStagedDomainEvent;
}

/// Files unstaged event
@freezed
class FilesUnstagedDomainEvent extends GitDomainEvent
    with _$FilesUnstagedDomainEvent {
  const factory FilesUnstagedDomainEvent({
    required RepositoryPath path,
    required List<String> filePaths,
    required DateTime occurredAt,
  }) = _FilesUnstagedDomainEvent;
}

/// Commit created event
@freezed
class CommitCreatedDomainEvent extends GitDomainEvent
    with _$CommitCreatedDomainEvent {
  const factory CommitCreatedDomainEvent({
    required RepositoryPath path,
    required GitCommit commit,
    required DateTime occurredAt,
  }) = _CommitCreatedDomainEvent;
}

/// Branch created event
@freezed
class BranchCreatedDomainEvent extends GitDomainEvent
    with _$BranchCreatedDomainEvent {
  const factory BranchCreatedDomainEvent({
    required RepositoryPath path,
    required GitBranch branch,
    required DateTime occurredAt,
  }) = _BranchCreatedDomainEvent;
}

/// Branch deleted event
@freezed
class BranchDeletedDomainEvent extends GitDomainEvent
    with _$BranchDeletedDomainEvent {
  const factory BranchDeletedDomainEvent({
    required RepositoryPath path,
    required BranchName branchName,
    required DateTime occurredAt,
  }) = _BranchDeletedDomainEvent;
}

/// Branch checked out event
@freezed
class BranchCheckedOutDomainEvent extends GitDomainEvent
    with _$BranchCheckedOutDomainEvent {
  const factory BranchCheckedOutDomainEvent({
    required RepositoryPath path,
    required BranchName branch,
    required DateTime occurredAt,
  }) = _BranchCheckedOutDomainEvent;
}

/// Changes pushed event
@freezed
class ChangesPushedDomainEvent extends GitDomainEvent
    with _$ChangesPushedDomainEvent {
  const factory ChangesPushedDomainEvent({
    required RepositoryPath path,
    required RemoteName remote,
    required BranchName branch,
    required int commitCount,
    required DateTime occurredAt,
  }) = _ChangesPushedDomainEvent;
}

/// Changes pulled event
@freezed
class ChangesPulledDomainEvent extends GitDomainEvent
    with _$ChangesPulledDomainEvent {
  const factory ChangesPulledDomainEvent({
    required RepositoryPath path,
    required RemoteName remote,
    required BranchName branch,
    required int commitCount,
    required List<String> changedFiles,
    required DateTime occurredAt,
  }) = _ChangesPulledDomainEvent;
}

/// Merge conflict detected event
@freezed
class MergeConflictDomainEvent extends GitDomainEvent
    with _$MergeConflictDomainEvent {
  const factory MergeConflictDomainEvent({
    required RepositoryPath path,
    required MergeConflict conflict,
    required DateTime occurredAt,
  }) = _MergeConflictDomainEvent;
}

/// Conflict resolved event
@freezed
class ConflictResolvedDomainEvent extends GitDomainEvent
    with _$ConflictResolvedDomainEvent {
  const factory ConflictResolvedDomainEvent({
    required RepositoryPath path,
    required String filePath,
    required DateTime occurredAt,
  }) = _ConflictResolvedDomainEvent;
}

/// Remote added event
@freezed
class RemoteAddedDomainEvent extends GitDomainEvent
    with _$RemoteAddedDomainEvent {
  const factory RemoteAddedDomainEvent({
    required RepositoryPath path,
    required RemoteName remoteName,
    required String url,
    required DateTime occurredAt,
  }) = _RemoteAddedDomainEvent;
}

/// Remote removed event
@freezed
class RemoteRemovedDomainEvent extends GitDomainEvent
    with _$RemoteRemovedDomainEvent {
  const factory RemoteRemovedDomainEvent({
    required RepositoryPath path,
    required RemoteName remoteName,
    required DateTime occurredAt,
  }) = _RemoteRemovedDomainEvent;
}

/// Stash created event
@freezed
class StashCreatedDomainEvent extends GitDomainEvent
    with _$StashCreatedDomainEvent {
  const factory StashCreatedDomainEvent({
    required RepositoryPath path,
    required int stashIndex,
    Option<String>? message,
    required DateTime occurredAt,
  }) = _StashCreatedDomainEvent;
}

/// Stash applied event
@freezed
class StashAppliedDomainEvent extends GitDomainEvent
    with _$StashAppliedDomainEvent {
  const factory StashAppliedDomainEvent({
    required RepositoryPath path,
    required int stashIndex,
    required bool popped,
    required DateTime occurredAt,
  }) = _StashAppliedDomainEvent;
}
