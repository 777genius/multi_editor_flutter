import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';
import '../data_sources/manifest_data_source.dart';
import '../services/cache_service.dart';
import '../services/logging_service.dart';
import '../models/manifest_dto.dart';

/// Manifest Repository Implementation
/// Fetches and manages runtime module manifests with persistent caching
class ManifestRepository implements IManifestRepository {
  final ManifestDataSource _dataSource;
  final CacheService? _cacheService;
  final LoggingService _logger;
  RuntimeManifest? _inMemoryCache;

  static const _cacheKey = 'runtime_manifest';
  static const _cacheTtl = Duration(hours: 24);

  ManifestRepository(
    this._dataSource, {
    CacheService? cacheService,
    LoggingService? logger,
  })  : _cacheService = cacheService,
        _logger = logger ?? LoggingService();

  @override
  Future<Either<DomainException, RuntimeManifest>> fetchManifest() async {
    try {
      // Try in-memory cache first (fastest)
      if (_inMemoryCache != null) {
        _logger.debug('Returning manifest from in-memory cache');
        return right(_inMemoryCache!);
      }

      // Try persistent cache second
      if (_cacheService != null) {
        final cachedManifest = await _cacheService!.get<RuntimeManifest>(
          _cacheKey,
          deserializer: (jsonString) {
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            final dto = ManifestDto.fromJson(json);
            return dto.toManifest();
          },
        );

        if (cachedManifest != null) {
          _logger.info('Returning manifest from persistent cache');
          _inMemoryCache = cachedManifest;
          return right(cachedManifest);
        }
      }

      // Fetch from network as last resort
      _logger.info('Fetching fresh manifest from network');
      final manifestDto = await _dataSource.fetchManifest();
      final manifest = manifestDto.toManifest();

      // Update caches
      _inMemoryCache = manifest;

      if (_cacheService != null) {
        await _cacheService!.set<RuntimeManifest>(
          _cacheKey,
          manifest,
          serializer: (m) {
            // Convert back to DTO for JSON serialization
            final dto = ManifestDto(
              version: m.version.toString(),
              modules: m.modules.map((module) {
                return ModuleDto(
                  id: module.id.value,
                  name: module.name,
                  description: module.description,
                  version: module.version.toString(),
                  required: module.isRequired,
                  dependencies: module.dependencies.map((d) => d.value).toList(),
                  platforms: module.supportedPlatforms.map((p) => p.toString()).toList(),
                  artifacts: module.artifacts.map((a) {
                    return PlatformArtifactDto(
                      platform: a.platform.toString(),
                      downloadUrl: a.downloadUrl.value,
                      size: a.size.bytes,
                      checksum: a.checksum.value,
                    );
                  }).toList(),
                );
              }).toList(),
            );
            return jsonEncode(dto.toJson());
          },
          ttl: _cacheTtl,
        );
      }

      return right(manifest);
    } catch (e, stackTrace) {
      _logger.error('Failed to fetch manifest', e, stackTrace);
      return left(
        DomainException('Failed to fetch manifest: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<DomainException, Option<RuntimeManifest>>> getCachedManifest() async {
    // Check in-memory cache
    if (_inMemoryCache != null) {
      return right(some(_inMemoryCache!));
    }

    // Check persistent cache
    if (_cacheService != null) {
      final cachedManifest = await _cacheService!.get<RuntimeManifest>(
        _cacheKey,
        deserializer: (jsonString) {
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          final dto = ManifestDto.fromJson(json);
          return dto.toManifest();
        },
      );

      if (cachedManifest != null) {
        _inMemoryCache = cachedManifest;
        return right(some(cachedManifest));
      }
    }

    return right(none());
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
      final cachedManifestResult = await getCachedManifest();

      return cachedManifestResult.fold(
        (error) => left(error),
        (cachedOption) {
          return cachedOption.fold(
            () => right(true), // No cache, so fetch is needed
            (cached) async {
              final currentVersion = cached.version.toString();
              final hasUpdate = await _dataSource.hasUpdate(currentVersion);
              return right(hasUpdate);
            },
          );
        },
      );
    } catch (e) {
      _logger.error('Failed to check for manifest updates', e);
      return left(
        DomainException('Failed to check for updates: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<DomainException, RuntimeVersion>> getManifestVersion() async {
    try {
      // Check cache first
      final cachedManifestResult = await getCachedManifest();

      final versionFromCache = cachedManifestResult.fold(
        (error) => null,
        (cachedOption) => cachedOption.fold(
          () => null,
          (cached) => cached.version,
        ),
      );

      if (versionFromCache != null) {
        return right(versionFromCache);
      }

      // Fetch to get version
      final manifestResult = await fetchManifest();
      return manifestResult.fold(
        (error) => left(error),
        (manifest) => right(manifest.version),
      );
    } catch (e) {
      _logger.error('Failed to get manifest version', e);
      return left(
        DomainException('Failed to get manifest version: ${e.toString()}'),
      );
    }
  }

  /// Clear all caches
  Future<void> clearCache() async {
    _inMemoryCache = null;
    if (_cacheService != null) {
      await _cacheService!.remove(_cacheKey);
      _logger.info('Manifest cache cleared');
    }
  }
}
