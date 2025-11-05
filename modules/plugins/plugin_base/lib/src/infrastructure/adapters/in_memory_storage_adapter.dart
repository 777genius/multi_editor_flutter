import 'package:editor_core/editor_core.dart' hide Either, Left, Right;
import '../../domain/ports/plugin_storage_port.dart';

class InMemoryStorageAdapter implements PluginStoragePort {
  final Map<String, Map<String, dynamic>> _storage = {};

  @override
  Future<Either<DomainFailure, Map<String, dynamic>>> load(String key) async {
    if (!_storage.containsKey(key)) {
      return Left(DomainFailure.notFound(
        entityType: 'PluginConfig',
        entityId: key,
        message: 'Key not found: $key',
      ));
    }

    return Right(Map<String, dynamic>.from(_storage[key]!));
  }

  @override
  Future<Either<DomainFailure, void>> save(String key, Map<String, dynamic> data) async {
    _storage[key] = Map<String, dynamic>.from(data);
    return const Right(null);
  }

  @override
  Future<Either<DomainFailure, void>> delete(String key) async {
    _storage.remove(key);
    return const Right(null);
  }

  @override
  Future<Either<DomainFailure, bool>> exists(String key) async {
    return Right(_storage.containsKey(key));
  }

  @override
  Future<Either<DomainFailure, List<String>>> getAllKeys() async {
    return Right(_storage.keys.toList());
  }

  @override
  Future<Either<DomainFailure, void>> clear() async {
    _storage.clear();
    return const Right(null);
  }

  void reset() {
    _storage.clear();
  }
}
