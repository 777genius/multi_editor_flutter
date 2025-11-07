import 'dart:async';
import 'package:flutter/foundation.dart';

typedef HookCallback<T> = FutureOr<void> Function(T data);
typedef HookErrorCallback =
    void Function(String hookName, Object error, StackTrace stackTrace);

class HookExecutionMetrics {
  int successCount = 0;
  int errorCount = 0;
  Duration totalExecutionTime = Duration.zero;
  final List<HookExecutionError> recentErrors = [];

  void recordSuccess(Duration executionTime) {
    successCount++;
    totalExecutionTime += executionTime;
  }

  void recordError(String hookName, Object error, StackTrace stackTrace) {
    errorCount++;
    recentErrors.add(
      HookExecutionError(
        hookName: hookName,
        error: error,
        stackTrace: stackTrace,
        timestamp: DateTime.now(),
      ),
    );
    if (recentErrors.length > 10) {
      recentErrors.removeAt(0);
    }
  }

  double get averageExecutionMs =>
      successCount > 0 ? totalExecutionTime.inMilliseconds / successCount : 0;
}

class HookExecutionError {
  final String hookName;
  final Object error;
  final StackTrace stackTrace;
  final DateTime timestamp;

  HookExecutionError({
    required this.hookName,
    required this.error,
    required this.stackTrace,
    required this.timestamp,
  });
}

class Hook<T> {
  final String name;
  final List<HookCallback<T>> _callbacks = [];
  final HookErrorCallback? onError;
  final HookExecutionMetrics metrics = HookExecutionMetrics();

  Hook(this.name, {this.onError});

  void register(HookCallback<T> callback) {
    _callbacks.add(callback);
  }

  void unregister(HookCallback<T> callback) {
    _callbacks.remove(callback);
  }

  Future<void> execute(T data) async {
    for (var i = 0; i < _callbacks.length; i++) {
      final callback = _callbacks[i];
      final stopwatch = Stopwatch()..start();

      try {
        await callback(data);
        stopwatch.stop();
        metrics.recordSuccess(stopwatch.elapsed);
      } catch (e, stackTrace) {
        stopwatch.stop();

        // Log error with context
        debugPrint('[HookRegistry] Error in hook "$name" callback #$i:');
        debugPrint('[HookRegistry] Error: $e');
        debugPrint('[HookRegistry] StackTrace: $stackTrace');

        // Record metrics
        metrics.recordError(name, e, stackTrace);

        // Call error callback if provided
        onError?.call(name, e, stackTrace);

        // Continue with next callback
      }
    }
  }

  int get callbackCount => _callbacks.length;

  void clear() {
    _callbacks.clear();
  }
}

class HookRegistry {
  final Map<String, Hook<dynamic>> _hooks = {};
  HookErrorCallback? _globalErrorHandler;

  HookRegistry({HookErrorCallback? onError}) : _globalErrorHandler = onError;

  void setGlobalErrorHandler(HookErrorCallback handler) {
    _globalErrorHandler = handler;
  }

  Hook<T> getOrCreate<T>(String hookName) {
    if (_hooks.containsKey(hookName)) {
      return _hooks[hookName]! as Hook<T>;
    }
    final hook = Hook<T>(hookName, onError: _globalErrorHandler);
    _hooks[hookName] = hook;
    return hook;
  }

  Hook<T>? get<T>(String hookName) {
    return _hooks[hookName] as Hook<T>?;
  }

  void register<T>(String hookName, HookCallback<T> callback) {
    final hook = getOrCreate<T>(hookName);
    hook.register(callback);
  }

  void unregister<T>(String hookName, HookCallback<T> callback) {
    final hook = get<T>(hookName);
    hook?.unregister(callback);
  }

  Future<void> execute<T>(String hookName, T data) async {
    final hook = get<T>(hookName);
    if (hook != null) {
      await hook.execute(data);
    }
  }

  List<String> get allHookNames => _hooks.keys.toList();

  Map<String, HookExecutionMetrics> getAllMetrics() {
    return Map.fromEntries(
      _hooks.entries.map((e) => MapEntry(e.key, e.value.metrics)),
    );
  }

  HookExecutionMetrics? getMetrics(String hookName) {
    return _hooks[hookName]?.metrics;
  }

  void clear() {
    for (final hook in _hooks.values) {
      hook.clear();
    }
    _hooks.clear();
  }
}
