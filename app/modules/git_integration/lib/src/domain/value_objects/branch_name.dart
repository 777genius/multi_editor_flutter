import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

part 'branch_name.freezed.dart';

/// Branch name value object with git naming rules validation
@freezed
class BranchName with _$BranchName {
  const BranchName._();

  const factory BranchName({
    required String value,
  }) = _BranchName;

  /// Factory with validation following git branch naming rules
  factory BranchName.create(String value) {
    if (value.isEmpty) {
      throw BranchNameValidationException('Branch name cannot be empty');
    }

    // Git branch name rules:
    // - Cannot contain '..'
    // - Cannot contain spaces
    // - Cannot start or end with '/'
    // - Cannot end with '.lock'
    // - Cannot contain special characters: ~, ^, :, \, *, ?, [
    if (value.contains('..')) {
      throw BranchNameValidationException(
        'Branch name cannot contain ".."',
      );
    }

    if (value.contains(' ')) {
      throw BranchNameValidationException(
        'Branch name cannot contain spaces',
      );
    }

    if (value.startsWith('/') || value.endsWith('/')) {
      throw BranchNameValidationException(
        'Branch name cannot start or end with "/"',
      );
    }

    if (value.endsWith('.lock')) {
      throw BranchNameValidationException(
        'Branch name cannot end with ".lock"',
      );
    }

    final invalidChars = RegExp(r'[~^:\\\*?\[]');
    if (invalidChars.hasMatch(value)) {
      throw BranchNameValidationException(
        'Branch name contains invalid characters: ~, ^, :, \\, *, ?, [',
      );
    }

    return BranchName(value: value);
  }

  /// Domain logic: Is remote branch name? (contains '/')
  bool get isRemote => value.contains('/');

  /// Domain logic: Get remote name for remote branch
  Option<String> get remoteName {
    if (!isRemote) return none();

    final parts = value.split('/');
    return some(parts.first);
  }

  /// Domain logic: Get short name (without remote prefix)
  String get shortName {
    if (!isRemote) return value;

    final parts = value.split('/');
    return parts.skip(1).join('/');
  }

  /// Domain logic: Get full remote tracking branch name
  String getRemoteTrackingName(String remoteName) {
    return '$remoteName/$value';
  }

  /// Domain logic: Is main/master branch?
  bool get isMainBranch {
    return value == 'main' || value == 'master';
  }
}

/// Exception for branch name validation
class BranchNameValidationException implements Exception {
  final String message;
  BranchNameValidationException(this.message);

  @override
  String toString() => 'BranchNameValidationException: $message';
}
