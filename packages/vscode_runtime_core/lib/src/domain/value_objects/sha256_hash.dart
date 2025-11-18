import 'package:freezed_annotation/freezed_annotation.dart';

part 'sha256_hash.freezed.dart';

/// Value Object: SHA256 Hash
/// Cryptographic hash with validation
@freezed
class SHA256Hash with _$SHA256Hash {
  const SHA256Hash._();

  const factory SHA256Hash(String value) = _SHA256Hash;

  /// Factory with validation
  factory SHA256Hash.fromString(String hash) {
    final cleaned = hash.trim().toLowerCase();

    if (cleaned.length != 64) {
      throw FormatException(
        'SHA256 hash must be exactly 64 characters, got ${cleaned.length}',
      );
    }

    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(cleaned)) {
      throw FormatException(
        'SHA256 hash must contain only hexadecimal characters (0-9, a-f)',
      );
    }

    return SHA256Hash(cleaned);
  }

  /// Verify hash against another SHA256Hash
  bool matches(SHA256Hash other) {
    return value.toLowerCase() == other.value.toLowerCase();
  }

  /// Alias for truncated (for compatibility)
  String truncate([int length = 8]) => truncated(length);

  /// Get first N characters (for display)
  String truncated([int length = 8]) {
    if (length <= 0 || length > 64) {
      throw ArgumentError('Length must be between 1 and 64');
    }
    return value.substring(0, length);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SHA256Hash &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
