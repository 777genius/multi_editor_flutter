# Multi Editor Flutter - Plugins

Comprehensive guide to the plugin ecosystem.

## 📦 Available Plugins

### 1. **TODO/FIXME Tracker** (`plugin.todo-tracker`)

Tracks TODO, FIXME, HACK, NOTE, XXX, BUG, OPTIMIZE, REVIEW comments in source code.

**Key Features:**
- Hybrid Dart + Rust WASM backend for performance
- Author and tag extraction
- Priority detection
- Real-time scanning

**Location:** `app/modules/plugins/multi_editor_plugin_todo_tracker/`

**WASM Backend:** `packages/wasm_plugins/todo_scanner_wasm/`

[Read more →](app/modules/plugins/multi_editor_plugin_todo_tracker/README.md)

---

### 2. **Git Blame Inline Viewer** (`plugin.git-blame`)

Shows git blame information for the current line.

**Key Features:**
- Inline commit info display
- Relative timestamps
- Author information
- Integration with git_integration module

**Location:** `app/modules/plugins/multi_editor_plugin_git_blame/`

[Read more →](app/modules/plugins/multi_editor_plugin_git_blame/README.md)

---

### 3. **Advanced Find & Replace** (`plugin.find-replace`)

Advanced search and replace with regex support and preview.

**Key Features:**
- Regex and literal search
- Replace preview with diff
- Multi-file support (planned)
- Search history

**Location:** `app/modules/plugins/multi_editor_plugin_find_replace/`

[Read more →](app/modules/plugins/multi_editor_plugin_find_replace/README.md)

---

### 4. **Bracket Pair Colorizer** (`plugin.bracket-colorizer`)

Rainbow bracket colorizer with nesting depth analysis and error detection.

**Key Features:**
- Rainbow colors for different nesting levels
- Supports (), {}, [], <>
- Unlimited nesting depth
- Error detection (unmatched, mismatched)
- String and comment awareness
- Rust WASM backend for performance

**Location:** `app/modules/plugins/multi_editor_plugin_bracket_colorizer/`

**WASM Backend:** `packages/wasm_plugins/bracket_colorizer_wasm/`

[Read more →](app/modules/plugins/multi_editor_plugin_bracket_colorizer/README.md)

---

### 5. **Auto Save** (`plugin.auto-save`)

Automatically saves files at configurable intervals.

**Location:** `app/modules/plugins/multi_editor_plugin_auto_save/`

---

### 6. **Recent Files** (`plugin.recent-files`)

Tracks and displays recently opened files.

**Location:** `app/modules/plugins/multi_editor_plugin_recent_files/`

---

### 7. **File Statistics** (`plugin.file-stats`)

Shows file metrics (lines, characters, words, size).

**Location:** `app/modules/plugins/multi_editor_plugin_file_stats/`

---

### 8. **File Icons** (`plugin.file-icons`)

Displays file type icons in file tree.

**Location:** `app/modules/plugins/multi_editor_plugin_file_icons/`

---

### 9. **Symbol Navigator** (`plugin.symbol-navigator`)

Code symbol navigation powered by WASM backend.

**Location:** `app/modules/plugins/multi_editor_plugin_symbol_navigator/`

**WASM Backend:** `packages/wasm_plugins/symbol_navigator_wasm/`

---

## 🏗️ Plugin Architecture

All plugins follow **Clean Architecture** + **DDD** principles:

```
Presentation (UI & Plugin API)
    ↓
Application (Use Cases)
    ↓
Domain (Entities, Value Objects)
    ↑
Infrastructure (Repositories, Adapters)
```

### Base Classes

- **BaseEditorPlugin**: Base class with lifecycle hooks and error handling
- **StatefulPlugin**: Mixin for in-memory state management
- **ConfigurablePlugin**: Mixin for persistent configuration

### Plugin Lifecycle

1. **Registration**: `pluginManager.registerPlugin(plugin)`
2. **Initialization**: `onInitialize(context)`
3. **Event Handling**: `onFileOpen()`, `onFileSave()`, etc.
4. **Disposal**: `onDispose()`

## 🔧 Creating a New Plugin

### Dart Plugin

```dart
class MyPlugin extends BaseEditorPlugin with StatefulPlugin {
  @override
  PluginManifest get manifest => PluginManifestBuilder()
      .withId('plugin.my-plugin')
      .withName('My Plugin')
      .withVersion('0.1.0')
      .build();

  @override
  Future<void> onInitialize(PluginContext context) async {
    // Setup
  }

  @override
  void onFileOpen(FileDocument file) {
    safeExecute('Handle file open', () {
      // Logic
    });
  }

  @override
  PluginUIDescriptor? getUIDescriptor() {
    return PluginUIDescriptor(
      pluginId: manifest.id,
      iconCode: 0xe873,
      iconFamily: 'MaterialIcons',
      tooltip: 'My Plugin',
      priority: 10,
      uiData: {
        'type': 'list',
        'items': [...],
      },
    );
  }
}
```

### Rust WASM Plugin

```rust
use serde::{Deserialize, Serialize};

#[no_mangle]
pub extern "C" fn plugin_get_manifest() -> u64 {
    let manifest = PluginManifest::new();
    memory::serialize_and_pack(&manifest)
}

#[no_mangle]
pub extern "C" fn plugin_handle_event(event_ptr: u32, event_len: u32) -> u64 {
    let event = read_event(event_ptr, event_len);
    let response = handle_event(event);
    memory::serialize_and_pack(&response)
}
```

## 📊 Performance Guidelines

### When to Use WASM

✅ **Use WASM for:**
- Heavy computation (> 1000 operations)
- Large data processing (> 5000 lines)
- AST parsing and analysis
- Complex regex operations
- Cryptographic operations

❌ **Use Dart for:**
- Simple string manipulation
- UI state management
- File I/O operations
- Small data sets (< 5000 items)
- Event handling

### Hybrid Approach

Best practice: Use Dart for small operations, WASM for large ones.

Example: TODO Tracker
- Small files (< 5000 lines): Dart regex
- Large files (>= 5000 lines): Rust WASM

## 🎯 Plugin Best Practices

1. **Error Isolation**: Use `safeExecute()` to prevent crashes
2. **Debouncing**: Debounce expensive operations (e.g., search, analysis)
3. **State Management**: Use `StatefulPlugin` for reactive state
4. **Configuration**: Use `ConfigurablePlugin` for persistent settings
5. **UI Updates**: Only update UI when necessary
6. **Memory Management**: Dispose resources in `onDispose()`
7. **Performance**: Profile and optimize hot paths
8. **Documentation**: Document public APIs and usage examples

## 🔌 Plugin Events

Available lifecycle events:

- `onInitialize(context)` - Plugin initialization
- `onFileOpen(file)` - File opened in editor
- `onFileClose(fileId)` - File closed
- `onFileSave(fileId, content)` - File saved
- `onFileContentChange(fileId, content)` - Content changed
- `onFileDelete(fileId)` - File deleted
- `onDispose()` - Plugin disposal

## 🎨 UI Integration

Plugins can define UI descriptors for:
- **Sidebar panels**: Lists, trees, custom widgets
- **Toolbar buttons**: Quick actions
- **Status bar items**: Inline information
- **Context menus**: Right-click actions

## 📝 Testing Plugins

```dart
void main() {
  test('Plugin initialization', () async {
    final plugin = MyPlugin();
    final context = MockPluginContext();

    await plugin.onInitialize(context);

    expect(plugin.isInitialized, true);
  });

  test('Plugin handles events', () {
    final plugin = MyPlugin();
    final file = FileDocument(id: '1', name: 'test.dart', content: '');

    plugin.onFileOpen(file);

    // Assertions
  });
}
```

## 🚀 Future Plugin Ideas

- [x] **Bracket Pair Colorizer** (WASM with tree-sitter) - ✅ Implemented!
- [ ] **Import Organizer** (WASM AST-based)
- [ ] **Code Complexity Analyzer** (WASM)
- [ ] **Duplicate Code Detector** (WASM)
- [ ] **JSON/YAML Formatter** (WASM with serde)
- [ ] **Code Snippets Manager**
- [ ] **Clipboard History**
- [ ] **EditorConfig Support**
- [ ] **Trailing Whitespace Highlighter**
- [ ] **Color Picker for CSS**
- [ ] **Markdown Table Formatter** (WASM)
- [ ] **RegEx Tester & Visualizer**

## 📚 Resources

- [Plugin System Core](packages/flutter_plugin_system_core/)
- [Plugin System WASM](packages/flutter_plugin_system_wasm/)
- [Base Plugin Package](app/modules/plugins/multi_editor_plugin_base/)
- [Plugin Manager](app/modules/multi_editor_plugins/)
