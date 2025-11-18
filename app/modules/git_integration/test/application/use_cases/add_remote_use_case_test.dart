import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockGitRepository extends Mock implements IGitRepository {}

void main() {
  group('AddRemoteUseCase', () {
    late MockGitRepository mockRepository;
    late AddRemoteUseCase useCase;
    late RepositoryPath repoPath;

    setUp(() {
      mockRepository = MockGitRepository();
      useCase = AddRemoteUseCase(mockRepository);
      repoPath = const RepositoryPath(path: '/test/repo');

      registerFallbackValue(repoPath);
      registerFallbackValue(RemoteName.create('origin'));
    });

    test('should add remote successfully', () async {
      // Arrange
      when(() => mockRepository.addRemote(
            path: any(named: 'path'),
            name: any(named: 'name'),
            url: any(named: 'url'),
          )).thenAnswer((_) async => right(unit));

      // Act
      final result = await useCase(
        path: repoPath,
        name: 'origin',
        url: 'https://github.com/user/repo.git',
      );

      // Assert
      expect(result.isRight(), isTrue);
    });
  });
}
