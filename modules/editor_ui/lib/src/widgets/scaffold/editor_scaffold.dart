import 'package:flutter/material.dart';
import 'package:editor_plugins/editor_plugins.dart';
import '../../controllers/editor_controller.dart';
import '../../controllers/file_tree_controller.dart';
import '../../state/editor_state.dart';
import '../code_editor/editor_config.dart';
import '../file_tree/file_tree_view.dart';
import 'widgets/empty_editor_placeholder.dart';
import 'widgets/loading_editor_indicator.dart';
import 'widgets/error_editor_message.dart';
import 'widgets/loaded_editor_view.dart';

class EditorScaffold extends StatefulWidget {
  final FileTreeController fileTreeController;
  final EditorController editorController;
  final EditorConfig editorConfig;
  final PluginManager? pluginManager;
  final double treeWidth;
  final Widget? customHeader;
  final Widget? customFooter;
  final bool showPluginToolbar;
  final bool showPluginSidebar;

  const EditorScaffold({
    super.key,
    required this.fileTreeController,
    required this.editorController,
    this.editorConfig = const EditorConfig(),
    this.pluginManager,
    this.treeWidth = 250,
    this.customHeader,
    this.customFooter,
    this.showPluginToolbar = true,
    this.showPluginSidebar = true,
  });

  @override
  State<EditorScaffold> createState() => _EditorScaffoldState();
}

class _EditorScaffoldState extends State<EditorScaffold> {
  @override
  void initState() {
    super.initState();
    widget.fileTreeController.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (widget.customHeader != null) widget.customHeader!,
          if (widget.showPluginToolbar && widget.pluginManager != null)
            _buildPluginToolbar(context),
          Expanded(
            child: Row(
              children: [
                FileTreeView(
                  controller: widget.fileTreeController,
                  width: widget.treeWidth,
                  pluginManager: widget.pluginManager,
                  onFileSelected: (fileId) async {
                    await widget.editorController.loadFile(fileId);
                  },
                ),
                Expanded(
                  child: ValueListenableBuilder<EditorState>(
                    valueListenable: widget.editorController,
                    builder: (context, state, _) {
                      return state.when(
                        initial: () => const EmptyEditorPlaceholder(),
                        loading: () => const LoadingEditorIndicator(),
                        loaded: (file, isDirty, isSaving) => LoadedEditorView(
                          file: file,
                          isDirty: isDirty,
                          isSaving: isSaving,
                          editorConfig: widget.editorConfig,
                          onContentChanged: (newContent) {
                            widget.editorController.updateContent(newContent);
                          },
                          onSave: () async {
                            await widget.editorController.save();
                          },
                          onClose: () {
                            widget.editorController.close();
                          },
                        ),
                        error: (message) => ErrorEditorMessage(
                          message: message,
                          onClose: () {
                            widget.editorController.close();
                          },
                        ),
                      );
                    },
                  ),
                ),
                if (widget.showPluginSidebar && widget.pluginManager != null)
                  _buildPluginSidebar(context),
              ],
            ),
          ),
          if (widget.customFooter != null) widget.customFooter!,
        ],
      ),
    );
  }

  Widget _buildPluginToolbar(BuildContext context) {
    final plugins = widget.pluginManager!.plugins;
    final toolbarActions = plugins
        .map((plugin) => plugin.buildToolbarAction(context))
        .where((widget) => widget != null)
        .cast<Widget>()
        .toList();

    if (toolbarActions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.extension,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            'Plugins',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(width: 16),
          ...toolbarActions.map((action) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: action,
              )),
        ],
      ),
    );
  }

  Widget _buildPluginSidebar(BuildContext context) {
    final plugins = widget.pluginManager!.plugins;
    final sidebarPanels = plugins
        .map((plugin) => plugin.buildSidebarPanel(context))
        .where((widget) => widget != null)
        .cast<Widget>()
        .toList();

    if (sidebarPanels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.widgets,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Plugin Panels',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: sidebarPanels.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) => sidebarPanels[index],
            ),
          ),
        ],
      ),
    );
  }
}
