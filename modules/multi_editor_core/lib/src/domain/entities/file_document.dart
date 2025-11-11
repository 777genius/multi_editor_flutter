import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_document.freezed.dart';
part 'file_document.g.dart';

@freezed
sealed class FileDocument with _$FileDocument {
  const FileDocument._();

  const factory FileDocument({
    required String id,
    required String name,
    required String folderId,
    required String content,
    required String language,
    required DateTime createdAt,
    required DateTime updatedAt,
    Map<String, dynamic>? metadata,
  }) = _FileDocument;

  factory FileDocument.fromJson(Map<String, dynamic> json) =>
      _$FileDocumentFromJson(json);

  FileDocument updateContent(String newContent) {
    return copyWith(content: newContent, updatedAt: DateTime.now());
  }

  FileDocument rename(String newName) {
    return copyWith(name: newName, updatedAt: DateTime.now());
  }

  FileDocument move(String targetFolderId) {
    return copyWith(folderId: targetFolderId, updatedAt: DateTime.now());
  }

  bool get isEmpty => content.trim().isEmpty;

  /// Get size in bytes (UTF-8 encoded)
  ///
  /// Note: String.length returns code units (UTF-16), not bytes.
  /// This method correctly calculates the UTF-8 byte size.
  int get sizeInBytes => utf8.encode(content).length;

  /// Get file extension
  ///
  /// Returns empty string for:
  /// - Files with no extension (e.g., "README")
  /// - Dotfiles without extension (e.g., ".gitignore", ".bashrc")
  ///
  /// Examples:
  /// - "main.dart" → "dart"
  /// - "archive.tar.gz" → "gz"
  /// - ".gitignore" → ""
  /// - ".zshrc" → ""
  /// - "README" → ""
  String get extension {
    // Handle dotfiles (files starting with . and no other dots)
    if (name.startsWith('.') && !name.substring(1).contains('.')) {
      return ''; // Dotfile without extension
    }

    final parts = name.split('.');
    return parts.length > 1 ? parts.last : '';
  }
}
