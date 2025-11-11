import '../failures/domain_failure.dart';
import 'file_name.dart';

class FilePath {
  final String value;

  static const int maxLength = 4096;

  // Reject only known invalid characters (null bytes and control characters)
  // This allows Unicode, spaces, and other valid filename characters
  static final RegExp _invalidCharsPattern = RegExp(r'[\x00-\x1F\x7F]');

  // Platform-specific invalid characters (Windows is most restrictive)
  static final RegExp _platformInvalidCharsPattern = RegExp(r'[<>:"|?*]');

  FilePath._(this.value);

  static Either<DomainFailure, FilePath> create(String input) {
    final trimmed = input.trim();

    if (trimmed.isEmpty) {
      return Left(
        DomainFailure.validationError(
          field: 'filePath',
          reason: 'File path cannot be empty',
          value: input,
        ),
      );
    }

    if (trimmed.length > maxLength) {
      return Left(
        DomainFailure.validationError(
          field: 'filePath',
          reason: 'File path cannot exceed $maxLength characters',
          value: input,
        ),
      );
    }

    // Check for control characters and null bytes
    if (_invalidCharsPattern.hasMatch(trimmed)) {
      return Left(
        DomainFailure.validationError(
          field: 'filePath',
          reason: 'File path contains invalid control characters',
          value: input,
        ),
      );
    }

    // Check for platform-specific invalid characters
    // Note: Windows paths like C:\ need special handling in calling code
    final pathWithoutDrive = trimmed.replaceFirst(RegExp(r'^[A-Za-z]:\\'), '');
    if (_platformInvalidCharsPattern.hasMatch(pathWithoutDrive)) {
      return Left(
        DomainFailure.validationError(
          field: 'filePath',
          reason: 'File path contains invalid characters: < > : " | ? *',
          value: input,
        ),
      );
    }

    if (trimmed.contains('..')) {
      return Left(
        DomainFailure.validationError(
          field: 'filePath',
          reason: 'File path cannot contain ".." (parent directory reference)',
          value: input,
        ),
      );
    }

    if (trimmed.contains('//')) {
      return Left(
        DomainFailure.validationError(
          field: 'filePath',
          reason: 'File path cannot contain consecutive slashes',
          value: input,
        ),
      );
    }

    return Right(FilePath._(trimmed));
  }

  List<String> get segments =>
      value.split('/').where((s) => s.isNotEmpty).toList();

  String get fileName {
    final segs = segments;
    return segs.isEmpty ? '' : segs.last;
  }

  String get directory {
    final segs = segments;
    if (segs.isEmpty) return '/';
    if (segs.length == 1) return '/';
    return '/${segs.sublist(0, segs.length - 1).join('/')}';
  }

  int get depth => segments.length;

  bool get isRoot => value == '/' || value.isEmpty;

  /// Get parent directory path
  ///
  /// Returns the parent directory of this path.
  ///
  /// **Important:** For root paths, this returns itself (root has no parent).
  /// Callers should check [isRoot] before calling if they need different behavior.
  ///
  /// Examples:
  /// - "/foo/bar/file.txt" → "/foo/bar"
  /// - "/foo/bar" → "/foo"
  /// - "/foo" → "/"
  /// - "/" → "/" (root returns itself)
  ///
  /// To avoid infinite loops when traversing up the tree:
  /// ```dart
  /// var current = filePath;
  /// while (!current.isRoot) {
  ///   print(current);
  ///   current = current.parent;
  /// }
  /// ```
  FilePath get parent {
    if (isRoot) {
      return this; // Root has no parent, return itself
    }
    final dir = directory;
    return FilePath._(dir);
  }

  FilePath join(String segment) {
    if (isRoot) return FilePath._('/$segment');
    return FilePath._('$value/$segment');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilePath &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
