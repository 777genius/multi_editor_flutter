import 'package:flutter/material.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import '../../controllers/file_tree_controller.dart';
import '../../state/file_tree_state.dart';
import '../dialogs/create_file_dialog.dart';
import '../dialogs/create_folder_dialog.dart';
import '../dialogs/rename_dialog.dart';
import '../dialogs/confirm_delete_dialog.dart';
import 'widgets/file_tree_header.dart';
import 'widgets/file_tree_content.dart';

class FileTreeView extends StatelessWidget {
  final FileTreeController controller;
  final ValueChanged<String>? onFileSelected;
  final PluginManager? pluginManager;
  final double width;
  final bool enableDragDrop;

  const FileTreeView({
    super.key,
    required this.controller,
    this.onFileSelected,
    this.pluginManager,
    this.width = 250,
    this.enableDragDrop = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          FileTreeHeader(
            onNewFile: () => _showCreateFileDialog(
              context,
              controller.getSelectedParentFolderId(),
            ),
            onNewFolder: () => _showCreateFolderDialog(
              context,
              controller.getSelectedParentFolderId(),
            ),
            onRefresh: () => controller.refresh(),
          ),
          const Divider(height: 1),
          Expanded(
            child: ValueListenableBuilder<FileTreeState>(
              valueListenable: controller,
              builder: (context, state, _) {
                return state.map(
                  initial: (_) => const Center(child: Text('Ready')),
                  loading: (_) =>
                      const Center(child: CircularProgressIndicator()),
                  loaded: (loadedState) => FileTreeContent(
                    state: loadedState,
                    containerWidth: width,
                    controller: controller,
                    pluginManager: pluginManager,
                    onFileSelected: onFileSelected,
                    enableDragDrop: enableDragDrop,
                    onShowFolderContextMenu: _showFolderContextMenu,
                    onShowFileContextMenu: _showFileContextMenu,
                  ),
                  error: (errorState) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error: ${errorState.message}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFolderContextMenu(
    BuildContext context,
    Offset position,
    FileTreeNode data,
  ) {
    final menuItems = <PopupMenuEntry<String>>[
      const PopupMenuItem(
        value: 'new_file',
        child: Row(
          children: [
            Icon(Icons.insert_drive_file, size: 16),
            SizedBox(width: 8),
            Text('New File'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'new_folder',
        child: Row(
          children: [
            Icon(Icons.create_new_folder, size: 16),
            SizedBox(width: 8),
            Text('New Folder'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'rename',
        child: Row(
          children: [
            Icon(Icons.edit, size: 16),
            SizedBox(width: 8),
            Text('Rename'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete, size: 16),
            SizedBox(width: 8),
            Text('Delete'),
          ],
        ),
      ),
    ];

    // Add plugin context menu items (folders don't have FileDocument, skip for now)
    // Plugins can potentially add folder-specific items in future

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: menuItems,
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'new_file':
            _showCreateFileDialog(context, data.id);
            break;
          case 'new_folder':
            _showCreateFolderDialog(context, data.id);
            break;
          case 'rename':
            _showRenameFolderDialog(context, data.id, data.name);
            break;
          case 'delete':
            _confirmDeleteFolder(context, data.id, data.name);
            break;
        }
      }
    });
  }

  void _showFileContextMenu(
    BuildContext context,
    Offset position,
    FileTreeNode data,
  ) async {
    final menuItems = <PopupMenuEntry<String>>[
      const PopupMenuItem(
        value: 'rename',
        child: Row(
          children: [
            Icon(Icons.edit, size: 16),
            SizedBox(width: 8),
            Text('Rename'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete, size: 16),
            SizedBox(width: 8),
            Text('Delete'),
          ],
        ),
      ),
    ];

    // Plugin context menu items removed - plugins now use header buttons
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: menuItems,
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'rename':
            _showRenameFileDialog(context, data.id, data.name);
            break;
          case 'delete':
            _confirmDeleteFile(context, data.id, data.name);
            break;
        }
      }
    });
  }

  Future<void> _showCreateFileDialog(
    BuildContext context,
    String? parentFolderId,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          CreateFileDialog(initialParentFolderId: parentFolderId),
    );

    if (result != null && context.mounted) {
      await controller.createFile(
        folderId: result['folderId'] as String,
        name: result['name'] as String,
      );
    }
  }

  Future<void> _showCreateFolderDialog(
    BuildContext context,
    String? parentFolderId,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          CreateFolderDialog(initialParentFolderId: parentFolderId),
    );

    if (result != null && context.mounted) {
      await controller.createFolder(
        name: result['name'] as String,
        parentId: result['parentId'] as String?,
      );
    }
  }

  Future<void> _showRenameFileDialog(
    BuildContext context,
    String fileId,
    String currentName,
  ) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) =>
          RenameDialog(currentName: currentName, itemType: 'file'),
    );

    if (newName != null && context.mounted) {
      await controller.renameFile(fileId, newName);
    }
  }

  Future<void> _showRenameFolderDialog(
    BuildContext context,
    String folderId,
    String currentName,
  ) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) =>
          RenameDialog(currentName: currentName, itemType: 'folder'),
    );

    if (newName != null && context.mounted) {
      await controller.renameFolder(folderId, newName);
    }
  }

  Future<void> _confirmDeleteFile(
    BuildContext context,
    String fileId,
    String fileName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) =>
          ConfirmDeleteDialog(itemName: fileName, itemType: 'file'),
    );

    if (confirmed == true && context.mounted) {
      await controller.deleteFile(fileId);
    }
  }

  Future<void> _confirmDeleteFolder(
    BuildContext context,
    String folderId,
    String folderName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDeleteDialog(
        itemName: folderName,
        itemType: 'folder',
        warningMessage:
            'All files and subfolders inside this folder will be deleted.',
      ),
    );

    if (confirmed == true && context.mounted) {
      await controller.deleteFolder(folderId);
    }
  }
}
