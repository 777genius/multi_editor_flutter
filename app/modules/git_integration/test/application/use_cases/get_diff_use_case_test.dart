import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockGitRepository extends Mock implements IGitRepository {}

void main() {
  group('GetDiffUseCase', () {
    late MockGitRepository mockRepository;
    late GetDiffUseCase useCase;
    late RepositoryPath repoPath;

    setUp(() {
      mockRepository = MockGitRepository();
      useCase = GetDiffUseCase(mockRepository);
      repoPath = const RepositoryPath(path: '/test/repo');

      registerFallbackValue(repoPath);
      registerFallbackValue(null);
    });

    test('should get diff successfully', () async {
      // Arrange
      const mockDiff = 'diff --git a/file.dart b/file.dart';

      when(() => mockRepository.diff(
            path: any(named: 'path'),
            staged: any(named: 'staged'),
            oldCommit: any(named: 'oldCommit'),
            newCommit: any(named: 'newCommit'),
            filePath: any(named: 'filePath'),
          )).thenAnswer((_) async => right(mockDiff));

      // Act
      final result = await useCase(path: repoPath);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should not fail'),
        (diff) => expect(diff, equals(mockDiff)),
      );
    });
  });
}
