import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:path/path.dart' as p;
import 'security_config.dart';

/// Secure file service with sandboxing and access control
///
/// Wraps file I/O operations with security checks to prevent:
/// - Reading sensitive system files
/// - Writing outside allowed directories
/// - Path traversal attacks
/// - Symlink attacks
class SecureFileService {
  final SecurityConfig _config;

  SecureFileService([SecurityConfig? config])
      : _config = config ?? getSecurityConfig();

  /// Read file with security checks
  ///
  /// Returns:
  /// - Right(String) on success
  /// - Left(SecurityError) if access denied
  /// - Left(FileError) if file error
  Future<Either<String, String>> readFile(String path) async {
    try {
      // Security check
      final securityCheck = _validatePath(path);
      if (securityCheck.isLeft()) {
        return securityCheck;
      }

      // Additional checks
      final file = File(path);

      // Check if file exists
      if (!await file.exists()) {
        return left('File not found: $path');
      }

      // Check if it's actually a file (not directory or symlink)
      final stat = await file.stat();
      if (stat.type != FileSystemEntityType.file) {
        return left('Path is not a regular file: $path');
      }

      // Check file size (prevent reading huge files)
      if (stat.size > 100 * 1024 * 1024) {
        // 100MB limit
        return left('File too large (>100MB): $path');
      }

      // Read file
      final content = await file.readAsString();

      _config.debugLog('Read file: $path (${stat.size} bytes)');

      return right(content);
    } on FileSystemException catch (e) {
      _config.errorLog('Failed to read file: $path', e);
      return left('File system error: ${e.message}');
    } catch (e) {
      _config.errorLog('Unexpected error reading file: $path', e);
      return left('Failed to read file: $e');
    }
  }

  /// Write file with security checks
  ///
  /// Returns:
  /// - Right(Unit) on success
  /// - Left(SecurityError) if access denied
  /// - Left(FileError) if file error
  Future<Either<String, Unit>> writeFile(String path, String content) async {
    try {
      // Security check
      final securityCheck = _validatePath(path);
      if (securityCheck.isLeft()) {
        return securityCheck.map((_) => unit);
      }

      // Create parent directory if needed
      final file = File(path);
      final parentDir = file.parent;
      if (!await parentDir.exists()) {
        // Validate parent directory path too
        final parentCheck = _validatePath(parentDir.path);
        if (parentCheck.isLeft()) {
          return parentCheck.map((_) => unit);
        }

        await parentDir.create(recursive: true);
      }

      // Write file
      await file.writeAsString(content);

      _config.debugLog('Wrote file: $path (${content.length} chars)');

      return right(unit);
    } on FileSystemException catch (e) {
      _config.errorLog('Failed to write file: $path', e);
      return left('File system error: ${e.message}');
    } catch (e) {
      _config.errorLog('Unexpected error writing file: $path', e);
      return left('Failed to write file: $e');
    }
  }

  /// Delete file with security checks
  Future<Either<String, Unit>> deleteFile(String path) async {
    try {
      // Security check
      final securityCheck = _validatePath(path);
      if (securityCheck.isLeft()) {
        return securityCheck.map((_) => unit);
      }

      final file = File(path);

      if (!await file.exists()) {
        return left('File not found: $path');
      }

      await file.delete();

      _config.debugLog('Deleted file: $path');

      return right(unit);
    } on FileSystemException catch (e) {
      _config.errorLog('Failed to delete file: $path', e);
      return left('File system error: ${e.message}');
    } catch (e) {
      _config.errorLog('Unexpected error deleting file: $path', e);
      return left('Failed to delete file: $e');
    }
  }

  /// List directory with security checks
  Future<Either<String, List<FileSystemEntity>>> listDirectory(
    String path, {
    bool recursive = false,
  }) async {
    try {
      // Security check
      final securityCheck = _validatePath(path);
      if (securityCheck.isLeft()) {
        return securityCheck.map((_) => <FileSystemEntity>[]);
      }

      final dir = Directory(path);

      if (!await dir.exists()) {
        return left('Directory not found: $path');
      }

      final entities = await dir.list(recursive: recursive).toList();

      _config.debugLog('Listed directory: $path (${entities.length} entries)');

      return right(entities);
    } on FileSystemException catch (e) {
      _config.errorLog('Failed to list directory: $path', e);
      return left('File system error: ${e.message}');
    } catch (e) {
      _config.errorLog('Unexpected error listing directory: $path', e);
      return left('Failed to list directory: $e');
    }
  }

  /// Check if path exists
  Future<bool> exists(String path) async {
    try {
      // Security check
      final securityCheck = _validatePath(path);
      if (securityCheck.isLeft()) {
        return false;
      }

      return await FileSystemEntity.isFile(path) ||
          await FileSystemEntity.isDirectory(path);
    } catch (e) {
      return false;
    }
  }

  /// Validate path against security policy
  Either<String, Unit> _validatePath(String path) {
    // Normalize path
    final normalized = p.normalize(path);

    // Check for path traversal attempts
    if (normalized.contains('..')) {
      _config.warnLog('Path traversal attempt blocked: $path');
      return left('Invalid path: contains ".."');
    }

    // Check if path is allowed by sandbox
    if (!_config.isPathAllowed(normalized)) {
      _config.warnLog('File access denied (sandbox): $path');
      return left('Access denied: path outside allowed directories');
    }

    // Check for suspicious patterns
    if (_isSuspiciousPath(normalized)) {
      _config.warnLog('Suspicious path blocked: $path');
      return left('Access denied: suspicious path pattern');
    }

    return right(unit);
  }

  /// Check if path looks suspicious
  bool _isSuspiciousPath(String path) {
    final lowercasePath = path.toLowerCase();

    // Common sensitive paths
    final suspiciousPatterns = [
      '/etc/passwd',
      '/etc/shadow',
      '/etc/sudoers',
      '.ssh/id_rsa',
      '.ssh/id_ed25519',
      '.aws/credentials',
      '.npmrc',
      '.pypirc',
      'web.config',
      '.env',
      '.git/config',
    ];

    for (final pattern in suspiciousPatterns) {
      if (lowercasePath.contains(pattern)) {
        return true;
      }
    }

    return false;
  }

  /// Get canonical path (resolve symlinks)
  Future<Either<String, String>> getCanonicalPath(String path) async {
    try {
      final file = File(path);
      final canonical = await file.resolveSymbolicLinks();

      // Validate canonical path too
      final securityCheck = _validatePath(canonical);
      if (securityCheck.isLeft()) {
        return left('Canonical path violates security policy');
      }

      return right(canonical);
    } catch (e) {
      return left('Failed to resolve path: $e');
    }
  }
}
