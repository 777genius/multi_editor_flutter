# VS Code Extension Compatibility Architecture

**Version:** 1.0.0
**Date:** 2025-01-18
**Status:** Design Phase
**Authors:** Architecture Team

---

## 📋 Table of Contents

1. [Executive Summary](#executive-summary)
2. [Strategic Design (DDD)](#strategic-design-ddd)
3. [Clean Architecture Layers](#clean-architecture-layers)
4. [Module Structure](#module-structure)
5. [Domain Model](#domain-model)
6. [Application Layer](#application-layer)
7. [Infrastructure Layer](#infrastructure-layer)
8. [Presentation Layer](#presentation-layer)
9. [Cross-Cutting Concerns](#cross-cutting-concerns)
10. [Deployment Strategy](#deployment-strategy)
11. [Testing Strategy](#testing-strategy)
12. [Migration Path](#migration-path)

---

## 1. Executive Summary

### 1.1 Vision

Создать модульную систему, обеспечивающую **100% совместимость с VS Code расширениями** при сохранении:
- Чистой архитектуры (Clean Architecture)
- Domain-Driven Design принципов
- SOLID принципов
- Минимального размера базового дистрибутива

### 1.2 Key Architectural Decisions

| Decision | Rationale |
|----------|-----------|
| **Clean Architecture** | Независимость от фреймворков, UI, БД |
| **DDD Tactical Patterns** | Богатая domain модель, явное выражение бизнес-логики |
| **Event-Driven Architecture** | Слабая связанность, расширяемость |
| **Hexagonal Ports & Adapters** | Изоляция от внешних зависимостей |
| **CQRS Lite** | Разделение команд и запросов для сложных операций |
| **Download on Demand** | Минимальный размер базовой установки |

### 1.3 Core Principles

```
┌─────────────────────────────────────────────────────────────┐
│                    ARCHITECTURE PRINCIPLES                   │
├─────────────────────────────────────────────────────────────┤
│ 1. Dependency Rule: Dependencies point inward only          │
│ 2. Abstraction over Implementation                          │
│ 3. Single Source of Truth                                   │
│ 4. Fail Fast & Explicit                                     │
│ 5. Immutability by Default                                  │
│ 6. Composition over Inheritance                             │
│ 7. Tell, Don't Ask                                          │
│ 8. Command-Query Separation                                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Strategic Design (DDD)

### 2.1 Bounded Contexts

```
┌───────────────────────────────────────────────────────────────┐
│                      CONTEXT MAP                              │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────────────┐                                 │
│  │  Runtime Management     │ ← Core Domain                   │
│  │  Context                │                                 │
│  │                         │                                 │
│  │  - Installation         │                                 │
│  │  - Verification         │                                 │
│  │  - Lifecycle            │                                 │
│  └──────────┬──────────────┘                                 │
│             │ Upstream/Downstream (U/D)                       │
│             ↓                                                 │
│  ┌─────────────────────────┐      ┌──────────────────────┐  │
│  │  Extension Management   │ ←──→ │  Plugin System       │  │
│  │  Context                │ P/S  │  Context (Existing)  │  │
│  │                         │      │                      │  │
│  │  - Extension Discovery  │      │  - Plugin Loading    │  │
│  │  - Installation         │      │  - Event Dispatch    │  │
│  │  - Activation           │      │  - Host Functions    │  │
│  └──────────┬──────────────┘      └──────────────────────┘  │
│             │ Conformist (C)                                 │
│             ↓                                                 │
│  ┌─────────────────────────┐                                 │
│  │  VS Code Server         │ ← Supporting Subdomain          │
│  │  Context                │                                 │
│  │                         │                                 │
│  │  - Server Process       │                                 │
│  │  - RPC Communication    │                                 │
│  │  - Extension Host       │                                 │
│  └─────────────────────────┘                                 │
│                                                               │
└───────────────────────────────────────────────────────────────┘

Legend:
  U/D = Upstream/Downstream
  P/S = Partnership
  C   = Conformist
```

### 2.2 Context Relationships

#### Runtime Management Context (Core)
- **Ubiquitous Language**: Installation, Module, Verification, Artifact, Platform
- **Responsibility**: Управление lifecycle runtime компонентов
- **Bounded by**: Всё, что касается download/install/verify Node.js + OpenVSCode Server

#### Extension Management Context
- **Ubiquitous Language**: Extension, Activation, Marketplace, Dependency
- **Responsibility**: Управление VS Code расширениями
- **Bounded by**: Всё, что касается .vsix packages, extension lifecycle

#### VS Code Server Context
- **Ubiquitous Language**: Server Process, RPC Channel, Extension Host
- **Responsibility**: Взаимодействие с OpenVSCode Server process
- **Bounded by**: Всё, что касается запуска и коммуникации с сервером

#### Integration with Existing Plugin System
- **Relationship**: Partnership/Shared Kernel
- **Anti-Corruption Layer**: `VSCodeExtensionAdapter` преобразует VS Code API → Plugin System API

---

## 3. Clean Architecture Layers

### 3.1 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                    ┌──────────────────────┐                     │
│                    │   Presentation       │                     │
│                    │   (UI, MobX, Pages)  │                     │
│                    └──────────┬───────────┘                     │
│                               │                                 │
│                    ┌──────────▼───────────┐                     │
│                    │   Application        │                     │
│                    │   (Use Cases, DTO)   │                     │
│                    └──────────┬───────────┘                     │
│                               │                                 │
│         ┌─────────────────────┼─────────────────────┐           │
│         │                     │                     │           │
│  ┌──────▼──────┐    ┌────────▼────────┐    ┌──────▼──────┐    │
│  │   Domain    │    │   Domain        │    │   Domain    │    │
│  │   (Runtime) │    │   (Extension)   │    │   (Server)  │    │
│  │             │    │                 │    │             │    │
│  │  Entities   │    │  Entities       │    │  Entities   │    │
│  │  VOs        │    │  VOs            │    │  VOs        │    │
│  │  Aggregates │    │  Aggregates     │    │  Aggregates │    │
│  │  Events     │    │  Events         │    │  Events     │    │
│  └──────┬──────┘    └────────┬────────┘    └──────┬──────┘    │
│         │                    │                    │           │
│         └─────────────────────┼─────────────────────┘           │
│                               │                                 │
│                    ┌──────────▼───────────┐                     │
│                    │   Infrastructure     │                     │
│                    │   (Repos, Services)  │                     │
│                    └──────────────────────┘                     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

Dependency Flow: Outward → Inward (Always toward Domain)
```

### 3.2 Layer Responsibilities

#### Domain Layer (Innermost)
- **Zero Dependencies** on external frameworks
- **Pure Business Logic**
- **Entities, Value Objects, Aggregates**
- **Domain Events**
- **Domain Services** (stateless business operations)
- **Specifications** (business rules as objects)

#### Application Layer
- **Use Cases** (application-specific business rules)
- **Application Services** (orchestration)
- **DTO** (data transfer between layers)
- **Ports** (interfaces for infrastructure)
- **Command/Query Handlers** (CQRS lite)

#### Infrastructure Layer
- **Adapters** (implementations of ports)
- **Repositories** (data persistence)
- **External Services** (HTTP, File System)
- **Mappers** (DTO ↔ Domain)
- **Third-party Integrations**

#### Presentation Layer
- **UI Components** (Flutter Widgets)
- **State Management** (MobX)
- **Stores** (reactive state management)
- **Dependency Injection** (composition root)

---

## 4. Module Structure

### 4.1 Package Organization

```
multi_editor_flutter/
├── packages/
│   │
│   ├── vscode_runtime_core/                    # Domain Layer
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   │   ├── domain/
│   │   │   │   │   ├── entities/
│   │   │   │   │   │   ├── runtime_module.dart
│   │   │   │   │   │   ├── platform_artifact.dart
│   │   │   │   │   │   └── installation_session.dart
│   │   │   │   │   ├── value_objects/
│   │   │   │   │   │   ├── runtime_version.dart
│   │   │   │   │   │   ├── module_id.dart
│   │   │   │   │   │   ├── download_url.dart
│   │   │   │   │   │   ├── sha256_hash.dart
│   │   │   │   │   │   ├── byte_size.dart
│   │   │   │   │   │   └── platform_identifier.dart
│   │   │   │   │   ├── aggregates/
│   │   │   │   │   │   └── runtime_installation.dart
│   │   │   │   │   ├── events/
│   │   │   │   │   │   ├── domain_event.dart
│   │   │   │   │   │   ├── installation_started.dart
│   │   │   │   │   │   ├── module_downloaded.dart
│   │   │   │   │   │   ├── module_verified.dart
│   │   │   │   │   │   ├── module_extracted.dart
│   │   │   │   │   │   ├── installation_completed.dart
│   │   │   │   │   │   └── installation_failed.dart
│   │   │   │   │   ├── specifications/
│   │   │   │   │   │   ├── specification.dart
│   │   │   │   │   │   ├── platform_compatible_spec.dart
│   │   │   │   │   │   └── dependencies_met_spec.dart
│   │   │   │   │   ├── services/
│   │   │   │   │   │   └── i_dependency_resolver.dart
│   │   │   │   │   └── exceptions/
│   │   │   │   │       ├── domain_exception.dart
│   │   │   │   │       ├── installation_exception.dart
│   │   │   │   │       └── verification_exception.dart
│   │   │   │   └── ports/
│   │   │   │       ├── repositories/
│   │   │   │       │   ├── i_runtime_repository.dart
│   │   │   │       │   └── i_manifest_repository.dart
│   │   │   │       ├── services/
│   │   │   │       │   ├── i_download_service.dart
│   │   │   │       │   ├── i_extraction_service.dart
│   │   │   │       │   ├── i_verification_service.dart
│   │   │   │       │   ├── i_file_system_service.dart
│   │   │   │       │   └── i_platform_service.dart
│   │   │   │       └── events/
│   │   │   │           └── i_event_bus.dart
│   │   │   └── vscode_runtime_core.dart
│   │   └── pubspec.yaml
│   │       dependencies:
│   │         - freezed_annotation
│   │         - dartz
│   │         - equatable
│   │
│   ├── vscode_runtime_application/             # Application Layer
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   │   ├── use_cases/
│   │   │   │   │   ├── commands/              # CQRS Commands
│   │   │   │   │   │   ├── install_runtime_command.dart
│   │   │   │   │   │   ├── uninstall_runtime_command.dart
│   │   │   │   │   │   └── update_runtime_command.dart
│   │   │   │   │   ├── queries/               # CQRS Queries
│   │   │   │   │   │   ├── get_runtime_status_query.dart
│   │   │   │   │   │   ├── get_available_modules_query.dart
│   │   │   │   │   │   └── get_installation_history_query.dart
│   │   │   │   │   └── handlers/
│   │   │   │   │       ├── install_runtime_handler.dart
│   │   │   │   │       ├── get_runtime_status_handler.dart
│   │   │   │   │       └── handler_base.dart
│   │   │   │   ├── services/
│   │   │   │   │   ├── installation_orchestrator.dart
│   │   │   │   │   ├── dependency_resolver_service.dart
│   │   │   │   │   └── progress_tracker_service.dart
│   │   │   │   ├── dto/
│   │   │   │   │   ├── runtime_status_dto.dart
│   │   │   │   │   ├── installation_progress_dto.dart
│   │   │   │   │   └── module_info_dto.dart
│   │   │   │   └── events/
│   │   │   │       └── application_event.dart
│   │   │   └── vscode_runtime_application.dart
│   │   └── pubspec.yaml
│   │       dependencies:
│   │         - vscode_runtime_core
│   │         - injectable
│   │
│   ├── vscode_runtime_infrastructure/          # Infrastructure Layer
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   │   ├── repositories/
│   │   │   │   │   ├── runtime_repository_impl.dart
│   │   │   │   │   └── manifest_repository_impl.dart
│   │   │   │   ├── services/
│   │   │   │   │   ├── download_service_impl.dart
│   │   │   │   │   ├── extraction_service_impl.dart
│   │   │   │   │   ├── verification_service_impl.dart
│   │   │   │   │   ├── file_system_service_impl.dart
│   │   │   │   │   └── platform_service_impl.dart
│   │   │   │   ├── data_sources/
│   │   │   │   │   ├── local/
│   │   │   │   │   │   ├── runtime_local_data_source.dart
│   │   │   │   │   │   └── file_system_data_source.dart
│   │   │   │   │   └── remote/
│   │   │   │   │       ├── manifest_remote_data_source.dart
│   │   │   │   │       └── cdn_client.dart
│   │   │   │   ├── mappers/
│   │   │   │   │   ├── runtime_module_mapper.dart
│   │   │   │   │   └── manifest_mapper.dart
│   │   │   │   ├── events/
│   │   │   │   │   └── event_bus_impl.dart
│   │   │   │   └── models/
│   │   │   │       ├── manifest_dto.dart
│   │   │   │       └── installation_record_dto.dart
│   │   │   └── vscode_runtime_infrastructure.dart
│   │   └── pubspec.yaml
│   │       dependencies:
│   │         - vscode_runtime_core
│   │         - vscode_runtime_application
│   │         - dio
│   │         - archive
│   │         - crypto
│   │         - path
│   │
│   ├── vscode_runtime_presentation/            # Presentation Layer
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   │   ├── stores/
│   │   │   │   │   ├── runtime_installation_store.dart
│   │   │   │   │   ├── runtime_status_store.dart
│   │   │   │   │   └── module_list_store.dart
│   │   │   │   ├── widgets/
│   │   │   │   │   ├── runtime_installation_dialog.dart
│   │   │   │   │   ├── installation_progress_widget.dart
│   │   │   │   │   ├── module_list_widget.dart
│   │   │   │   │   ├── runtime_status_widget.dart
│   │   │   │   │   └── platform_info_widget.dart
│   │   │   │   └── di/
│   │   │   │       └── injection.dart
│   │   │   └── vscode_runtime_presentation.dart
│   │   └── pubspec.yaml
│   │       dependencies:
│   │         - vscode_runtime_application
│   │         - mobx
│   │         - flutter_mobx
│   │
│   └── vscode_extension_core/                  # Extension Management Context
│       └── [similar structure]
│
└── modules/
    └── vscode_compatibility/                   # Facade Module
        ├── lib/
        │   ├── src/
        │   │   ├── di/
        │   │   │   ├── injection.dart
        │   │   │   ├── injection.config.dart
        │   │   │   └── modules/
        │   │   │       ├── core_module.dart
        │   │   │       ├── infrastructure_module.dart
        │   │   │       └── external_module.dart
        │   │   └── vscode_compatibility_facade.dart
        │   └── vscode_compatibility.dart
        └── pubspec.yaml
            dependencies:
              - vscode_runtime_core
              - vscode_runtime_application
              - vscode_runtime_infrastructure
              - vscode_runtime_presentation
              - vscode_extension_core
              - get_it
              - injectable
```

### 4.2 Dependency Rules

```yaml
# Allowed Dependencies

Domain Layer (Core):
  - freezed_annotation
  - dartz
  - equatable
  ❌ NO other dependencies

Application Layer:
  - vscode_runtime_core ✅
  - injectable
  ❌ NO infrastructure
  ❌ NO presentation

Infrastructure Layer:
  - vscode_runtime_core ✅
  - vscode_runtime_application ✅
  - dio, archive, crypto, path (external)

Presentation Layer:
  - vscode_runtime_application ✅
  - mobx + flutter_mobx
  ❌ NO infrastructure
  ❌ NO core (only through application)

Facade Module:
  - ALL packages ✅ (composition root)
```

---

## 5. Domain Model

### 5.1 Core Entities

#### RuntimeModule (Entity)

```dart
/// Entity: Runtime Module
/// Identity: ModuleId
/// Invariants:
///   - Must have at least one platform artifact
///   - Version must be valid
///   - Dependencies must form acyclic graph
@freezed
class RuntimeModule with _$RuntimeModule {
  const RuntimeModule._();

  const factory RuntimeModule({
    required ModuleId id,
    required String name,
    required ModuleType type,
    required RuntimeVersion version,
    required ImmutableMap<PlatformIdentifier, PlatformArtifact> platformArtifacts,
    @Default(ImmutableList.empty()) ImmutableList<ModuleId> dependencies,
    @Default(false) bool isOptional,
  }) = _RuntimeModule;

  /// Factory with validation
  factory RuntimeModule.create({
    required ModuleId id,
    required String name,
    required ModuleType type,
    required RuntimeVersion version,
    required Map<PlatformIdentifier, PlatformArtifact> platformArtifacts,
    List<ModuleId>? dependencies,
    bool isOptional = false,
  }) {
    // Validate invariants
    if (platformArtifacts.isEmpty) {
      throw DomainException('Module must have at least one platform artifact');
    }

    return RuntimeModule(
      id: id,
      name: name,
      type: type,
      version: version,
      platformArtifacts: ImmutableMap(platformArtifacts),
      dependencies: ImmutableList(dependencies ?? []),
      isOptional: isOptional,
    );
  }

  /// Business Logic: Get artifact for platform
  Option<PlatformArtifact> artifactFor(PlatformIdentifier platform) {
    return optionOf(platformArtifacts[platform]);
  }

  /// Business Logic: Check if has circular dependencies
  bool hasCircularDependency(Set<ModuleId> visited) {
    if (visited.contains(id)) return true;
    // ... implementation
    return false;
  }
}
```

#### Value Objects

```dart
/// Value Object: ModuleId
/// Self-validating, immutable
@freezed
class ModuleId with _$ModuleId {
  const ModuleId._();

  const factory ModuleId(String value) = _ModuleId;

  factory ModuleId.fromString(String value) {
    // Validation
    if (value.isEmpty) {
      throw FormatException('ModuleId cannot be empty');
    }
    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(value)) {
      throw FormatException('ModuleId must be lowercase alphanumeric with dashes');
    }
    return ModuleId(value);
  }

  /// Well-known module IDs
  static final nodejs = ModuleId('nodejs');
  static final openVSCodeServer = ModuleId('openvscode-server');
  static final baseExtensions = ModuleId('base-extensions');
}

/// Value Object: SHA256Hash
/// Cryptographic hash with validation
@freezed
class SHA256Hash with _$SHA256Hash {
  const SHA256Hash._();

  const factory SHA256Hash(String value) = _SHA256Hash;

  factory SHA256Hash.fromString(String hash) {
    if (hash.length != 64) {
      throw FormatException('SHA256 hash must be 64 characters');
    }
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(hash)) {
      throw FormatException('Invalid SHA256 hash format');
    }
    return SHA256Hash(hash);
  }

  /// Verify against bytes
  bool verify(List<int> bytes) {
    final computed = sha256.convert(bytes).toString();
    return computed == value;
  }
}
```

### 5.2 Aggregate Root

```dart
/// Aggregate Root: RuntimeInstallation
/// Manages installation consistency and lifecycle
/// Domain Events: tracks all state changes
@freezed
class RuntimeInstallation with _$RuntimeInstallation {
  const RuntimeInstallation._();

  const factory RuntimeInstallation({
    required InstallationId id,
    required ImmutableList<RuntimeModule> modules,
    required PlatformIdentifier targetPlatform,
    required InstallationStatus status,
    required DateTime createdAt,
    @Default(ImmutableList.empty()) ImmutableList<ModuleId> installedModules,
    @Default(ImmutableList.empty()) ImmutableList<DomainEvent> uncommittedEvents,
    Option<ModuleId>? currentModule,
    @Default(0.0) double progress,
    Option<String>? errorMessage,
  }) = _RuntimeInstallation;

  /// Factory: Create new installation
  factory RuntimeInstallation.create({
    required List<RuntimeModule> modules,
    required PlatformIdentifier platform,
  }) {
    final id = InstallationId.generate();
    final now = DateTime.now();

    // Validate all modules are compatible with platform
    final incompatible = modules.where(
      (m) => !m.platformArtifacts.containsKey(platform),
    );

    if (incompatible.isNotEmpty) {
      throw DomainException(
        'Modules not compatible with platform $platform: '
        '${incompatible.map((m) => m.id).join(', ')}'
      );
    }

    // Validate dependency graph
    _validateDependencies(modules);

    return RuntimeInstallation(
      id: id,
      modules: ImmutableList(modules),
      targetPlatform: platform,
      status: InstallationStatus.pending,
      createdAt: now,
      uncommittedEvents: ImmutableList([
        InstallationStarted(
          installationId: id,
          moduleCount: modules.length,
          timestamp: now,
        ),
      ]),
    );
  }

  /// Command: Start installation
  RuntimeInstallation start() {
    if (status != InstallationStatus.pending) {
      throw InvalidStateException(
        'Cannot start installation in state: $status',
      );
    }

    return copyWith(
      status: InstallationStatus.inProgress,
      uncommittedEvents: uncommittedEvents.add(
        InstallationProgressChanged(
          installationId: id,
          status: InstallationStatus.inProgress,
          timestamp: DateTime.now(),
        ),
      ),
    );
  }

  /// Command: Mark module as downloaded
  RuntimeInstallation markModuleDownloaded(ModuleId moduleId) {
    _validateModuleExists(moduleId);
    _validateModuleNotInstalled(moduleId);

    return copyWith(
      currentModule: some(moduleId),
      uncommittedEvents: uncommittedEvents.add(
        ModuleDownloaded(
          installationId: id,
          moduleId: moduleId,
          timestamp: DateTime.now(),
        ),
      ),
    );
  }

  /// Command: Mark module as verified
  RuntimeInstallation markModuleVerified(ModuleId moduleId) {
    _validateModuleExists(moduleId);

    return copyWith(
      uncommittedEvents: uncommittedEvents.add(
        ModuleVerified(
          installationId: id,
          moduleId: moduleId,
          timestamp: DateTime.now(),
        ),
      ),
    );
  }

  /// Command: Mark module as extracted/installed
  RuntimeInstallation markModuleInstalled(ModuleId moduleId) {
    _validateModuleExists(moduleId);
    _validateModuleNotInstalled(moduleId);

    final newInstalledModules = installedModules.add(moduleId);
    final isComplete = newInstalledModules.length == modules.length;
    final newStatus = isComplete
        ? InstallationStatus.completed
        : InstallationStatus.inProgress;

    final newProgress = modules.isEmpty
        ? 1.0
        : newInstalledModules.length / modules.length;

    final events = [
      ModuleExtracted(
        installationId: id,
        moduleId: moduleId,
        timestamp: DateTime.now(),
      ),
    ];

    if (isComplete) {
      events.add(
        InstallationCompleted(
          installationId: id,
          timestamp: DateTime.now(),
        ),
      );
    }

    return copyWith(
      installedModules: newInstalledModules,
      status: newStatus,
      progress: newProgress,
      currentModule: none(),
      uncommittedEvents: uncommittedEvents.addAll(events),
    );
  }

  /// Command: Fail installation
  RuntimeInstallation fail(String error) {
    return copyWith(
      status: InstallationStatus.failed,
      errorMessage: some(error),
      uncommittedEvents: uncommittedEvents.add(
        InstallationFailed(
          installationId: id,
          error: error,
          timestamp: DateTime.now(),
        ),
      ),
    );
  }

  /// Query: Get next module to install
  Option<RuntimeModule> getNextModuleToInstall() {
    final notInstalled = modules.where(
      (m) => !installedModules.contains(m.id),
    );

    if (notInstalled.isEmpty) return none();

    // Find module whose dependencies are all installed
    for (final module in notInstalled) {
      if (_areDependenciesMet(module)) {
        return some(module);
      }
    }

    // Should never happen if dependency graph is valid
    throw DomainException('Circular dependency detected');
  }

  /// Query: Check if dependencies are met
  bool _areDependenciesMet(RuntimeModule module) {
    return module.dependencies.every(
      (dep) => installedModules.contains(dep),
    );
  }

  /// Clear uncommitted events (after publishing)
  RuntimeInstallation clearEvents() {
    return copyWith(uncommittedEvents: ImmutableList.empty());
  }

  // Validation helpers
  void _validateModuleExists(ModuleId moduleId) {
    if (!modules.any((m) => m.id == moduleId)) {
      throw DomainException('Module not found: $moduleId');
    }
  }

  void _validateModuleNotInstalled(ModuleId moduleId) {
    if (installedModules.contains(moduleId)) {
      throw DomainException('Module already installed: $moduleId');
    }
  }

  static void _validateDependencies(List<RuntimeModule> modules) {
    // Check for circular dependencies
    final visited = <ModuleId>{};
    for (final module in modules) {
      if (module.hasCircularDependency(visited)) {
        throw DomainException('Circular dependency detected');
      }
    }
  }
}
```

### 5.3 Specifications Pattern

```dart
/// Specification: Platform Compatibility
/// Encapsulates business rule as object
class PlatformCompatibleSpecification extends Specification<RuntimeModule> {
  final PlatformIdentifier platform;

  PlatformCompatibleSpecification(this.platform);

  @override
  bool isSatisfiedBy(RuntimeModule candidate) {
    return candidate.platformArtifacts.containsKey(platform);
  }

  @override
  String get description => 'Module must support platform: $platform';
}

/// Specification: Dependencies Met
class DependenciesMetSpecification extends Specification<RuntimeModule> {
  final Set<ModuleId> installedModules;

  DependenciesMetSpecification(this.installedModules);

  @override
  bool isSatisfiedBy(RuntimeModule candidate) {
    return candidate.dependencies.every(
      (dep) => installedModules.contains(dep),
    );
  }

  @override
  String get description => 'All dependencies must be installed';
}

/// Composite Specification: Can Install Module
class CanInstallModuleSpecification extends CompositeSpecification<RuntimeModule> {
  CanInstallModuleSpecification({
    required PlatformIdentifier platform,
    required Set<ModuleId> installedModules,
  }) : super(
    [
      PlatformCompatibleSpecification(platform),
      DependenciesMetSpecification(installedModules),
    ],
  );
}
```

### 5.4 Domain Services

```dart
/// Domain Service: Dependency Resolution
/// Stateless operation that doesn't belong to any entity
abstract class IDependencyResolver {
  /// Resolve installation order based on dependencies
  Either<DomainException, ImmutableList<RuntimeModule>> resolveOrder(
    ImmutableList<RuntimeModule> modules,
  );

  /// Detect circular dependencies
  bool hasCircularDependencies(ImmutableList<RuntimeModule> modules);

  /// Get all transitive dependencies
  ImmutableList<ModuleId> getTransitiveDependencies(
    RuntimeModule module,
    Map<ModuleId, RuntimeModule> moduleMap,
  );
}

/// Implementation
@LazySingleton(as: IDependencyResolver)
class DependencyResolver implements IDependencyResolver {
  @override
  Either<DomainException, ImmutableList<RuntimeModule>> resolveOrder(
    ImmutableList<RuntimeModule> modules,
  ) {
    try {
      // Topological sort
      final sorted = <RuntimeModule>[];
      final visited = <ModuleId>{};
      final visiting = <ModuleId>{};
      final moduleMap = {for (var m in modules) m.id: m};

      for (final module in modules) {
        if (!_visit(module, moduleMap, visited, visiting, sorted)) {
          return left(DomainException('Circular dependency detected'));
        }
      }

      return right(ImmutableList(sorted));

    } catch (e) {
      return left(DomainException('Dependency resolution failed: $e'));
    }
  }

  bool _visit(
    RuntimeModule module,
    Map<ModuleId, RuntimeModule> moduleMap,
    Set<ModuleId> visited,
    Set<ModuleId> visiting,
    List<RuntimeModule> sorted,
  ) {
    if (visited.contains(module.id)) return true;
    if (visiting.contains(module.id)) return false; // Cycle!

    visiting.add(module.id);

    for (final depId in module.dependencies) {
      final dep = moduleMap[depId];
      if (dep != null) {
        if (!_visit(dep, moduleMap, visited, visiting, sorted)) {
          return false;
        }
      }
    }

    visiting.remove(module.id);
    visited.add(module.id);
    sorted.add(module);

    return true;
  }

  // ... other methods
}
```

---

## 6. Application Layer

### 6.1 CQRS Lite Pattern

```dart
/// Base Command
abstract class Command<TResult> {
  const Command();
}

/// Base Query
abstract class Query<TResult> {
  const Query();
}

/// Base Handler
abstract class CommandHandler<TCommand extends Command<TResult>, TResult> {
  Future<Either<ApplicationException, TResult>> handle(TCommand command);
}

abstract class QueryHandler<TQuery extends Query<TResult>, TResult> {
  Future<Either<ApplicationException, TResult>> handle(TQuery query);
}
```

### 6.2 Commands

```dart
/// Command: Install Runtime
@freezed
class InstallRuntimeCommand extends Command<Unit> with _$InstallRuntimeCommand {
  const factory InstallRuntimeCommand({
    required List<ModuleId> moduleIds,
    void Function(ModuleId, double)? onProgress,
  }) = _InstallRuntimeCommand;
}

/// Handler: Install Runtime
@injectable
class InstallRuntimeCommandHandler
    implements CommandHandler<InstallRuntimeCommand, Unit> {

  final IRuntimeRepository _runtimeRepository;
  final IManifestRepository _manifestRepository;
  final IDownloadService _downloadService;
  final IExtractionService _extractionService;
  final IVerificationService _verificationService;
  final IPlatformService _platformService;
  final IEventBus _eventBus;
  final IDependencyResolver _dependencyResolver;

  InstallRuntimeCommandHandler(
    this._runtimeRepository,
    this._manifestRepository,
    this._downloadService,
    this._extractionService,
    this._verificationService,
    this._platformService,
    this._eventBus,
    this._dependencyResolver,
  );

  @override
  Future<Either<ApplicationException, Unit>> handle(
    InstallRuntimeCommand command,
  ) async {
    try {
      // 1. Get platform
      final platformResult = await _platformService.getCurrentPlatform();
      final platform = platformResult.getOrElse(
        () => throw ApplicationException('Could not determine platform'),
      );

      // 2. Load available modules
      final modulesResult = await _manifestRepository.getModules();
      final allModules = modulesResult.getOrElse(
        () => throw ApplicationException('Could not load module manifest'),
      );

      // 3. Filter requested modules
      final requestedModules = allModules.where(
        (m) => command.moduleIds.contains(m.id),
      ).toList();

      if (requestedModules.length != command.moduleIds.length) {
        return left(ApplicationException('Some modules not found'));
      }

      // 4. Resolve dependencies
      final resolvedResult = _dependencyResolver.resolveOrder(
        ImmutableList(requestedModules),
      );

      final sortedModules = resolvedResult.getOrElse(
        () => throw ApplicationException('Dependency resolution failed'),
      );

      // 5. Create installation aggregate
      final installation = RuntimeInstallation.create(
        modules: sortedModules.toList(),
        platform: platform,
      );

      // 6. Start installation
      var currentInstallation = installation.start();

      // Publish events
      await _publishEvents(currentInstallation);
      currentInstallation = currentInstallation.clearEvents();

      // Save state
      await _runtimeRepository.saveInstallation(currentInstallation);

      // 7. Install each module
      while (true) {
        final nextModuleOption = currentInstallation.getNextModuleToInstall();

        if (nextModuleOption.isNone()) break; // All installed

        final module = nextModuleOption.getOrElse(() => throw Exception());

        // Install module
        final result = await _installModule(
          installation: currentInstallation,
          module: module,
          platform: platform,
          onProgress: command.onProgress,
        );

        currentInstallation = result.fold(
          (error) => currentInstallation.fail(error.message),
          (installation) => installation,
        );

        // Publish events
        await _publishEvents(currentInstallation);
        currentInstallation = currentInstallation.clearEvents();

        // Save state
        await _runtimeRepository.saveInstallation(currentInstallation);

        // Check for failure
        if (currentInstallation.status == InstallationStatus.failed) {
          return left(ApplicationException(
            currentInstallation.errorMessage.getOrElse(() => 'Unknown error'),
          ));
        }
      }

      return right(unit);

    } on DomainException catch (e) {
      return left(ApplicationException(e.message));
    } on Exception catch (e) {
      return left(ApplicationException('Unexpected error: $e'));
    }
  }

  Future<Either<ApplicationException, RuntimeInstallation>> _installModule({
    required RuntimeInstallation installation,
    required RuntimeModule module,
    required PlatformIdentifier platform,
    void Function(ModuleId, double)? onProgress,
  }) async {
    var current = installation;

    try {
      // Get artifact
      final artifactOption = module.artifactFor(platform);
      if (artifactOption.isNone()) {
        return left(ApplicationException(
          'No artifact for platform: $platform',
        ));
      }
      final artifact = artifactOption.getOrElse(() => throw Exception());

      // Download
      current = current.markModuleDownloaded(module.id);

      final downloadResult = await _downloadService.download(
        url: artifact.url,
        expectedSize: artifact.size,
        onProgress: (received, total) {
          final progress = received.progressTo(total);
          onProgress?.call(module.id, progress * 0.7); // 70% for download
        },
      );

      final file = downloadResult.getOrElse(
        () => throw ApplicationException('Download failed'),
      );

      // Verify
      current = current.markModuleVerified(module.id);

      final verifyResult = await _verificationService.verify(
        file: file,
        expectedHash: artifact.hash,
      );

      if (verifyResult.isLeft()) {
        return left(ApplicationException('Verification failed'));
      }

      onProgress?.call(module.id, 0.8); // 80% after verify

      // Extract
      final extractResult = await _extractionService.extract(
        archiveFile: file,
        targetDirectory: module.id.value,
        onProgress: (p) {
          onProgress?.call(module.id, 0.8 + p * 0.2); // 20% for extraction
        },
      );

      if (extractResult.isLeft()) {
        return left(ApplicationException('Extraction failed'));
      }

      // Mark as installed
      current = current.markModuleInstalled(module.id);

      onProgress?.call(module.id, 1.0);

      return right(current);

    } on Exception catch (e) {
      return left(ApplicationException('Module installation failed: $e'));
    }
  }

  Future<void> _publishEvents(RuntimeInstallation installation) async {
    for (final event in installation.uncommittedEvents) {
      await _eventBus.publish(event);
    }
  }
}
```

### 6.3 Queries

```dart
/// Query: Get Runtime Status
@freezed
class GetRuntimeStatusQuery
    extends Query<RuntimeStatusDto>
    with _$GetRuntimeStatusQuery {
  const factory GetRuntimeStatusQuery() = _GetRuntimeStatusQuery;
}

/// Handler: Get Runtime Status
@injectable
class GetRuntimeStatusQueryHandler
    implements QueryHandler<GetRuntimeStatusQuery, RuntimeStatusDto> {

  final IRuntimeRepository _repository;

  GetRuntimeStatusQueryHandler(this._repository);

  @override
  Future<Either<ApplicationException, RuntimeStatusDto>> handle(
    GetRuntimeStatusQuery query,
  ) async {
    try {
      // Check installed version
      final versionResult = await _repository.getInstalledVersion();
      final version = versionResult.getOrElse(() => null);

      if (version == null) {
        return right(RuntimeStatusDto.notInstalled());
      }

      // Check all modules present
      final modulesResult = await _repository.getAvailableModules();
      final modules = modulesResult.getOrElse(() => []);

      final missingModules = <ModuleId>[];

      for (final module in modules) {
        final isInstalledResult = await _repository.isModuleInstalled(
          module.id,
        );
        final isInstalled = isInstalledResult.getOrElse(() => false);

        if (!isInstalled) {
          missingModules.add(module.id);
        }
      }

      if (missingModules.isEmpty) {
        return right(RuntimeStatusDto.installed(version: version));
      } else {
        return right(RuntimeStatusDto.partiallyInstalled(
          version: version,
          missingModules: missingModules,
        ));
      }

    } on Exception catch (e) {
      return left(ApplicationException('Status check failed: $e'));
    }
  }
}
```

---

## 7. Infrastructure Layer

### 7.1 Repository Pattern

```dart
/// Repository Implementation
@LazySingleton(as: IRuntimeRepository)
class RuntimeRepositoryImpl implements IRuntimeRepository {
  final IRuntimeLocalDataSource _localDataSource;
  final IFileSystemService _fileSystem;

  RuntimeRepositoryImpl(
    this._localDataSource,
    this._fileSystem,
  );

  @override
  Future<Either<DomainException, Option<RuntimeVersion>>> getInstalledVersion() async {
    try {
      final versionFile = await _localDataSource.getVersionFile();

      if (!await versionFile.exists()) {
        return right(none());
      }

      final versionString = await versionFile.readAsString();
      final version = RuntimeVersion.fromString(versionString.trim());

      return right(some(version));

    } on FormatException catch (e) {
      return left(DomainException('Invalid version format: $e'));
    } on Exception catch (e) {
      return left(DomainException('Could not read version: $e'));
    }
  }

  @override
  Future<Either<DomainException, Unit>> saveInstallation(
    RuntimeInstallation installation,
  ) async {
    try {
      final installationFile = await _localDataSource.getInstallationFile(
        installation.id,
      );

      // Map to DTO
      final dto = InstallationRecordDto.fromDomain(installation);

      // Serialize
      final json = dto.toJson();
      await installationFile.writeAsString(jsonEncode(json));

      return right(unit);

    } on Exception catch (e) {
      return left(DomainException('Could not save installation: $e'));
    }
  }

  @override
  Future<Either<DomainException, bool>> isModuleInstalled(
    ModuleId moduleId,
  ) async {
    try {
      final moduleDir = await _fileSystem.getModuleDirectory(moduleId);
      return right(await moduleDir.exists());

    } on Exception catch (e) {
      return left(DomainException('Could not check module: $e'));
    }
  }

  // ... other methods
}
```

### 7.2 Service Implementations

```dart
/// Download Service with Retry Logic
@LazySingleton(as: IDownloadService)
class DownloadServiceImpl implements IDownloadService {
  final Dio _dio;
  final IFileSystemService _fileSystem;
  final int _maxRetries;

  DownloadServiceImpl(
    this._dio,
    this._fileSystem, {
    int maxRetries = 3,
  }) : _maxRetries = maxRetries;

  @override
  Future<Either<DomainException, File>> download({
    required DownloadUrl url,
    required ByteSize expectedSize,
    void Function(ByteSize, ByteSize)? onProgress,
    CancelToken? cancelToken,
  }) async {
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        return await _attemptDownload(
          url: url,
          expectedSize: expectedSize,
          onProgress: onProgress,
          cancelToken: cancelToken,
        );
      } on DioException catch (e) {
        if (attempt == _maxRetries - 1) {
          return left(DomainException('Download failed after $attempt retries: ${e.message}'));
        }

        // Exponential backoff
        await Future.delayed(Duration(seconds: math.pow(2, attempt).toInt()));
      }
    }

    return left(DomainException('Download failed'));
  }

  Future<Either<DomainException, File>> _attemptDownload({
    required DownloadUrl url,
    required ByteSize expectedSize,
    void Function(ByteSize, ByteSize)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final downloadDir = await _fileSystem.getDownloadDirectory();
      final fileName = _extractFileName(url);
      final targetPath = '${downloadDir.path}/$fileName';

      await _dio.download(
        url.value,
        targetPath,
        onReceiveProgress: (received, total) {
          onProgress?.call(
            ByteSize(received),
            ByteSize(total > 0 ? total : expectedSize.bytes),
          );
        },
        cancelToken: cancelToken,
      );

      final file = File(targetPath);
      final actualSize = await file.length();

      if (actualSize != expectedSize.bytes) {
        await file.delete();
        return left(DomainException(
          'Size mismatch: expected ${expectedSize.formatted}, '
          'got ${ByteSize(actualSize).formatted}',
        ));
      }

      return right(file);

    } on DioException {
      rethrow;
    } on Exception catch (e) {
      return left(DomainException('Download error: $e'));
    }
  }

  String _extractFileName(DownloadUrl url) {
    final uri = Uri.parse(url.value);
    return uri.pathSegments.last;
  }
}
```

---

## 8. Presentation Layer

### 8.1 MobX Pattern

```dart
/// Store for Runtime Installation
@injectable
class RuntimeInstallationStore = _RuntimeInstallationStore with _$RuntimeInstallationStore;

abstract class _RuntimeInstallationStore with Store {
  final InstallRuntimeCommandHandler _installHandler;
  final CancelInstallationCommandHandler _cancelHandler;
  final GetInstallationProgressQueryHandler _progressHandler;

  _RuntimeInstallationStore(
    this._installHandler,
    this._cancelHandler,
    this._progressHandler,
  );

  // Observables
  @observable
  InstallationId? currentInstallationId;

  @observable
  InstallationStatus status = InstallationStatus.pending;

  @observable
  double overallProgress = 0.0;

  @observable
  ModuleId? currentModule;

  @observable
  double currentModuleProgress = 0.0;

  @observable
  String? errorMessage;

  @observable
  int installedModuleCount = 0;

  @observable
  int totalModuleCount = 0;

  // Computed Values
  @computed
  bool get isInstalling => status == InstallationStatus.inProgress;

  @computed
  bool get isCompleted => status == InstallationStatus.completed;

  @computed
  bool get hasFailed => status == InstallationStatus.failed;

  @computed
  bool get canCancel => isInstalling && currentInstallationId != null;

  @computed
  String get progressText {
    if (totalModuleCount == 0) return 'Preparing...';
    return '$installedModuleCount / $totalModuleCount modules';
  }

  @computed
  String get statusMessage {
    return status.map(
      pending: (_) => 'Ready to install',
      inProgress: (_) => 'Installing ${currentModule?.value ?? ""}...',
      completed: (_) => 'Installation completed successfully',
      failed: (_) => 'Installation failed: ${errorMessage ?? "Unknown error"}',
      cancelled: (_) => 'Installation cancelled',
    );
  }

  // Actions
  @action
  Future<void> install({
    List<ModuleId> moduleIds = const [],
    InstallationTrigger trigger = InstallationTrigger.manual,
  }) async {
    try {
      status = InstallationStatus.inProgress;
      errorMessage = null;
      installedModuleCount = 0;
      totalModuleCount = moduleIds.length;

      final command = InstallRuntimeCommand(
        moduleIds: moduleIds,
        trigger: trigger,
        onProgress: _handleProgress,
      );

      final result = await _installHandler.handle(command);

      result.fold(
        (error) {
          status = InstallationStatus.failed;
          errorMessage = error.message;
        },
        (_) {
          status = InstallationStatus.completed;
          currentModule = null;
        },
      );
    } catch (e) {
      status = InstallationStatus.failed;
      errorMessage = e.toString();
    }
  }

  @action
  Future<void> cancel({String? reason}) async {
    if (!canCancel) return;

    try {
      final command = CancelInstallationCommand(
        installationId: currentInstallationId!,
        reason: reason,
      );

      final result = await _cancelHandler.handle(command);

      result.fold(
        (error) {
          errorMessage = 'Failed to cancel: ${error.message}';
        },
        (_) {
          status = InstallationStatus.cancelled;
        },
      );
    } catch (e) {
      errorMessage = 'Cancel failed: $e';
    }
  }

  @action
  void reset() {
    currentInstallationId = null;
    status = InstallationStatus.pending;
    overallProgress = 0.0;
    currentModule = null;
    currentModuleProgress = 0.0;
    errorMessage = null;
    installedModuleCount = 0;
    totalModuleCount = 0;
  }

  @action
  void _handleProgress(ModuleId moduleId, double progress) {
    currentModule = moduleId;
    currentModuleProgress = progress;

    if (progress >= 1.0) {
      installedModuleCount++;
    }

    if (totalModuleCount > 0) {
      overallProgress = installedModuleCount / totalModuleCount;
    }
  }

  @action
  Future<void> loadProgress({required InstallationId installationId}) async {
    try {
      final query = GetInstallationProgressQuery(
        installationId: installationId,
      );

      final result = await _progressHandler.handle(query);

      result.fold(
        (error) {
          errorMessage = error.message;
        },
        (progress) {
          currentInstallationId = installationId;
          status = progress.status;
          overallProgress = progress.overallProgress;
          currentModule = progress.currentModule;
          currentModuleProgress = progress.currentModuleProgress;
          installedModuleCount = progress.installedModuleCount;
          totalModuleCount = progress.totalModuleCount;
        },
      );
    } catch (e) {
      errorMessage = 'Failed to load progress: $e';
    }
  }
}
```

---

## 9. Cross-Cutting Concerns

### 9.1 Error Handling Strategy

```dart
/// Domain Layer Exceptions
sealed class DomainException implements Exception {
  final String message;
  const DomainException(this.message);

  @override
  String toString() => 'DomainException: $message';
}

class InvalidStateException extends DomainException {
  const InvalidStateException(super.message);
}

class ValidationException extends DomainException {
  const ValidationException(super.message);
}

/// Application Layer Exceptions
sealed class ApplicationException implements Exception {
  final String message;
  const ApplicationException(this.message);

  @override
  String toString() => 'ApplicationException: $message';
}

class NotFoundApplicationException extends ApplicationException {
  const NotFoundApplicationException(super.message);
}

/// Infrastructure Layer Exceptions
sealed class InfrastructureException implements Exception {
  final String message;
  final Exception? innerException;

  const InfrastructureException(this.message, [this.innerException]);

  @override
  String toString() => 'InfrastructureException: $message${innerException != null ? ' (${innerException})' : ''}';
}
```

### 9.2 Logging Strategy

```dart
/// Logger Interface
abstract class ILogger {
  void debug(String message, [Map<String, dynamic>? context]);
  void info(String message, [Map<String, dynamic>? context]);
  void warning(String message, [Map<String, dynamic>? context]);
  void error(String message, [Exception? exception, StackTrace? stackTrace]);
}

/// Implementation
@LazySingleton(as: ILogger)
class StructuredLogger implements ILogger {
  final String _component;

  StructuredLogger(@Named('component') this._component);

  @override
  void info(String message, [Map<String, dynamic>? context]) {
    final log = {
      'timestamp': DateTime.now().toIso8601String(),
      'level': 'INFO',
      'component': _component,
      'message': message,
      if (context != null) 'context': context,
    };

    print(jsonEncode(log));
  }

  // ... other methods
}
```

### 9.3 Telemetry & Analytics

```dart
/// Telemetry Interface
abstract class ITelemetry {
  void trackEvent(String eventName, [Map<String, dynamic>? properties]);
  void trackMetric(String metricName, double value);
  void trackException(Exception exception, [StackTrace? stackTrace]);
}

/// Usage in handlers
class InstallRuntimeCommandHandler {
  final ITelemetry _telemetry;

  Future<Either<ApplicationException, Unit>> handle(
    InstallRuntimeCommand command,
  ) async {
    _telemetry.trackEvent('runtime_installation_started', {
      'module_count': command.moduleIds.length,
    });

    final stopwatch = Stopwatch()..start();

    try {
      // ... installation logic

      _telemetry.trackMetric(
        'installation_duration_seconds',
        stopwatch.elapsed.inSeconds.toDouble(),
      );

      _telemetry.trackEvent('runtime_installation_completed');

      return right(unit);

    } catch (e) {
      _telemetry.trackException(e as Exception);
      rethrow;
    }
  }
}
```

---

## 10. Deployment Strategy

### 10.1 Distribution Modes

```yaml
Mode 1: Full Bundle
  Installer Size: ~600MB
  Contains:
    - IDE Core
    - Node.js Runtime
    - OpenVSCode Server
    - Base Extensions
  Target Users: Offline, Enterprise

Mode 2: Lite + Download on Demand (RECOMMENDED)
  Installer Size: ~50MB
  Downloads on First Use: ~400MB
  Contains:
    - IDE Core
    - Download Manager
  Target Users: General Public

Mode 3: Cloud-Hosted Extensions
  Installer Size: ~30MB
  Requires: Internet Connection
  Contains:
    - IDE Core
    - Cloud Client
  Target Users: SaaS, Web-based
```

### 10.2 CDN Structure

```
cdn.youride.com/
├── runtime/
│   ├── manifest.yaml                 # Master manifest
│   ├── v1.87.0/
│   │   ├── nodejs/
│   │   │   ├── node-v20.11.0-win-x64.zip
│   │   │   ├── node-v20.11.0-linux-x64.tar.xz
│   │   │   └── node-v20.11.0-darwin-arm64.tar.gz
│   │   ├── openvscode-server/
│   │   │   ├── openvscode-server-v1.87.0-win-x64.zip
│   │   │   ├── openvscode-server-v1.87.0-linux-x64.tar.gz
│   │   │   └── openvscode-server-v1.87.0-darwin-arm64.tar.gz
│   │   └── base-extensions/
│   │       └── base-extensions-v1.0.0.zip
│   └── checksums.sha256
└── extensions/
    └── [VS Code extensions mirror]
```

---

## 11. Testing Strategy

### 11.1 Testing Pyramid

```
┌──────────────────────────────┐
│   E2E Tests (5%)             │  Full installation flow
├──────────────────────────────┤
│   Integration Tests (15%)    │  Layer integration
├──────────────────────────────┤
│   Unit Tests (80%)           │  Domain logic, Use cases
└──────────────────────────────┘
```

### 11.2 Unit Tests (Domain)

```dart
void main() {
  group('RuntimeInstallation Aggregate', () {
    test('should create installation with valid modules', () {
      // Arrange
      final modules = [
        RuntimeModule.create(
          id: ModuleId.nodejs,
          name: 'Node.js',
          type: ModuleType.runtime,
          version: RuntimeVersion.fromString('20.11.0'),
          platformArtifacts: {
            PlatformIdentifier.windowsX64: PlatformArtifact(
              url: DownloadUrl('https://example.com/node.zip'),
              hash: SHA256Hash.fromString('a' * 64),
              size: ByteSize.fromMB(30),
            ),
          },
        ),
      ];

      // Act
      final installation = RuntimeInstallation.create(
        modules: modules,
        platform: PlatformIdentifier.windowsX64,
      );

      // Assert
      expect(installation.status, InstallationStatus.pending);
      expect(installation.modules.length, 1);
      expect(installation.uncommittedEvents.length, 1);
      expect(
        installation.uncommittedEvents.first,
        isA<InstallationStarted>(),
      );
    });

    test('should throw when platform not supported', () {
      // Arrange
      final modules = [
        RuntimeModule.create(
          id: ModuleId.nodejs,
          name: 'Node.js',
          type: ModuleType.runtime,
          version: RuntimeVersion.fromString('20.11.0'),
          platformArtifacts: {
            PlatformIdentifier.windowsX64: PlatformArtifact(
              url: DownloadUrl('https://example.com/node.zip'),
              hash: SHA256Hash.fromString('a' * 64),
              size: ByteSize.fromMB(30),
            ),
          },
        ),
      ];

      // Act & Assert
      expect(
        () => RuntimeInstallation.create(
          modules: modules,
          platform: PlatformIdentifier.linuxX64, // Not supported!
        ),
        throwsA(isA<DomainException>()),
      );
    });

    test('should progress through installation states', () {
      // Arrange
      final modules = [
        _createTestModule(ModuleId.nodejs),
      ];

      var installation = RuntimeInstallation.create(
        modules: modules,
        platform: PlatformIdentifier.windowsX64,
      );

      // Act & Assert
      installation = installation.start();
      expect(installation.status, InstallationStatus.inProgress);

      installation = installation.markModuleDownloaded(ModuleId.nodejs);
      expect(installation.currentModule, some(ModuleId.nodejs));

      installation = installation.markModuleVerified(ModuleId.nodejs);
      expect(installation.uncommittedEvents.any((e) => e is ModuleVerified), true);

      installation = installation.markModuleInstalled(ModuleId.nodejs);
      expect(installation.status, InstallationStatus.completed);
      expect(installation.progress, 1.0);
    });
  });
}
```

### 11.3 Integration Tests

```dart
void main() {
  late InstallRuntimeCommandHandler handler;
  late MockRuntimeRepository mockRepository;
  late MockDownloadService mockDownloadService;

  setUp(() {
    mockRepository = MockRuntimeRepository();
    mockDownloadService = MockDownloadService();

    handler = InstallRuntimeCommandHandler(
      mockRepository,
      // ... other mocks
    );
  });

  test('should install runtime successfully', () async {
    // Arrange
    when(() => mockDownloadService.download(any()))
        .thenAnswer((_) async => right(File('test.zip')));

    final command = InstallRuntimeCommand(
      moduleIds: [ModuleId.nodejs],
    );

    // Act
    final result = await handler.handle(command);

    // Assert
    expect(result.isRight(), true);
    verify(() => mockDownloadService.download(any())).called(1);
  });
}
```

---

## 12. Migration Path

### 12.1 Phase 1: Foundation (Weeks 1-2)

```
Tasks:
  ✓ Create package structure
  ✓ Define domain model (entities, VOs)
  ✓ Define ports (interfaces)
  ✓ Setup DI (injectable)
  ✓ Write domain unit tests

Deliverable: Core domain package with 100% test coverage
```

### 12.2 Phase 2: Infrastructure (Weeks 3-4)

```
Tasks:
  ✓ Implement repositories
  ✓ Implement services (download, extraction, verification)
  ✓ Setup CDN manifest structure
  ✓ Write integration tests

Deliverable: Working infrastructure layer
```

### 12.3 Phase 3: Application (Weeks 5-6)

```
Tasks:
  ✓ Implement command handlers
  ✓ Implement query handlers
  ✓ Setup event bus
  ✓ Write application tests

Deliverable: Complete use case layer
```

### 12.4 Phase 4: Presentation (Weeks 7-8)

```
Tasks:
  ✓ Create MobX Stores
  ✓ Build UI components (widgets)
  ✓ Implement installation dialog
  ✓ Add telemetry

Deliverable: Working UI with reactive state management
```

### 12.5 Phase 5: Integration (Weeks 9-10)

```
Tasks:
  ✓ Wire up all layers
  ✓ E2E testing
  ✓ Performance optimization
  ✓ Documentation

Deliverable: Production-ready system
```

---

## Appendix A: Technology Stack

```yaml
Core:
  - Language: Dart 3.x
  - Immutability: freezed
  - Functional: dartz (Either, Option)
  - Equality: equatable

Application:
  - DI: injectable + get_it
  - Validation: Built into domain

Infrastructure:
  - HTTP: dio
  - Archive: archive
  - Crypto: crypto
  - File System: dart:io

Presentation:
  - State: mobx + flutter_mobx
  - UI: Flutter Material 3

Testing:
  - Unit: test
  - Mocking: mocktail
  - Coverage: coverage
```

---

## Appendix B: Key Patterns Summary

| Pattern | Usage | Location |
|---------|-------|----------|
| **Aggregate** | RuntimeInstallation | Domain |
| **Value Object** | RuntimeVersion, ByteSize | Domain |
| **Specification** | PlatformCompatibleSpec | Domain |
| **Repository** | IRuntimeRepository | Port/Infrastructure |
| **Factory** | RuntimeInstallation.create() | Domain |
| **Command/Query** | CQRS Lite | Application |
| **Adapter** | Repository implementations | Infrastructure |
| **Strategy** | IDownloadService implementations | Infrastructure |
| **Observer** | Event Bus | Infrastructure |
| **MobX Observer** | Reactive state management | Presentation |
| **Dependency Injection** | get_it + injectable | All layers |

---

**End of Document**

Version: 1.0.0
Last Updated: 2025-01-18
Status: ✅ Ready for Implementation
