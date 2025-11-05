import 'package:editor_core/editor_core.dart';
import 'package:editor_plugins/editor_plugins.dart';
import 'package:plugin_base/plugin_base.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/file_statistics.dart';

class FileStatsPlugin extends BaseEditorPlugin with StatefulPlugin {
  final Map<String, FileStatistics> _statistics = {};

  @override
  PluginManifest get manifest => const PluginManifest(
        id: 'plugin.file_stats',
        name: 'File Statistics',
        version: '0.1.0',
        description: 'Displays file metrics (lines, characters, words, size)',
        author: 'Editor Team',
        activationEvents: ['onFileOpen', 'onFileContentChange'],
      );

  @override
  Future<void> onInitialize(PluginContext context) async {
    setState('statistics', _statistics);
  }

  @override
  Future<void> onDispose() async {
    disposeStateful();
  }

  @override
  void onFileOpen(FileDocument file) {
    safeExecute('Calculate file statistics', () {
      _updateStatistics(file.id, file.content);
    });
  }

  @override
  void onFileContentChange(String fileId, String content) {
    safeExecute('Update file statistics', () {
      _updateStatistics(fileId, content);
    });
  }

  @override
  void onFileClose(String fileId) {
    safeExecute('Clear file statistics', () {
      _statistics.remove(fileId);
      setState('statistics', _statistics);
    });
  }

  void _updateStatistics(String fileId, String content) {
    final stats = FileStatistics.calculate(fileId, content);
    _statistics[fileId] = stats;
    setState('statistics', _statistics);
  }

  @override
  Widget? buildToolbarAction(BuildContext context) {
    final currentFileId = getState<String>('currentFileId');
    if (currentFileId == null) {
      return null;
    }

    final stats = _statistics[currentFileId];
    if (stats == null) {
      return null;
    }

    return Tooltip(
      message: 'File Statistics',
      child: Chip(
        avatar: const Icon(Icons.analytics, size: 16),
        label: Text(
          stats.displayText,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  FileStatistics? getStatistics(String fileId) => _statistics[fileId];

  Map<String, FileStatistics> get allStatistics =>
      Map<String, FileStatistics>.from(_statistics);
}
