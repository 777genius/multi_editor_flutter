import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart' as fp;
import '../../domain/repositories/i_git_repository.dart';
import '../../domain/entities/git_repository.dart';
import '../../domain/entities/git_commit.dart';
import '../../domain/entities/git_branch.dart';
import '../../domain/entities/git_remote.dart';
import '../../domain/entities/git_stash.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/value_objects/commit_hash.dart';
import '../../domain/value_objects/commit_message.dart';
import '../../domain/value_objects/git_author.dart';
import '../../domain/value_objects/branch_name.dart';
import '../../domain/value_objects/remote_name.dart';
import '../../domain/failures/git_failures.dart';
import '../adapters/git_command_adapter.dart';
import '../adapters/git_parser_adapter.dart';

/// Git repository implementation using git CLI
///
/// This implements IGitRepository using the git command-line interface
/// via dart:io Process. All operations are delegated to git commands.
@LazySingleton(as: IGitRepository)
class GitCliRepository implements IGitRepository {
  final GitCommandAdapter _commandAdapter;
  final GitParserAdapter _parserAdapter;

  GitCliRepository(this._commandAdapter, this._parserAdapter);

  // ============================================================================
  // Repository Operations
  // ============================================================================

  @override
  Future<Either<GitFailure, GitRepository>> init({
    required RepositoryPath path,
  }) async {
    // Create directory if it doesn't exist
    final dir = Directory(path.path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Run git init
    final result = await _commandAdapter.executeAndCheckSuccess(
      args: ['init'],
      workingDirectory: path.path,
    );

    return result.flatMap((_) => open(path: path));
  }

  @override
  Future<Either<GitFailure, GitRepository>> clone({
    required String url,
    required RepositoryPath path,
    fp.Option<String>? branch,
    ProgressCallback? onProgress,
  }) async {
    // Build clone command
    final args = [
      'clone',
      if (branch != null && branch is fp.Some<String>) ...[
        '--branch',
        (branch as fp.Some<String>).value,
      ],
      '--progress',
      url,
      path.path,
    ];

    // Execute clone
    final result = await _commandAdapter.executeAndCheckSuccess(
      args: args,
      workingDirectory: Directory.current.path,
    );

    // TODO: Parse progress from stderr and call onProgress callback

    return result.flatMap((_) => open(path: path));
  }

  @override
  Future<Either<GitFailure, GitRepository>> open({
    required RepositoryPath path,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(GitFailure.notARepository(path: path));
    }

    // Get status to build repository state
    return getStatus(path: path);
  }

  // ============================================================================
  // Status Operations
  // ============================================================================

  @override
  Future<Either<GitFailure, GitRepository>> getStatus({
    required RepositoryPath path,
  }) async {
    // Get status
    final statusResult = await _commandAdapter.executeAndGetOutput(
      args: _commandAdapter.buildStatusCommand(),
      workingDirectory: path.path,
    );

    return statusResult.flatMap((statusOutput) async {
      final parsed = _parserAdapter.parseStatus(statusOutput);

      // Get branches
      final branchesResult = await getBranches(path: path);
      if (branchesResult.isLeft()) {
        return left((branchesResult as Left).value);
      }
      final branches =
          (branchesResult as Right<GitFailure, List<GitBranch>>).value;

      // Get remotes
      final remotesResult = await getRemotes(path: path);
      if (remotesResult.isLeft()) {
        return left((remotesResult as Left).value);
      }
      final remotes =
          (remotesResult as Right<GitFailure, List<GitRemote>>).value;

      // Find current branch
      final currentBranch = parsed.currentBranch != null
          ? branches.firstWhereOrNull(
              (b) => b.name.value == parsed.currentBranch && b.isCurrent)
          : null;

      // Get head commit
      final headCommit = parsed.headCommit != null &&
              parsed.headCommit!.length == 40 &&
              parsed.headCommit != '(initial)'
          ? fp.some(CommitHash.create(parsed.headCommit!))
          : fp.none<CommitHash>();

      // Determine repository state
      final state = _determineRepositoryState(
        parsed.changes,
        parsed.stagedChanges,
      );

      return right(GitRepository(
        path: path,
        currentBranch: currentBranch != null ? fp.some(currentBranch) : fp.none(),
        localBranches: branches.where((b) => !b.isRemote).toList(),
        remoteBranches: branches.where((b) => b.isRemote).toList(),
        remotes: remotes,
        state: state,
        changes: parsed.changes,
        stagedChanges: parsed.stagedChanges,
        headCommit: headCommit.isSome()
            ? fp.some(GitCommit(
                hash: headCommit.toNullable()!,
                parentHash: fp.none(),
                author: GitAuthor.create(name: '', email: ''),
                committer: GitAuthor.create(name: '', email: ''),
                message: CommitMessage.create(''),
                authorDate: DateTime.now(),
                commitDate: DateTime.now(),
              ))
            : fp.none(),
        stashes: [],
        activeConflict: fp.none(),
      ));
    });
  }

  @override
  Future<Either<GitFailure, GitRepository>> refreshStatus({
    required RepositoryPath path,
  }) async {
    return getStatus(path: path);
  }

  // ============================================================================
  // Staging Operations
  // ============================================================================

  @override
  Future<Either<GitFailure, Unit>> stageFiles({
    required RepositoryPath path,
    required List<String> filePaths,
  }) async {
    return _commandAdapter.executeAndCheckSuccess(
      args: ['add', ...filePaths],
      workingDirectory: path.path,
    );
  }

  @override
  Future<Either<GitFailure, Unit>> stageAll({
    required RepositoryPath path,
  }) async {
    return _commandAdapter.executeAndCheckSuccess(
      args: ['add', '-A'],
      workingDirectory: path.path,
    );
  }

  @override
  Future<Either<GitFailure, Unit>> unstageFiles({
    required RepositoryPath path,
    required List<String> filePaths,
  }) async {
    return _commandAdapter.executeAndCheckSuccess(
      args: ['reset', 'HEAD', '--', ...filePaths],
      workingDirectory: path.path,
    );
  }

  @override
  Future<Either<GitFailure, Unit>> unstageAll({
    required RepositoryPath path,
  }) async {
    return _commandAdapter.executeAndCheckSuccess(
      args: ['reset', 'HEAD'],
      workingDirectory: path.path,
    );
  }

  // ============================================================================
  // Commit Operations
  // ============================================================================

  @override
  Future<Either<GitFailure, GitCommit>> commit({
    required RepositoryPath path,
    required CommitMessage message,
    required GitAuthor author,
    bool amend = false,
  }) async {
    // Build commit command
    final args = [
      'commit',
      '-m',
      message.value,
      '--author',
      author.toGitFormat(),
      if (amend) '--amend',
    ];

    // Execute commit
    final result = await _commandAdapter.executeAndCheckSuccess(
      args: args,
      workingDirectory: path.path,
    );

    // Get the created commit
    return result.flatMap((_) async {
      final logResult = await _commandAdapter.executeAndGetOutput(
        args: ['log', '-1', '--pretty=format:%H%n%P%n%an%n%ae%n%at%n%cn%n%ce%n%ct%n%s%n%b%n---END---'],
        workingDirectory: path.path,
      );

      return logResult.map((output) {
        final commits = _parserAdapter.parseLog(output);
        if (commits.isEmpty) {
          throw Exception('Failed to get commit details');
        }
        return commits.first;
      });
    });
  }

  // ============================================================================
  // Branch Operations
  // ============================================================================

  @override
  Future<Either<GitFailure, List<GitBranch>>> getBranches({
    required RepositoryPath path,
    bool includeRemote = true,
  }) async {
    final result = await _commandAdapter.executeAndGetOutput(
      args: _commandAdapter.buildBranchListCommand(includeRemote: includeRemote),
      workingDirectory: path.path,
    );

    return result.map((output) => _parserAdapter.parseBranches(output));
  }

  @override
  Future<Either<GitFailure, GitBranch>> createBranch({
    required RepositoryPath path,
    required BranchName name,
    fp.Option<CommitHash>? startPoint,
  }) async {
    // Build create branch command
    final args = [
      'branch',
      name.value,
      if (startPoint != null && startPoint is fp.Some<CommitHash>)
        (startPoint as fp.Some<CommitHash>).value.value,
    ];

    final result = await _commandAdapter.executeAndCheckSuccess(
      args: args,
      workingDirectory: path.path,
    );

    return result.map((_) => GitBranch(
          name: name,
          isCurrent: false,
          isRemote: false,
          headCommit: startPoint,
        ));
  }

  @override
  Future<Either<GitFailure, Unit>> checkout({
    required RepositoryPath path,
    required BranchName branch,
    bool force = false,
  }) async {
    final args = [
      'checkout',
      if (force) '--force',
      branch.value,
    ];

    return _commandAdapter.executeAndCheckSuccess(
      args: args,
      workingDirectory: path.path,
    );
  }

  @override
  Future<Either<GitFailure, Unit>> deleteBranch({
    required RepositoryPath path,
    required BranchName branch,
    bool force = false,
    bool remote = false,
  }) async {
    final args = remote
        ? ['push', 'origin', '--delete', branch.value]
        : ['branch', force ? '-D' : '-d', branch.value];

    return _commandAdapter.executeAndCheckSuccess(
      args: args,
      workingDirectory: path.path,
    );
  }

  @override
  Future<Either<GitFailure, Unit>> merge({
    required RepositoryPath path,
    required BranchName branch,
    bool noFastForward = false,
  }) async {
    final args = [
      'merge',
      if (noFastForward) '--no-ff',
      branch.value,
    ];

    return _commandAdapter.executeAndCheckSuccess(
      args: args,
      workingDirectory: path.path,
    );
  }

  // ============================================================================
  // Remote Operations
  // ============================================================================

  @override
  Future<Either<GitFailure, List<GitRemote>>> getRemotes({
    required RepositoryPath path,
  }) async {
    final result = await _commandAdapter.executeAndGetOutput(
      args: _commandAdapter.buildRemoteListCommand(),
      workingDirectory: path.path,
    );

    return result.map((output) => _parserAdapter.parseRemotes(output));
  }

  @override
  Future<Either<GitFailure, Unit>> addRemote({
    required RepositoryPath path,
    required RemoteName name,
    required String url,
    bool fetch = false,
  }) async {
    final addResult = await _commandAdapter.executeAndCheckSuccess(
      args: ['remote', 'add', name.value, url],
      workingDirectory: path.path,
    );

    if (fetch && addResult.isRight()) {
      return this.fetch(
        path: path,
        remote: name,
        branch: fp.none(),
        prune: false,
        tags: true,
        onProgress: null,
      );
    }

    return addResult;
  }

  @override
  Future<Either<GitFailure, Unit>> removeRemote({
    required RepositoryPath path,
    required RemoteName name,
  }) async {
    return _commandAdapter.executeAndCheckSuccess(
      args: ['remote', 'remove', name.value],
      workingDirectory: path.path,
    );
  }

  @override
  Future<Either<GitFailure, Unit>> renameRemote({
    required RepositoryPath path,
    required RemoteName oldName,
    required RemoteName newName,
  }) async {
    return _commandAdapter.executeAndCheckSuccess(
      args: ['remote', 'rename', oldName.value, newName.value],
      workingDirectory: path.path,
    );
  }

  @override
  Future<Either<GitFailure, Unit>> push({
    required RepositoryPath path,
    required RemoteName remote,
    required BranchName branch,
    bool force = false,
    bool setUpstream = false,
    ProgressCallback? onProgress,
  }) async {
    final args = [
      'push',
      if (setUpstream) '-u',
      if (force) '--force',
      remote.value,
      branch.value,
    ];

    // TODO: Parse progress and call onProgress callback

    return _commandAdapter.executeAndCheckSuccess(
      args: args,
      workingDirectory: path.path,
    );
  }

  @override
  Future<Either<GitFailure, Unit>> pull({
    required RepositoryPath path,
    required RemoteName remote,
    fp.Option<BranchName>? branch,
    bool rebase = false,
    ProgressCallback? onProgress,
  }) async {
    final args = [
      'pull',
      if (rebase) '--rebase',
      remote.value,
      if (branch != null && branch is fp.Some<BranchName>)
        (branch as fp.Some<BranchName>).value.value,
    ];

    // TODO: Parse progress and call onProgress callback

    return _commandAdapter.executeAndCheckSuccess(
      args: args,
      workingDirectory: path.path,
    );
  }

  @override
  Future<Either<GitFailure, Unit>> fetch({
    required RepositoryPath path,
    required RemoteName remote,
    fp.Option<BranchName>? branch,
    bool prune = false,
    bool tags = true,
    ProgressCallback? onProgress,
  }) async {
    final args = [
      'fetch',
      if (prune) '--prune',
      if (tags) '--tags',
      remote.value,
      if (branch != null && branch is fp.Some<BranchName>)
        (branch as fp.Some<BranchName>).value.value,
    ];

    // TODO: Parse progress and call onProgress callback

    return _commandAdapter.executeAndCheckSuccess(
      args: args,
      workingDirectory: path.path,
    );
  }

  @override
  Future<Either<GitFailure, Unit>> fetchAll({
    required RepositoryPath path,
    bool prune = false,
    bool tags = true,
    ProgressCallback? onProgress,
  }) async {
    final args = [
      'fetch',
      '--all',
      if (prune) '--prune',
      if (tags) '--tags',
    ];

    return _commandAdapter.executeAndCheckSuccess(
      args: args,
      workingDirectory: path.path,
    );
  }

  @override
  Future<Either<GitFailure, int>> checkBehind({
    required RepositoryPath path,
    fp.Option<BranchName>? branch,
  }) async {
    // Get status to check ahead/behind
    final statusResult = await _commandAdapter.executeAndGetOutput(
      args: _commandAdapter.buildStatusCommand(),
      workingDirectory: path.path,
    );

    return statusResult.map((output) {
      final parsed = _parserAdapter.parseStatus(output);
      return parsed.behind;
    });
  }

  @override
  Future<Either<GitFailure, int>> checkAhead({
    required RepositoryPath path,
    fp.Option<BranchName>? branch,
  }) async {
    // Get status to check ahead/behind
    final statusResult = await _commandAdapter.executeAndGetOutput(
      args: _commandAdapter.buildStatusCommand(),
      workingDirectory: path.path,
    );

    return statusResult.map((output) {
      final parsed = _parserAdapter.parseStatus(output);
      return parsed.ahead;
    });
  }

  // ============================================================================
  // History Operations
  // ============================================================================

  @override
  Future<Either<GitFailure, List<GitCommit>>> getHistory({
    required RepositoryPath path,
    fp.Option<BranchName>? branch,
    int maxCount = 100,
    int skip = 0,
  }) async {
    final branchStr = branch != null && branch is fp.Some<BranchName>
        ? (branch as fp.Some<BranchName>).value.value
        : null;

    final result = await _commandAdapter.executeAndGetOutput(
      args: _commandAdapter.buildLogCommand(
        branch: branchStr,
        maxCount: maxCount,
        skip: skip,
      ),
      workingDirectory: path.path,
    );

    return result.map((output) => _parserAdapter.parseLog(output));
  }

  @override
  Future<Either<GitFailure, List<GitCommit>>> getFileHistory({
    required RepositoryPath path,
    required String filePath,
    int maxCount = 100,
  }) async {
    final result = await _commandAdapter.executeAndGetOutput(
      args: _commandAdapter.buildLogCommand(
        filePath: filePath,
        maxCount: maxCount,
      ),
      workingDirectory: path.path,
    );

    return result.map((output) => _parserAdapter.parseLog(output));
  }

  // ============================================================================
  // Stash Operations
  // ============================================================================

  @override
  Future<Either<GitFailure, GitStash>> stash({
    required RepositoryPath path,
    String? message,
    bool includeUntracked = false,
    bool keepIndex = false,
  }) async {
    final args = [
      'stash',
      'push',
      if (message != null) ...['-m', message],
      if (includeUntracked) '-u',
      if (keepIndex) '--keep-index',
    ];

    final result = await _commandAdapter.executeAndCheckSuccess(
      args: args,
      workingDirectory: path.path,
    );

    return result.map((_) => GitStash(
          index: 0,
          description: message ?? 'WIP',
          createdAt: DateTime.now(),
        ));
  }

  @override
  Future<Either<GitFailure, GitStash>> stashFiles({
    required RepositoryPath path,
    required List<String> filePaths,
    String? message,
  }) async {
    final args = [
      'stash',
      'push',
      if (message != null) ...['-m', message],
      '--',
      ...filePaths,
    ];

    final result = await _commandAdapter.executeAndCheckSuccess(
      args: args,
      workingDirectory: path.path,
    );

    return result.map((_) => GitStash(
          index: 0,
          description: message ?? 'WIP',
          createdAt: DateTime.now(),
        ));
  }

  @override
  Future<Either<GitFailure, List<GitStash>>> getStashes({
    required RepositoryPath path,
  }) async {
    final result = await _commandAdapter.executeAndGetOutput(
      args: ['stash', 'list'],
      workingDirectory: path.path,
    );

    return result.map((output) => _parserAdapter.parseStashes(output));
  }

  @override
  Future<Either<GitFailure, String>> showStash({
    required RepositoryPath path,
    required int stashIndex,
  }) async {
    return _commandAdapter.executeAndGetOutput(
      args: ['stash', 'show', '-p', 'stash@{$stashIndex}'],
      workingDirectory: path.path,
    );
  }

  @override
  Future<Either<GitFailure, Unit>> applyStash({
    required RepositoryPath path,
    required int stashIndex,
    bool pop = false,
    bool restoreIndex = false,
  }) async {
    final command = pop ? 'pop' : 'apply';
    final args = [
      'stash',
      command,
      if (restoreIndex) '--index',
      'stash@{$stashIndex}',
    ];

    return _commandAdapter.executeAndCheckSuccess(
      args: args,
      workingDirectory: path.path,
    );
  }

  @override
  Future<Either<GitFailure, Unit>> dropStash({
    required RepositoryPath path,
    required int stashIndex,
  }) async {
    return _commandAdapter.executeAndCheckSuccess(
      args: ['stash', 'drop', 'stash@{$stashIndex}'],
      workingDirectory: path.path,
    );
  }

  @override
  Future<Either<GitFailure, Unit>> clearStashes({
    required RepositoryPath path,
  }) async {
    return _commandAdapter.executeAndCheckSuccess(
      args: ['stash', 'clear'],
      workingDirectory: path.path,
    );
  }

  @override
  Future<Either<GitFailure, Unit>> createBranchFromStash({
    required RepositoryPath path,
    required String branchName,
    required int stashIndex,
  }) async {
    return _commandAdapter.executeAndCheckSuccess(
      args: ['stash', 'branch', branchName, 'stash@{$stashIndex}'],
      workingDirectory: path.path,
    );
  }

  // ============================================================================
  // Rebase Operations
  // ============================================================================

  @override
  Future<Either<GitFailure, Unit>> rebase({
    required RepositoryPath path,
    required BranchName onto,
    bool interactive = false,
  }) async {
    final args = [
      'rebase',
      if (interactive) '-i',
      onto.value,
    ];

    return _commandAdapter.executeAndCheckSuccess(
      args: args,
      workingDirectory: path.path,
    );
  }

  @override
  Future<Either<GitFailure, Unit>> rebaseContinue({
    required RepositoryPath path,
  }) async {
    return _commandAdapter.executeAndCheckSuccess(
      args: ['rebase', '--continue'],
      workingDirectory: path.path,
    );
  }

  @override
  Future<Either<GitFailure, Unit>> rebaseSkip({
    required RepositoryPath path,
  }) async {
    return _commandAdapter.executeAndCheckSuccess(
      args: ['rebase', '--skip'],
      workingDirectory: path.path,
    );
  }

  @override
  Future<Either<GitFailure, Unit>> rebaseAbort({
    required RepositoryPath path,
  }) async {
    return _commandAdapter.executeAndCheckSuccess(
      args: ['rebase', '--abort'],
      workingDirectory: path.path,
    );
  }

  @override
  Future<Either<GitFailure, bool>> isRebaseInProgress({
    required RepositoryPath path,
  }) async {
    // Check if .git/rebase-merge or .git/rebase-apply exists
    final rebaseMergeDir = Directory('${path.gitDirPath}/rebase-merge');
    final rebaseApplyDir = Directory('${path.gitDirPath}/rebase-apply');

    final mergeExists = await rebaseMergeDir.exists();
    final applyExists = await rebaseApplyDir.exists();

    return right(mergeExists || applyExists);
  }

  @override
  Future<Either<GitFailure, Unit>> rebaseInteractiveRange({
    required RepositoryPath path,
    required String fromCommit,
    required String toCommit,
  }) async {
    return _commandAdapter.executeAndCheckSuccess(
      args: ['rebase', '-i', '$fromCommit..$toCommit'],
      workingDirectory: path.path,
    );
  }

  // ============================================================================
  // Blame Operations
  // ============================================================================

  @override
  Future<Either<GitFailure, List<BlameLine>>> getBlame({
    required RepositoryPath path,
    required String filePath,
    CommitHash? commit,
    int? startLine,
    int? endLine,
  }) async {
    final result = await _commandAdapter.executeAndGetOutput(
      args: _commandAdapter.buildBlameCommand(
        filePath: filePath,
        commit: commit?.value,
        startLine: startLine,
        endLine: endLine,
      ),
      workingDirectory: path.path,
    );

    return result.map((output) => _parserAdapter.parseBlame(output));
  }

  // ============================================================================
  // Conflict Resolution Operations
  // ============================================================================

  @override
  Future<Either<GitFailure, List<MergeConflict>>> getConflicts({
    required RepositoryPath path,
  }) async {
    // Get status to find conflicted files
    final statusResult = await _commandAdapter.executeAndGetOutput(
      args: _commandAdapter.buildStatusCommand(),
      workingDirectory: path.path,
    );

    return statusResult.map((output) {
      final parsed = _parserAdapter.parseStatus(output);
      final conflictedFiles =
          parsed.changes.where((c) => c.status.isConflicted).toList();

      // TODO: Parse conflict regions from file content
      return [];
    });
  }

  @override
  Future<Either<GitFailure, Unit>> acceptIncoming({
    required RepositoryPath path,
    required String filePath,
  }) async {
    return _commandAdapter.executeAndCheckSuccess(
      args: ['checkout', '--theirs', filePath],
      workingDirectory: path.path,
    ).flatMap((_) => markResolved(path: path, filePath: filePath));
  }

  @override
  Future<Either<GitFailure, Unit>> acceptCurrent({
    required RepositoryPath path,
    required String filePath,
  }) async {
    return _commandAdapter.executeAndCheckSuccess(
      args: ['checkout', '--ours', filePath],
      workingDirectory: path.path,
    ).flatMap((_) => markResolved(path: path, filePath: filePath));
  }

  @override
  Future<Either<GitFailure, Unit>> acceptBoth({
    required RepositoryPath path,
    required String filePath,
  }) async {
    // TODO: Implement accepting both sides
    // This requires custom merge logic
    return left(GitFailure.unknown(
      message: 'Accept both not yet implemented',
    ));
  }

  @override
  Future<Either<GitFailure, Unit>> markResolved({
    required RepositoryPath path,
    required String filePath,
  }) async {
    return _commandAdapter.executeAndCheckSuccess(
      args: ['add', filePath],
      workingDirectory: path.path,
    );
  }

  @override
  Future<Either<GitFailure, Unit>> resolveConflictWithContent({
    required RepositoryPath path,
    required String filePath,
    required String content,
  }) async {
    // CRITICAL: Use atomic write to prevent data loss during conflict resolution
    // If process crashes mid-write, file would be corrupted without atomic write
    final file = File('${path.path}/$filePath');
    final tempFile = File('${file.path}.tmp.${DateTime.now().millisecondsSinceEpoch}');

    try {
      // Write content to temp file with flush
      await tempFile.writeAsString(content, flush: true);

      // Atomic rename - prevents partial writes
      await tempFile.rename(file.path);
    } catch (e) {
      // Clean up temp file on error
      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {
        // Ignore cleanup errors
      }

      return left(GitFailure.unknown(
        message: 'Failed to write file: ${e.toString()}',
        error: e,
      ));
    }

    // Mark as resolved
    return markResolved(path: path, filePath: filePath);
  }

  @override
  Future<Either<GitFailure, String>> getConflictContent({
    required RepositoryPath path,
    required String filePath,
  }) async {
    final file = File('${path.path}/$filePath');
    try {
      final content = await file.readAsString();
      return right(content);
    } catch (e) {
      return left(GitFailure.unknown(
        message: 'Failed to read file: ${e.toString()}',
        error: e,
      ));
    }
  }

  @override
  Future<Either<GitFailure, Unit>> abortMergeOrRebase({
    required RepositoryPath path,
  }) async {
    // Check if merge is in progress
    final mergeHeadFile = File('${path.gitDirPath}/MERGE_HEAD');
    if (await mergeHeadFile.exists()) {
      return _commandAdapter.executeAndCheckSuccess(
        args: ['merge', '--abort'],
        workingDirectory: path.path,
      );
    }

    // Check if rebase is in progress
    final rebaseResult = await isRebaseInProgress(path: path);
    return rebaseResult.flatMap((inProgress) {
      if (inProgress) {
        return rebaseAbort(path: path);
      }
      return left(GitFailure.unknown(
        message: 'No merge or rebase in progress',
      ));
    });
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Determine repository state from changes
  GitRepositoryState _determineRepositoryState(
    List<FileChange> changes,
    List<FileChange> stagedChanges,
  ) {
    // Check for conflicts
    if (changes.any((c) => c.status.isConflicted)) {
      return GitRepositoryState.merging;
    }

    // Check for staged changes
    if (stagedChanges.isNotEmpty) {
      return GitRepositoryState.staged;
    }

    // Check for unstaged changes
    if (changes.isNotEmpty) {
      return GitRepositoryState.modified;
    }

    // Clean state
    return GitRepositoryState.clean;
  }
}

/// Extension to add firstWhereOrNull to Iterable
extension _IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
