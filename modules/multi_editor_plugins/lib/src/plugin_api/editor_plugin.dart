import 'package:multi_editor_core/multi_editor_core.dart';
import 'plugin_context.dart';
import 'plugin_manifest.dart';
import 'plugin_config_schema.dart';
import '../ui/plugin_ui_descriptor.dart';
import '../ui/file_icon_descriptor.dart';

/// Base interface for editor plugins.
///
/// ## Clean Architecture:
/// This is a pure domain interface with NO UI framework dependencies.
/// Plugins focus on business logic, not presentation.
///
/// ## UI Registration:
/// Plugins that need UI should:
/// 1. Override `getUIDescriptor()` to describe their UI
/// 2. Register UI in `initialize()` via `PluginUIService`
///
/// Example:
/// ```dart
/// @override
/// PluginUIDescriptor? getUIDescriptor() {
///   return PluginUIDescriptor(
///     pluginId: manifest.id,
///     iconCode: 0xe3a8, // Icons.history
///     tooltip: 'Recent Files',
///     uiData: {'type': 'list', 'items': [...]},
///   );
/// }
///
/// @override
/// Future<void> initialize(PluginContext context) async {
///   final uiService = context.getService<PluginUIService>();
///   final descriptor = getUIDescriptor();
///   if (descriptor != null && uiService != null) {
///     uiService.registerUI(descriptor);
///   }
/// }
/// ```
abstract class EditorPlugin {
  PluginManifest get manifest;

  /// Optional configuration schema for this plugin
  PluginConfigSchema? get configSchema => null;

  Future<void> initialize(PluginContext context);

  Future<void> dispose();

  // ============================================================================
  // File Lifecycle Events
  // ============================================================================

  void onFileOpen(FileDocument file) {}

  void onFileClose(String fileId) {}

  void onFileSave(FileDocument file) {}

  void onFileContentChange(String fileId, String content) {}

  void onFileCreate(FileDocument file) {}

  void onFileDelete(String fileId) {}

  // ============================================================================
  // Folder Lifecycle Events
  // ============================================================================

  void onFolderCreate(Folder folder) {}

  void onFolderDelete(String folderId) {}

  // ============================================================================
  // Language Support
  // ============================================================================

  List<String> getSupportedLanguages() => [];

  bool supportsLanguage(String language) =>
      getSupportedLanguages().isEmpty ||
      getSupportedLanguages().contains(language);

  // ============================================================================
  // UI Descriptor (Clean Architecture approach)
  // ============================================================================

  /// Get the UI descriptor for this plugin.
  ///
  /// Return null if this plugin has no UI.
  /// Return a PluginUIDescriptor to register UI in the editor.
  ///
  /// The descriptor is framework-agnostic and describes WHAT to display,
  /// not HOW to display it. The presentation layer handles rendering.
  PluginUIDescriptor? getUIDescriptor() => null;

  // ============================================================================
  // File Icon Extension (Clean Architecture approach)
  // ============================================================================

  /// Get the icon descriptor for a file tree node.
  ///
  /// Return null if this plugin doesn't provide custom icons.
  /// Return a FileIconDescriptor to customize file/folder icons.
  ///
  /// The descriptor is framework-agnostic and describes WHAT icon to display,
  /// not HOW to display it. The presentation layer handles rendering.
  ///
  /// ## Priority:
  /// If multiple plugins provide icons for the same file, the one with
  /// the lowest priority value wins (default: 100).
  ///
  /// ## Example:
  /// ```dart
  /// @override
  /// FileIconDescriptor? getFileIconDescriptor(FileTreeNode node) {
  ///   if (node.type == FileTreeNodeType.file) {
  ///     final extension = _getExtension(node.name);
  ///     final iconUrl = _resolveIconUrl(extension);
  ///     return FileIconDescriptor.url(
  ///       url: iconUrl,
  ///       pluginId: manifest.id,
  ///       priority: 50,
  ///     );
  ///   }
  ///   return null;
  /// }
  /// ```
  FileIconDescriptor? getFileIconDescriptor(FileTreeNode node) => null;
}
