# Plugin System Architecture

> **Модульная, расширяемая система плагинов для Flutter с WASM поддержкой**
>
> Version: 1.0.0
> Date: 2025-01-10
> Status: Design & Implementation

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Architectural Principles](#architectural-principles)
3. [System Architecture](#system-architecture)
4. [Module Structure](#module-structure)
5. [WASM Runtime Strategy](#wasm-runtime-strategy)
6. [Host Functions & Communication](#host-functions--communication)
7. [Memory Management](#memory-management)
8. [Security & Sandboxing](#security--sandboxing)
9. [Plugin Lifecycle](#plugin-lifecycle)
10. [Error Handling](#error-handling)
11. [Performance](#performance)
12. [API Reference](#api-reference)
13. [Implementation Guidelines](#implementation-guidelines)

---

## Overview

### Vision

Создать **универсальную, модульную систему плагинов** для Flutter приложений, которая:

- ✅ **Изолирована**: Каждый плагин работает в изолированной среде (WASM sandbox)
- ✅ **Расширяема**: Open/Closed Principle - расширяется без изменения ядра
- ✅ **Переиспользуема**: Модули публикуются на pub.dev и используются между проектами
- ✅ **Мульти-язычна**: Плагины пишутся на Rust, Go, C, JavaScript, Dart
- ✅ **Безопасна**: Permission-based security model с runtime limits
- ✅ **Производительна**: WASM JIT compilation (wasmtime) + zero-copy где возможно

### Target Use Cases

1. **Code Editor Plugins**: LSP support, formatters, linters, language extensions
2. **File System Plugins**: Icons, previews, custom file handlers
3. **UI Extensions**: Custom panels, toolbars, context menus
4. **Data Transformers**: Import/export filters, data processors
5. **Integrations**: Git, Docker, Cloud services

---

## Architectural Principles

### 1. Clean Architecture

```
┌─────────────────────────────────────────────────────┐
│            Presentation Layer (UI)                   │
│         - Widgets, Screens, Controllers              │
└────────────────────┬────────────────────────────────┘
                     │ depends on (uses)
┌────────────────────▼────────────────────────────────┐
│         Application Layer (Use Cases)                │
│    - Business Logic, Orchestration, Services         │
└────────────────────┬────────────────────────────────┘
                     │ depends on (uses)
┌────────────────────▼────────────────────────────────┐
│         Domain Layer (Entities & Ports)              │
│  - IPlugin, IPluginRuntime, IPluginHost (interfaces) │
│  - PluginManifest, PluginContext (pure models)       │
└────────────────────▲────────────────────────────────┘
                     │ implemented by
┌────────────────────┴────────────────────────────────┐
│      Infrastructure Layer (Adapters)                 │
│   - WasmPluginAdapter, NativePluginAdapter          │
│   - FileSystemLoader, NetworkLoader                  │
└─────────────────────────────────────────────────────┘
```

**Dependency Rule**: Внутренние слои не знают о внешних. Зависимости направлены внутрь.

### 2. Domain-Driven Design (DDD)

#### Bounded Contexts

```
┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐
│   Plugin Context     │  │   Host Context       │  │   Runtime Context    │
│                      │  │                      │  │                      │
│  - Plugin            │  │  - HostFunction      │  │  - WasmRuntime       │
│  - PluginManifest    │  │  - Permissions       │  │  - WasmModule        │
│  - PluginEvent       │  │  - Capabilities      │  │  - WasmInstance      │
└──────────────────────┘  └──────────────────────┘  └──────────────────────┘
```

#### Aggregates

- **PluginAggregate**: Root = Plugin, содержит Context, State, Permissions
- **RuntimeAggregate**: Root = Runtime, содержит Modules, Instances

#### Value Objects

- `PluginId`: Уникальный идентификатор (immutable)
- `PluginVersion`: Semantic version (immutable)
- `PermissionSet`: Набор разрешений (immutable)

#### Ports & Adapters (Hexagonal Architecture)

```
                    ┌─────────────────┐
                    │   Application   │
                    │      Core       │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
  ┌─────▼─────┐        ┌─────▼─────┐       ┌─────▼─────┐
  │   Port    │        │   Port    │       │   Port    │
  │ IPlugin   │        │ IRuntime  │       │  IHost    │
  └─────┬─────┘        └─────┬─────┘       └─────┬─────┘
        │                    │                    │
  ┌─────▼─────┐        ┌─────▼─────┐       ┌─────▼─────┐
  │  Adapter  │        │  Adapter  │       │  Adapter  │
  │WasmPlugin │        │ WasmRun   │       │ EditorHost│
  └───────────┘        └───────────┘       └───────────┘
```

### 3. SOLID Principles

#### S - Single Responsibility Principle

✅ **Каждый модуль = одна ответственность**

- `core`: Определяет контракты
- `host`: Управляет lifecycle
- `wasm`: Абстрагирует WASM runtime
- `wasm_run_impl`: Конкретная реализация через wasm_run

#### O - Open/Closed Principle

✅ **Система открыта для расширения, закрыта для модификации**

```dart
// ❌ BAD: Нужно модифицировать класс для нового типа
class PluginManager {
  void loadPlugin(String type) {
    if (type == 'wasm') { ... }
    else if (type == 'native') { ... }
    // Нужно добавлять новые if для каждого типа
  }
}

// ✅ GOOD: Расширение через новую реализацию
abstract class IPluginRuntime {
  Future<IPlugin> loadPlugin(...);
}

class WasmRuntime implements IPluginRuntime { ... }
class NativeRuntime implements IPluginRuntime { ... }
class ScriptRuntime implements IPluginRuntime { ... } // Новый тип без изменения существующего кода
```

#### L - Liskov Substitution Principle

✅ **Все реализации IPlugin взаимозаменяемы**

```dart
void processPlugin(IPlugin plugin) {
  // Работает одинаково для WasmPlugin, NativePlugin, ScriptPlugin
  await plugin.initialize(context);
  final response = await plugin.handleEvent(event);
}
```

#### I - Interface Segregation Principle

✅ **Мелкие специфичные интерфейсы**

```dart
// ❌ BAD: Fat interface
abstract class IPlugin {
  Future<void> initialize();
  Future<void> dispose();
  Future<void> handleEvent();
  Future<void> handleWasmMemory();  // Только для WASM
  Future<void> handleNativeCall();  // Только для Native
}

// ✅ GOOD: Segregated interfaces
abstract class IPlugin {
  Future<void> initialize();
  Future<void> dispose();
  Future<void> handleEvent();
}

abstract class IWasmPlugin extends IPlugin {
  Future<void> handleWasmMemory();
}

abstract class INativePlugin extends IPlugin {
  Future<void> handleNativeCall();
}
```

#### D - Dependency Inversion Principle

✅ **Зависимость от абстракций, не от реализаций**

```dart
// ✅ Зависим от IPluginRuntime (абстракция)
class PluginManager {
  final IPluginRuntime runtime;  // Не WasmRuntime, не NativeRuntime

  PluginManager(this.runtime);  // Dependency Injection
}
```

### 4. DRY (Don't Repeat Yourself)

✅ **Переиспользуемые компоненты**

- **Base Plugin Contracts**: Один раз определены в `core`
- **Memory Management Pattern**: Переиспользуется всеми WASM плагинами
- **Serialization Strategy**: Единый подход для всех плагинов
- **Error Handling**: Общий ErrorTracker для всех runtime

---

## System Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      APPLICATION LAYER                          │
│              (IDE / Your Flutter App)                           │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ uses
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              flutter_plugin_system_host                         │
│                                                                  │
│  ┌────────────────┐  ┌────────────────┐  ┌─────────────────┐  │
│  │ PluginManager  │  │HostFunctionReg │  │ EventDispatcher │  │
│  │   (Facade)     │  │   (Registry)   │  │   (Pub/Sub)     │  │
│  └────────────────┘  └────────────────┘  └─────────────────┘  │
│                                                                  │
│  ┌────────────────┐  ┌────────────────┐  ┌─────────────────┐  │
│  │PluginRegistry  │  │ ErrorTracker   │  │  SecurityGuard  │  │
│  └────────────────┘  └────────────────┘  └─────────────────┘  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ depends on
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              flutter_plugin_system_core                         │
│                    (Pure Abstractions)                          │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Contracts (Interfaces)                                   │  │
│  │  - IPlugin, IPluginRuntime, IPluginHost, IHostFunction   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Models (Immutable Data)                                  │  │
│  │  - PluginManifest, PluginContext, PluginEvent            │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ implemented by
                         ▼
        ┌────────────────┴────────────────┬────────────────────┐
        │                                 │                    │
        ▼                                 ▼                    ▼
┌───────────────────┐      ┌──────────────────────┐   ┌──────────────┐
│flutter_plugin_    │      │flutter_plugin_       │   │flutter_plugin│
│system_wasm        │      │system_native         │   │_system_script│
│                   │      │                      │   │              │
│ (WASM Adapter)    │      │ (Dart Native Plugin) │   │ (JS/Lua/etc) │
└─────────┬─────────┘      └──────────────────────┘   └──────────────┘
          │
          │ implemented by
          ▼
┌──────────────────────────┐
│flutter_plugin_system_    │
│wasm_run                  │
│                          │
│ (wasm_run Implementation)│
└──────────────────────────┘
```

### Module Dependencies

```
core (ZERO dependencies)
  ↑
  │
  ├─── host (depends: core)
  │     ↑
  │     │
  │     ├─── wasm (depends: core, host)
  │     │     ↑
  │     │     │
  │     │     └─── wasm_run_impl (depends: wasm, wasm_run)
  │     │
  │     └─── native (depends: core, host)
  │
  └─── all (convenience package, re-exports all)
```

---

## Module Structure

### 1. `flutter_plugin_system_core`

**Purpose**: Universal abstractions - ZERO dependencies (except meta)

**Exports**:
- Contracts: `IPlugin`, `IPluginRuntime`, `IPluginHost`, `IHostFunction`
- Models: `PluginManifest`, `PluginContext`, `PluginEvent`, `PluginResponse`
- Exceptions: `PluginException`, `RuntimeException`, `HostFunctionException`
- Types: `PluginRuntimeType`, `PluginState`

**Structure**:
```
lib/
├── src/
│   ├── contracts/
│   │   ├── i_plugin.dart
│   │   ├── i_plugin_runtime.dart
│   │   ├── i_plugin_host.dart
│   │   └── i_host_function.dart
│   ├── models/
│   │   ├── plugin_manifest.dart
│   │   ├── plugin_context.dart
│   │   ├── plugin_event.dart
│   │   ├── plugin_response.dart
│   │   └── plugin_config.dart
│   ├── exceptions/
│   │   ├── plugin_exception.dart
│   │   └── runtime_exception.dart
│   └── types/
│       └── plugin_types.dart
└── flutter_plugin_system_core.dart
```

### 2. `flutter_plugin_system_host`

**Purpose**: Plugin host runtime - manages lifecycle, messaging, security

**Exports**:
- Runtime: `PluginManager`, `PluginRegistry`, `PluginLoader`
- Host: `HostFunctionRegistry`, `HostContext`, `HostCapabilities`
- Messaging: `MessageBus`, `EventDispatcher`, `PluginChannel`
- Security: `ErrorBoundary`, `ErrorTracker`, `SecurityGuard`, `PermissionSystem`
- Discovery: `PluginDiscoverer`, `ManifestParser`

**Structure**:
```
lib/
├── src/
│   ├── runtime/
│   │   ├── plugin_manager.dart
│   │   ├── plugin_registry.dart
│   │   ├── plugin_loader.dart
│   │   └── plugin_lifecycle.dart
│   ├── host/
│   │   ├── host_function_registry.dart
│   │   ├── host_context.dart
│   │   └── host_capabilities.dart
│   ├── messaging/
│   │   ├── message_bus.dart
│   │   ├── event_dispatcher.dart
│   │   └── plugin_channel.dart
│   ├── security/
│   │   ├── error_boundary.dart
│   │   ├── error_tracker.dart
│   │   ├── security_guard.dart
│   │   └── permission_system.dart
│   └── discovery/
│       ├── plugin_discoverer.dart
│       └── manifest_parser.dart
└── flutter_plugin_system_host.dart
```

### 3. `flutter_plugin_system_wasm`

**Purpose**: WASM adapter - runtime-agnostic abstraction

**Exports**:
- Contracts: `IWasmRuntime`, `IWasmModule`, `IWasmInstance`, `IWasmMemory`
- Adapters: `WasmPluginAdapter`, `WasmHostFunctionAdapter`
- Models: `WasmValue`, `WasmExport`, `WasmImport`, `WasmFeatures`
- Serialization: `PluginSerializer`, `JsonSerializer`, `MessagePackSerializer`
- Memory: `WasmMemoryBridge`, `MemoryAllocator`

**Structure**:
```
lib/
├── src/
│   ├── contracts/
│   │   ├── i_wasm_runtime.dart
│   │   ├── i_wasm_module.dart
│   │   ├── i_wasm_instance.dart
│   │   └── i_wasm_memory.dart
│   ├── adapters/
│   │   ├── wasm_plugin_adapter.dart
│   │   └── wasm_host_function_adapter.dart
│   ├── models/
│   │   ├── wasm_value.dart
│   │   ├── wasm_export.dart
│   │   ├── wasm_import.dart
│   │   └── wasm_features.dart
│   ├── serialization/
│   │   ├── plugin_serializer.dart
│   │   ├── json_serializer.dart
│   │   └── msgpack_serializer.dart
│   └── memory/
│       ├── wasm_memory_bridge.dart
│       └── memory_allocator.dart
└── flutter_plugin_system_wasm.dart
```

### 4. `flutter_plugin_system_wasm_run`

**Purpose**: wasm_run implementation of IWasmRuntime

**Exports**:
- Runtime: `WasmRunRuntime`, `WasmRunModule`, `WasmRunInstance`
- Bridge: `HostFunctionBridge`, `MemoryBridge`

**Structure**:
```
lib/
├── src/
│   ├── runtime/
│   │   ├── wasm_run_runtime.dart
│   │   ├── wasm_run_module.dart
│   │   └── wasm_run_instance.dart
│   └── bridge/
│       ├── host_function_bridge.dart
│       └── memory_bridge.dart
└── flutter_plugin_system_wasm_run.dart
```

### 5. `flutter_plugin_system_native`

**Purpose**: Native Dart plugin runtime

**Exports**:
- Runtime: `NativePluginRuntime`
- Base: `NativePluginBase`

**Structure**:
```
lib/
├── src/
│   ├── runtime/
│   │   └── native_plugin_runtime.dart
│   └── base/
│       └── native_plugin_base.dart
└── flutter_plugin_system_native.dart
```

### 6. `flutter_plugin_system` (Convenience Package)

**Purpose**: Re-exports all modules for easy import

```dart
export 'package:flutter_plugin_system_core/flutter_plugin_system_core.dart';
export 'package:flutter_plugin_system_host/flutter_plugin_system_host.dart';
export 'package:flutter_plugin_system_wasm/flutter_plugin_system_wasm.dart';
export 'package:flutter_plugin_system_wasm_run/flutter_plugin_system_wasm_run.dart';
export 'package:flutter_plugin_system_native/flutter_plugin_system_native.dart';
```

---

## WASM Runtime Strategy

### Runtime Selection: wasm_run

**Decision**: Используем `wasm_run` как основной WASM runtime.

**Reasons**:
- ✅ **Доступен сейчас**: Опубликован на pub.dev
- ✅ **Performance**: wasmtime (JIT) для desktop, wasmi для mobile
- ✅ **Platform Support**: Native (Linux, macOS, Windows, iOS, Android) + Web
- ✅ **Flutter Integration**: flutter_rust_bridge для FFI
- ✅ **WASI Support**: Полная поддержка WASI snapshot preview 1

**Future**: Абстракция позволит добавить extism когда появится Dart SDK.

### WASM Module Standard Interface

Каждый WASM плагин должен экспортировать:

```rust
// Required exports
#[no_mangle]
pub extern "C" fn plugin_get_manifest() -> u64;

#[no_mangle]
pub extern "C" fn plugin_initialize() -> i32;

#[no_mangle]
pub extern "C" fn plugin_handle_event(ptr: *const u8, len: usize) -> u64;

#[no_mangle]
pub extern "C" fn plugin_dispose() -> i32;

// Memory management
#[no_mangle]
pub extern "C" fn alloc(size: usize) -> *mut u8;

#[no_mangle]
pub extern "C" fn dealloc(ptr: *mut u8, size: usize);
```

---

## Host Functions & Communication

### Host Function System

**Concept**: Плагины вызывают функции хоста через `HostFunctionRegistry`.

```dart
// Host side
final registry = HostFunctionRegistry();

// Регистрация host function
registry.register('log_info', LogInfoHostFunction());
registry.register('get_current_file', GetCurrentFileHostFunction());
registry.register('open_file', OpenFileHostFunction());

// WASM side (Rust)
#[host_fn]
extern "ExtismHost" {
    fn log_info(ptr: u64, len: u32);
    fn get_current_file() -> u64;
    fn open_file(ptr: u64, len: u32) -> u64;
}
```

### Host Function Pattern

```dart
abstract class HostFunction<TResult> {
  /// Вызов функции
  Future<TResult> call(List<dynamic> args);

  /// Signature для валидации
  HostFunctionSignature get signature;
}

class GetCurrentFileHostFunction extends HostFunction<FileDocument> {
  final ICodeEditorRepository _editorRepository;

  GetCurrentFileHostFunction(this._editorRepository);

  @override
  HostFunctionSignature get signature => HostFunctionSignature(
    name: 'get_current_file',
    params: [],
    returnType: 'FileDocument',
  );

  @override
  Future<FileDocument> call(List<dynamic> args) async {
    return await _editorRepository.getCurrentFile();
  }
}
```

### Serialization Strategy

**Hybrid Approach**: JSON для development, MessagePack для production

```dart
abstract class PluginSerializer {
  Uint8List serialize(Map<String, dynamic> data);
  Map<String, dynamic> deserialize(Uint8List bytes);
}

// Development: Easy debugging
class JsonPluginSerializer implements PluginSerializer {
  @override
  Uint8List serialize(Map<String, dynamic> data) {
    final json = jsonEncode(data);
    return Uint8List.fromList(utf8.encode(json));
  }

  @override
  Map<String, dynamic> deserialize(Uint8List bytes) {
    final json = utf8.decode(bytes);
    return jsonDecode(json) as Map<String, dynamic>;
  }
}

// Production: Performance
class MessagePackPluginSerializer implements PluginSerializer {
  // msgpack implementation
}
```

**Usage**:
```dart
final serializer = config.isDebug
    ? JsonPluginSerializer()
    : MessagePackPluginSerializer();
```

---

## Memory Management

### Linear Memory Pattern

**Problem**: WASM и Dart имеют разные модели памяти. Как передавать данные?

**Solution**: Linear Memory + Explicit Allocator

```
┌─────────────────────────────────────────┐
│         Dart (Host) Memory              │
│                                         │
│  Uint8List data = [1,2,3,4,5]          │
└───────────────┬─────────────────────────┘
                │
                │ 1. Serialize
                ▼
      ┌──────────────────┐
      │ [JSON/MessagePack│
      │  bytes]          │
      └────────┬─────────┘
               │
               │ 2. Allocate in WASM
               ▼
┌─────────────────────────────────────────┐
│     WASM Linear Memory                  │
│                                         │
│  ┌────────────────────────────────┐    │
│  │ ptr ──> [serialized data]      │    │
│  └────────────────────────────────┘    │
│                                         │
│  3. Plugin processes data               │
│                                         │
│  ┌────────────────────────────────┐    │
│  │ result_ptr ──> [result data]   │    │
│  └────────────────────────────────┘    │
└───────────────┬─────────────────────────┘
                │
                │ 4. Read result
                ▼
      ┌──────────────────┐
      │ [result bytes]   │
      └────────┬─────────┘
               │
               │ 5. Deserialize
               ▼
┌─────────────────────────────────────────┐
│         Dart (Host) Memory              │
│                                         │
│  Map<String, dynamic> result            │
└─────────────────────────────────────────┘
```

### Implementation

**WASM Side (Rust)**:
```rust
use std::alloc::{alloc, dealloc, Layout};

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

**Host Side (Dart)**:
```dart
class WasmMemoryBridge {
  final IWasmInstance _instance;
  final PluginSerializer _serializer;

  /// Call plugin function with automatic memory management
  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    // 1. Serialize data
    final dataBytes = _serializer.serialize(data);

    // 2. Allocate in WASM memory
    final allocFn = _instance.getFunction('alloc')!;
    final ptr = await allocFn([dataBytes.length]) as int;

    // 3. Write data to WASM memory
    final memory = _instance.memory!;
    await memory.write(ptr, dataBytes);

    try {
      // 4. Call function
      final fn = _instance.getFunction(functionName)!;
      final packedResult = await fn([ptr, dataBytes.length]) as int;

      // 5. Unpack ptr + len
      final resultPtr = (packedResult >> 32) & 0xFFFFFFFF;
      final resultLen = packedResult & 0xFFFFFFFF;

      // 6. Read result
      final resultBytes = await memory.read(resultPtr, resultLen);

      // 7. Free result memory (plugin allocated)
      final deallocFn = _instance.getFunction('dealloc')!;
      await deallocFn([resultPtr, resultLen]);

      // 8. Deserialize
      return _serializer.deserialize(resultBytes);

    } finally {
      // 9. Free input memory (we allocated)
      final deallocFn = _instance.getFunction('dealloc')!;
      await deallocFn([ptr, dataBytes.length]);
    }
  }
}
```

**Benefits**:
- ✅ No memory leaks (explicit dealloc)
- ✅ Clear ownership (who allocated = who frees)
- ✅ Efficient (minimal copies)

---

## Security & Sandboxing

### Multi-Layer Security Model

```
┌─────────────────────────────────────────────────────────┐
│  Layer 1: WASM Sandbox                                  │
│  - Memory isolation (linear memory only)                │
│  - No direct system access                              │
│  - Cannot access host memory directly                   │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│  Layer 2: Permission System                             │
│  - Host function allowlist                              │
│  - Capability-based security                            │
│  - Plugin manifest declares required permissions        │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│  Layer 3: Runtime Limits                                │
│  - Max execution time (timeout)                         │
│  - Max memory allocation                                │
│  - Max call depth (prevent stack overflow)              │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│  Layer 4: Error Isolation                               │
│  - Try/catch boundaries                                 │
│  - Plugin errors don't crash host                       │
│  - Error tracking & reporting                           │
└─────────────────────────────────────────────────────────┘
```

### Permission System

**Manifest Declaration**:
```yaml
# plugin.yaml
permissions:
  host_functions:
    - get_file_content      # ✅ Allowed
    - open_file             # ✅ Allowed
    # NOT listed = ❌ Denied

  resources:
    max_execution_time: 5s
    max_memory: 50MB
    max_call_depth: 100

  capabilities:
    network: false          # ❌ No network access
    filesystem: read-only   # ✅ Read-only filesystem
```

**Runtime Enforcement**:
```dart
class SecurityGuard {
  final PermissionSystem _permissions;

  /// Check if plugin can call host function
  bool canCallHostFunction(String pluginId, String functionName) {
    final permissions = _permissions.getPermissions(pluginId);
    return permissions.allowedHostFunctions.contains(functionName);
  }

  /// Execute with timeout
  Future<T> executeWithTimeout<T>(
    String pluginId,
    Future<T> Function() fn,
  ) async {
    final permissions = _permissions.getPermissions(pluginId);
    return await fn().timeout(
      permissions.maxExecutionTime,
      onTimeout: () => throw PluginTimeoutException(pluginId),
    );
  }

  /// Check memory limit
  void checkMemoryLimit(String pluginId, int usedBytes) {
    final permissions = _permissions.getPermissions(pluginId);
    if (usedBytes > permissions.maxMemoryBytes) {
      throw PluginMemoryLimitException(pluginId, usedBytes);
    }
  }
}
```

---

## Plugin Lifecycle

### States

```
┌──────────┐
│ UNLOADED │
└────┬─────┘
     │ load()
     ▼
┌──────────┐
│ LOADING  │
└────┬─────┘
     │ loadComplete()
     ▼
┌──────────┐
│  LOADED  │
└────┬─────┘
     │ initialize()
     ▼
┌─────────────┐
│INITIALIZING │
└────┬────────┘
     │ initComplete()
     ▼
┌──────────┐      ┌───────┐
│  READY   │─────>│ ERROR │
└────┬─────┘      └───────┘
     │ dispose()
     ▼
┌──────────┐
│ DISPOSED │
└──────────┘
```

### Lifecycle Hooks

```dart
abstract class IPlugin {
  /// 1. Called when plugin is loaded (before initialization)
  Future<void> onLoad(PluginContext context) async {}

  /// 2. Called to initialize plugin
  Future<void> initialize(PluginContext context);

  /// 3. Called when plugin is ready
  Future<void> onReady() async {}

  /// 4. Called when host wants plugin to handle event
  Future<PluginResponse> handleEvent(PluginEvent event);

  /// 5. Called before plugin is disposed
  Future<void> onBeforeDispose() async {}

  /// 6. Called to dispose plugin
  Future<void> dispose();
}
```

### Manager Implementation

```dart
class PluginLifecycleManager {
  final PluginRegistry _registry;
  final EventDispatcher _events;

  Future<void> loadAndInitialize(
    PluginManifest manifest,
    PluginSource source,
  ) async {
    final pluginId = manifest.id;

    try {
      // 1. LOADING
      _setState(pluginId, PluginState.loading);
      _events.dispatch(PluginLoadingEvent(pluginId));

      // 2. Load plugin through runtime
      final runtime = _selectRuntime(manifest.runtime);
      final plugin = await runtime.loadPlugin(
        pluginId: pluginId,
        source: source,
      );

      // 3. LOADED
      _setState(pluginId, PluginState.loaded);
      _events.dispatch(PluginLoadedEvent(pluginId));

      // 4. INITIALIZING
      _setState(pluginId, PluginState.initializing);
      final context = _createContext(manifest);
      await plugin.initialize(context);

      // 5. READY
      _setState(pluginId, PluginState.ready);
      _registry.register(pluginId, plugin, context);
      _events.dispatch(PluginReadyEvent(pluginId));

    } catch (e, stack) {
      // ERROR
      _setState(pluginId, PluginState.error);
      _events.dispatch(PluginErrorEvent(pluginId, e, stack));
      rethrow;
    }
  }
}
```

---

## Error Handling

### Error Hierarchy

```
PluginException (base)
  ├── PluginLoadException
  │   ├── PluginNotFoundException
  │   ├── InvalidManifestException
  │   └── RuntimeNotAvailableException
  │
  ├── PluginInitializationException
  │   ├── DependencyNotMetException
  │   └── PermissionDeniedException
  │
  ├── PluginExecutionException
  │   ├── PluginTimeoutException
  │   ├── PluginMemoryLimitException
  │   └── HostFunctionException
  │
  └── PluginCommunicationException
      ├── SerializationException
      └── DeserializationException
```

### Error Tracking

```dart
class ErrorTracker {
  final StreamController<PluginError> _errorStream =
      StreamController.broadcast();

  final Map<String, List<PluginError>> _errorHistory = {};
  final int maxErrorsPerPlugin;

  ErrorTracker({this.maxErrorsPerPlugin = 100});

  /// Track error
  void trackError(
    String pluginId,
    Object error,
    StackTrace? stackTrace,
  ) {
    final pluginError = PluginError(
      pluginId: pluginId,
      message: error.toString(),
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );

    // Add to history
    _errorHistory.putIfAbsent(pluginId, () => []);
    final history = _errorHistory[pluginId]!;
    history.add(pluginError);

    // Limit size
    if (history.length > maxErrorsPerPlugin) {
      history.removeAt(0);
    }

    // Dispatch event
    _errorStream.add(pluginError);

    // Log
    print('[Plugin Error] $pluginId: $error');
  }

  /// Get errors for plugin
  List<PluginError> getErrors(String pluginId) {
    return _errorHistory[pluginId] ?? [];
  }

  /// Stream of all errors
  Stream<PluginError> get errors => _errorStream.stream;
}
```

### Error Isolation Pattern

```dart
class ErrorBoundary {
  final ErrorTracker _tracker;

  /// Execute with error isolation
  Future<T> execute<T>(
    String pluginId,
    Future<T> Function() fn, {
    T Function(Object error)? fallback,
  }) async {
    try {
      return await fn();
    } catch (e, stack) {
      // Track error
      _tracker.trackError(pluginId, e, stack);

      // Return fallback or rethrow
      if (fallback != null) {
        return fallback(e);
      } else {
        rethrow;
      }
    }
  }
}
```

---

## Performance

### Optimization Strategies

#### 1. Lazy Loading

```dart
class LazyPluginLoader {
  final Map<String, Future<IPlugin>?> _loadingPlugins = {};

  /// Load plugin only when first needed
  Future<IPlugin> loadWhenNeeded(String pluginId) async {
    // Already loading?
    if (_loadingPlugins.containsKey(pluginId)) {
      return await _loadingPlugins[pluginId]!;
    }

    // Start loading
    final future = _loadPlugin(pluginId);
    _loadingPlugins[pluginId] = future;

    try {
      final plugin = await future;
      _loadingPlugins.remove(pluginId);
      return plugin;
    } catch (e) {
      _loadingPlugins.remove(pluginId);
      rethrow;
    }
  }
}
```

#### 2. Memory Pooling

```dart
class MemoryPool {
  final Queue<Uint8List> _pool = Queue();
  final int maxPoolSize;

  MemoryPool({this.maxPoolSize = 10});

  /// Rent buffer from pool
  Uint8List rent(int size) {
    // Try to reuse from pool
    if (_pool.isNotEmpty) {
      final buffer = _pool.removeFirst();
      if (buffer.length >= size) {
        return Uint8List.view(buffer.buffer, 0, size);
      }
    }

    // Allocate new
    return Uint8List(size);
  }

  /// Return buffer to pool
  void returnBuffer(Uint8List buffer) {
    if (_pool.length < maxPoolSize) {
      _pool.add(buffer);
    }
  }
}
```

#### 3. WASM Compilation Cache

```dart
class WasmCompilationCache {
  final Map<String, CompiledWasmModule> _cache = {};

  Future<CompiledWasmModule> getOrCompile(
    String pluginId,
    Uint8List wasmBytes,
  ) async {
    // Check cache
    if (_cache.containsKey(pluginId)) {
      return _cache[pluginId]!;
    }

    // Compile
    final module = await _compileModule(wasmBytes);

    // Cache
    _cache[pluginId] = module;

    return module;
  }
}
```

#### 4. Batch Event Processing

```dart
class BatchEventProcessor {
  final Duration batchWindow;
  final int maxBatchSize;

  final Map<String, List<PluginEvent>> _pendingEvents = {};
  Timer? _timer;

  /// Queue event for batching
  void queueEvent(String pluginId, PluginEvent event) {
    _pendingEvents.putIfAbsent(pluginId, () => []);
    _pendingEvents[pluginId]!.add(event);

    // Start timer if not running
    _timer ??= Timer(batchWindow, _processBatches);

    // Process immediately if batch is full
    if (_pendingEvents[pluginId]!.length >= maxBatchSize) {
      _processBatch(pluginId);
    }
  }

  Future<void> _processBatch(String pluginId) async {
    final events = _pendingEvents[pluginId] ?? [];
    if (events.isEmpty) return;

    _pendingEvents[pluginId] = [];

    // Send batch to plugin
    await _plugin.handleEventBatch(events);
  }
}
```

---

## API Reference

### Core Interfaces

#### IPlugin

```dart
/// Base plugin interface
abstract class IPlugin {
  /// Plugin manifest
  PluginManifest get manifest;

  /// Initialize plugin
  Future<void> initialize(PluginContext context);

  /// Handle event
  Future<PluginResponse> handleEvent(PluginEvent event);

  /// Dispose plugin
  Future<void> dispose();
}
```

#### IPluginRuntime

```dart
/// Plugin runtime interface
abstract class IPluginRuntime {
  /// Runtime type (wasm, native, script)
  PluginRuntimeType get type;

  /// Load plugin
  Future<IPlugin> loadPlugin({
    required String pluginId,
    required PluginSource source,
    PluginConfig? config,
  });

  /// Unload plugin
  Future<void> unloadPlugin(String pluginId);

  /// Check compatibility
  bool isCompatible(PluginManifest manifest);
}
```

#### IPluginHost

```dart
/// Host interface (capabilities provided to plugins)
abstract class IPluginHost {
  /// Register host function
  void registerHostFunction<T>(String name, HostFunction<T> function);

  /// Call host function
  Future<T> callHostFunction<T>(String name, List<dynamic> args);

  /// Get host capabilities
  HostCapabilities get capabilities;
}
```

### Host Runtime

#### PluginManager

```dart
/// Plugin manager (Facade)
class PluginManager {
  /// Load plugin
  Future<void> loadPlugin({
    required PluginManifest manifest,
    required PluginSource source,
  });

  /// Unload plugin
  Future<void> unloadPlugin(String pluginId);

  /// Send event to plugin
  Future<PluginResponse> sendEvent(PluginEvent event);

  /// Get plugin
  IPlugin? getPlugin(String pluginId);

  /// List all plugins
  List<IPlugin> getAllPlugins();

  /// Check if loaded
  bool isLoaded(String pluginId);
}
```

### WASM Runtime

#### IWasmRuntime

```dart
/// WASM runtime interface
abstract class IWasmRuntime {
  /// Load WASM module
  Future<IWasmModule> loadModule(Uint8List wasmBytes);

  /// Instantiate module
  Future<IWasmInstance> instantiate(
    IWasmModule module,
    Map<String, WasmImport> imports,
  );

  /// Supported features
  WasmFeatures get supportedFeatures;
}
```

---

## Implementation Guidelines

### 1. Module Development

**Checklist**:
- ✅ Follow Clean Architecture (Domain → Application → Infrastructure)
- ✅ All public APIs documented (dartdoc)
- ✅ Unit tests (>80% coverage)
- ✅ Integration tests for cross-module interaction
- ✅ Example code in README.md
- ✅ CHANGELOG.md with semantic versioning
- ✅ LICENSE file (MIT)

### 2. Plugin Development

**Checklist**:
- ✅ Create `plugin.yaml` manifest
- ✅ Implement required WASM exports
- ✅ Handle memory management correctly (alloc/dealloc)
- ✅ Use serialization (JSON or MessagePack)
- ✅ Test with host functions
- ✅ Document required permissions
- ✅ Provide example usage

### 3. Testing Strategy

```
Unit Tests (per module)
  → Integration Tests (module interactions)
    → E2E Tests (full system with real plugins)
      → Performance Tests (benchmarks)
```

### 4. Documentation

**Required docs**:
- `README.md`: Overview, features, installation, quick start
- `ARCHITECTURE.md`: This document
- `API.md`: Detailed API reference
- `PLUGIN_GUIDE.md`: How to create plugins
- `EXAMPLES.md`: Example code and use cases
- `CHANGELOG.md`: Version history

---

## Conclusion

This architecture provides:

✅ **Modularity**: 6 independent packages, publishable on pub.dev
✅ **Extensibility**: Open/Closed - add new runtimes without changing core
✅ **Security**: Multi-layer security with WASM sandbox + permissions
✅ **Performance**: WASM JIT + lazy loading + caching
✅ **Maintainability**: Clean Architecture + DDD + SOLID
✅ **Reusability**: DRY - shared across projects
✅ **Testability**: Dependency Injection + isolated modules

**Next Steps**:
1. Implement `flutter_plugin_system_core`
2. Implement `flutter_plugin_system_host`
3. Implement `flutter_plugin_system_wasm`
4. Implement `flutter_plugin_system_wasm_run`
5. Create example plugin (file_icons)
6. Integrate into IDE
7. Write comprehensive tests
8. Publish to pub.dev

---

**Version History**:
- v1.0.0 (2025-01-10): Initial architecture document
