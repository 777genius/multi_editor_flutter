import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockGitRepository extends Mock implements IGitRepository {}

void main() {
  group('StageFilesUseCase', () {
    late MockGitRepository mockRepository;
    late StageFilesUseCase useCase;
    late RepositoryPath repoPath;

    setUp(() {
      mockRepository = MockGitRepository();
      useCase = StageFilesUseCase(mockRepository);
      repoPath = const RepositoryPath(path: '/test/repo');

      registerFallbackValue(repoPath);
    });

    group('call', () {
      test('should stage files successfully', () async {
        // Arrange
        final filePaths = ['lib/main.dart', 'lib/feature.dart'];

        when(() => mockRepository.stageFiles(
              path: any(named: 'path'),
              filePaths: any(named: 'filePaths'),
            )).thenAnswer((_) async => right(unit));

        // Act
        final result = await useCase(
          path: repoPath,
          filePaths: filePaths,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockRepository.stageFiles(
              path: repoPath,
              filePaths: filePaths,
            )).called(1);
      });

      test('should return unit when file list is empty', () async {
        // Act
        final result = await useCase(
          path: repoPath,
          filePaths: [],
        );

        // Assert
        expect(result.isRight(), isTrue);
        verifyNever(() => mockRepository.stageFiles(
              path: any(named: 'path'),
              filePaths: any(named: 'filePaths'),
            ));
      });

      test('should fail when repository not found', () async {
        // Arrange
        when(() => mockRepository.stageFiles(
              path: any(named: 'path'),
              filePaths: any(named: 'filePaths'),
            )).thenAnswer(
          (_) async => left(const GitFailure.repositoryNotFound(
            path: RepositoryPath(path: '/test/repo'),
          )),
        );

        // Act
        final result = await useCase(
          path: repoPath,
          filePaths: ['lib/main.dart'],
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<_RepositoryNotFound>());
          },
          (_) => fail('Should not succeed'),
        );
      });

      test('should fail when file not found', () async {
        // Arrange
        when(() => mockRepository.stageFiles(
              path: any(named: 'path'),
              filePaths: any(named: 'filePaths'),
            )).thenAnswer(
          (_) async => left(const GitFailure.unknown(
            message: 'File not found',
          )),
        );

        // Act
        final result = await useCase(
          path: repoPath,
          filePaths: ['nonexistent.dart'],
        );

        // Assert
        expect(result.isLeft(), isTrue);
      });

      test('should handle multiple files', () async {
        // Arrange
        final filePaths = [
          'lib/main.dart',
          'lib/feature1.dart',
          'lib/feature2.dart',
          'test/test.dart',
        ];

        when(() => mockRepository.stageFiles(
              path: any(named: 'path'),
              filePaths: any(named: 'filePaths'),
            )).thenAnswer((_) async => right(unit));

        // Act
        final result = await useCase(
          path: repoPath,
          filePaths: filePaths,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockRepository.stageFiles(
              path: repoPath,
              filePaths: filePaths,
            )).called(1);
      });
    });

    group('stageAll', () {
      test('should stage all changes successfully', () async {
        // Arrange
        when(() => mockRepository.stageAll(
              path: any(named: 'path'),
            )).thenAnswer((_) async => right(unit));

        // Act
        final result = await useCase.stageAll(path: repoPath);

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockRepository.stageAll(path: repoPath)).called(1);
      });

      test('should fail when repository not found', () async {
        // Arrange
        when(() => mockRepository.stageAll(
              path: any(named: 'path'),
            )).thenAnswer(
          (_) async => left(const GitFailure.repositoryNotFound(
            path: RepositoryPath(path: '/test/repo'),
          )),
        );

        // Act
        final result = await useCase.stageAll(path: repoPath);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<_RepositoryNotFound>());
          },
          (_) => fail('Should not succeed'),
        );
      });

      test('should work when no changes to stage', () async {
        // Arrange
        when(() => mockRepository.stageAll(
              path: any(named: 'path'),
            )).thenAnswer((_) async => right(unit));

        // Act
        final result = await useCase.stageAll(path: repoPath);

        // Assert
        expect(result.isRight(), isTrue);
      });
    });
  });
}
