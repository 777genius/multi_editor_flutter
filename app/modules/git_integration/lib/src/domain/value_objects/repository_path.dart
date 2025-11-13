import 'dart:io';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' as p;

part 'repository_path.freezed.dart';

/// Repository path value object with validation
@freezed
class RepositoryPath with _$RepositoryPath {
  const RepositoryPath._();

  const factory RepositoryPath({
    required String path,
  }) = _RepositoryPath;

  /// Factory with validation
  factory RepositoryPath.create(String path) {
    if (path.isEmpty) {
      throw RepositoryPathValidationException('Path cannot be empty');
    }

    // Normalize path (resolve relative paths, remove trailing slashes)
    final normalized = p.normalize(path);

    return RepositoryPath(path: normalized);
  }

  /// Domain logic: Get .git directory path
  String get gitDirPath => p.join(path, '.git');

  /// Domain logic: Check if repository exists
  Future<bool> exists() async {
    final gitDir = Directory(gitDirPath);
    return gitDir.exists();
  }

  /// Domain logic: Get absolute path
  String get absolute => p.absolute(path);

  /// Domain logic: Get directory name
  String get name => p.basename(path);
}

/// Exception for repository path validation
class RepositoryPathValidationException implements Exception {
  final String message;
  RepositoryPathValidationException(this.message);

  @override
  String toString() => 'RepositoryPathValidationException: $message';
}
