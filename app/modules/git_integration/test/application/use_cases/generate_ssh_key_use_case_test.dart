import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/src/application/use_cases/generate_ssh_key_use_case.dart';
import 'dart:io';

void main() {
  late GenerateSshKeyUseCase useCase;

  setUp(() {
    useCase = GenerateSshKeyUseCase();
  });

  group('GenerateSshKeyUseCase', () {
    test('should validate email format', () async {
      // Arrange
      const invalidEmail = 'notanemail';

      // Act
      final result = await useCase(
        email: invalidEmail,
        keyType: SshKeyType.ed25519,
      );

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.userMessage, contains('Invalid email')),
        (_) => fail('Should have failed with invalid email'),
      );
    });

    test('should handle valid email', () async {
      // Arrange
      const validEmail = 'test@example.com';

      // Act
      final result = await useCase(
        email: validEmail,
        keyType: SshKeyType.ed25519,
        keyName: 'test_key_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Assert - Either succeeds or fails due to ssh-keygen not available
      result.fold(
        (failure) {
          // May fail if ssh-keygen not installed (acceptable in test environment)
          expect(
            failure.userMessage,
            anyOf(
              contains('ssh-keygen'),
              contains('already exists'),
            ),
          );
        },
        (keyPair) {
          // Success - validate key pair
          expect(keyPair.publicKey, isNotEmpty);
          expect(keyPair.privateKey, isNotEmpty);
          expect(keyPair.keyType, SshKeyType.ed25519);
          expect(keyPair.comment, validEmail);

          // Cleanup - delete generated key
          try {
            File(keyPair.publicKeyPath).deleteSync();
            File(keyPair.privateKeyPath).deleteSync();
          } catch (_) {}
        },
      );
    });

    test('should list existing SSH keys', () async {
      // Act
      final result = await useCase.listKeys();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should have succeeded: ${failure.userMessage}'),
        (keys) {
          // Should return a list (may be empty)
          expect(keys, isA<List<String>>());
        },
      );
    });

    test('should generate different key types', () async {
      for (final keyType in SshKeyType.values) {
        // Arrange
        final keyName = 'test_${keyType.value}_${DateTime.now().millisecondsSinceEpoch}';

        // Act
        final result = await useCase(
          email: 'test@example.com',
          keyType: keyType,
          keyName: keyName,
        );

        // Assert
        result.fold(
          (failure) {
            // May fail if ssh-keygen not available
            expect(failure.userMessage, contains('ssh-keygen'));
          },
          (keyPair) {
            expect(keyPair.keyType, keyType);

            // Cleanup
            try {
              File(keyPair.publicKeyPath).deleteSync();
              File(keyPair.privateKeyPath).deleteSync();
            } catch (_) {}
          },
        );
      }
    });
  });
}
