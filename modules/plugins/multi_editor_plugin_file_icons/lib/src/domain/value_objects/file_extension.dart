import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_extension.freezed.dart';

/// Value Object representing a validated file extension.
///
/// Handles normalization and validation of file extensions.
/// Immutable by design (DDD principle).
@freezed
sealed class FileExtension with _$FileExtension {
  const FileExtension._();

  const factory FileExtension({required String value}) = _FileExtension;

  /// Factory constructor with validation and normalization
  factory FileExtension.parse(String filename) {
    if (filename.isEmpty) {
      return const FileExtension(value: 'unknown');
    }

    // Extract extension from filename
    final lastDotIndex = filename.lastIndexOf('.');
    if (lastDotIndex == -1 || lastDotIndex == filename.length - 1) {
      // No extension or filename ends with dot
      return const FileExtension(value: 'unknown');
    }

    // Get extension without dot, lowercase
    final extension = filename.substring(lastDotIndex + 1).toLowerCase();

    // Validate extension (alphanumeric + underscore)
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(extension)) {
      return const FileExtension(value: 'unknown');
    }

    return FileExtension(value: extension);
  }

  /// Check if this is an unknown extension
  bool get isUnknown => value == 'unknown';

  /// Check if this is a known extension
  bool get isKnown => !isUnknown;

  @override
  String toString() => value;
}
