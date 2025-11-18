import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockGitRepository extends Mock implements IGitRepository {}

void main() {
  group('PullChangesUseCase', () {
    late MockGitRepository mockRepository;
    late PullChangesUseCase useCase;
    late RepositoryPath repoPath;

    setUp(() {
      mockRepository = MockGitRepository();
      useCase = PullChangesUseCase(mockRepository);
      repoPath = const RepositoryPath(path: '/test/repo');

      registerFallbackValue(repoPath);
      registerFallbackValue(RemoteName.create('origin'));
      registerFallbackValue(null);
    });

    test('should pull changes successfully', () async {
      // Arrange
      when(() => mockRepository.pull(
            path: any(named: 'path'),
            remote: any(named: 'remote'),
            branch: any(named: 'branch'),
            rebase: any(named: 'rebase'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((_) async => right(unit));

      // Act
      final result = await useCase(path: repoPath);

      // Assert
      expect(result.isRight(), isTrue);
      verify(() => mockRepository.pull(
            path: repoPath,
            remote: any(named: 'remote'),
            branch: any(named: 'branch'),
            rebase: false,
            onProgress: any(named: 'onProgress'),
          )).called(1);
    });

    test('should pull with rebase when specified', () async {
      // Arrange
      when(() => mockRepository.pull(
            path: any(named: 'path'),
            remote: any(named: 'remote'),
            branch: any(named: 'branch'),
            rebase: any(named: 'rebase'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((_) async => right(unit));

      // Act
      final result = await useCase(path: repoPath, rebase: true);

      // Assert
      expect(result.isRight(), isTrue);
      verify(() => mockRepository.pull(
            path: any(named: 'path'),
            remote: any(named: 'remote'),
            branch: any(named: 'branch'),
            rebase: true,
            onProgress: any(named: 'onProgress'),
          )).called(1);
    });

    test('should fail when repository not found', () async {
      // Arrange
      final nonExistentPath = const RepositoryPath(path: '/nonexistent');

      // Act
      final result = await useCase(path: nonExistentPath);

      // Assert
      expect(result.isLeft(), isTrue);
    });
  });
}
