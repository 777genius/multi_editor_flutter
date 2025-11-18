import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockGitRepository extends Mock implements IGitRepository {}

void main() {
  group('GetBlameUseCase', () {
    late MockGitRepository mockRepository;
    late GetBlameUseCase useCase;
    late RepositoryPath repoPath;

    setUp(() {
      mockRepository = MockGitRepository();
      useCase = GetBlameUseCase(mockRepository);
      repoPath = const RepositoryPath(path: '/test/repo');

      registerFallbackValue(repoPath);
    });

    test('should get blame successfully', () async {
      // Arrange
      final blameLines = [
        BlameLine(
          lineNumber: 1,
          commit: GitCommit(
            hash: CommitHash.create('a' * 40),
            author: const GitAuthor(name: 'Test', email: 'test@example.com'),
            committer: const GitAuthor(name: 'Test', email: 'test@example.com'),
            message: const CommitMessage(subject: 'Test'),
            authorDate: DateTime.now(),
            commitDate: DateTime.now(),
          ),
          content: 'test line',
        ),
      ];

      when(() => mockRepository.blame(
            path: any(named: 'path'),
            filePath: any(named: 'filePath'),
            startLine: any(named: 'startLine'),
            endLine: any(named: 'endLine'),
          )).thenAnswer((_) async => right(blameLines));

      // Act
      final result = await useCase(
        path: repoPath,
        filePath: 'test.dart',
      );

      // Assert
      expect(result.isRight(), isTrue);
    });
  });
}
