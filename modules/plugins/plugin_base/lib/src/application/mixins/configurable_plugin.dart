import 'package:editor_plugins/editor_plugins.dart';
import '../../domain/entities/plugin_configuration.dart';
import '../../domain/value_objects/plugin_id.dart';
import '../../domain/ports/plugin_storage_port.dart';

mixin ConfigurablePlugin on EditorPlugin {
  PluginConfiguration? _configuration;
  PluginStoragePort? _storage;

  PluginConfiguration get configuration {
    if (_configuration == null) {
      throw StateError('Configuration not loaded. Call loadConfiguration() first.');
    }
    return _configuration!;
  }

  bool get hasConfiguration => _configuration != null;

  Future<void> loadConfiguration(
    PluginStoragePort storage,
    PluginId pluginId,
  ) async {
    _storage = storage;
    final key = 'config.${pluginId.value}';

    final result = await storage.load(key);
    _configuration = result.fold(
      (failure) => PluginConfiguration.create(pluginId),
      (data) {
        try {
          return PluginConfiguration.fromJson(data);
        } catch (e) {
          return PluginConfiguration.create(pluginId);
        }
      },
    );
  }

  Future<void> saveConfiguration() async {
    if (_storage == null || _configuration == null) {
      throw StateError('Cannot save: storage or configuration not initialized');
    }

    final key = 'config.${_configuration!.pluginId.value}';
    await _storage!.save(key, _configuration!.toJson());
  }

  Future<void> updateConfiguration(
    PluginConfiguration Function(PluginConfiguration) update,
  ) async {
    if (_configuration == null) {
      throw StateError('Configuration not loaded');
    }

    _configuration = update(_configuration!);
    await saveConfiguration();
  }

  T? getConfigSetting<T>(String key, {T? defaultValue}) {
    return _configuration?.getSetting<T>(key, defaultValue: defaultValue);
  }

  Future<void> setConfigSetting(String key, dynamic value) async {
    if (_configuration == null) {
      throw StateError('Configuration not loaded');
    }

    _configuration = _configuration!.updateSetting(key, value);
    await saveConfiguration();
  }

  bool get isEnabled => _configuration?.enabled ?? false;

  Future<void> enable() async {
    if (_configuration == null) {
      throw StateError('Configuration not loaded');
    }

    _configuration = _configuration!.enable();
    await saveConfiguration();
  }

  Future<void> disable() async {
    if (_configuration == null) {
      throw StateError('Configuration not loaded');
    }

    _configuration = _configuration!.disable();
    await saveConfiguration();
  }
}
