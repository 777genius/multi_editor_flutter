import '../entities/icon_theme.dart';

/// Repository interface for icon theme management.
///
/// Manages available icon themes and the currently active theme.
abstract class IconThemeRepository {
  /// Get all available icon themes.
  Future<List<IconTheme>> getAvailableThemes();

  /// Get the currently active theme.
  Future<IconTheme?> getActiveTheme();

  /// Set the active theme by ID.
  Future<void> setActiveTheme(String themeId);

  /// Get a specific theme by ID.
  Future<IconTheme?> getTheme(String themeId);

  /// Register a new theme.
  Future<void> registerTheme(IconTheme theme);

  /// Check if a theme exists.
  Future<bool> hasTheme(String themeId);
}
