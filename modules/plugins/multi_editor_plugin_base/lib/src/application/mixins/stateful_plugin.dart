import 'package:flutter/foundation.dart';

mixin StatefulPlugin {
  final Map<String, dynamic> _state = {};
  final ValueNotifier<int> _notifier = ValueNotifier(0);
  bool _disposed = false;

  ValueListenable<int> get stateChanges => _notifier;

  T? getState<T>(String key) {
    final value = _state[key];
    return value is T ? value : null;
  }

  void setState(String key, dynamic value) {
    if (_disposed) return; // Guard: Don't update state after dispose
    _state[key] = value;
    _notifier.value++;
  }

  void removeState(String key) {
    if (_disposed) return; // Guard: Don't update state after dispose
    _state.remove(key);
    _notifier.value++;
  }

  void clearState() {
    if (_disposed) return; // Guard: Don't update state after dispose
    _state.clear();
    _notifier.value++;
  }

  bool hasState(String key) => _state.containsKey(key);

  Map<String, dynamic> getAllState() => Map<String, dynamic>.from(_state);

  void disposeStateful() {
    _disposed = true;
    _state.clear();
    _notifier.dispose();
  }
}
