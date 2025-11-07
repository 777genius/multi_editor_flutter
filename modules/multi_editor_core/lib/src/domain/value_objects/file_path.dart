import '../failures/domain_failure.dart';
import 'file_name.dart';

class FilePath {
  final String value;

  static const int maxLength = 4096;
  static final RegExp _validPattern = RegExp(r'^[a-zA-Z0-9._/\-]+$');

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

    if (!_validPattern.hasMatch(trimmed)) {
      return Left(
        DomainFailure.validationError(
          field: 'filePath',
          reason: 'File path contains invalid characters',
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

  FilePath get parent {
    if (isRoot) return this;
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
