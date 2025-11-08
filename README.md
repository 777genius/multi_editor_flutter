# Multi-File Code Editor

[![CodeFactor](https://img.shields.io/codefactor/grade/github/777genius/multi_editor_flutter?style=flat-square)](https://www.codefactor.io/repository/github/777genius/multi_editor_flutter)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20Web-blue?style=flat-square)](https://github.com/777genius/multi_editor_flutter)
[![Flutter](https://img.shields.io/badge/Flutter-3.35.0+-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.8+-0175C2?style=flat-square&logo=dart)](https://dart.dev)

A production-ready, extensible multi-file code editor for Flutter built on **Clean Architecture** and **Domain-Driven Design** principles.

![Multi-File Code Editor](image.png)

## ✨ Features

- ✅ **Monaco Editor** - VS Code's professional editor
- ✅ **100+ languages** - Syntax highlighting for all major languages
- ✅ **Unlimited nesting** - Hierarchical file tree with drag-and-drop
- ✅ **Plugin system** - Extensible with lifecycle management, event-driven architecture
- ✅ **Multiple themes** - Light, Dark, High Contrast with dynamic switching
- ✅ **Type-safe** - Freezed sealed classes (Dart 3.x)
- ✅ **Production-ready** - Error isolation, auto-disable, retry mechanisms

## 🖥️ Platform Support

| Platform | Status | WebView Engine | Notes |
|----------|--------|----------------|-------|
| **Windows** | ✅ Supported | CEF (Chromium Embedded Framework) | Production-ready |
| **macOS** | ✅ Supported | CEF (Chromium Embedded Framework) | Production-ready |
| **Linux** | ✅ Supported | CEF (Chromium Embedded Framework) | Production-ready |
| **Web** | ✅ Supported | Native Browser (IFrame) | Production-ready |
| Android | 🔧 Easy to enable | WebView (webview_flutter) | UI not optimized for mobile |
| iOS | 🔧 Easy to enable | WKWebView (webview_flutter) | UI not optimized for mobile |

> **Desktop & Web Ready**: The editor is production-ready for desktop and web platforms with optimized UI.
>
> **Mobile Support**: Android and iOS support can be easily re-enabled by uncommenting `webview_flutter` dependency and platform declarations in `pubspec.yaml`. However, the current UI is designed for desktop/web with:
> - Fixed sidebars and panels
> - Mouse/keyboard-first interactions
> - No responsive breakpoints for small screens
>
> 📱 **[Mobile Re-enabling Guide →](MOBILE_SUPPORT.md)** - Step-by-step instructions, limitations, and recommendations for mobile adaptation.

### Linux Requirements

On Linux, the editor uses [webview_cef](https://pub.dev/packages/webview_cef) which requires CEF (Chromium Embedded Framework). The CEF binaries are automatically downloaded during the first build for your architecture (x64 or arm64).

No additional system dependencies are required - CEF bundles everything needed.

📖 **[Detailed Linux Guide →](LINUX.md)** - Installation, troubleshooting, packaging, and more.

## 🚀 Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  multi_editor_core: ^0.1.0
  multi_editor_ui: ^0.1.0
  multi_editor_plugins: ^0.1.0

  # Optional plugins
  multi_editor_plugin_auto_save: ^0.1.0
  multi_editor_plugin_file_icons: ^0.1.0
  multi_editor_plugin_file_stats: ^0.1.0
  multi_editor_plugin_recent_files: ^0.1.0
  multi_editor_plugin_dart: ^0.1.0
```

### Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:multi_editor_ui/multi_editor_ui.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Code Editor',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const EditorScreen(),
    );
  }
}

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final EditorController _controller;
  late final PluginManager _pluginManager;

  @override
  void initState() {
    super.initState();

    // Initialize controller
    _controller = EditorController(
      repository: YourFileRepository(), // Implement your repository
    );

    // Initialize plugin manager
    _pluginManager = PluginManager()
      ..registerPlugin(AutoSavePlugin())
      ..registerPlugin(FileIconsPlugin())
      ..registerPlugin(FileStatsPlugin())
      ..initializeAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EditorScaffold(
        controller: _controller,
        pluginManager: _pluginManager,
      ),
    );
  }

  @override
  void dispose() {
    _pluginManager.disposeAll();
    _controller.dispose();
    super.dispose();
  }
}
```

### Implement Repository

The editor requires a repository implementation for file operations:

```dart
class YourFileRepository implements FileRepository {
  @override
  Future<FileDocument> getFile(String id) async {
    // Load file from your backend/storage
  }

  @override
  Future<void> saveFile(FileDocument file) async {
    // Save file to your backend/storage
  }

  @override
  Future<FileTreeNode> getFileTree() async {
    // Return your file tree structure
  }

  // Implement other required methods...
}
```

## 📦 Packages

The project is organized as a **monorepo** with **10 packages**.

### Core Packages

| Package | Description | Version |
|---------|-------------|---------|
| [**multi_editor_core**](modules/multi_editor_core) | Domain layer: entities, value objects, repositories | ![pub](https://img.shields.io/badge/pub-0.1.0-blue) |
| [**multi_editor_plugins**](modules/multi_editor_plugins) | Plugin system with lifecycle management | ![pub](https://img.shields.io/badge/pub-0.1.0-blue) |
| [**multi_editor_ui**](modules/multi_editor_ui) | Flutter widgets, Monaco editor integration | ![pub](https://img.shields.io/badge/pub-0.1.0-blue) |
| [**multi_editor_mock**](modules/multi_editor_mock) | Testing infrastructure with in-memory implementations | ![pub](https://img.shields.io/badge/pub-0.1.0-blue) |

### Plugin Packages

| Plugin | Description | Version |
|--------|-------------|---------|
| [**multi_editor_plugin_base**](modules/plugins/multi_editor_plugin_base) | Base abstractions for all plugins | ![pub](https://img.shields.io/badge/pub-0.1.0-blue) |
| [**multi_editor_plugin_auto_save**](modules/plugins/multi_editor_plugin_auto_save) | Auto-save with debouncing | ![pub](https://img.shields.io/badge/pub-0.1.0-blue) |
| [**multi_editor_plugin_file_icons**](modules/plugins/multi_editor_plugin_file_icons) | 150+ file type icons via Devicon CDN | ![pub](https://img.shields.io/badge/pub-0.1.0-blue) |
| [**multi_editor_plugin_file_stats**](modules/plugins/multi_editor_plugin_file_stats) | Real-time file statistics (lines, chars, words) | ![pub](https://img.shields.io/badge/pub-0.1.0-blue) |
| [**multi_editor_plugin_recent_files**](modules/plugins/multi_editor_plugin_recent_files) | Recent files tracking | ![pub](https://img.shields.io/badge/pub-0.1.0-blue) |
| [**multi_editor_plugin_dart**](modules/plugins/multi_editor_plugin_dart) | Dart language support with snippets | ![pub](https://img.shields.io/badge/pub-0.1.0-blue) |

## 🏗️ Architecture

### Clean Architecture Layers

```
┌─────────────────────────────────────────────┐
│        Presentation (multi_editor_ui)        │
│   Widgets │ Controllers │ State Management   │
└───────────────────┬──────────────────────────┘
                    │
┌───────────────────▼──────────────────────────┐
│     Application (multi_editor_plugins)       │
│  Plugin Manager │ Events │ Messaging │ UI   │
└───────────────────┬──────────────────────────┘
                    │
┌───────────────────▼──────────────────────────┐
│         Domain (multi_editor_core)           │
│  Entities │ Value Objects │ Repositories     │
└───────────────────┬──────────────────────────┘
                    │
┌───────────────────▼──────────────────────────┐
│             Infrastructure                    │
│         multi_editor_mock │ Adapters         │
└─────────────────────────────────────────────┘
```

### Key Architectural Patterns

- **Domain-Driven Design** - Rich domain models with behavior
- **SOLID Principles** - Single responsibility, dependency inversion
- **Plugin Architecture** - Extensible system with lifecycle hooks
- **Event Bus** - Decoupled communication via pub/sub
- **Repository Pattern** - Abstract data access
- **Command Pattern** - Command bus for operations

## 🔌 Creating Custom Plugins

```dart
import 'package:multi_editor_plugin_base/multi_editor_plugin_base.dart';

class MyCustomPlugin extends BaseEditorPlugin {
  @override
  PluginManifest get manifest => PluginManifest(
    id: 'my-custom-plugin',
    name: 'My Custom Plugin',
    version: '1.0.0',
    dependencies: [], // Plugin dependencies
  );

  @override
  Future<void> onInitialize(PluginContext context) async {
    final editorService = context.getService<EditorService>();
    // Initialize your plugin
  }

  @override
  void onFileOpen(FileDocument file) {
    // Handle file open event
  }

  @override
  FileIconDescriptor? getFileIconDescriptor(FileTreeNode node) {
    if (node.name.endsWith('.custom')) {
      return FileIconDescriptor.url(
        url: 'https://cdn.example.com/icon.svg',
        pluginId: manifest.id,
        priority: 50,
      );
    }
    return null;
  }
}
```

### Plugin Capabilities

- ✅ File/folder lifecycle events (open, close, save, create, delete)
- ✅ Custom UI widgets
- ✅ File icons customization
- ✅ Inter-plugin messaging
- ✅ Configuration storage
- ✅ State persistence
- ✅ Language-specific features

## 🛠️ Development

### Local Setup

```bash
# Clone repository
git clone https://github.com/777genius/multi_editor_flutter.git
cd multi_file_code_editor

# Initialize workspace
dart pub get

# Bootstrap with Melos (11 packages)
dart run melos bootstrap

# Generate code (Freezed)
dart run melos run build_runner
```

### Development Commands

```bash
# Analyze all packages
dart run melos run analyze

# Format code
dart run melos run format

# Run tests with coverage
dart run melos run test

# Clean all packages
dart run melos run clean
```

### Running on Different Platforms

```bash
# Run on desktop (will auto-detect your OS)
cd example
flutter run -d windows  # Windows
flutter run -d macos    # macOS
flutter run -d linux    # Linux

# Run on web
flutter run -d chrome

# Build for production
flutter build windows   # Windows
flutter build macos     # macOS
flutter build linux     # Linux (CEF binaries auto-downloaded on first build)
flutter build web       # Web
```

## 📤 Publishing

The project uses **Pub Workspaces** for automatic dependency management.

```bash
# 1. Commit with Conventional Commits
git commit -m "feat: add new feature"

# 2. Update versions automatically
dart run melos version

# 3. Publish (dry-run first)
dart run melos publish

# 4. Real publish (edit melos.yaml: dry-run: false)
dart run melos publish
```

**Key Benefits:**
- ✅ Automatic local → hosted switching during publish
- ✅ No manual pubspec.yaml changes required
- ✅ Instant changes reflected in dependent packages

See [WORKSPACE_SETUP.md](WORKSPACE_SETUP.md) for details.

## 🎯 Use Cases

- **Cross-Platform Desktop Apps** - Embed multi-file code editor (Windows, macOS, Linux)
- **Web Applications** - Browser-based code editing
- **Custom IDEs** - Build Flutter-based IDEs for any platform
- **Code Review Tools** - Review code with Monaco editor
- **Educational Platforms** - Code learning with syntax highlighting
- **API Documentation** - Interactive code examples

## TODO

- [ ] Search & replace across files
- [ ] Full desktop integration (LSP autocompletion)
- [ ] full IDE mode (module) with git, terminal...
- [ ] ? Re-enable mobile support (Android/iOS)


## 📊 Tech Stack

- **Dart**: 3.8+ (sealed classes)
- **Flutter**: 3.35.0+
- **Monaco Editor**: 0.52.2+ (VS Code's editor)
- **webview_cef**: ^0.2.2 - Desktop WebView (Windows/macOS/Linux)
- **Freezed**: ^3.1.0 - Immutable data classes
- **Melos**: ^7.0.0 - Monorepo management

## 🤝 Contributing

Contributions welcome! Follow Conventional Commits format:

```
feat: add new feature
fix: bug fix
docs: documentation
refactor: code refactoring
test: add tests
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file.

## 📞 Contact

- **GitHub**: [@777genius](https://github.com/777genius)
- **Repository**: [multi_editor_flutter](https://github.com/777genius/multi_editor_flutter)
- **Issues**: [Report bugs](https://github.com/777genius/multi_editor_flutter/issues)

---

**Built with ❤️ using Flutter**
