import '../../domain/entities/plugin_configuration.dart';
import '../../domain/ports/plugin_storage_port.dart';

class SavePluginConfigUseCase {
  final PluginStoragePort _storage;

  SavePluginConfigUseCase(this._storage);

  Future<void> execute(PluginConfiguration config) async {
    final key = 'config.${config.pluginId.value}';
    final result = await _storage.save(key, config.toJson());

    return result.fold(
      (failure) =>
          throw Exception('Failed to save config: ${failure.displayMessage}'),
      (_) => Future<void>.value(),
    );
  }
}
