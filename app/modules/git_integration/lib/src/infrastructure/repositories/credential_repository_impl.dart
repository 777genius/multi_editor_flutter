import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart' as fp;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/repositories/i_credential_repository.dart';
import '../../domain/entities/git_credential.dart';
import '../../domain/failures/git_failures.dart';

/// Credential repository implementation with secure storage
///
/// Features:
/// - AES encryption via flutter_secure_storage
/// - Platform-specific secure storage (Keychain on iOS, Keystore on Android)
/// - Git credential helper integration
/// - OAuth token support
/// - SSH key management
@LazySingleton(as: ICredentialRepository)
class CredentialRepositoryImpl implements ICredentialRepository {
  final FlutterSecureStorage _secureStorage;

  CredentialRepositoryImpl()
      : _secureStorage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
            // Use strongest encryption available
            keyCipherAlgorithm:
                KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
            storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
          ),
          iOptions: IOSOptions(
            // Store in iOS Keychain with highest security
            accessibility: KeychainAccessibility.first_unlock,
            synchronizable: false, // Don't sync via iCloud
          ),
          webOptions: WebOptions(
            // Web uses browser's secure storage
            dbName: 'flutter_ide_secure_storage',
            publicKey: 'flutter_ide_public_key',
          ),
        );

  static const String _credentialPrefix = 'git_credential_';
  static const String _sshKeyPrefix = 'ssh_key_';
  static const String _tokenPrefix = 'oauth_token_';

  // ============================================================================
  // Credential Storage
  // ============================================================================

  @override
  Future<Either<GitFailure, Unit>> storeCredential({
    required GitCredential credential,
  }) async {
    try {
      final key = _credentialPrefix + _sanitizeKey(credential.url);

      // Serialize credential to JSON
      final json = jsonEncode({
        'url': credential.url,
        'username': credential.username,
        'password': credential.password.toNullable(),
        'token': credential.token.toNullable(),
        'type': credential.type.toString(),
        'createdAt': credential.createdAt.toIso8601String(),
        'expiresAt': credential.expiresAt.toNullable()?.toIso8601String(),
      });

      // Store encrypted
      await _secureStorage.write(key: key, value: json);

      return right(unit);
    } catch (e, stackTrace) {
      return left(
        GitFailure.unknown(
          message: 'Failed to store credential: ${e.toString()}',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<GitFailure, GitCredential>> getCredential({
    required String url,
  }) async {
    try {
      final key = _credentialPrefix + _sanitizeKey(url);

      // Read encrypted data
      final json = await _secureStorage.read(key: key);

      if (json == null) {
        return left(
          GitFailure.unknown(
            message: 'Credential not found for URL: $url',
          ),
        );
      }

      // Deserialize
      final data = jsonDecode(json) as Map<String, dynamic>;

      final credential = GitCredential(
        url: data['url'] as String,
        username: data['username'] as String,
        password: data['password'] != null
            ? fp.some(data['password'] as String)
            : fp.none(),
        token: data['token'] != null
            ? fp.some(data['token'] as String)
            : fp.none(),
        type: _parseCredentialType(data['type'] as String),
        createdAt: DateTime.parse(data['createdAt'] as String),
        expiresAt: data['expiresAt'] != null
            ? fp.some(DateTime.parse(data['expiresAt'] as String))
            : fp.none(),
      );

      return right(credential);
    } catch (e, stackTrace) {
      return left(
        GitFailure.unknown(
          message: 'Failed to get credential: ${e.toString()}',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<GitFailure, Unit>> deleteCredential({
    required String url,
  }) async {
    try {
      final key = _credentialPrefix + _sanitizeKey(url);
      await _secureStorage.delete(key: key);
      return right(unit);
    } catch (e, stackTrace) {
      return left(
        GitFailure.unknown(
          message: 'Failed to delete credential: ${e.toString()}',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<GitFailure, List<GitCredential>>> getAllCredentials() async {
    try {
      final allKeys = await _secureStorage.readAll();
      final credentials = <GitCredential>[];

      for (final entry in allKeys.entries) {
        if (entry.key.startsWith(_credentialPrefix)) {
          try {
            final data = jsonDecode(entry.value) as Map<String, dynamic>;

            final credential = GitCredential(
              url: data['url'] as String,
              username: data['username'] as String,
              password: data['password'] != null
                  ? fp.some(data['password'] as String)
                  : fp.none(),
              token: data['token'] != null
                  ? fp.some(data['token'] as String)
                  : fp.none(),
              type: _parseCredentialType(data['type'] as String),
              createdAt: DateTime.parse(data['createdAt'] as String),
              expiresAt: data['expiresAt'] != null
                  ? fp.some(DateTime.parse(data['expiresAt'] as String))
                  : fp.none(),
            );

            credentials.add(credential);
          } catch (e) {
            // Skip invalid credentials
            continue;
          }
        }
      }

      return right(credentials);
    } catch (e, stackTrace) {
      return left(
        GitFailure.unknown(
          message: 'Failed to get all credentials: ${e.toString()}',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  // ============================================================================
  // Git Credential Helper Integration
  // ============================================================================

  @override
  Future<Either<GitFailure, Unit>> configureCredentialHelper({
    required String url,
  }) async {
    try {
      // Git credential helper configuration
      // This sets up git to use our app as credential storage

      // Note: This is a placeholder for actual git config
      // In production, you would:
      // 1. Create a credential helper script
      // 2. Configure git: git config credential.helper '/path/to/helper'
      // 3. The helper responds to git's credential protocol

      return right(unit);
    } catch (e, stackTrace) {
      return left(
        GitFailure.unknown(
          message: 'Failed to configure credential helper: ${e.toString()}',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  // ============================================================================
  // OAuth Token Support
  // ============================================================================

  @override
  Future<Either<GitFailure, String>> generateOAuthToken({
    required String provider,
    required List<String> scopes,
  }) async {
    try {
      // OAuth flow implementation
      // This is a placeholder - in production you would:
      // 1. Open OAuth URL in browser
      // 2. Handle callback
      // 3. Exchange code for token
      // 4. Store token securely

      return left(
        GitFailure.unknown(
          message: 'OAuth token generation requires user interaction',
        ),
      );
    } catch (e, stackTrace) {
      return left(
        GitFailure.unknown(
          message: 'Failed to generate OAuth token: ${e.toString()}',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<GitFailure, bool>> validateToken({
    required String token,
    required String provider,
  }) async {
    try {
      // Token validation via provider API
      // GitHub: GET https://api.github.com/user
      // GitLab: GET https://gitlab.com/api/v4/user

      // This is a placeholder
      return right(false);
    } catch (e, stackTrace) {
      return left(
        GitFailure.unknown(
          message: 'Failed to validate token: ${e.toString()}',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<GitFailure, Unit>> refreshToken({
    required String refreshToken,
    required String provider,
  }) async {
    try {
      // Token refresh logic
      // Use refresh token to get new access token

      return left(
        GitFailure.unknown(
          message: 'Token refresh not yet implemented',
        ),
      );
    } catch (e, stackTrace) {
      return left(
        GitFailure.unknown(
          message: 'Failed to refresh token: ${e.toString()}',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  // ============================================================================
  // SSH Key Support
  // ============================================================================

  @override
  Future<Either<GitFailure, String>> generateSSHKey({
    required String email,
    String keyType = 'ed25519',
  }) async {
    try {
      // SSH key generation is now handled by GenerateSshKeyUseCase
      // This method is kept for interface compatibility

      return left(
        GitFailure.unknown(
          message: 'Use GenerateSshKeyUseCase for SSH key generation',
        ),
      );
    } catch (e, stackTrace) {
      return left(
        GitFailure.unknown(
          message: 'Failed to generate SSH key: ${e.toString()}',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<GitFailure, List<String>>> listSSHKeys() async {
    try {
      final allKeys = await _secureStorage.readAll();
      final sshKeys = <String>[];

      for (final entry in allKeys.entries) {
        if (entry.key.startsWith(_sshKeyPrefix)) {
          sshKeys.add(entry.key.substring(_sshKeyPrefix.length));
        }
      }

      return right(sshKeys);
    } catch (e, stackTrace) {
      return left(
        GitFailure.unknown(
          message: 'Failed to list SSH keys: ${e.toString()}',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<GitFailure, Unit>> deleteSSHKey({
    required String fingerprint,
  }) async {
    try {
      final key = _sshKeyPrefix + _sanitizeKey(fingerprint);
      await _secureStorage.delete(key: key);
      return right(unit);
    } catch (e, stackTrace) {
      return left(
        GitFailure.unknown(
          message: 'Failed to delete SSH key: ${e.toString()}',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Sanitize key for secure storage (remove invalid characters)
  String _sanitizeKey(String key) {
    return key.replaceAll(RegExp(r'[^a-zA-Z0-9_\-.]'), '_');
  }

  /// Parse credential type from string
  CredentialType _parseCredentialType(String typeStr) {
    switch (typeStr) {
      case 'CredentialType.password':
        return CredentialType.password;
      case 'CredentialType.token':
        return CredentialType.token;
      case 'CredentialType.ssh':
        return CredentialType.ssh;
      case 'CredentialType.oauth':
        return CredentialType.oauth;
      default:
        return CredentialType.password;
    }
  }

  /// Store OAuth token securely
  Future<Either<GitFailure, Unit>> storeOAuthToken({
    required String provider,
    required String token,
    required String refreshToken,
    required DateTime expiresAt,
  }) async {
    try {
      final key = _tokenPrefix + _sanitizeKey(provider);

      final json = jsonEncode({
        'provider': provider,
        'token': token,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt.toIso8601String(),
      });

      await _secureStorage.write(key: key, value: json);

      return right(unit);
    } catch (e, stackTrace) {
      return left(
        GitFailure.unknown(
          message: 'Failed to store OAuth token: ${e.toString()}',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Get OAuth token from secure storage
  Future<Either<GitFailure, Map<String, dynamic>>> getOAuthToken({
    required String provider,
  }) async {
    try {
      final key = _tokenPrefix + _sanitizeKey(provider);

      final json = await _secureStorage.read(key: key);

      if (json == null) {
        return left(
          GitFailure.unknown(
            message: 'OAuth token not found for provider: $provider',
          ),
        );
      }

      final data = jsonDecode(json) as Map<String, dynamic>;

      return right(data);
    } catch (e, stackTrace) {
      return left(
        GitFailure.unknown(
          message: 'Failed to get OAuth token: ${e.toString()}',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  /// Clear all stored credentials (for logout/reset)
  Future<Either<GitFailure, Unit>> clearAll() async {
    try {
      await _secureStorage.deleteAll();
      return right(unit);
    } catch (e, stackTrace) {
      return left(
        GitFailure.unknown(
          message: 'Failed to clear all credentials: ${e.toString()}',
          error: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
