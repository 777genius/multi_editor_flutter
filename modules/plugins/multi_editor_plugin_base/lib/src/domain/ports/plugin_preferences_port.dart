import 'package:multi_editor_core/multi_editor_core.dart' hide Either, Left, Right;
import 'plugin_storage_port.dart';

abstract class PluginPreferencesPort {
  Future<Either<DomainFailure, String?>> getString(String key);

  Future<Either<DomainFailure, int?>> getInt(String key);

  Future<Either<DomainFailure, bool?>> getBool(String key);

  Future<Either<DomainFailure, double?>> getDouble(String key);

  Future<Either<DomainFailure, List<String>?>> getStringList(String key);

  Future<Either<DomainFailure, void>> setString(String key, String value);

  Future<Either<DomainFailure, void>> setInt(String key, int value);

  Future<Either<DomainFailure, void>> setBool(String key, bool value);

  Future<Either<DomainFailure, void>> setDouble(String key, double value);

  Future<Either<DomainFailure, void>> setStringList(String key, List<String> value);

  Future<Either<DomainFailure, void>> remove(String key);

  Future<Either<DomainFailure, void>> clear();
}
