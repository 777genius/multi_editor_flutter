import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockGitRepository extends Mock implements IGitRepository {}

void main() {
  group('CloneRepositoryUseCase', () {
    late MockGitRepository mockRepository;
    late CloneRepositoryUseCase useCase;
    late RepositoryPath repoPath;

    setUp(() {
      mockRepository = MockGitRepository();
      useCase = CloneRepositoryUseCase(mockRepository);
      repoPath = const RepositoryPath(path: '/test/repo');

      registerFallbackValue(repoPath);
    });

    test('should clone repository successfully', () async {
      // Arrange
      when(() => mockRepository.clone(
            url: any(named: 'url'),
            path: any(named: 'path'),
            branch: any(named: 'branch'),
            depth: any(named: 'depth'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((_) async => right(unit));

      // Act
      final result = await useCase(
        url: 'https://github.com/user/repo.git',
        path: repoPath,
      );

      // Assert
      expect(result.isRight(), isTrue);
    });

    test('should clone with shallow depth', () async {
      // Arrange
      when(() => mockRepository.clone(
            url: any(named: 'url'),
            path: any(named: 'path'),
            branch: any(named: 'branch'),
            depth: any(named: 'depth'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((_) async => right(unit));

      // Act
      final result = await useCase(
        url: 'https://github.com/user/repo.git',
        path: repoPath,
        depth: 1,
      );

      // Assert
      expect(result.isRight(), isTrue);
    });
  });
}
