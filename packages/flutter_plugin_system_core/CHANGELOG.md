# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial release of flutter_plugin_system_core
- Core interfaces: `IPlugin`, `IPluginRuntime`, `IPluginHost`, `HostFunction`
- Immutable models: `PluginManifest`, `PluginContext`, `PluginEvent`, `PluginResponse`, `PluginConfig`, `PluginSource`
- Type definitions: `PluginRuntimeType`, `PluginState`, `PluginSourceType`
- Exception hierarchy: `PluginException` and specialized exceptions
- Comprehensive documentation and examples
- Zero dependencies (except meta and code generation)
- Clean Architecture compliance
- SOLID principles implementation
- Full API documentation

### Features

- **Pure Abstractions**: Runtime-agnostic plugin system contracts
- **Type Safety**: Strongly typed interfaces with Freezed models
- **Immutability**: All models are immutable for thread safety
- **Extensibility**: Easy to extend without modifying existing code
- **Reusability**: Can be used across multiple projects

[0.1.0]: https://github.com/777genius/multi_editor_flutter/releases/tag/flutter_plugin_system_core-v0.1.0
