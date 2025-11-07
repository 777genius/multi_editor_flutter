import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import 'package:flutter/widgets.dart';

/// Simple test plugin without dependencies
class SimplePlugin extends EditorPlugin {
  bool isInitialized = false;
  bool isDisposed = false;

  @override
  PluginManifest get manifest => const PluginManifest(
        id: 'test.simple',
        name: 'Simple Test Plugin',
        version: '1.0.0',
        description: 'Simple plugin for testing',
        author: 'Test',
      );

  @override
  Future<void> initialize(PluginContext context) async {
    isInitialized = true;
  }

  @override
  Future<void> dispose() async {
    isDisposed = true;
  }
}

/// Plugin that fails during initialization
class FailingPlugin extends EditorPlugin {
  final String errorMessage;

  FailingPlugin({this.errorMessage = 'Initialization failed'});

  @override
  PluginManifest get manifest => const PluginManifest(
        id: 'test.failing',
        name: 'Failing Test Plugin',
        version: '1.0.0',
        description: 'Plugin that fails on init',
        author: 'Test',
      );

  @override
  Future<void> initialize(PluginContext context) async {
    throw Exception(errorMessage);
  }

  @override
  Future<void> dispose() async {}
}

/// Plugin with dependencies
class PluginWithDependencies extends EditorPlugin {
  bool isInitialized = false;

  @override
  PluginManifest get manifest => const PluginManifest(
        id: 'test.with-deps',
        name: 'Plugin With Dependencies',
        version: '1.0.0',
        description: 'Plugin with dependencies',
        author: 'Test',
        dependencies: ['test.simple'],
      );

  @override
  Future<void> initialize(PluginContext context) async {
    isInitialized = true;
  }

  @override
  Future<void> dispose() async {}
}

/// Plugin that tracks file events
class FileTrackingPlugin extends EditorPlugin {
  final List<String> openedFiles = [];
  final List<String> closedFiles = [];
  final List<String> savedFiles = [];

  @override
  PluginManifest get manifest => const PluginManifest(
        id: 'test.file-tracker',
        name: 'File Tracking Plugin',
        version: '1.0.0',
        description: 'Tracks file events',
        author: 'Test',
      );

  @override
  Future<void> initialize(PluginContext context) async {}

  @override
  void onFileOpen(FileDocument file) {
    openedFiles.add(file.id);
  }

  @override
  void onFileClose(String fileId) {
    closedFiles.add(fileId);
  }

  @override
  void onFileSave(FileDocument file) {
    savedFiles.add(file.id);
  }

  @override
  Future<void> dispose() async {}
}

/// Plugin that throws errors in event handlers
class ErrorThrowingPlugin extends EditorPlugin {
  @override
  PluginManifest get manifest => const PluginManifest(
        id: 'test.error-throwing',
        name: 'Error Throwing Plugin',
        version: '1.0.0',
        description: 'Throws errors in handlers',
        author: 'Test',
      );

  @override
  Future<void> initialize(PluginContext context) async {}

  @override
  void onFileOpen(FileDocument file) {
    throw Exception('Error in onFileOpen');
  }

  @override
  Future<void> dispose() async {}
}

/// Plugin with specific version
class VersionedPlugin extends EditorPlugin {
  final String pluginId;
  final String version;
  final List<String> dependencies;

  VersionedPlugin({
    required this.pluginId,
    required this.version,
    this.dependencies = const [],
  });

  @override
  PluginManifest get manifest => PluginManifest(
        id: pluginId,
        name: 'Versioned Plugin $pluginId',
        version: version,
        description: 'Plugin with version $version',
        author: 'Test',
        dependencies: dependencies,
      );

  @override
  Future<void> initialize(PluginContext context) async {}

  @override
  Future<void> dispose() async {}
}

/// Plugin with language support
class TestLanguagePlugin extends EditorPlugin {
  final String languageId;

  TestLanguagePlugin(this.languageId);

  @override
  PluginManifest get manifest => PluginManifest(
        id: 'test.language-$languageId',
        name: '$languageId Language Plugin',
        version: '1.0.0',
        description: 'Language support for $languageId',
        author: 'Test',
      );

  @override
  Future<void> initialize(PluginContext context) async {}

  @override
  bool supportsLanguage(String language) {
    return language == languageId;
  }

  @override
  Future<void> dispose() async {}
}

/// Plugin with configuration schema
class ConfigurableTestPlugin extends EditorPlugin {
  @override
  PluginManifest get manifest => const PluginManifest(
        id: 'test.configurable',
        name: 'Configurable Test Plugin',
        version: '1.0.0',
        description: 'Plugin with config schema',
        author: 'Test',
      );

  @override
  PluginConfigSchema? get configSchema => const PluginConfigSchema({
        'enabled': ConfigFieldSchema(
          key: 'enabled',
          type: ConfigFieldType.boolean,
          defaultValue: true,
          description: 'Enable/disable plugin',
          required: true,
        ),
        'timeout': ConfigFieldSchema(
          key: 'timeout',
          type: ConfigFieldType.number,
          defaultValue: 5000,
          description: 'Timeout in ms',
        ),
        'name': ConfigFieldSchema(
          key: 'name',
          type: ConfigFieldType.string,
          defaultValue: 'default',
          description: 'Plugin name',
        ),
      });

  @override
  Future<void> initialize(PluginContext context) async {}

  @override
  Future<void> dispose() async {}
}

/// Plugin with toolbar action
class ToolbarPlugin extends EditorPlugin {
  @override
  PluginManifest get manifest => const PluginManifest(
        id: 'test.toolbar',
        name: 'Toolbar Plugin',
        version: '1.0.0',
        description: 'Plugin with toolbar action',
        author: 'Test',
      );

  @override
  Future<void> initialize(PluginContext context) async {}

  @override
  Widget? buildToolbarAction(BuildContext context) {
    return const Text('Toolbar Action');
  }

  @override
  Future<void> dispose() async {}
}
