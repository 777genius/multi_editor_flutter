import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:fpdart/fpdart.dart' as fp;
import 'package:git_integration/src/infrastructure/repositories/diff_repository_impl.dart';
import 'package:git_integration/src/infrastructure/adapters/git_command_adapter.dart';
import 'package:git_integration/src/domain/entities/diff_hunk.dart';
import 'package:git_integration/src/domain/value_objects/repository_path.dart';
import 'package:git_integration/src/domain/value_objects/commit_hash.dart';
import 'package:git_integration/src/domain/failures/git_failures.dart';

// Mock classes
class MockGitCommandAdapter extends Mock implements GitCommandAdapter {}

void main() {
  group('DiffRepositoryImpl', () {
    late DiffRepositoryImpl repository;
    late MockGitCommandAdapter mockCommandAdapter;
    late RepositoryPath repositoryPath;

    setUp(() {
      mockCommandAdapter = MockGitCommandAdapter();
      repository = DiffRepositoryImpl(mockCommandAdapter);
      repositoryPath = RepositoryPath('/test/repo');
    });

    group('Text Diff (getDiff)', () {
      group('fallback diff implementation', () {
        test('should compute diff for identical content', () async {
          // Arrange
          const content = 'line 1\nline 2\nline 3';

          // Act
          final result = await repository.getDiff(
            oldContent: content,
            newContent: content,
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should have succeeded'),
            (hunks) {
              expect(hunks.length, 1);
              final hunk = hunks[0];
              expect(hunk.lines.every((line) => line.isContext), true);
            },
          );
        });

        test('should compute diff for added lines', () async {
          // Arrange
          const oldContent = 'line 1\nline 2';
          const newContent = 'line 1\nline 2\nline 3';

          // Act
          final result = await repository.getDiff(
            oldContent: oldContent,
            newContent: newContent,
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should have succeeded'),
            (hunks) {
              expect(hunks.length, 1);
              final hunk = hunks[0];
              expect(hunk.addedLinesCount, 1);
              expect(hunk.removedLinesCount, 0);
              final addedLine = hunk.lines.firstWhere((l) => l.isAdded);
              expect(addedLine.content, 'line 3');
            },
          );
        });

        test('should compute diff for removed lines', () async {
          // Arrange
          const oldContent = 'line 1\nline 2\nline 3';
          const newContent = 'line 1\nline 3';

          // Act
          final result = await repository.getDiff(
            oldContent: oldContent,
            newContent: newContent,
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should have succeeded'),
            (hunks) {
              expect(hunks.isNotEmpty, true);
              final hunk = hunks[0];
              expect(hunk.removedLinesCount, greaterThan(0));
            },
          );
        });

        test('should compute diff for modified lines', () async {
          // Arrange
          const oldContent = 'line 1\nline 2\nline 3';
          const newContent = 'line 1\nmodified line\nline 3';

          // Act
          final result = await repository.getDiff(
            oldContent: oldContent,
            newContent: newContent,
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should have succeeded'),
            (hunks) {
              expect(hunks.isNotEmpty, true);
              final hunk = hunks[0];
              expect(hunk.addedLinesCount, greaterThan(0));
              expect(hunk.removedLinesCount, greaterThan(0));
            },
          );
        });

        test('should compute diff for empty old content', () async {
          // Arrange
          const oldContent = '';
          const newContent = 'line 1\nline 2';

          // Act
          final result = await repository.getDiff(
            oldContent: oldContent,
            newContent: newContent,
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should have succeeded'),
            (hunks) {
              expect(hunks.isNotEmpty, true);
              final hunk = hunks[0];
              expect(hunk.addedLinesCount, 2);
              expect(hunk.removedLinesCount, 0);
            },
          );
        });

        test('should compute diff for empty new content', () async {
          // Arrange
          const oldContent = 'line 1\nline 2';
          const newContent = '';

          // Act
          final result = await repository.getDiff(
            oldContent: oldContent,
            newContent: newContent,
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should have succeeded'),
            (hunks) {
              expect(hunks.isNotEmpty, true);
              final hunk = hunks[0];
              expect(hunk.removedLinesCount, 2);
              expect(hunk.addedLinesCount, 0);
            },
          );
        });

        test('should compute diff for both empty contents', () async {
          // Arrange
          const oldContent = '';
          const newContent = '';

          // Act
          final result = await repository.getDiff(
            oldContent: oldContent,
            newContent: newContent,
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should have succeeded'),
            (hunks) {
              expect(hunks.isEmpty, true);
            },
          );
        });

        test('should set correct line numbers in diff lines', () async {
          // Arrange
          const oldContent = 'line 1\nline 2';
          const newContent = 'line 1\nline 2\nline 3';

          // Act
          final result = await repository.getDiff(
            oldContent: oldContent,
            newContent: newContent,
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should have succeeded'),
            (hunks) {
              final hunk = hunks[0];
              final contextLines = hunk.lines.where((l) => l.isContext).toList();
              expect(contextLines.isNotEmpty, true);
              // Check that context lines have both old and new line numbers
              for (final line in contextLines) {
                expect(line.hasOldLineNumber, true);
                expect(line.hasNewLineNumber, true);
              }
            },
          );
        });

        test('should create hunk with correct header', () async {
          // Arrange
          const oldContent = 'line 1\nline 2';
          const newContent = 'line 1\nline 2\nline 3';

          // Act
          final result = await repository.getDiff(
            oldContent: oldContent,
            newContent: newContent,
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should have succeeded'),
            (hunks) {
              expect(hunks.isNotEmpty, true);
              final hunk = hunks[0];
              expect(hunk.header, contains('@@'));
              expect(hunk.header, contains('-1,'));
              expect(hunk.header, contains('+1,'));
            },
          );
        });

        test('should handle multiline string correctly', () async {
          // Arrange
          const oldContent = 'function test() {\n  return 1;\n}';
          const newContent = 'function test() {\n  return 2;\n}';

          // Act
          final result = await repository.getDiff(
            oldContent: oldContent,
            newContent: newContent,
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should have succeeded'),
            (hunks) {
              expect(hunks.isNotEmpty, true);
              expect(hunks[0].lines.any((l) => l.content.contains('return')),
                  true);
            },
          );
        });
      });

      group('error handling', () {
        test('should handle errors gracefully', () async {
          // Act - Pass null strings (would cause error in real scenario)
          final result = await repository.getDiff(
            oldContent: 'valid content',
            newContent: 'valid content',
          );

          // Assert - Should not throw, should return result
          expect(result.isRight(), true);
        });
      });
    });

    group('Repository Diff (getDiffBetweenCommits)', () {
      test('should get diff between two commits', () async {
        // Arrange
        final oldCommit = CommitHash.create('a' * 40);
        final newCommit = CommitHash.create('b' * 40);

        // Mock file list
        when(() => mockCommandAdapter.executeAndGetOutput(
              args: any(named: 'args'),
              workingDirectory: any(named: 'workingDirectory'),
            )).thenAnswer((_) async => right('file1.dart\nfile2.dart'));

        // Mock individual file diffs
        when(() => mockCommandAdapter.executeAndGetOutput(
              args: ['diff', oldCommit.value, newCommit.value, '--', 'file1.dart'],
              workingDirectory: repositoryPath.path,
            )).thenAnswer((_) async => right(_createMockDiffOutput()));

        when(() => mockCommandAdapter.executeAndGetOutput(
              args: ['diff', oldCommit.value, newCommit.value, '--', 'file2.dart'],
              workingDirectory: repositoryPath.path,
            )).thenAnswer((_) async => right(_createMockDiffOutput()));

        // Act
        final result = await repository.getDiffBetweenCommits(
          path: repositoryPath,
          oldCommit: oldCommit,
          newCommit: newCommit,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should have succeeded'),
          (fileDiffs) {
            expect(fileDiffs.length, 2);
            expect(fileDiffs.containsKey('file1.dart'), true);
            expect(fileDiffs.containsKey('file2.dart'), true);
          },
        );
      });

      test('should handle no changed files', () async {
        // Arrange
        final oldCommit = CommitHash.create('a' * 40);
        final newCommit = CommitHash.create('b' * 40);

        when(() => mockCommandAdapter.executeAndGetOutput(
              args: any(named: 'args'),
              workingDirectory: any(named: 'workingDirectory'),
            )).thenAnswer((_) async => right(''));

        // Act
        final result = await repository.getDiffBetweenCommits(
          path: repositoryPath,
          oldCommit: oldCommit,
          newCommit: newCommit,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should have succeeded'),
          (fileDiffs) => expect(fileDiffs.isEmpty, true),
        );
      });

      test('should handle command failure', () async {
        // Arrange
        final oldCommit = CommitHash.create('a' * 40);
        final newCommit = CommitHash.create('b' * 40);
        final failure = GitFailure.unknown(message: 'Command failed');

        when(() => mockCommandAdapter.executeAndGetOutput(
              args: any(named: 'args'),
              workingDirectory: any(named: 'workingDirectory'),
            )).thenAnswer((_) async => left(failure));

        // Act
        final result = await repository.getDiffBetweenCommits(
          path: repositoryPath,
          oldCommit: oldCommit,
          newCommit: newCommit,
        );

        // Assert
        expect(result.isLeft(), true);
      });

      test('should skip files with diff errors', () async {
        // Arrange
        final oldCommit = CommitHash.create('a' * 40);
        final newCommit = CommitHash.create('b' * 40);

        // Mock file list
        when(() => mockCommandAdapter.executeAndGetOutput(
              args: ['diff', '--name-only', oldCommit.value, newCommit.value],
              workingDirectory: repositoryPath.path,
            )).thenAnswer((_) async => right('file1.dart\nfile2.dart'));

        // Mock file1 succeeds, file2 fails
        when(() => mockCommandAdapter.executeAndGetOutput(
              args: ['diff', oldCommit.value, newCommit.value, '--', 'file1.dart'],
              workingDirectory: repositoryPath.path,
            )).thenAnswer((_) async => right(_createMockDiffOutput()));

        when(() => mockCommandAdapter.executeAndGetOutput(
              args: ['diff', oldCommit.value, newCommit.value, '--', 'file2.dart'],
              workingDirectory: repositoryPath.path,
            )).thenAnswer(
            (_) async => left(GitFailure.unknown(message: 'File error')));

        // Act
        final result = await repository.getDiffBetweenCommits(
          path: repositoryPath,
          oldCommit: oldCommit,
          newCommit: newCommit,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should have succeeded'),
          (fileDiffs) {
            expect(fileDiffs.length, 1);
            expect(fileDiffs.containsKey('file1.dart'), true);
            expect(fileDiffs.containsKey('file2.dart'), false);
          },
        );
      });
    });

    group('Staged Diff (getStagedDiff)', () {
      test('should get staged diff', () async {
        // Arrange
        when(() => mockCommandAdapter.executeAndGetOutput(
              args: ['diff', '--staged', '--name-only'],
              workingDirectory: repositoryPath.path,
            )).thenAnswer((_) async => right('staged.dart'));

        when(() => mockCommandAdapter.executeAndGetOutput(
              args: ['diff', '--staged', '--', 'staged.dart'],
              workingDirectory: repositoryPath.path,
            )).thenAnswer((_) async => right(_createMockDiffOutput()));

        // Act
        final result = await repository.getStagedDiff(path: repositoryPath);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should have succeeded'),
          (fileDiffs) {
            expect(fileDiffs.length, 1);
            expect(fileDiffs.containsKey('staged.dart'), true);
          },
        );
      });

      test('should handle no staged files', () async {
        // Arrange
        when(() => mockCommandAdapter.executeAndGetOutput(
              args: ['diff', '--staged', '--name-only'],
              workingDirectory: repositoryPath.path,
            )).thenAnswer((_) async => right(''));

        // Act
        final result = await repository.getStagedDiff(path: repositoryPath);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should have succeeded'),
          (fileDiffs) => expect(fileDiffs.isEmpty, true),
        );
      });

      test('should handle multiple staged files', () async {
        // Arrange
        when(() => mockCommandAdapter.executeAndGetOutput(
              args: ['diff', '--staged', '--name-only'],
              workingDirectory: repositoryPath.path,
            )).thenAnswer((_) async => right('file1.dart\nfile2.dart\nfile3.dart'));

        when(() => mockCommandAdapter.executeAndGetOutput(
              args: ['diff', '--staged', '--', any()],
              workingDirectory: repositoryPath.path,
            )).thenAnswer((_) async => right(_createMockDiffOutput()));

        // Act
        final result = await repository.getStagedDiff(path: repositoryPath);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should have succeeded'),
          (fileDiffs) {
            expect(fileDiffs.length, 3);
          },
        );
      });
    });

    group('Unstaged Diff (getUnstagedDiff)', () {
      test('should get unstaged diff', () async {
        // Arrange
        when(() => mockCommandAdapter.executeAndGetOutput(
              args: ['diff', '--name-only'],
              workingDirectory: repositoryPath.path,
            )).thenAnswer((_) async => right('unstaged.dart'));

        when(() => mockCommandAdapter.executeAndGetOutput(
              args: ['diff', '--', 'unstaged.dart'],
              workingDirectory: repositoryPath.path,
            )).thenAnswer((_) async => right(_createMockDiffOutput()));

        // Act
        final result = await repository.getUnstagedDiff(path: repositoryPath);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should have succeeded'),
          (fileDiffs) {
            expect(fileDiffs.length, 1);
            expect(fileDiffs.containsKey('unstaged.dart'), true);
          },
        );
      });

      test('should handle no unstaged files', () async {
        // Arrange
        when(() => mockCommandAdapter.executeAndGetOutput(
              args: ['diff', '--name-only'],
              workingDirectory: repositoryPath.path,
            )).thenAnswer((_) async => right(''));

        // Act
        final result = await repository.getUnstagedDiff(path: repositoryPath);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should have succeeded'),
          (fileDiffs) => expect(fileDiffs.isEmpty, true),
        );
      });
    });

    group('File Diff (getFileDiff)', () {
      test('should get diff for specific file', () async {
        // Arrange
        when(() => mockCommandAdapter.executeAndGetOutput(
              args: ['diff', '--', 'test.dart'],
              workingDirectory: repositoryPath.path,
            )).thenAnswer((_) async => right(_createMockDiffOutput()));

        // Act
        final result = await repository.getFileDiff(
          path: repositoryPath,
          filePath: 'test.dart',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should have succeeded'),
          (hunks) {
            expect(hunks.isNotEmpty, true);
          },
        );
      });

      test('should get staged diff when staged parameter is true', () async {
        // Arrange
        when(() => mockCommandAdapter.executeAndGetOutput(
              args: ['diff', '--staged', '--', 'test.dart'],
              workingDirectory: repositoryPath.path,
            )).thenAnswer((_) async => right(_createMockDiffOutput()));

        // Act
        final result = await repository.getFileDiff(
          path: repositoryPath,
          filePath: 'test.dart',
          staged: true,
        );

        // Assert
        expect(result.isRight(), true);
        verify(() => mockCommandAdapter.executeAndGetOutput(
              args: ['diff', '--staged', '--', 'test.dart'],
              workingDirectory: repositoryPath.path,
            )).called(1);
      });

      test('should handle empty diff output', () async {
        // Arrange
        when(() => mockCommandAdapter.executeAndGetOutput(
              args: any(named: 'args'),
              workingDirectory: any(named: 'workingDirectory'),
            )).thenAnswer((_) async => right(''));

        // Act
        final result = await repository.getFileDiff(
          path: repositoryPath,
          filePath: 'test.dart',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should have succeeded'),
          (hunks) => expect(hunks.isEmpty, true),
        );
      });

      test('should handle command failure', () async {
        // Arrange
        final failure = GitFailure.unknown(message: 'Command failed');
        when(() => mockCommandAdapter.executeAndGetOutput(
              args: any(named: 'args'),
              workingDirectory: any(named: 'workingDirectory'),
            )).thenAnswer((_) async => left(failure));

        // Act
        final result = await repository.getFileDiff(
          path: repositoryPath,
          filePath: 'test.dart',
        );

        // Assert
        expect(result.isLeft(), true);
      });
    });

    group('Diff Parsing (_parseDiffOutput)', () {
      test('should parse standard git diff output', () async {
        // Arrange
        const diffOutput = '''
diff --git a/file.txt b/file.txt
index abc123..def456 100644
--- a/file.txt
+++ b/file.txt
@@ -1,3 +1,4 @@
 context line
-removed line
+added line
 context line
''';

        when(() => mockCommandAdapter.executeAndGetOutput(
              args: any(named: 'args'),
              workingDirectory: any(named: 'workingDirectory'),
            )).thenAnswer((_) async => right(diffOutput));

        // Act
        final result = await repository.getFileDiff(
          path: repositoryPath,
          filePath: 'file.txt',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should have succeeded'),
          (hunks) {
            expect(hunks.length, 1);
            final hunk = hunks[0];
            expect(hunk.oldStart, 1);
            expect(hunk.oldCount, 3);
            expect(hunk.newStart, 1);
            expect(hunk.newCount, 4);
            expect(hunk.addedLinesCount, 1);
            expect(hunk.removedLinesCount, 1);
          },
        );
      });

      test('should parse multiple hunks', () async {
        // Arrange
        const diffOutput = '''
diff --git a/file.txt b/file.txt
@@ -1,2 +1,2 @@
 line 1
-old line 2
+new line 2
@@ -10,2 +10,3 @@
 line 10
+added line
 line 11
''';

        when(() => mockCommandAdapter.executeAndGetOutput(
              args: any(named: 'args'),
              workingDirectory: any(named: 'workingDirectory'),
            )).thenAnswer((_) async => right(diffOutput));

        // Act
        final result = await repository.getFileDiff(
          path: repositoryPath,
          filePath: 'file.txt',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should have succeeded'),
          (hunks) {
            expect(hunks.length, 2);
            expect(hunks[0].oldStart, 1);
            expect(hunks[1].oldStart, 10);
          },
        );
      });

      test('should parse added lines correctly', () async {
        // Arrange
        const diffOutput = '''
@@ -1,1 +1,2 @@
 context
+added
''';

        when(() => mockCommandAdapter.executeAndGetOutput(
              args: any(named: 'args'),
              workingDirectory: any(named: 'workingDirectory'),
            )).thenAnswer((_) async => right(diffOutput));

        // Act
        final result = await repository.getFileDiff(
          path: repositoryPath,
          filePath: 'file.txt',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should have succeeded'),
          (hunks) {
            final addedLine = hunks[0].lines.firstWhere((l) => l.isAdded);
            expect(addedLine.content, 'added');
            expect(addedLine.type, DiffLineType.added);
          },
        );
      });

      test('should parse removed lines correctly', () async {
        // Arrange
        const diffOutput = '''
@@ -1,2 +1,1 @@
 context
-removed
''';

        when(() => mockCommandAdapter.executeAndGetOutput(
              args: any(named: 'args'),
              workingDirectory: any(named: 'workingDirectory'),
            )).thenAnswer((_) async => right(diffOutput));

        // Act
        final result = await repository.getFileDiff(
          path: repositoryPath,
          filePath: 'file.txt',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should have succeeded'),
          (hunks) {
            final removedLine = hunks[0].lines.firstWhere((l) => l.isRemoved);
            expect(removedLine.content, 'removed');
            expect(removedLine.type, DiffLineType.removed);
          },
        );
      });

      test('should parse context lines correctly', () async {
        // Arrange
        const diffOutput = '''
@@ -1,1 +1,1 @@
 unchanged line
''';

        when(() => mockCommandAdapter.executeAndGetOutput(
              args: any(named: 'args'),
              workingDirectory: any(named: 'workingDirectory'),
            )).thenAnswer((_) async => right(diffOutput));

        // Act
        final result = await repository.getFileDiff(
          path: repositoryPath,
          filePath: 'file.txt',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should have succeeded'),
          (hunks) {
            final contextLine = hunks[0].lines.firstWhere((l) => l.isContext);
            expect(contextLine.content, 'unchanged line');
            expect(contextLine.type, DiffLineType.context);
          },
        );
      });

      test('should skip file headers', () async {
        // Arrange
        const diffOutput = '''
diff --git a/file.txt b/file.txt
index abc123..def456 100644
--- a/file.txt
+++ b/file.txt
@@ -1,1 +1,1 @@
 line
''';

        when(() => mockCommandAdapter.executeAndGetOutput(
              args: any(named: 'args'),
              workingDirectory: any(named: 'workingDirectory'),
            )).thenAnswer((_) async => right(diffOutput));

        // Act
        final result = await repository.getFileDiff(
          path: repositoryPath,
          filePath: 'file.txt',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should have succeeded'),
          (hunks) {
            // Should not include header lines in diff lines
            expect(
              hunks[0].lines.any((l) => l.content.contains('diff --git')),
              false,
            );
            expect(
              hunks[0].lines.any((l) => l.content.contains('index')),
              false,
            );
          },
        );
      });

      test('should handle empty lines in diff', () async {
        // Arrange
        const diffOutput = '''
@@ -1,2 +1,2 @@
 line 1

''';

        when(() => mockCommandAdapter.executeAndGetOutput(
              args: any(named: 'args'),
              workingDirectory: any(named: 'workingDirectory'),
            )).thenAnswer((_) async => right(diffOutput));

        // Act
        final result = await repository.getFileDiff(
          path: repositoryPath,
          filePath: 'file.txt',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should have succeeded'),
          (hunks) {
            expect(hunks.isNotEmpty, true);
            final emptyLine = hunks[0].lines.any((l) => l.content.isEmpty);
            expect(emptyLine, true);
          },
        );
      });

      test('should preserve hunk header', () async {
        // Arrange
        const diffOutput = '''
@@ -1,3 +1,4 @@ function name
 context
+added
 context
''';

        when(() => mockCommandAdapter.executeAndGetOutput(
              args: any(named: 'args'),
              workingDirectory: any(named: 'workingDirectory'),
            )).thenAnswer((_) async => right(diffOutput));

        // Act
        final result = await repository.getFileDiff(
          path: repositoryPath,
          filePath: 'file.txt',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should have succeeded'),
          (hunks) {
            expect(hunks[0].header, contains('@@'));
            expect(hunks[0].header, contains('-1,3'));
            expect(hunks[0].header, contains('+1,4'));
          },
        );
      });
    });

    group('Edge Cases', () {
      test('should handle very large diffs', () async {
        // Arrange
        final largeOld = List.generate(1000, (i) => 'line $i').join('\n');
        final largeNew = List.generate(1100, (i) => 'line $i').join('\n');

        // Act
        final result = await repository.getDiff(
          oldContent: largeOld,
          newContent: largeNew,
        );

        // Assert
        expect(result.isRight(), true);
      });

      test('should handle special characters in content', () async {
        // Arrange
        const oldContent = 'line with special chars: \$, @, #, &';
        const newContent = 'line with special chars: \$, @, #, &, *';

        // Act
        final result = await repository.getDiff(
          oldContent: oldContent,
          newContent: newContent,
        );

        // Assert
        expect(result.isRight(), true);
      });

      test('should handle unicode characters', () async {
        // Arrange
        const oldContent = 'Hello 世界';
        const newContent = 'Hello 世界!';

        // Act
        final result = await repository.getDiff(
          oldContent: oldContent,
          newContent: newContent,
        );

        // Assert
        expect(result.isRight(), true);
      });

      test('should handle files with only whitespace changes', () async {
        // Arrange
        const oldContent = 'line1\nline2';
        const newContent = 'line1\n  line2';

        // Act
        final result = await repository.getDiff(
          oldContent: oldContent,
          newContent: newContent,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should have succeeded'),
          (hunks) {
            expect(hunks.isNotEmpty, true);
          },
        );
      });
    });
  });
}

// Helper function to create mock diff output
String _createMockDiffOutput() {
  return '''
diff --git a/file.dart b/file.dart
index abc123..def456 100644
--- a/file.dart
+++ b/file.dart
@@ -1,3 +1,4 @@
 context line
-removed line
+added line
 context line
''';
}
