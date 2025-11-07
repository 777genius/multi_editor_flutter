/// Value object describing a file icon's presentation.
///
/// This is a pure domain object with NO Flutter dependencies.
/// It describes WHAT icon to display, not HOW to display it.
///
/// ## Clean Architecture:
/// - Domain layer: defines the structure (this class)
/// - Presentation layer: renders based on this structure
///
/// ## Icon Types:
/// - **URL**: Load icon from remote CDN (lazy loading)
/// - **Local**: Use bundled icon from assets
/// - **IconData**: Use Flutter IconData (code point + font family)
/// - **Default**: Let the UI decide (fallback to default icon)
///
/// ## Example:
/// ```dart
/// // CDN icon
/// FileIconDescriptor.url(
///   url: 'https://cdn.jsdelivr.net/npm/@vscode/codicons/icons/file-code.svg',
///   size: 18,
/// )
///
/// // Icon font
/// FileIconDescriptor.iconData(
///   iconCode: 0xe24d, // Icons.code.codePoint
///   iconFamily: 'MaterialIcons',
///   color: 0xFF42A5F5,
/// )
/// ```
class FileIconDescriptor {
  /// Type of icon source
  final FileIconType type;

  /// Icon URL for remote icons (when type == url)
  final String? url;

  /// Local asset path for bundled icons (when type == local)
  final String? assetPath;

  /// Icon code point for icon fonts (when type == iconData)
  final int? iconCode;

  /// Icon font family (when type == iconData)
  final String? iconFamily;

  /// Icon color (ARGB hex value, e.g., 0xFF42A5F5)
  final int? color;

  /// Icon size in logical pixels
  final double size;

  /// Priority for icon selection when multiple plugins provide icons
  /// Lower value = higher priority
  final int priority;

  /// Plugin ID that provided this icon
  final String pluginId;

  const FileIconDescriptor._({
    required this.type,
    this.url,
    this.assetPath,
    this.iconCode,
    this.iconFamily,
    this.color,
    this.size = 18.0,
    this.priority = 100,
    required this.pluginId,
  });

  /// Create icon descriptor for remote URL
  const FileIconDescriptor.url({
    required String url,
    double size = 18.0,
    int priority = 100,
    required String pluginId,
  }) : this._(
          type: FileIconType.url,
          url: url,
          size: size,
          priority: priority,
          pluginId: pluginId,
        );

  /// Create icon descriptor for local asset
  const FileIconDescriptor.asset({
    required String assetPath,
    double size = 18.0,
    int priority = 100,
    required String pluginId,
  }) : this._(
          type: FileIconType.local,
          assetPath: assetPath,
          size: size,
          priority: priority,
          pluginId: pluginId,
        );

  /// Create icon descriptor for icon font (IconData)
  const FileIconDescriptor.iconData({
    required int iconCode,
    String? iconFamily,
    int? color,
    double size = 18.0,
    int priority = 100,
    required String pluginId,
  }) : this._(
          type: FileIconType.iconData,
          iconCode: iconCode,
          iconFamily: iconFamily,
          color: color,
          size: size,
          priority: priority,
          pluginId: pluginId,
        );

  /// Create default icon descriptor (fallback to UI default)
  const FileIconDescriptor.defaultIcon({
    int priority = 999,
    required String pluginId,
  }) : this._(
          type: FileIconType.defaultIcon,
          priority: priority,
          pluginId: pluginId,
        );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileIconDescriptor &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          url == other.url &&
          assetPath == other.assetPath &&
          iconCode == other.iconCode &&
          iconFamily == other.iconFamily &&
          color == other.color &&
          size == other.size &&
          priority == other.priority &&
          pluginId == other.pluginId;

  @override
  int get hashCode => Object.hash(
        type,
        url,
        assetPath,
        iconCode,
        iconFamily,
        color,
        size,
        priority,
        pluginId,
      );

  @override
  String toString() {
    return 'FileIconDescriptor('
        'type: $type, '
        'pluginId: $pluginId, '
        'priority: $priority, '
        'size: $size'
        ')';
  }
}

/// Type of file icon source
enum FileIconType {
  /// Remote URL (CDN, lazy loading)
  url,

  /// Local asset bundled with app
  local,

  /// Icon font (MaterialIcons, custom font)
  iconData,

  /// Default icon (let UI decide)
  defaultIcon,
}
