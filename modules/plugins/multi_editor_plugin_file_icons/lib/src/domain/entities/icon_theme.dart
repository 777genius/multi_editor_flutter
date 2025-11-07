import 'package:freezed_annotation/freezed_annotation.dart';

part 'icon_theme.freezed.dart';

/// Domain aggregate representing an icon theme (e.g., vscode-icons, material-icons).
///
/// In DDD, this is an aggregate root that encapsulates a collection of icons.
@freezed
sealed class IconTheme with _$IconTheme {
  const IconTheme._();

  const factory IconTheme({
    /// Unique theme identifier
    required String id,

    /// Human-readable theme name
    required String name,

    /// Theme provider (e.g., "iconify", "vscode", "material")
    required String provider,

    /// Base CDN URL for this theme's icons
    required String baseUrl,

    /// Priority for icon selection (lower = higher priority)
    @Default(100) int priority,

    /// Whether this theme is currently active
    @Default(false) bool isActive,

    /// Supported file extensions for this theme
    @Default([]) List<String> supportedExtensions,

    /// Theme metadata (version, author, etc.)
    @Default({}) Map<String, dynamic> metadata,
  }) = _IconTheme;

  /// Check if this theme supports a given file extension
  bool supportsExtension(String extension) {
    // Empty list means supports all extensions
    if (supportedExtensions.isEmpty) return true;
    return supportedExtensions.contains(extension.toLowerCase());
  }

  /// Get icon URL for a specific file extension
  String getIconUrl(String extension) {
    // Different providers have different URL patterns
    return switch (provider) {
      'iconify' => '$baseUrl/vscode-icons:file-type-$extension.svg',
      'vscode' => '$baseUrl/icons/file_type_$extension.svg',
      'material' => '$baseUrl/icons/$extension.svg',
      _ => '$baseUrl/$extension.svg',
    };
  }
}
