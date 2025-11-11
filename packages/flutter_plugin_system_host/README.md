# flutter_plugin_system_host

> **Plugin host runtime for Flutter - manages plugin lifecycle, host functions, messaging, security, and discovery**

[![pub package](https://img.shields.io/pub/v/flutter_plugin_system_host.svg)](https://pub.dev/packages/flutter_plugin_system_host)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Complete plugin host runtime for Flutter applications. Provides plugin lifecycle management, host function registry, event messaging, security enforcement, and error isolation.

## ✨ Features

- 🎯 **PluginManager** - Unified facade for all plugin operations
- 📦 **PluginRegistry** - Central registry with lifecycle state management
- 🔧 **HostFunctionRegistry** - Expose host capabilities to plugins
- 📡 **EventDispatcher** - Reactive pub/sub event system (RxDart)
- 🛡️ **SecurityGuard** - Permission enforcement with runtime limits
- 🔐 **PermissionSystem** - Manifest-based permission management
- 🚨 **ErrorBoundary** - Error isolation prevents plugin crashes
- 📊 **ErrorTracker** - Comprehensive error monitoring and history

## 📦 Installation

```yaml
dependencies:
  flutter_plugin_system_host: ^0.1.0
  flutter_plugin_system_core: ^0.1.0
```

## 🚀 Quick Start

### 1. Create Plugin Manager

```dart
import 'package:flutter_plugin_system_host/flutter_plugin_system_host.dart';

// Create manager with default components
final manager = PluginManager.create();

// Or create with custom components
final manager = PluginManager(
  registry: PluginRegistry(),
  hostFunctions: HostFunctionRegistry(),
  eventDispatcher: EventDispatcher(),
  permissionSystem: PermissionSystem(),
  securityGuard: SecurityGuard(permissionSystem),
  errorTracker: ErrorTracker(),
  errorBoundary: ErrorBoundary(errorTracker),
);
```

### 2. Register Host Functions

```dart
// Define a host function
class LogInfoFunction extends HostFunction<void> {
  @override
  HostFunctionSignature get signature => HostFunctionSignature(
    name: 'log_info',
    description: 'Log an info message',
    params: [HostFunctionParam('message', 'String', 'Message to log')],
    returnType: 'void',
  );

  @override
  Future<void> call(List<dynamic> args) async {
    final message = args[0] as String;
    print('[INFO] $message');
  }
}

// Register it
manager.registerHostFunction('log_info', LogInfoFunction());
```

### 3. Load a Plugin

```dart
// Define manifest
final manifest = PluginManifest(
  id: 'plugin.file-icons',
  name: 'File Icons',
  version: '1.0.0',
  description: 'Beautiful file icons',
  runtime: PluginRuntimeType.wasm,
  requiredHostFunctions: ['log_info', 'get_file_extension'],
);

// Load plugin
await manager.loadPlugin(
  manifest: manifest,
  source: PluginSource.file(path: 'plugins/file_icons.wasm'),
  runtime: wasmRuntime,
);
```

### 4. Send Events to Plugins

```dart
// Send event to specific plugin
final response = await manager.sendEvent(
  PluginEvent.now(
    type: 'file.opened',
    targetPluginId: 'plugin.file-icons',
    data: {'filename': 'main.dart', 'path': '/src/main.dart'},
  ),
);

if (response.isSuccess) {
  final icon = response.getData<String>('icon');
  print('Icon: $icon');
}

// Broadcast event to all subscribed plugins
manager.dispatchEvent(
  PluginEvent.now(
    type: 'file.saved',
    data: {'filename': 'main.dart'},
  ),
);
```

### 5. Monitor Events and Errors

```dart
// Listen to all events
manager.eventStream.listen((event) {
  print('Event: ${event.type} → ${event.targetPluginId}');
});

// Listen to errors
manager.errorStream.listen((error) {
  print('Error in ${error.pluginId}: ${error.message}');
});
```

## 📐 Architecture

### Component Overview

```text
┌─────────────────────────────────────────────────────┐
│             PluginManager (Facade)                  │
│  Unified interface to the plugin system             │
└───────────────────┬─────────────────────────────────┘
                    │
      ┌─────────────┼─────────────┐
      │             │             │
┌─────▼─────┐ ┌────▼────┐ ┌──────▼──────┐
│  Runtime  │ │  Host   │ │  Messaging  │
│ PluginReg │ │ HostFunc│ │   Events    │
│           │ │         │ │   Pub/Sub   │
└───────────┘ └─────────┘ └─────────────┘
      │             │             │
┌─────▼─────────────▼─────────────▼──────┐
│           Security Layer                │
│  PermissionSystem │ SecurityGuard       │
│  ErrorBoundary    │ ErrorTracker        │
└─────────────────────────────────────────┘
```

### Plugin Lifecycle

```text
┌──────────┐
│ UNLOADED │
└────┬─────┘
     │ loadPlugin()
     ▼
┌──────────┐
│ LOADING  │ ← Runtime loads plugin code
└────┬─────┘
     │ loadComplete()
     ▼
┌──────────┐
│  LOADED  │ ← Plugin code loaded
└────┬─────┘
     │ initialize()
     ▼
┌─────────────┐
│INITIALIZING │ ← Plugin.initialize() called
└────┬────────┘
     │ initComplete()
     ▼
┌──────────┐      ┌───────┐
│  READY   │─────>│ ERROR │ ← Errors tracked
└────┬─────┘      └───────┘
     │ dispose()
     ▼
┌──────────┐
│ DISPOSED │
└──────────┘
```

## 🎯 Core Components

### PluginManager

Facade that provides a unified interface to all plugin system components.

```dart
final manager = PluginManager.create();

// Load plugin
await manager.loadPlugin(manifest: manifest, source: source, runtime: runtime);

// Send event
final response = await manager.sendEvent(event);

// Query plugins
final plugin = manager.getPlugin('plugin.example');
final allPlugins = manager.getAllPlugins();
final readyPlugins = manager.getPluginsByState(PluginState.ready);

// Statistics
final stats = manager.getStatistics();
print('Total plugins: ${stats['registry']['total_plugins']}');

// Cleanup
await manager.dispose();
```

### PluginRegistry

Central registry for plugin lifecycle management.

```dart
final registry = PluginRegistry();

// Register plugin
registry.register(pluginId, plugin, context, state: PluginState.ready);

// Update state
registry.updateState(pluginId, PluginState.error);

// Query
final plugin = registry.getPlugin(pluginId);
final state = registry.getState(pluginId);
final readyPlugins = registry.getPluginsByState(PluginState.ready);

// Statistics
final stats = registry.getStatistics();
```

### HostFunctionRegistry

Registry for host capabilities exposed to plugins.

```dart
final hostFunctions = HostFunctionRegistry();

// Register function
hostFunctions.register('log_info', LogInfoFunction());

// Call function
final result = await hostFunctions.call<void>('log_info', ['Hello!']);

// Query
final hasFunction = hostFunctions.has('log_info');
final signature = hostFunctions.getSignature('log_info');
final callCount = hostFunctions.getCallCount('log_info');
```

### EventDispatcher

Reactive pub/sub event system using RxDart.

```dart
final dispatcher = EventDispatcher();

// Listen to all events
dispatcher.stream.listen((event) {
  print('Event: ${event.type}');
});

// Listen to specific event type
dispatcher.streamFor('file.opened').listen((event) {
  print('File opened: ${event.data}');
});

// Listen to multiple event types
dispatcher.streamForAny(['file.opened', 'file.closed']).listen((event) {
  print('File event: ${event.type}');
});

// Dispatch event
dispatcher.dispatch(event);

// Statistics
final stats = dispatcher.getStatistics();
```

### SecurityGuard & PermissionSystem

Security enforcement with permission checking and runtime limits.

```dart
final permissionSystem = PermissionSystem();
final securityGuard = SecurityGuard(permissionSystem);

// Register permissions
permissionSystem.registerPlugin(
  'plugin.example',
  PluginPermissions(
    allowedHostFunctions: ['log_info', 'get_file_content'],
    maxExecutionTime: Duration(seconds: 5),
    maxMemoryBytes: 50 * 1024 * 1024, // 50 MB
    filesystemAccess: FilesystemAccessLevel.readOnly,
  ),
);

// Check permissions
if (securityGuard.canCallHostFunction(pluginId, 'log_info')) {
  // Allow call
}

// Enforce permissions
securityGuard.enforceHostFunctionPermission(pluginId, 'log_info');
securityGuard.enforceNetworkPermission(pluginId);
securityGuard.enforceFilesystemPermission(pluginId, FilesystemAccessLevel.readOnly);

// Execute with timeout
final result = await securityGuard.executeWithTimeout(
  pluginId,
  () => plugin.handleEvent(event),
);

// Check memory limit
securityGuard.checkMemoryLimit(pluginId, usedBytes);
```

### ErrorBoundary & ErrorTracker

Error isolation and tracking for fault tolerance.

```dart
final errorTracker = ErrorTracker();
final errorBoundary = ErrorBoundary(errorTracker);

// Execute with error isolation
final result = await errorBoundary.execute<String>(
  'plugin.example',
  () => plugin.handleEvent(event),
  fallback: (error) => 'default_value',
);

// Execute with timeout
await errorBoundary.executeWithTimeout(
  pluginId,
  () => plugin.process(),
  timeout: Duration(seconds: 5),
);

// Execute with retry
await errorBoundary.executeWithRetry(
  pluginId,
  () => plugin.fetchRemoteData(),
  maxRetries: 3,
  retryDelay: Duration(seconds: 2),
);

// Get errors
final errors = errorTracker.getErrors('plugin.example');
for (final error in errors) {
  print('${error.timestamp}: ${error.message}');
}

// Listen to errors
errorTracker.errors.listen((error) {
  print('Error in ${error.pluginId}: ${error.message}');
});
```

## 🔧 Advanced Usage

### Custom Host Function with Dependencies

```dart
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

// Register with dependency
manager.registerHostFunction(
  'get_current_file',
  GetCurrentFileFunction(editorRepository),
);
```

### Event Filtering and Pattern Matching

```dart
// Listen to file events with pattern
dispatcher.streamForPattern('file.*').listen((event) {
  print('File event: ${event.type}');
});

// Filter events by data
dispatcher.stream
  .where((event) => event.type == 'file.opened')
  .where((event) => event.getData<String>('extension') == '.dart')
  .listen((event) {
    print('Dart file opened: ${event.data}');
  });
```

### Custom Permissions

```dart
final permissions = PluginPermissions(
  allowedHostFunctions: ['log_info', 'get_file_content'],
  maxExecutionTime: Duration(seconds: 10),
  maxMemoryBytes: 100 * 1024 * 1024, // 100 MB
  maxCallDepth: 200,
  canAccessNetwork: true,
  filesystemAccess: FilesystemAccessLevel.readWrite,
  customLimits: {
    'max_concurrent_requests': 5,
    'cache_size_bytes': 10 * 1024 * 1024,
  },
);
```

## 📊 Monitoring and Statistics

```dart
// System statistics
final stats = manager.getStatistics();
print('Registry: ${stats['registry']}');
print('Host Functions: ${stats['host_functions']}');
print('Events: ${stats['events']}');
print('Permissions: ${stats['permissions']}');

// Plugin-specific errors
final errors = manager.getPluginErrors('plugin.example');
for (final error in errors) {
  print('${error.severity}: ${error.message}');
}

// Security summary
final summary = securityGuard.getSecuritySummary('plugin.example');
print('Allowed functions: ${summary['allowed_host_functions']}');
print('Max execution time: ${summary['max_execution_time_ms']}ms');
```

## 🏗️ Architecture Principles

This package follows:

- **Clean Architecture** - Clear separation of concerns
- **SOLID Principles** - Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion
- **DDD** - Domain-Driven Design with bounded contexts
- **DRY** - Don't Repeat Yourself
- **Facade Pattern** - PluginManager provides unified interface
- **Registry Pattern** - Centralized plugin and function management
- **Pub/Sub Pattern** - Event-driven architecture
- **Error Isolation** - Prevent plugin errors from crashing host

## 🔗 Related Packages

- **flutter_plugin_system_core**: Pure abstractions and interfaces
- **flutter_plugin_system_wasm**: WASM plugin adapter
- **flutter_plugin_system_wasm_run**: wasm_run implementation
- **flutter_plugin_system_native**: Native Dart plugin runtime
- **flutter_plugin_system**: Convenience package (re-exports all)

## 📖 Documentation

- [Architecture Document](../../docs/PLUGIN_SYSTEM_ARCHITECTURE.md)
- [API Reference](https://pub.dev/documentation/flutter_plugin_system_host/latest/)

## 🤝 Contributing

Contributions welcome! Please read our contributing guidelines.

## 📄 License

MIT License - see [LICENSE](LICENSE) file

## 🙋 Support

- [GitHub Issues](https://github.com/777genius/multi_editor_flutter/issues)
- [Documentation](https://pub.dev/documentation/flutter_plugin_system_host/latest/)
