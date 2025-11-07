import 'package:flutter/material.dart';
import 'systems/app_spacing.dart';
import 'systems/app_radius.dart';
import 'systems/app_elevation.dart';
import 'systems/app_icon_size.dart';
import 'tokens/primitive/font_primitives.dart';
import 'editor_theme_extension.dart';

/// Professional theme configuration for the code editor application.
/// Follows Flutter best practices 2025 and Material Design 3 principles.
///
/// Uses ColorScheme.fromSeed() for harmonious color generation,
/// eliminates code duplication, and leverages design tokens throughout.
class AppThemeData {
  AppThemeData._();

  /// Light theme configuration
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0066CC),
      brightness: Brightness.light,
    );

    return _buildTheme(colorScheme, EditorThemeExtension.light);
  }

  /// Dark theme configuration
  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4D9FFF),
      brightness: Brightness.dark,
    );

    return _buildTheme(colorScheme, EditorThemeExtension.dark);
  }

  /// Build theme from color scheme (eliminates duplication)
  static ThemeData _buildTheme(
    ColorScheme colorScheme,
    EditorThemeExtension editorExtension,
  ) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: colorScheme.brightness,

      // Typography
      textTheme: _buildTextTheme(colorScheme),

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.onSurface,
        elevation: AppElevation.none,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: FontPrimitives.fontSize16,
          fontWeight: FontPrimitives.fontWeightMedium,
        ),
      ),

      // Icon theme
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: AppIconSize.s,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 1,
        space: 1,
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: AppElevation.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.l),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.m,
        ),
      ),

      // List tile theme
      listTileTheme: const ListTileThemeData(
        dense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.s,
          vertical: AppSpacing.xxs,
        ),
      ),

      // Popup menu theme
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surface,
        elevation: AppElevation.l,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),

      // Tooltip theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppRadius.s),
        ),
        textStyle: TextStyle(
          color: colorScheme.surface,
          fontSize: FontPrimitives.fontSize12,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s,
          vertical: AppSpacing.xs,
        ),
      ),

      // Custom theme extension
      extensions: <ThemeExtension<dynamic>>[editorExtension],
    );
  }

  /// Build text theme with proper typography scale
  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: FontPrimitives.fontSize32,
        fontWeight: FontPrimitives.fontWeightSemiBold,
        color: colorScheme.onSurface,
      ),
      displayMedium: TextStyle(
        fontSize: FontPrimitives.fontSize28,
        fontWeight: FontPrimitives.fontWeightSemiBold,
        color: colorScheme.onSurface,
      ),
      displaySmall: TextStyle(
        fontSize: FontPrimitives.fontSize24,
        fontWeight: FontPrimitives.fontWeightSemiBold,
        color: colorScheme.onSurface,
      ),
      headlineLarge: TextStyle(
        fontSize: FontPrimitives.fontSize20,
        fontWeight: FontPrimitives.fontWeightMedium,
        color: colorScheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: FontPrimitives.fontSize18,
        fontWeight: FontPrimitives.fontWeightMedium,
        color: colorScheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: FontPrimitives.fontSize16,
        fontWeight: FontPrimitives.fontWeightMedium,
        color: colorScheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: FontPrimitives.fontSize16,
        fontWeight: FontPrimitives.fontWeightMedium,
        color: colorScheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: FontPrimitives.fontSize14,
        fontWeight: FontPrimitives.fontWeightMedium,
        color: colorScheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: FontPrimitives.fontSize12,
        fontWeight: FontPrimitives.fontWeightMedium,
        color: colorScheme.onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: FontPrimitives.fontSize14,
        fontWeight: FontPrimitives.fontWeightRegular,
        color: colorScheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: FontPrimitives.fontSize13,
        fontWeight: FontPrimitives.fontWeightRegular,
        color: colorScheme.onSurface,
      ),
      bodySmall: TextStyle(
        fontSize: FontPrimitives.fontSize12,
        fontWeight: FontPrimitives.fontWeightRegular,
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontSize: FontPrimitives.fontSize14,
        fontWeight: FontPrimitives.fontWeightMedium,
        color: colorScheme.onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: FontPrimitives.fontSize12,
        fontWeight: FontPrimitives.fontWeightMedium,
        color: colorScheme.onSurface,
      ),
      labelSmall: TextStyle(
        fontSize: FontPrimitives.fontSize11,
        fontWeight: FontPrimitives.fontWeightMedium,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
