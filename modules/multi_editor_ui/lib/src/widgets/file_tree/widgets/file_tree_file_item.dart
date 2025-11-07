import 'package:flutter/material.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import '../../../theme/colors/language_colors.dart';
import '../../../controllers/file_tree_controller.dart';
import 'file_tree_item_with_hover.dart';
import 'file_icon_widget.dart';

class FileTreeFileItem extends StatelessWidget {
  final FileTreeNode data;
  final bool isSelected;
  final bool enableDragDrop;
  final FileTreeController controller;
  final PluginManager? pluginManager;
  final void Function(BuildContext context, Offset position, FileTreeNode data)
  onShowContextMenu;

  const FileTreeFileItem({
    super.key,
    required this.data,
    required this.isSelected,
    required this.enableDragDrop,
    required this.controller,
    this.pluginManager,
    required this.onShowContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    final widget = FileTreeItemWithHover(
      isSelected: isSelected,
      onSecondaryTap: (details) =>
          onShowContextMenu(context, details.globalPosition, data),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        leading: _buildFileIcon(context),
        title: Text(
          data.name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ),
    );

    if (!enableDragDrop) {
      return widget;
    }

    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        final dragData = details.data;

        final parts = dragData.split(':');
        if (parts.length != 2) return;

        final type = parts[0];
        final draggedId = parts[1];

        if (draggedId == data.id) return;

        if (data.parentId == null) return;

        if (type == 'file') {
          controller.moveFile(draggedId, data.parentId!);
        } else if (type == 'folder') {
          controller.moveFolder(draggedId, data.parentId!);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return Draggable<String>(
          data: 'file:${data.id}',
          feedback: Material(
            elevation: 4,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getFileIcon(data.language), size: 18),
                  const SizedBox(width: 8),
                  Text(data.name),
                ],
              ),
            ),
          ),
          child: Container(
            color: isHovered
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                : null,
            child: widget,
          ),
        );
      },
    );
  }

  /// Build file icon with plugin support
  Widget _buildFileIcon(BuildContext context) {
    // Try to get custom icon from plugins
    if (pluginManager != null) {
      final descriptor = pluginManager!.getFileIconDescriptor(data);
      if (descriptor != null) {
        // Use custom icon from plugin
        return FileIconWidget(
          descriptor: descriptor,
          fallback: _buildDefaultIcon(context),
        );
      }
    }

    // Fallback to default icon
    return _buildDefaultIcon(context);
  }

  /// Build default icon based on language
  Widget _buildDefaultIcon(BuildContext context) {
    return Icon(
      _getFileIcon(data.language),
      size: 18,
      color: _getFileColor(context, data.language),
    );
  }

  IconData _getFileIcon(String? language) {
    final lang = ProgrammingLanguage.fromString(language);
    return lang.getIcon();
  }

  Color _getFileColor(BuildContext context, String? language) {
    final lang = ProgrammingLanguage.fromString(language);
    return lang.color;
  }
}
