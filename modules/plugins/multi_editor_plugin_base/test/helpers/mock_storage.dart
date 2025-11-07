import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugin_base/src/domain/ports/plugin_storage_port.dart'
    as storage_port;

/// Mock in-memory storage for testing
class MockPluginStorage implements storage_port.PluginStoragePort {
  final Map<String, Map<String, dynamic>> _storage = {};
  bool _shouldFail = false;

  /// Simulate storage failures for testing error handling
  void setShouldFail(bool shouldFail) {
    _shouldFail = shouldFail;
  }

  @override
  Future<storage_port.Either<DomainFailure, Map<String, dynamic>>> load(
    String key,
  ) async {
    if (_shouldFail) {
      return storage_port.Left(
        DomainFailure.unexpected(message: 'Storage load failed'),
      );
    }

    if (_storage.containsKey(key)) {
      return storage_port.Right(Map<String, dynamic>.from(_storage[key]!));
    }

    return storage_port.Left(
      DomainFailure.notFound(entityType: 'Config', entityId: key),
    );
  }

  @override
  Future<storage_port.Either<DomainFailure, void>> save(
    String key,
    Map<String, dynamic> data,
  ) async {
    if (_shouldFail) {
      return storage_port.Left(
        DomainFailure.unexpected(message: 'Storage save failed'),
      );
    }

    _storage[key] = Map<String, dynamic>.from(data);
    return const storage_port.Right(null);
  }

  @override
  Future<storage_port.Either<DomainFailure, void>> delete(String key) async {
    if (_shouldFail) {
      return storage_port.Left(
        DomainFailure.unexpected(message: 'Storage delete failed'),
      );
    }

    _storage.remove(key);
    return const storage_port.Right(null);
  }

  @override
  Future<storage_port.Either<DomainFailure, bool>> exists(String key) async {
    if (_shouldFail) {
      return storage_port.Left(
        DomainFailure.unexpected(message: 'Storage exists check failed'),
      );
    }

    return storage_port.Right(_storage.containsKey(key));
  }

  @override
  Future<storage_port.Either<DomainFailure, List<String>>> getAllKeys() async {
    if (_shouldFail) {
      return storage_port.Left(
        DomainFailure.unexpected(message: 'Storage getAllKeys failed'),
      );
    }

    return storage_port.Right(List<String>.from(_storage.keys));
  }

  @override
  Future<storage_port.Either<DomainFailure, void>> clear() async {
    if (_shouldFail) {
      return storage_port.Left(
        DomainFailure.unexpected(message: 'Storage clear failed'),
      );
    }

    _storage.clear();
    return const storage_port.Right(null);
  }

  /// Helper method to get all stored data (for testing)
  Map<String, Map<String, dynamic>> getAllData() {
    return Map.unmodifiable(_storage);
  }

  /// Helper method to clear all data (for test cleanup)
  void reset() {
    _storage.clear();
    _shouldFail = false;
  }
}
