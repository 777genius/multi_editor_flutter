import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_uri.freezed.dart';

/// Represents a document URI.
/// Platform-agnostic - used for LSP, file system, virtual documents, etc.
@freezed
class DocumentUri with _$DocumentUri {
  const factory DocumentUri(String value) = _DocumentUri;

  const DocumentUri._();

  /// Creates a URI from a file path
  factory DocumentUri.fromFilePath(String path) {
    // Normalize path separators
    final normalized = path.replaceAll('\\', '/');

    // Ensure it starts with file://
    if (normalized.startsWith('file://')) {
      return DocumentUri(normalized);
    }

    // Add file:// prefix
    final withoutLeadingSlash = normalized.startsWith('/')
        ? normalized.substring(1)
        : normalized;
    return DocumentUri('file:///$withoutLeadingSlash');
  }

  /// Converts URI to file path
  String toFilePath() {
    return value.replaceFirst('file:///', '');
  }

  /// Gets the file path (alias for toFilePath())
  String get path => toFilePath();

  /// Gets the file name from the URI
  String get fileName {
    final path = toFilePath();
    final parts = path.split('/');
    return parts.isEmpty ? '' : parts.last;
  }

  /// Gets the directory path from the URI
  String get directoryPath {
    final path = toFilePath();
    final lastSlash = path.lastIndexOf('/');
    return lastSlash == -1 ? '' : path.substring(0, lastSlash);
  }

  /// Gets the file extension
  String get extension {
    final name = fileName;
    final lastDot = name.lastIndexOf('.');
    return lastDot == -1 ? '' : name.substring(lastDot + 1);
  }
}
