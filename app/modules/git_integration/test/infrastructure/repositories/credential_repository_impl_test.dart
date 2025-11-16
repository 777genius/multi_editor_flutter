import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/src/infrastructure/repositories/credential_repository_impl.dart';
import 'package:git_integration/src/domain/entities/git_credential.dart';
import 'package:fpdart/fpdart.dart' as fp;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  // Note: flutter_secure_storage requires platform setup
  // These tests verify the interface and logic, not actual encryption

  group('CredentialRepositoryImpl', () {
    late CredentialRepositoryImpl repository;

    setUp(() {
      // Initialize mock secure storage for testing
      FlutterSecureStorage.setMockInitialValues({});
      repository = CredentialRepositoryImpl();
    });

    test('should store and retrieve credential', () async {
      // Arrange
      final credential = GitCredential(
        url: 'https://github.com/test/repo.git',
        username: 'testuser',
        password: fp.some('testpassword'),
        token: fp.none(),
        type: CredentialType.password,
        createdAt: DateTime.now(),
        expiresAt: fp.none(),
      );

      // Act - Store
      final storeResult = await repository.storeCredential(
        credential: credential,
      );

      // Assert - Store succeeded
      expect(storeResult.isRight(), true);

      // Act - Retrieve
      final getResult = await repository.getCredential(
        url: credential.url,
      );

      // Assert - Retrieved correctly
      expect(getResult.isRight(), true);
      getResult.fold(
        (failure) => fail('Should have succeeded'),
        (retrieved) {
          expect(retrieved.url, credential.url);
          expect(retrieved.username, credential.username);
          expect(retrieved.type, credential.type);
        },
      );
    });

    test('should delete credential', () async {
      // Arrange
      final credential = GitCredential(
        url: 'https://gitlab.com/test/repo.git',
        username: 'testuser',
        password: fp.none(),
        token: fp.some('test_token_123'),
        type: CredentialType.token,
        createdAt: DateTime.now(),
        expiresAt: fp.none(),
      );

      await repository.storeCredential(credential: credential);

      // Act - Delete
      final deleteResult = await repository.deleteCredential(
        url: credential.url,
      );

      // Assert - Delete succeeded
      expect(deleteResult.isRight(), true);

      // Verify deletion
      final getResult = await repository.getCredential(url: credential.url);
      expect(getResult.isLeft(), true);
    });

    test('should list all credentials', () async {
      // Arrange - Store multiple credentials
      final credentials = [
        GitCredential(
          url: 'https://github.com/user1/repo1.git',
          username: 'user1',
          password: fp.some('pass1'),
          token: fp.none(),
          type: CredentialType.password,
          createdAt: DateTime.now(),
          expiresAt: fp.none(),
        ),
        GitCredential(
          url: 'https://github.com/user2/repo2.git',
          username: 'user2',
          password: fp.none(),
          token: fp.some('token2'),
          type: CredentialType.token,
          createdAt: DateTime.now(),
          expiresAt: fp.none(),
        ),
      ];

      for (final cred in credentials) {
        await repository.storeCredential(credential: cred);
      }

      // Act
      final result = await repository.getAllCredentials();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should have succeeded'),
        (allCreds) {
          expect(allCreds.length, greaterThanOrEqualTo(2));
        },
      );
    });

    test('should handle missing credential', () async {
      // Act
      final result = await repository.getCredential(
        url: 'https://nonexistent.com/repo.git',
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.userMessage, contains('not found')),
        (_) => fail('Should have failed'),
      );
    });

    test('should sanitize keys correctly', () async {
      // Arrange - URL with special characters
      final credential = GitCredential(
        url: 'https://github.com/user@org/repo.git?param=value',
        username: 'testuser',
        password: fp.some('password'),
        token: fp.none(),
        type: CredentialType.password,
        createdAt: DateTime.now(),
        expiresAt: fp.none(),
      );

      // Act
      final storeResult = await repository.storeCredential(
        credential: credential,
      );
      final getResult = await repository.getCredential(url: credential.url);

      // Assert - Should handle special chars
      expect(storeResult.isRight(), true);
      expect(getResult.isRight(), true);
    });

    test('should list SSH keys', () async {
      // Act
      final result = await repository.listSSHKeys();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should have succeeded'),
        (keys) => expect(keys, isA<List<String>>()),
      );
    });

    test('should clear all credentials', () async {
      // Arrange - Store some credentials
      final credential = GitCredential(
        url: 'https://test.com/repo.git',
        username: 'user',
        password: fp.some('pass'),
        token: fp.none(),
        type: CredentialType.password,
        createdAt: DateTime.now(),
        expiresAt: fp.none(),
      );

      await repository.storeCredential(credential: credential);

      // Act
      final clearResult = await repository.clearAll();

      // Assert
      expect(clearResult.isRight(), true);

      // Verify cleared
      final getResult = await repository.getAllCredentials();
      getResult.fold(
        (failure) => fail('Should have succeeded'),
        (creds) => expect(creds, isEmpty),
      );
    });
  });
}
