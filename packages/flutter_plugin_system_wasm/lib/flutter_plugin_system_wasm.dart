/// Flutter Plugin System WASM
///
/// WASM plugin adapter for Flutter - provides WASM runtime abstractions,
/// memory management, serialization, and plugin adapters.
///
/// ## Features
///
/// - 🔌 **WASM Abstractions** - IWasmRuntime, IWasmModule, IWasmInstance, IWasmMemory
/// - 💾 **Memory Management** - WasmMemoryBridge for Dart ↔ WASM data exchange
/// - 📦 **Serialization** - JSON and MessagePack serializers
/// - 🔄 **Plugin Adapter** - WasmPluginAdapter converts WASM to IPlugin
/// - ⚡ **Runtime Integration** - WasmPluginRuntime implements IPluginRuntime
///
/// ## Architecture
///
/// ```
/// ┌─────────────────────────────────────────┐
/// │     WasmPluginRuntime (IPluginRuntime)  │
/// │  - Load WASM modules                    │
/// │  - Create plugin instances              │
/// └───────────────┬─────────────────────────┘
///                 │
/// ┌───────────────▼─────────────────────────┐
/// │      WasmPluginAdapter (IPlugin)        │
/// │  - Implements plugin interface          │
/// │  - Manages lifecycle                    │
/// └───────────────┬─────────────────────────┘
///                 │
/// ┌───────────────▼─────────────────────────┐
/// │        WasmMemoryBridge                 │
/// │  - Memory allocation/deallocation       │
/// │  - Data serialization/deserialization   │
/// │  - Function call marshalling            │
/// └───────────────┬─────────────────────────┘
///                 │
/// ┌───────────────▼─────────────────────────┐
/// │          IWasmInstance                  │
/// │  - WASM linear memory                   │
/// │  - Exported functions                   │
/// │  - Globals                              │
/// └─────────────────────────────────────────┘
/// ```
///
/// ## Example
///
/// ```dart
/// import 'package:flutter_plugin_system_core/flutter_plugin_system_core.dart';
/// import 'package:flutter_plugin_system_wasm/flutter_plugin_system_wasm.dart';
///
/// // Create WASM runtime (implementation-specific)
/// final wasmRuntime = WasmRunRuntime(config: WasmRuntimeConfig(
///   enableOptimization: true,
///   maxMemoryPages: 1024, // 64MB
/// ));
///
/// // Create plugin runtime
/// final pluginRuntime = WasmPluginRuntime(
///   wasmRuntime: wasmRuntime,
///   serializer: HybridPluginSerializer(useMessagePack: !kDebugMode),
/// );
///
/// // Load plugin
/// final plugin = await pluginRuntime.loadPlugin(
///   pluginId: 'plugin.file-icons',
///   source: PluginSource.file(path: 'plugins/file_icons.wasm'),
/// );
///
/// // Initialize plugin
/// await plugin.initialize(context);
///
/// // Handle events
/// final response = await plugin.handleEvent(
///   PluginEvent.now(
///     type: 'file.opened',
///     targetPluginId: 'plugin.file-icons',
///     data: {'filename': 'main.dart'},
///   ),
/// );
///
/// print('Icon: ${response.getData<String>('icon')}');
/// ```
///
/// ## Memory Management
///
/// The memory bridge handles all aspects of data transfer:
///
/// ```dart
/// // Create memory bridge
/// final bridge = WasmMemoryBridge(
///   instance: wasmInstance,
///   serializer: JsonPluginSerializer(),
/// );
///
/// // Call WASM function with automatic memory management
/// final result = await bridge.call('plugin_handle_event', {
///   'type': 'file.opened',
///   'filename': 'main.dart',
/// });
///
/// // Memory is automatically allocated, used, and freed
/// ```
///
/// ## Serialization
///
/// Choose serializer based on environment:
///
/// ```dart
/// // Development: JSON (easy debugging)
/// final devSerializer = JsonPluginSerializer();
///
/// // Production: MessagePack (performance)
/// final prodSerializer = MessagePackPluginSerializer();
///
/// // Hybrid: Switch based on config
/// final serializer = HybridPluginSerializer(
///   useMessagePack: !kDebugMode,
/// );
/// ```
///
/// ## WASM Plugin Requirements
///
/// WASM plugins must export the following functions:
///
/// ```rust
/// // Memory management
/// #[no_mangle]
/// pub extern "C" fn alloc(size: usize) -> *mut u8;
///
/// #[no_mangle]
/// pub extern "C" fn dealloc(ptr: *mut u8, size: usize);
///
/// // Plugin interface
/// #[no_mangle]
/// pub extern "C" fn plugin_handle_event(ptr: *const u8, len: usize) -> u64;
///
/// // Optional
/// #[no_mangle]
/// pub extern "C" fn plugin_initialize() -> i32;
///
/// #[no_mangle]
/// pub extern "C" fn plugin_dispose() -> i32;
///
/// #[no_mangle]
/// pub extern "C" fn plugin_get_manifest() -> u64;
/// ```
///
/// ## Related Packages
///
/// - **flutter_plugin_system_core**: Pure abstractions and interfaces
/// - **flutter_plugin_system_host**: Plugin host runtime
/// - **flutter_plugin_system_wasm_run**: wasm_run implementation
/// - **flutter_plugin_system**: Convenience package (re-exports all)
///
/// For more information, see the [architecture documentation](../../docs/PLUGIN_SYSTEM_ARCHITECTURE.md).
library flutter_plugin_system_wasm;

// Re-export core package for convenience
export 'package:flutter_plugin_system_core/flutter_plugin_system_core.dart';

// Export WASM components
export 'src/adapters.dart';
export 'src/contracts.dart';
export 'src/memory.dart';
export 'src/serialization.dart';
