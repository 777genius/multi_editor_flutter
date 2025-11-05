import 'package:flutter/material.dart';
import 'package:editor_core/editor_core.dart';
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
  final VoidCallback onSave;
  final VoidCallback onClose;

  const LoadedEditorView({
    super.key,
    required this.file,
    required this.isDirty,
    required this.isSaving,
    required this.editorConfig,
    required this.onContentChanged,
    required this.onSave,
    required this.onClose,
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
        ),
        const Divider(height: 1),
        Expanded(
          child: MonacoCodeEditor(
            key: ValueKey('monaco-${file.id}'),
            code: file.content,
            language: file.language,
            config: editorConfig,
            onChanged: onContentChanged,
          ),
        ),
        if (isDirty) DirtyChangesIndicator(onSave: onSave),
      ],
    );
  }
}
