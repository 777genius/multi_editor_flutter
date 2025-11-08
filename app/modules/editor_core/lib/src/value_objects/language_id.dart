import 'package:freezed_annotation/freezed_annotation.dart';

part 'language_id.freezed.dart';

/// Represents a programming language identifier.
/// Platform-agnostic - can be mapped to Monaco languages, LSP languages, etc.
@freezed
class LanguageId with _$LanguageId {
  const factory LanguageId(String value) = _LanguageId;

  const LanguageId._();

  // Predefined language IDs
  static const dart = LanguageId('dart');
  static const javascript = LanguageId('javascript');
  static const typescript = LanguageId('typescript');
  static const python = LanguageId('python');
  static const rust = LanguageId('rust');
  static const go = LanguageId('go');
  static const java = LanguageId('java');
  static const kotlin = LanguageId('kotlin');
  static const swift = LanguageId('swift');
  static const c = LanguageId('c');
  static const cpp = LanguageId('cpp');
  static const csharp = LanguageId('csharp');
  static const ruby = LanguageId('ruby');
  static const php = LanguageId('php');
  static const html = LanguageId('html');
  static const css = LanguageId('css');
  static const scss = LanguageId('scss');
  static const json = LanguageId('json');
  static const xml = LanguageId('xml');
  static const yaml = LanguageId('yaml');
  static const markdown = LanguageId('markdown');
  static const sql = LanguageId('sql');
  static const shellscript = LanguageId('shellscript');
  static const plaintext = LanguageId('plaintext');

  /// Detects language from file extension
  static LanguageId fromFileExtension(String extension) {
    final normalized = extension.toLowerCase().replaceFirst('.', '');
    return switch (normalized) {
      'dart' => dart,
      'js' || 'mjs' || 'jsx' => javascript,
      'ts' || 'tsx' => typescript,
      'py' => python,
      'rs' => rust,
      'go' => go,
      'java' => java,
      'kt' || 'kts' => kotlin,
      'swift' => swift,
      'c' => c,
      'cpp' || 'cc' || 'cxx' || 'c++' || 'h' || 'hpp' => cpp,
      'cs' => csharp,
      'rb' => ruby,
      'php' => php,
      'html' || 'htm' => html,
      'css' => css,
      'scss' || 'sass' => scss,
      'json' => json,
      'xml' => xml,
      'yaml' || 'yml' => yaml,
      'md' || 'markdown' => markdown,
      'sql' => sql,
      'sh' || 'bash' => shellscript,
      _ => plaintext,
    };
  }

  /// Detects language from file name
  static LanguageId fromFileName(String fileName) {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      return fromFileExtension(parts.last);
    }
    return plaintext;
  }
}
