# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial release of flutter_plugin_system_wasm_run
- **WasmRunRuntime**: IWasmRuntime implementation using wasm_run
  - Load and compile WASM modules
  - Instantiate with imports
  - Validate bytecode
  - Feature detection
- **WasmRunModule**: IWasmModule implementation
  - Import/export inspection
  - Module validation
  - Custom section access
  - Module statistics
- **WasmRunInstance**: IWasmInstance implementation
  - Function calls
  - Memory access
  - Global variables
  - Lifecycle management
- **WasmRunMemory**: IWasmMemory implementation
  - Read/write operations (sync and async)
  - Memory growth
  - Typed access (int32, int64, float32, float64)
  - Memory operations (copy, fill)
- Comprehensive documentation and examples
- Full API documentation with dartdoc
- Clean Architecture and SOLID principles implementation

### Features

- **Platform Optimized**:
  - Desktop: wasmtime with JIT compilation
  - Mobile: wasmi interpreter
  - Web: Native WebAssembly
- **WASI Support**: Full WASI snapshot preview 1
- **Feature Detection**: WASI, multi-value, bulk memory, SIMD, reference types
- **Performance**: JIT optimization on desktop platforms
- **Memory Safety**: Bounds checking, explicit ownership
- **Validation**: Module validation and bytecode verification

[0.1.0]: https://github.com/777genius/multi_editor_flutter/releases/tag/flutter_plugin_system_wasm_run-v0.1.0
