import 'package:flutter_plugin_system_core/flutter_plugin_system_core.dart';

/// Host function registry
///
/// Central registry for host functions that plugins can call.
/// Provides registration, validation, and invocation of host functions.
///
/// ## Design Principles
///
/// - **Single Responsibility**: Only manages host function registration and calling
/// - **Type Safety**: Strongly typed function calls
/// - **Validation**: Validates function signatures before calling
///
/// ## Example
///
/// ```dart
/// final registry = HostFunctionRegistry();
///
/// // Register functions
/// registry.register('log_info', LogInfoFunction());
/// registry.register('get_current_file', GetCurrentFileFunction());
///
/// // Call function
/// final file = await registry.call<FileDocument>('get_current_file', []);
///
/// // Check if exists
/// if (registry.has('open_file')) {
///   await registry.call('open_file', ['/path/to/file']);
/// }
/// ```
class HostFunctionRegistry {
  final Map<String, HostFunction> _functions = {};
  final Map<String, int> _callCounts = {};

  /// Register host function
  ///
  /// Makes a function available for plugins to call.
  ///
  /// ## Parameters
  ///
  /// - `name`: Function name (snake_case recommended)
  /// - `function`: Function implementation
  ///
  /// ## Throws
  ///
  /// [StateError] if function with this name is already registered
  ///
  /// ## Example
  ///
  /// ```dart
  /// registry.register('log_info', LogInfoFunction());
  /// registry.register('get_file', GetFileFunction());
  /// ```
  void register<T>(String name, HostFunction<T> function) {
    if (_functions.containsKey(name)) {
      throw StateError('Host function already registered: $name');
    }

    _functions[name] = function;
    _callCounts[name] = 0;
  }

  /// Unregister host function
  ///
  /// Removes a function from the registry.
  ///
  /// ## Parameters
  ///
  /// - `name`: Function name to remove
  ///
  /// ## Returns
  ///
  /// `true` if function was removed, `false` if function was not found
  bool unregister(String name) {
    _callCounts.remove(name);
    return _functions.remove(name) != null;
  }

  /// Call host function
  ///
  /// Invokes a registered host function with arguments.
  ///
  /// ## Parameters
  ///
  /// - `name`: Function name
  /// - `args`: Function arguments (positional)
  ///
  /// ## Returns
  ///
  /// Function result (typed as T)
  ///
  /// ## Throws
  ///
  /// - [HostFunctionNotFoundException]: If function not registered
  /// - [ArgumentError]: If arguments are invalid
  /// - [HostFunctionException]: If function execution fails
  ///
  /// ## Example
  ///
  /// ```dart
  /// // No arguments
  /// final file = await registry.call<FileDocument>('get_current_file', []);
  ///
  /// // With arguments
  /// await registry.call('open_file', ['/path/to/file.txt']);
  ///
  /// // With multiple arguments
  /// final completions = await registry.call<List<CompletionItem>>(
  ///   'lsp_get_completions',
  ///   ['file123', 10, 5],
  /// );
  /// ```
  Future<T> call<T>(String name, List<dynamic> args) async {
    final function = _functions[name];
    if (function == null) {
      throw HostFunctionNotFoundException(name);
    }

    // Increment call count
    _callCounts[name] = (_callCounts[name] ?? 0) + 1;

    try {
      // Validate arguments
      if (!function.validateArgs(args)) {
        throw ArgumentError(
          'Invalid arguments for function $name: $args. '
          'Expected signature: ${function.signature}',
        );
      }

      // Call function
      final result = await function.call(args);
      return result as T;
    } catch (e, stack) {
      if (e is HostFunctionException) {
        rethrow;
      }
      throw HostFunctionException(
        name,
        'Host function failed: $e',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  /// Check if function exists
  ///
  /// ## Parameters
  ///
  /// - `name`: Function name
  ///
  /// ## Returns
  ///
  /// `true` if function is registered, `false` otherwise
  bool has(String name) {
    return _functions.containsKey(name);
  }

  /// Get function signature
  ///
  /// ## Parameters
  ///
  /// - `name`: Function name
  ///
  /// ## Returns
  ///
  /// Function signature or `null` if not registered
  HostFunctionSignature? getSignature(String name) {
    return _functions[name]?.signature;
  }

  /// Get all registered function names
  ///
  /// ## Returns
  ///
  /// List of all registered function names
  List<String> getAllFunctionNames() {
    return _functions.keys.toList();
  }

  /// Get all function signatures
  ///
  /// ## Returns
  ///
  /// Map of function name → signature
  Map<String, HostFunctionSignature> getAllSignatures() {
    return Map.fromEntries(
      _functions.entries.map(
        (entry) => MapEntry(entry.key, entry.value.signature),
      ),
    );
  }

  /// Get call count for function
  ///
  /// ## Parameters
  ///
  /// - `name`: Function name
  ///
  /// ## Returns
  ///
  /// Number of times function was called, or 0 if not registered
  int getCallCount(String name) {
    return _callCounts[name] ?? 0;
  }

  /// Get all call counts
  ///
  /// ## Returns
  ///
  /// Map of function name → call count
  Map<String, int> getAllCallCounts() {
    return Map.from(_callCounts);
  }

  /// Reset call count for function
  ///
  /// ## Parameters
  ///
  /// - `name`: Function name
  void resetCallCount(String name) {
    _callCounts[name] = 0;
  }

  /// Reset all call counts
  void resetAllCallCounts() {
    _callCounts.clear();
  }

  /// Get number of registered functions
  int get count => _functions.length;

  /// Check if registry is empty
  bool get isEmpty => _functions.isEmpty;

  /// Check if registry has functions
  bool get isNotEmpty => _functions.isNotEmpty;

  /// Clear all functions
  ///
  /// Removes all functions from registry.
  void clear() {
    _functions.clear();
    _callCounts.clear();
  }

  /// Get registry statistics
  ///
  /// ## Returns
  ///
  /// Map with statistics:
  /// - `total_functions`: Total number of registered functions
  /// - `total_calls`: Total number of function calls
  /// - `most_called`: Name of most called function
  Map<String, dynamic> getStatistics() {
    final totalCalls = _callCounts.values.fold<int>(0, (sum, count) => sum + count);

    String? mostCalled;
    int maxCalls = 0;
    for (final entry in _callCounts.entries) {
      if (entry.value > maxCalls) {
        maxCalls = entry.value;
        mostCalled = entry.key;
      }
    }

    return {
      'total_functions': _functions.length,
      'total_calls': totalCalls,
      if (mostCalled != null) 'most_called': mostCalled,
      if (mostCalled != null) 'most_called_count': maxCalls,
    };
  }

  @override
  String toString() {
    final stats = getStatistics();
    return 'HostFunctionRegistry(${stats['total_functions']} functions, ${stats['total_calls']} calls)';
  }
}
