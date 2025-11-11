import 'dart:typed_data';

/// WASM import
///
/// Represents a host function or value imported by a WASM module.
///
/// ## Types
///
/// - **Function**: Host function callable from WASM
/// - **Global**: Host global variable
/// - **Memory**: Shared linear memory
/// - **Table**: Function table
///
/// ## Example
///
/// ```dart
/// final imports = {
///   'env': {
///     'log_info': WasmImport.function(logInfoFunction),
///     'memory': WasmImport.memory(memory),
///   },
/// };
/// ```
class WasmImport {
  final WasmImportType type;
  final Object value;

  const WasmImport._(this.type, this.value);

  /// Create function import
  factory WasmImport.function(Function function) {
    return WasmImport._(WasmImportType.function, function);
  }

  /// Create global import
  factory WasmImport.global(Object value) {
    return WasmImport._(WasmImportType.global, value);
  }

  /// Create memory import
  factory WasmImport.memory(Object memory) {
    return WasmImport._(WasmImportType.memory, memory);
  }

  /// Create table import
  factory WasmImport.table(Object table) {
    return WasmImport._(WasmImportType.table, table);
  }
}

/// WASM import type
enum WasmImportType {
  function,
  global,
  memory,
  table,
}

/// WASM module interface
///
/// Represents a loaded WASM module ready to be instantiated.
///
/// ## Lifecycle
///
/// 1. Load WASM bytes → IWasmModule (compilation)
/// 2. Instantiate with imports → IWasmInstance (linking)
/// 3. Use instance → execute functions
/// 4. Dispose module → free resources
///
/// ## Example
///
/// ```dart
/// // Load module
/// final module = await runtime.loadModule(wasmBytes);
///
/// // Get module info
/// print('Imports: ${module.listImports()}');
/// print('Exports: ${module.listExports()}');
///
/// // Validate
/// final validation = module.validate();
/// if (validation.isValid) {
///   print('Module is valid');
/// }
/// ```
abstract class IWasmModule {
  /// Get module size in bytes
  ///
  /// Returns the size of the compiled WASM module.
  int get size;

  /// List all imports required by module
  ///
  /// Returns a list of all imports (functions, globals, memory, tables)
  /// that the module requires from the host.
  ///
  /// ## Returns
  ///
  /// Map of module name → import name → import type
  ///
  /// ## Example
  ///
  /// ```dart
  /// final imports = module.listImports();
  /// // {'env': {'log_info': 'function', 'memory': 'memory'}}
  /// ```
  Map<String, Map<String, String>> listImports();

  /// List all exports provided by module
  ///
  /// Returns a list of all exports (functions, globals, memory, tables)
  /// that the module provides.
  ///
  /// ## Returns
  ///
  /// Map of export name → export type
  ///
  /// ## Example
  ///
  /// ```dart
  /// final exports = module.listExports();
  /// // {'plugin_initialize': 'function', 'alloc': 'function', 'memory': 'memory'}
  /// ```
  Map<String, String> listExports();

  /// Validate module
  ///
  /// Validates the WASM module structure and correctness.
  ///
  /// ## Returns
  ///
  /// Validation result with error details if invalid
  ///
  /// ## Example
  ///
  /// ```dart
  /// final validation = module.validate();
  /// if (!validation.isValid) {
  ///   print('Validation errors: ${validation.errors}');
  /// }
  /// ```
  WasmModuleValidation validate();

  /// Get custom section by name
  ///
  /// Retrieves a custom section from the WASM module.
  /// Custom sections can store metadata like plugin manifest.
  ///
  /// ## Parameters
  ///
  /// - `name`: Custom section name
  ///
  /// ## Returns
  ///
  /// Custom section bytes, or null if not found
  ///
  /// ## Example
  ///
  /// ```dart
  /// final manifest = module.getCustomSection('plugin_manifest');
  /// if (manifest != null) {
  ///   final manifestJson = utf8.decode(manifest);
  /// }
  /// ```
  Uint8List? getCustomSection(String name);

  /// Dispose module and free resources
  ///
  /// Frees all resources associated with this module.
  /// After disposal, the module cannot be used.
  Future<void> dispose();
}

/// WASM module validation result
///
/// Contains validation status and error details.
class WasmModuleValidation {
  /// Whether module is valid
  final bool isValid;

  /// Validation errors (if any)
  final List<String> errors;

  /// Validation warnings (if any)
  final List<String> warnings;

  const WasmModuleValidation({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  /// Create valid result
  factory WasmModuleValidation.valid({List<String> warnings = const []}) {
    return WasmModuleValidation(
      isValid: true,
      warnings: warnings,
    );
  }

  /// Create invalid result
  factory WasmModuleValidation.invalid(List<String> errors) {
    return WasmModuleValidation(
      isValid: false,
      errors: errors,
    );
  }
}
