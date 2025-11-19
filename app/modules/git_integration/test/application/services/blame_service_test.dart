import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:git_integration/src/application/services/blame_service.dart';
import 'package:git_integration/src/application/use_cases/get_blame_use_case.dart';
import 'package:git_integration/src/domain/entities/blame_line.dart';
import 'package:git_integration/src/domain/value_objects/repository_path.dart';
import 'package:git_integration/src/domain/value_objects/commit_hash.dart';
import 'package:git_integration/src/domain/value_objects/git_author.dart';
import 'package:git_integration/src/domain/failures/git_failures.dart';

// Mock classes
class MockGetBlameUseCase extends Mock implements GetBlameUseCase {}

void main() {
  group('BlameService', () {
    late BlameService service;
    late MockGetBlameUseCase mockGetBlameUseCase;
    late RepositoryPath repositoryPath;

    setUp(() {
      mockGetBlameUseCase = MockGetBlameUseCase();
      service = BlameService(mockGetBlameUseCase);
      repositoryPath = RepositoryPath('/test/repo');
    });

    setUpAll(() {
      // Register fallback values for mocktail
      registerFallbackValue(repositoryPath);
    });

    // Helper to create test blame lines
    List<BlameLine> createTestBlameLines({
      int count = 3,
      DateTime? timestamp,
    }) {
      final now = timestamp ?? DateTime.now();
      return List.generate(
        count,
        (i) => BlameLine(
          lineNumber: i + 1,
          content: 'Line ${i + 1} content',
          commitHash: CommitHash.create('a' * 40),
          author: const GitAuthor(
            name: 'John Doe',
            email: 'john@example.com',
          ),
          timestamp: now.subtract(Duration(days: i)),
          commitMessage: 'Commit message ${i + 1}',
        ),
      );
    }

    group('Blame Operations', () {
      group('getBlame', () {
        test('should return blame lines from use case when useCache is false',
            () async {
          // Arrange
          final blameLines = createTestBlameLines();
          when(() => mockGetBlameUseCase(
                path: any(named: 'path'),
                filePath: any(named: 'filePath'),
                commit: any(named: 'commit'),
                startLine: any(named: 'startLine'),
                endLine: any(named: 'endLine'),
              )).thenAnswer((_) async => right(blameLines));

          // Act
          final result = await service.getBlame(
            path: repositoryPath,
            filePath: 'test.dart',
            useCache: false,
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should have succeeded'),
            (lines) {
              expect(lines.length, 3);
              expect(lines[0].lineNumber, 1);
              expect(lines[0].content, 'Line 1 content');
            },
          );
          verify(() => mockGetBlameUseCase(
                path: repositoryPath,
                filePath: 'test.dart',
                commit: null,
                startLine: null,
                endLine: null,
              )).called(1);
        });

        test('should return cached blame lines when useCache is true', () async {
          // Arrange
          final blameLines = createTestBlameLines();
          when(() => mockGetBlameUseCase(
                path: any(named: 'path'),
                filePath: any(named: 'filePath'),
                commit: any(named: 'commit'),
                startLine: any(named: 'startLine'),
                endLine: any(named: 'endLine'),
              )).thenAnswer((_) async => right(blameLines));

          // Act - First call populates cache
          await service.getBlame(
            path: repositoryPath,
            filePath: 'test.dart',
            useCache: true,
          );

          // Act - Second call should use cache
          final result = await service.getBlame(
            path: repositoryPath,
            filePath: 'test.dart',
            useCache: true,
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should have succeeded'),
            (lines) => expect(lines.length, 3),
          );
          // Use case should only be called once (cache hit on second call)
          verify(() => mockGetBlameUseCase(
                path: repositoryPath,
                filePath: 'test.dart',
                commit: null,
                startLine: null,
                endLine: null,
              )).called(1);
        });

        test('should cache results with different cache keys for different parameters',
            () async {
          // Arrange
          final blameLines1 = createTestBlameLines(count: 2);
          final blameLines2 = createTestBlameLines(count: 3);

          when(() => mockGetBlameUseCase(
                path: repositoryPath,
                filePath: 'test.dart',
                commit: null,
                startLine: null,
                endLine: null,
              )).thenAnswer((_) async => right(blameLines1));

          when(() => mockGetBlameUseCase(
                path: repositoryPath,
                filePath: 'test.dart',
                commit: null,
                startLine: 1,
                endLine: 5,
              )).thenAnswer((_) async => right(blameLines2));

          // Act
          final result1 = await service.getBlame(
            path: repositoryPath,
            filePath: 'test.dart',
            useCache: true,
          );
          final result2 = await service.getBlame(
            path: repositoryPath,
            filePath: 'test.dart',
            startLine: 1,
            endLine: 5,
            useCache: true,
          );

          // Assert - Both calls should hit use case due to different cache keys
          expect(result1.isRight(), true);
          expect(result2.isRight(), true);
          result1.fold(
            (failure) => fail('Should have succeeded'),
            (lines) => expect(lines.length, 2),
          );
          result2.fold(
            (failure) => fail('Should have succeeded'),
            (lines) => expect(lines.length, 3),
          );
        });

        test('should not cache results when failure occurs', () async {
          // Arrange
          final failure = GitFailure.unknown(message: 'Test error');
          when(() => mockGetBlameUseCase(
                path: any(named: 'path'),
                filePath: any(named: 'filePath'),
                commit: any(named: 'commit'),
                startLine: any(named: 'startLine'),
                endLine: any(named: 'endLine'),
              )).thenAnswer((_) async => left(failure));

          // Act
          final result1 = await service.getBlame(
            path: repositoryPath,
            filePath: 'test.dart',
            useCache: true,
          );
          final result2 = await service.getBlame(
            path: repositoryPath,
            filePath: 'test.dart',
            useCache: true,
          );

          // Assert
          expect(result1.isLeft(), true);
          expect(result2.isLeft(), true);
          // Should be called twice since error shouldn't be cached
          verify(() => mockGetBlameUseCase(
                path: repositoryPath,
                filePath: 'test.dart',
                commit: null,
                startLine: null,
                endLine: null,
              )).called(2);
        });

        test('should pass commit parameter to use case', () async {
          // Arrange
          final blameLines = createTestBlameLines();
          when(() => mockGetBlameUseCase(
                path: any(named: 'path'),
                filePath: any(named: 'filePath'),
                commit: any(named: 'commit'),
                startLine: any(named: 'startLine'),
                endLine: any(named: 'endLine'),
              )).thenAnswer((_) async => right(blameLines));

          // Act
          await service.getBlame(
            path: repositoryPath,
            filePath: 'test.dart',
            commit: 'abc123',
            useCache: false,
          );

          // Assert
          verify(() => mockGetBlameUseCase(
                path: repositoryPath,
                filePath: 'test.dart',
                commit: 'abc123',
                startLine: null,
                endLine: null,
              )).called(1);
        });

        test('should pass line range parameters to use case', () async {
          // Arrange
          final blameLines = createTestBlameLines();
          when(() => mockGetBlameUseCase(
                path: any(named: 'path'),
                filePath: any(named: 'filePath'),
                commit: any(named: 'commit'),
                startLine: any(named: 'startLine'),
                endLine: any(named: 'endLine'),
              )).thenAnswer((_) async => right(blameLines));

          // Act
          await service.getBlame(
            path: repositoryPath,
            filePath: 'test.dart',
            startLine: 10,
            endLine: 20,
            useCache: false,
          );

          // Assert
          verify(() => mockGetBlameUseCase(
                path: repositoryPath,
                filePath: 'test.dart',
                commit: null,
                startLine: 10,
                endLine: 20,
              )).called(1);
        });
      });

      group('getFileBlame', () {
        test('should call getBlame with correct parameters', () async {
          // Arrange
          final blameLines = createTestBlameLines();
          when(() => mockGetBlameUseCase(
                path: any(named: 'path'),
                filePath: any(named: 'filePath'),
                commit: any(named: 'commit'),
                startLine: any(named: 'startLine'),
                endLine: any(named: 'endLine'),
              )).thenAnswer((_) async => right(blameLines));

          // Act
          final result = await service.getFileBlame(
            path: repositoryPath,
            filePath: 'test.dart',
          );

          // Assert
          expect(result.isRight(), true);
          verify(() => mockGetBlameUseCase(
                path: repositoryPath,
                filePath: 'test.dart',
                commit: null,
                startLine: null,
                endLine: null,
              )).called(1);
        });

        test('should respect useCache parameter', () async {
          // Arrange
          final blameLines = createTestBlameLines();
          when(() => mockGetBlameUseCase(
                path: any(named: 'path'),
                filePath: any(named: 'filePath'),
                commit: any(named: 'commit'),
                startLine: any(named: 'startLine'),
                endLine: any(named: 'endLine'),
              )).thenAnswer((_) async => right(blameLines));

          // Act
          await service.getFileBlame(
            path: repositoryPath,
            filePath: 'test.dart',
            useCache: false,
          );
          await service.getFileBlame(
            path: repositoryPath,
            filePath: 'test.dart',
            useCache: false,
          );

          // Assert - Should be called twice with useCache false
          verify(() => mockGetBlameUseCase(
                path: repositoryPath,
                filePath: 'test.dart',
                commit: null,
                startLine: null,
                endLine: null,
              )).called(2);
        });
      });

      group('getLineRangeBlame', () {
        test('should call getBlame with line range parameters', () async {
          // Arrange
          final blameLines = createTestBlameLines();
          when(() => mockGetBlameUseCase(
                path: any(named: 'path'),
                filePath: any(named: 'filePath'),
                commit: any(named: 'commit'),
                startLine: any(named: 'startLine'),
                endLine: any(named: 'endLine'),
              )).thenAnswer((_) async => right(blameLines));

          // Act
          final result = await service.getLineRangeBlame(
            path: repositoryPath,
            filePath: 'test.dart',
            startLine: 5,
            endLine: 15,
          );

          // Assert
          expect(result.isRight(), true);
          verify(() => mockGetBlameUseCase(
                path: repositoryPath,
                filePath: 'test.dart',
                commit: null,
                startLine: 5,
                endLine: 15,
              )).called(1);
        });
      });

      group('getHistoricalBlame', () {
        test('should call getBlame with commit parameter', () async {
          // Arrange
          final blameLines = createTestBlameLines();
          when(() => mockGetBlameUseCase(
                path: any(named: 'path'),
                filePath: any(named: 'filePath'),
                commit: any(named: 'commit'),
                startLine: any(named: 'startLine'),
                endLine: any(named: 'endLine'),
              )).thenAnswer((_) async => right(blameLines));

          // Act
          final result = await service.getHistoricalBlame(
            path: repositoryPath,
            filePath: 'test.dart',
            commit: 'abc123def456',
          );

          // Assert
          expect(result.isRight(), true);
          verify(() => mockGetBlameUseCase(
                path: repositoryPath,
                filePath: 'test.dart',
                commit: 'abc123def456',
                startLine: null,
                endLine: null,
              )).called(1);
        });
      });
    });

    group('Blame Statistics', () {
      group('getBlameSummary', () {
        test('should return summary from use case', () async {
          // Arrange
          final summary = {'John Doe': 10, 'Jane Smith': 5};
          when(() => mockGetBlameUseCase.getBlameSummary(
                path: any(named: 'path'),
                filePath: any(named: 'filePath'),
              )).thenAnswer((_) async => right(summary));

          // Act
          final result = await service.getBlameSummary(
            path: repositoryPath,
            filePath: 'test.dart',
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should have succeeded'),
            (data) {
              expect(data['John Doe'], 10);
              expect(data['Jane Smith'], 5);
            },
          );
        });

        test('should handle empty summary', () async {
          // Arrange
          when(() => mockGetBlameUseCase.getBlameSummary(
                path: any(named: 'path'),
                filePath: any(named: 'filePath'),
              )).thenAnswer((_) async => right({}));

          // Act
          final result = await service.getBlameSummary(
            path: repositoryPath,
            filePath: 'test.dart',
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should have succeeded'),
            (data) => expect(data.isEmpty, true),
          );
        });

        test('should handle failure from use case', () async {
          // Arrange
          final failure = GitFailure.unknown(message: 'Test error');
          when(() => mockGetBlameUseCase.getBlameSummary(
                path: any(named: 'path'),
                filePath: any(named: 'filePath'),
              )).thenAnswer((_) async => left(failure));

          // Act
          final result = await service.getBlameSummary(
            path: repositoryPath,
            filePath: 'test.dart',
          );

          // Assert
          expect(result.isLeft(), true);
        });
      });

      group('getBlameHeatMap', () {
        test('should return heat map from use case', () async {
          // Arrange
          final heatMap = [0, 5, 30, 100, 365];
          when(() => mockGetBlameUseCase.getBlameHeatMap(
                path: any(named: 'path'),
                filePath: any(named: 'filePath'),
              )).thenAnswer((_) async => right(heatMap));

          // Act
          final result = await service.getBlameHeatMap(
            path: repositoryPath,
            filePath: 'test.dart',
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should have succeeded'),
            (data) {
              expect(data.length, 5);
              expect(data[0], 0);
              expect(data[4], 365);
            },
          );
        });

        test('should handle empty heat map', () async {
          // Arrange
          when(() => mockGetBlameUseCase.getBlameHeatMap(
                path: any(named: 'path'),
                filePath: any(named: 'filePath'),
              )).thenAnswer((_) async => right([]));

          // Act
          final result = await service.getBlameHeatMap(
            path: repositoryPath,
            filePath: 'test.dart',
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should have succeeded'),
            (data) => expect(data.isEmpty, true),
          );
        });
      });

      group('getAuthorContribution', () {
        test('should calculate author contribution percentages', () async {
          // Arrange
          final summary = {'John Doe': 60, 'Jane Smith': 40};
          when(() => mockGetBlameUseCase.getBlameSummary(
                path: any(named: 'path'),
                filePath: any(named: 'filePath'),
              )).thenAnswer((_) async => right(summary));

          // Act
          final result = await service.getAuthorContribution(
            path: repositoryPath,
            filePath: 'test.dart',
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should have succeeded'),
            (contribution) {
              expect(contribution['John Doe'], 60.0);
              expect(contribution['Jane Smith'], 40.0);
            },
          );
        });

        test('should handle empty summary and return empty contribution',
            () async {
          // Arrange
          when(() => mockGetBlameUseCase.getBlameSummary(
                path: any(named: 'path'),
                filePath: any(named: 'filePath'),
              )).thenAnswer((_) async => right({}));

          // Act
          final result = await service.getAuthorContribution(
            path: repositoryPath,
            filePath: 'test.dart',
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should have succeeded'),
            (contribution) => expect(contribution.isEmpty, true),
          );
        });

        test('should handle single author', () async {
          // Arrange
          final summary = {'John Doe': 100};
          when(() => mockGetBlameUseCase.getBlameSummary(
                path: any(named: 'path'),
                filePath: any(named: 'filePath'),
              )).thenAnswer((_) async => right(summary));

          // Act
          final result = await service.getAuthorContribution(
            path: repositoryPath,
            filePath: 'test.dart',
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should have succeeded'),
            (contribution) {
              expect(contribution['John Doe'], 100.0);
            },
          );
        });

        test('should calculate correct percentages for multiple authors',
            () async {
          // Arrange
          final summary = {
            'Author A': 25,
            'Author B': 25,
            'Author C': 50,
          };
          when(() => mockGetBlameUseCase.getBlameSummary(
                path: any(named: 'path'),
                filePath: any(named: 'filePath'),
              )).thenAnswer((_) async => right(summary));

          // Act
          final result = await service.getAuthorContribution(
            path: repositoryPath,
            filePath: 'test.dart',
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should have succeeded'),
            (contribution) {
              expect(contribution['Author A'], 25.0);
              expect(contribution['Author B'], 25.0);
              expect(contribution['Author C'], 50.0);
            },
          );
        });
      });
    });

    group('Blame Annotations', () {
      group('getLineAnnotation', () {
        test('should return formatted annotation for line', () async {
          // Arrange
          final now = DateTime.now();
          final blameLines = [
            BlameLine(
              lineNumber: 42,
              content: 'test content',
              commitHash: CommitHash.create('abcdef1' + '0' * 33),
              author: const GitAuthor(
                name: 'John Doe',
                email: 'john@example.com',
              ),
              timestamp: now.subtract(const Duration(hours: 2)),
              commitMessage: 'Test commit',
            ),
          ];

          when(() => mockGetBlameUseCase(
                path: any(named: 'path'),
                filePath: any(named: 'filePath'),
                commit: any(named: 'commit'),
                startLine: any(named: 'startLine'),
                endLine: any(named: 'endLine'),
              )).thenAnswer((_) async => right(blameLines));

          // Act
          final result = await service.getLineAnnotation(
            path: repositoryPath,
            filePath: 'test.dart',
            lineNumber: 42,
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should have succeeded'),
            (annotation) {
              expect(annotation, contains('John Doe'));
              expect(annotation, contains('abcdef1'));
            },
          );
        });

        test('should return default message for empty blame lines', () async {
          // Arrange
          when(() => mockGetBlameUseCase(
                path: any(named: 'path'),
                filePath: any(named: 'filePath'),
                commit: any(named: 'commit'),
                startLine: any(named: 'startLine'),
                endLine: any(named: 'endLine'),
              )).thenAnswer((_) async => right([]));

          // Act
          final result = await service.getLineAnnotation(
            path: repositoryPath,
            filePath: 'test.dart',
            lineNumber: 1,
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should have succeeded'),
            (annotation) => expect(annotation, 'No blame information'),
          );
        });

        test('should handle failure from use case', () async {
          // Arrange
          final failure = GitFailure.unknown(message: 'Test error');
          when(() => mockGetBlameUseCase(
                path: any(named: 'path'),
                filePath: any(named: 'filePath'),
                commit: any(named: 'commit'),
                startLine: any(named: 'startLine'),
                endLine: any(named: 'endLine'),
              )).thenAnswer((_) async => left(failure));

          // Act
          final result = await service.getLineAnnotation(
            path: repositoryPath,
            filePath: 'test.dart',
            lineNumber: 1,
          );

          // Assert
          expect(result.isLeft(), true);
        });
      });

      group('getLineTooltip', () {
        test('should return tooltip with commit details', () async {
          // Arrange
          final now = DateTime.now();
          final blameLines = [
            BlameLine(
              lineNumber: 10,
              content: 'const value = 42;',
              commitHash: CommitHash.create('abc1234' + '0' * 33),
              author: const GitAuthor(
                name: 'Jane Doe',
                email: 'jane@example.com',
              ),
              timestamp: now.subtract(const Duration(days: 5)),
              commitMessage: 'Add constant value\n\nDetailed description',
            ),
          ];

          when(() => mockGetBlameUseCase(
                path: any(named: 'path'),
                filePath: any(named: 'filePath'),
                commit: any(named: 'commit'),
                startLine: any(named: 'startLine'),
                endLine: any(named: 'endLine'),
              )).thenAnswer((_) async => right(blameLines));

          // Act
          final result = await service.getLineTooltip(
            path: repositoryPath,
            filePath: 'test.dart',
            lineNumber: 10,
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should have succeeded'),
            (tooltip) {
              expect(tooltip.author, 'Jane Doe');
              expect(tooltip.commitHash, 'abc1234');
              expect(tooltip.commitMessage, 'Add constant value');
              expect(tooltip.lineContent, 'const value = 42;');
            },
          );
        });

        test('should return default tooltip for empty blame lines', () async {
          // Arrange
          when(() => mockGetBlameUseCase(
                path: any(named: 'path'),
                filePath: any(named: 'filePath'),
                commit: any(named: 'commit'),
                startLine: any(named: 'startLine'),
                endLine: any(named: 'endLine'),
              )).thenAnswer((_) async => right([]));

          // Act
          final result = await service.getLineTooltip(
            path: repositoryPath,
            filePath: 'test.dart',
            lineNumber: 1,
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should have succeeded'),
            (tooltip) {
              expect(tooltip.author, 'Unknown');
              expect(tooltip.commitMessage, 'No blame information');
              expect(tooltip.commitHash, '');
              expect(tooltip.lineContent, '');
            },
          );
        });
      });
    });

    group('Blame Formatting', () {
      group('formatBlameText', () {
        test('should format blame lines as text', () {
          // Arrange
          final now = DateTime.now();
          final blameLines = [
            BlameLine(
              lineNumber: 1,
              content: 'line 1',
              commitHash: CommitHash.create('abc1234' + '0' * 33),
              author: const GitAuthor(
                name: 'John Doe',
                email: 'john@example.com',
              ),
              timestamp: now,
              commitMessage: 'message 1',
            ),
            BlameLine(
              lineNumber: 2,
              content: 'line 2',
              commitHash: CommitHash.create('def5678' + '0' * 33),
              author: const GitAuthor(
                name: 'Jane Smith',
                email: 'jane@example.com',
              ),
              timestamp: now,
              commitMessage: 'message 2',
            ),
          ];

          // Act
          final formatted = service.formatBlameText(blameLines);

          // Assert
          expect(formatted, contains('abc1234'));
          expect(formatted, contains('def5678'));
          expect(formatted, contains('John Doe'));
          expect(formatted, contains('Jane Smith'));
          expect(formatted, contains('line 1'));
          expect(formatted, contains('line 2'));
        });

        test('should handle empty blame lines', () {
          // Arrange & Act
          final formatted = service.formatBlameText([]);

          // Assert
          expect(formatted, isEmpty);
        });

        test('should format with proper padding', () {
          // Arrange
          final now = DateTime.now();
          final blameLines = [
            BlameLine(
              lineNumber: 1,
              content: 'test',
              commitHash: CommitHash.create('a' * 40),
              author: const GitAuthor(
                name: 'A',
                email: 'a@test.com',
              ),
              timestamp: now,
              commitMessage: 'msg',
            ),
          ];

          // Act
          final formatted = service.formatBlameText(blameLines);

          // Assert
          expect(formatted, contains('   1)'));
        });
      });

      group('groupByCommit', () {
        test('should group blame lines by commit hash', () {
          // Arrange
          final now = DateTime.now();
          final hash1 = CommitHash.create('a' * 40);
          final hash2 = CommitHash.create('b' * 40);

          final blameLines = [
            BlameLine(
              lineNumber: 1,
              content: 'line 1',
              commitHash: hash1,
              author: const GitAuthor(name: 'John', email: 'john@test.com'),
              timestamp: now,
              commitMessage: 'msg 1',
            ),
            BlameLine(
              lineNumber: 2,
              content: 'line 2',
              commitHash: hash2,
              author: const GitAuthor(name: 'Jane', email: 'jane@test.com'),
              timestamp: now,
              commitMessage: 'msg 2',
            ),
            BlameLine(
              lineNumber: 3,
              content: 'line 3',
              commitHash: hash1,
              author: const GitAuthor(name: 'John', email: 'john@test.com'),
              timestamp: now,
              commitMessage: 'msg 1',
            ),
          ];

          // Act
          final groups = service.groupByCommit(blameLines);

          // Assert
          expect(groups.length, 2);
          expect(groups[hash1.value]?.length, 2);
          expect(groups[hash2.value]?.length, 1);
        });

        test('should handle empty blame lines', () {
          // Arrange & Act
          final groups = service.groupByCommit([]);

          // Assert
          expect(groups.isEmpty, true);
        });

        test('should handle single commit', () {
          // Arrange
          final now = DateTime.now();
          final hash = CommitHash.create('a' * 40);

          final blameLines = [
            BlameLine(
              lineNumber: 1,
              content: 'line 1',
              commitHash: hash,
              author: const GitAuthor(name: 'John', email: 'john@test.com'),
              timestamp: now,
              commitMessage: 'msg',
            ),
            BlameLine(
              lineNumber: 2,
              content: 'line 2',
              commitHash: hash,
              author: const GitAuthor(name: 'John', email: 'john@test.com'),
              timestamp: now,
              commitMessage: 'msg',
            ),
          ];

          // Act
          final groups = service.groupByCommit(blameLines);

          // Assert
          expect(groups.length, 1);
          expect(groups[hash.value]?.length, 2);
        });
      });

      group('groupByAuthor', () {
        test('should group blame lines by author name', () {
          // Arrange
          final now = DateTime.now();
          final blameLines = [
            BlameLine(
              lineNumber: 1,
              content: 'line 1',
              commitHash: CommitHash.create('a' * 40),
              author: const GitAuthor(name: 'John Doe', email: 'john@test.com'),
              timestamp: now,
              commitMessage: 'msg 1',
            ),
            BlameLine(
              lineNumber: 2,
              content: 'line 2',
              commitHash: CommitHash.create('b' * 40),
              author:
                  const GitAuthor(name: 'Jane Smith', email: 'jane@test.com'),
              timestamp: now,
              commitMessage: 'msg 2',
            ),
            BlameLine(
              lineNumber: 3,
              content: 'line 3',
              commitHash: CommitHash.create('c' * 40),
              author: const GitAuthor(name: 'John Doe', email: 'john@test.com'),
              timestamp: now,
              commitMessage: 'msg 3',
            ),
          ];

          // Act
          final groups = service.groupByAuthor(blameLines);

          // Assert
          expect(groups.length, 2);
          expect(groups['John Doe']?.length, 2);
          expect(groups['Jane Smith']?.length, 1);
        });

        test('should handle empty blame lines', () {
          // Arrange & Act
          final groups = service.groupByAuthor([]);

          // Assert
          expect(groups.isEmpty, true);
        });
      });
    });

    group('Cache Management', () {
      test('clearCache should clear all cached blame data', () async {
        // Arrange
        final blameLines = createTestBlameLines();
        when(() => mockGetBlameUseCase(
              path: any(named: 'path'),
              filePath: any(named: 'filePath'),
              commit: any(named: 'commit'),
              startLine: any(named: 'startLine'),
              endLine: any(named: 'endLine'),
            )).thenAnswer((_) async => right(blameLines));

        // Populate cache
        await service.getBlame(
          path: repositoryPath,
          filePath: 'test.dart',
          useCache: true,
        );

        // Act
        service.clearCache();

        // Retrieve again - should call use case since cache is cleared
        await service.getBlame(
          path: repositoryPath,
          filePath: 'test.dart',
          useCache: true,
        );

        // Assert - Should be called twice (once before clear, once after)
        verify(() => mockGetBlameUseCase(
              path: repositoryPath,
              filePath: 'test.dart',
              commit: null,
              startLine: null,
              endLine: null,
            )).called(2);
      });

      test('clearFileCache should clear cache for specific file', () async {
        // Arrange
        final blameLines = createTestBlameLines();
        when(() => mockGetBlameUseCase(
              path: any(named: 'path'),
              filePath: any(named: 'filePath'),
              commit: any(named: 'commit'),
              startLine: any(named: 'startLine'),
              endLine: any(named: 'endLine'),
            )).thenAnswer((_) async => right(blameLines));

        // Populate cache for multiple files
        await service.getBlame(
          path: repositoryPath,
          filePath: 'test1.dart',
          useCache: true,
        );
        await service.getBlame(
          path: repositoryPath,
          filePath: 'test2.dart',
          useCache: true,
        );

        // Act - Clear cache for test1.dart
        service.clearFileCache('test1.dart');

        // Get test1.dart again - should call use case
        await service.getBlame(
          path: repositoryPath,
          filePath: 'test1.dart',
          useCache: true,
        );

        // Get test2.dart again - should use cache
        await service.getBlame(
          path: repositoryPath,
          filePath: 'test2.dart',
          useCache: true,
        );

        // Assert
        verify(() => mockGetBlameUseCase(
              path: repositoryPath,
              filePath: 'test1.dart',
              commit: null,
              startLine: null,
              endLine: null,
            )).called(2); // Called twice for test1.dart
        verify(() => mockGetBlameUseCase(
              path: repositoryPath,
              filePath: 'test2.dart',
              commit: null,
              startLine: null,
              endLine: null,
            )).called(1); // Called once for test2.dart
      });

      test('invalidateFileCache should clear cache for file', () async {
        // Arrange
        final blameLines = createTestBlameLines();
        when(() => mockGetBlameUseCase(
              path: any(named: 'path'),
              filePath: any(named: 'filePath'),
              commit: any(named: 'commit'),
              startLine: any(named: 'startLine'),
              endLine: any(named: 'endLine'),
            )).thenAnswer((_) async => right(blameLines));

        await service.getBlame(
          path: repositoryPath,
          filePath: 'test.dart',
          useCache: true,
        );

        // Act
        service.invalidateFileCache('test.dart');

        await service.getBlame(
          path: repositoryPath,
          filePath: 'test.dart',
          useCache: true,
        );

        // Assert - Should be called twice
        verify(() => mockGetBlameUseCase(
              path: repositoryPath,
              filePath: 'test.dart',
              commit: null,
              startLine: null,
              endLine: null,
            )).called(2);
      });
    });

    group('BlameTooltip', () {
      group('formattedDate', () {
        test('should return "just now" for current time', () {
          // Arrange
          final tooltip = BlameTooltip(
            author: 'John Doe',
            date: DateTime.now(),
            commitHash: 'abc123',
            commitMessage: 'Test',
            lineContent: 'test',
          );

          // Act
          final formatted = tooltip.formattedDate;

          // Assert
          expect(formatted, 'just now');
        });

        test('should return minutes ago', () {
          // Arrange
          final date = DateTime.now().subtract(const Duration(minutes: 30));
          final tooltip = BlameTooltip(
            author: 'John Doe',
            date: date,
            commitHash: 'abc123',
            commitMessage: 'Test',
            lineContent: 'test',
          );

          // Act
          final formatted = tooltip.formattedDate;

          // Assert
          expect(formatted, contains('minute'));
          expect(formatted, contains('ago'));
        });

        test('should return hours ago', () {
          // Arrange
          final date = DateTime.now().subtract(const Duration(hours: 5));
          final tooltip = BlameTooltip(
            author: 'John Doe',
            date: date,
            commitHash: 'abc123',
            commitMessage: 'Test',
            lineContent: 'test',
          );

          // Act
          final formatted = tooltip.formattedDate;

          // Assert
          expect(formatted, contains('hour'));
          expect(formatted, contains('ago'));
        });

        test('should return days ago', () {
          // Arrange
          final date = DateTime.now().subtract(const Duration(days: 10));
          final tooltip = BlameTooltip(
            author: 'John Doe',
            date: date,
            commitHash: 'abc123',
            commitMessage: 'Test',
            lineContent: 'test',
          );

          // Act
          final formatted = tooltip.formattedDate;

          // Assert
          expect(formatted, contains('day'));
          expect(formatted, contains('ago'));
        });

        test('should return months ago', () {
          // Arrange
          final date = DateTime.now().subtract(const Duration(days: 60));
          final tooltip = BlameTooltip(
            author: 'John Doe',
            date: date,
            commitHash: 'abc123',
            commitMessage: 'Test',
            lineContent: 'test',
          );

          // Act
          final formatted = tooltip.formattedDate;

          // Assert
          expect(formatted, contains('month'));
          expect(formatted, contains('ago'));
        });

        test('should return years ago', () {
          // Arrange
          final date = DateTime.now().subtract(const Duration(days: 400));
          final tooltip = BlameTooltip(
            author: 'John Doe',
            date: date,
            commitHash: 'abc123',
            commitMessage: 'Test',
            lineContent: 'test',
          );

          // Act
          final formatted = tooltip.formattedDate;

          // Assert
          expect(formatted, contains('year'));
          expect(formatted, contains('ago'));
        });

        test('should handle plural correctly', () {
          // Arrange - Single hour
          final tooltip1 = BlameTooltip(
            author: 'John Doe',
            date: DateTime.now().subtract(const Duration(hours: 1)),
            commitHash: 'abc123',
            commitMessage: 'Test',
            lineContent: 'test',
          );

          // Arrange - Multiple hours
          final tooltip2 = BlameTooltip(
            author: 'John Doe',
            date: DateTime.now().subtract(const Duration(hours: 3)),
            commitHash: 'abc123',
            commitMessage: 'Test',
            lineContent: 'test',
          );

          // Act
          final formatted1 = tooltip1.formattedDate;
          final formatted2 = tooltip2.formattedDate;

          // Assert
          expect(formatted1, contains('hour ago'));
          expect(formatted2, contains('hours ago'));
        });
      });
    });
  });
}
