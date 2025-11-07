import '../../domain/entities/plugin_configuration.dart';
import '../../domain/value_objects/plugin_id.dart';
import '../../domain/ports/plugin_storage_port.dart';

class LoadPluginConfigUseCase {
  final PluginStoragePort _storage;

  LoadPluginConfigUseCase(this._storage);

  Future<PluginConfiguration> execute(PluginId pluginId) async {
    final key = 'config.${pluginId.value}';

    final result = await _storage.load(key);

    return result.fold((failure) => PluginConfiguration.create(pluginId), (
      data,
    ) {
      try {
        return PluginConfiguration.fromJson(data);
      } catch (e) {
        return PluginConfiguration.create(pluginId);
      }
    });
  }
}
