import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockGitRepository extends Mock implements IGitRepository {}

void main() {
  group('PushChangesUseCase', () {
    late MockGitRepository mockRepository;
    late PushChangesUseCase useCase;
    late RepositoryPath repoPath;

    setUp(() {
      mockRepository = MockGitRepository();
      useCase = PushChangesUseCase(mockRepository);
      repoPath = const RepositoryPath(path: '/test/repo');

      registerFallbackValue(repoPath);
      registerFallbackValue(const RemoteName(value: 'origin'));
      registerFallbackValue(const BranchName(value: 'main'));
    });

    group('call', () {
      test('should push changes successfully', () async {
        // Arrange
        const remoteName = RemoteName(value: 'origin');
        const branchName = BranchName(value: 'main');

        when(() => mockRepository.push(
              path: any(named: 'path'),
              remote: any(named: 'remote'),
              branch: any(named: 'branch'),
              force: any(named: 'force'),
              setUpstream: any(named: 'setUpstream'),
            )).thenAnswer((_) async => right(unit));

        // Act
        final result = await useCase(
          path: repoPath,
          remoteName: remoteName.value,
          branchName: branchName.value,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockRepository.push(
              path: repoPath,
              remote: remoteName,
              branch: branchName,
              force: false,
              setUpstream: false,
            )).called(1);
      });

      test('should fail with network error', () async {
        // Arrange
        when(() => mockRepository.push(
              path: any(named: 'path'),
              remote: any(named: 'remote'),
              branch: any(named: 'branch'),
              force: any(named: 'force'),
              setUpstream: any(named: 'setUpstream'),
            )).thenAnswer(
          (_) async => left(const GitFailure.networkError(
            message: 'Connection timeout',
          )),
        );

        // Act
        final result = await useCase(
          path: repoPath,
          remoteName: 'origin',
          branchName: 'main',
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<_NetworkError>());
          },
          (_) => fail('Should not succeed'),
        );
      });

      test('should fail with authentication error', () async {
        // Arrange
        when(() => mockRepository.push(
              path: any(named: 'path'),
              remote: any(named: 'remote'),
              branch: any(named: 'branch'),
              force: any(named: 'force'),
              setUpstream: any(named: 'setUpstream'),
            )).thenAnswer(
          (_) async => left(const GitFailure.authenticationFailed(
            url: 'https://github.com/user/repo.git',
            reason: 'Invalid credentials',
          )),
        );

        // Act
        final result = await useCase(
          path: repoPath,
          remoteName: 'origin',
          branchName: 'main',
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<_AuthenticationFailed>());
          },
          (_) => fail('Should not succeed'),
        );
      });

      test('should support force push', () async {
        // Arrange
        const remoteName = RemoteName(value: 'origin');
        const branchName = BranchName(value: 'feature/force-update');

        when(() => mockRepository.push(
              path: any(named: 'path'),
              remote: any(named: 'remote'),
              branch: any(named: 'branch'),
              force: true,
              setUpstream: any(named: 'setUpstream'),
            )).thenAnswer((_) async => right(unit));

        // Act
        final result = await useCase(
          path: repoPath,
          remoteName: remoteName.value,
          branchName: branchName.value,
          force: true,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockRepository.push(
              path: repoPath,
              remote: remoteName,
              branch: branchName,
              force: true,
              setUpstream: false,
            )).called(1);
      });

      test('should support set upstream', () async {
        // Arrange
        const remoteName = RemoteName(value: 'origin');
        const branchName = BranchName(value: 'feature/new-branch');

        when(() => mockRepository.push(
              path: any(named: 'path'),
              remote: any(named: 'remote'),
              branch: any(named: 'branch'),
              force: any(named: 'force'),
              setUpstream: true,
            )).thenAnswer((_) async => right(unit));

        // Act
        final result = await useCase(
          path: repoPath,
          remoteName: remoteName.value,
          branchName: branchName.value,
          setUpstream: true,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockRepository.push(
              path: repoPath,
              remote: remoteName,
              branch: branchName,
              force: false,
              setUpstream: true,
            )).called(1);
      });

      test('should fail when remote not found', () async {
        // Arrange
        const remoteName = RemoteName(value: 'upstream');

        when(() => mockRepository.push(
              path: any(named: 'path'),
              remote: any(named: 'remote'),
              branch: any(named: 'branch'),
              force: any(named: 'force'),
              setUpstream: any(named: 'setUpstream'),
            )).thenAnswer(
          (_) async => left(const GitFailure.remoteNotFound(
            remote: remoteName,
          )),
        );

        // Act
        final result = await useCase(
          path: repoPath,
          remoteName: remoteName.value,
          branchName: 'main',
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<_RemoteNotFound>());
          },
          (_) => fail('Should not succeed'),
        );
      });

      test('should fail with timeout', () async {
        // Arrange
        when(() => mockRepository.push(
              path: any(named: 'path'),
              remote: any(named: 'remote'),
              branch: any(named: 'branch'),
              force: any(named: 'force'),
              setUpstream: any(named: 'setUpstream'),
            )).thenAnswer(
          (_) async => left(const GitFailure.timeout(
            operation: 'push',
            duration: Duration(seconds: 120),
          )),
        );

        // Act
        final result = await useCase(
          path: repoPath,
          remoteName: 'origin',
          branchName: 'main',
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<_Timeout>());
          },
          (_) => fail('Should not succeed'),
        );
      });

      test('should push to non-default remote', () async {
        // Arrange
        const remoteName = RemoteName(value: 'upstream');
        const branchName = BranchName(value: 'develop');

        when(() => mockRepository.push(
              path: any(named: 'path'),
              remote: remoteName,
              branch: any(named: 'branch'),
              force: any(named: 'force'),
              setUpstream: any(named: 'setUpstream'),
            )).thenAnswer((_) async => right(unit));

        // Act
        final result = await useCase(
          path: repoPath,
          remoteName: remoteName.value,
          branchName: branchName.value,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockRepository.push(
              path: repoPath,
              remote: remoteName,
              branch: branchName,
              force: false,
              setUpstream: false,
            )).called(1);
      });
    });
  });
}
