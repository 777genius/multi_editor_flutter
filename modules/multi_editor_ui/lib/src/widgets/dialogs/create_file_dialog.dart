import 'package:flutter/material.dart';

class CreateFileDialog extends StatefulWidget {
  final String? initialParentFolderId;

  const CreateFileDialog({super.key, this.initialParentFolderId});

  @override
  State<CreateFileDialog> createState() => _CreateFileDialogState();
}

class _CreateFileDialogState extends State<CreateFileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop({
        'name': _nameController.text.trim(),
        'folderId': widget.initialParentFolderId ?? 'root',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New File'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'File name',
                hintText: 'example.dart',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'File name cannot be empty';
                }
                if (value.contains('/') || value.contains('\\')) {
                  return 'File name cannot contain slashes';
                }
                if (value.length > 255) {
                  return 'File name too long (max 255 characters)';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }
}
