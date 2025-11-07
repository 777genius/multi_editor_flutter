import 'dart:async';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import 'package:flutter/foundation.dart';

/// Concrete implementation of PluginUIService for the presentation layer.
///
/// ## Architecture:
/// - Implements domain interface `PluginUIService`
/// - Lives in presentation layer (editor_ui)
/// - Manages UI registrations in-memory
///
/// ## SOLID Principles:
/// - **Single Responsibility**: manages plugin UI registrations only
/// - **Dependency Inversion**: plugins depend on abstract PluginUIService
///
/// ## Usage:
/// Register as a service in PluginContext:
/// ```dart
/// final uiRegistry = PluginUIRegistry();
/// pluginContext.registerService<PluginUIService>(uiRegistry);
/// ```
class PluginUIRegistry implements PluginUIService {
  final Map<String, PluginUIDescriptor> _registry = {};
  final StreamController<PluginUIUpdateEvent> _updateController =
      StreamController<PluginUIUpdateEvent>.broadcast();

  @override
  void registerUI(PluginUIDescriptor descriptor) {
    final existed = _registry.containsKey(descriptor.pluginId);

    _registry[descriptor.pluginId] = descriptor;

    final event = PluginUIUpdateEvent(
      type: existed
          ? PluginUIUpdateType.updated
          : PluginUIUpdateType.registered,
      descriptor: descriptor,
    );

    _updateController.add(event);

    debugPrint(
      '[PluginUIRegistry] ${existed ? 'Updated' : 'Registered'} UI for plugin: ${descriptor.pluginId}',
    );
  }

  @override
  void unregisterUI(String pluginId) {
    final descriptor = _registry.remove(pluginId);

    if (descriptor != null) {
      final event = PluginUIUpdateEvent(
        type: PluginUIUpdateType.unregistered,
        descriptor: descriptor,
      );

      _updateController.add(event);

      debugPrint('[PluginUIRegistry] Unregistered UI for plugin: $pluginId');
    }
  }

  @override
  List<PluginUIDescriptor> getRegisteredUIs() {
    // Sort by priority (lower number = higher priority)
    final list = _registry.values.toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
    return list;
  }

  @override
  PluginUIDescriptor? getUI(String pluginId) {
    return _registry[pluginId];
  }

  @override
  Stream<PluginUIUpdateEvent> get updates => _updateController.stream;

  @override
  bool hasUI(String pluginId) {
    return _registry.containsKey(pluginId);
  }

  /// Dispose resources
  void dispose() {
    _updateController.close();
    _registry.clear();
    debugPrint('[PluginUIRegistry] Disposed');
  }

  /// Get statistics for debugging
  Map<String, dynamic> getStatistics() {
    return {
      'totalRegistered': _registry.length,
      'plugins': _registry.keys.toList(),
    };
  }
}
