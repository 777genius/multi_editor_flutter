import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockGitRepository extends Mock implements IGitRepository {}

void main() {
  group('MergeBranchUseCase', () {
    late MockGitRepository mockRepository;
    late MergeBranchUseCase useCase;
    late RepositoryPath repoPath;

    setUp(() {
      mockRepository = MockGitRepository();
      useCase = MergeBranchUseCase(mockRepository);
      repoPath = const RepositoryPath(path: '/test/repo');

      registerFallbackValue(repoPath);
      registerFallbackValue(BranchName.create('feature'));
    });

    test('should merge branch successfully', () async {
      // Arrange
      when(() => mockRepository.merge(
            path: any(named: 'path'),
            branch: any(named: 'branch'),
            fastForward: any(named: 'fastForward'),
          )).thenAnswer((_) async => right(unit));

      // Act
      final result = await useCase(
        path: repoPath,
        branchName: 'feature',
      );

      // Assert
      expect(result.isRight(), isTrue);
    });

    test('should fail on merge conflict', () async {
      // Arrange
      when(() => mockRepository.merge(
            path: any(named: 'path'),
            branch: any(named: 'branch'),
            fastForward: any(named: 'fastForward'),
          )).thenAnswer(
        (_) async => left(const GitFailure.mergeConflict(files: [])),
      );

      // Act
      final result = await useCase(
        path: repoPath,
        branchName: 'feature',
      );

      // Assert
      expect(result.isLeft(), isTrue);
    });
  });
}
