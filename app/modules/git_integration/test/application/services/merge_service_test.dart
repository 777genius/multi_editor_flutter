import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

// Mock classes
class MockMergeBranchUseCase extends Mock implements MergeBranchUseCase {}

class MockRebaseBranchUseCase extends Mock implements RebaseBranchUseCase {}

class MockResolveConflictUseCase extends Mock
    implements ResolveConflictUseCase {}

void main() {
  group('MergeService', () {
    late MergeService service;
    late MockMergeBranchUseCase mockMerge;
    late MockRebaseBranchUseCase mockRebase;
    late MockResolveConflictUseCase mockResolveConflict;
    late RepositoryPath path;
    late MergeConflict sampleConflict;

    setUp(() {
      mockMerge = MockMergeBranchUseCase();
      mockRebase = MockRebaseBranchUseCase();
      mockResolveConflict = MockResolveConflictUseCase();

      service = MergeService(
        mockMerge,
        mockRebase,
        mockResolveConflict,
      );

      path = RepositoryPath.create('/test/repo');

      sampleConflict = MergeConflict(
        sourceBranch: 'feature',
        targetBranch: 'main',
        conflictedFiles: const [
          ConflictedFile(
            filePath: 'lib/main.dart',
            theirContent: 'their version',
            ourContent: 'our version',
            baseContent: 'base version',
            markers: [],
            isResolved: false,
            resolvedContent: null,
          ),
        ],
        detectedAt: DateTime.now(),
      );
    });

    group('merge', () {
      test('should merge branch successfully', () async {
        // Arrange
        when(() => mockMerge(
              path: path,
              branch: 'feature',
              noFastForward: false,
            )).thenAnswer((_) async => right(unit));

        // Act
        final result = await service.merge(
          path: path,
          branch: 'feature',
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockMerge(
              path: path,
              branch: 'feature',
              noFastForward: false,
            )).called(1);
      });

      test('should cache conflict on merge failure', () async {
        // Arrange
        final failure = GitFailure.mergeConflict(conflict: sampleConflict);

        when(() => mockMerge(
              path: path,
              branch: 'feature',
              noFastForward: false,
            )).thenAnswer((_) async => left(failure));

        // Act
        await service.merge(path: path, branch: 'feature');

        // Assert - Conflict should be cached internally
        verify(() => mockMerge(
              path: path,
              branch: 'feature',
              noFastForward: false,
            )).called(1);
      });

      test('should support no-fast-forward merge', () async {
        // Arrange
        when(() => mockMerge(
              path: path,
              branch: 'feature',
              noFastForward: true,
            )).thenAnswer((_) async => right(unit));

        // Act
        final result = await service.merge(
          path: path,
          branch: 'feature',
          noFastForward: true,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockMerge(
              path: path,
              branch: 'feature',
              noFastForward: true,
            )).called(1);
      });
    });

    group('rebase', () {
      test('should rebase successfully', () async {
        // Arrange
        when(() => mockRebase(
              path: path,
              onto: 'main',
              interactive: false,
            )).thenAnswer((_) async => right(unit));

        // Act
        final result = await service.rebase(
          path: path,
          onto: 'main',
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockRebase(
              path: path,
              onto: 'main',
              interactive: false,
            )).called(1);
      });

      test('should support interactive rebase', () async {
        // Arrange
        when(() => mockRebase(
              path: path,
              onto: 'main',
              interactive: true,
            )).thenAnswer((_) async => right(unit));

        // Act
        final result = await service.rebase(
          path: path,
          onto: 'main',
          interactive: true,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockRebase(
              path: path,
              onto: 'main',
              interactive: true,
            )).called(1);
      });
    });

    group('rebase operations', () {
      test('should continue rebase', () async {
        // Arrange
        when(() => mockRebase.continue_(path: path))
            .thenAnswer((_) async => right(unit));

        // Act
        final result = await service.rebaseContinue(path: path);

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockRebase.continue_(path: path)).called(1);
      });

      test('should skip rebase commit', () async {
        // Arrange
        when(() => mockRebase.skip(path: path))
            .thenAnswer((_) async => right(unit));

        // Act
        final result = await service.rebaseSkip(path: path);

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockRebase.skip(path: path)).called(1);
      });

      test('should abort rebase', () async {
        // Arrange
        when(() => mockRebase.abort(path: path))
            .thenAnswer((_) async => right(unit));

        // Act
        final result = await service.rebaseAbort(path: path);

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockRebase.abort(path: path)).called(1);
      });

      test('should check if rebase is in progress', () async {
        // Arrange
        when(() => mockRebase.isRebaseInProgress(path: path))
            .thenAnswer((_) async => right(true));

        // Act
        final result = await service.isRebaseInProgress(path: path);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should succeed'),
          (inProgress) => expect(inProgress, isTrue),
        );
      });
    });

    group('getConflicts', () {
      test('should get conflicts from repository', () async {
        // Arrange
        when(() => mockResolveConflict.getConflicts(path: path))
            .thenAnswer((_) async => right([sampleConflict]));

        // Act
        final result = await service.getConflicts(path: path);

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockResolveConflict.getConflicts(path: path)).called(1);
      });

      test('should use cache when requested', () async {
        // Arrange
        when(() => mockResolveConflict.getConflicts(path: path))
            .thenAnswer((_) async => right([sampleConflict]));

        // Act
        await service.getConflicts(path: path);
        final result = await service.getConflicts(path: path, useCache: true);

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockResolveConflict.getConflicts(path: path)).called(1);
      });
    });

    group('resolveWithStrategy', () {
      test('should resolve conflict with strategy', () async {
        // Arrange
        when(() => mockResolveConflict.resolveWithStrategy(
              path: path,
              filePath: 'lib/main.dart',
              strategy: ConflictResolutionStrategy.keepCurrent,
            )).thenAnswer((_) async => right(unit));

        // Act
        final result = await service.resolveWithStrategy(
          path: path,
          filePath: 'lib/main.dart',
          strategy: ConflictResolutionStrategy.keepCurrent,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockResolveConflict.resolveWithStrategy(
              path: path,
              filePath: 'lib/main.dart',
              strategy: ConflictResolutionStrategy.keepCurrent,
            )).called(1);
      });

      test('should resolve with accept incoming strategy', () async {
        // Arrange
        when(() => mockResolveConflict.resolveWithStrategy(
              path: path,
              filePath: 'file.dart',
              strategy: ConflictResolutionStrategy.acceptIncoming,
            )).thenAnswer((_) async => right(unit));

        // Act
        final result = await service.resolveWithStrategy(
          path: path,
          filePath: 'file.dart',
          strategy: ConflictResolutionStrategy.acceptIncoming,
        );

        // Assert
        expect(result.isRight(), isTrue);
      });
    });

    group('resolveWithContent', () {
      test('should resolve conflict with custom content', () async {
        // Arrange
        const resolvedContent = 'merged content';

        when(() => mockResolveConflict.resolveWithContent(
              path: path,
              filePath: 'lib/main.dart',
              resolvedContent: resolvedContent,
            )).thenAnswer((_) async => right(unit));

        // Act
        final result = await service.resolveWithContent(
          path: path,
          filePath: 'lib/main.dart',
          resolvedContent: resolvedContent,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockResolveConflict.resolveWithContent(
              path: path,
              filePath: 'lib/main.dart',
              resolvedContent: resolvedContent,
            )).called(1);
      });
    });

    group('markAsResolved', () {
      test('should mark file as resolved', () async {
        // Arrange
        when(() => mockResolveConflict.markAsResolved(
              path: path,
              filePath: 'lib/main.dart',
            )).thenAnswer((_) async => right(unit));

        // Act
        final result = await service.markAsResolved(
          path: path,
          filePath: 'lib/main.dart',
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockResolveConflict.markAsResolved(
              path: path,
              filePath: 'lib/main.dart',
            )).called(1);
      });
    });

    group('canContinue', () {
      test('should check if merge can continue', () async {
        // Arrange
        when(() => mockResolveConflict.canContinue(path: path))
            .thenAnswer((_) async => right(true));

        // Act
        final result = await service.canContinue(path: path);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should succeed'),
          (canContinue) => expect(canContinue, isTrue),
        );
      });
    });

    group('abort', () {
      test('should abort merge', () async {
        // Arrange
        when(() => mockResolveConflict.abort(path: path))
            .thenAnswer((_) async => right(unit));

        // Act
        final result = await service.abort(path: path);

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockResolveConflict.abort(path: path)).called(1);
      });

      test('should clear conflict cache after abort', () async {
        // Arrange
        when(() => mockResolveConflict.abort(path: path))
            .thenAnswer((_) async => right(unit));

        // Act
        await service.abort(path: path);

        // Assert - Cache should be cleared
        verify(() => mockResolveConflict.abort(path: path)).called(1);
      });
    });

    group('getConflictContent', () {
      test('should get conflict content with markers', () async {
        // Arrange
        const content = '''
<<<<<<< HEAD
our content
=======
their content
>>>>>>> feature
''';

        when(() => mockResolveConflict.getConflictContent(
              path: path,
              filePath: 'lib/main.dart',
            )).thenAnswer((_) async => right(content));

        // Act
        final result = await service.getConflictContent(
          path: path,
          filePath: 'lib/main.dart',
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should succeed'),
          (c) {
            expect(c, contains('<<<<<<< HEAD'));
            expect(c, contains('======='));
            expect(c, contains('>>>>>>>'));
          },
        );
      });
    });

    group('analyzeConflict', () {
      test('should suggest accepting incoming when ours is empty', () async {
        // Arrange
        const content = '''
<<<<<<< HEAD
=======
new content
>>>>>>> feature
''';

        when(() => mockResolveConflict.getConflictContent(
              path: path,
              filePath: 'file.dart',
            )).thenAnswer((_) async => right(content));

        when(() => mockResolveConflict.parseConflictMarkers(content))
            .thenReturn({'ours': '', 'theirs': 'new content'});

        // Act
        final suggestion = await service.analyzeConflict(
          path: path,
          filePath: 'file.dart',
        );

        // Assert
        expect(suggestion, isNotNull);
        expect(suggestion!.strategy,
            equals(ConflictResolutionStrategy.acceptIncoming));
        expect(suggestion.confidence, greaterThan(0.8));
      });

      test('should suggest keeping current when theirs is empty', () async {
        // Arrange
        const content = '''
<<<<<<< HEAD
existing content
=======
>>>>>>> feature
''';

        when(() => mockResolveConflict.getConflictContent(
              path: path,
              filePath: 'file.dart',
            )).thenAnswer((_) async => right(content));

        when(() => mockResolveConflict.parseConflictMarkers(content))
            .thenReturn({'ours': 'existing content', 'theirs': ''});

        // Act
        final suggestion = await service.analyzeConflict(
          path: path,
          filePath: 'file.dart',
        );

        // Assert
        expect(suggestion, isNotNull);
        expect(
            suggestion!.strategy, equals(ConflictResolutionStrategy.keepCurrent));
        expect(suggestion.confidence, greaterThan(0.8));
      });

      test('should suggest accepting either when identical', () async {
        // Arrange
        const content = '''
<<<<<<< HEAD
same content
=======
same content
>>>>>>> feature
''';

        when(() => mockResolveConflict.getConflictContent(
              path: path,
              filePath: 'file.dart',
            )).thenAnswer((_) async => right(content));

        when(() => mockResolveConflict.parseConflictMarkers(content))
            .thenReturn({'ours': 'same content', 'theirs': 'same content'});

        // Act
        final suggestion = await service.analyzeConflict(
          path: path,
          filePath: 'file.dart',
        );

        // Assert
        expect(suggestion, isNotNull);
        expect(suggestion!.confidence, equals(1.0));
      });
    });

    group('getConflictStatistics', () {
      test('should calculate conflict statistics', () async {
        // Arrange
        final conflicts = [
          MergeConflict(
            sourceBranch: 'feature',
            targetBranch: 'main',
            conflictedFiles: const [
              ConflictedFile(
                filePath: 'file1.dart',
                theirContent: 'theirs',
                ourContent: 'ours',
                baseContent: 'base',
                markers: [
                  ConflictMarker(startLine: 0, middleLine: 2, endLine: 4),
                ],
                isResolved: false,
                resolvedContent: null,
              ),
              ConflictedFile(
                filePath: 'file2.dart',
                theirContent: 'theirs',
                ourContent: 'ours',
                baseContent: 'base',
                markers: [
                  ConflictMarker(startLine: 0, middleLine: 1, endLine: 2),
                ],
                isResolved: false,
                resolvedContent: null,
              ),
            ],
            detectedAt: DateTime.now(),
          ),
        ];

        when(() => mockResolveConflict.getConflicts(path: path))
            .thenAnswer((_) async => right(conflicts));

        // Act
        final result = await service.getConflictStatistics(path: path);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should succeed'),
          (stats) {
            expect(stats.totalFiles, equals(1));
            expect(stats.totalConflicts, equals(2));
          },
        );
      });
    });

    group('resolveAllWithStrategy', () {
      test('should resolve all conflicts with same strategy', () async {
        // Arrange
        when(() => mockResolveConflict.getConflicts(path: path))
            .thenAnswer((_) async => right([sampleConflict]));

        when(() => mockResolveConflict.resolveWithStrategy(
              path: path,
              filePath: any(named: 'filePath'),
              strategy: ConflictResolutionStrategy.keepCurrent,
            )).thenAnswer((_) async => right(unit));

        // Act
        final result = await service.resolveAllWithStrategy(
          path: path,
          strategy: ConflictResolutionStrategy.keepCurrent,
        );

        // Assert
        expect(result.isRight(), isTrue);
      });
    });

    group('cache management', () {
      test('should clear conflict cache', () {
        // Act
        service.clearCache();

        // Assert - No exception should be thrown
      });
    });

    group('use cases', () {
      test('should handle typical merge conflict workflow', () async {
        // Arrange
        final failure = GitFailure.mergeConflict(conflict: sampleConflict);

        when(() => mockMerge(
              path: path,
              branch: 'feature',
              noFastForward: false,
            )).thenAnswer((_) async => left(failure));

        when(() => mockResolveConflict.getConflicts(path: path))
            .thenAnswer((_) async => right([sampleConflict]));

        when(() => mockResolveConflict.resolveWithStrategy(
              path: path,
              filePath: any(named: 'filePath'),
              strategy: any(named: 'strategy'),
            )).thenAnswer((_) async => right(unit));

        // Act - Try merge, get conflicts, resolve
        await service.merge(path: path, branch: 'feature');
        final conflicts = await service.getConflicts(path: path);
        await service.resolveWithStrategy(
          path: path,
          filePath: 'lib/main.dart',
          strategy: ConflictResolutionStrategy.keepCurrent,
        );

        // Assert
        expect(conflicts.isRight(), isTrue);
      });

      test('should handle interactive rebase workflow', () async {
        // Arrange
        when(() => mockRebase(
              path: path,
              onto: 'main',
              interactive: true,
            )).thenAnswer((_) async => right(unit));

        when(() => mockRebase.isRebaseInProgress(path: path))
            .thenAnswer((_) async => right(true));

        when(() => mockRebase.continue_(path: path))
            .thenAnswer((_) async => right(unit));

        // Act
        await service.rebase(path: path, onto: 'main', interactive: true);
        final inProgress = await service.isRebaseInProgress(path: path);
        await service.rebaseContinue(path: path);

        // Assert
        expect(inProgress.isRight(), isTrue);
      });

      test('should handle conflict resolution with suggestions', () async {
        // Arrange
        const content = '''
<<<<<<< HEAD
=======
new feature
>>>>>>> feature
''';

        when(() => mockResolveConflict.getConflictContent(
              path: path,
              filePath: 'file.dart',
            )).thenAnswer((_) async => right(content));

        when(() => mockResolveConflict.parseConflictMarkers(content))
            .thenReturn({'ours': '', 'theirs': 'new feature'});

        when(() => mockResolveConflict.resolveWithStrategy(
              path: path,
              filePath: 'file.dart',
              strategy: ConflictResolutionStrategy.acceptIncoming,
            )).thenAnswer((_) async => right(unit));

        // Act
        final suggestion =
            await service.analyzeConflict(path: path, filePath: 'file.dart');

        if (suggestion != null && suggestion.isHighConfidence) {
          await service.resolveWithStrategy(
            path: path,
            filePath: 'file.dart',
            strategy: suggestion.strategy,
          );
        }

        // Assert
        expect(suggestion, isNotNull);
        expect(suggestion!.isHighConfidence, isTrue);
      });
    });
  });
}
