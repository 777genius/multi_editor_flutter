import 'i_wasm_memory.dart';

/// WASM function type
///
/// Represents a callable WASM function.
typedef WasmFunction = Future<Object?> Function(List<Object?> args);

/// WASM instance interface
///
/// Represents an instantiated WASM module with its linear memory,
/// exported functions, and globals.
///
/// ## Lifecycle
///
/// 1. Module is loaded → IWasmModule
/// 2. Module is instantiated with imports → IWasmInstance
/// 3. Functions can be called → results
/// 4. Instance is disposed → resources freed
///
/// ## Example
///
/// ```dart
/// // Get exported function
/// final addFunction = instance.getFunction('add');
/// if (addFunction != null) {
///   final result = await addFunction([2, 3]); // Returns 5
/// }
///
/// // Access memory
/// final memory = instance.memory;
/// if (memory != null) {
///   await memory.write(ptr, data);
/// }
/// ```
abstract class IWasmInstance {
  /// Get linear memory
  ///
  /// Returns the WASM module's linear memory, or null if module
  /// doesn't export memory.
  IWasmMemory? get memory;

  /// Get exported function by name
  ///
  /// Returns a callable function if it exists and is exported.
  ///
  /// ## Parameters
  ///
  /// - `name`: Function name
  ///
  /// ## Returns
  ///
  /// Callable function, or null if not found
  ///
  /// ## Example
  ///
  /// ```dart
  /// final allocFn = instance.getFunction('alloc');
  /// if (allocFn != null) {
  ///   final ptr = await allocFn([1024]) as int; // Allocate 1024 bytes
  /// }
  /// ```
  WasmFunction? getFunction(String name);

  /// Get exported global value by name
  ///
  /// Returns a global variable value if it exists and is exported.
  ///
  /// ## Parameters
  ///
  /// - `name`: Global variable name
  ///
  /// ## Returns
  ///
  /// Global value, or null if not found
  ///
  /// ## Example
  ///
  /// ```dart
  /// final stackPointer = instance.getGlobal('__stack_pointer');
  /// ```
  Object? getGlobal(String name);

  /// Set exported global value by name
  ///
  /// Sets a global variable value if it exists, is exported, and is mutable.
  ///
  /// ## Parameters
  ///
  /// - `name`: Global variable name
  /// - `value`: New value
  ///
  /// ## Throws
  ///
  /// - [ArgumentError] if global is immutable or doesn't exist
  ///
  /// ## Example
  ///
  /// ```dart
  /// instance.setGlobal('__heap_base', 65536);
  /// ```
  void setGlobal(String name, Object? value);

  /// List all exported function names
  ///
  /// Returns a list of all function names exported by the module.
  ///
  /// ## Returns
  ///
  /// List of function names
  ///
  /// ## Example
  ///
  /// ```dart
  /// final functions = instance.listFunctions();
  /// print('Available functions: $functions');
  /// ```
  List<String> listFunctions();

  /// List all exported global names
  ///
  /// Returns a list of all global variable names exported by the module.
  ///
  /// ## Returns
  ///
  /// List of global names
  List<String> listGlobals();

  /// Dispose instance and free resources
  ///
  /// Frees all resources associated with this instance.
  /// After disposal, the instance cannot be used.
  ///
  /// ## Example
  ///
  /// ```dart
  /// await instance.dispose();
  /// // instance can no longer be used
  /// ```
  Future<void> dispose();
}
