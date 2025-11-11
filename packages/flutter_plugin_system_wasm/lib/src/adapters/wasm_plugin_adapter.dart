import 'package:flutter_plugin_system_core/flutter_plugin_system_core.dart';
import '../contracts/i_wasm_instance.dart';
import '../memory/wasm_memory_bridge.dart';
import '../serialization/plugin_serializer.dart';

/// WASM plugin adapter
///
/// Adapts a WASM instance to the IPlugin interface.
/// Implements the Adapter pattern from architecture document.
///
/// ## Purpose
///
/// Bridges the gap between WASM runtime and plugin system:
/// - WASM instance → IPlugin interface
/// - Manages memory and serialization
/// - Handles plugin lifecycle
///
/// ## Example
///
/// ```dart
/// // Load WASM module
/// final module = await wasmRuntime.loadModule(wasmBytes);
/// final instance = await wasmRuntime.instantiate(module, imports);
///
/// // Create adapter
/// final plugin = WasmPluginAdapter(
///   manifest: manifest,
///   instance: instance,
///   serializer: JsonPluginSerializer(),
/// );
///
/// // Use as IPlugin
/// await plugin.initialize(context);
/// final response = await plugin.handleEvent(event);
/// ```
class WasmPluginAdapter implements IPlugin {
  final PluginManifest _manifest;
  final IWasmInstance _instance;
  final WasmMemoryBridge _memoryBridge;

  /// Get WASM instance
  IWasmInstance get instance => _instance;

  /// Get memory bridge
  WasmMemoryBridge get memoryBridge => _memoryBridge;

  /// Create WASM plugin adapter
  ///
  /// ## Parameters
  ///
  /// - `manifest`: Plugin manifest
  /// - `instance`: WASM instance
  /// - `serializer`: Serializer for data conversion
  ///
  /// ## Throws
  ///
  /// - [WasmPluginException] if instance is missing required exports
  WasmPluginAdapter({
    required PluginManifest manifest,
    required IWasmInstance instance,
    required PluginSerializer serializer,
  })  : _manifest = manifest,
        _instance = instance,
        _memoryBridge = WasmMemoryBridge(
          instance: instance,
          serializer: serializer,
        ) {
    _validateInstance();
  }

  @override
  PluginManifest get manifest => _manifest;

  @override
  Future<void> initialize(PluginContext context) async {
    final initFn = _instance.getFunction('plugin_initialize');
    if (initFn == null) {
      // Initialize function is optional
      return;
    }

    try {
      final result = await initFn([]) as int;
      if (result != 0) {
        throw PluginInitializationException(
          'Plugin initialization returned error code: $result',
          pluginId: manifest.id,
        );
      }
    } catch (e) {
      if (e is PluginInitializationException) rethrow;
      throw PluginInitializationException(
        'Failed to initialize plugin: $e',
        pluginId: manifest.id,
        originalError: e,
      );
    }
  }

  @override
  Future<PluginResponse> handleEvent(PluginEvent event) async {
    final handleEventFn = _instance.getFunction('plugin_handle_event');
    if (handleEventFn == null) {
      return PluginResponse.error(
        message: 'Plugin does not export plugin_handle_event function',
      );
    }

    try {
      // Convert event to map
      final eventData = event.toJson();

      // Call WASM function with memory bridge
      final resultData = await _memoryBridge.call(
        'plugin_handle_event',
        eventData,
      );

      // Parse response
      return PluginResponse.fromJson(resultData);
    } catch (e) {
      return PluginResponse.error(
        message: 'Event handling failed: $e',
      );
    }
  }

  @override
  Future<void> dispose() async {
    final disposeFn = _instance.getFunction('plugin_dispose');
    if (disposeFn != null) {
      try {
        await disposeFn([]);
      } catch (e) {
        // Log error but don't throw during disposal
        // ignore: avoid_print
        print('Warning: Plugin dispose failed: $e');
      }
    }

    // Dispose WASM instance
    await _instance.dispose();
  }

  /// Validate WASM instance has required exports
  ///
  /// Checks that the instance exports required functions and memory.
  ///
  /// ## Throws
  ///
  /// - [WasmPluginException] if validation fails
  void _validateInstance() {
    // Check memory export
    if (_instance.memory == null) {
      throw WasmPluginException(
        'WASM instance must export memory',
        pluginId: manifest.id,
      );
    }

    // Check required functions
    final requiredFunctions = ['alloc', 'dealloc', 'plugin_handle_event'];
    final missingFunctions = <String>[];

    for (final functionName in requiredFunctions) {
      if (_instance.getFunction(functionName) == null) {
        missingFunctions.add(functionName);
      }
    }

    if (missingFunctions.isNotEmpty) {
      throw WasmPluginException(
        'WASM instance missing required functions: ${missingFunctions.join(', ')}',
        pluginId: manifest.id,
      );
    }
  }

  /// Get manifest from WASM module
  ///
  /// Calls the plugin_get_manifest function to retrieve manifest from WASM.
  /// This is an alternative to providing manifest externally.
  ///
  /// ## Returns
  ///
  /// Plugin manifest from WASM
  ///
  /// ## Throws
  ///
  /// - [WasmPluginException] if manifest retrieval fails
  ///
  /// ## Example
  ///
  /// ```dart
  /// final manifest = await adapter.getManifestFromWasm();
  /// print('Plugin: ${manifest.name} v${manifest.version}');
  /// ```
  Future<PluginManifest> getManifestFromWasm() async {
    final getManifestFn = _instance.getFunction('plugin_get_manifest');
    if (getManifestFn == null) {
      throw WasmPluginException(
        'WASM instance does not export plugin_get_manifest',
        pluginId: manifest.id,
      );
    }

    try {
      final packed = await getManifestFn([]) as int;
      final ptr = (packed >> 32) & 0xFFFFFFFF;
      final len = packed & 0xFFFFFFFF;

      // Validate packed result
      // Check for null pointer (0,0) or invalid sentinel values
      if (packed == 0 || packed == 0xFFFFFFFFFFFFFFFF) {
        throw WasmPluginException(
          'Invalid manifest pointer: packed=$packed (likely indicates plugin error)',
          pluginId: manifest.id,
        );
      }

      // Sanity check: manifest should be reasonable size (max 1MB)
      if (len > 1024 * 1024) {
        throw WasmPluginException(
          'Manifest too large: $len bytes (max 1MB)',
          pluginId: manifest.id,
        );
      }

      final manifestBytes = await _memoryBridge.read(ptr, len);
      final manifestData = _memoryBridge.serializer.deserialize(manifestBytes);

      // Free memory
      await _memoryBridge.deallocate(ptr, len);

      return PluginManifest.fromJson(manifestData);
    } catch (e) {
      throw WasmPluginException(
        'Failed to get manifest from WASM: $e',
        pluginId: manifest.id,
        originalError: e,
      );
    }
  }

  /// Call custom WASM function
  ///
  /// Allows calling custom plugin functions beyond the standard interface.
  ///
  /// ## Parameters
  ///
  /// - `functionName`: WASM function name
  /// - `data`: Input data
  ///
  /// ## Returns
  ///
  /// Result data
  ///
  /// ## Example
  ///
  /// ```dart
  /// final result = await adapter.callCustomFunction(
  ///   'get_icon_for_file',
  ///   {'filename': 'main.dart'},
  /// );
  /// print('Icon: ${result['icon']}');
  /// ```
  Future<Map<String, dynamic>> callCustomFunction(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    return await _memoryBridge.call(functionName, data);
  }

  /// Get plugin statistics
  ///
  /// Returns statistics about the plugin instance.
  ///
  /// ## Returns
  ///
  /// Map with statistics:
  /// - `manifest`: Plugin manifest data
  /// - `memory`: Memory statistics
  /// - `functions`: List of exported functions
  ///
  /// ## Example
  ///
  /// ```dart
  /// final stats = adapter.getStatistics();
  /// print('Functions: ${stats['functions']}');
  /// print('Memory: ${stats['memory']}');
  /// ```
  Map<String, dynamic> getStatistics() {
    return {
      'manifest': {
        'id': manifest.id,
        'name': manifest.name,
        'version': manifest.version,
        'runtime': manifest.runtime.name,
      },
      'memory': _memoryBridge.getMemoryStats(),
      'functions': _instance.listFunctions(),
      'globals': _instance.listGlobals(),
    };
  }
}

/// WASM plugin exception
///
/// Thrown when WASM plugin operations fail.
class WasmPluginException extends PluginException {
  const WasmPluginException(
    super.message, {
    super.pluginId,
    super.originalError,
    super.stackTrace,
  });
}
