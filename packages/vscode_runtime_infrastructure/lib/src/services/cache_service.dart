import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'logging_service.dart';

/// Cache Entry with expiration
class CacheEntry<T> {
  final T value;
  final DateTime expiresAt;

  CacheEntry({
    required this.value,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'value': value,
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory CacheEntry.fromJson(Map<String, dynamic> json, T value) {
    return CacheEntry(
      value: value,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}

/// Persistent Cache Service
/// Provides persistent caching with expiration using SharedPreferences
class CacheService {
  final SharedPreferences _prefs;
  final LoggingService _logger;
  final String _keyPrefix;

  CacheService({
    required SharedPreferences prefs,
    LoggingService? logger,
    String keyPrefix = 'cache_',
  })  : _prefs = prefs,
        _logger = logger ?? LoggingService(),
        _keyPrefix = keyPrefix;

  /// Get cached value if not expired
  Future<T?> get<T>(
    String key, {
    required T Function(String) deserializer,
  }) async {
    try {
      final fullKey = _keyPrefix + key;
      final jsonString = _prefs.getString(fullKey);

      if (jsonString == null) {
        _logger.debug('Cache miss: $key');
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(json['expiresAt'] as String);

      // Check if expired
      if (DateTime.now().toUtc().isAfter(expiresAt)) {
        _logger.debug('Cache expired: $key (expired at: $expiresAt)');
        await remove(key);
        return null;
      }

      final value = deserializer(json['value'] as String);
      _logger.debug('Cache hit: $key');
      return value;
    } catch (e) {
      _logger.error('Failed to read from cache: $key', e);
      return null;
    }
  }

  /// Set cached value with TTL (Time To Live)
  Future<bool> set<T>(
    String key,
    T value, {
    required String Function(T) serializer,
    Duration ttl = const Duration(hours: 24),
  }) async {
    try {
      final fullKey = _keyPrefix + key;
      final expiresAt = DateTime.now().toUtc().add(ttl);

      final entry = {
        'value': serializer(value),
        'expiresAt': expiresAt.toIso8601String(),
      };

      final jsonString = jsonEncode(entry);
      final success = await _prefs.setString(fullKey, jsonString);

      if (success) {
        _logger.debug('Cached: $key (expires at: $expiresAt)');
      } else {
        _logger.warning('Failed to cache: $key');
      }

      return success;
    } catch (e) {
      _logger.error('Failed to write to cache: $key', e);
      return false;
    }
  }

  /// Remove cached value
  Future<bool> remove(String key) async {
    try {
      final fullKey = _keyPrefix + key;
      final success = await _prefs.remove(fullKey);

      if (success) {
        _logger.debug('Removed from cache: $key');
      }

      return success;
    } catch (e) {
      _logger.error('Failed to remove from cache: $key', e);
      return false;
    }
  }

  /// Clear all cached values with our prefix
  Future<bool> clearAll() async {
    try {
      final keys = _prefs.getKeys().where((k) => k.startsWith(_keyPrefix));
      var success = true;

      for (final key in keys) {
        success = success && await _prefs.remove(key);
      }

      if (success) {
        _logger.info('Cleared all cache entries (${keys.length} items)');
      } else {
        _logger.warning('Failed to clear some cache entries');
      }

      return success;
    } catch (e) {
      _logger.error('Failed to clear cache', e);
      return false;
    }
  }

  /// Remove expired entries
  Future<int> removeExpired() async {
    try {
      final keys = _prefs.getKeys().where((k) => k.startsWith(_keyPrefix));
      var removedCount = 0;

      for (final fullKey in keys) {
        final jsonString = _prefs.getString(fullKey);
        if (jsonString == null) continue;

        try {
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          final expiresAt = DateTime.parse(json['expiresAt'] as String);

          if (DateTime.now().toUtc().isAfter(expiresAt)) {
            await _prefs.remove(fullKey);
            removedCount++;
          }
        } catch (e) {
          // Invalid entry, remove it
          await _prefs.remove(fullKey);
          removedCount++;
        }
      }

      if (removedCount > 0) {
        _logger.info('Removed $removedCount expired cache entries');
      }

      return removedCount;
    } catch (e) {
      _logger.error('Failed to remove expired entries', e);
      return 0;
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getStats() async {
    try {
      final keys = _prefs.getKeys().where((k) => k.startsWith(_keyPrefix)).toList();
      var expiredCount = 0;
      var validCount = 0;

      for (final fullKey in keys) {
        final jsonString = _prefs.getString(fullKey);
        if (jsonString == null) continue;

        try {
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          final expiresAt = DateTime.parse(json['expiresAt'] as String);

          if (DateTime.now().toUtc().isAfter(expiresAt)) {
            expiredCount++;
          } else {
            validCount++;
          }
        } catch (e) {
          expiredCount++;
        }
      }

      return {
        'total': keys.length,
        'valid': validCount,
        'expired': expiredCount,
      };
    } catch (e) {
      _logger.error('Failed to get cache stats', e);
      return {
        'total': 0,
        'valid': 0,
        'expired': 0,
      };
    }
  }
}
