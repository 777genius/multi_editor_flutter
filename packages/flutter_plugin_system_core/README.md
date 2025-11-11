# flutter_plugin_system_core

> **Universal plugin system abstractions for Flutter - runtime-agnostic contracts and models**

[![pub package](https://img.shields.io/pub/v/flutter_plugin_system_core.svg)](https://pub.dev/packages/flutter_plugin_system_core)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Pure abstractions for building extensible plugin systems in Flutter applications. This package provides **zero-dependency** interfaces and immutable models following Clean Architecture, DDD, and SOLID principles.

## ✨ Features

- 🎯 **Pure Abstractions** - Zero dependencies (except `meta` and code generation)
- 🔌 **Runtime Agnostic** - Works with WASM, Native Dart, or Script runtimes
- 🛡️ **Type Safe** - Strongly typed interfaces with Freezed models
- 📚 **Well Documented** - Comprehensive API documentation
- 🏗️ **Clean Architecture** - Clear separation of concerns
- ♻️ **Reusable** - Use across multiple projects

## 📦 Installation

```yaml
dependencies:
  flutter_plugin_system_core: ^0.1.0
```

## 🚀 Quick Start

### 1. Define a Plugin

```dart
import 'package:flutter_plugin_system_core/flutter_plugin_system_core.dart';

class MyPlugin implements IPlugin {
  @override
  PluginManifest get manifest => PluginManifest(
    id: 'com.example.my-plugin',
    name: 'My Plugin',
    version: '1.0.0',
    description: 'Example plugin',
    runtime: PluginRuntimeType.native,
  );

  @override
  Future<void> initialize(PluginContext context) async {
    // Initialize plugin
    final config = context.config;
    print('Initializing ${manifest.name} with config: $config');
  }

  @override
  Future<PluginResponse> handleEvent(PluginEvent event) async {
    switch (event.type) {
      case 'file.opened':
        final filename = event.getData<String>('filename');
        return PluginResponse.success(data: {'processed': filename});

      default:
        return PluginResponse.error(
          message: 'Unknown event type: ${event.type}',
        );
    }
  }

  @override
  Future<void> dispose() async {
    // Cleanup
    print('Disposing ${manifest.name}');
  }
}
```

### 2. Define a Runtime

```dart
class NativeRuntime implements IPluginRuntime {
  @override
  PluginRuntimeType get type => PluginRuntimeType.native;

  @override
  Future<IPlugin> loadPlugin({
    required String pluginId,
    required PluginSource source,
    PluginConfig? config,
  }) async {
    // Load plugin based on source
    if (source.type == PluginSourceType.package) {
      return MyPlugin();
    }
    throw PluginLoadException('Unsupported source type: ${source.type}');
  }

  @override
  Future<void> unloadPlugin(String pluginId) async {
    // Cleanup runtime resources
  }

  @override
  bool isCompatible(PluginManifest manifest) {
    return manifest.runtime == PluginRuntimeType.native;
  }
}
```

### 3. Define Host Functions

```dart
class LogInfoFunction extends HostFunction<void> {
  @override
  HostFunctionSignature get signature => HostFunctionSignature(
    name: 'log_info',
    description: 'Log an info message',
    params: [
      HostFunctionParam('message', 'String', 'Message to log'),
    ],
    returnType: 'void',
  );

  @override
  Future<void> call(List<dynamic> args) async {
    final message = args[0] as String;
    print('[INFO] $message');
  }
}

class GetCurrentFileFunction extends HostFunction<FileDocument> {
  final ICodeEditorRepository repository;

  GetCurrentFileFunction(this.repository);

  @override
  HostFunctionSignature get signature => HostFunctionSignature(
    name: 'get_current_file',
    description: 'Get the currently open file',
    params: [],
    returnType: 'FileDocument',
  );

  @override
  Future<FileDocument> call(List<dynamic> args) async {
    return await repository.getCurrentFile();
  }
}
```

## 📐 Architecture

This package follows **Clean Architecture** principles with clear separation of concerns:

```text
┌────────────────────────────────────────┐
│         Contracts (Interfaces)         │
│  - IPlugin, IPluginRuntime, IPluginHost│
└────────────────┬───────────────────────┘
                 │
┌────────────────▼───────────────────────┐
│         Models (Immutable Data)        │
│  - PluginManifest, PluginContext, etc  │
└────────────────┬───────────────────────┘
                 │
┌────────────────▼───────────────────────┐
│         Types & Exceptions             │
│  - Enums, Error types                  │
└────────────────────────────────────────┘
```

### Core Concepts

#### Contracts (Ports)

- **IPlugin**: Base plugin interface
- **IPluginRuntime**: Runtime abstraction (WASM, Native, Script)
- **IPluginHost**: Host capabilities provided to plugins
- **HostFunction**: Base class for host functions

#### Models

- **PluginManifest**: Plugin metadata (ID, version, permissions)
- **PluginContext**: Isolated execution context
- **PluginEvent**: Event structure (type, data, metadata)
- **PluginResponse**: Response structure (success/error)
- **PluginConfig**: Runtime configuration
- **PluginSource**: Plugin code source (file, URL, memory)

#### Types

- **PluginRuntimeType**: `wasm`, `native`, `script`
- **PluginState**: `unloaded`, `loading`, `loaded`, `ready`, `error`, `disposed`
- **PluginSourceType**: `file`, `url`, `memory`, `package`

## 🎯 SOLID Principles

### Single Responsibility

Each interface has one clear purpose:
- `IPlugin`: Plugin lifecycle
- `IPluginRuntime`: Plugin loading
- `IPluginHost`: Host capabilities

### Open/Closed

Extend system without modifying core:
```dart
// Add new runtime without changing IPluginRuntime
class WasmRuntime implements IPluginRuntime { ... }
class ScriptRuntime implements IPluginRuntime { ... }
```

### Liskov Substitution

All plugins are interchangeable:
```dart
void processPlugin(IPlugin plugin) {
  // Works with any IPlugin implementation
  await plugin.initialize(context);
  await plugin.handleEvent(event);
}
```

### Interface Segregation

Small, focused interfaces:
```dart
// Plugin only sees what it needs
abstract class IPluginHost {
  Future<T> callHostFunction<T>(String name, List<dynamic> args);
}
```

### Dependency Inversion

Depend on abstractions:
```dart
class PluginManager {
  final IPluginRuntime runtime; // Not WasmRuntime, not NativeRuntime
  PluginManager(this.runtime);   // Dependency Injection
}
```

## 📚 API Reference

### Core Interfaces

#### IPlugin

```dart
abstract class IPlugin {
  PluginManifest get manifest;
  Future<void> initialize(PluginContext context);
  Future<PluginResponse> handleEvent(PluginEvent event);
  Future<void> dispose();
}
```

#### IPluginRuntime

```dart
abstract class IPluginRuntime {
  PluginRuntimeType get type;
  Future<IPlugin> loadPlugin({
    required String pluginId,
    required PluginSource source,
    PluginConfig? config,
  });
  Future<void> unloadPlugin(String pluginId);
  bool isCompatible(PluginManifest manifest);
}
```

#### IPluginHost

```dart
abstract class IPluginHost {
  void registerHostFunction<T>(String name, HostFunction<T> function);
  Future<T> callHostFunction<T>(String name, List<dynamic> args);
  HostCapabilities get capabilities;
}
```

### Models

All models are **immutable** (using Freezed):

```dart
final manifest = PluginManifest(
  id: 'plugin.example',
  name: 'Example',
  version: '1.0.0',
  description: 'Example plugin',
  runtime: PluginRuntimeType.wasm,
);

final event = PluginEvent.now(
  type: 'file.opened',
  targetPluginId: 'plugin.example',
  data: {'filename': 'main.dart'},
);

final response = PluginResponse.success(
  data: {'result': 'processed'},
);
```

## 🔧 Related Packages

- **flutter_plugin_system_host**: Plugin host runtime (lifecycle, messaging, security)
- **flutter_plugin_system_wasm**: WASM plugin adapter
- **flutter_plugin_system_wasm_run**: wasm_run implementation
- **flutter_plugin_system_native**: Native Dart plugin runtime
- **flutter_plugin_system**: Convenience package (re-exports all)

## 📖 Documentation

- [Architecture Document](../../docs/PLUGIN_SYSTEM_ARCHITECTURE.md)
- [API Reference](https://pub.dev/documentation/flutter_plugin_system_core/latest/)

## 🤝 Contributing

Contributions welcome! Please read our contributing guidelines.

## 📄 License

MIT License - see [LICENSE](LICENSE) file

## 🙋 Support

- [GitHub Issues](https://github.com/777genius/multi_editor_flutter/issues)
- [Documentation](https://pub.dev/documentation/flutter_plugin_system_core/latest/)
