import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_mock/multi_editor_mock.dart';
import 'package:multi_editor_ui/multi_editor_ui.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import 'package:multi_editor_plugin_auto_save/multi_editor_plugin_auto_save.dart';
import 'package:multi_editor_plugin_recent_files/multi_editor_plugin_recent_files.dart';
import 'package:multi_editor_plugin_file_stats/multi_editor_plugin_file_stats.dart';
import 'package:multi_editor_plugin_file_icons/multi_editor_plugin_file_icons.dart';
import 'package:multi_editor_plugin_dart/multi_editor_plugin_dart.dart';
import '../plugins/app_plugin_context.dart';
import '../services/monaco_service.dart' as monaco;
import '../services/app_file_navigation_service.dart';
import 'package:multi_editor_ui/src/plugins/plugin_ui_registry.dart';

/// Simple service locator for dependency injection
class ServiceLocator {
  static ServiceLocator? _instance;
  static ServiceLocator get instance => _instance ??= ServiceLocator._();

  ServiceLocator._();

  late final FileRepository fileRepository;
  late final FolderRepository folderRepository;
  late final ProjectRepository projectRepository;
  late final EventBus eventBus;
  late final ValidationService validationService;
  late final LanguageDetector languageDetector;

  late final FileTreeController fileTreeController;
  late final EditorController editorController;
  late final PluginManager pluginManager;
  late final monaco.MonacoService monacoService;
  late final ErrorTracker errorTracker;
  late final PluginUIRegistry pluginUIRegistry;

  /// Initialize all dependencies
  Future<void> init() async {
    // Create Monaco service
    monacoService = monaco.MonacoService();

    // Create event bus
    eventBus = MockEventBus();

    // Create mock repositories and services
    fileRepository = MockFileRepository();
    folderRepository = MockFolderRepository();
    projectRepository = MockProjectRepository();
    validationService = MockValidationService();
    languageDetector = MockLanguageDetector();

    // Initialize mock repositories with sample data
    await _seedMockData();

    // Create controllers
    fileTreeController = FileTreeController(
      folderRepository: folderRepository,
      fileRepository: fileRepository,
      eventBus: eventBus,
    );

    editorController = EditorController(
      fileRepository: fileRepository,
      eventBus: eventBus,
    );

    // Initialize plugin system
    await _initializePlugins();
  }

  /// Initialize plugin system and register plugins
  Future<void> _initializePlugins() async {
    // Create error tracker
    errorTracker = ErrorTracker(maxErrors: 100);

    // Create plugin context
    final pluginContext = AppPluginContext(
      fileRepository: fileRepository,
      folderRepository: folderRepository,
      projectRepository: projectRepository,
      validationService: validationService,
      languageDetector: languageDetector,
      eventBus: eventBus,
    );

    // Register Monaco service as EditorService for type-safe plugin access
    pluginContext.registerService<EditorService>(monacoService);

    // Register FileNavigationService for plugin file opening
    final navigationService = AppFileNavigationService(editorController);
    pluginContext.registerService<FileNavigationService>(navigationService);

    // Create and register PluginUIRegistry
    pluginUIRegistry = PluginUIRegistry();
    pluginContext.registerService<PluginUIService>(pluginUIRegistry);

    // Create plugin manager with error tracker
    pluginManager = PluginManager(pluginContext, errorTracker: errorTracker);

    // Register plugins
    await pluginManager.registerPlugin(FileIconsPlugin());
    await pluginManager.registerPlugin(AutoSavePlugin());
    await pluginManager.registerPlugin(RecentFilesPlugin());
    await pluginManager.registerPlugin(FileStatsPlugin());
    await pluginManager.registerPlugin(DartLanguagePlugin());
  }

  /// Seed mock data for testing
  Future<void> _seedMockData() async {
    // Create root folder
    await folderRepository.create(name: 'root', parentId: null);

    // Create some sample folders
    final srcResult = await folderRepository.create(
      name: 'src',
      parentId: 'root',
    );

    final libResult = await folderRepository.create(
      name: 'lib',
      parentId: 'root',
    );

    final testResult = await folderRepository.create(
      name: 'test',
      parentId: 'root',
    );

    // Create subfolders
    await srcResult.fold((failure) => null, (srcFolder) async {
      await folderRepository.create(name: 'components', parentId: srcFolder.id);
      await folderRepository.create(name: 'utils', parentId: srcFolder.id);
    });

    // Create sample files
    await fileRepository.create(
      name: 'main.dart',
      folderId: 'root',
      initialContent: '''void main() {
  print('Hello, Multi-File Editor!');
}
''',
      language: 'dart',
    );

    await libResult.fold((failure) => null, (libFolder) async {
      await fileRepository.create(
        name: 'app.dart',
        folderId: libFolder.id,
        initialContent: '''import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi-File Editor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-File Editor'),
      ),
      body: const Center(
        child: Text('Welcome!'),
      ),
    );
  }
}
''',
        language: 'dart',
      );

      await fileRepository.create(
        name: 'constants.dart',
        folderId: libFolder.id,
        initialContent: '''class Constants {
  static const String appName = 'Multi-File Editor';
  static const String version = '1.0.0';
  static const int maxFileSize = 1024 * 1024; // 1MB
}
''',
        language: 'dart',
      );
    });

    await testResult.fold((failure) => null, (testFolder) async {
      await fileRepository.create(
        name: 'app_test.dart',
        folderId: testFolder.id,
        initialContent: '''import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Sample test', () {
    expect(1 + 1, equals(2));
  });
}
''',
        language: 'dart',
      );
    });

    // Create a README.md
    await fileRepository.create(
      name: 'README.md',
      folderId: 'root',
      initialContent: '''# Multi-File Code Editor Example

This is an example application demonstrating the multi-file code editor package.

## Features

- 📁 File tree with unlimited nesting
- ✏️ Monaco code editor with syntax highlighting
- 🖱️ Drag & Drop support
- 💾 Auto-save functionality
- 🔍 File watching

## Usage

1. Select a file from the tree on the left
2. Edit the file in the Monaco editor
3. Save using Ctrl+S or the save button
4. Create, rename, or delete files using the context menu

## Architecture

This example uses:
- `editor_core` - Domain layer with entities and repositories
- `editor_plugins` - Infrastructure layer with implementations
- `editor_mock` - Mock implementations for testing
- `editor_ui` - Presentation layer with widgets and controllers

Enjoy coding!
''',
      language: 'markdown',
    );

    // Create a JSON config file
    await fileRepository.create(
      name: 'config.json',
      folderId: 'root',
      initialContent: '''{
  "name": "multi-file-editor",
  "version": "1.0.0",
  "description": "A multi-file code editor built with Flutter",
  "author": "Your Name",
  "license": "MIT",
  "features": [
    "File tree navigation",
    "Monaco code editor",
    "Syntax highlighting",
    "Drag & Drop",
    "Auto-save"
  ],
  "settings": {
    "theme": "dark",
    "fontSize": 14,
    "tabSize": 2,
    "autoSave": true,
    "autoSaveDelay": 2
  }
}
''',
      language: 'json',
    );
  }

  /// Dispose all resources
  Future<void> dispose() async {
    await pluginManager.disposeAll();
    fileTreeController.dispose();
    editorController.dispose();
    errorTracker.dispose();
  }
}
