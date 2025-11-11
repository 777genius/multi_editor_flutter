import '../models/plugin_config.dart';
import '../models/plugin_manifest.dart';
import '../models/plugin_source.dart';
import '../types/plugin_types.dart';
import 'i_plugin.dart';

/// Plugin runtime interface
///
/// Abstraction for different plugin execution environments (WASM, Native, Script).
/// Each runtime is responsible for loading and instantiating plugins of its type.
///
/// ## Design Principles
///
/// - **Strategy Pattern**: Different runtimes implement same interface
/// - **Dependency Inversion**: Host depends on abstraction, not concrete runtime
/// - **Open/Closed**: Add new runtimes without modifying host
///
/// ## Implementations
///
/// - `WasmPluginRuntime`: Executes WASM modules (Rust, Go, C compiled to WASM)
/// - `NativePluginRuntime`: Executes pure Dart plugins
/// - `ScriptPluginRuntime`: Executes script languages (future)
///
/// ## Example Usage
///
/// ```dart
/// // Create runtime
/// final runtime = WasmPluginRuntime(wasmRuntime: myWasmRuntime);
///
/// // Load plugin
/// final plugin = await runtime.loadPlugin(
///   pluginId: 'plugin.file-icons',
///   source: PluginSource.file('plugins/file_icons.wasm'),
/// );
///
/// // Plugin is ready to use
/// final response = await plugin.handleEvent(event);
/// ```
abstract class IPluginRuntime {
  /// Runtime type
  ///
  /// Identifies which type of plugins this runtime executes.
  PluginRuntimeType get type;

  /// Load plugin
  ///
  /// Loads and prepares a plugin for initialization.
  /// Plugin is not yet initialized - that happens separately via `IPlugin.initialize()`.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Unique identifier for this plugin instance
  /// - `source`: Where to load plugin code from (file, URL, memory)
  /// - `config`: Optional runtime configuration
  ///
  /// ## Returns
  ///
  /// Loaded plugin instance (not yet initialized)
  ///
  /// ## Throws
  ///
  /// - `PluginLoadException`: If plugin cannot be loaded
  /// - `InvalidManifestException`: If manifest is invalid
  /// - `RuntimeNotAvailableException`: If runtime is not available
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Load from file
  /// final plugin = await runtime.loadPlugin(
  ///   pluginId: 'plugin.file-icons',
  ///   source: PluginSource.file('/path/to/plugin.wasm'),
  /// );
  ///
  /// // Load from URL
  /// final plugin = await runtime.loadPlugin(
  ///   pluginId: 'plugin.formatter',
  ///   source: PluginSource.url('https://example.com/plugin.wasm'),
  /// );
  ///
  /// // Load from memory
  /// final plugin = await runtime.loadPlugin(
  ///   pluginId: 'plugin.embedded',
  ///   source: PluginSource.memory(wasmBytes),
  /// );
  /// ```
  Future<IPlugin> loadPlugin({
    required String pluginId,
    required PluginSource source,
    PluginConfig? config,
  });

  /// Unload plugin
  ///
  /// Cleanup runtime-specific resources for this plugin.
  /// Plugin should be disposed before calling this.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: ID of plugin to unload
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Dispose plugin first
  /// await plugin.dispose();
  ///
  /// // Then unload from runtime
  /// await runtime.unloadPlugin('plugin.file-icons');
  /// ```
  Future<void> unloadPlugin(String pluginId);

  /// Check if runtime can execute this plugin
  ///
  /// Validates that plugin's manifest is compatible with this runtime.
  ///
  /// ## Parameters
  ///
  /// - `manifest`: Plugin manifest to check
  ///
  /// ## Returns
  ///
  /// `true` if plugin is compatible, `false` otherwise
  ///
  /// ## Example
  ///
  /// ```dart
  /// final manifest = PluginManifest(
  ///   id: 'plugin.example',
  ///   runtime: PluginRuntimeType.wasm,
  ///   // ...
  /// );
  ///
  /// if (runtime.isCompatible(manifest)) {
  ///   await runtime.loadPlugin(...);
  /// }
  /// ```
  bool isCompatible(PluginManifest manifest);

  // Optional capabilities

  /// Check if runtime supports hot reload
  bool get supportsHotReload => false;

  /// Hot reload plugin
  ///
  /// Reloads plugin code without reinitializing state.
  /// Only supported if `supportsHotReload` is true.
  Future<void> hotReload(String pluginId) async {
    throw UnsupportedError('Hot reload not supported by this runtime');
  }

  /// Get runtime-specific information
  Map<String, dynamic> getRuntimeInfo() => {
        'type': type.toString(),
        'supportsHotReload': supportsHotReload,
      };
}
