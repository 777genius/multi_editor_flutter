import '../failures/domain_failure.dart';
import 'file_name.dart';

class FileContent {
  final String value;

  static const int maxSizeInBytes = 10 * 1024 * 1024;

  FileContent._(this.value);

  static Either<DomainFailure, FileContent> create(String input) {
    final sizeInBytes = input.length;

    if (sizeInBytes > maxSizeInBytes) {
      return Left(
        DomainFailure.validationError(
          field: 'fileContent',
          reason: 'File content exceeds maximum size of ${maxSizeInBytes ~/ 1024 ~/ 1024}MB',
          value: '${sizeInBytes ~/ 1024}KB',
        ),
      );
    }

    return Right(FileContent._(input));
  }

  bool get isEmpty => value.trim().isEmpty;

  bool get isNotEmpty => !isEmpty;

  int get sizeInBytes => value.length;

  int get sizeInKilobytes => sizeInBytes ~/ 1024;

  int get lineCount => value.split('\n').length;

  String get preview {
    const maxPreviewLength = 100;
    if (value.length <= maxPreviewLength) return value;
    return '${value.substring(0, maxPreviewLength)}...';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileContent &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
