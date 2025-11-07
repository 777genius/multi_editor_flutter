/// Value object describing a plugin's UI presentation.
///
/// This is a pure domain object with NO Flutter dependencies.
/// It describes WHAT to display, not HOW to display it.
///
/// ## Clean Architecture:
/// - Domain layer: defines the structure
/// - Presentation layer: renders based on this structure
///
/// ## Example:
/// ```dart
/// PluginUIDescriptor(
///   pluginId: 'plugin.recent-files',
///   iconCode: 0xe3a8, // Icons.history.codePoint
///   iconFamily: 'MaterialIcons',
///   tooltip: 'Recent Files',
///   label: 'Recent',
///   uiData: {
///     'type': 'list',
///     'items': [
///       {'id': '1', 'title': 'file.dart', 'subtitle': 'src/'},
///     ],
///   },
/// )
/// ```
class PluginUIDescriptor {
  /// Unique plugin identifier
  final String pluginId;

  /// Icon code point (from IconData.codePoint)
  final int iconCode;

  /// Icon font family (from IconData.fontFamily)
  final String? iconFamily;

  /// Tooltip text shown on hover
  final String tooltip;

  /// Optional label text shown next to icon
  final String? label;

  /// Structured data describing the UI content
  ///
  /// This is framework-agnostic. The presentation layer
  /// interprets this data to build actual widgets.
  ///
  /// Common structures:
  /// - List: `{'type': 'list', 'items': [...]}`
  /// - Grid: `{'type': 'grid', 'items': [...]}`
  /// - Custom: `{'type': 'custom', 'data': {...}}`
  final Map<String, dynamic> uiData;

  /// Priority for ordering in UI (lower = higher priority)
  final int priority;

  const PluginUIDescriptor({
    required this.pluginId,
    required this.iconCode,
    this.iconFamily,
    required this.tooltip,
    this.label,
    required this.uiData,
    this.priority = 100,
  });

  /// Copy with modifications
  PluginUIDescriptor copyWith({
    String? pluginId,
    int? iconCode,
    String? iconFamily,
    String? tooltip,
    String? label,
    Map<String, dynamic>? uiData,
    int? priority,
  }) {
    return PluginUIDescriptor(
      pluginId: pluginId ?? this.pluginId,
      iconCode: iconCode ?? this.iconCode,
      iconFamily: iconFamily ?? this.iconFamily,
      tooltip: tooltip ?? this.tooltip,
      label: label ?? this.label,
      uiData: uiData ?? this.uiData,
      priority: priority ?? this.priority,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PluginUIDescriptor &&
          runtimeType == other.runtimeType &&
          pluginId == other.pluginId;

  @override
  int get hashCode => pluginId.hashCode;

  @override
  String toString() => 'PluginUIDescriptor($pluginId, tooltip: $tooltip)';
}
