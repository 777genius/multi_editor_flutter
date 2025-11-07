import 'package:flutter/material.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';

/// Factory for building UI widgets from PluginUIDescriptor.
///
/// ## Architecture:
/// - Belongs to presentation layer
/// - Interprets domain data (PluginUIDescriptor) into UI widgets
/// - Decouples domain from UI framework
///
/// ## Supported UI Types:
/// - **list**: Displays a list of items with title/subtitle/icon
/// - **custom**: For future extensibility
///
/// ## Example uiData structures:
///
/// List:
/// ```json
/// {
///   "type": "list",
///   "items": [
///     {
///       "id": "file1",
///       "title": "main.dart",
///       "subtitle": "lib/",
///       "iconCode": 0xe24d,
///       "onTap": "openFile"
///     }
///   ]
/// }
/// ```
class PluginUIBuilder {
  /// Build a widget from a PluginUIDescriptor
  ///
  /// [descriptor] - The UI descriptor from the plugin
  /// [onItemAction] - Callback when user interacts with an item
  static Widget build(
    PluginUIDescriptor descriptor, {
    required Function(String action, Map<String, dynamic> data) onItemAction,
  }) {
    final type = descriptor.uiData['type'] as String?;

    switch (type) {
      case 'list':
        return _buildList(descriptor, onItemAction);
      case 'custom':
        return _buildCustom(descriptor, onItemAction);
      default:
        return _buildError('Unknown UI type: $type');
    }
  }

  /// Build a list UI
  static Widget _buildList(
    PluginUIDescriptor descriptor,
    Function(String action, Map<String, dynamic> data) onItemAction,
  ) {
    final items = descriptor.uiData['items'] as List<dynamic>? ?? [];

    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No items', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index] as Map<String, dynamic>;
        return _buildListItem(context, item, onItemAction);
      },
    );
  }

  /// Build a single list item with hover effect
  static Widget _buildListItem(
    BuildContext context,
    Map<String, dynamic> item,
    Function(String action, Map<String, dynamic> data) onItemAction,
  ) {
    final title = item['title'] as String? ?? '';
    final subtitle = item['subtitle'] as String?;
    final iconCode = item['iconCode'] as int?;
    final action = item['onTap'] as String? ?? 'select';
    final id = item['id'] as String? ?? '';

    return _HoverListTile(
      leading: iconCode != null
          ? Icon(IconData(iconCode, fontFamily: 'MaterialIcons'))
          : const Icon(Icons.insert_drive_file),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      onTap: () {
        onItemAction(action, {'id': id, ...item});
      },
    );
  }

  /// Build custom UI (placeholder for extensibility)
  static Widget _buildCustom(
    PluginUIDescriptor descriptor,
    Function(String action, Map<String, dynamic> data) onItemAction,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Custom UI type not yet implemented',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  /// Build error message
  static Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(message, style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}

/// List tile with hover effect
class _HoverListTile extends StatefulWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final VoidCallback? onTap;

  const _HoverListTile({this.leading, this.title, this.subtitle, this.onTap});

  @override
  State<_HoverListTile> createState() => _HoverListTileState();
}

class _HoverListTileState extends State<_HoverListTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = _isHovered
        ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        color: backgroundColor,
        child: ListTile(
          leading: widget.leading,
          title: widget.title,
          subtitle: widget.subtitle,
          onTap: widget.onTap,
          dense: true,
        ),
      ),
    );
  }
}
