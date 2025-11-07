import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_icons_config.freezed.dart';

/// Configuration for File Icons Plugin.
@freezed
sealed class FileIconsConfig with _$FileIconsConfig {
  const factory FileIconsConfig({
    /// Default icon theme to use
    @Default('iconify-vscode') String defaultTheme,

    /// Maximum number of icons to cache in memory
    @Default(100) int maxCacheSize,

    /// Enable fallback to default icons when custom icons fail
    @Default(true) bool enableFallback,

    /// Icon size in logical pixels
    @Default(18) int iconSize,

    /// Priority for this plugin's icons (lower = higher priority)
    @Default(50) int priority,
  }) = _FileIconsConfig;
}
