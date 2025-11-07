import 'package:flutter/material.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import '../../../controllers/file_tree_controller.dart';
import '../../../state/file_tree_state.dart';
import 'folder_tile.dart';

class FileTreeFolderItem extends StatelessWidget {
  final FileTreeNode data;
  final bool isSelected;
  final bool enableDragDrop;
  final FileTreeController controller;
  final void Function(BuildContext context, Offset position, FileTreeNode data)
  onShowContextMenu;

  const FileTreeFolderItem({
    super.key,
    required this.data,
    required this.isSelected,
    required this.enableDragDrop,
    required this.controller,
    required this.onShowContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    if (!enableDragDrop) {
      return FolderTile(
        data: data,
        isSelected: isSelected,
        onShowContextMenu: onShowContextMenu,
      );
    }

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        final dragData = details.data;

        final parts = dragData.split(':');
        if (parts.length != 2) return false;

        final type = parts[0];
        final draggedId = parts[1];

        if (draggedId == data.id) return false;

        if (type == 'folder') {
          final rootNode = controller.value.maybeMap(
            loaded: (state) => state.rootNode,
            orElse: () => null,
          );

          if (rootNode == null) return false;

          final draggedNode = rootNode.findNode(draggedId);
          if (draggedNode == null) return false;

          if (draggedNode.findNode(data.id) != null) return false;
        }

        return true;
      },
      onAcceptWithDetails: (details) {
        final parts = details.data.split(':');
        final type = parts[0];
        final draggedId = parts[1];

        if (type == 'file') {
          controller.moveFile(draggedId, data.id);
        } else if (type == 'folder') {
          controller.moveFolder(draggedId, data.id);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return Draggable<String>(
          data: 'folder:${data.id}',
          feedback: Material(
            elevation: 4,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.folder, size: 18),
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
            child: FolderTile(
              data: data,
              isSelected: isSelected,
              onShowContextMenu: onShowContextMenu,
            ),
          ),
        );
      },
    );
  }
}
