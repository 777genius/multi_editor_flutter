import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:fpdart/fpdart.dart' as fp;

void main() {
  group('GitCredential', () {
    late DateTime now;
    late DateTime futureDate;
    late DateTime pastDate;

    setUp(() {
      now = DateTime.now();
      futureDate = now.add(const Duration(days: 30));
      pastDate = now.subtract(const Duration(days: 1));
    });

    group('factory constructors', () {
      test('should create password credential', () {
        // Arrange & Act
        final credential = GitCredential.password(
          url: 'https://github.com/user/repo.git',
          username: 'user',
          password: 'secret123',
        );

        // Assert
        expect(credential.type, equals(GitCredentialType.password));
        expect(credential.username, equals('user'));
        expect(credential.credentialValue, equals('secret123'));
      });

      test('should create token credential', () {
        // Arrange & Act
        final credential = GitCredential.token(
          url: 'https://github.com/user/repo.git',
          username: 'user',
          token: 'ghp_token123',
          provider: 'github',
        );

        // Assert
        expect(credential.type, equals(GitCredentialType.token));
        expect(credential.username, equals('user'));
        expect(credential.credentialValue, equals('ghp_token123'));
        expect(credential.provider, equals(fp.some('github')));
      });

      test('should create oauth credential', () {
        // Arrange & Act
        final credential = GitCredential.oauth(
          url: 'https://github.com/user/repo.git',
          username: 'user',
          accessToken: 'oauth_access_token',
          refreshToken: 'oauth_refresh_token',
          provider: 'github',
          expiresAt: futureDate,
        );

        // Assert
        expect(credential.type, equals(GitCredentialType.oauth));
        expect(credential.username, equals('user'));
        expect(credential.credentialValue, equals('oauth_access_token'));
        expect(credential.refreshToken, equals(fp.some('oauth_refresh_token')));
      });

      test('should create ssh credential', () {
        // Arrange & Act
        final credential = GitCredential.ssh(
          url: 'git@github.com:user/repo.git',
          username: 'git',
          privateKey: 'private_key_content',
          publicKey: 'public_key_content',
          passphrase: 'passphrase123',
        );

        // Assert
        expect(credential.type, equals(GitCredentialType.ssh));
        expect(credential.username, equals('git'));
        expect(credential.credentialValue, equals('private_key_content'));
        expect(credential.sshPassphrase, equals(fp.some('passphrase123')));
      });
    });

    group('isExpired', () {
      test('should return false for credential without expiry', () {
        // Arrange
        final credential = GitCredential.token(
          url: 'https://github.com/user/repo.git',
          username: 'user',
          token: 'token',
        );

        // Act & Assert
        expect(credential.isExpired, isFalse);
      });

      test('should return false for credential not yet expired', () {
        // Arrange
        final credential = GitCredential.token(
          url: 'https://github.com/user/repo.git',
          username: 'user',
          token: 'token',
          expiresAt: futureDate,
        );

        // Act & Assert
        expect(credential.isExpired, isFalse);
      });

      test('should return true for expired credential', () {
        // Arrange
        final credential = GitCredential.token(
          url: 'https://github.com/user/repo.git',
          username: 'user',
          token: 'token',
          expiresAt: pastDate,
        );

        // Act & Assert
        expect(credential.isExpired, isTrue);
      });
    });

    group('isExpiringSoon', () {
      test('should return false for credential without expiry', () {
        // Arrange
        final credential = GitCredential.token(
          url: 'https://github.com/user/repo.git',
          username: 'user',
          token: 'token',
        );

        // Act & Assert
        expect(credential.isExpiringSoon, isFalse);
      });

      test('should return true for credential expiring within 7 days', () {
        // Arrange
        final soonDate = now.add(const Duration(days: 3));
        final credential = GitCredential.token(
          url: 'https://github.com/user/repo.git',
          username: 'user',
          token: 'token',
          expiresAt: soonDate,
        );

        // Act & Assert
        expect(credential.isExpiringSoon, isTrue);
      });

      test('should return false for credential expiring after 7 days', () {
        // Arrange
        final laterDate = now.add(const Duration(days: 10));
        final credential = GitCredential.token(
          url: 'https://github.com/user/repo.git',
          username: 'user',
          token: 'token',
          expiresAt: laterDate,
        );

        // Act & Assert
        expect(credential.isExpiringSoon, isFalse);
      });

      test('should return false for already expired credential', () {
        // Arrange
        final credential = GitCredential.token(
          url: 'https://github.com/user/repo.git',
          username: 'user',
          token: 'token',
          expiresAt: pastDate,
        );

        // Act & Assert
        expect(credential.isExpiringSoon, isFalse);
      });
    });

    group('credentialValue', () {
      test('should return password for password type', () {
        // Arrange
        final credential = GitCredential.password(
          url: 'https://github.com/user/repo.git',
          username: 'user',
          password: 'secret',
        );

        // Act
        final value = credential.credentialValue;

        // Assert
        expect(value, equals('secret'));
      });

      test('should return token for token type', () {
        // Arrange
        final credential = GitCredential.token(
          url: 'https://github.com/user/repo.git',
          username: 'user',
          token: 'ghp_token',
        );

        // Act
        final value = credential.credentialValue;

        // Assert
        expect(value, equals('ghp_token'));
      });

      test('should return oauth token for oauth type', () {
        // Arrange
        final credential = GitCredential.oauth(
          url: 'https://github.com/user/repo.git',
          username: 'user',
          accessToken: 'oauth_token',
          provider: 'github',
        );

        // Act
        final value = credential.credentialValue;

        // Assert
        expect(value, equals('oauth_token'));
      });

      test('should return private key for ssh type', () {
        // Arrange
        final credential = GitCredential.ssh(
          url: 'git@github.com:user/repo.git',
          username: 'git',
          privateKey: 'private_key',
          publicKey: 'public_key',
        );

        // Act
        final value = credential.credentialValue;

        // Assert
        expect(value, equals('private_key'));
      });
    });

    group('maskedValue', () {
      test('should mask short credential', () {
        // Arrange
        final credential = GitCredential.password(
          url: 'https://github.com/user/repo.git',
          username: 'user',
          password: 'short',
        );

        // Act
        final masked = credential.maskedValue;

        // Assert
        expect(masked, equals('********'));
      });

      test('should show first and last 4 chars for long credential', () {
        // Arrange
        final credential = GitCredential.password(
          url: 'https://github.com/user/repo.git',
          username: 'user',
          password: 'verylongpassword123',
        );

        // Act
        final masked = credential.maskedValue;

        // Assert
        expect(masked, startsWith('very'));
        expect(masked, endsWith('d123'));
        expect(masked, contains('...'));
      });
    });

    group('markAsUsed', () {
      test('should update last used timestamp', () {
        // Arrange
        final credential = GitCredential.token(
          url: 'https://github.com/user/repo.git',
          username: 'user',
          token: 'token',
        );

        // Act
        final updated = credential.markAsUsed();

        // Assert
        expect(updated.lastUsedAt.isSome(), isTrue);
      });

      test('should preserve other fields when marking as used', () {
        // Arrange
        final credential = GitCredential.token(
          url: 'https://github.com/user/repo.git',
          username: 'user',
          token: 'token',
          provider: 'github',
        );

        // Act
        final updated = credential.markAsUsed();

        // Assert
        expect(updated.url, equals(credential.url));
        expect(updated.username, equals(credential.username));
        expect(updated.credentialValue, equals(credential.credentialValue));
      });
    });

    group('canAuthenticateUrl', () {
      test('should authenticate exact matching URL', () {
        // Arrange
        final credential = GitCredential.token(
          url: 'https://github.com/user/repo.git',
          username: 'user',
          token: 'token',
        );

        // Act
        final canAuth = credential.canAuthenticateUrl(
          'https://github.com/user/repo.git',
        );

        // Assert
        expect(canAuth, isTrue);
      });

      test('should authenticate different repo on same host', () {
        // Arrange
        final credential = GitCredential.token(
          url: 'https://github.com/user/repo1.git',
          username: 'user',
          token: 'token',
        );

        // Act
        final canAuth = credential.canAuthenticateUrl(
          'https://github.com/user/repo2.git',
        );

        // Assert
        expect(canAuth, isTrue);
      });

      test('should not authenticate different host', () {
        // Arrange
        final credential = GitCredential.token(
          url: 'https://github.com/user/repo.git',
          username: 'user',
          token: 'token',
        );

        // Act
        final canAuth = credential.canAuthenticateUrl(
          'https://gitlab.com/user/repo.git',
        );

        // Assert
        expect(canAuth, isFalse);
      });

      test('should not authenticate different scheme', () {
        // Arrange
        final credential = GitCredential.token(
          url: 'https://github.com/user/repo.git',
          username: 'user',
          token: 'token',
        );

        // Act
        final canAuth = credential.canAuthenticateUrl(
          'http://github.com/user/repo.git',
        );

        // Assert
        expect(canAuth, isFalse);
      });
    });

    group('defaultScopes', () {
      test('should return GitHub scopes', () {
        // Arrange
        final credential = GitCredential.token(
          url: 'https://github.com/user/repo.git',
          username: 'user',
          token: 'token',
          provider: 'github',
        );

        // Act
        final scopes = credential.defaultScopes;

        // Assert
        expect(scopes, contains('repo'));
        expect(scopes, contains('user'));
        expect(scopes, contains('gist'));
      });

      test('should return GitLab scopes', () {
        // Arrange
        final credential = GitCredential.token(
          url: 'https://gitlab.com/user/repo.git',
          username: 'user',
          token: 'token',
          provider: 'gitlab',
        );

        // Act
        final scopes = credential.defaultScopes;

        // Assert
        expect(scopes, contains('api'));
        expect(scopes, contains('read_user'));
        expect(scopes, contains('read_repository'));
      });

      test('should return Bitbucket scopes', () {
        // Arrange
        final credential = GitCredential.token(
          url: 'https://bitbucket.org/user/repo.git',
          username: 'user',
          token: 'token',
          provider: 'bitbucket',
        );

        // Act
        final scopes = credential.defaultScopes;

        // Assert
        expect(scopes, contains('repository'));
        expect(scopes, contains('account'));
      });

      test('should return empty list for unknown provider', () {
        // Arrange
        final credential = GitCredential.token(
          url: 'https://custom.com/user/repo.git',
          username: 'user',
          token: 'token',
          provider: 'custom',
        );

        // Act
        final scopes = credential.defaultScopes;

        // Assert
        expect(scopes, isEmpty);
      });

      test('should return empty list for no provider', () {
        // Arrange
        final credential = GitCredential.token(
          url: 'https://github.com/user/repo.git',
          username: 'user',
          token: 'token',
        );

        // Act
        final scopes = credential.defaultScopes;

        // Assert
        expect(scopes, isEmpty);
      });
    });

    group('toGitCredentialFormat', () {
      test('should format credential for git helper', () {
        // Arrange
        final credential = GitCredential.password(
          url: 'https://github.com/user/repo.git',
          username: 'user',
          password: 'secret',
        );

        // Act
        final formatted = credential.toGitCredentialFormat();

        // Assert
        expect(formatted, contains('protocol=https'));
        expect(formatted, contains('host=github.com'));
        expect(formatted, contains('username=user'));
        expect(formatted, contains('password=secret'));
      });

      test('should handle URLs without credentials', () {
        // Arrange
        final credential = GitCredential.ssh(
          url: 'git@github.com:user/repo.git',
          username: 'git',
          privateKey: 'key',
          publicKey: 'pub',
        );

        // Act
        final formatted = credential.toGitCredentialFormat();

        // Assert
        expect(formatted, isNotEmpty);
      });
    });

    group('GitCredentialType extension', () {
      test('should return correct display name for password', () {
        // Arrange & Act
        final displayName = GitCredentialType.password.displayName;

        // Assert
        expect(displayName, equals('Password'));
      });

      test('should return correct display name for token', () {
        // Arrange & Act
        final displayName = GitCredentialType.token.displayName;

        // Assert
        expect(displayName, equals('Access Token'));
      });

      test('should return correct display name for oauth', () {
        // Arrange & Act
        final displayName = GitCredentialType.oauth.displayName;

        // Assert
        expect(displayName, equals('OAuth'));
      });

      test('should return correct display name for ssh', () {
        // Arrange & Act
        final displayName = GitCredentialType.ssh.displayName;

        // Assert
        expect(displayName, equals('SSH Key'));
      });

      test('should return correct description for each type', () {
        // Arrange & Act
        final passwordDesc = GitCredentialType.password.description;
        final tokenDesc = GitCredentialType.token.description;
        final oauthDesc = GitCredentialType.oauth.description;
        final sshDesc = GitCredentialType.ssh.description;

        // Assert
        expect(passwordDesc, isNotEmpty);
        expect(tokenDesc, contains('recommended'));
        expect(oauthDesc, contains('OAuth'));
        expect(sshDesc, contains('SSH'));
      });

      test('should mark password as not secure', () {
        // Arrange & Act
        final isSecure = GitCredentialType.password.isSecure;

        // Assert
        expect(isSecure, isFalse);
      });

      test('should mark token as secure', () {
        // Arrange & Act
        final isSecure = GitCredentialType.token.isSecure;

        // Assert
        expect(isSecure, isTrue);
      });

      test('should mark oauth as secure', () {
        // Arrange & Act
        final isSecure = GitCredentialType.oauth.isSecure;

        // Assert
        expect(isSecure, isTrue);
      });

      test('should mark ssh as secure', () {
        // Arrange & Act
        final isSecure = GitCredentialType.ssh.isSecure;

        // Assert
        expect(isSecure, isTrue);
      });
    });

    group('use cases', () {
      test('should handle GitHub personal access token', () {
        // Arrange & Act
        final credential = GitCredential.token(
          url: 'https://github.com/user/repo.git',
          username: 'user',
          token: 'ghp_1234567890abcdefghijklmnop',
          provider: 'github',
        );

        // Assert
        expect(credential.type, equals(GitCredentialType.token));
        expect(credential.canAuthenticateUrl('https://github.com/user/other.git'),
            isTrue);
        expect(credential.defaultScopes, contains('repo'));
        expect(credential.isExpired, isFalse);
      });

      test('should handle SSH key with passphrase', () {
        // Arrange & Act
        final credential = GitCredential.ssh(
          url: 'git@github.com:user/repo.git',
          username: 'git',
          privateKey: '-----BEGIN OPENSSH PRIVATE KEY-----',
          publicKey: 'ssh-ed25519 AAAAC3...',
          passphrase: 'my_passphrase',
        );

        // Assert
        expect(credential.type, equals(GitCredentialType.ssh));
        expect(credential.sshPassphrase.isSome(), isTrue);
      });

      test('should handle expiring OAuth token', () {
        // Arrange & Act
        final expiryDate = now.add(const Duration(days: 5));
        final credential = GitCredential.oauth(
          url: 'https://gitlab.com/user/repo.git',
          username: 'user',
          accessToken: 'oauth_token',
          refreshToken: 'refresh_token',
          provider: 'gitlab',
          expiresAt: expiryDate,
        );

        // Assert
        expect(credential.isExpiringSoon, isTrue);
        expect(credential.isExpired, isFalse);
        expect(credential.refreshToken.isSome(), isTrue);
      });
    });
  });
}
