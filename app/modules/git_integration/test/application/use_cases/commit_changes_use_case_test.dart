import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockGitRepository extends Mock implements IGitRepository {}

void main() {
  group('CommitChangesUseCase', () {
    late MockGitRepository mockRepository;
    late CommitChangesUseCase useCase;
    late RepositoryPath repoPath;
    late GitAuthor author;

    setUp(() {
      mockRepository = MockGitRepository();
      useCase = CommitChangesUseCase(mockRepository);
      repoPath = const RepositoryPath(path: '/test/repo');
      author = const GitAuthor(
        name: 'Test User',
        email: 'test@example.com',
      );

      // Register fallback values for any
      registerFallbackValue(repoPath);
      registerFallbackValue(const CommitMessage(subject: 'Test'));
      registerFallbackValue(author);
    });

    group('call', () {
      test('should create commit successfully', () async {
        // Arrange
        final expectedCommit = GitCommit(
          hash: CommitHash.create('a' * 40),
          author: author,
          committer: author,
          message: const CommitMessage(subject: 'Add feature'),
          authorDate: DateTime.now(),
          commitDate: DateTime.now(),
        );

        when(() => mockRepository.commit(
              path: any(named: 'path'),
              message: any(named: 'message'),
              author: any(named: 'author'),
              amend: any(named: 'amend'),
            )).thenAnswer((_) async => right(expectedCommit));

        // Act
        final result = await useCase(
          path: repoPath,
          message: 'Add feature',
          author: author,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should not fail'),
          (commit) {
            expect(commit.hash, equals(expectedCommit.hash));
            expect(commit.message.subject, equals('Add feature'));
          },
        );

        verify(() => mockRepository.commit(
              path: repoPath,
              message: any(named: 'message'),
              author: author,
              amend: false,
            )).called(1);
      });

      test('should fail when repository not found', () async {
        // Arrange
        when(() => mockRepository.commit(
              path: any(named: 'path'),
              message: any(named: 'message'),
              author: any(named: 'author'),
              amend: any(named: 'amend'),
            )).thenAnswer(
          (_) async => left(const GitFailure.repositoryNotFound(
            path: RepositoryPath(path: '/test/repo'),
          )),
        );

        // Act
        final result = await useCase(
          path: repoPath,
          message: 'Test commit',
          author: author,
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

      test('should fail with nothing to commit', () async {
        // Arrange
        when(() => mockRepository.commit(
              path: any(named: 'path'),
              message: any(named: 'message'),
              author: any(named: 'author'),
              amend: any(named: 'amend'),
            )).thenAnswer(
          (_) async => left(const GitFailure.nothingToCommit()),
        );

        // Act
        final result = await useCase(
          path: repoPath,
          message: 'Test commit',
          author: author,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<_NothingToCommit>());
          },
          (_) => fail('Should not succeed'),
        );
      });

      test('should support amend parameter', () async {
        // Arrange
        final expectedCommit = GitCommit(
          hash: CommitHash.create('a' * 40),
          author: author,
          committer: author,
          message: const CommitMessage(subject: 'Amended message'),
          authorDate: DateTime.now(),
          commitDate: DateTime.now(),
        );

        when(() => mockRepository.commit(
              path: any(named: 'path'),
              message: any(named: 'message'),
              author: any(named: 'author'),
              amend: true,
            )).thenAnswer((_) async => right(expectedCommit));

        // Act
        final result = await useCase(
          path: repoPath,
          message: 'Amended message',
          author: author,
          amend: true,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockRepository.commit(
              path: repoPath,
              message: any(named: 'message'),
              author: author,
              amend: true,
            )).called(1);
      });

      test('should handle multi-line commit messages', () async {
        // Arrange
        final multiLineMessage = 'Add feature\n\nDetailed description of the feature';

        final expectedCommit = GitCommit(
          hash: CommitHash.create('a' * 40),
          author: author,
          committer: author,
          message: CommitMessage.create(multiLineMessage),
          authorDate: DateTime.now(),
          commitDate: DateTime.now(),
        );

        when(() => mockRepository.commit(
              path: any(named: 'path'),
              message: any(named: 'message'),
              author: any(named: 'author'),
              amend: any(named: 'amend'),
            )).thenAnswer((_) async => right(expectedCommit));

        // Act
        final result = await useCase(
          path: repoPath,
          message: multiLineMessage,
          author: author,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (commit) {
            expect(commit.message.subject, equals('Add feature'));
          },
        );
      });
    });
  });
}
