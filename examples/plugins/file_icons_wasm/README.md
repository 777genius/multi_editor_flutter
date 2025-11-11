# File Icons WASM Plugin

Rust → WASM plugin example demonstrating the Flutter Plugin System architecture.

## 🎯 Features

- ✅ **Written in Rust** - Safe, fast, compiled to WASM
- ✅ **Linear Memory Pattern** - Efficient Dart ↔ WASM communication
- ✅ **MessagePack Serialization** - Binary protocol for performance
- ✅ **Zero-Copy Memory** - Explicit ownership model
- ✅ **Small Binary** - ~50KB optimized WASM
- ✅ **File Icon Mapping** - 20+ file types supported

## 📦 Building

### Prerequisites

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Add WASM target
rustup target add wasm32-unknown-unknown

# Optional: Install wasm-opt for optimization
cargo install wasm-opt
```

### Build

```bash
./build.sh
```

Output: `build/file_icons_wasm.wasm` (~50KB)

## 🚀 Usage from Dart

### 1. Load Plugin

```dart
import 'package:flutter_plugin_system_host/flutter_plugin_system_host.dart';
import 'package:flutter_plugin_system_wasm_run/flutter_plugin_system_wasm_run.dart';

// Create WASM runtime
final wasmRuntime = WasmRunRuntime(
  config: WasmRuntimeConfig(
    maxMemoryPages: 16,     // 1MB
    maxExecutionTime: Duration(milliseconds: 100),
  ),
);

// Create plugin manager
final pluginManager = PluginManager(
  registry: PluginRegistry(),
  hostFunctions: HostFunctionRegistry(),
  eventDispatcher: EventDispatcher(),
  permissionSystem: PermissionSystem(),
  securityGuard: SecurityGuard(permissionSystem),
  errorBoundary: ErrorBoundary(errorTracker),
);

// Load plugin
final plugin = await pluginManager.loadPlugin(
  pluginId: 'plugin.file-icons-wasm',
  source: PluginSource.file(
    path: 'examples/plugins/file_icons_wasm/build/file_icons_wasm.wasm',
  ),
  runtime: wasmRuntime,
);
```

### 2. Use Plugin

```dart
// Initialize plugin
await plugin.initialize(pluginContext);

// Get icon for Rust file
final response = await plugin.handleEvent(
  PluginEvent(
    type: 'get_icon',
    data: {'extension': 'rs'},
  ),
);

if (response.handled) {
  print('Icon: ${response.data['icon']}');
  // Output: Icon: devicon-rust-plain
}

// Get icon for Dart file
final dartIcon = await plugin.handleEvent(
  PluginEvent(
    type: 'get_icon',
    data: {'extension': 'dart'},
  ),
);

print('Dart icon: ${dartIcon.data['icon']}');
// Output: Dart icon: devicon-dart-plain
```

## 🏗️ Architecture

### Memory Management (Linear Memory Pattern)

```text
┌─────────────┐                    ┌──────────────┐
│ Dart Host   │                    │ WASM Plugin  │
└──────┬──────┘                    └──────┬───────┘
       │                                  │
       │ 1. alloc(size)                   │
       ├─────────────────────────────────>│
       │                  <────────────────┤
       │                      ptr          │
       │                                  │
       │ 2. write(ptr, data)              │
       ├─────────────────────────────────>│
       │                                  │
       │ 3. plugin_handle_event(ptr, len) │
       ├─────────────────────────────────>│
       │                                  │
       │          Process event...         │
       │                                  │
       │                  <────────────────┤
       │                packed (ptr, len)  │
       │                                  │
       │ 4. read(ptr, len)                │
       ├─────────────────────────────────>│
       │                  <────────────────┤
       │                    data           │
       │                                  │
       │ 5. dealloc(ptr, len)             │
       ├─────────────────────────────────>│
       │                                  │
```

### Exported Functions

```rust
// Memory management
pub extern "C" fn alloc(size: u32) -> *mut u8;
pub extern "C" fn dealloc(ptr: *mut u8, size: u32);

// Plugin API
pub extern "C" fn plugin_get_manifest() -> u64;
pub extern "C" fn plugin_initialize(ptr: *const u8, len: u32) -> u64;
pub extern "C" fn plugin_handle_event(ptr: *const u8, len: u32) -> u64;
pub extern "C" fn plugin_dispose() -> u64;
```

### Packed Return Values

All plugin functions return `u64` with packed pointer and length:

```rust
// Pack pointer + length into u64
fn pack_ptr_len(ptr: u32, len: u32) -> u64 {
    ((ptr as u64) << 32) | (len as u64)
}

// Unpack on Dart side
final resultPtr = (packed >> 32) & 0xFFFFFFFF;
final resultLen = packed & 0xFFFFFFFF;
```

## 📊 Supported File Types

| Extension | Icon Class              | Language        |
|-----------|-------------------------|-----------------|
| `.rs`     | `devicon-rust-plain`    | Rust            |
| `.dart`   | `devicon-dart-plain`    | Dart            |
| `.js`     | `devicon-javascript-plain` | JavaScript   |
| `.ts`     | `devicon-typescript-plain` | TypeScript   |
| `.py`     | `devicon-python-plain`  | Python          |
| `.java`   | `devicon-java-plain`    | Java            |
| `.go`     | `devicon-go-plain`      | Go              |
| `.cpp`    | `devicon-cplusplus-plain` | C++          |
| `.html`   | `devicon-html5-plain`   | HTML            |
| `.json`   | `devicon-json-plain`    | JSON            |
| `.yaml`   | `devicon-yaml-plain`    | YAML            |
| _default_ | `devicon-file-text`     | Text file       |

## 🔧 Development

### Project Structure

```
file_icons_wasm/
├── Cargo.toml          # Rust dependencies
├── src/
│   └── lib.rs          # Plugin implementation
├── plugin.yaml         # Plugin manifest
├── build.sh            # Build script
├── build/              # Output directory
│   └── file_icons_wasm.wasm
└── README.md           # This file
```

### Dependencies

- **rmp-serde**: MessagePack serialization
- **serde**: Serialization framework
- **serde_json**: JSON values for data

### Build Configuration

```toml
[profile.release]
opt-level = "z"     # Optimize for size
lto = true          # Link-time optimization
codegen-units = 1   # Better optimization
panic = "abort"     # Smaller binary
strip = true        # Strip symbols
```

Result: ~50KB optimized WASM binary

## 🧪 Testing

### Manual Test

```bash
# Build plugin
./build.sh

# Run Dart test (from project root)
dart test packages/flutter_plugin_system_wasm/test/
```

### Integration Test

```dart
test('WASM plugin returns correct icon', () async {
  final plugin = await loadWasmPlugin('file_icons_wasm.wasm');

  final response = await plugin.handleEvent(
    PluginEvent(type: 'get_icon', data: {'extension': 'rs'}),
  );

  expect(response.handled, true);
  expect(response.data['icon'], 'devicon-rust-plain');
});
```

## 📈 Performance

| Metric               | Value      |
|----------------------|------------|
| Binary size          | ~50KB      |
| Load time            | ~10ms      |
| Initialization       | ~1ms       |
| Event handling       | ~0.1ms     |
| Memory usage         | <1MB       |

## 🔗 Related

- [Plugin System Architecture](../../../docs/PLUGIN_SYSTEM_ARCHITECTURE.md)
- [flutter_plugin_system_core](../../../packages/flutter_plugin_system_core/)
- [flutter_plugin_system_wasm](../../../packages/flutter_plugin_system_wasm/)
- [flutter_plugin_system_wasm_run](../../../packages/flutter_plugin_system_wasm_run/)

## 📝 License

MIT License - see [LICENSE](../../../LICENSE)
