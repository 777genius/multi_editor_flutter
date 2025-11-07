import 'package:flutter/material.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'file_tree_item_with_hover.dart';

class FolderTile extends StatelessWidget {
  final FileTreeNode data;
  final bool isSelected;
  final void Function(BuildContext context, Offset position, FileTreeNode data)
  onShowContextMenu;

  const FolderTile({
    super.key,
    required this.data,
    required this.isSelected,
    required this.onShowContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    return FileTreeItemWithHover(
      isSelected: isSelected,
      onSecondaryTap: (details) =>
          onShowContextMenu(context, details.globalPosition, data),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        leading: Icon(
          Icons.folder,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          data.name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
