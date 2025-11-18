import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';

void main() {
  group('RemoteName', () {
    group('creation with validation', () {
      test('should create valid remote name', () {
        // Arrange & Act
        final remoteName = RemoteName.create('origin');

        // Assert
        expect(remoteName.value, equals('origin'));
      });

      test('should create remote name with hyphens', () {
        // Arrange & Act
        final remoteName = RemoteName.create('my-remote');

        // Assert
        expect(remoteName.value, equals('my-remote'));
      });

      test('should create remote name with underscores', () {
        // Arrange & Act
        final remoteName = RemoteName.create('my_remote');

        // Assert
        expect(remoteName.value, equals('my_remote'));
      });

      test('should create remote name with numbers', () {
        // Arrange & Act
        final remoteName = RemoteName.create('remote123');

        // Assert
        expect(remoteName.value, equals('remote123'));
      });

      test('should create mixed alphanumeric remote name', () {
        // Arrange & Act
        final remoteName = RemoteName.create('My-Remote_123');

        // Assert
        expect(remoteName.value, equals('My-Remote_123'));
      });
    });

    group('validation errors', () {
      test('should throw error for empty name', () {
        // Act & Assert
        expect(
          () => RemoteName.create(''),
          throwsA(isA<RemoteNameValidationException>()),
        );
      });

      test('should throw error for whitespace-only name', () {
        // Act & Assert
        expect(
          () => RemoteName.create('   '),
          throwsA(isA<RemoteNameValidationException>()),
        );
      });

      test('should throw error for name with spaces', () {
        // Act & Assert
        expect(
          () => RemoteName.create('my remote'),
          throwsA(isA<RemoteNameValidationException>()),
        );
      });

      test('should throw error for name with slash', () {
        // Act & Assert
        expect(
          () => RemoteName.create('origin/main'),
          throwsA(isA<RemoteNameValidationException>()),
        );
      });

      test('should throw error for name with special characters', () {
        // Act & Assert
        expect(
          () => RemoteName.create('origin@remote'),
          throwsA(isA<RemoteNameValidationException>()),
        );
      });

      test('should throw error for name with dot', () {
        // Act & Assert
        expect(
          () => RemoteName.create('origin.remote'),
          throwsA(isA<RemoteNameValidationException>()),
        );
      });

      test('should throw error for name with colon', () {
        // Act & Assert
        expect(
          () => RemoteName.create('origin:remote'),
          throwsA(isA<RemoteNameValidationException>()),
        );
      });
    });

    group('isOrigin', () {
      test('should detect origin remote', () {
        // Arrange
        final remoteName = RemoteName.create('origin');

        // Act & Assert
        expect(remoteName.isOrigin, isTrue);
      });

      test('should not detect non-origin remote', () {
        // Arrange
        final remoteName = RemoteName.create('upstream');

        // Act & Assert
        expect(remoteName.isOrigin, isFalse);
      });

      test('should not detect similar names as origin', () {
        // Arrange
        final remoteName = RemoteName.create('origin2');

        // Act & Assert
        expect(remoteName.isOrigin, isFalse);
      });
    });

    group('isUpstream', () {
      test('should detect upstream remote', () {
        // Arrange
        final remoteName = RemoteName.create('upstream');

        // Act & Assert
        expect(remoteName.isUpstream, isTrue);
      });

      test('should not detect non-upstream remote', () {
        // Arrange
        final remoteName = RemoteName.create('origin');

        // Act & Assert
        expect(remoteName.isUpstream, isFalse);
      });

      test('should not detect similar names as upstream', () {
        // Arrange
        final remoteName = RemoteName.create('upstream2');

        // Act & Assert
        expect(remoteName.isUpstream, isFalse);
      });
    });

    group('defaultRemote', () {
      test('should return origin as default remote', () {
        // Arrange & Act
        final defaultRemote = RemoteName.defaultRemote;

        // Assert
        expect(defaultRemote.value, equals('origin'));
        expect(defaultRemote.isOrigin, isTrue);
      });
    });

    group('equality', () {
      test('should be equal with same value', () {
        // Arrange
        final remote1 = RemoteName.create('origin');
        final remote2 = RemoteName.create('origin');

        // Act & Assert
        expect(remote1, equals(remote2));
      });

      test('should not be equal with different values', () {
        // Arrange
        final remote1 = RemoteName.create('origin');
        final remote2 = RemoteName.create('upstream');

        // Act & Assert
        expect(remote1, isNot(equals(remote2)));
      });
    });

    group('use cases', () {
      test('should handle typical origin remote', () {
        // Arrange & Act
        final remote = RemoteName.create('origin');

        // Assert
        expect(remote.value, equals('origin'));
        expect(remote.isOrigin, isTrue);
        expect(remote.isUpstream, isFalse);
      });

      test('should handle upstream remote', () {
        // Arrange & Act
        final remote = RemoteName.create('upstream');

        // Assert
        expect(remote.value, equals('upstream'));
        expect(remote.isOrigin, isFalse);
        expect(remote.isUpstream, isTrue);
      });

      test('should handle custom remote name', () {
        // Arrange & Act
        final remote = RemoteName.create('my-fork');

        // Assert
        expect(remote.value, equals('my-fork'));
        expect(remote.isOrigin, isFalse);
        expect(remote.isUpstream, isFalse);
      });

      test('should handle company remote', () {
        // Arrange & Act
        final remote = RemoteName.create('company_gitlab');

        // Assert
        expect(remote.value, equals('company_gitlab'));
        expect(remote.isOrigin, isFalse);
        expect(remote.isUpstream, isFalse);
      });

      test('should handle backup remote', () {
        // Arrange & Act
        final remote = RemoteName.create('backup');

        // Assert
        expect(remote.value, equals('backup'));
        expect(remote.isOrigin, isFalse);
        expect(remote.isUpstream, isFalse);
      });
    });

    group('RemoteNameValidationException', () {
      test('should have descriptive string representation', () {
        // Arrange
        final exception = RemoteNameValidationException('Test error');

        // Act & Assert
        expect(exception.toString(), contains('RemoteNameValidationException'));
        expect(exception.toString(), contains('Test error'));
      });

      test('should preserve error message', () {
        // Arrange
        final message = 'Invalid remote name';
        final exception = RemoteNameValidationException(message);

        // Act & Assert
        expect(exception.message, equals(message));
      });
    });
  });
}
