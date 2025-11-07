import 'package:freezed_annotation/freezed_annotation.dart';
import '../value_objects/icon_url.dart';

part 'file_icon.freezed.dart';

/// Domain entity representing a file icon.
///
/// This is a value object in DDD terms - immutable and contains no logic.
/// Business logic belongs in domain services or use cases.
@freezed
sealed class FileIcon with _$FileIcon {
  const FileIcon._();

  const factory FileIcon({
    /// URL to the icon image (CDN)
    required IconUrl url,

    /// File extension this icon represents (e.g., "dart", "json")
    required String extension,

    /// Icon theme ID (e.g., "vscode-icons", "material-icons")
    required String themeId,

    /// Icon format (e.g., "svg", "png")
    @Default('svg') String format,

    /// Icon size in pixels
    @Default(18) int size,

    /// Whether this icon has been successfully loaded
    @Default(false) bool isLoaded,

    /// Error message if loading failed
    String? errorMessage,
  }) = _FileIcon;

  /// Check if icon is available for use
  bool get isAvailable => isLoaded && errorMessage == null;

  /// Check if icon loading failed
  bool get hasFailed => errorMessage != null;
}
