import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:editor_core/editor_core.dart';
import '../../controllers/file_tree_controller.dart';
import '../../state/file_tree_state.dart';
import '../../theme/editor_theme_extension.dart';
import '../../theme/colors/language_colors.dart';
import '../dialogs/create_file_dialog.dart';
import '../dialogs/create_folder_dialog.dart';
import '../dialogs/rename_dialog.dart';
import '../dialogs/confirm_delete_dialog.dart';
import '../../utils/context_menu_stub.dart'
    if (dart.library.html) '../../utils/context_menu_web.dart';

class FileTreeView extends StatelessWidget {
  final FileTreeController controller;
  final ValueChanged<String>? onFileSelected;
  final double width;
  final bool enableDragDrop;

  const FileTreeView({
    super.key,
    required this.controller,
    this.onFileSelected,
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
          _buildHeader(context),
          const Divider(height: 1),
          Expanded(
            child: ValueListenableBuilder<FileTreeState>(
              valueListenable: controller,
              builder: (context, state, _) {
                return state.map(
                  initial: (_) => const Center(child: Text('Ready')),
                  loading:
                      (_) => const Center(child: CircularProgressIndicator()),
                  loaded: (loadedState) => _buildTree(context, loadedState),
                  error:
                      (errorState) => Center(
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Text(
            'Files',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.insert_drive_file, size: 18),
            tooltip: 'New File',
            onPressed:
                () =>
                    _showCreateFileDialog(
                      context,
                      controller.getSelectedParentFolderId(),
                    ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.create_new_folder, size: 18),
            tooltip: 'New Folder',
            onPressed:
                () =>
                    _showCreateFolderDialog(
                      context,
                      controller.getSelectedParentFolderId(),
                    ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: 'Refresh',
            onPressed: () => controller.refresh(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildTree(BuildContext context, FileTreeState state) {
    return state.maybeWhen(
      loaded: (rootNode, selectedNodeId, expandedFolderIds) {
        if (rootNode.children.isEmpty) {
          return _buildEmptyState(context);
        }

        final treeNode = _convertToTreeNode(rootNode);
        final maxWidth = _calculateMaxWidth(rootNode);

        return _buildTreeView(context, treeNode, maxWidth, selectedNodeId);
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildTreeView(
    BuildContext context,
    TreeNode<FileTreeNode> treeNode,
    double maxWidth,
    String? selectedNodeId,
  ) {
    final currentWidth = max(width - 20, maxWidth);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: currentWidth,
        child: Listener(
          onPointerDown: (event) {
            // Prevent native browser context menu on right-click (secondary button)
            if (event.buttons == kSecondaryButton) {
              preventNativeContextMenu(event);
            }
          },
          child: TreeView.simple<FileTreeNode>(
            tree: treeNode,
            showRootNode: false,
            expansionBehavior: ExpansionBehavior.collapseOthersAndSnapToTop,
            indentation: const Indentation(width: 20),
            onItemTap: (item) {
              final node = item.data!;
              if (node.isFolder) {
                controller.toggleFolder(node.id);
              } else {
                controller.selectNode(node.id);
                onFileSelected?.call(node.id);
              }
            },
            builder: (context, node) {
              final data = node.data!;
              final isSelected = selectedNodeId == data.id;

              return data.isFolder
                  ? _buildFolderItem(context, data, isSelected)
                  : _buildFileItem(context, data, isSelected);
            },
          ),
        ),
      ),
    );
  }

  TreeNode<FileTreeNode> _convertToTreeNode(FileTreeNode node) {
    final treeNode = TreeNode<FileTreeNode>(key: node.id, data: node);

    for (final child in node.children) {
      treeNode.add(_convertToTreeNode(child));
    }

    return treeNode;
  }

  double _calculateMaxWidth(FileTreeNode node, [int depth = 0]) {
    const baseWidth = 100.0;
    const indentWidth = 20.0;
    const charWidth = 8.0;

    final nameWidth = node.name.length * charWidth;
    final currentWidth = baseWidth + (depth * indentWidth) + nameWidth;

    if (node.children.isEmpty) {
      return currentWidth;
    }

    final childrenMaxWidth = node.children
        .map((child) => _calculateMaxWidth(child, depth + 1))
        .reduce(max);

    return max(currentWidth, childrenMaxWidth);
  }

  Widget _buildFolderItem(
    BuildContext context,
    FileTreeNode data,
    bool isSelected,
  ) {
    if (!enableDragDrop) {
      return _buildFolderTile(context, data, isSelected);
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
            color:
                isHovered
                    ? Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2)
                    : null,
            child: _buildFolderTile(context, data, isSelected),
          ),
        );
      },
    );
  }

  Widget _buildFolderTile(
    BuildContext context,
    FileTreeNode data,
    bool isSelected,
  ) {
    return _FileTreeItemWithHover(
      isSelected: isSelected,
      onSecondaryTap: (details) => _showFolderContextMenu(
        context,
        details.globalPosition,
        data,
      ),
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

  void _showFolderContextMenu(
    BuildContext context,
    Offset position,
    FileTreeNode data,
  ) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
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
      ],
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

  Widget _buildFileItem(
    BuildContext context,
    FileTreeNode data,
    bool isSelected,
  ) {
    final widget = _FileTreeItemWithHover(
      isSelected: isSelected,
      onSecondaryTap: (details) => _showFileContextMenu(
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
                    ? Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.2)
                    : null,
            child: widget,
          ),
        );
      },
    );
  }

  void _showFileContextMenu(
    BuildContext context,
    Offset position,
    FileTreeNode data,
  ) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
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
      ],
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

  IconData _getFileIcon(String? language) {
    final lang = ProgrammingLanguage.fromString(language);
    return lang.getIcon();
  }

  Color _getFileColor(BuildContext context, String? language) {
    final lang = ProgrammingLanguage.fromString(language);
    return lang.color;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No files yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first file or folder',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateFileDialog(
    BuildContext context,
    String? parentFolderId,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => CreateFileDialog(initialParentFolderId: parentFolderId),
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
      builder:
          (context) =>
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
      builder:
          (context) => RenameDialog(currentName: currentName, itemType: 'file'),
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
      builder:
          (context) =>
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
      builder:
          (context) =>
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
      builder:
          (context) => ConfirmDeleteDialog(
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

/// A wrapper widget that adds hover effects and handles right-click context menu
/// for file tree items.
class _FileTreeItemWithHover extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final void Function(TapDownDetails details)? onSecondaryTap;

  const _FileTreeItemWithHover({
    required this.child,
    required this.isSelected,
    this.onSecondaryTap,
  });

  @override
  State<_FileTreeItemWithHover> createState() => _FileTreeItemWithHoverState();
}

class _FileTreeItemWithHoverState extends State<_FileTreeItemWithHover> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final editorTheme = context.editorTheme;

    Color? backgroundColor;
    if (widget.isSelected) {
      backgroundColor = _isHovered
          ? editorTheme.fileTreeSelectionHoverBackground
          : editorTheme.fileTreeSelectionBackground;
    } else if (_isHovered) {
      backgroundColor = editorTheme.fileTreeHoverBackground;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onSecondaryTapDown: widget.onSecondaryTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          color: backgroundColor,
          child: widget.child,
        ),
      ),
    );
  }
}
