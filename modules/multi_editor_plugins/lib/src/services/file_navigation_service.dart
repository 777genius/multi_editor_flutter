/// Abstract interface for file navigation that plugins can use.
///
/// This provides a type-safe way for plugins to request file opening
/// without depending on specific implementations like EditorController.
///
/// ## Architecture:
/// - Follows Dependency Inversion Principle (SOLID)
/// - Plugins depend on this abstraction, not concrete implementation
/// - EditorScaffold provides concrete implementation
///
/// ## Usage in plugins:
/// ```dart
/// final navigation = context.getService<FileNavigationService>();
/// if (navigation != null) {
///   await navigation.openFile(fileId);
/// }
/// ```
abstract class FileNavigationService {
  /// Open a file by its ID
  ///
  /// [fileId] - The unique identifier of the file to open
  /// Returns a Future that completes when the file is loaded
  Future<void> openFile(String fileId);

  /// Check if the navigation service is currently available
  bool get isAvailable;
}
