import 'dart:typed_data';
import 'i_wasm_instance.dart';
import 'i_wasm_module.dart';

/// WASM runtime features
///
/// Describes features supported by a WASM runtime.
///
/// ## Example
///
/// ```dart
/// final features = runtime.supportedFeatures;
/// if (features.supportsMultiValue) {
///   print('Runtime supports multi-value returns');
/// }
/// ```
class WasmFeatures {
  /// Supports WASI (WebAssembly System Interface)
  final bool supportsWasi;

  /// Supports multi-value returns
  final bool supportsMultiValue;

  /// Supports bulk memory operations
  final bool supportsBulkMemory;

  /// Supports reference types
  final bool supportsReferenceTypes;

  /// Supports SIMD (Single Instruction Multiple Data)
  final bool supportsSimd;

  /// Supports threads and atomics
  final bool supportsThreads;

  /// Supports tail calls
  final bool supportsTailCalls;

  /// Supports exceptions
  final bool supportsExceptions;

  /// Custom features (runtime-specific)
  final Map<String, bool> customFeatures;

  const WasmFeatures({
    this.supportsWasi = false,
    this.supportsMultiValue = false,
    this.supportsBulkMemory = false,
    this.supportsReferenceTypes = false,
    this.supportsSimd = false,
    this.supportsThreads = false,
    this.supportsTailCalls = false,
    this.supportsExceptions = false,
    this.customFeatures = const {},
  });
}

/// WASM runtime configuration
///
/// Configuration options for WASM runtime behavior.
///
/// ## Example
///
/// ```dart
/// final config = WasmRuntimeConfig(
///   enableOptimization: true,
///   maxMemoryPages: 1024, // 64MB max memory
///   fuelLimit: 1000000,   // Execution limit
/// );
/// ```
class WasmRuntimeConfig {
  /// Enable JIT optimization (if supported)
  final bool enableOptimization;

  /// Maximum memory pages (64KB per page)
  final int? maxMemoryPages;

  /// Maximum call stack depth
  final int? maxStackDepth;

  /// Fuel limit for execution metering (if supported)
  final int? fuelLimit;

  /// Enable WASI support
  final bool enableWasi;

  /// Custom configuration options
  final Map<String, dynamic> custom;

  const WasmRuntimeConfig({
    this.enableOptimization = true,
    this.maxMemoryPages,
    this.maxStackDepth,
    this.fuelLimit,
    this.enableWasi = false,
    this.custom = const {},
  });
}

/// WASM runtime interface
///
/// Represents a WASM runtime engine capable of loading and executing
/// WebAssembly modules.
///
/// ## Implementations
///
/// - **WasmRunRuntime**: Uses wasm_run package (wasmtime/wasmi)
/// - **ExtismRuntime**: Uses Extism (future)
/// - **WasmEdgeRuntime**: Uses WasmEdge (future)
///
/// ## Example
///
/// ```dart
/// // Create runtime
/// final runtime = WasmRunRuntime(config: WasmRuntimeConfig(
///   enableOptimization: true,
///   maxMemoryPages: 1024,
/// ));
///
/// // Load module
/// final module = await runtime.loadModule(wasmBytes);
///
/// // Instantiate with imports
/// final instance = await runtime.instantiate(module, {
///   'env': {
///     'log_info': WasmImport.function(logInfoFunction),
///   },
/// });
///
/// // Call function
/// final result = await instance.getFunction('add')!([2, 3]);
/// print('Result: $result'); // 5
///
/// // Cleanup
/// await instance.dispose();
/// await module.dispose();
/// await runtime.dispose();
/// ```
abstract class IWasmRuntime {
  /// Runtime name
  ///
  /// Returns the name of the runtime implementation.
  String get name;

  /// Runtime version
  ///
  /// Returns the version of the runtime implementation.
  String get version;

  /// Supported features
  ///
  /// Returns the WASM features supported by this runtime.
  WasmFeatures get supportedFeatures;

  /// Runtime configuration
  ///
  /// Returns the configuration used by this runtime.
  WasmRuntimeConfig get config;

  /// Load WASM module from bytes
  ///
  /// Compiles WASM bytecode into a module ready for instantiation.
  ///
  /// ## Parameters
  ///
  /// - `wasmBytes`: WASM binary module
  ///
  /// ## Returns
  ///
  /// Loaded WASM module
  ///
  /// ## Throws
  ///
  /// - [WasmCompilationException] if compilation fails
  /// - [ArgumentError] if bytes are invalid
  ///
  /// ## Example
  ///
  /// ```dart
  /// final wasmBytes = await File('plugin.wasm').readAsBytes();
  /// final module = await runtime.loadModule(wasmBytes);
  /// ```
  Future<IWasmModule> loadModule(Uint8List wasmBytes);

  /// Load WASM module from file
  ///
  /// Convenience method to load module from a file path.
  ///
  /// ## Parameters
  ///
  /// - `path`: File path to WASM module
  ///
  /// ## Returns
  ///
  /// Loaded WASM module
  ///
  /// ## Example
  ///
  /// ```dart
  /// final module = await runtime.loadModuleFromFile('plugins/example.wasm');
  /// ```
  Future<IWasmModule> loadModuleFromFile(String path);

  /// Instantiate WASM module with imports
  ///
  /// Creates a WASM instance by linking the module with host imports.
  ///
  /// ## Parameters
  ///
  /// - `module`: WASM module to instantiate
  /// - `imports`: Host imports (functions, globals, memory, tables)
  ///
  /// ## Returns
  ///
  /// WASM instance ready for use
  ///
  /// ## Throws
  ///
  /// - [WasmInstantiationException] if instantiation fails
  /// - [ArgumentError] if required imports are missing
  ///
  /// ## Example
  ///
  /// ```dart
  /// final instance = await runtime.instantiate(module, {
  ///   'env': {
  ///     'log_info': WasmImport.function((args) {
  ///       print('[INFO] ${args[0]}');
  ///       return null;
  ///     }),
  ///     'memory': WasmImport.memory(sharedMemory),
  ///   },
  /// });
  /// ```
  Future<IWasmInstance> instantiate(
    IWasmModule module,
    Map<String, Map<String, WasmImport>> imports,
  );

  /// Validate WASM bytes without loading
  ///
  /// Quickly validates WASM bytecode without full compilation.
  ///
  /// ## Parameters
  ///
  /// - `wasmBytes`: WASM binary module
  ///
  /// ## Returns
  ///
  /// Validation result
  ///
  /// ## Example
  ///
  /// ```dart
  /// final validation = await runtime.validateBytes(wasmBytes);
  /// if (!validation.isValid) {
  ///   print('Invalid WASM: ${validation.errors}');
  /// }
  /// ```
  Future<WasmModuleValidation> validateBytes(Uint8List wasmBytes);

  /// Get runtime statistics
  ///
  /// Returns statistics about runtime performance and resource usage.
  ///
  /// ## Returns
  ///
  /// Map with statistics:
  /// - `modules_loaded`: Number of modules loaded
  /// - `instances_active`: Number of active instances
  /// - `total_memory_bytes`: Total memory allocated
  ///
  /// ## Example
  ///
  /// ```dart
  /// final stats = runtime.getStatistics();
  /// print('Active instances: ${stats['instances_active']}');
  /// ```
  Map<String, dynamic> getStatistics();

  /// Dispose runtime and free all resources
  ///
  /// Frees all resources associated with this runtime.
  /// All modules and instances created by this runtime must be disposed first.
  ///
  /// ## Example
  ///
  /// ```dart
  /// await runtime.dispose();
  /// ```
  Future<void> dispose();
}

/// WASM compilation exception
///
/// Thrown when WASM module compilation fails.
class WasmCompilationException implements Exception {
  final String message;
  final List<String>? errors;

  const WasmCompilationException(this.message, {this.errors});

  @override
  String toString() {
    if (errors != null && errors!.isNotEmpty) {
      return 'WasmCompilationException: $message\nErrors:\n${errors!.join('\n')}';
    }
    return 'WasmCompilationException: $message';
  }
}

/// WASM instantiation exception
///
/// Thrown when WASM module instantiation fails.
class WasmInstantiationException implements Exception {
  final String message;
  final List<String>? missingImports;

  const WasmInstantiationException(this.message, {this.missingImports});

  @override
  String toString() {
    if (missingImports != null && missingImports!.isNotEmpty) {
      return 'WasmInstantiationException: $message\nMissing imports:\n${missingImports!.join('\n')}';
    }
    return 'WasmInstantiationException: $message';
  }
}
