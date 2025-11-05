import 'package:flutter/material.dart';
import 'package:editor_core/editor_core.dart';
import '../../../theme/colors/language_colors.dart';
import '../../../controllers/file_tree_controller.dart';
import 'file_tree_item_with_hover.dart';

class FileTreeFileItem extends StatelessWidget {
  final FileTreeNode data;
  final bool isSelected;
  final bool enableDragDrop;
  final FileTreeController controller;
  final void Function(BuildContext context, Offset position, FileTreeNode data)
      onShowContextMenu;

  const FileTreeFileItem({
    super.key,
    required this.data,
    required this.isSelected,
    required this.enableDragDrop,
    required this.controller,
    required this.onShowContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    final widget = FileTreeItemWithHover(
      isSelected: isSelected,
      onSecondaryTap: (details) => onShowContextMenu(
        context,
        details.globalPosition,
        data,
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        leading: Icon(
          _getFileIcon(data.language),
          size: 18,
          color: _getFileColor(context, data.language),
        ),
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
            color:
                isHovered
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                    : null,
            child: widget,
          ),
        );
      },
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
