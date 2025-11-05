import 'dart:async';
import 'package:editor_core/editor_core.dart';
import 'package:editor_plugins/editor_plugins.dart';
import 'package:plugin_base/plugin_base.dart';
import '../../domain/value_objects/auto_save_config.dart';
import '../../domain/value_objects/save_interval.dart';
import '../../domain/entities/save_task.dart';
import '../../application/use_cases/trigger_save_use_case.dart';

class AutoSavePlugin extends BaseEditorPlugin with ConfigurablePlugin, StatefulPlugin {
  Timer? _timer;
  final Map<String, String> _unsavedContent = {};
  TriggerSaveUseCase? _triggerSaveUseCase;

  @override
  PluginManifest get manifest => const PluginManifest(
        id: 'plugin.auto_save',
        name: 'Auto Save',
        version: '0.1.0',
        description: 'Automatically saves file changes at configurable intervals',
        author: 'Editor Team',
        capabilities: {
          'file.save': 'Automatically saves files',
          'config.interval': 'Configurable save interval',
        },
        activationEvents: [
          'onFileOpen',
          'onFileContentChange',
        ],
      );

  @override
  Future<void> onInitialize(PluginContext context) async {
    await loadConfiguration(
      InMemoryStorageAdapter(),
      PluginId(value: manifest.id),
    );

    if (!hasConfiguration) {
      await updateConfiguration((_) => PluginConfiguration.create(
            PluginId(value: manifest.id),
          ).updateSetting('config', AutoSaveConfig.defaultConfig().toJson()));
    }

    _triggerSaveUseCase = TriggerSaveUseCase(context.fileRepository);

    final config = _getConfig();
    if (config.enabled) {
      _startTimer(config.interval);
    }
  }

  @override
  Future<void> onDispose() async {
    _stopTimer();
    disposeStateful();
  }

  @override
  void onFileContentChange(String fileId, String content) {
    safeExecute('Track content change', () {
      _unsavedContent[fileId] = content;
      setState('lastChange', DateTime.now());
    });
  }

  @override
  void onFileClose(String fileId) {
    safeExecute('Clean up closed file', () {
      _unsavedContent.remove(fileId);
    });
  }

  void _startTimer(SaveInterval interval) {
    _stopTimer();
    _timer = Timer.periodic(interval.duration, (_) => _saveAll());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _saveAll() async {
    if (_unsavedContent.isEmpty) return;

    await safeExecuteAsync('Auto-save all files', () async {
      for (final entry in _unsavedContent.entries) {
        final task = SaveTask.create(
          fileId: entry.key,
          content: entry.value,
        );

        try {
          await _triggerSaveUseCase!.execute(task);
          _unsavedContent.remove(entry.key);
        } catch (e) {
          // Log failure but continue with next file
        }
      }
    });
  }

  AutoSaveConfig _getConfig() {
    final configJson = getConfigSetting<Map<String, dynamic>>('config');
    if (configJson == null) {
      return AutoSaveConfig.defaultConfig();
    }

    try {
      return AutoSaveConfig.fromJson(configJson);
    } catch (e) {
      return AutoSaveConfig.defaultConfig();
    }
  }

  Future<void> updateAutoSaveConfig(AutoSaveConfig config) async {
    await setConfigSetting('config', config.toJson());

    if (config.enabled) {
      _startTimer(config.interval);
    } else {
      _stopTimer();
    }
  }
}
