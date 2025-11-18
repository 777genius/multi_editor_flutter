import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockGitRepository extends Mock implements IGitRepository {}

void main() {
  group('StashChangesUseCase', () {
    late MockGitRepository mockRepository;
    late StashChangesUseCase useCase;
    late RepositoryPath repoPath;

    setUp(() {
      mockRepository = MockGitRepository();
      useCase = StashChangesUseCase(mockRepository);
      repoPath = const RepositoryPath(path: '/test/repo');

      registerFallbackValue(repoPath);
    });

    test('should stash changes successfully', () async {
      // Arrange
      final stash = GitStash(
        index: 0,
        description: 'WIP on main',
        createdAt: DateTime.now(),
      );

      when(() => mockRepository.stash(
            path: any(named: 'path'),
            message: any(named: 'message'),
            includeUntracked: any(named: 'includeUntracked'),
          )).thenAnswer((_) async => right(stash));

      // Act
      final result = await useCase(path: repoPath);

      // Assert
      expect(result.isRight(), isTrue);
    });
  });
}
