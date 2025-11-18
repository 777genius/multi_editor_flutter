import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockGitRepository extends Mock implements IGitRepository {}

void main() {
  group('UnstageFilesUseCase', () {
    late MockGitRepository mockRepository;
    late UnstageFilesUseCase useCase;
    late RepositoryPath repoPath;

    setUp(() {
      mockRepository = MockGitRepository();
      useCase = UnstageFilesUseCase(mockRepository);
      repoPath = const RepositoryPath(path: '/test/repo');

      registerFallbackValue(repoPath);
    });

    test('should unstage files successfully', () async {
      // Arrange
      when(() => mockRepository.unstage(
            path: any(named: 'path'),
            files: any(named: 'files'),
          )).thenAnswer((_) async => right(unit));

      // Act
      final result = await useCase(
        path: repoPath,
        files: ['file1.dart', 'file2.dart'],
      );

      // Assert
      expect(result.isRight(), isTrue);
    });
  });
}
