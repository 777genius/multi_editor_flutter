import 'package:flutter/material.dart';
import '../tokens/primitive/color_primitives.dart';

/// Programming language colors enum.
///
/// Provides type-safe access to language-specific colors
/// and display names.
enum ProgrammingLanguage {
  dart(ColorPrimitives.dartBlue, 'Dart'),
  javaScript(ColorPrimitives.javaScriptYellow, 'JavaScript'),
  typeScript(ColorPrimitives.typeScriptBlue, 'TypeScript'),
  python(ColorPrimitives.pythonGreen, 'Python'),
  json(ColorPrimitives.orange50, 'JSON'),
  markdown(ColorPrimitives.purple50, 'Markdown'),
  html(ColorPrimitives.htmlOrange, 'HTML'),
  css(ColorPrimitives.cssBlue, 'CSS'),
  scss(ColorPrimitives.cssBlue, 'SCSS'),
  yaml(ColorPrimitives.gray60, 'YAML'),
  yml(ColorPrimitives.gray60, 'YML'),
  unknown(ColorPrimitives.gray60, 'Unknown');

  const ProgrammingLanguage(this.color, this.displayName);

  final Color color;
  final String displayName;

  /// Get language enum from string identifier
  static ProgrammingLanguage fromString(String? language) {
    if (language == null) return unknown;

    return ProgrammingLanguage.values.firstWhere(
      (e) => e.name.toLowerCase() == language.toLowerCase(),
      orElse: () => unknown,
    );
  }

  /// Get language icon based on language type
  IconData getIcon() {
    return switch (this) {
      dart || javaScript || typeScript || python => Icons.code,
      json => Icons.data_object,
      markdown => Icons.description,
      html => Icons.html,
      css || scss => Icons.css,
      yaml || yml => Icons.settings,
      unknown => Icons.insert_drive_file,
    };
  }
}
