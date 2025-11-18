import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockGitRepository extends Mock implements IGitRepository {}

void main() {
  group('ApplyStashUseCase', () {
    late MockGitRepository mockRepository;
    late ApplyStashUseCase useCase;
    late RepositoryPath repoPath;

    setUp(() {
      mockRepository = MockGitRepository();
      useCase = ApplyStashUseCase(mockRepository);
      repoPath = const RepositoryPath(path: '/test/repo');

      registerFallbackValue(repoPath);
    });

    test('should apply stash successfully', () async {
      // Arrange
      when(() => mockRepository.applyStash(
            path: any(named: 'path'),
            index: any(named: 'index'),
            pop: any(named: 'pop'),
          )).thenAnswer((_) async => right(unit));

      // Act
      final result = await useCase(path: repoPath, index: 0);

      // Assert
      expect(result.isRight(), isTrue);
    });
  });
}
