import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockGitRepository extends Mock implements IGitRepository {}

void main() {
  group('CheckoutBranchUseCase', () {
    late MockGitRepository mockRepository;
    late CheckoutBranchUseCase useCase;
    late RepositoryPath repoPath;

    setUp(() {
      mockRepository = MockGitRepository();
      useCase = CheckoutBranchUseCase(mockRepository);
      repoPath = const RepositoryPath(path: '/test/repo');

      registerFallbackValue(repoPath);
      registerFallbackValue(const BranchName(value: 'main'));
    });

    group('call', () {
      test('should checkout branch successfully', () async {
        // Arrange
        const branchName = BranchName(value: 'feature/new-feature');
        final expectedBranch = GitBranch(
          name: branchName,
          headCommit: CommitHash.create('a' * 40),
          type: BranchType.local,
          isCurrent: true,
        );

        when(() => mockRepository.checkoutBranch(
              path: any(named: 'path'),
              branchName: any(named: 'branchName'),
              createIfNotExists: any(named: 'createIfNotExists'),
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
            expect(branch.isCurrent, isTrue);
          },
        );

        verify(() => mockRepository.checkoutBranch(
              path: repoPath,
              branchName: branchName,
              createIfNotExists: false,
            )).called(1);
      });

      test('should fail when branch not found', () async {
        // Arrange
        const branchName = BranchName(value: 'nonexistent');

        when(() => mockRepository.checkoutBranch(
              path: any(named: 'path'),
              branchName: any(named: 'branchName'),
              createIfNotExists: any(named: 'createIfNotExists'),
            )).thenAnswer(
          (_) async => left(const GitFailure.branchNotFound(
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
            expect(failure, isA<_BranchNotFound>());
          },
          (_) => fail('Should not succeed'),
        );
      });

      test('should fail when cannot checkout due to uncommitted changes', () async {
        // Arrange
        const branchName = BranchName(value: 'develop');

        when(() => mockRepository.checkoutBranch(
              path: any(named: 'path'),
              branchName: any(named: 'branchName'),
              createIfNotExists: any(named: 'createIfNotExists'),
            )).thenAnswer(
          (_) async => left(const GitFailure.cannotCheckout(
            reason: 'Uncommitted changes in working directory',
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
            expect(failure, isA<_CannotCheckout>());
          },
          (_) => fail('Should not succeed'),
        );
      });

      test('should create and checkout when createIfNotExists is true', () async {
        // Arrange
        const branchName = BranchName(value: 'feature/auto-create');
        final expectedBranch = GitBranch(
          name: branchName,
          headCommit: CommitHash.create('a' * 40),
          type: BranchType.local,
          isCurrent: true,
        );

        when(() => mockRepository.checkoutBranch(
              path: any(named: 'path'),
              branchName: any(named: 'branchName'),
              createIfNotExists: true,
            )).thenAnswer((_) async => right(expectedBranch));

        // Act
        final result = await useCase(
          path: repoPath,
          branchName: branchName.value,
          createIfNotExists: true,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockRepository.checkoutBranch(
              path: repoPath,
              branchName: branchName,
              createIfNotExists: true,
            )).called(1);
      });

      test('should checkout main branch', () async {
        // Arrange
        const branchName = BranchName(value: 'main');
        final expectedBranch = GitBranch(
          name: branchName,
          headCommit: CommitHash.create('a' * 40),
          type: BranchType.local,
          isCurrent: true,
        );

        when(() => mockRepository.checkoutBranch(
              path: any(named: 'path'),
              branchName: any(named: 'branchName'),
              createIfNotExists: any(named: 'createIfNotExists'),
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
            expect(branch.isMainBranch, isTrue);
          },
        );
      });

      test('should fail when repository not found', () async {
        // Arrange
        when(() => mockRepository.checkoutBranch(
              path: any(named: 'path'),
              branchName: any(named: 'branchName'),
              createIfNotExists: any(named: 'createIfNotExists'),
            )).thenAnswer(
          (_) async => left(const GitFailure.repositoryNotFound(
            path: RepositoryPath(path: '/test/repo'),
          )),
        );

        // Act
        final result = await useCase(
          path: repoPath,
          branchName: 'develop',
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
    });
  });
}
