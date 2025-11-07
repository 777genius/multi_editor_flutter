import 'package:flutter/material.dart';
import 'tokens/primitive/color_primitives.dart';

/// Custom theme extension for editor-specific colors.
/// Extends Flutter's ThemeExtension to provide additional colors
/// that are not part of the standard Material Design palette.
@immutable
class EditorThemeExtension extends ThemeExtension<EditorThemeExtension> {
  const EditorThemeExtension({
    required this.fileTreeHoverBackground,
    required this.fileTreeSelectionBackground,
    required this.fileTreeSelectionHoverBackground,
    required this.fileTreeBorder,
  });

  // File tree colors
  final Color fileTreeHoverBackground;
  final Color fileTreeSelectionBackground;
  final Color fileTreeSelectionHoverBackground;
  final Color fileTreeBorder;

  /// Light theme extension
  static const light = EditorThemeExtension(
    fileTreeHoverBackground: ColorPrimitives.gray95,
    fileTreeSelectionBackground: Color(0xFFE3F2FD),
    fileTreeSelectionHoverBackground: Color(0xFFBBDEFB),
    fileTreeBorder: ColorPrimitives.gray90,
  );

  /// Dark theme extension
  static const dark = EditorThemeExtension(
    fileTreeHoverBackground: ColorPrimitives.gray30,
    fileTreeSelectionBackground: ColorPrimitives.gray40,
    fileTreeSelectionHoverBackground: ColorPrimitives.gray50,
    fileTreeBorder: ColorPrimitives.gray40,
  );

  @override
  ThemeExtension<EditorThemeExtension> copyWith({
    Color? fileTreeHoverBackground,
    Color? fileTreeSelectionBackground,
    Color? fileTreeSelectionHoverBackground,
    Color? fileTreeBorder,
  }) {
    return EditorThemeExtension(
      fileTreeHoverBackground:
          fileTreeHoverBackground ?? this.fileTreeHoverBackground,
      fileTreeSelectionBackground:
          fileTreeSelectionBackground ?? this.fileTreeSelectionBackground,
      fileTreeSelectionHoverBackground: fileTreeSelectionHoverBackground ??
          this.fileTreeSelectionHoverBackground,
      fileTreeBorder: fileTreeBorder ?? this.fileTreeBorder,
    );
  }

  @override
  ThemeExtension<EditorThemeExtension> lerp(
    covariant ThemeExtension<EditorThemeExtension>? other,
    double t,
  ) {
    if (other is! EditorThemeExtension) {
      return this;
    }

    return EditorThemeExtension(
      fileTreeHoverBackground: Color.lerp(
        fileTreeHoverBackground,
        other.fileTreeHoverBackground,
        t,
      )!,
      fileTreeSelectionBackground: Color.lerp(
        fileTreeSelectionBackground,
        other.fileTreeSelectionBackground,
        t,
      )!,
      fileTreeSelectionHoverBackground: Color.lerp(
        fileTreeSelectionHoverBackground,
        other.fileTreeSelectionHoverBackground,
        t,
      )!,
      fileTreeBorder: Color.lerp(
        fileTreeBorder,
        other.fileTreeBorder,
        t,
      )!,
    );
  }
}

/// Extension to easily access EditorThemeExtension from BuildContext
extension EditorThemeExtensionGetter on BuildContext {
  EditorThemeExtension get editorTheme =>
      Theme.of(this).extension<EditorThemeExtension>() ??
      EditorThemeExtension.light;
}
