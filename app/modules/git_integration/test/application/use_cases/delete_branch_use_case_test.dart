import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockGitRepository extends Mock implements IGitRepository {}

void main() {
  group('DeleteBranchUseCase', () {
    late MockGitRepository mockRepository;
    late DeleteBranchUseCase useCase;
    late RepositoryPath repoPath;

    setUp(() {
      mockRepository = MockGitRepository();
      useCase = DeleteBranchUseCase(mockRepository);
      repoPath = const RepositoryPath(path: '/test/repo');

      registerFallbackValue(repoPath);
      registerFallbackValue(BranchName.create('feature'));
    });

    test('should delete branch successfully', () async {
      // Arrange
      when(() => mockRepository.deleteBranch(
            path: any(named: 'path'),
            branch: any(named: 'branch'),
            force: any(named: 'force'),
          )).thenAnswer((_) async => right(unit));

      // Act
      final result = await useCase(path: repoPath, branchName: 'feature');

      // Assert
      expect(result.isRight(), isTrue);
    });
  });
}
