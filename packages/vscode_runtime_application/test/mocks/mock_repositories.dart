import 'package:dartz/dartz.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';

/// Mock implementation of IRuntimeRepository for testing
class MockRuntimeRepository implements IRuntimeRepository {
  final Map<InstallationId, RuntimeInstallation> _installations = {};
  RuntimeVersion? _installedVersion;
  final Map<ModuleId, bool> _installedModules = {};

  @override
  Future<Either<DomainException, Option<RuntimeVersion>>> getInstalledVersion() async {
    return right(optionOf(_installedVersion));
  }

  @override
  Future<Either<DomainException, Unit>> saveInstallation(
    RuntimeInstallation installation,
  ) async {
    _installations[installation.id] = installation;
    return right(unit);
  }

  @override
  Future<Either<DomainException, Option<RuntimeInstallation>>> getInstallation(
    InstallationId id,
  ) async {
    return right(optionOf(_installations[id]));
  }

  @override
  Future<Either<DomainException, bool>> isModuleInstalled(ModuleId moduleId) async {
    return right(_installedModules[moduleId] ?? false);
  }

  @override
  Future<Either<DomainException, List<RuntimeModule>>> getAvailableModules() async {
    // Return empty list by default, can be overridden in tests
    return right([]);
  }

  @override
  Future<Either<DomainException, Unit>> setInstalledVersion(RuntimeVersion version) async {
    _installedVersion = version;
    return right(unit);
  }

  @override
  Future<Either<DomainException, Unit>> setModuleInstalled(
    ModuleId moduleId,
    bool installed,
  ) async {
    if (installed) {
      _installedModules[moduleId] = true;
    } else {
      _installedModules.remove(moduleId);
    }
    return right(unit);
  }

  @override
  Future<Either<DomainException, Unit>> removeModule(ModuleId moduleId) async {
    _installedModules.remove(moduleId);
    return right(unit);
  }

  @override
  Future<Either<DomainException, List<RuntimeInstallation>>> getAllInstallations() async {
    return right(_installations.values.toList());
  }

  // Helper methods for testing
  void mockInstalledVersion(RuntimeVersion version) {
    _installedVersion = version;
  }

  void mockModuleInstalled(ModuleId moduleId) {
    _installedModules[moduleId] = true;
  }

  void reset() {
    _installations.clear();
    _installedVersion = null;
    _installedModules.clear();
  }
}

/// Mock implementation of IManifestRepository for testing
class MockManifestRepository implements IManifestRepository {
  List<RuntimeModule> _modules = [];
  RuntimeVersion? _latestVersion;

  @override
  Future<Either<DomainException, List<RuntimeModule>>> getModules({
    RuntimeVersion? version,
  }) async {
    return right(_modules);
  }

  @override
  Future<Either<DomainException, RuntimeVersion>> getLatestVersion() async {
    if (_latestVersion == null) {
      return left(DomainException('No latest version configured'));
    }
    return right(_latestVersion!);
  }

  @override
  Future<Either<DomainException, Option<RuntimeModule>>> getModule(
    ModuleId moduleId, {
    RuntimeVersion? version,
  }) async {
    final module = _modules.where((m) => m.id == moduleId).firstOrNull;
    return right(optionOf(module));
  }

  @override
  Future<Either<DomainException, Unit>> refreshManifest() async {
    return right(unit);
  }

  // Helper methods for testing
  void mockModules(List<RuntimeModule> modules) {
    _modules = modules;
  }

  void mockLatestVersion(RuntimeVersion version) {
    _latestVersion = version;
  }

  void reset() {
    _modules = [];
    _latestVersion = null;
  }
}
