import 'dart:convert';
import 'package:multi_editor_core/multi_editor_core.dart' hide Either, Left, Right;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/ports/plugin_storage_port.dart';

class SharedPreferencesStorageAdapter implements PluginStoragePort {
  final SharedPreferences _prefs;

  SharedPreferencesStorageAdapter(this._prefs);

  static Future<SharedPreferencesStorageAdapter> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesStorageAdapter(prefs);
  }

  @override
  Future<Either<DomainFailure, Map<String, dynamic>>> load(String key) async {
    try {
      final jsonString = _prefs.getString(_prefixKey(key));
      if (jsonString == null) {
        return Left(DomainFailure.notFound(
          entityType: 'PluginConfig',
          entityId: key,
          message: 'Key not found: $key',
        ));
      }

      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      return Right(data);
    } catch (e) {
      return Left(DomainFailure.unexpected(message: 'Failed to load: $e'));
    }
  }

  @override
  Future<Either<DomainFailure, void>> save(String key, Map<String, dynamic> data) async {
    try {
      final jsonString = jsonEncode(data);
      final success = await _prefs.setString(_prefixKey(key), jsonString);
      if (!success) {
        return Left(DomainFailure.unexpected(message: 'Failed to save'));
      }
      return const Right(null);
    } catch (e) {
      return Left(DomainFailure.unexpected(message: 'Failed to save: $e'));
    }
  }

  @override
  Future<Either<DomainFailure, void>> delete(String key) async {
    try {
      final success = await _prefs.remove(_prefixKey(key));
      if (!success) {
        return Left(DomainFailure.unexpected(message: 'Failed to delete'));
      }
      return const Right(null);
    } catch (e) {
      return Left(DomainFailure.unexpected(message: 'Failed to delete: $e'));
    }
  }

  @override
  Future<Either<DomainFailure, bool>> exists(String key) async {
    try {
      final exists = _prefs.containsKey(_prefixKey(key));
      return Right(exists);
    } catch (e) {
      return Left(DomainFailure.unexpected(message: 'Failed to check existence: $e'));
    }
  }

  @override
  Future<Either<DomainFailure, List<String>>> getAllKeys() async {
    try {
      final keys = _prefs.getKeys()
          .where((key) => key.startsWith('plugin.storage.'))
          .map((key) => key.replaceFirst('plugin.storage.', ''))
          .toList();
      return Right(keys);
    } catch (e) {
      return Left(DomainFailure.unexpected(message: 'Failed to get keys: $e'));
    }
  }

  @override
  Future<Either<DomainFailure, void>> clear() async {
    try {
      final keysToRemove = _prefs.getKeys()
          .where((key) => key.startsWith('plugin.storage.'))
          .toList();

      for (final key in keysToRemove) {
        await _prefs.remove(key);
      }

      return const Right(null);
    } catch (e) {
      return Left(DomainFailure.unexpected(message: 'Failed to clear: $e'));
    }
  }

  String _prefixKey(String key) => 'plugin.storage.$key';
}
