import 'package:freezed_annotation/freezed_annotation.dart';
import '../value_objects/repository_path.dart';
import '../value_objects/branch_name.dart';
import '../value_objects/remote_name.dart';
import '../entities/merge_conflict.dart';

part 'git_failures.freezed.dart';

/// Base failure class for git operations
@freezed
class GitFailure with _$GitFailure {
  const factory GitFailure.repositoryNotFound({
    required RepositoryPath path,
  }) = _RepositoryNotFound;

  const factory GitFailure.notARepository({
    required RepositoryPath path,
  }) = _NotARepository;

  const factory GitFailure.fileNotChanged({
    required String filePath,
  }) = _FileNotChanged;

  const factory GitFailure.fileNotStaged({
    required String filePath,
  }) = _FileNotStaged;

  const factory GitFailure.nothingToCommit() = _NothingToCommit;

  const factory GitFailure.branchNotFound({
    required BranchName branch,
  }) = _BranchNotFound;

  const factory GitFailure.branchAlreadyExists({
    required BranchName branch,
  }) = _BranchAlreadyExists;

  const factory GitFailure.cannotCheckout({
    required String reason,
  }) = _CannotCheckout;

  const factory GitFailure.mergeConflict({
    required MergeConflict conflict,
  }) = _MergeConflictFailure;

  const factory GitFailure.remoteNotFound({
    required RemoteName remote,
  }) = _RemoteNotFound;

  const factory GitFailure.remoteAlreadyExists({
    required RemoteName remote,
  }) = _RemoteAlreadyExists;

  const factory GitFailure.networkError({
    required String message,
  }) = _NetworkError;

  const factory GitFailure.authenticationFailed({
    required String url,
    String? reason,
  }) = _AuthenticationFailed;

  const factory GitFailure.permissionDenied({
    required String path,
  }) = _PermissionDenied;

  const factory GitFailure.commandFailed({
    required String command,
    required int exitCode,
    required String stderr,
  }) = _CommandFailed;

  const factory GitFailure.invalidUrl({
    required String url,
  }) = _InvalidUrl;

  const factory GitFailure.timeout({
    required String operation,
    required Duration duration,
  }) = _Timeout;

  const factory GitFailure.diskFull() = _DiskFull;

  const factory GitFailure.unknown({
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) = _Unknown;

  const GitFailure._();

  /// Get user-friendly error message
  String get userMessage {
    return when(
      repositoryNotFound: (path) =>
          'Repository not found at: ${path.path}',
      notARepository: (path) =>
          'Not a git repository: ${path.path}',
      fileNotChanged: (filePath) =>
          'File has no changes: $filePath',
      fileNotStaged: (filePath) =>
          'File is not staged: $filePath',
      nothingToCommit: () =>
          'Nothing to commit, working tree clean',
      branchNotFound: (branch) =>
          'Branch not found: ${branch.value}',
      branchAlreadyExists: (branch) =>
          'Branch already exists: ${branch.value}',
      cannotCheckout: (reason) =>
          'Cannot checkout: $reason',
      mergeConflict: (conflict) =>
          'Merge conflict: ${conflict.summary}',
      remoteNotFound: (remote) =>
          'Remote not found: ${remote.value}',
      remoteAlreadyExists: (remote) =>
          'Remote already exists: ${remote.value}',
      networkError: (message) =>
          'Network error: $message',
      authenticationFailed: (url, reason) =>
          'Authentication failed for $url${reason != null ? ": $reason" : ""}',
      permissionDenied: (path) =>
          'Permission denied: $path',
      commandFailed: (command, exitCode, stderr) =>
          'Git command failed (exit $exitCode): $command\n$stderr',
      invalidUrl: (url) =>
          'Invalid URL: $url',
      timeout: (operation, duration) =>
          'Operation timed out: $operation (${duration.inSeconds}s)',
      diskFull: () =>
          'Disk is full',
      unknown: (message, error, stackTrace) =>
          'Unknown error: $message${error != null ? "\n$error" : ""}',
    );
  }

  /// Is recoverable error?
  bool get isRecoverable {
    return when(
      repositoryNotFound: (_) => false,
      notARepository: (_) => false,
      fileNotChanged: (_) => true,
      fileNotStaged: (_) => true,
      nothingToCommit: () => true,
      branchNotFound: (_) => false,
      branchAlreadyExists: (_) => true,
      cannotCheckout: (_) => true,
      mergeConflict: (_) => true, // Can be resolved
      remoteNotFound: (_) => false,
      remoteAlreadyExists: (_) => true,
      networkError: (_) => true, // Can retry
      authenticationFailed: (_, __) => true, // Can re-authenticate
      permissionDenied: (_) => false,
      commandFailed: (_, __, ___) => true, // Depends on command
      invalidUrl: (_) => true, // Can correct URL
      timeout: (_, __) => true, // Can retry
      diskFull: () => false,
      unknown: (_, __, ___) => false,
    );
  }
}
