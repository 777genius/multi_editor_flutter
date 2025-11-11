# Symbol Navigator Plugin - Quick Start Guide

Get up and running in **5 minutes**! ⚡

## 🎯 Prerequisites

```bash
# Check versions
flutter --version   # Need: 3.0+
go version          # Need: 1.21+
```

## 🚀 Installation

### Option 1: Using Dev Scripts (Recommended)

```bash
# 1. Navigate to Dart plugin
cd modules/plugins/multi_editor_plugin_symbol_navigator

# 2. Run all setup and checks
./dev.sh all
# This will:
# ✓ Get dependencies
# ✓ Format code
# ✓ Analyze code
# ✓ Generate freezed files
# ✓ Run tests

# 3. Build WASM plugin
cd ../../../packages/wasm_plugins/symbol_navigator_wasm
./dev.sh build install
# This will:
# ✓ Download Go dependencies
# ✓ Build WASM binary
# ✓ Install to Flutter project

# ✅ Done! Plugin ready to use
```

### Option 2: Manual Steps

```bash
# Dart setup
cd modules/plugins/multi_editor_plugin_symbol_navigator
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Go WASM setup
cd ../../../packages/wasm_plugins/symbol_navigator_wasm
go mod download
make build
make install
```

## 🎮 Basic Usage

### 1. Register Plugin

```dart
import 'package:multi_editor_plugin_symbol_navigator/multi_editor_plugin_symbol_navigator.dart';

// Create plugin instance
final symbolNavigator = SymbolNavigatorPlugin();

// Register with plugin manager
await pluginManager.registerPlugin(symbolNavigator);

// Initialize
await symbolNavigator.onInitialize(pluginContext);
```

### 2. Open a File

```dart
// Create or load a file
final dartFile = FileDocument(
  id: 'file-1',
  name: 'my_widget.dart',
  content: '''
    class MyWidget extends StatelessWidget {
      final String title;

      @override
      Widget build(BuildContext context) {
        return Text(title);
      }
    }
  ''',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

// Trigger symbol parsing
symbolNavigator.onFileOpen(dartFile);
```

### 3. Access Symbols

```dart
// Get symbol tree
final tree = symbolNavigator.currentSymbolTree;

print('File: ${tree?.filePath}');
print('Language: ${tree?.language}');
print('Total symbols: ${tree?.totalCount}');
print('Parse time: ${tree?.parseDurationMs}ms');

// Access symbols
for (final symbol in tree?.symbols ?? []) {
  print('${symbol.kind.displayName}: ${symbol.name}');

  // Access children
  for (final child in symbol.children) {
    print('  └─ ${child.kind.displayName}: ${child.name}');
  }
}
```

### 4. Find Symbols

```dart
// Find by name
final myClass = tree?.findSymbolByName('MyWidget');
print('Found: ${myClass?.qualifiedName}');

// Find at line
final symbolAtLine5 = tree?.findSymbolAtLine(5);
print('Symbol at line 5: ${symbolAtLine5?.name}');

// Get statistics
final stats = tree?.statistics ?? {};
stats.forEach((kind, count) {
  print('$kind: $count');
});
```

## 📊 Output Example

```text
File: my_widget.dart
Language: dart
Total symbols: 3
Parse time: 5ms

Class: MyWidget
  └─ Field: title
  └─ Method: build

Statistics:
  Class: 1
  Field: 1
  Method: 1
```

## 🎨 UI Integration

### Display Symbol Tree

```dart
class SymbolTreeView extends StatelessWidget {
  final SymbolNavigatorPlugin plugin;

  @override
  Widget build(BuildContext context) {
    final tree = plugin.currentSymbolTree;

    if (tree == null) {
      return Text('No symbols');
    }

    return ListView.builder(
      itemCount: tree.symbols.length,
      itemBuilder: (context, index) {
        final symbol = tree.symbols[index];
        return ListTile(
          leading: Icon(
            IconData(symbol.kind.iconCode, fontFamily: 'MaterialIcons'),
          ),
          title: Text(symbol.name),
          subtitle: Text('Line ${symbol.location.startLine + 1}'),
          onTap: () => _jumpToLine(symbol.location.startLine),
        );
      },
    );
  }
}
```

## 🧪 Testing

### Run All Tests

```bash
# Dart tests
cd modules/plugins/multi_editor_plugin_symbol_navigator
./dev.sh test

# Go tests
cd ../../../packages/wasm_plugins/symbol_navigator_wasm
./dev.sh test

# Or run all at once
./dev.sh all  # Includes tests
```

### Example Test

```dart
test('parses Dart class', () {
  final symbols = parseTestFile('''
    class Test {
      void method() {}
    }
  ''');

  expect(symbols.length, 1);
  expect(symbols[0].name, 'Test');
  expect(symbols[0].children.length, 1);
  expect(symbols[0].children[0].name, 'method');
});
```

## 🔧 Development Mode

### Watch for Changes

```bash
# Dart: Auto-regenerate freezed files
cd modules/plugins/multi_editor_plugin_symbol_navigator
./dev.sh watch

# Go: Auto-rebuild on changes (requires fswatch)
cd packages/wasm_plugins/symbol_navigator_wasm
./dev.sh watch
```

### Hot Reload During Development

```bash
# Terminal 1: Run Dart watch
./dev.sh watch

# Terminal 2: Run your app
flutter run

# Terminal 3: Rebuild WASM when needed
cd packages/wasm_plugins/symbol_navigator_wasm
./dev.sh build install
```

## 🐛 Troubleshooting

### Issue: Freezed Files Not Generated

```bash
# Solution
cd modules/plugins/multi_editor_plugin_symbol_navigator
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: WASM Build Fails

```bash
# Check Go version
go version  # Must be 1.21+

# Clean and rebuild
cd packages/wasm_plugins/symbol_navigator_wasm
./dev.sh clean
./dev.sh deps
./dev.sh build
```

### Issue: No Symbols Parsed

```dart
// Check file extension is supported
final language = _detectLanguage('test.dart');
print('Detected language: $language');  // Should be 'dart'

// Check file content
print('Content length: ${file.content.length}');

// Check for errors
symbolNavigator.getState<String?>('error');  // Should be null
```

### Issue: Performance Slow

```dart
// Check parse duration
final tree = symbolNavigator.currentSymbolTree;
print('Parse time: ${tree?.parseDurationMs}ms');

// Expected: 5-10ms per 1000 lines
// If slower, check file size or complexity
```

## 📈 Performance Tips

### Optimize Parsing

```dart
// Use debouncing (already built-in, 500ms)
// Avoid parsing on every keystroke

// For large files, consider:
// 1. Incremental parsing (future feature)
// 2. Parse on save only
// 3. Background thread parsing
```

### Memory Management

```dart
// Clean up when done
await symbolNavigator.onDispose();

// Clear state manually if needed
symbolNavigator.clearState();
```

## 🎓 Next Steps

### Learn More

1. **Architecture**: Read [ARCHITECTURE.md](ARCHITECTURE.md)
2. **Examples**: Check [example/](example/) directory
3. **Contributing**: See [CONTRIBUTING.md](CONTRIBUTING.md)
4. **API Docs**: Generate with `dart doc`

### Extend Functionality

```dart
// 1. Add custom symbol kinds
const factory SymbolKind.customKind() = _CustomKind;

// 2. Add metadata
final symbol = CodeSymbol(
  name: 'myMethod',
  kind: const SymbolKind.method(),
  location: location,
  metadata: {
    'visibility': 'public',
    'async': true,
    'returnType': 'Future<void>',
  },
);

// 3. Implement custom UI
class CustomSymbolNavigator extends StatelessWidget {
  // Your custom implementation
}
```

### Add New Language

See [CONTRIBUTING.md#adding-new-language-support](CONTRIBUTING.md#adding-new-language-support) for detailed guide.

## 🆘 Getting Help

- **Documentation**: Check [README.md](README.md)
- **Issues**: Open issue on GitHub
- **Examples**: Run [example/usage_example.dart](example/usage_example.dart)
- **Tests**: Look at test files for usage patterns

## 📋 Checklist

Before using in production:

- [ ] Freezed files generated
- [ ] WASM plugin built and installed
- [ ] Tests passing (Dart + Go)
- [ ] Performance acceptable (< 10ms per 1K lines)
- [ ] Error handling tested
- [ ] UI integration working
- [ ] Memory leaks checked

## 🎉 You're Ready!

Symbol Navigator Plugin is now ready to use. Happy coding! 🚀

---

**Quick Commands Reference:**

```bash
# Setup
./dev.sh all              # Dart: Full setup + checks
./dev.sh build install    # Go: Build + install WASM

# Development
./dev.sh watch            # Auto-regenerate
./dev.sh test             # Run tests
./dev.sh fmt              # Format code

# Troubleshooting
./dev.sh clean            # Clean artifacts
./dev.sh deps             # Re-download deps
```

Need more help? Check [README.md](README.md) or [CONTRIBUTING.md](CONTRIBUTING.md)!
