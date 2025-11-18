import 'package:test/test.dart';
import 'package:git_integration/src/infrastructure/adapters/git_command_adapter.dart';

void main() {
  group('GitCommandAdapter', () {
    late GitCommandAdapter adapter;

    setUp(() {
      adapter = GitCommandAdapter();
    });

    group('GitCommandResult', () {
      test('should identify successful result', () {
        // Arrange
        final result = GitCommandResult(
          exitCode: 0,
          stdout: 'Success',
          stderr: '',
        );

        // Act & Assert
        expect(result.isSuccess, isTrue);
        expect(result.isError, isFalse);
      });

      test('should identify error result', () {
        // Arrange
        final result = GitCommandResult(
          exitCode: 1,
          stdout: '',
          stderr: 'Error message',
        );

        // Act & Assert
        expect(result.isSuccess, isFalse);
        expect(result.isError, isTrue);
      });

      test('should provide output and error accessors', () {
        // Arrange
        final result = GitCommandResult(
          exitCode: 0,
          stdout: 'Output text',
          stderr: 'Error text',
        );

        // Act & Assert
        expect(result.output, equals('Output text'));
        expect(result.error, equals('Error text'));
      });
    });

    group('buildStatusCommand', () {
      test('should build porcelain status command', () {
        // Act
        final command = adapter.buildStatusCommand(porcelain: true);

        // Assert
        expect(command, contains('status'));
        expect(command, contains('--porcelain=v2'));
        expect(command, contains('--branch'));
      });

      test('should build non-porcelain status command', () {
        // Act
        final command = adapter.buildStatusCommand(porcelain: false);

        // Assert
        expect(command, contains('status'));
        expect(command, isNot(contains('--porcelain=v2')));
        expect(command, contains('--branch'));
      });
    });

    group('buildDiffCommand', () {
      test('should build basic diff command', () {
        // Act
        final command = adapter.buildDiffCommand();

        // Assert
        expect(command, equals(['diff']));
      });

      test('should build staged diff command', () {
        // Act
        final command = adapter.buildDiffCommand(staged: true);

        // Assert
        expect(command, contains('diff'));
        expect(command, contains('--staged'));
      });

      test('should build name-only diff command', () {
        // Act
        final command = adapter.buildDiffCommand(nameOnly: true);

        // Assert
        expect(command, contains('diff'));
        expect(command, contains('--name-only'));
      });

      test('should build diff command with commit range', () {
        // Act
        final command = adapter.buildDiffCommand(
          oldCommit: 'abc123',
          newCommit: 'def456',
        );

        // Assert
        expect(command, contains('diff'));
        expect(command, contains('abc123'));
        expect(command, contains('def456'));
      });

      test('should build diff command for specific file', () {
        // Act
        final command = adapter.buildDiffCommand(
          filePath: 'path/to/file.dart',
        );

        // Assert
        expect(command, contains('diff'));
        expect(command, contains('--'));
        expect(command, contains('path/to/file.dart'));
      });

      test('should build diff command with all options', () {
        // Act
        final command = adapter.buildDiffCommand(
          staged: true,
          nameOnly: true,
          oldCommit: 'abc123',
          newCommit: 'def456',
          filePath: 'file.dart',
        );

        // Assert
        expect(command, contains('diff'));
        expect(command, contains('--staged'));
        expect(command, contains('--name-only'));
        expect(command, contains('abc123'));
        expect(command, contains('def456'));
        expect(command, contains('--'));
        expect(command, contains('file.dart'));
      });
    });

    group('buildLogCommand', () {
      test('should build basic log command', () {
        // Act
        final command = adapter.buildLogCommand();

        // Assert
        expect(command, contains('log'));
        expect(command.any((arg) => arg.startsWith('--pretty=format:')), isTrue);
      });

      test('should build log command for specific branch', () {
        // Act
        final command = adapter.buildLogCommand(branch: 'feature/test');

        // Assert
        expect(command, contains('log'));
        expect(command, contains('feature/test'));
      });

      test('should build log command with max count', () {
        // Act
        final command = adapter.buildLogCommand(maxCount: 10);

        // Assert
        expect(command, contains('log'));
        expect(command, contains('-10'));
      });

      test('should build log command with skip', () {
        // Act
        final command = adapter.buildLogCommand(skip: 5);

        // Assert
        expect(command, contains('log'));
        expect(command, contains('--skip=5'));
      });

      test('should build log command for specific file', () {
        // Act
        final command = adapter.buildLogCommand(filePath: 'path/to/file.dart');

        // Assert
        expect(command, contains('log'));
        expect(command, contains('--'));
        expect(command, contains('path/to/file.dart'));
      });

      test('should build log command without pretty format', () {
        // Act
        final command = adapter.buildLogCommand(pretty: false);

        // Assert
        expect(command, contains('log'));
        expect(command.any((arg) => arg.startsWith('--pretty=')), isFalse);
      });

      test('should build log command with all options', () {
        // Act
        final command = adapter.buildLogCommand(
          branch: 'main',
          maxCount: 20,
          skip: 10,
          filePath: 'file.dart',
        );

        // Assert
        expect(command, contains('log'));
        expect(command, contains('main'));
        expect(command, contains('-20'));
        expect(command, contains('--skip=10'));
        expect(command, contains('--'));
        expect(command, contains('file.dart'));
      });
    });

    group('buildBlameCommand', () {
      test('should build basic blame command', () {
        // Act
        final command = adapter.buildBlameCommand(filePath: 'test.dart');

        // Assert
        expect(command, contains('blame'));
        expect(command, contains('--porcelain'));
        expect(command, contains('test.dart'));
      });

      test('should build blame command for specific commit', () {
        // Act
        final command = adapter.buildBlameCommand(
          filePath: 'test.dart',
          commit: 'abc123',
        );

        // Assert
        expect(command, contains('blame'));
        expect(command, contains('--porcelain'));
        expect(command, contains('abc123'));
        expect(command, contains('test.dart'));
      });

      test('should build blame command for line range', () {
        // Act
        final command = adapter.buildBlameCommand(
          filePath: 'test.dart',
          startLine: 10,
          endLine: 20,
        );

        // Assert
        expect(command, contains('blame'));
        expect(command, contains('--porcelain'));
        expect(command, contains('-L'));
        expect(command, contains('10,20'));
        expect(command, contains('test.dart'));
      });

      test('should build blame command with all options', () {
        // Act
        final command = adapter.buildBlameCommand(
          filePath: 'test.dart',
          commit: 'def456',
          startLine: 5,
          endLine: 15,
        );

        // Assert
        expect(command, contains('blame'));
        expect(command, contains('--porcelain'));
        expect(command, contains('-L'));
        expect(command, contains('5,15'));
        expect(command, contains('def456'));
        expect(command, contains('test.dart'));
      });
    });

    group('buildShowCommand', () {
      test('should build basic show command', () {
        // Act
        final command = adapter.buildShowCommand(commit: 'abc123');

        // Assert
        expect(command, contains('show'));
        expect(command, contains('abc123'));
        expect(command.any((arg) => arg.startsWith('--pretty=format:')), isTrue);
      });

      test('should build show command with name-only', () {
        // Act
        final command = adapter.buildShowCommand(
          commit: 'abc123',
          nameOnly: true,
        );

        // Assert
        expect(command, contains('show'));
        expect(command, contains('--name-only'));
        expect(command, contains('abc123'));
      });
    });

    group('buildBranchListCommand', () {
      test('should build branch list command with remote', () {
        // Act
        final command = adapter.buildBranchListCommand(includeRemote: true);

        // Assert
        expect(command, contains('branch'));
        expect(command, contains('-a'));
        expect(command, contains('-v'));
        expect(command, contains('--no-abbrev'));
      });

      test('should build branch list command without remote', () {
        // Act
        final command = adapter.buildBranchListCommand(includeRemote: false);

        // Assert
        expect(command, contains('branch'));
        expect(command, isNot(contains('-a')));
        expect(command, contains('-v'));
        expect(command, contains('--no-abbrev'));
      });
    });

    group('buildRemoteListCommand', () {
      test('should build remote list command with verbose', () {
        // Act
        final command = adapter.buildRemoteListCommand(verbose: true);

        // Assert
        expect(command, contains('remote'));
        expect(command, contains('-v'));
      });

      test('should build remote list command without verbose', () {
        // Act
        final command = adapter.buildRemoteListCommand(verbose: false);

        // Assert
        expect(command, contains('remote'));
        expect(command, isNot(contains('-v')));
      });
    });

    group('timeout constants', () {
      test('should have default timeout of 30 seconds', () {
        // Assert
        expect(GitCommandAdapter.defaultTimeout.inSeconds, equals(30));
      });

      test('should have extended timeout of 5 minutes', () {
        // Assert
        expect(GitCommandAdapter.extendedTimeout.inMinutes, equals(5));
      });
    });

    group('Command Arguments Validation', () {
      test('should not include null values in diff command', () {
        // Act
        final command = adapter.buildDiffCommand(
          staged: false,
          nameOnly: false,
          oldCommit: null,
          newCommit: null,
          filePath: null,
        );

        // Assert
        expect(command, equals(['diff']));
      });

      test('should maintain argument order in log command', () {
        // Act
        final command = adapter.buildLogCommand(
          branch: 'main',
          maxCount: 10,
          skip: 5,
          filePath: 'file.dart',
        );

        // Assert
        final logIndex = command.indexOf('log');
        final branchIndex = command.indexOf('main');
        final maxCountIndex = command.indexOf('-10');
        final skipIndex = command.indexOf('--skip=5');
        final separatorIndex = command.indexOf('--');

        expect(logIndex, lessThan(branchIndex));
        expect(branchIndex, lessThan(maxCountIndex));
        expect(maxCountIndex, lessThan(skipIndex));
        expect(skipIndex, lessThan(separatorIndex));
      });

      test('should properly format blame line range', () {
        // Act
        final command = adapter.buildBlameCommand(
          filePath: 'test.dart',
          startLine: 100,
          endLine: 200,
        );

        // Assert
        expect(command, contains('100,200'));
      });

      test('should only include line range separator when both start and end provided', () {
        // Act - Only startLine
        final commandStart = adapter.buildBlameCommand(
          filePath: 'test.dart',
          startLine: 10,
        );

        // Assert
        expect(commandStart, isNot(contains('-L')));
        expect(commandStart, isNot(contains('10,')));
      });
    });

    group('Edge Cases', () {
      test('should handle empty file path gracefully in diff', () {
        // Act
        final command = adapter.buildDiffCommand(filePath: '');

        // Assert
        expect(command, contains('diff'));
        expect(command, contains('--'));
        expect(command, contains(''));
      });

      test('should handle zero max count in log', () {
        // Act
        final command = adapter.buildLogCommand(maxCount: 0);

        // Assert
        expect(command, contains('log'));
        expect(command, contains('-0'));
      });

      test('should handle zero skip in log', () {
        // Act
        final command = adapter.buildLogCommand(skip: 0);

        // Assert
        expect(command, contains('log'));
        expect(command, contains('--skip=0'));
      });
    });

    group('Pretty Format Strings', () {
      test('should include END marker in log pretty format', () {
        // Act
        final command = adapter.buildLogCommand();

        // Assert
        final prettyArg = command.firstWhere((arg) => arg.startsWith('--pretty=format:'));
        expect(prettyArg, contains('---END---'));
      });

      test('should include all required fields in log pretty format', () {
        // Act
        final command = adapter.buildLogCommand();

        // Assert
        final prettyArg = command.firstWhere((arg) => arg.startsWith('--pretty=format:'));
        expect(prettyArg, contains('%H')); // Hash
        expect(prettyArg, contains('%P')); // Parent
        expect(prettyArg, contains('%an')); // Author name
        expect(prettyArg, contains('%ae')); // Author email
        expect(prettyArg, contains('%at')); // Author timestamp
        expect(prettyArg, contains('%cn')); // Committer name
        expect(prettyArg, contains('%ce')); // Committer email
        expect(prettyArg, contains('%ct')); // Committer timestamp
        expect(prettyArg, contains('%s')); // Subject
        expect(prettyArg, contains('%b')); // Body
      });

      test('should match show and log pretty formats', () {
        // Act
        final logCommand = adapter.buildLogCommand();
        final showCommand = adapter.buildShowCommand(commit: 'abc123');

        // Assert
        final logPretty = logCommand.firstWhere((arg) => arg.startsWith('--pretty=format:'));
        final showPretty = showCommand.firstWhere((arg) => arg.startsWith('--pretty=format:'));
        expect(logPretty, equals(showPretty));
      });
    });

    group('File Path Handling', () {
      test('should handle file path with spaces in diff', () {
        // Act
        final command = adapter.buildDiffCommand(
          filePath: 'path with spaces/file.dart',
        );

        // Assert
        expect(command, contains('path with spaces/file.dart'));
      });

      test('should handle file path with special characters in log', () {
        // Act
        final command = adapter.buildLogCommand(
          filePath: 'path/with-special_chars.123.dart',
        );

        // Assert
        expect(command, contains('path/with-special_chars.123.dart'));
      });

      test('should handle file path with dots in blame', () {
        // Act
        final command = adapter.buildBlameCommand(
          filePath: '../relative/path/file.dart',
        );

        // Assert
        expect(command, contains('../relative/path/file.dart'));
      });
    });

    group('Commit Hash Handling', () {
      test('should handle short commit hashes in diff', () {
        // Act
        final command = adapter.buildDiffCommand(
          oldCommit: 'abc123',
          newCommit: 'def456',
        );

        // Assert
        expect(command, contains('abc123'));
        expect(command, contains('def456'));
      });

      test('should handle full commit hashes in diff', () {
        // Act
        final command = adapter.buildDiffCommand(
          oldCommit: 'abc1234567890abcdef1234567890abcdef123456',
          newCommit: 'def4567890123456789012345678901234567890',
        );

        // Assert
        expect(command, contains('abc1234567890abcdef1234567890abcdef123456'));
        expect(command, contains('def4567890123456789012345678901234567890'));
      });

      test('should handle HEAD references in diff', () {
        // Act
        final command = adapter.buildDiffCommand(
          oldCommit: 'HEAD~1',
          newCommit: 'HEAD',
        );

        // Assert
        expect(command, contains('HEAD~1'));
        expect(command, contains('HEAD'));
      });
    });
  });
}
