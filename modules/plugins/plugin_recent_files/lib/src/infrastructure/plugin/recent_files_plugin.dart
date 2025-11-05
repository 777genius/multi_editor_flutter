import 'package:editor_core/editor_core.dart';
import 'package:editor_plugins/editor_plugins.dart';
import 'package:plugin_base/plugin_base.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/recent_files_list.dart';
import '../../domain/value_objects/recent_file_entry.dart';

class RecentFilesPlugin extends BaseEditorPlugin with StatefulPlugin {
  RecentFilesList _recentFiles = RecentFilesList.create(maxEntries: 10);

  @override
  PluginManifest get manifest => const PluginManifest(
        id: 'plugin.recent_files',
        name: 'Recent Files',
        version: '0.1.0',
        description: 'Tracks and displays recently opened files',
        author: 'Editor Team',
        activationEvents: ['onFileOpen'],
      );

  @override
  Future<void> onInitialize(PluginContext context) async {
    setState('recentFiles', _recentFiles);
  }

  @override
  Future<void> onDispose() async {
    disposeStateful();
  }

  @override
  void onFileOpen(FileDocument file) {
    safeExecute('Add to recent files', () {
      final entry = RecentFileEntry.create(
        fileId: file.id,
        fileName: file.name,
        filePath: file.name,
      );

      _recentFiles = _recentFiles.addFile(entry);
      setState('recentFiles', _recentFiles);
    });
  }

  @override
  void onFileDelete(String fileId) {
    safeExecute('Remove from recent files', () {
      _recentFiles = _recentFiles.removeFile(fileId);
      setState('recentFiles', _recentFiles);
    });
  }

  @override
  Widget? buildSidebarPanel(BuildContext context) {
    return RecentFilesPanel(
      recentFiles: _recentFiles,
      onFileSelected: (entry) {
        context
            .findAncestorStateOfType<NavigatorState>()
            ?.pop();
      },
    );
  }

  void clearRecentFiles() {
    _recentFiles = _recentFiles.clear();
    setState('recentFiles', _recentFiles);
  }

  List<RecentFileEntry> get recentFiles => _recentFiles.sortedByRecent;
}

class RecentFilesPanel extends StatelessWidget {
  final RecentFilesList recentFiles;
  final void Function(RecentFileEntry) onFileSelected;

  const RecentFilesPanel({
    super.key,
    required this.recentFiles,
    required this.onFileSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (recentFiles.isEmpty) {
      return const Center(
        child: Text('No recent files'),
      );
    }

    return ListView.builder(
      itemCount: recentFiles.count,
      itemBuilder: (context, index) {
        final entry = recentFiles.entries[index];
        return ListTile(
          leading: const Icon(Icons.insert_drive_file),
          title: Text(entry.fileName),
          subtitle: Text(entry.filePath),
          onTap: () => onFileSelected(entry),
        );
      },
    );
  }
}
