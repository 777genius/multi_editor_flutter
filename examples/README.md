# Flutter Plugin System Examples

Practical examples demonstrating the Flutter Plugin System with WASM integration.

## 📚 Available Examples

### [plugins/file_icons_wasm](plugins/file_icons_wasm/)

**Rust → WASM Plugin Example**

Complete example showing:
- ✅ Rust plugin compiled to WASM
- ✅ Linear Memory Pattern implementation
- ✅ MessagePack serialization
- ✅ File icon mapping (20+ types)
- ✅ Full Dart integration example

**Quick Start:**
```bash
cd plugins/file_icons_wasm
./build.sh
dart run example.dart
```

## 🎯 What You'll Learn

### 1. Plugin Development

- Writing plugins in Rust
- Compiling to WebAssembly
- Memory management patterns
- Serialization protocols

### 2. Plugin Integration

- Loading WASM plugins from Dart
- Event-driven communication
- Error handling
- Performance optimization

### 3. Architecture Patterns

- Linear Memory Pattern
- Packed pointer returns
- Zero-copy data exchange
- Plugin lifecycle management

## 🏗️ Example Structure

Each example includes:

```
example_plugin/
├── Cargo.toml          # Rust dependencies
├── src/
│   └── lib.rs          # Plugin implementation (Rust)
├── plugin.yaml         # Plugin manifest
├── build.sh            # Build script
├── example.dart        # Usage example (Dart)
└── README.md           # Documentation
```

## 📖 Documentation

- [Plugin System Architecture](../docs/PLUGIN_SYSTEM_ARCHITECTURE.md)
- [Core Package](../packages/flutter_plugin_system_core/)
- [Host Package](../packages/flutter_plugin_system_host/)
- [WASM Package](../packages/flutter_plugin_system_wasm/)
- [WASM Runtime](../packages/flutter_plugin_system_wasm_run/)

## 🚀 Creating Your Own Plugin

### 1. Setup Rust Project

```bash
cargo new --lib my_plugin
cd my_plugin
```

### 2. Configure for WASM

**Cargo.toml:**
```toml
[lib]
crate-type = ["cdylib"]

[dependencies]
rmp-serde = "1.1"
serde = { version = "1.0", features = ["derive"] }
```

### 3. Implement Plugin API

**src/lib.rs:**
```rust
#[no_mangle]
pub extern "C" fn alloc(size: u32) -> *mut u8 { /* ... */ }

#[no_mangle]
pub extern "C" fn dealloc(ptr: *mut u8, size: u32) { /* ... */ }

#[no_mangle]
pub extern "C" fn plugin_get_manifest() -> u64 { /* ... */ }

#[no_mangle]
pub extern "C" fn plugin_initialize(ptr: *const u8, len: u32) -> u64 { /* ... */ }

#[no_mangle]
pub extern "C" fn plugin_handle_event(ptr: *const u8, len: u32) -> u64 { /* ... */ }

#[no_mangle]
pub extern "C" fn plugin_dispose() -> u64 { /* ... */ }
```

### 4. Build

```bash
cargo build --target wasm32-unknown-unknown --release
```

### 5. Use from Dart

```dart
final plugin = await pluginManager.loadPlugin(
  pluginId: 'my-plugin',
  source: PluginSource.file(path: 'my_plugin.wasm'),
  runtime: wasmRuntime,
);

await plugin.handleEvent(myEvent);
```

## 🔧 Development Tools

### Required

- **Rust** (https://rustup.rs)
- **wasm32 target**: `rustup target add wasm32-unknown-unknown`

### Optional

- **wasm-opt**: `cargo install wasm-opt` (optimize binaries)
- **wabt**: WASM toolkit for debugging
- **cargo-watch**: `cargo install cargo-watch` (auto-rebuild)

## 📊 Performance Tips

1. **Optimize for size**: Use `opt-level = "z"` in Cargo.toml
2. **Enable LTO**: `lto = true` for link-time optimization
3. **Strip symbols**: `strip = true` to remove debug info
4. **Use MessagePack**: Smaller than JSON (~30-50% savings)
5. **Minimize allocations**: Reuse buffers when possible

## 🧪 Testing

### Unit Tests (Rust)

```bash
cd plugins/my_plugin
cargo test
```

### Integration Tests (Dart)

```bash
# From project root
dart test packages/flutter_plugin_system_wasm/test/
```

## 📝 License

MIT License - see [LICENSE](../LICENSE)
