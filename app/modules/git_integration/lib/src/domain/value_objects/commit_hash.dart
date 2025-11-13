import 'package:freezed_annotation/freezed_annotation.dart';

part 'commit_hash.freezed.dart';

/// Commit hash (SHA-1) value object with validation
@freezed
class CommitHash with _$CommitHash {
  const CommitHash._();

  const factory CommitHash({
    required String value,
  }) = _CommitHash;

  /// Factory with validation for full SHA-1 hash (40 hex chars)
  factory CommitHash.create(String value) {
    // Validate SHA-1 format (40 hex chars)
    if (value.length != 40) {
      throw CommitHashValidationException(
        'Commit hash must be 40 characters, got ${value.length}',
      );
    }

    if (!RegExp(r'^[a-f0-9]{40}$', caseSensitive: false).hasMatch(value)) {
      throw CommitHashValidationException(
        'Invalid commit hash format: must be 40 hexadecimal characters',
      );
    }

    return CommitHash(value: value.toLowerCase());
  }

  /// Create from short hash (7+ chars) - no validation, used for display
  factory CommitHash.fromShort(String shortHash) {
    if (shortHash.length < 7) {
      throw CommitHashValidationException(
        'Short hash must be at least 7 characters',
      );
    }

    // Pad with zeros to make it 40 chars (for internal representation)
    final padded = shortHash.toLowerCase().padRight(40, '0');
    return CommitHash(value: padded);
  }

  /// Domain logic: Get short hash (7 chars)
  String get short => value.substring(0, 7);

  /// Domain logic: Get medium hash (10 chars)
  String get medium => value.substring(0, 10);

  /// Domain logic: Compare hashes (case-insensitive)
  bool matches(CommitHash other) {
    return value.toLowerCase() == other.value.toLowerCase();
  }
}

/// Exception for commit hash validation
class CommitHashValidationException implements Exception {
  final String message;
  CommitHashValidationException(this.message);

  @override
  String toString() => 'CommitHashValidationException: $message';
}
