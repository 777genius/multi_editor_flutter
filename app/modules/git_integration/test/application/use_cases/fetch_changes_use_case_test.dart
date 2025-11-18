import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockGitRepository extends Mock implements IGitRepository {}

void main() {
  group('FetchChangesUseCase', () {
    late MockGitRepository mockRepository;
    late FetchChangesUseCase useCase;
    late RepositoryPath repoPath;

    setUp(() {
      mockRepository = MockGitRepository();
      useCase = FetchChangesUseCase(mockRepository);
      repoPath = const RepositoryPath(path: '/test/repo');

      registerFallbackValue(repoPath);
      registerFallbackValue(RemoteName.create('origin'));
      registerFallbackValue(null);
    });

    test('should fetch changes successfully', () async {
      // Arrange
      when(() => mockRepository.fetch(
            path: any(named: 'path'),
            remote: any(named: 'remote'),
            branch: any(named: 'branch'),
            prune: any(named: 'prune'),
            tags: any(named: 'tags'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((_) async => right(unit));

      // Act
      final result = await useCase(path: repoPath);

      // Assert
      expect(result.isRight(), isTrue);
    });

    test('should fetch all remotes', () async {
      // Arrange
      when(() => mockRepository.fetchAll(
            path: any(named: 'path'),
            prune: any(named: 'prune'),
            tags: any(named: 'tags'),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((_) async => right(unit));

      // Act
      final result = await useCase.fetchAll(path: repoPath);

      // Assert
      expect(result.isRight(), isTrue);
    });

    test('should check ahead commits', () async {
      // Arrange
      when(() => mockRepository.checkAhead(
            path: any(named: 'path'),
            branch: any(named: 'branch'),
          )).thenAnswer((_) async => right(3));

      // Act
      final result = await useCase.checkAhead(path: repoPath);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should not fail'),
        (count) => expect(count, equals(3)),
      );
    });

    test('should check behind commits', () async {
      // Arrange
      when(() => mockRepository.checkBehind(
            path: any(named: 'path'),
            branch: any(named: 'branch'),
          )).thenAnswer((_) async => right(5));

      // Act
      final result = await useCase.checkBehind(path: repoPath);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should not fail'),
        (count) => expect(count, equals(5)),
      );
    });
  });
}
