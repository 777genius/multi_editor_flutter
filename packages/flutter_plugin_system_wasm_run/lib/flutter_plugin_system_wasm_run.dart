/// Flutter Plugin System WasmRun
///
/// wasm_run implementation of WASM runtime for Flutter plugin system.
/// Provides concrete WASM runtime using wasmtime (JIT) for desktop and
/// wasmi (interpreter) for mobile platforms.
///
/// ## Features
///
/// - 🚀 **WasmRunRuntime** - IWasmRuntime implementation using wasm_run
/// - 📦 **WasmRunModule** - IWasmModule implementation
/// - ⚡ **WasmRunInstance** - IWasmInstance implementation
/// - 💾 **WasmRunMemory** - IWasmMemory implementation
/// - 🏗️ **Platform Optimized** - wasmtime (JIT) for desktop, wasmi for mobile
/// - 🌐 **WASI Support** - Full WASI snapshot preview 1
///
/// ## Architecture
///
/// ```
/// ┌──────────────────────────────────────┐
/// │       WasmRunRuntime                 │
/// │    (IWasmRuntime Implementation)     │
/// │  - Load/compile modules              │
/// │  - Instantiate with imports          │
/// │  - Validate bytecode                 │
/// └───────────────┬──────────────────────┘
///                 │
/// ┌───────────────▼──────────────────────┐
/// │       WasmRunModule                  │
/// │    (IWasmModule Implementation)      │
/// │  - Import/export inspection          │
/// │  - Validation                        │
/// │  - Custom sections                   │
/// └───────────────┬──────────────────────┘
///                 │
/// ┌───────────────▼──────────────────────┐
/// │      WasmRunInstance                 │
/// │   (IWasmInstance Implementation)     │
/// │  - Function calls                    │
/// │  - Memory access                     │
/// │  - Globals                           │
/// └───────────────┬──────────────────────┘
///                 │
/// ┌───────────────▼──────────────────────┐
/// │       WasmRunMemory                  │
/// │    (IWasmMemory Implementation)      │
/// │  - Read/write bytes                  │
/// │  - Memory growth                     │
/// │  - Typed access (int32, float64, etc)│
/// └──────────────────────────────────────┘
/// ```
///
/// ## Example
///
/// ```dart
/// import 'package:flutter_plugin_system_wasm/flutter_plugin_system_wasm.dart';
/// import 'package:flutter_plugin_system_wasm_run/flutter_plugin_system_wasm_run.dart';
///
/// // Create wasm_run runtime
/// final wasmRuntime = WasmRunRuntime(
///   config: WasmRuntimeConfig(
///     enableOptimization: true,
///     maxMemoryPages: 1024, // 64MB max
///     maxStackDepth: 1000,
///   ),
/// );
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
/// // Use plugin
/// await plugin.initialize(context);
/// final response = await plugin.handleEvent(event);
/// ```
///
/// ## Platform Support
///
/// ### Desktop (Linux, macOS, Windows)
/// - Uses **wasmtime** with JIT compilation
/// - Optimized performance with AOT compilation
/// - Full WASI support
///
/// ### Mobile (iOS, Android)
/// - Uses **wasmi** interpreter
/// - Lower memory footprint
/// - Sandboxed execution
///
/// ### Web
/// - Uses browser's native WebAssembly
/// - No external dependencies
///
/// ## Runtime Configuration
///
/// ```dart
/// final config = WasmRuntimeConfig(
///   enableOptimization: true,        // Enable JIT (desktop only)
///   maxMemoryPages: 1024,            // 64MB max memory
///   maxStackDepth: 1000,             // Call stack limit
///   fuelLimit: 1000000,              // Execution metering
///   enableWasi: false,               // WASI support
/// );
///
/// final runtime = WasmRunRuntime(config: config);
/// ```
///
/// ## Features
///
/// ### Supported WASM Features
///
/// - ✅ **WASI** - WebAssembly System Interface
/// - ✅ **Multi-Value** - Multiple return values
/// - ✅ **Bulk Memory** - Efficient memory operations
/// - ✅ **Reference Types** - anyref and funcref
/// - ✅ **SIMD** - Vector instructions (desktop)
/// - ❌ **Threads** - Not yet supported
/// - ❌ **Tail Calls** - Not yet supported
/// - ❌ **Exceptions** - Not yet supported
///
/// ## Performance
///
/// ### Module Loading
///
/// ```dart
/// // Load and compile module
/// final module = await runtime.loadModule(wasmBytes);
/// // ~10-50ms depending on module size
///
/// // Instantiate module
/// final instance = await runtime.instantiate(module, imports);
/// // ~5-20ms
///
/// // Call function
/// final result = await instance.call('add', [2, 3]);
/// // ~0.1-1ms
/// ```
///
/// ### Memory Operations
///
/// ```dart
/// final memory = instance.memory!;
///
/// // Write (sync)
/// memory.writeSync(ptr, data); // ~0.01ms per KB
///
/// // Read (sync)
/// final result = memory.readSync(ptr, length); // ~0.01ms per KB
///
/// // Typed access
/// memory.writeInt32(ptr, 42); // ~0.001ms
/// final value = memory.readInt32(ptr); // ~0.001ms
/// ```
///
/// ## Advanced Usage
///
/// ### Pre-compilation (Desktop Only)
///
/// ```dart
/// // Compile module to native code
/// final compiled = await runtime.compile(module);
/// await File('plugin.compiled').writeAsBytes(compiled);
///
/// // Load pre-compiled module (faster)
/// final compiledBytes = await File('plugin.compiled').readAsBytes();
/// final module = await runtime.loadCompiled(compiledBytes);
/// ```
///
/// ### Fuel Metering
///
/// ```dart
/// // Set execution limit
/// await runtime.setFuel(instance, 1000000);
///
/// // Execute (will throw if fuel exhausted)
/// try {
///   await instance.call('expensive_function', []);
/// } catch (e) {
///   print('Function exceeded fuel limit');
/// }
///
/// // Check remaining fuel
/// final remaining = await runtime.getFuel(instance);
/// print('Fuel remaining: $remaining');
/// ```
///
/// ## Related Packages
///
/// - **flutter_plugin_system_core**: Pure abstractions and interfaces
/// - **flutter_plugin_system_wasm**: WASM abstractions and adapters
/// - **flutter_plugin_system_host**: Plugin host runtime
/// - **flutter_plugin_system**: Convenience package (re-exports all)
///
/// For more information, see the [architecture documentation](../../docs/PLUGIN_SYSTEM_ARCHITECTURE.md).
library flutter_plugin_system_wasm_run;

// Re-export core and wasm packages for convenience
export 'package:flutter_plugin_system_core/flutter_plugin_system_core.dart';
export 'package:flutter_plugin_system_wasm/flutter_plugin_system_wasm.dart';

// Export wasm_run components
export 'src/runtime.dart';
