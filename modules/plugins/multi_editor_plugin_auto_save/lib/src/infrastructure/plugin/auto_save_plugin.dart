import 'dart:async';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import 'package:multi_editor_plugin_base/multi_editor_plugin_base.dart';
import '../../domain/value_objects/auto_save_config.dart';
import '../../domain/value_objects/save_interval.dart';
import '../../domain/entities/save_task.dart';
import '../../application/use_cases/trigger_save_use_case.dart';

/// Auto-save plugin that periodically saves file changes.
///
/// ## Architecture improvements:
/// - Uses PluginManifestBuilder for cleaner manifest
/// - Throttles content change tracking (max once per 500ms per file)
/// - Simplified through updated BaseEditorPlugin
class AutoSavePlugin extends BaseEditorPlugin
    with ConfigurablePlugin, StatefulPlugin {
  Timer? _timer;
  final Map<String, String> _unsavedContent = {};
  final Map<String, DateTime> _lastContentChangeTime = {};
  TriggerSaveUseCase? _triggerSaveUseCase;
  bool _disposed = false;

  /// Minimum time between content change tracking for same file
  static const _contentChangeThrottle = Duration(milliseconds: 500);

  @override
  PluginManifest get manifest => PluginManifestBuilder()
      .withId('plugin.auto-save')
      .withName('Auto Save')
      .withVersion('0.1.0')
      .withDescription(
        'Automatically saves file changes at configurable intervals',
      )
      .withAuthor('Editor Team')
      .withCapability('file.save', 'Automatically saves files')
      .withCapability('config.interval', 'Configurable save interval')
      .addActivationEvent('onFileOpen')
      .addActivationEvent('onFileContentChange')
      .build();

  @override
  Future<void> onInitialize(PluginContext context) async {
    await loadConfiguration(
      InMemoryStorageAdapter(),
      PluginId(value: manifest.id),
    );

    if (!hasConfiguration) {
      await updateConfiguration(
        (_) => PluginConfiguration.create(
          PluginId(value: manifest.id),
        ).updateSetting('config', AutoSaveConfig.defaultConfig().toJson()),
      );
    }

    _triggerSaveUseCase = TriggerSaveUseCase(context.fileRepository);

    final config = _getConfig();
    if (config.enabled) {
      _startTimer(config.interval);
    }
  }

  @override
  Future<void> onDispose() async {
    _disposed = true;
    _stopTimer();
    disposeStateful();
  }

  @override
  void onFileContentChange(String fileId, String content) {
    safeExecute('Track content change', () {
      // Throttle: Skip if changed too recently
      final lastChange = _lastContentChangeTime[fileId];
      final now = DateTime.now();

      if (lastChange != null) {
        final timeSinceLastChange = now.difference(lastChange);
        if (timeSinceLastChange < _contentChangeThrottle) {
          // Skip this change, too soon after last one
          return;
        }
      }

      // Track this change
      _unsavedContent[fileId] = content;
      _lastContentChangeTime[fileId] = now;
      setState('lastChange', now);
    });
  }

  @override
  void onFileClose(String fileId) {
    safeExecute('Clean up closed file', () {
      _unsavedContent.remove(fileId);
      _lastContentChangeTime.remove(fileId);
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
    // Guard: Don't save if plugin is disposed
    if (_disposed) return;

    if (_unsavedContent.isEmpty) return;

    await safeExecuteAsync('Auto-save all files', () async {
      // CRITICAL: Iterate over a copy of entries to avoid ConcurrentModificationError
      // We're removing items from _unsavedContent during iteration, which would cause:
      // "ConcurrentModificationError: Concurrent modification during iteration"
      // Creating a list copy ensures the iteration is safe
      for (final entry in _unsavedContent.entries.toList()) {
        final task = SaveTask.create(fileId: entry.key, content: entry.value);

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
