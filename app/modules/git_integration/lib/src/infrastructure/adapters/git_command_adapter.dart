import 'dart:io';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import '../../domain/failures/git_failures.dart';

/// Result of a git command execution
class GitCommandResult {
  final int exitCode;
  final String stdout;
  final String stderr;

  GitCommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  bool get isSuccess => exitCode == 0;
  bool get isError => exitCode != 0;

  String get output => stdout;
  String get error => stderr;
}

/// Adapter for executing git commands using dart:io Process
///
/// This provides a clean interface for running git commands and
/// handling their output. All git operations go through this adapter.
class GitCommandAdapter {
  /// Execute a git command
  ///
  /// Parameters:
  /// - args: Git command arguments (e.g., ['status', '--porcelain'])
  /// - workingDirectory: Repository path
  /// - environment: Additional environment variables
  ///
  /// Returns: GitCommandResult or GitFailure
  Future<Either<GitFailure, GitCommandResult>> execute({
    required List<String> args,
    required String workingDirectory,
    Map<String, String>? environment,
  }) async {
    try {
      // Prepare environment
      final env = <String, String>{
        ...Platform.environment,
        if (environment != null) ...environment,
      };

      // Execute git command
      final process = await Process.start(
        'git',
        args,
        workingDirectory: workingDirectory,
        environment: env,
        runInShell: false,
      );

      // Collect output
      final stdoutFuture = process.stdout
          .transform(utf8.decoder)
          .fold<String>('', (previous, element) => previous + element);

      final stderrFuture = process.stderr
          .transform(utf8.decoder)
          .fold<String>('', (previous, element) => previous + element);

      // Wait for completion
      final exitCode = await process.exitCode;
      final stdout = await stdoutFuture;
      final stderr = await stderrFuture;

      final result = GitCommandResult(
        exitCode: exitCode,
        stdout: stdout.trim(),
        stderr: stderr.trim(),
      );

      // Check for errors
      if (result.isError) {
        return left(_mapError(args, result));
      }

      return right(result);
    } on ProcessException catch (e, stackTrace) {
      return left(
        GitFailure.commandFailed(
          command: 'git ${args.join(' ')}',
          exitCode: -1,
          stderr: e.message,
        ),
      );
    } catch (e, stackTrace) {
      return left(
        GitFailure.unknown(
          message: 'Failed to execute git command: ${e.toString()}',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Execute a git command and return stdout
  ///
  /// This is a convenience method that returns only stdout on success.
  Future<Either<GitFailure, String>> executeAndGetOutput({
    required List<String> args,
    required String workingDirectory,
    Map<String, String>? environment,
  }) async {
    final result = await execute(
      args: args,
      workingDirectory: workingDirectory,
      environment: environment,
    );

    return result.map((r) => r.stdout);
  }

  /// Execute a git command and check success
  ///
  /// This is a convenience method that returns Unit on success.
  Future<Either<GitFailure, Unit>> executeAndCheckSuccess({
    required List<String> args,
    required String workingDirectory,
    Map<String, String>? environment,
  }) async {
    final result = await execute(
      args: args,
      workingDirectory: workingDirectory,
      environment: environment,
    );

    return result.map((_) => unit);
  }

  /// Execute a git command with stdin input
  ///
  /// This is useful for commands that require interactive input.
  Future<Either<GitFailure, GitCommandResult>> executeWithInput({
    required List<String> args,
    required String workingDirectory,
    required String input,
    Map<String, String>? environment,
  }) async {
    try {
      // Prepare environment
      final env = <String, String>{
        ...Platform.environment,
        if (environment != null) ...environment,
      };

      // Execute git command
      final process = await Process.start(
        'git',
        args,
        workingDirectory: workingDirectory,
        environment: env,
        runInShell: false,
      );

      // Write input
      process.stdin.write(input);
      await process.stdin.flush();
      await process.stdin.close();

      // Collect output
      final stdoutFuture = process.stdout
          .transform(utf8.decoder)
          .fold<String>('', (previous, element) => previous + element);

      final stderrFuture = process.stderr
          .transform(utf8.decoder)
          .fold<String>('', (previous, element) => previous + element);

      // Wait for completion
      final exitCode = await process.exitCode;
      final stdout = await stdoutFuture;
      final stderr = await stderrFuture;

      final result = GitCommandResult(
        exitCode: exitCode,
        stdout: stdout.trim(),
        stderr: stderr.trim(),
      );

      // Check for errors
      if (result.isError) {
        return left(_mapError(args, result));
      }

      return right(result);
    } on ProcessException catch (e, stackTrace) {
      return left(
        GitFailure.commandFailed(
          command: 'git ${args.join(' ')}',
          exitCode: -1,
          stderr: e.message,
        ),
      );
    } catch (e, stackTrace) {
      return left(
        GitFailure.unknown(
          message: 'Failed to execute git command: ${e.toString()}',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Check if git is installed
  Future<bool> isGitInstalled() async {
    try {
      final result = await Process.run('git', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Get git version
  Future<Either<GitFailure, String>> getGitVersion() async {
    final result = await executeAndGetOutput(
      args: ['--version'],
      workingDirectory: Directory.current.path,
    );

    return result.map((output) {
      // Parse "git version 2.39.0" -> "2.39.0"
      final match = RegExp(r'git version (.+)').firstMatch(output);
      return match?.group(1) ?? output;
    });
  }

  /// Map git error to appropriate GitFailure
  GitFailure _mapError(List<String> args, GitCommandResult result) {
    final stderr = result.stderr.toLowerCase();
    final command = 'git ${args.join(' ')}';

    // Repository not found
    if (stderr.contains('not a git repository') ||
        stderr.contains('no such file or directory')) {
      return GitFailure.unknown(
        message: 'Not a git repository',
      );
    }

    // Network errors
    if (stderr.contains('could not resolve host') ||
        stderr.contains('failed to connect') ||
        stderr.contains('network unreachable') ||
        stderr.contains('connection timed out')) {
      return GitFailure.networkError(
        message: result.stderr,
      );
    }

    // Authentication errors
    if (stderr.contains('authentication failed') ||
        stderr.contains('permission denied') ||
        stderr.contains('could not read username') ||
        stderr.contains('could not read password')) {
      return GitFailure.authenticationFailed(
        url: '',
        reason: result.stderr,
      );
    }

    // Merge conflicts
    if (stderr.contains('merge conflict') ||
        stderr.contains('conflict') ||
        result.stdout.contains('conflict')) {
      return GitFailure.unknown(
        message: 'Merge conflict detected',
      );
    }

    // Branch not found
    if (stderr.contains('not a valid branch') ||
        stderr.contains('branch not found') ||
        stderr.contains("pathspec '") && stderr.contains("did not match")) {
      return GitFailure.unknown(
        message: 'Branch not found',
      );
    }

    // Generic command failure
    return GitFailure.commandFailed(
      command: command,
      exitCode: result.exitCode,
      stderr: result.stderr,
    );
  }

  /// Build git command for status
  List<String> buildStatusCommand({bool porcelain = true}) {
    return [
      'status',
      if (porcelain) '--porcelain=v2',
      '--branch',
    ];
  }

  /// Build git command for diff
  List<String> buildDiffCommand({
    bool staged = false,
    bool nameOnly = false,
    String? oldCommit,
    String? newCommit,
    String? filePath,
  }) {
    return [
      'diff',
      if (staged) '--staged',
      if (nameOnly) '--name-only',
      if (oldCommit != null) oldCommit,
      if (newCommit != null) newCommit,
      if (filePath != null) '--',
      if (filePath != null) filePath,
    ];
  }

  /// Build git command for log
  List<String> buildLogCommand({
    String? branch,
    int? maxCount,
    int? skip,
    String? filePath,
    bool pretty = true,
  }) {
    return [
      'log',
      if (pretty) '--pretty=format:%H%n%P%n%an%n%ae%n%at%n%cn%n%ce%n%ct%n%s%n%b%n---END---',
      if (branch != null) branch,
      if (maxCount != null) '-$maxCount',
      if (skip != null) '--skip=$skip',
      if (filePath != null) '--',
      if (filePath != null) filePath,
    ];
  }

  /// Build git command for blame
  List<String> buildBlameCommand({
    required String filePath,
    String? commit,
    int? startLine,
    int? endLine,
  }) {
    return [
      'blame',
      '--porcelain',
      if (startLine != null && endLine != null) '-L',
      if (startLine != null && endLine != null) '$startLine,$endLine',
      if (commit != null) commit,
      filePath,
    ];
  }

  /// Build git command for show (commit details)
  List<String> buildShowCommand({
    required String commit,
    bool nameOnly = false,
  }) {
    return [
      'show',
      if (nameOnly) '--name-only',
      '--pretty=format:%H%n%P%n%an%n%ae%n%at%n%cn%n%ce%n%ct%n%s%n%b%n---END---',
      commit,
    ];
  }

  /// Build git command for branch list
  List<String> buildBranchListCommand({bool includeRemote = true}) {
    return [
      'branch',
      if (includeRemote) '-a',
      '-v',
      '--no-abbrev',
    ];
  }

  /// Build git command for remote list
  List<String> buildRemoteListCommand({bool verbose = true}) {
    return [
      'remote',
      if (verbose) '-v',
    ];
  }
}
