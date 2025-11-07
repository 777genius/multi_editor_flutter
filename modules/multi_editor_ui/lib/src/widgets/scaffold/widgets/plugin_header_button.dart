import 'package:flutter/material.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import '../../../plugins/plugin_ui_builder.dart';

/// Header button for a plugin that shows a popup on click.
///
/// ## Architecture:
/// - Presentation layer component
/// - Takes domain object (PluginUIDescriptor) and renders it
/// - Shows popup dialog with plugin content on click
///
/// ## Example:
/// ```dart
/// PluginHeaderButton(
///   descriptor: recentFilesDescriptor,
///   onItemAction: (action, data) {
///     if (action == 'openFile') {
///       openFile(data['id']);
///     }
///   },
/// )
/// ```
class PluginHeaderButton extends StatelessWidget {
  final PluginUIDescriptor descriptor;
  final Function(String action, Map<String, dynamic> data) onItemAction;

  const PluginHeaderButton({
    super.key,
    required this.descriptor,
    required this.onItemAction,
  });

  @override
  Widget build(BuildContext context) {
    final icon = IconData(
      descriptor.iconCode,
      fontFamily: descriptor.iconFamily ?? 'MaterialIcons',
    );

    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: descriptor.tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () => _showPluginPopup(context),
    );
  }

  void _showPluginPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      IconData(
                        descriptor.iconCode,
                        fontFamily: descriptor.iconFamily ?? 'MaterialIcons',
                      ),
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        descriptor.tooltip,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              // Content
              Flexible(
                child: PluginUIBuilder.build(
                  descriptor,
                  onItemAction: (action, data) {
                    Navigator.of(context).pop(); // Close dialog
                    onItemAction(action, data); // Execute action
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
