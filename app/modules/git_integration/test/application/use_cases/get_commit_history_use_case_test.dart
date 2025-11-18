import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockGitRepository extends Mock implements IGitRepository {}

void main() {
  group('GetCommitHistoryUseCase', () {
    late MockGitRepository mockRepository;
    late GetCommitHistoryUseCase useCase;
    late RepositoryPath repoPath;

    setUp(() {
      mockRepository = MockGitRepository();
      useCase = GetCommitHistoryUseCase(mockRepository);
      repoPath = const RepositoryPath(path: '/test/repo');

      registerFallbackValue(repoPath);
      registerFallbackValue(null);
    });

    test('should get commit history successfully', () async {
      // Arrange
      final commits = [
        GitCommit(
          hash: CommitHash.create('a' * 40),
          author: const GitAuthor(name: 'Test', email: 'test@example.com'),
          committer: const GitAuthor(name: 'Test', email: 'test@example.com'),
          message: const CommitMessage(subject: 'Test commit'),
          authorDate: DateTime.now(),
          commitDate: DateTime.now(),
        ),
      ];

      when(() => mockRepository.log(
            path: any(named: 'path'),
            branch: any(named: 'branch'),
            maxCount: any(named: 'maxCount'),
            skip: any(named: 'skip'),
          )).thenAnswer((_) async => right(commits));

      // Act
      final result = await useCase(path: repoPath);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should not fail'),
        (history) {
          expect(history.length, equals(1));
        },
      );
    });
  });
}
