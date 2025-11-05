# Plugin System - Architecture & Examples

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Application Layer                        │
│                     (example/lib/main.dart)                      │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Service Locator                           │
│              (example/lib/di/service_locator.dart)              │
│                                                                  │
│  • Creates PluginManager                                        │
│  • Registers all plugins                                        │
│  • Manages plugin lifecycle                                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│                      Plugin Manager                              │
│   (modules/editor_plugins/lib/src/plugin_manager/)              │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ registerPlugin(plugin)                                  │  │
│  │ • Validate manifest                                     │  │
│  │ • Check dependencies                                    │  │
│  │ • Call initialize()                                     │  │
│  │ • Subscribe to events                                   │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                   ┌─────────┴─────────┐
                   │                   │
                   ▼                   ▼
        ┌──────────────────┐  ┌──────────────────┐
        │  PluginContext   │  │  EventBus        │
        │                  │  │                  │
        │ • fileRepository │  │ • Publishes:     │
        │ • eventBus       │  │   - FileOpened   │
        │ • commands       │  │   - FileSaved    │
        │ • hooks          │  │   - FileDeleted  │
        │ • services       │  │   etc.           │
        └──────────────────┘  └──────────────────┘
                   │
                   └────────┬────────┐
                            │        │
                            ▼        ▼
        ┌────────────────────────────────────────┐
        │          Active Plugins                │
        │                                        │
        │ ┌─────────────────────────────────┐   │
        │ │  AutoSavePlugin                 │   │
        │ │  └─ Tracks changes              │   │
        │ │  └─ Saves periodically          │   │
        │ └─────────────────────────────────┘   │
        │ ┌─────────────────────────────────┐   │
        │ │  RecentFilesPlugin              │   │
        │ │  └─ Builds sidebar panel        │   │
        │ │  └─ Tracks recent files         │   │
        │ └─────────────────────────────────┘   │
        │ ┌─────────────────────────────────┐   │
        │ │  FileStatsPlugin                │   │
        │ │  └─ Builds toolbar action       │   │
        │ │  └─ Calculates statistics       │   │
        │ └─────────────────────────────────┘   │
        │                                        │
        │ + Custom plugins...                    │
        └────────────────────────────────────────┘
```

## Plugin Inheritance Hierarchy

```
EditorPlugin (interface)
    │
    └── BaseEditorPlugin (abstract)
            │
            ├── + ConfigurablePlugin (mixin)
            │       • Configuration management
            │       • Persistence
            │
            ├── + StatefulPlugin (mixin)
            │       • Session state
            │       • Change notifications
            │
            └── Concrete Implementations
                ├── AutoSavePlugin
                ├── RecentFilesPlugin
                ├── FileStatsPlugin
                ├── DartLanguagePlugin
                └── YourCustomPlugin
```

## Event Flow Diagram

```
File System Event
    │
    ▼
EventBus.emit(FileOpened)
    │
    ├─→ Plugin1.onFileOpen()
    ├─→ Plugin2.onFileOpen()
    ├─→ Plugin3.onFileOpen()
    │   └─→ setState() [triggers stateChanges listener]
    │
    ▼ (for each plugin that implements buildSidebarPanel)
    
UI Updates [Future - not yet integrated]
```

## State Lifecycle

```
┌──────────────┐
│ uninitialized│  ◄── Plugin created
└──────┬───────┘
       │ registerPlugin()
       ▼
┌──────────────┐
│ initializing │  ◄── initialize() called
└──────┬───────┘
       │ onInitialize() completes
       ▼
┌──────────────┐
│    ready     │  ◄── Plugin functional
└──────┬───────┘     Can use context
       │ (error)     Can publish state
       ▼
   ┌──────────┐
   │  error   │  ◄── Initialization failed
   └──────┬───┘
          │ (retry: registerPlugin again)
          └─→ (can attempt recover)
       
       │ dispose()
       ▼
   ┌──────────┐
   │ disposed │  ◄── Cleanup complete
   └──────────┘     Resources freed
```

## Data Flow: File Changes

```
User edits code in Monaco Editor
    │
    ▼
EditorController.updateContent(newContent)
    │
    ▼
eventBus.emit(FileContentChanged)
    │
    ├─→ AutoSavePlugin.onFileContentChange()
    │       └─→ Tracks unsaved content
    │       └─→ Updates state
    │
    └─→ FileStatsPlugin.onFileContentChange()
            └─→ Recalculates statistics
            └─→ Updates state
            └─→ buildToolbarAction() will refresh
```

## Configuration Persistence Flow

```
PluginConfiguration
    │
    ├─ pluginId: PluginId
    ├─ enabled: bool
    ├─ settings: Map<String, dynamic>
    └─ lastModified: DateTime
    │
    ▼
JSON Serialization (via Freezed)
    │
    ▼
Storage Adapter
    ├─ SharedPreferencesStorageAdapter [Persistent]
    └─ InMemoryStorageAdapter [Session-only]
    │
    ▼
loadConfiguration() ◄─→ saveConfiguration()
    │                        │
    ▼                        ▼
_configuration  ◄─→  UpdateSetting()
    │
    ▼
getConfigSetting() / setConfigSetting()
```

---

## Code Examples

### Example 1: Simple Timer Plugin

```dart
// timer_plugin.dart
import 'dart:async';
import 'package:plugin_base/plugin_base.dart';
import 'package:editor_plugins/editor_plugins.dart';

class TimerPlugin extends BaseEditorPlugin with StatefulPlugin {
  Timer? _timer;
  
  @override
  PluginManifest get manifest => const PluginManifest(
    id: 'plugin.timer',
    name: 'Timer',
    version: '0.1.0',
    description: 'Tracks time spent editing each file',
    author: 'Developer',
    activationEvents: ['onFileOpen'],
  );

  @override
  Future<void> onInitialize(PluginContext context) async {
    // Start a timer that updates state every second
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      final elapsed = getState<Duration>('elapsed') ?? Duration.zero;
      setState('elapsed', elapsed + Duration(seconds: 1));
    });
  }

  @override
  Future<void> onDispose() async {
    _timer?.cancel();
    disposeStateful();
  }

  @override
  void onFileOpen(FileDocument file) {
    setState('currentFile', file.id);
    setState('elapsed', Duration.zero);
  }

  @override
  void onFileClose(String fileId) {
    final elapsed = getState<Duration>('elapsed') ?? Duration.zero;
    debugPrint('File $fileId: Edited for ${elapsed.inSeconds}s');
    clearState();
  }

  Duration? getElapsedTime() => getState<Duration>('elapsed');
}
```

### Example 2: Configuration Plugin

```dart
// theme_plugin.dart
import 'package:plugin_base/plugin_base.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:editor_plugins/editor_plugins.dart';

part 'theme_config.freezed.dart';
part 'theme_config.g.dart';

@freezed
sealed class ThemeConfig with _$ThemeConfig {
  const ThemeConfig._();
  
  const factory ThemeConfig({
    required String theme,  // 'light', 'dark', 'auto'
    required int fontSize,
    @Default(true) bool showMinimap,
  }) = _ThemeConfig;
  
  factory ThemeConfig.fromJson(Map<String, dynamic> json) =>
      _$ThemeConfigFromJson(json);
}

class ThemePlugin extends BaseEditorPlugin with ConfigurablePlugin {
  @override
  PluginManifest get manifest => const PluginManifest(
    id: 'plugin.theme',
    name: 'Theme Manager',
    version: '0.1.0',
    description: 'Manage editor theme and appearance',
  );

  @override
  Future<void> onInitialize(PluginContext context) async {
    // Load from persistent storage
    await loadConfiguration(
      SharedPreferencesStorageAdapter(),
      PluginId(value: manifest.id),
    );

    // Set default if first time
    if (!hasConfiguration) {
      final defaultConfig = ThemeConfig(
        theme: 'dark',
        fontSize: 14,
        showMinimap: true,
      );
      await setConfigSetting('theme', defaultConfig.toJson());
    }
  }

  @override
  Future<void> onDispose() async {
    // Configuration is auto-saved
  }

  Future<void> setTheme(String theme) async {
    await setConfigSetting('theme', theme);
  }

  String getTheme() => getConfigSetting<String>('theme') ?? 'dark';
}
```

### Example 3: File Analysis Plugin

```dart
// metrics_plugin.dart
import 'package:plugin_base/plugin_base.dart';
import 'package:editor_plugins/editor_plugins.dart';

class FileMetrics {
  final String fileId;
  final int lines;
  final int complexity;  // Mock complexity score
  final DateTime analyzedAt;

  FileMetrics({
    required this.fileId,
    required this.lines,
    required this.complexity,
    required this.analyzedAt,
  });

  factory FileMetrics.analyze(FileDocument file) {
    final lines = file.content.split('\n').length;
    final complexity = _calculateComplexity(file.content);
    return FileMetrics(
      fileId: file.id,
      lines: lines,
      complexity: complexity,
      analyzedAt: DateTime.now(),
    );
  }

  static int _calculateComplexity(String content) {
    // Simple mock: count control structures
    int count = 0;
    count += RegExp(r'\bif\b').allMatches(content).length;
    count += RegExp(r'\bfor\b').allMatches(content).length;
    count += RegExp(r'\bwhile\b').allMatches(content).length;
    count += RegExp(r'\bswitch\b').allMatches(content).length;
    return count;
  }

  bool get isComplex => complexity > 10;
}

class MetricsPlugin extends BaseEditorPlugin with StatefulPlugin {
  final Map<String, FileMetrics> _metrics = {};

  @override
  PluginManifest get manifest => const PluginManifest(
    id: 'plugin.metrics',
    name: 'File Metrics',
    version: '0.1.0',
    description: 'Analyze file metrics and complexity',
  );

  @override
  Future<void> onInitialize(PluginContext context) async {
    setState('metrics', _metrics);
  }

  @override
  Future<void> onDispose() async {
    disposeStateful();
  }

  @override
  void onFileOpen(FileDocument file) {
    safeExecute('Analyze file', () {
      final metrics = FileMetrics.analyze(file);
      _metrics[file.id] = metrics;
      setState('metrics', _metrics);

      if (metrics.isComplex) {
        debugPrint('[${manifest.name}] File ${file.name} is complex');
      }
    });
  }

  @override
  void onFileContentChange(String fileId, String content) {
    safeExecute('Update metrics', () {
      // Could trigger re-analysis, but debounce for performance
      // For now, just mark as stale
      setState('needsReanalysis', fileId);
    });
  }

  FileMetrics? getMetrics(String fileId) => _metrics[fileId];
  
  Map<String, FileMetrics> getAllMetrics() => 
      Map<String, FileMetrics>.from(_metrics);
}
```

### Example 4: Event-Listening Plugin

```dart
// audit_plugin.dart
import 'package:plugin_base/plugin_base.dart';
import 'package:editor_plugins/editor_plugins.dart';

class AuditEntry {
  final DateTime timestamp;
  final String eventType;
  final String fileId;
  final String? details;

  AuditEntry({
    required this.timestamp,
    required this.eventType,
    required this.fileId,
    this.details,
  });

  @override
  String toString() => '[$timestamp] $eventType: $fileId ${details ?? ''}';
}

class AuditPlugin extends BaseEditorPlugin with StatefulPlugin {
  final List<AuditEntry> _audit = [];
  static const int maxEntries = 1000;

  @override
  PluginManifest get manifest => const PluginManifest(
    id: 'plugin.audit',
    name: 'Audit Log',
    version: '0.1.0',
    description: 'Logs all file operations for audit trail',
  );

  @override
  Future<void> onInitialize(PluginContext context) async {
    setState('audit', _audit);
  }

  @override
  Future<void> onDispose() async {
    disposeStateful();
  }

  void _log(String eventType, FileDocument file) {
    _addEntry(AuditEntry(
      timestamp: DateTime.now(),
      eventType: eventType,
      fileId: file.id,
      details: file.name,
    ));
  }

  void _addEntry(AuditEntry entry) {
    _audit.add(entry);
    if (_audit.length > maxEntries) {
      _audit.removeAt(0);  // Remove oldest
    }
    setState('audit', _audit);
    debugPrint('[${manifest.name}] ${entry.toString()}');
  }

  @override
  void onFileOpen(FileDocument file) => _log('OPEN', file);

  @override
  void onFileSave(FileDocument file) => _log('SAVE', file);

  @override
  void onFileCreate(FileDocument file) => _log('CREATE', file);

  @override
  void onFileDelete(String fileId) {
    _addEntry(AuditEntry(
      timestamp: DateTime.now(),
      eventType: 'DELETE',
      fileId: fileId,
    ));
  }

  List<AuditEntry> getAuditTrail() => List<AuditEntry>.from(_audit);
  
  void clearAudit() {
    _audit.clear();
    setState('audit', _audit);
  }
}
```

### Example 5: Registration in ServiceLocator

```dart
// service_locator.dart - _initializePlugins() method
Future<void> _initializePlugins() async {
  final pluginContext = AppPluginContext(
    fileRepository: fileRepository,
    folderRepository: folderRepository,
    eventBus: eventBus,
  );

  pluginManager = PluginManager(pluginContext);

  // Register in order (dependencies first)
  await pluginManager.registerPlugin(AutoSavePlugin());
  await pluginManager.registerPlugin(RecentFilesPlugin());
  await pluginManager.registerPlugin(FileStatsPlugin());
  
  // Custom plugins
  await pluginManager.registerPlugin(TimerPlugin());
  await pluginManager.registerPlugin(ThemePlugin());
  await pluginManager.registerPlugin(MetricsPlugin());
  await pluginManager.registerPlugin(AuditPlugin());
}
```

### Example 6: Using Plugins in UI

```dart
// In a widget
@override
Widget build(BuildContext context) {
  final pluginManager = ServiceLocator.instance.pluginManager;
  final timerPlugin = pluginManager.getPlugin('plugin.timer') as TimerPlugin?;
  
  return ValueListenableBuilder<int>(
    valueListenable: timerPlugin?.stateChanges ?? ValueNotifier(0),
    builder: (context, _, __) {
      final elapsed = timerPlugin?.getElapsedTime() ?? Duration.zero;
      return Text('Editing for ${elapsed.inSeconds}s');
    },
  );
}
```

---

## Testing Plugins

### Unit Test Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockPluginContext extends Mock implements PluginContext {}

void main() {
  group('TimerPlugin', () {
    late TimerPlugin plugin;
    late MockPluginContext context;

    setUp(() {
      plugin = TimerPlugin();
      context = MockPluginContext();
    });

    test('initializes successfully', () async {
      await plugin.initialize(context);
      expect(plugin.isInitialized, isTrue);
      expect(plugin.state.value, PluginState.ready);
    });

    test('tracks elapsed time', () async {
      await plugin.initialize(context);
      plugin.onFileOpen(mockFile);
      
      await Future.delayed(Duration(seconds: 1));
      
      final elapsed = plugin.getElapsedTime();
      expect(elapsed, isNotNull);
      expect(elapsed!.inSeconds, greaterThan(0));
    });

    test('clears state on file close', () async {
      await plugin.initialize(context);
      plugin.onFileOpen(mockFile);
      plugin.onFileClose('file-id');
      
      expect(plugin.getState('currentFile'), isNull);
    });

    tearDown(() async {
      await plugin.dispose();
    });
  });
}
```

---

## Performance Considerations

### Memory
- Plugins should clean up resources in `onDispose()`
- Use weak references where appropriate
- Consider maxing recent files, audit logs, etc.

### CPU
- Debounce frequent events
- Use lazy evaluation
- Cache expensive calculations

### Storage
- Use SharedPreferences for small data only
- Implement data rotation for logs
- Compress large datasets

---

## Security

### Safe Plugin Code
```dart
// Always validate user input
void setSetting(String value) {
  if (value.length > 256) {
    throw ArgumentError('Value too long');
  }
  setConfigSetting('setting', value);
}

// Always check file permissions
@override
void onFileOpen(FileDocument file) {
  if (!_hasPermission(file)) {
    debugPrint('No permission for ${file.id}');
    return;
  }
  // Process file
}

// Always use try-catch for external operations
Future<void> loadRemoteData() async {
  try {
    final data = await _fetchData();
    setState('data', data);
  } catch (e) {
    debugPrint('Failed to load data: $e');
  }
}
```

