import 'package:flutter_plugin_system_wasm/flutter_plugin_system_wasm.dart';
import 'wasm_run_memory.dart';

/// WasmRun instance implementation
///
/// Implements IWasmInstance interface using wasm_run's instantiated module.
/// Provides access to exported functions, memory, and globals.
///
/// ## Lifecycle
///
/// 1. Module instantiated → WasmRunInstance created
/// 2. Functions can be called
/// 3. Memory can be accessed
/// 4. Instance disposed → resources freed
///
/// ## Example
///
/// ```dart
/// final instance = WasmRunInstance(wasmInstance);
///
/// // Call function
/// final addFn = instance.getFunction('add');
/// final result = await addFn!([2, 3]); // Returns 5
///
/// // Access memory
/// final memory = instance.memory;
/// await memory?.write(ptr, data);
/// ```
class WasmRunInstance implements IWasmInstance {
  // TODO: Replace with actual wasm_run instance type when available
  final Object _wasmInstance;

  final WasmRunMemory? _memory;
  final Map<String, WasmFunction> _functions = {};
  final Map<String, Object?> _globals = {};

  bool _disposed = false;

  /// Create wasm_run instance wrapper
  ///
  /// ## Parameters
  ///
  /// - `wasmInstance`: Underlying wasm_run instance object
  /// - `memory`: Optional memory (if exported)
  WasmRunInstance(
    this._wasmInstance, {
    WasmRunMemory? memory,
  }) : _memory = memory {
    _initializeExports();
  }

  @override
  IWasmMemory? get memory => _memory;

  @override
  WasmFunction? getFunction(String name) {
    _checkDisposed();
    return _functions[name];
  }

  @override
  Object? getGlobal(String name) {
    _checkDisposed();
    return _globals[name];
  }

  @override
  void setGlobal(String name, Object? value) {
    _checkDisposed();

    if (!_globals.containsKey(name)) {
      throw ArgumentError('Global not found: $name');
    }

    // TODO: Check if global is mutable
    _globals[name] = value;
  }

  @override
  List<String> listFunctions() {
    _checkDisposed();
    return _functions.keys.toList();
  }

  @override
  List<String> listGlobals() {
    _checkDisposed();
    return _globals.keys.toList();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;

    _disposed = true;
    _functions.clear();
    _globals.clear();

    // TODO: Call wasm_run instance dispose
  }

  /// Initialize exports
  ///
  /// Discovers and registers all exported functions and globals.
  /// In production, this would inspect wasm_run instance exports.
  void _initializeExports() {
    // TODO: Replace with actual wasm_run export inspection

    // For now, register common plugin functions as stubs
    _registerStubFunctions();
  }

  /// Register stub functions for development
  ///
  /// These are placeholder implementations until wasm_run is integrated.
  void _registerStubFunctions() {
    // Memory management functions
    _functions['alloc'] = _createStubFunction('alloc');
    _functions['dealloc'] = _createStubFunction('dealloc');

    // Plugin interface functions
    _functions['plugin_initialize'] = _createStubFunction('plugin_initialize');
    _functions['plugin_handle_event'] =
        _createStubFunction('plugin_handle_event');
    _functions['plugin_dispose'] = _createStubFunction('plugin_dispose');
    _functions['plugin_get_manifest'] =
        _createStubFunction('plugin_get_manifest');
  }

  /// Create stub function
  ///
  /// Creates a placeholder function that returns appropriate values.
  WasmFunction _createStubFunction(String name) {
    return (List<Object?> args) async {
      // Simulate function behavior
      switch (name) {
        case 'alloc':
          // Return pointer (simulated)
          final size = args[0] as int;
          return 1000 + size; // Fake pointer

        case 'dealloc':
          // No return value
          return null;

        case 'plugin_initialize':
          // Return success code
          return 0;

        case 'plugin_handle_event':
          // Return packed ptr + len (simulated response)
          return ((1000 << 32) | 100); // ptr=1000, len=100

        case 'plugin_dispose':
          // Return success code
          return 0;

        case 'plugin_get_manifest':
          // Return packed ptr + len (simulated manifest)
          return ((2000 << 32) | 200); // ptr=2000, len=200

        default:
          throw UnimplementedError('Function not implemented: $name');
      }
    };
  }

  /// Check if instance is disposed
  void _checkDisposed() {
    if (_disposed) {
      throw StateError('Instance has been disposed');
    }
  }

  /// Get instance statistics
  ///
  /// Returns statistics about the instance.
  ///
  /// ## Returns
  ///
  /// Map with statistics:
  /// - `functions`: Number of exported functions
  /// - `globals`: Number of exported globals
  /// - `memory_size`: Memory size in bytes (if memory exported)
  /// - `disposed`: Whether instance is disposed
  ///
  /// ## Example
  ///
  /// ```dart
  /// final stats = instance.getStatistics();
  /// print('Functions: ${stats['functions']}');
  /// ```
  Map<String, dynamic> getStatistics() {
    return {
      'functions': _functions.length,
      'globals': _globals.length,
      'memory_size': _memory?.size ?? 0,
      'memory_pages': _memory?.sizeInPages ?? 0,
      'disposed': _disposed,
    };
  }

  /// Call function by name with arguments
  ///
  /// Convenience method to call a function directly.
  ///
  /// ## Parameters
  ///
  /// - `functionName`: Name of function to call
  /// - `args`: Function arguments
  ///
  /// ## Returns
  ///
  /// Function result
  ///
  /// ## Throws
  ///
  /// - [ArgumentError] if function not found
  ///
  /// ## Example
  ///
  /// ```dart
  /// final result = await instance.call('add', [2, 3]);
  /// print('Result: $result'); // 5
  /// ```
  Future<Object?> call(String functionName, List<Object?> args) async {
    _checkDisposed();

    final function = getFunction(functionName);
    if (function == null) {
      throw ArgumentError('Function not found: $functionName');
    }

    return await function(args);
  }

  /// Check if function exists
  ///
  /// Returns true if the function is exported by the module.
  ///
  /// ## Parameters
  ///
  /// - `name`: Function name
  ///
  /// ## Returns
  ///
  /// `true` if function exists, `false` otherwise
  bool hasFunction(String name) {
    _checkDisposed();
    return _functions.containsKey(name);
  }

  /// Check if global exists
  ///
  /// Returns true if the global is exported by the module.
  ///
  /// ## Parameters
  ///
  /// - `name`: Global name
  ///
  /// ## Returns
  ///
  /// `true` if global exists, `false` otherwise
  bool hasGlobal(String name) {
    _checkDisposed();
    return _globals.containsKey(name);
  }
}
