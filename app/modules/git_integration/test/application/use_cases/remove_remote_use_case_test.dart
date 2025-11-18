import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockGitRepository extends Mock implements IGitRepository {}

void main() {
  group('RemoveRemoteUseCase', () {
    late MockGitRepository mockRepository;
    late RemoveRemoteUseCase useCase;
    late RepositoryPath repoPath;

    setUp(() {
      mockRepository = MockGitRepository();
      useCase = RemoveRemoteUseCase(mockRepository);
      repoPath = const RepositoryPath(path: '/test/repo');

      registerFallbackValue(repoPath);
      registerFallbackValue(RemoteName.create('origin'));
    });

    test('should remove remote successfully', () async {
      // Arrange
      when(() => mockRepository.removeRemote(
            path: any(named: 'path'),
            name: any(named: 'name'),
          )).thenAnswer((_) async => right(unit));

      // Act
      final result = await useCase(path: repoPath, name: 'origin');

      // Assert
      expect(result.isRight(), isTrue);
    });
  });
}
