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
    return copyWith(
      content: newContent,
      updatedAt: DateTime.now(),
    );
  }

  FileDocument rename(String newName) {
    return copyWith(
      name: newName,
      updatedAt: DateTime.now(),
    );
  }

  FileDocument move(String targetFolderId) {
    return copyWith(
      folderId: targetFolderId,
      updatedAt: DateTime.now(),
    );
  }

  bool get isEmpty => content.trim().isEmpty;

  int get sizeInBytes => content.length;

  String get extension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last : '';
  }
}
