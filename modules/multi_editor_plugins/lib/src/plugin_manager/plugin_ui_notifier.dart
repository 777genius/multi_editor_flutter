import 'package:flutter/foundation.dart';
import '../plugin_api/editor_plugin.dart';

/// Notifier that listens to all plugins' state changes and triggers UI rebuilds
/// Supports plugins with stateChanges property (duck typing)
class PluginUINotifier extends ChangeNotifier {
  final List<EditorPlugin> _plugins;
  final List<VoidCallback> _listeners = [];
  final List<dynamic> _notifiers = [];

  PluginUINotifier(this._plugins) {
    _subscribeToPlugins();
  }

  void _subscribeToPlugins() {
    for (final plugin in _plugins) {
      // Duck typing: check if plugin has stateChanges property
      try {
        final dynamic pluginDynamic = plugin;
        final stateChanges = pluginDynamic.stateChanges as ValueListenable<int>?;
        if (stateChanges != null) {
          void listener() => notifyListeners();
          stateChanges.addListener(listener);
          _listeners.add(listener);
          _notifiers.add(stateChanges);
        }
      } catch (_) {
        // Plugin doesn't have stateChanges, skip it
      }
    }
  }

  void _unsubscribeFromPlugins() {
    for (var i = 0; i < _notifiers.length; i++) {
      if (i < _listeners.length) {
        final notifier = _notifiers[i] as ValueListenable<int>;
        notifier.removeListener(_listeners[i]);
      }
    }
    _listeners.clear();
    _notifiers.clear();
  }

  @override
  void dispose() {
    _unsubscribeFromPlugins();
    super.dispose();
  }
}
