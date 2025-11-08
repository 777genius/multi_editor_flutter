import 'package:freezed_annotation/freezed_annotation.dart';
import '../value_objects/language_id.dart';
import '../value_objects/document_uri.dart';

part 'editor_document.freezed.dart';

/// Represents a document in the code editor.
/// This is platform-agnostic and doesn't depend on any specific editor implementation.
@freezed
class EditorDocument with _$EditorDocument {
  const factory EditorDocument({
    required DocumentUri uri,
    required String content,
    required LanguageId languageId,
    required DateTime lastModified,
    @Default(false) bool isDirty,
    @Default(false) bool isReadOnly,
  }) = _EditorDocument;

  const EditorDocument._();

  /// Creates a new document with updated content
  EditorDocument updateContent(String newContent) {
    return copyWith(
      content: newContent,
      lastModified: DateTime.now(),
      isDirty: true,
    );
  }

  /// Marks the document as saved
  EditorDocument markAsSaved() {
    return copyWith(
      isDirty: false,
      lastModified: DateTime.now(),
    );
  }

  /// Gets the number of lines in the document
  /// Optimized to avoid allocating intermediate array
  int get lineCount {
    if (content.isEmpty) return 1;
    return '\n'.allMatches(content).length + 1;
  }

  /// Gets the number of characters in the document
  int get characterCount => content.length;
}
