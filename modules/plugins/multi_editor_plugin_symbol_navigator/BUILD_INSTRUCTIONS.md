# Build Instructions for Symbol Navigator Plugin

## Step 1: Generate Freezed Files

This plugin uses `freezed` for immutable data classes. You need to generate the freezed files before using the plugin.

### Run Code Generation

```bash
cd modules/plugins/multi_editor_plugin_symbol_navigator
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate the following files:
- `lib/src/domain/value_objects/symbol_kind.freezed.dart`
- `lib/src/domain/value_objects/symbol_location.freezed.dart`
- `lib/src/domain/value_objects/symbol_location.g.dart`
- `lib/src/domain/entities/code_symbol.freezed.dart`
- `lib/src/domain/entities/code_symbol.g.dart`

### Watch Mode (for development)

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

## Step 2: Build WASM Plugin

The Symbol Navigator uses a Go WASM plugin for high-performance parsing.

### Prerequisites

- Go 1.21+
- Optional: `binaryen` for optimization (`brew install binaryen` on macOS)

### Build WASM

```bash
cd packages/wasm_plugins/symbol_navigator_wasm
make build
```

This creates `build/symbol_navigator.wasm`.

### Install WASM to Flutter Project

```bash
make install
```

This copies the WASM file to the plugin directory (accessible at runtime as `packages/multi_editor_plugin_symbol_navigator/wasm/`).

## Step 3: Register Plugin

Add the plugin to your plugin manager:

```dart
import 'package:multi_editor_plugin_symbol_navigator/multi_editor_plugin_symbol_navigator.dart';

// Register plugin
final plugin = SymbolNavigatorPlugin();
await pluginManager.registerPlugin(plugin);
```

## Step 4: Load WASM Plugin (Optional)

If using WASM parsing:

```dart
// Load WASM runtime
final wasmPath = 'packages/multi_editor_plugin_symbol_navigator/wasm/symbol_navigator.wasm';
await wasmRuntime.loadPlugin(wasmPath);
```

## Troubleshooting

### Freezed generation fails

- Make sure `build_runner` and `freezed` are in `dev_dependencies`
- Try `flutter clean` then regenerate
- Check for syntax errors in source files

### WASM build fails

- Verify Go version: `go version` (needs 1.21+)
- Check GOOS/GOARCH support: `go tool dist list | grep wasm`
- Make sure dependencies are downloaded: `make deps`

### WASM plugin not loading

- Verify WASM file exists: `ls wasm/symbol_navigator.wasm`
- Check WASM validation: `wasm-validate wasm/symbol_navigator.wasm`
- Review console for error messages

## Development Workflow

1. **Modify Dart models** → Run `build_runner build`
2. **Modify Go parser** → Run `make build && make install`
3. **Test changes** → Run tests or launch app
4. **Commit** → Commit source files only (generated `.freezed.dart` and `.g.dart` files are gitignored and regenerated on build)

## Performance Notes

Current implementation uses regex-based parsing (~5-10ms for 1000 lines).

Future tree-sitter integration will provide 10-100x speedup.

## Language Support

Currently supported:
- ✅ Dart (regex-based parser)
- ⏳ JavaScript (TODO)
- ⏳ TypeScript (TODO)
- ⏳ Python (TODO)
- ⏳ Go (TODO)
- ⏳ Rust (TODO)
