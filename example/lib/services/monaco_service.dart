import 'package:flutter_monaco_crossplatform/flutter_monaco.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';

/// Service that provides access to MonacoController
/// The controller is set dynamically when a file is opened
class MonacoService implements EditorService {
  MonacoController? _controller;

  /// Get the current MonacoController if available
  MonacoController? get controller => _controller;

  /// Check if Monaco is currently available
  @override
  bool get isAvailable => _controller != null;

  /// Set the current MonacoController
  void setController(MonacoController? controller) {
    _controller = controller;
  }

  /// Register snippets with Monaco if available
  @override
  Future<void> registerSnippets(
    String languageId,
    List<dynamic> snippets,
  ) async {
    if (_controller == null) {
      throw StateError('MonacoController not available');
    }
    await _controller!.registerSnippets(languageId, snippets);
  }

  @override
  void dispose() {
    _controller = null;
  }
}
