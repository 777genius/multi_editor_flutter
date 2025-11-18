import 'package:dartz/dartz.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';
import '../data_sources/manifest_data_source.dart';

/// Manifest Repository Implementation
/// Fetches and manages runtime module manifests
class ManifestRepository implements IManifestRepository {
  final ManifestDataSource _dataSource;
  RuntimeManifest? _cachedManifest;

  ManifestRepository(this._dataSource);

  @override
  Future<Either<DomainException, RuntimeManifest>> fetchManifest() async {
    try {
      final manifestDto = await _dataSource.fetchManifest();

      final manifest = manifestDto.toManifest();

      _cachedManifest = manifest;

      return right(manifest);
    } catch (e) {
      return left(
        DomainException('Failed to fetch manifest: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<DomainException, Option<RuntimeManifest>>> getCachedManifest() async {
    return right(optionOf(_cachedManifest));
  }

  @override
  Future<Either<DomainException, List<RuntimeModule>>> getModules([
    PlatformIdentifier? platform,
  ]) async {
    try {
      final manifestResult = await fetchManifest();

      return manifestResult.fold(
        (error) => left(error),
        (manifest) {
          if (platform != null) {
            // Filter modules that support the target platform
            final compatibleModules = manifest.modules
                .where((m) => m.isAvailableForPlatform(platform))
                .toList();
            return right(compatibleModules);
          }

          return right(manifest.modules);
        },
      );
    } catch (e) {
      return left(
        DomainException('Failed to get modules: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<DomainException, Option<RuntimeModule>>> getModule(
    ModuleId moduleId,
  ) async {
    try {
      final modulesResult = await getModules();

      return modulesResult.fold(
        (error) => left(error),
        (modules) {
          final module = modules.where((m) => m.id == moduleId).firstOrNull;
          return right(optionOf(module));
        },
      );
    } catch (e) {
      return left(
        DomainException('Failed to get module: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<DomainException, bool>> hasManifestUpdate() async {
    try {
      // Get current cached version
      if (_cachedManifest == null) {
        // No cache, so fetch is needed
        return right(true);
      }

      final currentVersion = _cachedManifest!.version.toString();
      final hasUpdate = await _dataSource.hasUpdate(currentVersion);

      return right(hasUpdate);
    } catch (e) {
      return left(
        DomainException('Failed to check for updates: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<DomainException, RuntimeVersion>> getManifestVersion() async {
    try {
      if (_cachedManifest != null) {
        return right(_cachedManifest!.version);
      }

      // Fetch to get version
      final manifestResult = await fetchManifest();
      return manifestResult.fold(
        (error) => left(error),
        (manifest) => right(manifest.version),
      );
    } catch (e) {
      return left(
        DomainException('Failed to get manifest version: ${e.toString()}'),
      );
    }
  }
}
