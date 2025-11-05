# Plugin System - Quick Reference

## Plugin Locations

```
modules/plugins/
├── plugin_base/              # Base classes & utilities
│   ├── BaseEditorPlugin     # Abstract base class
│   ├── ConfigurablePlugin   # Mixin for persistence
│   └── StatefulPlugin       # Mixin for state management
├── plugin_auto_save/         # Auto-save functionality
├── plugin_recent_files/      # Recent files tracking
└── plugin_file_stats/        # File statistics display
```

## Core Interfaces Location

```
modules/editor_plugins/lib/src/plugin_api/
├── editor_plugin.dart        # EditorPlugin interface
├── plugin_context.dart       # PluginContext interface
├── plugin_manifest.dart      # Metadata structure
└── language_plugin.dart      # Language support
```

## Registration Location

```
example/lib/
├── main.dart                 # App entry point
├── di/service_locator.dart   # Plugin registration
└── plugins/app_plugin_context.dart  # Context implementation
```

---

## Plugin Quick Checklist

### Creating a Plugin

- [ ] Extend `BaseEditorPlugin`
- [ ] Implement `manifest` getter
- [ ] Implement `onInitialize()` method
- [ ] Implement `onDispose()` method
- [ ] Add event handlers if needed
- [ ] Add optional UI methods
- [ ] Register in `ServiceLocator._initializePlugins()`
- [ ] Export from pubspec.yaml

### Plugin Manifest

```dart
PluginManifest(
  id: 'plugin.unique_id',              // Required: Unique identifier
  name: 'Display Name',                // Required: User-visible name
  version: '0.1.0',                    // Required: Semantic versioning
  description: '...',                  // Optional: What it does
  author: 'Author Name',               // Optional: Creator
  dependencies: [],                    // Optional: Other plugin IDs
  capabilities: {},                    // Optional: Advertised features
  activationEvents: ['onFileOpen'],    // Optional: Trigger events
  metadata: {},                        // Optional: Custom data
)
```

### Event Handlers

```dart
void onFileOpen(FileDocument file)          // File selected
void onFileClose(String fileId)             // Tab closed
void onFileSave(FileDocument file)          // File saved
void onFileContentChange(String fileId, String content)  // Text changed
void onFileCreate(FileDocument file)        // New file created
void onFileDelete(String fileId)            // File deleted
void onFolderCreate(Folder folder)          // New folder
void onFolderDelete(String folderId)        // Folder deleted
```

### UI Building Methods

```dart
Widget? buildToolbarAction(BuildContext context)      // Toolbar button/chip
Widget? buildContextMenuItem(BuildContext context, FileDocument file)  // Right-click
Widget? buildSidebarPanel(BuildContext context)       // Sidebar widget
```

### State Management

**StatefulPlugin** (no persistence):
```dart
setState('key', value);                  // Set state
T? getState<T>('key');                   // Get state
removeState('key');                      // Remove key
ValueListenable<int> stateChanges;       // Listen for changes
```

**ConfigurablePlugin** (persistent):
```dart
loadConfiguration(storage, pluginId);    // Load from storage
getConfigSetting<T>('key');              // Get setting
setConfigSetting('key', value);          // Set and save
updateConfiguration((config) => ...);    // Update entire config
enable() / disable();                    // Toggle enable state
```

---

## Access Plugins

### From ServiceLocator

```dart
final plugin = ServiceLocator.instance.pluginManager
    .getPlugin('plugin.id') as MyPlugin;
```

### Check Status

```dart
if (pluginManager.isPluginActivated('plugin.id')) {
  // Plugin is ready
}
```

### Get All Plugins

```dart
List<PluginManifest> all = pluginManager.allPlugins;
```

### Get Language-Specific Plugins

```dart
List<EditorPlugin> dartPlugins = pluginManager.getPluginsForLanguage('dart');
```

---

## The Three Built-In Plugins

### AutoSavePlugin
- **ID**: `plugin.auto_save`
- **Features**: Auto-saves every 5 seconds (configurable)
- **Configuration**: `AutoSaveConfig` (enabled, interval, notifications)
- **Events**: Tracks `onFileContentChange`, `onFileClose`
- **UI**: None (background only)

**Access**:
```dart
final plugin = pluginManager.getPlugin('plugin.auto_save') as AutoSavePlugin;
await plugin.updateAutoSaveConfig(AutoSaveConfig(
  enabled: true,
  interval: SaveInterval.fromSeconds(10),
));
```

### RecentFilesPlugin
- **ID**: `plugin.recent_files`
- **Features**: Tracks up to 10 recently opened files
- **Data**: `RecentFilesList`, `RecentFileEntry`
- **Events**: Listens to `onFileOpen`, `onFileDelete`
- **UI**: `buildSidebarPanel()` returns `RecentFilesPanel`

**Access**:
```dart
final plugin = pluginManager.getPlugin('plugin.recent_files') as RecentFilesPlugin;
List<RecentFileEntry> recent = plugin.recentFiles;  // Sorted by most recent
plugin.clearRecentFiles();
```

### FileStatsPlugin
- **ID**: `plugin.file_stats`
- **Features**: Calculates lines, characters, words, bytes
- **Data**: `FileStatistics` per file
- **Events**: Listens to `onFileOpen`, `onFileContentChange`, `onFileClose`
- **UI**: `buildToolbarAction()` returns stats chip with icon

**Access**:
```dart
final plugin = pluginManager.getPlugin('plugin.file_stats') as FileStatsPlugin;
FileStatistics? stats = plugin.getStatistics('file-id');
print(stats?.displayText);  // "45 lines, 1023 chars, 182 words"
```

---

## Error Handling

### Safe Execution

```dart
safeExecute('Operation name', () {
  // Your code
  doSomething();
}, onError: (error) {
  // Handle error
  print('Operation failed: $error');
});
```

### Safe Async Execution

```dart
await safeExecuteAsync('Async operation', () async {
  await performAsyncTask();
});
```

### Check Initialization

```dart
if (!isInitialized) {
  throw StateError('Plugin not initialized');
}

final context = this.context;  // Throws if not initialized
```

---

## Plugin Dependencies

Declare required plugins:

```dart
PluginManifest(
  id: 'plugin.my_plugin',
  name: 'My Plugin',
  version: '0.1.0',
  dependencies: ['plugin.auto_save'],  // Requires AutoSavePlugin
)
```

Will auto-activate dependencies. Fails if:
- Dependency not registered
- Dependency fails to initialize
- Circular dependency detected

---

## Storage Options

### SharedPreferences (Persistent)
```dart
await loadConfiguration(
  SharedPreferencesStorageAdapter(),
  PluginId(value: manifest.id),
);
```

### In-Memory (Session Only)
```dart
await loadConfiguration(
  InMemoryStorageAdapter(),
  PluginId(value: manifest.id),
);
```

---

## Best Practices

1. **Always implement `onDispose()`** - Clean up resources
2. **Use `safeExecute()` / `safeExecuteAsync()`** - Prevents crashes
3. **Call `disposeStateful()`** - When using StatefulPlugin mixin
4. **Validate configuration on load** - Handle missing/corrupt data
5. **Keep operations idempotent** - Safe to call multiple times
6. **Use descriptive manifest fields** - Help users understand plugin
7. **Log important events** - Use debugPrint with plugin name
8. **Handle file deletion** - Remove associated data

---

## Common Patterns

### Track File Content
```dart
final Map<String, String> _fileContents = {};

@override
void onFileContentChange(String fileId, String content) {
  safeExecute('Track content', () {
    _fileContents[fileId] = content;
    setState('lastModified', DateTime.now());
  });
}

@override
void onFileClose(String fileId) {
  _fileContents.remove(fileId);
}
```

### Periodic Task
```dart
Timer? _timer;

@override
Future<void> onInitialize(PluginContext context) async {
  _timer = Timer.periodic(Duration(seconds: 5), (_) => _doWork());
}

@override
Future<void> onDispose() async {
  _timer?.cancel();
  _timer = null;
}

Future<void> _doWork() async {
  await safeExecuteAsync('Do work', () async {
    // Perform work
  });
}
```

### Configuration UI
```dart
@override
Widget? buildToolbarAction(BuildContext context) {
  return IconButton(
    icon: const Icon(Icons.settings),
    onPressed: () => _showSettings(context),
  );
}

void _showSettings(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Settings UI
        ],
      ),
    ),
  );
}
```

---

## Testing Plugins

### Mock Setup
```dart
final mockContext = MockPluginContext();
final plugin = MyPlugin();

await plugin.initialize(mockContext);

// Simulate events
plugin.onFileOpen(mockFileDocument);
plugin.onFileContentChange('file-id', 'new content');

// Assert state changes
expect(plugin.getState('key'), equals(expected));

await plugin.dispose();
```

### Common Test Cases
- [ ] Plugin initializes successfully
- [ ] Plugin handles events correctly
- [ ] Plugin saves/loads configuration
- [ ] Plugin cleans up on dispose
- [ ] Plugin handles errors gracefully
- [ ] Plugin respects enable/disable state

---

## Debugging

### Check Plugin State
```dart
final plugin = pluginManager.getPlugin('plugin.id');
if (plugin is BaseEditorPlugin) {
  print('State: ${plugin.state.value}');
  print('Initialized: ${plugin.isInitialized}');
}
```

### Monitor Event Flow
```dart
context.events.on<FileOpened>().listen((event) {
  debugPrint('[${manifest.name}] File opened: ${event.file.name}');
});
```

### Verify Configuration
```dart
if (hasConfiguration) {
  var config = configuration;
  debugPrint('Config: ${config.toJson()}');
}
```

---

## UI Integration Status

### Currently Implemented
- ✅ Plugin registration system
- ✅ Event subscription and dispatch
- ✅ State and configuration management
- ✅ Lifecycle hooks (init, dispose)

### UI Methods Available (Not Yet Integrated)
- ⚠️ `buildToolbarAction()` - Defined but not rendered in UI
- ⚠️ `buildContextMenuItem()` - Defined but not rendered in UI
- ⚠️ `buildSidebarPanel()` - Defined but not rendered in UI

### Future Enhancement
The EditorScaffold component will be updated to render plugin UI elements when these features are integrated.

---

## Performance Tips

1. **Lazy Load Data** - Only compute when needed
2. **Debounce Events** - Don't process every keystroke
3. **Cancel Tasks on Close** - Free resources immediately
4. **Use Weak References** - Prevent memory leaks
5. **Batch Updates** - Combine state changes

---

## Version Compatibility

- **Dart**: ^3.7.0+
- **Flutter**: Latest stable
- **Freezed**: ^3.1.0+
- **Plugin Base**: 0.1.0

All plugins use semantic versioning.

---

## Support & Resources

- **Architecture**: Clean Architecture + DDD
- **State Management**: ValueNotifier + Freezed
- **Data Persistence**: SharedPreferences adapter
- **Testing**: mockito with Dart test framework
- **Documentation**: Comprehensive in source code

