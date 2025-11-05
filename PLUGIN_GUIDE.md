# Multi-File Code Editor - Plugin System Guide

## Overview

The multi-file code editor has a comprehensive plugin system built on Clean Architecture and Domain-Driven Design principles. The system allows you to extend the editor's functionality without modifying core code.

### Architecture Layers

- **Plugin API** (`editor_plugins`): Core interfaces and abstractions
- **Plugin Base** (`plugin_base`): Reusable base classes and utilities
- **Concrete Plugins**: Implementation of specific features
- **Editor UI** (`editor_ui`): UI rendering components

---

## Plugin System Architecture

### Core Components

#### 1. EditorPlugin Interface
**Location**: `modules/editor_plugins/lib/src/plugin_api/editor_plugin.dart`

Every plugin extends `EditorPlugin` and must implement:

```dart
abstract class EditorPlugin {
  PluginManifest get manifest;  // Plugin metadata
  Future<void> initialize(PluginContext context);  // Initialize plugin
  Future<void> dispose();  // Cleanup resources
  
  // Lifecycle hooks
  void onFileOpen(FileDocument file) {}
  void onFileClose(String fileId) {}
  void onFileSave(FileDocument file) {}
  void onFileContentChange(String fileId, String content) {}
  void onFileCreate(FileDocument file) {}
  void onFileDelete(String fileId) {}
  void onFolderCreate(Folder folder) {}
  void onFolderDelete(String folderId) {}
  
  // UI Building Methods
  Widget? buildToolbarAction(BuildContext context) => null;
  Widget? buildContextMenuItem(BuildContext context, FileDocument file) => null;
  Widget? buildSidebarPanel(BuildContext context) => null;
  
  // Language Support
  List<String> getSupportedLanguages() => [];
  bool supportsLanguage(String language) => true;
}
```

#### 2. PluginContext
**Location**: `modules/editor_plugins/lib/src/plugin_api/plugin_context.dart`

Provides plugins access to editor services:

```dart
abstract class PluginContext {
  CommandBus get commands;           // Command execution
  EventBus get events;               // Event broadcasting
  HookRegistry get hooks;            // Hook management
  
  FileRepository get fileRepository;
  FolderRepository get folderRepository;
  ProjectRepository get projectRepository;
  ValidationService get validationService;
  LanguageDetector get languageDetector;
  
  Map<String, dynamic> getConfiguration(String key);
  void setConfiguration(String key, Map<String, dynamic> value);
  T? getService<T extends Object>();
  void registerService<T extends Object>(T service);
}
```

#### 3. PluginManifest
Metadata about the plugin:

```dart
const factory PluginManifest({
  required String id,                    // Unique identifier
  required String name,                  // Display name
  required String version,               // Semantic version
  String? description,                   // What it does
  String? author,                        // Creator
  @Default([]) List<String> dependencies,         // Required plugins
  @Default({}) Map<String, String> capabilities, // Advertised features
  @Default([]) List<String> activationEvents,    // Triggers
  @Default({}) Map<String, dynamic> metadata,    // Custom data
})
```

#### 4. PluginState Lifecycle
**Enum States**:
- `uninitialized`: Created but not initialized
- `initializing`: Currently initializing
- `ready`: Fully functional
- `error`: Failed during initialization
- `disposed`: Cleaned up and inactive

---

## Base Plugin Class

**Location**: `modules/plugins/plugin_base/`

`BaseEditorPlugin` provides essential functionality:

```dart
abstract class BaseEditorPlugin extends EditorPlugin {
  final ValueNotifier<PluginState> state = ValueNotifier(PluginState.uninitialized);
  PluginContext get context;  // Throws if not initialized
  bool get isInitialized => state.value.isReady;
  
  Future<void> initialize(PluginContext context) async;
  Future<void> dispose() async;
  
  @protected
  Future<void> onInitialize(PluginContext context);
  
  @protected
  Future<void> onDispose();
  
  @protected
  void safeExecute(String operation, void Function() action);
  
  @protected
  Future<void> safeExecuteAsync(String operation, Future<void> Function() action);
}
```

### Mixins for Extended Functionality

#### ConfigurablePlugin
Manage plugin configuration with persistence:

```dart
mixin ConfigurablePlugin on EditorPlugin {
  Future<void> loadConfiguration(PluginStoragePort storage, PluginId pluginId);
  Future<void> saveConfiguration();
  Future<void> updateConfiguration(PluginConfiguration Function(PluginConfiguration) update);
  
  T? getConfigSetting<T>(String key, {T? defaultValue});
  Future<void> setConfigSetting(String key, dynamic value);
  
  bool get isEnabled;
  Future<void> enable();
  Future<void> disable();
}
```

#### StatefulPlugin
Manage plugin state without persistence:

```dart
mixin StatefulPlugin {
  ValueListenable<int> get stateChanges;  // Listen for changes
  T? getState<T>(String key);
  void setState(String key, dynamic value);
  void removeState(String key);
  void clearState();
  bool hasState(String key);
  Map<String, dynamic> getAllState();
  void disposeStateful();
}
```

---

## Plugin Manager

**Location**: `modules/editor_plugins/lib/src/plugin_manager/plugin_manager.dart`

Handles plugin registration and lifecycle:

```dart
class PluginManager {
  Future<void> registerPlugin(EditorPlugin plugin);
  Future<void> unregisterPlugin(String pluginId);
  
  EditorPlugin? getPlugin(String pluginId);
  bool isPluginRegistered(String pluginId);
  bool isPluginActivated(String pluginId);
  
  List<PluginManifest> get allPlugins;
  List<EditorPlugin> getPluginsForLanguage(String language);
  
  Future<void> disposeAll();
}
```

---

## Existing Plugins

### 1. AutoSavePlugin

**Location**: `/modules/plugins/plugin_auto_save/`

Automatically saves file changes at configurable intervals.

#### Features
- Configurable save interval (1-60 seconds)
- Auto-save on content change
- Idle detection option
- Notification support

#### Configuration
```dart
const factory AutoSaveConfig({
  required bool enabled,
  required SaveInterval interval,
  @Default(false) bool onlyWhenIdle,
  @Default(true) bool showNotifications,
})

factory AutoSaveConfig.defaultConfig() => AutoSaveConfig(
  enabled: true,
  interval: SaveInterval.defaultInterval(),  // 5 seconds
  onlyWhenIdle: false,
  showNotifications: true,
);
```

#### Usage Example
```dart
// Get the plugin from service locator
final autoSavePlugin = ServiceLocator.instance.pluginManager
    .getPlugin('plugin.auto_save') as AutoSavePlugin;

// Update configuration
await autoSavePlugin.updateAutoSaveConfig(
  AutoSaveConfig(
    enabled: true,
    interval: SaveInterval.fromSeconds(10),
    onlyWhenIdle: false,
    showNotifications: true,
  ),
);

// Enable/disable
await autoSavePlugin.enable();
await autoSavePlugin.disable();
```

#### Manifest
```dart
PluginManifest(
  id: 'plugin.auto_save',
  name: 'Auto Save',
  version: '0.1.0',
  description: 'Automatically saves file changes at configurable intervals',
  author: 'Editor Team',
  capabilities: {
    'file.save': 'Automatically saves files',
    'config.interval': 'Configurable save interval',
  },
  activationEvents: ['onFileOpen', 'onFileContentChange'],
)
```

#### Activation & Events
Triggered by:
- `onFileOpen`: File opened, auto-save interval timer starts
- `onFileContentChange`: Tracks unsaved content
- `onFileClose`: Cleans up tracked content

#### Implementation Details
- Uses `Timer.periodic()` for interval-based saving
- Tracks unsaved content per file
- `_triggerSaveUseCase` handles actual save operations
- Non-blocking - failures continue with next file

---

### 2. RecentFilesPlugin

**Location**: `/modules/plugins/plugin_recent_files/`

Tracks and displays recently opened files.

#### Features
- Maintains up to 10 recent files (configurable)
- Displays in sidebar panel
- Automatic removal when files deleted
- Time-based ordering (most recent first)

#### Data Structures
```dart
const factory RecentFileEntry({
  required String fileId,
  required String fileName,
  required String filePath,
  required DateTime lastOpened,
})

factory RecentFileEntry.create({
  required String fileId,
  required String fileName,
  required String filePath,
}) // Auto-sets lastOpened to now
```

```dart
const factory RecentFilesList({
  @Default([]) List<RecentFileEntry> entries,
  @Default(10) int maxEntries,
})

factory RecentFilesList.create({int maxEntries = 10}) // Validates 1-50
```

#### Usage Example
```dart
final recentFilesPlugin = ServiceLocator.instance.pluginManager
    .getPlugin('plugin.recent_files') as RecentFilesPlugin;

// Get list of recent files
List<RecentFileEntry> recent = recentFilesPlugin.recentFiles;

// Clear recent files
recentFilesPlugin.clearRecentFiles();

// Each entry contains:
// - fileId: Unique file identifier
// - fileName: Display name
// - filePath: Full path
// - lastOpened: When file was last opened
```

#### UI Component
Provides `RecentFilesPanel` - a `ListView` showing:
- File icon
- File name
- File path
- Tap to open

```dart
// From RecentFilesPlugin.buildSidebarPanel():
@override
Widget? buildSidebarPanel(BuildContext context) {
  return RecentFilesPanel(
    recentFiles: _recentFiles,
    onFileSelected: (entry) {
      context.findAncestorStateOfType<NavigatorState>()?.pop();
    },
  );
}
```

#### Manifest
```dart
PluginManifest(
  id: 'plugin.recent_files',
  name: 'Recent Files',
  version: '0.1.0',
  description: 'Tracks and displays recently opened files',
  author: 'Editor Team',
  activationEvents: ['onFileOpen'],
)
```

#### Lifecycle Hooks
- `onFileOpen()`: Adds file to recent list (moves to top if already exists)
- `onFileDelete()`: Removes from recent list
- `onInitialize()`: Creates empty recent files list
- `onDispose()`: Cleans up state

---

### 3. FileStatsPlugin

**Location**: `/modules/plugins/plugin_file_stats/`

Displays file metrics and statistics.

#### Features
- Calculates lines, characters, words, bytes
- Shows stats in toolbar (chip with icon)
- Real-time updates on content change
- Per-file tracking

#### Data Structure
```dart
const factory FileStatistics({
  required String fileId,
  required int lines,
  required int characters,
  required int words,
  required int bytes,
  required DateTime calculatedAt,
})

factory FileStatistics.calculate(String fileId, String content) {
  // Lines: split by '\n'
  // Characters: content.length
  // Words: split by whitespace regex
  // Bytes: content length
}

// Display: "45 lines, 1023 chars, 182 words"
```

#### Usage Example
```dart
final statsPlugin = ServiceLocator.instance.pluginManager
    .getPlugin('plugin.file_stats') as FileStatsPlugin;

// Get stats for current file
final stats = statsPlugin.getStatistics('file-id-123');
if (stats != null) {
  print('${stats.lines} lines, ${stats.characters} chars');
}

// Get all statistics
Map<String, FileStatistics> allStats = statsPlugin.allStatistics;
```

#### UI Component
Provides toolbar action (chip):
```
📊 45 lines, 1023 chars, 182 words
```

```dart
// From FileStatsPlugin.buildToolbarAction():
Tooltip(
  message: 'File Statistics',
  child: Chip(
    avatar: const Icon(Icons.analytics, size: 16),
    label: Text(stats.displayText),
  ),
)
```

#### Manifest
```dart
PluginManifest(
  id: 'plugin.file_stats',
  name: 'File Statistics',
  version: '0.1.0',
  description: 'Displays file metrics (lines, characters, words, size)',
  author: 'Editor Team',
  activationEvents: ['onFileOpen', 'onFileContentChange'],
)
```

#### Lifecycle Hooks
- `onFileOpen()`: Calculates initial statistics
- `onFileContentChange()`: Updates statistics in real-time
- `onFileClose()`: Clears cached statistics
- `onInitialize()`: Creates empty statistics map
- `onDispose()`: Cleans up state

---

## Plugin Registration

**Location**: `/example/lib/di/service_locator.dart`

Plugins are registered during app initialization:

```dart
Future<void> _initializePlugins() async {
  final pluginContext = AppPluginContext(
    fileRepository: fileRepository,
    folderRepository: folderRepository,
    eventBus: eventBus,
  );

  pluginManager = PluginManager(pluginContext);

  // Register plugins in order
  await pluginManager.registerPlugin(AutoSavePlugin());
  await pluginManager.registerPlugin(RecentFilesPlugin());
  await pluginManager.registerPlugin(FileStatsPlugin());
  await pluginManager.registerPlugin(DartLanguagePlugin());
}
```

### Registration Process
1. Plugin manifest is validated
2. Dependencies are checked (must be registered first)
3. `plugin.initialize(context)` is called
4. Event subscriptions are created
5. Plugin is marked as activated

---

## Plugin Context Implementation

**Location**: `/example/lib/plugins/app_plugin_context.dart`

`AppPluginContext` is the concrete implementation of `PluginContext`:

```dart
class AppPluginContext implements PluginContext {
  final FileRepository _fileRepository;
  final FolderRepository _folderRepository;
  final EventBus _eventBus;
  final CommandBus _commandBus;
  final HookRegistry _hookRegistry;
  final Map<String, dynamic> _configuration = {};
  final Map<Type, Object> _services = {};
  
  // Provides access to repositories, event bus, and storage
}
```

---

## Plugin Lifecycle

### 1. Creation
```dart
final plugin = AutoSavePlugin();
```

### 2. Registration
```dart
await pluginManager.registerPlugin(plugin);
```

This triggers:
- Dependency validation
- `plugin.initialize(context)` call
- Event subscription setup
- State transition to `ready`

### 3. Activation
```dart
// Triggered automatically during registration if dependencies met
plugin.onInitialize(context);  // Custom initialization
```

### 4. Runtime
Plugin responds to events:
```dart
onFileOpen()          // File opened
onFileSave()          // File saved
onFileContentChange() // Content changed
onFileClose()         // File closed
onFileDelete()        // File deleted
onFolderCreate()      // Folder created
onFolderDelete()      // Folder deleted
```

### 5. Unregistration
```dart
await pluginManager.unregisterPlugin('plugin.id');
```

This triggers:
- Dependency checks (fails if other plugins depend on it)
- `plugin.dispose()` call
- State transition to `disposed`
- Resource cleanup

### 6. Cleanup
```dart
await pluginManager.disposeAll();  // Called on app shutdown
```

---

## Event System

Events are published by the editor core and received by plugins:

**Available Events**:
- `FileOpened`: File selected/opened
- `FileClosed`: File tab closed
- `FileSaved`: File saved to disk
- `FileContentChanged`: Editor content changed
- `FileCreated`: New file created
- `FileDeleted`: File deleted
- `FolderCreated`: New folder created
- `FolderDeleted`: Folder deleted

**Listening to Events**:
```dart
@override
Future<void> onInitialize(PluginContext context) async {
  context.events.on<FileOpened>().listen((event) {
    // event.file contains FileDocument
    onFileOpen(event.file);
  });
}
```

---

## UI Integration Points

### 1. Toolbar Actions
```dart
Widget? buildToolbarAction(BuildContext context) {
  return Chip(label: Text('My Action'));
}
```

Currently used by: **FileStatsPlugin**

### 2. Context Menu Items
```dart
Widget? buildContextMenuItem(BuildContext context, FileDocument file) {
  return ListTile(label: Text('My Menu Item'));
}
```

Not currently used by any plugin.

### 3. Sidebar Panel
```dart
Widget? buildSidebarPanel(BuildContext context) {
  return Container(child: Text('My Panel'));
}
```

Currently used by: **RecentFilesPlugin**

### Current UI Rendering Status
⚠️ **Note**: Plugin UI elements (`buildToolbarAction`, `buildContextMenuItem`, `buildSidebarPanel`) are **NOT currently rendered** in the editor scaffold. They are defined but not integrated into the UI layer yet.

**EditorScaffold Location**: `/modules/editor_ui/lib/src/widgets/scaffold/editor_scaffold.dart`

The scaffold provides header and footer customization but does not render plugin-specific UI elements. This would be a future enhancement to fully integrate plugins with the UI.

---

## Creating a Custom Plugin

### Step 1: Extend BaseEditorPlugin

```dart
import 'package:plugin_base/plugin_base.dart';
import 'package:editor_plugins/editor_plugins.dart';

class MyCustomPlugin extends BaseEditorPlugin with StatefulPlugin {
  @override
  PluginManifest get manifest => const PluginManifest(
    id: 'plugin.my_custom',
    name: 'My Custom Plugin',
    version: '0.1.0',
    description: 'Does something cool',
    author: 'Your Name',
    activationEvents: ['onFileOpen'],
  );

  @override
  Future<void> onInitialize(PluginContext context) async {
    // Initialize your plugin
    setState('initialized', true);
  }

  @override
  Future<void> onDispose() async {
    // Clean up resources
    disposeStateful();
  }

  @override
  void onFileOpen(FileDocument file) {
    // Handle file open event
    setState('lastOpenedFile', file.id);
  }
}
```

### Step 2: Register in ServiceLocator

```dart
Future<void> _initializePlugins() async {
  // ... existing code ...
  
  await pluginManager.registerPlugin(MyCustomPlugin());
}
```

### Step 3: Access from Anywhere

```dart
final myPlugin = ServiceLocator.instance.pluginManager
    .getPlugin('plugin.my_custom') as MyCustomPlugin;

// Access state
String? lastFileId = myPlugin.getState<String>('lastOpenedFile');
```

---

## Configuration & Persistence

Plugins using `ConfigurablePlugin` can persist settings:

```dart
class MyConfigurablePlugin extends BaseEditorPlugin with ConfigurablePlugin {
  @override
  Future<void> onInitialize(PluginContext context) async {
    // Load configuration from storage
    await loadConfiguration(
      SharedPreferencesStorageAdapter(),  // or InMemoryStorageAdapter()
      PluginId(value: manifest.id),
    );
    
    // Get existing settings or create defaults
    var config = getConfigSetting<String>('theme') ?? 'dark';
  }
  
  // Update a single setting
  Future<void> setTheme(String theme) async {
    await setConfigSetting('theme', theme);
  }
  
  // Update entire configuration
  Future<void> updateConfig(MyConfig newConfig) async {
    await updateConfiguration((_) => newConfig);
  }
}
```

**Storage Adapters**:
- `SharedPreferencesStorageAdapter()`: Persistent storage
- `InMemoryStorageAdapter()`: Session-only storage

---

## Best Practices

### 1. Always Use safeExecute()
```dart
@override
void onFileOpen(FileDocument file) {
  safeExecute('Handle file open', () {
    // Your logic here
  }, onError: (e) {
    debugPrint('Error: $e');
  });
}
```

### 2. Check Plugin State
```dart
if (!isInitialized) {
  throw StateError('Plugin not initialized');
}
```

### 3. Use Manifest Metadata
```dart
const factory PluginManifest({
  // ...
  @Default({}) Map<String, dynamic> metadata,
})

// Store custom data
metadata: {
  'settingsPage': 'routes/settings',
  'hotkey': 'Ctrl+Shift+P',
}
```

### 4. Implement Language Support
```dart
@override
List<String> getSupportedLanguages() => ['dart', 'flutter'];
```

### 5. Clean Up Resources
```dart
@override
Future<void> onDispose() async {
  // Cancel timers, streams, etc.
  _timer?.cancel();
  _subscription?.cancel();
  disposeStateful();
}
```

### 6. Handle Dependencies
```dart
const factory PluginManifest({
  // ...
  @Default([]) List<String> dependencies,  // Other plugin IDs required
})
```

---

## Dependencies & Versions

**Current Stack**:
- Dart: ^3.7.0
- Flutter: Latest stable
- freezed: ^3.1.0
- freezed_annotation: ^3.1.0
- json_annotation: ^4.9.0

All plugins follow Clean Architecture and DDD patterns using Freezed for immutable data classes.

---

## Troubleshooting

### Plugin Not Registering
- Check dependencies are registered first
- Verify manifest ID is unique
- Check for `PluginException` messages

### State Not Persisting
- Use `ConfigurablePlugin` mixin + storage adapter
- Call `saveConfiguration()` after updates
- Check storage adapter initialization

### Events Not Firing
- Verify plugin is in `ready` state
- Check event bus is properly initialized
- Ensure `onInitialize()` subscribed to events

### Memory Leaks
- Always dispose timers/streams in `onDispose()`
- Call `disposeStateful()` for state cleanup
- Remove event listeners if needed

---

## API Reference

### File Document
```dart
class FileDocument {
  String id;
  String name;
  String language;
  String content;
  DateTime createdAt;
  DateTime modifiedAt;
  String? folderId;
}
```

### Folder
```dart
class Folder {
  String id;
  String name;
  String? parentId;
  DateTime createdAt;
}
```

### Save Interval
```dart
factory SaveInterval.fromSeconds(int seconds) {
  // Validates 1-60 seconds
}
Duration get duration => Duration(seconds: seconds);
```

---

## Summary

The plugin system provides a powerful, extensible architecture for adding features to the editor:

1. **Three Existing Plugins**:
   - AutoSavePlugin: Automatic file saving
   - RecentFilesPlugin: Recently opened files tracking
   - FileStatsPlugin: File metrics display

2. **Three Extension Points**:
   - `buildToolbarAction()`: Toolbar buttons
   - `buildContextMenuItem()`: Right-click menu
   - `buildSidebarPanel()`: Sidebar widget

3. **Two State Management Patterns**:
   - `StatefulPlugin`: Session-only state
   - `ConfigurablePlugin`: Persistent configuration

4. **Event-Driven Architecture**:
   - 8 file/folder lifecycle events
   - Event subscription during initialization

5. **Clean Architecture**:
   - Separated concerns (domain, application, infrastructure)
   - Type-safe with Freezed
   - Testable with dependency injection

---

## Example: Complete Plugin Implementation

```dart
// my_stats_plugin.dart
import 'package:plugin_base/plugin_base.dart';
import 'package:editor_plugins/editor_plugins.dart';
import 'package:flutter/material.dart';

class MyStatsPlugin extends BaseEditorPlugin with StatefulPlugin {
  final Map<String, int> _lineCount = {};

  @override
  PluginManifest get manifest => const PluginManifest(
    id: 'plugin.my_stats',
    name: 'My Statistics',
    version: '0.1.0',
    description: 'Custom statistics plugin',
  );

  @override
  Future<void> onInitialize(PluginContext context) async {
    setState('stats', _lineCount);
  }

  @override
  Future<void> onDispose() async {
    disposeStateful();
  }

  @override
  void onFileOpen(FileDocument file) {
    safeExecute('Calculate lines', () {
      final lines = file.content.split('\n').length;
      _lineCount[file.id] = lines;
      setState('stats', _lineCount);
    });
  }

  @override
  void onFileClose(String fileId) {
    _lineCount.remove(fileId);
    setState('stats', _lineCount);
  }

  @override
  Widget? buildToolbarAction(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: stateChanges,
      builder: (context, _, __) {
        return Text('Custom Plugin Active');
      },
    );
  }
}
```

Register and use:
```dart
await pluginManager.registerPlugin(MyStatsPlugin());

final plugin = pluginManager.getPlugin('plugin.my_stats') as MyStatsPlugin;
var stats = plugin.getState<Map<String, int>>('stats');
```

---

**Last Updated**: 2024
**Status**: Complete Plugin System Foundation
