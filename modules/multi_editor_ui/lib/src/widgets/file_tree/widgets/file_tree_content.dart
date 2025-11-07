import 'dart:math';
import 'package:flutter/material.dart';
import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import '../../../controllers/file_tree_controller.dart';
import '../../../state/file_tree_state.dart';
import 'empty_file_tree_placeholder.dart';
import 'file_tree_list_view.dart';

class FileTreeContent extends StatelessWidget {
  final FileTreeState state;
  final double containerWidth;
  final FileTreeController controller;
  final PluginManager? pluginManager;
  final ValueChanged<String>? onFileSelected;
  final bool enableDragDrop;
  final void Function(BuildContext context, Offset position, FileTreeNode data)
  onShowFolderContextMenu;
  final void Function(BuildContext context, Offset position, FileTreeNode data)
  onShowFileContextMenu;

  const FileTreeContent({
    super.key,
    required this.state,
    required this.containerWidth,
    required this.controller,
    this.pluginManager,
    required this.onFileSelected,
    required this.enableDragDrop,
    required this.onShowFolderContextMenu,
    required this.onShowFileContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    if (!enableDragDrop) {
      return _buildContent(context);
    }

    return state.maybeWhen(
      loaded: (rootNode, selectedNodeId, expandedFolderIds) {
        return DragTarget<String>(
          onWillAcceptWithDetails: (details) {
            final parts = details.data.split(':');
            if (parts.length != 2) return false;

            final type = parts[0]; // 'file' or 'folder'
            final draggedId = parts[1];

            // Don't accept root folder
            if (draggedId == rootNode.id) return false;

            // Accept both files and folders
            return type == 'file' || type == 'folder';
          },
          onAcceptWithDetails: (details) {
            final parts = details.data.split(':');
            final type = parts[0];
            final draggedId = parts[1];

            if (type == 'file') {
              controller.moveFile(draggedId, 'root');
            } else if (type == 'folder') {
              controller.moveFolder(draggedId, 'root');
            }
          },
          builder: (context, candidateData, rejectedData) {
            final isHovered = candidateData.isNotEmpty;

            return Stack(
              children: [
                if (isHovered)
                  Positioned.fill(
                    child: Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                _buildLoadedContent(
                  context,
                  rootNode,
                  selectedNodeId,
                  isHovered: isHovered,
                ),
              ],
            );
          },
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildContent(BuildContext context) {
    return state.maybeWhen(
      loaded: (rootNode, selectedNodeId, expandedFolderIds) {
        return _buildLoadedContent(context, rootNode, selectedNodeId);
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildLoadedContent(
    BuildContext context,
    FileTreeNode rootNode,
    String? selectedNodeId, {
    bool isHovered = false,
  }) {
    if (rootNode.children.isEmpty) {
      return EmptyFileTreePlaceholder(isHovered: isHovered);
    }

    // Don't pass isHovered to tree view - it doesn't use it
    // This prevents unnecessary rebuilds
    final treeNode = _convertToTreeNode(rootNode);
    final maxWidth = _calculateMaxWidth(rootNode);

    return FileTreeListView(
      key: ValueKey('file-tree-${rootNode.id}'),
      treeNode: treeNode,
      maxWidth: maxWidth,
      selectedNodeId: selectedNodeId,
      containerWidth: containerWidth,
      controller: controller,
      pluginManager: pluginManager,
      onFileSelected: onFileSelected,
      enableDragDrop: enableDragDrop,
      onShowFolderContextMenu: onShowFolderContextMenu,
      onShowFileContextMenu: onShowFileContextMenu,
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
}
