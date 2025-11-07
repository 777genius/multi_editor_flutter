import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import '../../../controllers/file_tree_controller.dart';
import '../../../utils/context_menu_stub.dart'
    if (dart.library.html) '../../../utils/context_menu_web.dart';
import 'file_tree_folder_item.dart';
import 'file_tree_file_item.dart';

class FileTreeListView extends StatelessWidget {
  final TreeNode<FileTreeNode> treeNode;
  final double maxWidth;
  final String? selectedNodeId;
  final double containerWidth;
  final FileTreeController controller;
  final PluginManager? pluginManager;
  final ValueChanged<String>? onFileSelected;
  final bool enableDragDrop;
  final void Function(BuildContext context, Offset position, FileTreeNode data)
      onShowFolderContextMenu;
  final void Function(BuildContext context, Offset position, FileTreeNode data)
      onShowFileContextMenu;

  const FileTreeListView({
    super.key,
    required this.treeNode,
    required this.maxWidth,
    required this.selectedNodeId,
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
    final currentWidth = max(containerWidth - 20, maxWidth);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: currentWidth,
        child: Listener(
          onPointerDown: (event) {
            if (event.buttons == kSecondaryButton) {
              preventNativeContextMenu(event);
            }
          },
          child: TreeView.simple<FileTreeNode>(
            tree: treeNode,
            showRootNode: false,
            expansionBehavior: ExpansionBehavior.none,
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
                  ? FileTreeFolderItem(
                      key: ValueKey(data.id),
                      data: data,
                      isSelected: isSelected,
                      enableDragDrop: enableDragDrop,
                      controller: controller,
                      onShowContextMenu: onShowFolderContextMenu,
                    )
                  : FileTreeFileItem(
                      key: ValueKey(data.id),
                      data: data,
                      isSelected: isSelected,
                      enableDragDrop: enableDragDrop,
                      controller: controller,
                      pluginManager: pluginManager,
                      onShowContextMenu: onShowFileContextMenu,
                    );
            },
          ),
        ),
      ),
    );
  }
}
