# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial release of flutter_plugin_system_wasm
- **WASM Abstractions**: IWasmRuntime, IWasmModule, IWasmInstance, IWasmMemory
- **WasmMemoryBridge**: Memory management for Dart ↔ WASM data exchange
- **Serialization**: JSON and MessagePack serializers
  - `JsonPluginSerializer`: Development-friendly, human-readable
  - `MessagePackPluginSerializer`: Production-optimized, binary format
  - `HybridPluginSerializer`: Automatic switching based on config
- **WasmPluginAdapter**: Adapts WASM instance to IPlugin interface
- **WasmPluginRuntime**: Implements IPluginRuntime for WASM plugins
- Comprehensive documentation and examples
- Full API documentation with dartdoc
- Clean Architecture and SOLID principles implementation

### Features

- **Memory Management**: Linear memory pattern with explicit allocator
  - Automatic allocation/deallocation
  - No memory leaks (clear ownership model)
  - Efficient (minimal copies)
- **Serialization**: Hybrid approach
  - JSON for development (easy debugging)
  - MessagePack for production (30-50% smaller, faster)
- **Runtime Abstractions**: Works with any WASM runtime
  - wasmtime (JIT optimization)
  - wasmi (interpreter)
  - Future: Extism, WasmEdge support
- **Type Safety**: Strongly typed interfaces
- **Error Handling**: Comprehensive exception hierarchy

[0.1.0]: https://github.com/777genius/multi_editor_flutter/releases/tag/flutter_plugin_system_wasm-v0.1.0
