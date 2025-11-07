import 'package:flutter/foundation.dart';

mixin StatefulPlugin {
  final Map<String, dynamic> _state = {};
  final ValueNotifier<int> _notifier = ValueNotifier(0);

  ValueListenable<int> get stateChanges => _notifier;

  T? getState<T>(String key) {
    final value = _state[key];
    return value is T ? value : null;
  }

  void setState(String key, dynamic value) {
    _state[key] = value;
    _notifier.value++;
  }

  void removeState(String key) {
    _state.remove(key);
    _notifier.value++;
  }

  void clearState() {
    _state.clear();
    _notifier.value++;
  }

  bool hasState(String key) => _state.containsKey(key);

  Map<String, dynamic> getAllState() => Map<String, dynamic>.from(_state);

  void disposeStateful() {
    _state.clear();
    _notifier.dispose();
  }
}
