import 'package:flutter/material.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import 'package:flutter_monaco_crossplatform/flutter_monaco_crossplatform.dart';
import '../../code_editor/monaco_code_editor.dart';
import '../../code_editor/editor_config.dart';
import 'editor_header_bar.dart';
import 'dirty_changes_indicator.dart';

class LoadedEditorView extends StatelessWidget {
  final FileDocument file;
  final bool isDirty;
  final bool isSaving;
  final EditorConfig editorConfig;
  final ValueChanged<String> onContentChanged;
  final ValueChanged<MonacoController>? onControllerReady;
  final VoidCallback onSave;
  final VoidCallback onClose;
  final PluginUIService? pluginUIService;
  final PluginManager? pluginManager;
  final Function(String action, Map<String, dynamic> data)? onPluginAction;

  const LoadedEditorView({
    super.key,
    required this.file,
    required this.isDirty,
    required this.isSaving,
    required this.editorConfig,
    required this.onContentChanged,
    this.onControllerReady,
    required this.onSave,
    required this.onClose,
    this.pluginUIService,
    this.pluginManager,
    this.onPluginAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EditorHeaderBar(
          file: file,
          isDirty: isDirty,
          isSaving: isSaving,
          onSave: onSave,
          onClose: onClose,
          pluginUIService: pluginUIService,
          pluginManager: pluginManager,
          onPluginAction: onPluginAction,
        ),
        const Divider(height: 1),
        Expanded(
          child: MonacoCodeEditor(
            key: ValueKey('monaco-${file.id}'),
            code: file.content,
            language: file.language,
            config: editorConfig,
            onChanged: onContentChanged,
            onControllerReady: onControllerReady,
          ),
        ),
        if (isDirty) DirtyChangesIndicator(onSave: onSave),
      ],
    );
  }
}
