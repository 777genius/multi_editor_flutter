import '../../domain/entities/file_icon.dart';
import '../../domain/repositories/icon_repository.dart';
import '../../domain/value_objects/file_extension.dart';
import '../services/icon_cache_service.dart';

/// Repository implementation with caching.
class IconRepositoryImpl implements IconRepository {
  final IconCacheService _cache;

  IconRepositoryImpl(this._cache);

  @override
  Future<FileIcon?> getIcon(FileExtension extension) async {
    return _cache.get(extension);
  }

  @override
  Future<Map<FileExtension, FileIcon>> getIcons(
    List<FileExtension> extensions,
  ) async {
    final result = <FileExtension, FileIcon>{};
    for (final ext in extensions) {
      final icon = await getIcon(ext);
      if (icon != null) {
        result[ext] = icon;
      }
    }
    return result;
  }

  @override
  Future<bool> hasIcon(FileExtension extension) async {
    return _cache.has(extension);
  }

  @override
  Future<void> clearCache() async {
    _cache.clear();
  }

  @override
  Future<IconRepositoryStats> getStats() async {
    return IconRepositoryStats(
      cachedIconsCount: _cache.size,
      totalRequests: 0,
      cacheHits: 0,
      cacheMisses: 0,
      failedRequests: 0,
    );
  }
}
