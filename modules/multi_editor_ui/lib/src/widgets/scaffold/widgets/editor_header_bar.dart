import 'package:flutter/material.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import 'plugin_header_button.dart';
import '../../file_tree/widgets/file_icon_widget.dart';

class EditorHeaderBar extends StatelessWidget {
  final FileDocument file;
  final bool isDirty;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onClose;
  final PluginUIService? pluginUIService;
  final PluginManager? pluginManager;
  final Function(String action, Map<String, dynamic> data)? onPluginAction;

  const EditorHeaderBar({
    super.key,
    required this.file,
    required this.isDirty,
    required this.isSaving,
    required this.onSave,
    required this.onClose,
    this.pluginUIService,
    this.pluginManager,
    this.onPluginAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildFileIcon(context),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              file.name,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          // Plugin buttons
          if (pluginUIService != null) ..._buildPluginButtons(),
          if (isDirty) ...[
            Text(
              'Modified',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (isSaving)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (isDirty)
            IconButton(
              icon: const Icon(Icons.save, size: 18),
              tooltip: 'Save (Ctrl+S)',
              onPressed: onSave,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Close',
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// Build file icon with plugin support
  Widget _buildFileIcon(BuildContext context) {
    // Try to get icon from plugins
    if (pluginManager != null) {
      final descriptor = pluginManager!.getFileIconDescriptorByName(file.name);
      if (descriptor != null) {
        return FileIconWidget(
          descriptor: descriptor,
          fallback: _buildDefaultIcon(context),
        );
      }
    }

    // Fallback to default icon
    return _buildDefaultIcon(context);
  }

  /// Build default file icon
  Widget _buildDefaultIcon(BuildContext context) {
    return Icon(
      Icons.insert_drive_file,
      size: 16,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
    );
  }

  /// Build plugin buttons from registered UIs
  List<Widget> _buildPluginButtons() {
    if (pluginUIService == null) return [];

    final descriptors = pluginUIService!.getRegisteredUIs();

    return descriptors.map((descriptor) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: PluginHeaderButton(
          descriptor: descriptor,
          onItemAction: onPluginAction ?? (action, data) {},
        ),
      );
    }).toList();
  }
}
