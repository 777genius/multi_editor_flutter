/// Abstract interface for editor services that plugins can use
/// This provides a type-safe way for plugins to interact with the editor
/// without depending on specific implementations like MonacoEditor
abstract class EditorService {
  /// Check if the editor service is currently available
  bool get isAvailable;

  /// Register code snippets for a specific language
  ///
  /// [languageId] - The language identifier (e.g., 'dart', 'javascript')
  /// [snippets] - List of snippet definitions
  Future<void> registerSnippets(String languageId, List<dynamic> snippets);

  /// Optional: Dispose resources when service is no longer needed
  void dispose() {}
}
