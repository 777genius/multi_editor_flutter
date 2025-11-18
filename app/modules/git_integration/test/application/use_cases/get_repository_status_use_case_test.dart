import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockGitRepository extends Mock implements IGitRepository {}

void main() {
  group('GetRepositoryStatusUseCase', () {
    late MockGitRepository mockRepository;
    late GetRepositoryStatusUseCase useCase;
    late RepositoryPath repoPath;

    setUp(() {
      mockRepository = MockGitRepository();
      useCase = GetRepositoryStatusUseCase(mockRepository);
      repoPath = const RepositoryPath(path: '/test/repo');

      registerFallbackValue(repoPath);
    });

    test('should get repository status successfully', () async {
      // Arrange
      final mockStatus = RepositoryStatus(
        currentBranch: 'main',
        changes: const [],
        stagedChanges: const [],
      );

      when(() => mockRepository.status(path: any(named: 'path')))
          .thenAnswer((_) async => right(mockStatus));

      // Act
      final result = await useCase(path: repoPath);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should not fail'),
        (status) {
          expect(status.currentBranch, equals('main'));
        },
      );
    });

    test('should fail when repository not found', () async {
      // Arrange
      when(() => mockRepository.status(path: any(named: 'path'))).thenAnswer(
        (_) async => left(const GitFailure.repositoryNotFound(
          path: RepositoryPath(path: '/test/repo'),
        )),
      );

      // Act
      final result = await useCase(path: repoPath);

      // Assert
      expect(result.isLeft(), isTrue);
    });
  });
}
