import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:fpdart/fpdart.dart' as fp;

// Mock classes
class MockGetDiffUseCase extends Mock implements GetDiffUseCase {}

void main() {
  group('DiffService', () {
    late DiffService service;
    late MockGetDiffUseCase mockGetDiff;
    late RepositoryPath path;
    late List<DiffHunk> sampleHunks;

    setUp(() {
      mockGetDiff = MockGetDiffUseCase();
      service = DiffService(mockGetDiff);
      path = RepositoryPath.create('/test/repo');

      sampleHunks = const [
        DiffHunk(
          oldStart: 1,
          oldCount: 3,
          newStart: 1,
          newCount: 4,
          lines: [
            DiffLine(
              type: DiffLineType.context,
              content: 'line 1',
              oldLineNumber: fp.some(1),
              newLineNumber: fp.some(1),
            ),
            DiffLine(
              type: DiffLineType.removed,
              content: 'old line',
              oldLineNumber: fp.some(2),
              newLineNumber: fp.none(),
            ),
            DiffLine(
              type: DiffLineType.added,
              content: 'new line',
              oldLineNumber: fp.none(),
              newLineNumber: fp.some(2),
            ),
          ],
          header: 'function main()',
        ),
      ];
    });

    group('getDiff', () {
      test('should get diff between two texts', () async {
        // Arrange
        const oldContent = 'old text';
        const newContent = 'new text';

        when(() => mockGetDiff.getDiff(
              oldContent: oldContent,
              newContent: newContent,
              contextLines: 3,
            )).thenAnswer((_) async => right(sampleHunks));

        // Act
        final result = await service.getDiff(
          oldContent: oldContent,
          newContent: newContent,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockGetDiff.getDiff(
              oldContent: oldContent,
              newContent: newContent,
              contextLines: 3,
            )).called(1);
      });

      test('should use cache for repeated diff requests', () async {
        // Arrange
        const oldContent = 'old';
        const newContent = 'new';

        when(() => mockGetDiff.getDiff(
              oldContent: oldContent,
              newContent: newContent,
              contextLines: 3,
            )).thenAnswer((_) async => right(sampleHunks));

        // Act
        await service.getDiff(
          oldContent: oldContent,
          newContent: newContent,
        );
        final result = await service.getDiff(
          oldContent: oldContent,
          newContent: newContent,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockGetDiff.getDiff(
              oldContent: oldContent,
              newContent: newContent,
              contextLines: 3,
            )).called(1); // Only called once due to cache
      });

      test('should bypass cache when useCache is false', () async {
        // Arrange
        const oldContent = 'old';
        const newContent = 'new';

        when(() => mockGetDiff.getDiff(
              oldContent: oldContent,
              newContent: newContent,
              contextLines: 3,
            )).thenAnswer((_) async => right(sampleHunks));

        // Act
        await service.getDiff(
          oldContent: oldContent,
          newContent: newContent,
        );
        final result = await service.getDiff(
          oldContent: oldContent,
          newContent: newContent,
          useCache: false,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockGetDiff.getDiff(
              oldContent: oldContent,
              newContent: newContent,
              contextLines: 3,
            )).called(2); // Called twice
      });

      test('should support custom context lines', () async {
        // Arrange
        const oldContent = 'old';
        const newContent = 'new';

        when(() => mockGetDiff.getDiff(
              oldContent: oldContent,
              newContent: newContent,
              contextLines: 5,
            )).thenAnswer((_) async => right(sampleHunks));

        // Act
        final result = await service.getDiff(
          oldContent: oldContent,
          newContent: newContent,
          contextLines: 5,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockGetDiff.getDiff(
              oldContent: oldContent,
              newContent: newContent,
              contextLines: 5,
            )).called(1);
      });
    });

    group('getDiffBetweenCommits', () {
      test('should get diff between two commits', () async {
        // Arrange
        final fileDiffs = {'file.dart': sampleHunks};

        when(() => mockGetDiff.getDiffBetweenCommits(
              path: path,
              oldCommit: 'abc123',
              newCommit: 'def456',
            )).thenAnswer((_) async => right(fileDiffs));

        // Act
        final result = await service.getDiffBetweenCommits(
          path: path,
          oldCommit: 'abc123',
          newCommit: 'def456',
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockGetDiff.getDiffBetweenCommits(
              path: path,
              oldCommit: 'abc123',
              newCommit: 'def456',
            )).called(1);
      });
    });

    group('getStagedDiff', () {
      test('should get staged diff', () async {
        // Arrange
        final fileDiffs = {'file.dart': sampleHunks};

        when(() => mockGetDiff.getStagedDiff(path: path))
            .thenAnswer((_) async => right(fileDiffs));

        // Act
        final result = await service.getStagedDiff(path: path);

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockGetDiff.getStagedDiff(path: path)).called(1);
      });
    });

    group('getUnstagedDiff', () {
      test('should get unstaged diff', () async {
        // Arrange
        final fileDiffs = {'file.dart': sampleHunks};

        when(() => mockGetDiff.getUnstagedDiff(path: path))
            .thenAnswer((_) async => right(fileDiffs));

        // Act
        final result = await service.getUnstagedDiff(path: path);

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockGetDiff.getUnstagedDiff(path: path)).called(1);
      });
    });

    group('getFileDiff', () {
      test('should get diff for specific file', () async {
        // Arrange
        when(() => mockGetDiff.getFileDiff(
              path: path,
              filePath: 'lib/main.dart',
              staged: false,
            )).thenAnswer((_) async => right(sampleHunks));

        // Act
        final result = await service.getFileDiff(
          path: path,
          filePath: 'lib/main.dart',
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockGetDiff.getFileDiff(
              path: path,
              filePath: 'lib/main.dart',
              staged: false,
            )).called(1);
      });

      test('should get staged diff for file', () async {
        // Arrange
        when(() => mockGetDiff.getFileDiff(
              path: path,
              filePath: 'lib/main.dart',
              staged: true,
            )).thenAnswer((_) async => right(sampleHunks));

        // Act
        final result = await service.getFileDiff(
          path: path,
          filePath: 'lib/main.dart',
          staged: true,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockGetDiff.getFileDiff(
              path: path,
              filePath: 'lib/main.dart',
              staged: true,
            )).called(1);
      });
    });

    group('calculateStatistics', () {
      test('should calculate diff statistics correctly', () {
        // Arrange
        final hunks = const [
          DiffHunk(
            oldStart: 1,
            oldCount: 1,
            newStart: 1,
            newCount: 1,
            lines: [
              DiffLine(
                type: DiffLineType.added,
                content: 'added',
                oldLineNumber: fp.none(),
                newLineNumber: fp.some(1),
              ),
              DiffLine(
                type: DiffLineType.added,
                content: 'added2',
                oldLineNumber: fp.none(),
                newLineNumber: fp.some(2),
              ),
              DiffLine(
                type: DiffLineType.removed,
                content: 'removed',
                oldLineNumber: fp.some(1),
                newLineNumber: fp.none(),
              ),
              DiffLine(
                type: DiffLineType.context,
                content: 'context',
                oldLineNumber: fp.some(2),
                newLineNumber: fp.some(3),
              ),
            ],
            header: '',
          ),
        ];

        // Act
        final stats = service.calculateStatistics(hunks);

        // Assert
        expect(stats.additions, equals(2));
        expect(stats.deletions, equals(1));
        expect(stats.context, equals(1));
        expect(stats.total, equals(4));
        expect(stats.changes, equals(3));
      });

      test('should calculate statistics for multiple hunks', () {
        // Arrange
        final hunks = const [
          DiffHunk(
            oldStart: 1,
            oldCount: 1,
            newStart: 1,
            newCount: 1,
            lines: [
              DiffLine(
                type: DiffLineType.added,
                content: 'added',
                oldLineNumber: fp.none(),
                newLineNumber: fp.some(1),
              ),
            ],
            header: '',
          ),
          DiffHunk(
            oldStart: 10,
            oldCount: 1,
            newStart: 10,
            newCount: 1,
            lines: [
              DiffLine(
                type: DiffLineType.removed,
                content: 'removed',
                oldLineNumber: fp.some(10),
                newLineNumber: fp.none(),
              ),
            ],
            header: '',
          ),
        ];

        // Act
        final stats = service.calculateStatistics(hunks);

        // Assert
        expect(stats.additions, equals(1));
        expect(stats.deletions, equals(1));
        expect(stats.total, equals(2));
      });
    });

    group('calculateFileStatistics', () {
      test('should calculate statistics for multiple files', () {
        // Arrange
        final fileDiffs = {
          'file1.dart': const [
            DiffHunk(
              oldStart: 1,
              oldCount: 1,
              newStart: 1,
              newCount: 1,
              lines: [
                DiffLine(
                  type: DiffLineType.added,
                  content: 'added',
                  oldLineNumber: fp.none(),
                  newLineNumber: fp.some(1),
                ),
              ],
              header: '',
            ),
          ],
          'file2.dart': const [
            DiffHunk(
              oldStart: 1,
              oldCount: 1,
              newStart: 1,
              newCount: 1,
              lines: [
                DiffLine(
                  type: DiffLineType.removed,
                  content: 'removed',
                  oldLineNumber: fp.some(1),
                  newLineNumber: fp.none(),
                ),
              ],
              header: '',
            ),
          ],
        };

        // Act
        final stats = service.calculateFileStatistics(fileDiffs);

        // Assert
        expect(stats.length, equals(2));
        expect(stats['file1.dart']!.additions, equals(1));
        expect(stats['file2.dart']!.deletions, equals(1));
      });
    });

    group('formatUnifiedDiff', () {
      test('should format as unified diff', () {
        // Arrange & Act
        final formatted = service.formatUnifiedDiff(
          filePath: 'lib/main.dart',
          hunks: sampleHunks,
        );

        // Assert
        expect(formatted, contains('--- a/lib/main.dart'));
        expect(formatted, contains('+++ b/lib/main.dart'));
        expect(formatted, contains('function main()'));
      });

      test('should include all diff lines with prefixes', () {
        // Arrange & Act
        final formatted = service.formatUnifiedDiff(
          filePath: 'file.dart',
          hunks: sampleHunks,
        );

        // Assert
        expect(formatted, contains(' line 1')); // Context line
        expect(formatted, contains('-old line')); // Removed line
        expect(formatted, contains('+new line')); // Added line
      });
    });

    group('formatSideBySide', () {
      test('should format as side-by-side view', () {
        // Arrange & Act
        final lines = service.formatSideBySide(hunks: sampleHunks);

        // Assert
        expect(lines.length, greaterThan(0));
        expect(lines.first.isHunkHeader, isTrue);
      });

      test('should include old and new content', () {
        // Arrange & Act
        final lines = service.formatSideBySide(hunks: sampleHunks);

        // Assert
        final contentLines = lines.where((l) => !l.isHunkHeader).toList();
        expect(contentLines, isNotEmpty);
      });
    });

    group('cache management', () {
      test('should clear all cache', () async {
        // Arrange
        const oldContent = 'old';
        const newContent = 'new';

        when(() => mockGetDiff.getDiff(
              oldContent: oldContent,
              newContent: newContent,
              contextLines: 3,
            )).thenAnswer((_) async => right(sampleHunks));

        // Act
        await service.getDiff(oldContent: oldContent, newContent: newContent);
        service.clearCache();
        await service.getDiff(oldContent: oldContent, newContent: newContent);

        // Assert
        verify(() => mockGetDiff.getDiff(
              oldContent: oldContent,
              newContent: newContent,
              contextLines: 3,
            )).called(2); // Called twice due to cache clear
      });

      test('should clear specific cache entry', () async {
        // Arrange
        const oldContent = 'old';
        const newContent = 'new';

        when(() => mockGetDiff.getDiff(
              oldContent: oldContent,
              newContent: newContent,
              contextLines: 3,
            )).thenAnswer((_) async => right(sampleHunks));

        // Act
        await service.getDiff(oldContent: oldContent, newContent: newContent);
        service.clearCacheEntry(oldContent, newContent, 3);
        await service.getDiff(oldContent: oldContent, newContent: newContent);

        // Assert
        verify(() => mockGetDiff.getDiff(
              oldContent: oldContent,
              newContent: newContent,
              contextLines: 3,
            )).called(2);
      });
    });

    group('use cases', () {
      test('should handle typical file diff workflow', () async {
        // Arrange
        when(() => mockGetDiff.getFileDiff(
              path: path,
              filePath: 'lib/main.dart',
              staged: false,
            )).thenAnswer((_) async => right(sampleHunks));

        // Act
        final result = await service.getFileDiff(
          path: path,
          filePath: 'lib/main.dart',
        );

        final stats = result.fold(
          (_) => null,
          (hunks) => service.calculateStatistics(hunks),
        );

        // Assert
        expect(result.isRight(), isTrue);
        expect(stats, isNotNull);
        expect(stats!.changes, greaterThan(0));
      });

      test('should handle commit comparison workflow', () async {
        // Arrange
        final fileDiffs = {
          'file1.dart': sampleHunks,
          'file2.dart': sampleHunks,
        };

        when(() => mockGetDiff.getDiffBetweenCommits(
              path: path,
              oldCommit: 'abc',
              newCommit: 'def',
            )).thenAnswer((_) async => right(fileDiffs));

        // Act
        final result = await service.getDiffBetweenCommits(
          path: path,
          oldCommit: 'abc',
          newCommit: 'def',
        );

        final stats = result.fold(
          (_) => null,
          (diffs) => service.calculateFileStatistics(diffs),
        );

        // Assert
        expect(result.isRight(), isTrue);
        expect(stats, isNotNull);
        expect(stats!.length, equals(2));
      });

      test('should handle review changes workflow', () async {
        // Arrange
        final stagedDiffs = {'staged.dart': sampleHunks};
        final unstagedDiffs = {'unstaged.dart': sampleHunks};

        when(() => mockGetDiff.getStagedDiff(path: path))
            .thenAnswer((_) async => right(stagedDiffs));
        when(() => mockGetDiff.getUnstagedDiff(path: path))
            .thenAnswer((_) async => right(unstagedDiffs));

        // Act
        final stagedResult = await service.getStagedDiff(path: path);
        final unstagedResult = await service.getUnstagedDiff(path: path);

        // Assert
        expect(stagedResult.isRight(), isTrue);
        expect(unstagedResult.isRight(), isTrue);
      });
    });
  });
}
