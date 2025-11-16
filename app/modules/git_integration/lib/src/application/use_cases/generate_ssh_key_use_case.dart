import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import '../../domain/failures/git_failures.dart';

/// SSH Key Type
enum SshKeyType {
  rsa('rsa', 4096),
  ed25519('ed25519', 256),
  ecdsa('ecdsa', 521);

  final String value;
  final int bits;

  const SshKeyType(this.value, this.bits);
}

/// SSH Key Pair
class SshKeyPair {
  final String publicKey;
  final String privateKey;
  final String publicKeyPath;
  final String privateKeyPath;
  final SshKeyType keyType;
  final String comment;

  const SshKeyPair({
    required this.publicKey,
    required this.privateKey,
    required this.publicKeyPath,
    required this.privateKeyPath,
    required this.keyType,
    required this.comment,
  });

  String get fingerprint => _calculateFingerprint();

  String _calculateFingerprint() {
    // Simple fingerprint based on first and last chars
    // In production, use proper SHA256 hash
    final key = publicKey.replaceAll(RegExp(r'\s+'), '');
    if (key.length < 20) return 'invalid';
    return '${key.substring(0, 8)}...${key.substring(key.length - 8)}';
  }
}

/// Use Case for generating SSH keys
@injectable
class GenerateSshKeyUseCase {
  /// Generate new SSH key pair
  ///
  /// Parameters:
  /// - email: Email for key comment
  /// - keyType: Type of key to generate (RSA, ED25519, ECDSA)
  /// - keyName: Optional key name (default: id_<keyType>)
  /// - passphrase: Optional passphrase for private key
  ///
  /// Returns: SshKeyPair on success or GitFailure
  Future<Either<GitFailure, SshKeyPair>> call({
    required String email,
    required SshKeyType keyType,
    String? keyName,
    String? passphrase,
  }) async {
    try {
      // Validate email
      if (email.isEmpty || !email.contains('@')) {
        return left(
          const GitFailure.unknown(
            message: 'Invalid email address',
          ),
        );
      }

      // Determine key path
      final sshDir = await _getSshDirectory();
      final keyFileName = keyName ?? 'id_${keyType.value}_flutter_ide';
      final privateKeyPath = p.join(sshDir, keyFileName);
      final publicKeyPath = '$privateKeyPath.pub';

      // Check if key already exists
      if (await File(privateKeyPath).exists()) {
        return left(
          GitFailure.unknown(
            message: 'Key already exists: $privateKeyPath',
          ),
        );
      }

      // Build ssh-keygen command
      final args = [
        '-t', keyType.value, // Key type
        '-b', keyType.bits.toString(), // Key size
        '-C', email, // Comment
        '-f', privateKeyPath, // Output file
        '-N', passphrase ?? '', // Passphrase (empty if not provided)
      ];

      // Execute ssh-keygen
      final result = await Process.run('ssh-keygen', args);

      if (result.exitCode != 0) {
        return left(
          GitFailure.commandFailed(
            command: 'ssh-keygen ${args.join(' ')}',
            exitCode: result.exitCode,
            stderr: result.stderr.toString(),
          ),
        );
      }

      // Read generated keys
      final privateKey = await File(privateKeyPath).readAsString();
      final publicKey = await File(publicKeyPath).readAsString();

      // Set proper permissions (Unix/Mac only)
      if (!Platform.isWindows) {
        await Process.run('chmod', ['600', privateKeyPath]);
        await Process.run('chmod', ['644', publicKeyPath]);
      }

      return right(
        SshKeyPair(
          publicKey: publicKey,
          privateKey: privateKey,
          publicKeyPath: publicKeyPath,
          privateKeyPath: privateKeyPath,
          keyType: keyType,
          comment: email,
        ),
      );
    } on ProcessException catch (e) {
      return left(
        GitFailure.unknown(
          message: 'Failed to execute ssh-keygen: ${e.message}',
        ),
      );
    } catch (e) {
      return left(
        GitFailure.unknown(
          message: 'Unexpected error: $e',
        ),
      );
    }
  }

  /// List existing SSH keys
  Future<Either<GitFailure, List<String>>> listKeys() async {
    try {
      final sshDir = await _getSshDirectory();
      final dir = Directory(sshDir);

      if (!await dir.exists()) {
        return right([]);
      }

      final keys = <String>[];
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.pub')) {
          keys.add(entity.path);
        }
      }

      return right(keys);
    } catch (e) {
      return left(
        GitFailure.unknown(
          message: 'Failed to list keys: $e',
        ),
      );
    }
  }

  /// Delete SSH key pair
  Future<Either<GitFailure, Unit>> deleteKey({
    required String publicKeyPath,
  }) async {
    try {
      final privateKeyPath = publicKeyPath.replaceAll('.pub', '');

      // Delete both keys
      final publicFile = File(publicKeyPath);
      final privateFile = File(privateKeyPath);

      if (await publicFile.exists()) {
        await publicFile.delete();
      }

      if (await privateFile.exists()) {
        await privateFile.delete();
      }

      return right(unit);
    } catch (e) {
      return left(
        GitFailure.unknown(
          message: 'Failed to delete key: $e',
        ),
      );
    }
  }

  /// Get SSH directory path
  Future<String> _getSshDirectory() async {
    final homeDir = Platform.isWindows
        ? Platform.environment['USERPROFILE']
        : Platform.environment['HOME'];

    if (homeDir == null) {
      throw Exception('Cannot determine home directory');
    }

    final sshDir = p.join(homeDir, '.ssh');

    // Create .ssh directory if it doesn't exist
    final dir = Directory(sshDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);

      // Set proper permissions (Unix/Mac only)
      if (!Platform.isWindows) {
        await Process.run('chmod', ['700', sshDir]);
      }
    }

    return sshDir;
  }

  /// Copy public key to clipboard (helper for UI)
  Future<Either<GitFailure, String>> getPublicKeyContent({
    required String publicKeyPath,
  }) async {
    try {
      final file = File(publicKeyPath);

      if (!await file.exists()) {
        return left(
          GitFailure.unknown(
            message: 'Public key not found: $publicKeyPath',
          ),
        );
      }

      final content = await file.readAsString();
      return right(content);
    } catch (e) {
      return left(
        GitFailure.unknown(
          message: 'Failed to read public key: $e',
        ),
      );
    }
  }
}
