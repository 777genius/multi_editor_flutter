import 'editor_plugin.dart';
import 'snippet_data.dart';

/// Base class for language-specific editor plugins.
///
/// Extends [EditorPlugin] with language-specific capabilities like
/// snippets, code completion, diagnostics, and formatting.
///
/// ## Example:
/// ```dart
/// class DartLanguagePlugin extends LanguagePlugin {
///   @override
///   String get languageId => 'dart';
///
///   @override
///   List<String> get fileExtensions => ['.dart'];
///
///   @override
///   Future<List<SnippetData>> provideSnippets() async {
///     return DartSnippets.all;
///   }
/// }
/// ```
abstract class LanguagePlugin extends EditorPlugin {
  /// The unique language identifier (e.g., 'dart', 'javascript', 'python').
  ///
  /// This should match Monaco editor's language IDs.
  String get languageId;

  /// File extensions supported by this language (e.g., ['.dart', '.dart.js']).
  List<String> get fileExtensions;

  /// Provides code snippets for this language.
  ///
  /// Snippets are registered with Monaco editor when the plugin initializes.
  /// They appear in the autocomplete dropdown when the user types the prefix.
  Future<List<SnippetData>> provideSnippets();

  /// Returns the list of supported languages (defaults to [languageId]).
  @override
  List<String> getSupportedLanguages() => [languageId];

  /// Checks if a file extension is supported by this plugin.
  bool supportsFileExtension(String fileName) {
    return fileExtensions.any((ext) => fileName.endsWith(ext));
  }

  /// Checks if the language matches this plugin.
  @override
  bool supportsLanguage(String language) {
    return language.toLowerCase() == languageId.toLowerCase();
  }
}
