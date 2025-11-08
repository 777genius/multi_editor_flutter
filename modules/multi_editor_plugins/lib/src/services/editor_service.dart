/// Abstract interface for editor services that plugins can use
/// This provides a type-safe way for plugins to interact with the editor
/// without depending on specific implementations like MonacoEditor
abstract class EditorService {
  /// Check if the editor service is currently available
  bool get isAvailable;

  // Note: registerSnippets method removed in v0.1.1
  // Snippets registration moved to Monaco's completion API
  // See flutter_monaco_crossplatform documentation for new approach

  /// Optional: Dispose resources when service is no longer needed
  void dispose() {}
}
