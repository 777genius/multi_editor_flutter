import 'dart:async';

import 'package:flutter/foundation.dart';
import '../plugin_api/editor_plugin.dart';
import '../plugin_api/plugin_manifest.dart';

/// Factory function for creating plugin instances
typedef PluginFactory = FutureOr<EditorPlugin> Function();

/// Information about a registered plugin
class PluginRegistryEntry {
  final PluginManifest manifest;
  final PluginFactory factory;
  final bool autoLoad;
  final DateTime registeredAt;

  PluginRegistryEntry({
    required this.manifest,
    required this.factory,
    this.autoLoad = false,
    DateTime? registeredAt,
  }) : registeredAt = registeredAt ?? DateTime.now();

  /// Get plugin ID
  String get id => manifest.id;

  /// Get plugin name
  String get name => manifest.name;

  /// Get plugin version
  String get version => manifest.version;

  @override
  String toString() => 'PluginRegistryEntry($id v$version)';
}

/// Registry of available plugins (not necessarily activated)
class PluginRegistry extends ChangeNotifier {
  final Map<String, PluginRegistryEntry> _entries = {};
  final Map<String, EditorPlugin> _instances = {};

  /// Register a plugin with the registry
  void register({
    required PluginManifest manifest,
    required PluginFactory factory,
    bool autoLoad = false,
  }) {
    if (_entries.containsKey(manifest.id)) {
      throw PluginRegistryException(
        'Plugin "${manifest.id}" is already registered',
      );
    }

    _entries[manifest.id] = PluginRegistryEntry(
      manifest: manifest,
      factory: factory,
      autoLoad: autoLoad,
    );

    notifyListeners();
  }

  /// Unregister a plugin from the registry
  void unregister(String pluginId) {
    _entries.remove(pluginId);
    _instances.remove(pluginId);
    notifyListeners();
  }

  /// Check if a plugin is registered
  bool isRegistered(String pluginId) => _entries.containsKey(pluginId);

  /// Get registry entry for a plugin
  PluginRegistryEntry? getEntry(String pluginId) => _entries[pluginId];

  /// Get all registered plugin entries
  List<PluginRegistryEntry> get allEntries => _entries.values.toList();

  /// Get entries that should be auto-loaded
  List<PluginRegistryEntry> get autoLoadEntries {
    return _entries.values.where((e) => e.autoLoad).toList();
  }

  /// Get plugin instance (creates if not exists)
  Future<EditorPlugin> getInstance(String pluginId) async {
    // Return cached instance if exists
    if (_instances.containsKey(pluginId)) {
      return _instances[pluginId]!;
    }

    // Get entry
    final entry = _entries[pluginId];
    if (entry == null) {
      throw PluginRegistryException('Plugin "$pluginId" not found in registry');
    }

    // Create instance
    try {
      final instance = await entry.factory();
      _instances[pluginId] = instance;
      return instance;
    } catch (e, stackTrace) {
      debugPrint('[PluginRegistry] Failed to create instance of "$pluginId": $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Query plugins by criteria
  List<PluginRegistryEntry> query({
    String? namePattern,
    String? author,
    List<String>? tags,
    bool? autoLoad,
  }) {
    var results = _entries.values.toList();

    if (namePattern != null) {
      final pattern = RegExp(namePattern, caseSensitive: false);
      results = results.where((e) => pattern.hasMatch(e.name)).toList();
    }

    if (author != null) {
      results = results.where((e) => e.manifest.author == author).toList();
    }

    if (tags != null && tags.isNotEmpty) {
      results = results.where((e) {
        final pluginTags = _getPluginTags(e.manifest);
        return tags.any((tag) => pluginTags.contains(tag));
      }).toList();
    }

    if (autoLoad != null) {
      results = results.where((e) => e.autoLoad == autoLoad).toList();
    }

    return results;
  }

  /// Get tags from plugin metadata
  List<String> _getPluginTags(PluginManifest manifest) {
    final tags = manifest.metadata['tags'];
    if (tags is List) {
      return tags.cast<String>();
    }
    return [];
  }

  /// Get plugins by language support
  List<PluginRegistryEntry> getByLanguage(String language) {
    // We can't check supportsLanguage without creating instances,
    // so we filter by manifest data only
    return _entries.values.where((entry) {
      // Check if manifest has language info (custom metadata)
      final tags = _getPluginTags(entry.manifest);
      final description = entry.manifest.description ?? '';
      return tags.contains(language) ||
          description.toLowerCase().contains(language.toLowerCase());
    }).toList();
  }

  /// Get dependency graph for all registered plugins
  Map<String, List<String>> getDependencyGraph() {
    final graph = <String, List<String>>{};
    for (final entry in _entries.values) {
      graph[entry.id] = List<String>.from(entry.manifest.dependencies);
    }
    return graph;
  }

  /// Clear all entries and instances
  void clear() {
    _entries.clear();
    _instances.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }

  /// Get statistics about the registry
  RegistryStatistics get statistics {
    return RegistryStatistics(
      totalPlugins: _entries.length,
      autoLoadPlugins: autoLoadEntries.length,
      loadedInstances: _instances.length,
      byAuthor: _getAuthorStats(),
      byTags: _getTagStats(),
    );
  }

  Map<String, int> _getAuthorStats() {
    final stats = <String, int>{};
    for (final entry in _entries.values) {
      final author = entry.manifest.author ?? 'Unknown';
      stats[author] = (stats[author] ?? 0) + 1;
    }
    return stats;
  }

  Map<String, int> _getTagStats() {
    final stats = <String, int>{};
    for (final entry in _entries.values) {
      final tags = _getPluginTags(entry.manifest);
      for (final tag in tags) {
        stats[tag] = (stats[tag] ?? 0) + 1;
      }
    }
    return stats;
  }
}

/// Statistics about the plugin registry
class RegistryStatistics {
  final int totalPlugins;
  final int autoLoadPlugins;
  final int loadedInstances;
  final Map<String, int> byAuthor;
  final Map<String, int> byTags;

  RegistryStatistics({
    required this.totalPlugins,
    required this.autoLoadPlugins,
    required this.loadedInstances,
    required this.byAuthor,
    required this.byTags,
  });

  @override
  String toString() {
    return '''
RegistryStatistics:
  Total: $totalPlugins
  Auto-load: $autoLoadPlugins
  Loaded: $loadedInstances
  Authors: ${byAuthor.length}
  Tags: ${byTags.length}
''';
  }
}

class PluginRegistryException implements Exception {
  final String message;

  PluginRegistryException(this.message);

  @override
  String toString() => 'PluginRegistryException: $message';
}
