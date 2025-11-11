import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_plugin_system_core/flutter_plugin_system_core.dart';
import '../contracts/i_wasm_runtime.dart';
import '../serialization/plugin_serializer.dart';
import 'wasm_plugin_adapter.dart';

/// WASM plugin runtime
///
/// Implementation of IPluginRuntime for WASM plugins.
/// Integrates WASM runtime with plugin system.
///
/// ## Example
///
/// ```dart
/// final wasmRuntime = WasmRunRuntime(); // Actual WASM runtime implementation
/// final pluginRuntime = WasmPluginRuntime(
///   wasmRuntime: wasmRuntime,
///   serializer: JsonPluginSerializer(),
/// );
///
/// // Use with PluginManager
/// await pluginManager.loadPlugin(
///   manifest: manifest,
///   source: PluginSource.file(path: 'plugin.wasm'),
///   runtime: pluginRuntime,
/// );
/// ```
class WasmPluginRuntime implements IPluginRuntime {
  final IWasmRuntime _wasmRuntime;
  final PluginSerializer _serializer;

  /// Get WASM runtime
  IWasmRuntime get wasmRuntime => _wasmRuntime;

  /// Get serializer
  PluginSerializer get serializer => _serializer;

  /// Create WASM plugin runtime
  ///
  /// ## Parameters
  ///
  /// - `wasmRuntime`: Underlying WASM runtime implementation
  /// - `serializer`: Serializer for data conversion
  WasmPluginRuntime({
    required IWasmRuntime wasmRuntime,
    required PluginSerializer serializer,
  })  : _wasmRuntime = wasmRuntime,
        _serializer = serializer;

  @override
  PluginRuntimeType get type => PluginRuntimeType.wasm;

  @override
  Future<IPlugin> loadPlugin({
    required String pluginId,
    required PluginSource source,
    PluginConfig? config,
  }) async {
    try {
      // 1. Load WASM bytes from source
      final wasmBytes = await _loadWasmBytes(source);

      // 2. Load WASM module
      final module = await _wasmRuntime.loadModule(wasmBytes);

      // 3. Prepare imports (host functions)
      final imports = _prepareImports(pluginId, config);

      // 4. Instantiate WASM module
      final instance = await _wasmRuntime.instantiate(module, imports);

      // 5. Create manifest (either from config or from WASM)
      final manifest = await _createManifest(pluginId, instance, config);

      // 6. Create plugin adapter
      return WasmPluginAdapter(
        manifest: manifest,
        instance: instance,
        serializer: _serializer,
      );
    } catch (e) {
      throw PluginLoadException(
        'Failed to load WASM plugin: $e',
        pluginId: pluginId,
        originalError: e,
      );
    }
  }

  @override
  Future<void> unloadPlugin(String pluginId) async {
    // Plugin disposal is handled by WasmPluginAdapter.dispose()
    // Nothing to do here
  }

  @override
  bool isCompatible(PluginManifest manifest) {
    return manifest.runtime == PluginRuntimeType.wasm;
  }

  /// Load WASM bytes from source
  Future<Uint8List> _loadWasmBytes(PluginSource source) async {
    switch (source.type) {
      case PluginSourceType.file:
        final file = File(source.path!);
        if (!await file.exists()) {
          throw PluginLoadException(
            'WASM file not found: ${source.path}',
          );
        }
        return await file.readAsBytes();

      case PluginSourceType.url:
        // TODO: Implement HTTP fetch
        throw UnimplementedError('URL source not yet implemented');

      case PluginSourceType.memory:
        if (source.bytes == null) {
          throw PluginLoadException('Memory source has no bytes');
        }
        return source.bytes!;

      case PluginSourceType.package:
        // TODO: Implement package loading
        throw UnimplementedError('Package source not yet implemented');
    }
  }

  /// Prepare WASM imports
  ///
  /// Creates the import map for WASM instantiation.
  /// Currently returns empty map - host functions should be added here.
  Map<String, Map<String, WasmImport>> _prepareImports(
    String pluginId,
    PluginConfig? config,
  ) {
    // TODO: Add host function imports
    // For now, return empty imports
    // In production, this would include:
    // - Host function imports (log_info, get_current_file, etc.)
    // - Shared memory (if applicable)
    return {};
  }

  /// Create plugin manifest
  ///
  /// Either uses manifest from config or retrieves it from WASM.
  Future<PluginManifest> _createManifest(
    String pluginId,
    dynamic instance,
    PluginConfig? config,
  ) async {
    // If manifest is in config metadata, use it
    final manifestData = config?.metadata?['manifest'] as Map<String, dynamic>?;
    if (manifestData != null) {
      return PluginManifest.fromJson(manifestData);
    }

    // Otherwise, try to get it from WASM
    // For now, create a minimal manifest
    // In production, this would call plugin_get_manifest
    return PluginManifest(
      id: pluginId,
      name: pluginId,
      version: '0.0.0',
      description: 'WASM plugin',
      runtime: PluginRuntimeType.wasm,
    );
  }

  /// Get runtime statistics
  ///
  /// Returns statistics about the WASM runtime.
  Map<String, dynamic> getStatistics() {
    return {
      'type': type.name,
      'wasm_runtime': _wasmRuntime.name,
      'wasm_runtime_version': _wasmRuntime.version,
      'serializer': _serializer.name,
      'features': {
        'wasi': _wasmRuntime.supportedFeatures.supportsWasi,
        'multi_value': _wasmRuntime.supportedFeatures.supportsMultiValue,
        'bulk_memory': _wasmRuntime.supportedFeatures.supportsBulkMemory,
        'simd': _wasmRuntime.supportedFeatures.supportsSimd,
      },
      ..._wasmRuntime.getStatistics(),
    };
  }

  /// Dispose runtime
  ///
  /// Frees all resources associated with the runtime.
  Future<void> dispose() async {
    await _wasmRuntime.dispose();
  }
}
