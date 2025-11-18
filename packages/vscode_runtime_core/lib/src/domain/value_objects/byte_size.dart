import 'package:freezed_annotation/freezed_annotation.dart';

part 'byte_size.freezed.dart';

/// Value Object: Byte Size with human-readable formatting
@freezed
class ByteSize with _$ByteSize implements Comparable<ByteSize> {
  const ByteSize._();

  const factory ByteSize(int bytes) = _ByteSize;

  /// Factory methods
  factory ByteSize.fromKB(double kb) => ByteSize((kb * 1024).round());
  factory ByteSize.fromMB(double mb) => ByteSize((mb * 1024 * 1024).round());
  factory ByteSize.fromGB(double gb) =>
      ByteSize((gb * 1024 * 1024 * 1024).round());

  /// Validation
  factory ByteSize.validate(int bytes) {
    if (bytes < 0) {
      throw ArgumentError('Byte size cannot be negative');
    }
    return ByteSize(bytes);
  }

  /// Getters for different units
  double get kb => bytes / 1024;
  double get mb => bytes / (1024 * 1024);
  double get gb => bytes / (1024 * 1024 * 1024);

  /// Human-readable format
  String get formatted {
    if (gb >= 1) return '${gb.toStringAsFixed(2)} GB';
    if (mb >= 1) return '${mb.toStringAsFixed(2)} MB';
    if (kb >= 1) return '${kb.toStringAsFixed(2)} KB';
    return '$bytes B';
  }

  /// Alias for formatted (for compatibility)
  String toHumanReadable() => formatted;

  /// Compact format (no decimals for large sizes)
  String get compactFormatted {
    if (gb >= 1) return '${gb.toStringAsFixed(1)} GB';
    if (mb >= 1) return '${mb.toStringAsFixed(0)} MB';
    if (kb >= 1) return '${kb.toStringAsFixed(0)} KB';
    return '$bytes B';
  }

  /// Calculate progress to total size
  double progressTo(ByteSize total) {
    if (total.bytes == 0) return 0.0;
    return (bytes / total.bytes).clamp(0.0, 1.0);
  }

  /// Add sizes
  ByteSize operator +(ByteSize other) => ByteSize(bytes + other.bytes);

  /// Subtract sizes
  ByteSize operator -(ByteSize other) => ByteSize((bytes - other.bytes).clamp(0, bytes));

  /// Multiply by factor
  ByteSize operator *(double factor) => ByteSize((bytes * factor).round());

  /// Check if zero
  bool get isZero => bytes == 0;

  /// Check if non-zero
  bool get isNonZero => bytes > 0;

  @override
  int compareTo(ByteSize other) => bytes.compareTo(other.bytes);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ByteSize && runtimeType == other.runtimeType && bytes == other.bytes;

  @override
  int get hashCode => bytes.hashCode;

  @override
  String toString() => formatted;
}
