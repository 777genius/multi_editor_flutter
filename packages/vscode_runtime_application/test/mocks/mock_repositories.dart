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
  Future<Either<DomainException, Option<RuntimeInstallation>>> loadInstallation(
    InstallationId installationId,
    List<RuntimeModule> modules,
  ) async {
    return right(optionOf(_installations[installationId]));
  }

  @override
  Future<Either<DomainException, List<RuntimeInstallation>>> getInstallationHistory() async {
    return right(_installations.values.toList());
  }

  @override
  Future<Either<DomainException, bool>> isModuleInstalled(ModuleId moduleId) async {
    return right(_installedModules[moduleId] ?? false);
  }

  @override
  Future<Either<DomainException, String>> getInstallationDirectory() async {
    return right('/tmp/vscode_runtime');
  }

  @override
  Future<Either<DomainException, String>> getModuleDirectory(ModuleId moduleId) async {
    return right('/tmp/vscode_runtime/modules/${moduleId.value}');
  }

  @override
  Future<Either<DomainException, Unit>> deleteInstallation([
    InstallationId? installationId,
  ]) async {
    if (installationId != null) {
      _installations.remove(installationId);
    } else {
      _installations.clear();
    }
    return right(unit);
  }

  @override
  Future<Either<DomainException, Unit>> saveInstalledVersion(
    RuntimeVersion version,
  ) async {
    _installedVersion = version;
    return right(unit);
  }

  @override
  Future<Either<DomainException, Option<RuntimeInstallation>>> getLatestInstallation() async {
    if (_installations.isEmpty) {
      return right(none());
    }
    final latest = _installations.values.reduce((a, b) =>
        a.createdAt.isAfter(b.createdAt) ? a : b);
    return right(some(latest));
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
  RuntimeManifest? _cachedManifest;

  @override
  Future<Either<DomainException, RuntimeManifest>> fetchManifest() async {
    if (_modules.isEmpty) {
      return left(DomainException('No modules configured'));
    }

    final manifest = RuntimeManifest(
      version: RuntimeVersion.fromString('1.0.0'),
      modules: _modules,
      publishedAt: DateTime.now(),
    );

    _cachedManifest = manifest;
    return right(manifest);
  }

  @override
  Future<Either<DomainException, Option<RuntimeManifest>>> getCachedManifest() async {
    return right(optionOf(_cachedManifest));
  }

  @override
  Future<Either<DomainException, List<RuntimeModule>>> getModules([
    PlatformIdentifier? platform,
  ]) async {
    if (platform != null) {
      // Filter modules by platform
      final filtered = _modules
          .where((m) => m.isAvailableForPlatform(platform))
          .toList();
      return right(filtered);
    }
    return right(_modules);
  }

  @override
  Future<Either<DomainException, Option<RuntimeModule>>> getModule(
    ModuleId moduleId,
  ) async {
    final module = _modules.where((m) => m.id == moduleId).firstOrNull;
    return right(optionOf(module));
  }

  @override
  Future<Either<DomainException, bool>> hasManifestUpdate() async {
    // Simple mock - always return false
    return right(false);
  }

  @override
  Future<Either<DomainException, RuntimeVersion>> getManifestVersion() async {
    if (_cachedManifest != null) {
      return right(_cachedManifest!.version);
    }
    return right(RuntimeVersion.fromString('1.0.0'));
  }

  // Helper methods for testing
  void mockModules(List<RuntimeModule> modules) {
    _modules = modules;
  }

  void mockModule(RuntimeModule module) {
    _modules = [module];
  }

  void reset() {
    _modules = [];
    _cachedManifest = null;
  }
}
