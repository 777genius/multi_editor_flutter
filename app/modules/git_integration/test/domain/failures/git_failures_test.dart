import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';

void main() {
  group('GitFailure', () {
    group('repositoryNotFound', () {
      test('should create repository not found failure', () {
        // Arrange
        const path = RepositoryPath(path: '/path/to/repo');

        // Act
        const failure = GitFailure.repositoryNotFound(path: path);

        // Assert
        expect(failure.userMessage, contains('not found'));
        expect(failure.userMessage, contains('/path/to/repo'));
        expect(failure.isRecoverable, isFalse);
      });
    });

    group('notARepository', () {
      test('should create not a repository failure', () {
        const path = RepositoryPath(path: '/path/to/folder');

        const failure = GitFailure.notARepository(path: path);

        expect(failure.userMessage, contains('Not a git repository'));
        expect(failure.isRecoverable, isFalse);
      });
    });

    group('fileNotChanged', () {
      test('should create file not changed failure', () {
        const failure = GitFailure.fileNotChanged(filePath: 'lib/main.dart');

        expect(failure.userMessage, contains('no changes'));
        expect(failure.userMessage, contains('lib/main.dart'));
        expect(failure.isRecoverable, isTrue);
      });
    });

    group('fileNotStaged', () {
      test('should create file not staged failure', () {
        const failure = GitFailure.fileNotStaged(filePath: 'lib/feature.dart');

        expect(failure.userMessage, contains('not staged'));
        expect(failure.isRecoverable, isTrue);
      });
    });

    group('nothingToCommit', () {
      test('should create nothing to commit failure', () {
        const failure = GitFailure.nothingToCommit();

        expect(failure.userMessage, contains('Nothing to commit'));
        expect(failure.userMessage, contains('working tree clean'));
        expect(failure.isRecoverable, isTrue);
      });
    });

    group('branchNotFound', () {
      test('should create branch not found failure', () {
        const branch = BranchName(value: 'feature/auth');

        const failure = GitFailure.branchNotFound(branch: branch);

        expect(failure.userMessage, contains('Branch not found'));
        expect(failure.userMessage, contains('feature/auth'));
        expect(failure.isRecoverable, isFalse);
      });
    });

    group('branchAlreadyExists', () {
      test('should create branch already exists failure', () {
        const branch = BranchName(value: 'main');

        const failure = GitFailure.branchAlreadyExists(branch: branch);

        expect(failure.userMessage, contains('already exists'));
        expect(failure.isRecoverable, isTrue);
      });
    });

    group('cannotCheckout', () {
      test('should create cannot checkout failure', () {
        const failure = GitFailure.cannotCheckout(
          reason: 'Uncommitted changes',
        );

        expect(failure.userMessage, contains('Cannot checkout'));
        expect(failure.userMessage, contains('Uncommitted changes'));
        expect(failure.isRecoverable, isTrue);
      });
    });

    group('mergeConflict', () {
      test('should create merge conflict failure', () {
        final conflict = MergeConflict(
          sourceBranch: 'feature/auth',
          targetBranch: 'main',
          conflictedFiles: const [],
          detectedAt: DateTime.now(),
        );

        final failure = GitFailure.mergeConflict(conflict: conflict);

        expect(failure.userMessage, contains('Merge conflict'));
        expect(failure.isRecoverable, isTrue);
      });
    });

    group('remoteNotFound', () {
      test('should create remote not found failure', () {
        const remote = RemoteName(value: 'upstream');

        const failure = GitFailure.remoteNotFound(remote: remote);

        expect(failure.userMessage, contains('Remote not found'));
        expect(failure.userMessage, contains('upstream'));
        expect(failure.isRecoverable, isFalse);
      });
    });

    group('remoteAlreadyExists', () {
      test('should create remote already exists failure', () {
        const remote = RemoteName(value: 'origin');

        const failure = GitFailure.remoteAlreadyExists(remote: remote);

        expect(failure.userMessage, contains('already exists'));
        expect(failure.isRecoverable, isTrue);
      });
    });

    group('networkError', () {
      test('should create network error failure', () {
        const failure = GitFailure.networkError(
          message: 'Connection timeout',
        );

        expect(failure.userMessage, contains('Network error'));
        expect(failure.userMessage, contains('Connection timeout'));
        expect(failure.isRecoverable, isTrue);
      });
    });

    group('authenticationFailed', () {
      test('should create authentication failed failure without reason', () {
        const failure = GitFailure.authenticationFailed(
          url: 'https://github.com/user/repo.git',
        );

        expect(failure.userMessage, contains('Authentication failed'));
        expect(failure.userMessage, contains('github.com'));
        expect(failure.isRecoverable, isTrue);
      });

      test('should create authentication failed failure with reason', () {
        const failure = GitFailure.authenticationFailed(
          url: 'https://github.com/user/repo.git',
          reason: 'Invalid credentials',
        );

        expect(failure.userMessage, contains('Invalid credentials'));
        expect(failure.isRecoverable, isTrue);
      });
    });

    group('permissionDenied', () {
      test('should create permission denied failure', () {
        const failure = GitFailure.permissionDenied(
          path: '/protected/repo',
        );

        expect(failure.userMessage, contains('Permission denied'));
        expect(failure.userMessage, contains('/protected/repo'));
        expect(failure.isRecoverable, isFalse);
      });
    });

    group('commandFailed', () {
      test('should create command failed failure', () {
        const failure = GitFailure.commandFailed(
          command: 'git push',
          exitCode: 128,
          stderr: 'fatal: repository not found',
        );

        expect(failure.userMessage, contains('Git command failed'));
        expect(failure.userMessage, contains('exit 128'));
        expect(failure.userMessage, contains('git push'));
        expect(failure.userMessage, contains('repository not found'));
        expect(failure.isRecoverable, isTrue);
      });
    });

    group('invalidUrl', () {
      test('should create invalid URL failure', () {
        const failure = GitFailure.invalidUrl(
          url: 'not-a-valid-url',
        );

        expect(failure.userMessage, contains('Invalid URL'));
        expect(failure.userMessage, contains('not-a-valid-url'));
        expect(failure.isRecoverable, isTrue);
      });
    });

    group('timeout', () {
      test('should create timeout failure', () {
        const failure = GitFailure.timeout(
          operation: 'fetch',
          duration: Duration(seconds: 30),
        );

        expect(failure.userMessage, contains('timed out'));
        expect(failure.userMessage, contains('fetch'));
        expect(failure.userMessage, contains('30s'));
        expect(failure.isRecoverable, isTrue);
      });
    });

    group('diskFull', () {
      test('should create disk full failure', () {
        const failure = GitFailure.diskFull();

        expect(failure.userMessage, contains('Disk is full'));
        expect(failure.isRecoverable, isFalse);
      });
    });

    group('unknown', () {
      test('should create unknown failure with message', () {
        const failure = GitFailure.unknown(
          message: 'Something went wrong',
        );

        expect(failure.userMessage, contains('Unknown error'));
        expect(failure.userMessage, contains('Something went wrong'));
        expect(failure.isRecoverable, isFalse);
      });

      test('should create unknown failure with error object', () {
        final error = Exception('Original error');
        final failure = GitFailure.unknown(
          message: 'Unexpected error',
          error: error,
        );

        expect(failure.userMessage, contains('Unexpected error'));
        expect(failure.userMessage, contains('Exception'));
      });

      test('should create unknown failure with stack trace', () {
        final stackTrace = StackTrace.current;
        const failure = GitFailure.unknown(
          message: 'Error occurred',
          stackTrace: null,
        );

        expect(failure.userMessage, isNotEmpty);
      });
    });

    group('equality', () {
      test('should be equal with same type and data', () {
        const failure1 = GitFailure.nothingToCommit();
        const failure2 = GitFailure.nothingToCommit();

        expect(failure1, equals(failure2));
      });

      test('should be equal for repository not found with same path', () {
        const path = RepositoryPath(path: '/same/path');

        const failure1 = GitFailure.repositoryNotFound(path: path);
        const failure2 = GitFailure.repositoryNotFound(path: path);

        expect(failure1, equals(failure2));
      });

      test('should not be equal with different types', () {
        const failure1 = GitFailure.nothingToCommit();
        const failure2 = GitFailure.diskFull();

        expect(failure1, isNot(equals(failure2)));
      });

      test('should not be equal with different data', () {
        const failure1 = GitFailure.fileNotChanged(filePath: 'file1.dart');
        const failure2 = GitFailure.fileNotChanged(filePath: 'file2.dart');

        expect(failure1, isNot(equals(failure2)));
      });
    });

    group('pattern matching', () {
      test('should support when pattern matching', () {
        const failure = GitFailure.networkError(message: 'Timeout');

        final result = failure.when(
          repositoryNotFound: (_) => 'repo_not_found',
          notARepository: (_) => 'not_a_repo',
          fileNotChanged: (_) => 'file_not_changed',
          fileNotStaged: (_) => 'file_not_staged',
          nothingToCommit: () => 'nothing_to_commit',
          branchNotFound: (_) => 'branch_not_found',
          branchAlreadyExists: (_) => 'branch_exists',
          cannotCheckout: (_) => 'cannot_checkout',
          mergeConflict: (_) => 'merge_conflict',
          remoteNotFound: (_) => 'remote_not_found',
          remoteAlreadyExists: (_) => 'remote_exists',
          networkError: (_) => 'network_error',
          authenticationFailed: (_, __) => 'auth_failed',
          permissionDenied: (_) => 'permission_denied',
          commandFailed: (_, __, ___) => 'command_failed',
          invalidUrl: (_) => 'invalid_url',
          timeout: (_, __) => 'timeout',
          diskFull: () => 'disk_full',
          unknown: (_, __, ___) => 'unknown',
        );

        expect(result, equals('network_error'));
      });

      test('should support maybeWhen with orElse', () {
        const failure = GitFailure.diskFull();

        final result = failure.maybeWhen(
          diskFull: () => 'handled',
          orElse: () => 'not_handled',
        );

        expect(result, equals('handled'));
      });

      test('should call orElse for unhandled cases', () {
        const failure = GitFailure.timeout(
          operation: 'clone',
          duration: Duration(seconds: 60),
        );

        final result = failure.maybeWhen(
          networkError: (_) => 'network',
          orElse: () => 'other',
        );

        expect(result, equals('other'));
      });
    });

    group('isRecoverable categorization', () {
      test('should mark file-related errors as recoverable', () {
        const failures = [
          GitFailure.fileNotChanged(filePath: 'test.dart'),
          GitFailure.fileNotStaged(filePath: 'test.dart'),
          GitFailure.nothingToCommit(),
        ];

        for (final failure in failures) {
          expect(failure.isRecoverable, isTrue);
        }
      });

      test('should mark not-found errors as non-recoverable', () {
        const failures = [
          GitFailure.repositoryNotFound(path: RepositoryPath(path: '/path')),
          GitFailure.notARepository(path: RepositoryPath(path: '/path')),
          GitFailure.branchNotFound(branch: BranchName(value: 'branch')),
          GitFailure.remoteNotFound(remote: RemoteName(value: 'remote')),
        ];

        for (final failure in failures) {
          expect(failure.isRecoverable, isFalse);
        }
      });

      test('should mark network errors as recoverable', () {
        const failures = [
          GitFailure.networkError(message: 'Error'),
          GitFailure.authenticationFailed(url: 'url'),
          GitFailure.timeout(operation: 'fetch', duration: Duration(seconds: 30)),
        ];

        for (final failure in failures) {
          expect(failure.isRecoverable, isTrue);
        }
      });

      test('should mark system errors as non-recoverable', () {
        const failures = [
          GitFailure.permissionDenied(path: '/path'),
          GitFailure.diskFull(),
          GitFailure.unknown(message: 'error'),
        ];

        for (final failure in failures) {
          expect(failure.isRecoverable, isFalse);
        }
      });
    });

    group('use cases', () {
      test('should represent typical clone failure', () {
        const failure = GitFailure.authenticationFailed(
          url: 'https://github.com/private/repo.git',
          reason: 'Invalid token',
        );

        expect(failure.userMessage, contains('Authentication failed'));
        expect(failure.isRecoverable, isTrue);
      });

      test('should represent merge conflict during pull', () {
        final conflict = MergeConflict(
          sourceBranch: 'origin/main',
          targetBranch: 'main',
          conflictedFiles: const [
            ConflictedFile(
              filePath: 'lib/config.dart',
              theirContent: 'their',
              ourContent: 'our',
              baseContent: 'base',
              markers: [],
              isResolved: false,
            ),
          ],
          detectedAt: DateTime.now(),
        );

        final failure = GitFailure.mergeConflict(conflict: conflict);

        expect(failure.isRecoverable, isTrue);
        expect(failure.userMessage, contains('Merge conflict'));
      });

      test('should represent failed push due to network', () {
        const failure = GitFailure.timeout(
          operation: 'push to origin',
          duration: Duration(seconds: 120),
        );

        expect(failure.isRecoverable, isTrue);
        expect(failure.userMessage, contains('120s'));
      });

      test('should represent invalid repository initialization', () {
        const failure = GitFailure.permissionDenied(
          path: '/root/protected',
        );

        expect(failure.isRecoverable, isFalse);
        expect(failure.userMessage, contains('Permission denied'));
      });
    });
  });
}
