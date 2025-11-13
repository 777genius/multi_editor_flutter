import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../failures/git_failures.dart';
import 'package:fpdart/fpdart.dart' as fp;

part 'i_credential_repository.freezed.dart';

/// Git credential types
@freezed
class GitCredential with _$GitCredential {
  const factory GitCredential.userPassword({
    required String username,
    required String password,
  }) = _UserPassword;

  const factory GitCredential.sshKey({
    required String privateKeyPath,
    fp.Option<String>? passphrase,
  }) = _SshKey;

  const factory GitCredential.token({
    required String token,
  }) = _Token;

  const factory GitCredential.none() = _NoCredential;

  const GitCredential._();

  /// Get credential type name
  String get typeName {
    return when(
      userPassword: (_, __) => 'Username/Password',
      sshKey: (_, __) => 'SSH Key',
      token: (_) => 'Token',
      none: () => 'None',
    );
  }

  /// Has credentials?
  bool get hasCredentials {
    return when(
      userPassword: (_, __) => true,
      sshKey: (_, __) => true,
      token: (_) => true,
      none: () => false,
    );
  }
}

/// Credential management repository interface
abstract class ICredentialRepository {
  /// Get credentials for URL
  Future<Either<GitFailure, GitCredential>> getCredentials({
    required String url,
  });

  /// Store credentials
  Future<Either<GitFailure, Unit>> storeCredentials({
    required String url,
    required GitCredential credential,
  });

  /// Remove credentials
  Future<Either<GitFailure, Unit>> removeCredentials({
    required String url,
  });

  /// Has stored credentials?
  Future<bool> hasCredentials({
    required String url,
  });
}
