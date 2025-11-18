import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockGitRepository extends Mock implements IGitRepository {}

void main() {
  group('CreateBranchUseCase', () {
    late MockGitRepository mockRepository;
    late CreateBranchUseCase useCase;
    late RepositoryPath repoPath;

    setUp(() {
      mockRepository = MockGitRepository();
      useCase = CreateBranchUseCase(mockRepository);
      repoPath = const RepositoryPath(path: '/test/repo');

      registerFallbackValue(repoPath);
      registerFallbackValue(const BranchName(value: 'main'));
    });

    group('call', () {
      test('should create branch successfully', () async {
        // Arrange
        const branchName = BranchName(value: 'feature/new-feature');
        final expectedBranch = GitBranch(
          name: branchName,
          headCommit: CommitHash.create('a' * 40),
          type: BranchType.local,
          isCurrent: false,
        );

        when(() => mockRepository.createBranch(
              path: any(named: 'path'),
              branchName: any(named: 'branchName'),
              startPoint: any(named: 'startPoint'),
              checkout: any(named: 'checkout'),
            )).thenAnswer((_) async => right(expectedBranch));

        // Act
        final result = await useCase(
          path: repoPath,
          branchName: branchName.value,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (branch) {
            expect(branch.name, equals(branchName));
            expect(branch.type, equals(BranchType.local));
          },
        );

        verify(() => mockRepository.createBranch(
              path: repoPath,
              branchName: branchName,
              startPoint: any(named: 'startPoint'),
              checkout: false,
            )).called(1);
      });

      test('should fail when branch already exists', () async {
        // Arrange
        const branchName = BranchName(value: 'existing-branch');

        when(() => mockRepository.createBranch(
              path: any(named: 'path'),
              branchName: any(named: 'branchName'),
              startPoint: any(named: 'startPoint'),
              checkout: any(named: 'checkout'),
            )).thenAnswer(
          (_) async => left(const GitFailure.branchAlreadyExists(
            branch: branchName,
          )),
        );

        // Act
        final result = await useCase(
          path: repoPath,
          branchName: branchName.value,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<_BranchAlreadyExists>());
          },
          (_) => fail('Should not succeed'),
        );
      });

      test('should create and checkout branch when checkout is true', () async {
        // Arrange
        const branchName = BranchName(value: 'feature/auth');
        final expectedBranch = GitBranch(
          name: branchName,
          headCommit: CommitHash.create('a' * 40),
          type: BranchType.local,
          isCurrent: true,
        );

        when(() => mockRepository.createBranch(
              path: any(named: 'path'),
              branchName: any(named: 'branchName'),
              startPoint: any(named: 'startPoint'),
              checkout: true,
            )).thenAnswer((_) async => right(expectedBranch));

        // Act
        final result = await useCase(
          path: repoPath,
          branchName: branchName.value,
          checkout: true,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (branch) {
            expect(branch.isCurrent, isTrue);
          },
        );

        verify(() => mockRepository.createBranch(
              path: repoPath,
              branchName: branchName,
              startPoint: any(named: 'startPoint'),
              checkout: true,
            )).called(1);
      });

      test('should create branch from specific start point', () async {
        // Arrange
        const branchName = BranchName(value: 'hotfix/bug-fix');
        const startPoint = BranchName(value: 'main');
        final expectedBranch = GitBranch(
          name: branchName,
          headCommit: CommitHash.create('a' * 40),
          type: BranchType.local,
          isCurrent: false,
        );

        when(() => mockRepository.createBranch(
              path: any(named: 'path'),
              branchName: any(named: 'branchName'),
              startPoint: startPoint,
              checkout: any(named: 'checkout'),
            )).thenAnswer((_) async => right(expectedBranch));

        // Act
        final result = await useCase(
          path: repoPath,
          branchName: branchName.value,
          startPoint: startPoint.value,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockRepository.createBranch(
              path: repoPath,
              branchName: branchName,
              startPoint: startPoint,
              checkout: false,
            )).called(1);
      });

      test('should fail when repository not found', () async {
        // Arrange
        when(() => mockRepository.createBranch(
              path: any(named: 'path'),
              branchName: any(named: 'branchName'),
              startPoint: any(named: 'startPoint'),
              checkout: any(named: 'checkout'),
            )).thenAnswer(
          (_) async => left(const GitFailure.repositoryNotFound(
            path: RepositoryPath(path: '/test/repo'),
          )),
        );

        // Act
        final result = await useCase(
          path: repoPath,
          branchName: 'feature/new',
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

      test('should validate branch name format', () async {
        // Arrange
        const branchName = BranchName(value: 'feature/special-chars');

        final expectedBranch = GitBranch(
          name: branchName,
          headCommit: CommitHash.create('a' * 40),
          type: BranchType.local,
          isCurrent: false,
        );

        when(() => mockRepository.createBranch(
              path: any(named: 'path'),
              branchName: any(named: 'branchName'),
              startPoint: any(named: 'startPoint'),
              checkout: any(named: 'checkout'),
            )).thenAnswer((_) async => right(expectedBranch));

        // Act
        final result = await useCase(
          path: repoPath,
          branchName: branchName.value,
        );

        // Assert
        expect(result.isRight(), isTrue);
      });
    });
  });
}
