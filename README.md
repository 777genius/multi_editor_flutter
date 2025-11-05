# Multi-File Code Editor

A production-ready, extensible, multi-file code editor package for Flutter.

![Multi-File Code Editor](image.png)

## Features

- 🌳 **Unlimited folder nesting** with hierarchical file tree
- 📝 **Monaco Editor** integration via `flutter_monaco` package
- 🔌 **Plugin architecture** for extensibility
- 🎨 **Multiple backend adapters** (HTTP, Local, Custom)
- 📦 **Clean Architecture** with DDD, SOLID, DRY principles
- 🧪 **Fully tested** with unit, widget, and integration tests
- 🚀 **Ready for pub.dev** publication

## Packages

This is a monorepo managed by [melos](https://pub.dev/packages/melos).

### Core Packages

- **editor_core** - Domain entities, value objects, and port interfaces
- **editor_plugins** - Plugin API, manager, and built-in plugins
- **editor_ui** - UI widgets, controllers, and Monaco integration

### Adapter Packages

- **editor_adapter_http** - HTTP backend adapter
- **editor_adapter_local** - Local storage adapter
- **editor_mock** - Mock adapter for testing

## Architecture

```
┌─────────────────────────────────────────────┐
│              UI Layer (editor_ui)            │
│   Monaco Editor │ File Tree │ Controllers   │
└───────────────────┬──────────────────────────┘
                    │
┌───────────────────▼──────────────────────────┐
│      Application Layer (editor_plugins)      │
│   Plugin Manager │ Event Bus │ Commands      │
└───────────────────┬──────────────────────────┘
                    │
┌───────────────────▼──────────────────────────┐
│        Domain Layer (editor_core)            │
│   Entities │ Value Objects │ Ports           │
└───────────────────┬──────────────────────────┘
                    │
┌───────────────────▼──────────────────────────┐
│           Infrastructure Layer               │
│   HTTP Adapter │ Local Adapter │ Mock        │
└─────────────────────────────────────────────┘
```

## Getting Started

### Prerequisites

- Flutter SDK: ^3.35.0
- Dart SDK: ^3.8.0

### Setup

```bash
# Install melos
dart pub global activate melos

# Bootstrap the monorepo
melos bootstrap

# Run build_runner for all packages
melos run build_runner
```

### Development

```bash
# Analyze all packages
melos run analyze

# Format all packages
melos run format

# Run all tests
melos run test

# Clean all packages
melos run clean
```

## Usage

See individual package READMEs for detailed usage instructions:

- [editor_core](modules/editor_core/README.md)
- [editor_plugins](modules/editor_plugins/README.md)
- [editor_ui](modules/editor_ui/README.md)

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## License

BSD-3-Clause License. See [LICENSE](LICENSE) file for details.
