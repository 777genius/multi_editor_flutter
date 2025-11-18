import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockGitRepository extends Mock implements IGitRepository {}

void main() {
  group('InitRepositoryUseCase', () {
    late MockGitRepository mockRepository;
    late InitRepositoryUseCase useCase;
    late RepositoryPath repoPath;

    setUp(() {
      mockRepository = MockGitRepository();
      useCase = InitRepositoryUseCase(mockRepository);
      repoPath = const RepositoryPath(path: '/test/repo');

      registerFallbackValue(repoPath);
    });

    test('should initialize repository successfully', () async {
      // Arrange
      when(() => mockRepository.init(
            path: any(named: 'path'),
            bare: any(named: 'bare'),
            defaultBranch: any(named: 'defaultBranch'),
          )).thenAnswer((_) async => right(unit));

      // Act
      final result = await useCase(path: repoPath);

      // Assert
      expect(result.isRight(), isTrue);
    });

    test('should initialize with custom default branch', () async {
      // Arrange
      when(() => mockRepository.init(
            path: any(named: 'path'),
            bare: any(named: 'bare'),
            defaultBranch: any(named: 'defaultBranch'),
          )).thenAnswer((_) async => right(unit));

      // Act
      final result = await useCase(
        path: repoPath,
        defaultBranch: 'main',
      );

      // Assert
      expect(result.isRight(), isTrue);
    });
  });
}
