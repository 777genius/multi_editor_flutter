import '../../domain/entities/file_icon.dart';
import '../../domain/value_objects/file_extension.dart';

/// Simple LRU cache for file icons.
class IconCacheService {
  final int _maxSize;
  final Map<String, FileIcon> _cache = {};
  final List<String> _accessOrder = [];

  IconCacheService({int maxSize = 100}) : _maxSize = maxSize;

  /// Get icon from cache.
  FileIcon? get(FileExtension extension) {
    final key = extension.value;
    if (_cache.containsKey(key)) {
      // Update access order (LRU)
      _accessOrder.remove(key);
      _accessOrder.add(key);
      return _cache[key];
    }
    return null;
  }

  /// Put icon in cache.
  void put(FileExtension extension, FileIcon icon) {
    final key = extension.value;

    // Evict oldest if at capacity
    if (_cache.length >= _maxSize && !_cache.containsKey(key)) {
      final oldest = _accessOrder.removeAt(0);
      _cache.remove(oldest);
    }

    _cache[key] = icon;
    _accessOrder.remove(key);
    _accessOrder.add(key);
  }

  /// Check if icon is cached.
  bool has(FileExtension extension) {
    return _cache.containsKey(extension.value);
  }

  /// Clear cache.
  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }

  /// Get cache size.
  int get size => _cache.length;
}
