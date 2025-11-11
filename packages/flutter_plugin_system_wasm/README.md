

# flutter_plugin_system_wasm

> **WASM plugin adapter for Flutter - provides WASM runtime abstractions, memory management, serialization, and plugin adapters**

[![pub package](https://img.shields.io/pub/v/flutter_plugin_system_wasm.svg)](https://pub.dev/packages/flutter_plugin_system_wasm)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Complete WASM adapter layer for Flutter plugin system. Provides abstractions for WASM runtime, automatic memory management, efficient serialization, and seamless integration with the plugin system.

## ✨ Features

- 🔌 **WASM Abstractions** - Runtime-agnostic interfaces (IWasmRuntime, IWasmModule, IWasmInstance)
- 💾 **Memory Bridge** - Automatic memory management for Dart ↔ WASM communication
- 📦 **Dual Serialization** - JSON (debug) and MessagePack (production)
- 🔄 **Plugin Adapter** - Seamless WASM → IPlugin conversion
- ⚡ **Runtime Integration** - Works with any WASM runtime (wasmtime, wasmi, Extism)
- 🛡️ **Type Safe** - Strongly typed interfaces with comprehensive error handling

## 📦 Installation

```yaml
dependencies:
  flutter_plugin_system_wasm: ^0.1.0
  flutter_plugin_system_core: ^0.1.0
```

## 🚀 Quick Start

### 1. Create WASM Plugin Runtime

```dart
import 'package:flutter_plugin_system_wasm/flutter_plugin_system_wasm.dart';

// Create WASM runtime (implementation-specific)
final wasmRuntime = WasmRunRuntime(config: WasmRuntimeConfig(
  enableOptimization: true,
  maxMemoryPages: 1024, // 64MB max
));

// Create plugin runtime
final pluginRuntime = WasmPluginRuntime(
  wasmRuntime: wasmRuntime,
  serializer: HybridPluginSerializer(useMessagePack: !kDebugMode),
);
```

### 2. Load WASM Plugin

```dart
// Load plugin
final plugin = await pluginRuntime.loadPlugin(
  pluginId: 'plugin.file-icons',
  source: PluginSource.file(path: 'plugins/file_icons.wasm'),
);

// Initialize
await plugin.initialize(context);
```

### 3. Call Plugin Functions

```dart
// Handle events
final response = await plugin.handleEvent(
  PluginEvent.now(
    type: 'file.opened',
    targetPluginId: 'plugin.file-icons',
    data: {'filename': 'main.dart', 'extension': '.dart'},
  ),
);

if (response.isSuccess) {
  final icon = response.getData<String>('icon');
  print('Icon for main.dart: $icon');
}
```

## 📐 Architecture

### Component Hierarchy

```text
┌──────────────────────────────────────────┐
│      WasmPluginRuntime                   │
│    (IPluginRuntime Implementation)       │
│  - Load WASM modules                     │
│  - Create plugin instances               │
│  - Manage plugin lifecycle               │
└─────────────────┬────────────────────────┘
                  │
┌─────────────────▼────────────────────────┐
│      WasmPluginAdapter                   │
│       (IPlugin Implementation)           │
│  - Implements plugin interface           │
│  - Delegates to WASM instance            │
│  - Manages plugin lifecycle              │
└─────────────────┬────────────────────────┘
                  │
┌─────────────────▼────────────────────────┐
│        WasmMemoryBridge                  │
│  - Memory allocation/deallocation        │
│  - Data serialization/deserialization    │
│  - Function call marshalling             │
│  - Automatic cleanup                     │
└─────────────────┬────────────────────────┘
                  │
┌─────────────────▼────────────────────────┐
│          IWasmInstance                   │
│  - WASM linear memory                    │
│  - Exported functions                    │
│  - Global variables                      │
└──────────────────────────────────────────┘
```

### Memory Management Pattern

```text
Dart Memory                WASM Linear Memory
    │                           │
    │ 1. Serialize              │
    ├──────────────────────►    │
    │                           │
    │ 2. Allocate (alloc)       │
    ├──────────────────────►    │
    │                     [ptr] │
    │                           │
    │ 3. Write data             │
    ├──────────────────────►    │
    │                 [data at ptr]
    │                           │
    │ 4. Call function          │
    ├──────────────────────►    │
    │                  [processing]
    │                           │
    │ 5. Return result_ptr      │
    │◄──────────────────────┤
    │                           │
    │ 6. Read result            │
    │◄──────────────────────┤
    │                           │
    │ 7. Free memory (dealloc)  │
    ├──────────────────────►    │
```

## 🎯 Core Components

### WasmMemoryBridge

Automatic memory management for Dart ↔ WASM communication.

```dart
final bridge = WasmMemoryBridge(
  instance: wasmInstance,
  serializer: JsonPluginSerializer(),
);

// Call with automatic memory management
final result = await bridge.call('plugin_handle_event', {
  'type': 'file.opened',
  'filename': 'main.dart',
});

// Memory is automatically:
// 1. Allocated
// 2. Written
// 3. Read
// 4. Freed
```

### Serialization

Choose serializer based on environment:

```dart
// Development: JSON (easy debugging)
final devSerializer = JsonPluginSerializer();
final data = {'type': 'file.opened', 'filename': 'main.dart'};
final bytes = devSerializer.serialize(data);
// bytes = UTF-8 encoded JSON

// Production: MessagePack (30-50% smaller, faster)
final prodSerializer = MessagePackPluginSerializer();
final bytes = prodSerializer.serialize(data);
// bytes = binary MessagePack

// Hybrid: Automatic switching
final serializer = HybridPluginSerializer(
  useMessagePack: !kDebugMode,
);
```

### WASM Runtime Abstractions

Runtime-agnostic interfaces work with any WASM engine:

```dart
abstract class IWasmRuntime {
  String get name;
  String get version;
  WasmFeatures get supportedFeatures;

  Future<IWasmModule> loadModule(Uint8List wasmBytes);
  Future<IWasmInstance> instantiate(
    IWasmModule module,
    Map<String, Map<String, WasmImport>> imports,
  );
}

// Implementations:
// - WasmRunRuntime (wasmtime/wasmi)
// - ExtismRuntime (future)
// - WasmEdgeRuntime (future)
```

### Plugin Adapter

Adapts WASM instance to IPlugin interface:

```dart
final plugin = WasmPluginAdapter(
  manifest: manifest,
  instance: wasmInstance,
  serializer: JsonPluginSerializer(),
);

// Use as IPlugin
await plugin.initialize(context);
final response = await plugin.handleEvent(event);
await plugin.dispose();

// Access WASM directly
final stats = plugin.getStatistics();
print('Functions: ${stats['functions']}');
print('Memory: ${stats['memory']}');
```

## 🔧 Advanced Usage

### Custom WASM Functions

Call custom plugin functions beyond standard interface:

```dart
final adapter = plugin as WasmPluginAdapter;

// Call custom function
final result = await adapter.callCustomFunction(
  'get_icon_for_file',
  {'filename': 'main.dart', 'extension': '.dart'},
);

print('Icon: ${result['icon']}');
print('Color: ${result['color']}');
```

### Manual Memory Management

For advanced use cases, manage memory manually:

```dart
final bridge = WasmMemoryBridge(
  instance: wasmInstance,
  serializer: JsonPluginSerializer(),
);

// Allocate
final ptr = await bridge.allocate(1024);

try {
  // Write
  final data = Uint8List.fromList([1, 2, 3, 4]);
  await bridge.write(ptr, data);

  // Read
  final result = await bridge.read(ptr, 4);
} finally {
  // Free
  await bridge.deallocate(ptr, 1024);
}
```

### Runtime Configuration

Configure WASM runtime behavior:

```dart
final config = WasmRuntimeConfig(
  enableOptimization: true,        // JIT optimization
  maxMemoryPages: 1024,            // 64MB max memory
  maxStackDepth: 1000,             // Call stack limit
  fuelLimit: 1000000,              // Execution metering
  enableWasi: false,               // WASI support
);

final runtime = WasmRunRuntime(config: config);
```

## 📝 WASM Plugin Requirements

Your WASM plugin must export these functions:

### Required Exports

```rust
// Memory management (required)
#[no_mangle]
pub extern "C" fn alloc(size: usize) -> *mut u8 {
    let layout = Layout::array::<u8>(size).unwrap();
    unsafe { alloc(layout) }
}

#[no_mangle]
pub extern "C" fn dealloc(ptr: *mut u8, size: usize) {
    let layout = Layout::array::<u8>(size).unwrap();
    unsafe { dealloc(ptr, layout) }
}

// Event handler (required)
#[no_mangle]
pub extern "C" fn plugin_handle_event(ptr: *const u8, len: usize) -> u64 {
    // 1. Read event from memory
    let event_bytes = unsafe { std::slice::from_raw_parts(ptr, len) };
    let event: PluginEvent = deserialize(event_bytes);

    // 2. Process event
    let response = handle_event_internal(event);

    // 3. Allocate response memory
    let response_bytes = serialize(&response);
    let response_ptr = alloc(response_bytes.len());

    // 4. Copy response
    unsafe {
        std::ptr::copy_nonoverlapping(
            response_bytes.as_ptr(),
            response_ptr,
            response_bytes.len()
        );
    }

    // 5. Pack ptr + len into u64
    pack_ptr_len(response_ptr as usize, response_bytes.len())
}

fn pack_ptr_len(ptr: usize, len: usize) -> u64 {
    ((ptr as u64) << 32) | (len as u64)
}
```

### Optional Exports

```rust
// Initialization (optional)
#[no_mangle]
pub extern "C" fn plugin_initialize() -> i32 {
    // Initialize plugin
    0 // Return 0 on success
}

// Cleanup (optional)
#[no_mangle]
pub extern "C" fn plugin_dispose() -> i32 {
    // Cleanup resources
    0 // Return 0 on success
}

// Manifest retrieval (optional)
#[no_mangle]
pub extern "C" fn plugin_get_manifest() -> u64 {
    let manifest = get_manifest_json();
    let manifest_bytes = manifest.as_bytes();
    let ptr = alloc(manifest_bytes.len());

    unsafe {
        std::ptr::copy_nonoverlapping(
            manifest_bytes.as_ptr(),
            ptr,
            manifest_bytes.len()
        );
    }

    pack_ptr_len(ptr as usize, manifest_bytes.len())
}
```

## 📊 Performance

### Serialization Comparison

| Serializer | Payload Size | Ser Time | Deser Time | Use Case |
|-----------|-------------|----------|------------|----------|
| JSON | 100% (baseline) | ~1ms | ~1.2ms | Development, debugging |
| MessagePack | ~60% | ~0.6ms | ~0.8ms | Production, performance |

### Memory Efficiency

- **Zero-copy reads**: Direct memory access where possible
- **Explicit ownership**: Clear allocation/deallocation responsibility
- **No leaks**: Automatic cleanup in `finally` blocks
- **Minimal overhead**: Single allocation per call

## 🏗️ Architecture Principles

This package follows:

- **Clean Architecture** - Clear separation of concerns
- **Adapter Pattern** - WASM → IPlugin conversion
- **Bridge Pattern** - Memory management abstraction
- **Strategy Pattern** - Pluggable serialization
- **SOLID Principles** - Extensible, maintainable code
- **DRY** - Reusable components

## 🔗 Related Packages

- **flutter_plugin_system_core**: Pure abstractions and interfaces
- **flutter_plugin_system_host**: Plugin host runtime
- **flutter_plugin_system_wasm_run**: wasm_run implementation
- **flutter_plugin_system**: Convenience package (re-exports all)

## 📖 Documentation

- [Architecture Document](../../docs/PLUGIN_SYSTEM_ARCHITECTURE.md)
- [API Reference](https://pub.dev/documentation/flutter_plugin_system_wasm/latest/)

## 🤝 Contributing

Contributions welcome! Please read our contributing guidelines.

## 📄 License

MIT License - see [LICENSE](LICENSE) file

## 🙋 Support

- [GitHub Issues](https://github.com/777genius/multi_editor_flutter/issues)
- [Documentation](https://pub.dev/documentation/flutter_plugin_system_wasm/latest/)
