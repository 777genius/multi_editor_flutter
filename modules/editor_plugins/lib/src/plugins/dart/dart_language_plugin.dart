import 'package:editor_core/editor_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../../plugin_api/language_plugin.dart';
import '../../plugin_api/plugin_context.dart';
import '../../plugin_api/plugin_manifest.dart';
import 'models/snippet_data.dart';
import 'snippets/dart_snippets.dart';

/// Language plugin providing Dart support.
///
/// Features:
/// - Syntax highlighting (via Monaco built-in)
/// - Bracket matching (via Monaco built-in)
/// - Code snippets (custom implementation)
/// - Word-based autocomplete (via Monaco built-in)
///
/// ## Usage:
/// ```dart
/// final dartPlugin = DartLanguagePlugin();
/// await pluginManager.registerPlugin(dartPlugin);
/// ```
class DartLanguagePlugin extends LanguagePlugin {
  DartLanguagePlugin();

  dynamic _monacoController;

  @override
  PluginManifest get manifest => const PluginManifest(
        id: 'dart-language-support',
        name: 'Dart Language Support',
        version: '1.0.0',
        description:
            'Syntax highlighting, snippets, and code completion for Dart',
        author: 'Multi-File Code Editor',
        capabilities: {
          'language': 'dart',
          'snippets': 'true',
          'syntax': 'true',
          'autocomplete': 'true',
        },
        activationEvents: ['onLanguage:dart'],
      );

  @override
  String get languageId => 'dart';

  @override
  List<String> get fileExtensions => ['.dart'];

  @override
  Future<void> initialize(PluginContext context) async {
    debugPrint('[DartPlugin] Initializing Dart language support...');

    // Note: MonacoController is not yet available in PluginContext
    // This will be added in a future update when EditorController
    // exposes MonacoController as a service
    // For now, snippets registration is skipped
    _monacoController = null;

    if (_monacoController == null) {
      debugPrint('[DartPlugin] Warning: MonacoController not found in context');
      debugPrint('[DartPlugin] Snippet registration will be skipped');
      return;
    }

    // Register snippets with Monaco
    final snippets = await provideSnippets();
    await _registerSnippets(snippets);

    debugPrint(
      '[DartPlugin] Initialized with ${snippets.length} snippets',
    );
  }

  @override
  Future<List<SnippetData>> provideSnippets() async {
    return DartSnippets.all;
  }

  Future<void> _registerSnippets(List<SnippetData> snippets) async {
    if (_monacoController == null) return;

    try {
      // Call MonacoController.registerSnippets()
      // This method will be added to MonacoController in the next step
      await (_monacoController as dynamic).registerSnippets(
        languageId,
        snippets,
      );
      debugPrint('[DartPlugin] Registered ${snippets.length} snippets');
    } catch (e) {
      debugPrint('[DartPlugin] Error registering snippets: $e');
    }
  }

  @override
  void onFileOpen(FileDocument file) {
    if (supportsLanguage(file.language)) {
      debugPrint('[DartPlugin] Dart file opened: ${file.name}');
    }
  }

  @override
  void onFileSave(FileDocument file) {
    if (supportsLanguage(file.language)) {
      debugPrint('[DartPlugin] Dart file saved: ${file.name}');
    }
  }

  @override
  Widget? buildToolbarAction(BuildContext context) {
    // Future enhancement: Add format button
    return null;
  }

  @override
  Future<void> dispose() async {
    debugPrint('[DartPlugin] Disposing Dart language support');
    _monacoController = null;
  }
}
