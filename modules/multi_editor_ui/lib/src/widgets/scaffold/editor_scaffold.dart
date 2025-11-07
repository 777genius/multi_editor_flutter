import 'package:flutter/material.dart';
import 'package:flutter_monaco_crossplatform/flutter_monaco_crossplatform.dart' hide EditorState;
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
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
  final PluginUIService? pluginUIService;
  final ValueChanged<MonacoController>? onControllerReady;
  final double treeWidth;
  final Widget? customHeader;
  final Widget? customFooter;

  const EditorScaffold({
    super.key,
    required this.fileTreeController,
    required this.editorController,
    this.editorConfig = const EditorConfig(),
    this.pluginManager,
    this.pluginUIService,
    this.onControllerReady,
    this.treeWidth = 250,
    this.customHeader,
    this.customFooter,
  });

  @override
  State<EditorScaffold> createState() => _EditorScaffoldState();
}

class _EditorScaffoldState extends State<EditorScaffold> {
  PluginUINotifier? _pluginUINotifier;

  @override
  void initState() {
    super.initState();
    widget.fileTreeController.load();
    _initPluginUINotifier();
  }

  @override
  void didUpdateWidget(EditorScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pluginManager != widget.pluginManager) {
      _pluginUINotifier?.dispose();
      _initPluginUINotifier();
    }
  }

  void _initPluginUINotifier() {
    if (widget.pluginManager != null) {
      _pluginUINotifier = PluginUINotifier(widget.pluginManager!.plugins);
    }
  }

  @override
  void dispose() {
    _pluginUINotifier?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (widget.customHeader != null) widget.customHeader!,
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
                          onControllerReady: widget.onControllerReady,
                          onSave: () async {
                            await widget.editorController.save();
                          },
                          onClose: () {
                            widget.editorController.close();
                          },
                          pluginUIService: widget.pluginUIService,
                          pluginManager: widget.pluginManager,
                          onPluginAction: _handlePluginAction,
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
              ],
            ),
          ),
          if (widget.customFooter != null) widget.customFooter!,
        ],
      ),
    );
  }

  /// Handle plugin action from UI
  void _handlePluginAction(String action, Map<String, dynamic> data) {
    switch (action) {
      case 'openFile':
        final fileId = data['id'] as String?;
        if (fileId != null) {
          // Update file tree selection first to sync UI
          widget.fileTreeController.selectNode(fileId);
          // Then load the file
          widget.editorController.loadFile(fileId);
        }
        break;
      default:
        debugPrint('[EditorScaffold] Unknown plugin action: $action');
    }
  }
}
