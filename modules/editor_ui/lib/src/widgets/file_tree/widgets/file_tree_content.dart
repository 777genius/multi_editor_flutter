import 'dart:math';
import 'package:flutter/material.dart';
import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:editor_core/editor_core.dart';
import '../../../controllers/file_tree_controller.dart';
import '../../../state/file_tree_state.dart';
import 'empty_file_tree_placeholder.dart';
import 'file_tree_list_view.dart';

class FileTreeContent extends StatelessWidget {
  final FileTreeState state;
  final double containerWidth;
  final FileTreeController controller;
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
    required this.onFileSelected,
    required this.enableDragDrop,
    required this.onShowFolderContextMenu,
    required this.onShowFileContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    return state.maybeWhen(
      loaded: (rootNode, selectedNodeId, expandedFolderIds) {
        if (rootNode.children.isEmpty) {
          return const EmptyFileTreePlaceholder();
        }

        final treeNode = _convertToTreeNode(rootNode);
        final maxWidth = _calculateMaxWidth(rootNode);

        return FileTreeListView(
          treeNode: treeNode,
          maxWidth: maxWidth,
          selectedNodeId: selectedNodeId,
          containerWidth: containerWidth,
          controller: controller,
          onFileSelected: onFileSelected,
          enableDragDrop: enableDragDrop,
          onShowFolderContextMenu: onShowFolderContextMenu,
          onShowFileContextMenu: onShowFileContextMenu,
        );
      },
      orElse: () => const SizedBox.shrink(),
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
