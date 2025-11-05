import 'package:flutter/material.dart';

class FileTreeHeader extends StatelessWidget {
  final VoidCallback onNewFile;
  final VoidCallback onNewFolder;
  final VoidCallback onRefresh;

  const FileTreeHeader({
    super.key,
    required this.onNewFile,
    required this.onNewFolder,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Text(
            'Files',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.insert_drive_file, size: 18),
            tooltip: 'New File',
            onPressed: onNewFile,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.create_new_folder, size: 18),
            tooltip: 'New Folder',
            onPressed: onNewFolder,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: 'Refresh',
            onPressed: onRefresh,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
