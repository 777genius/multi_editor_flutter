import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import 'package:multi_editor_plugin_base/multi_editor_plugin_base.dart';

/// Simple test plugin that initializes successfully
class TestPlugin extends BaseEditorPlugin {
  bool isInitializeCalled = false;
  bool isDisposeCalled = false;

  @override
  PluginManifest get manifest => const PluginManifest(
    id: 'test-plugin',
    name: 'Test Plugin',
    version: '1.0.0',
    author: 'Test Author',
    description: 'A test plugin',
    dependencies: [],
  );

  @override
  Future<void> onInitialize(PluginContext context) async {
    isInitializeCalled = true;
  }

  @override
  Future<void> onDispose() async {
    isDisposeCalled = true;
  }

  // Expose protected members for testing
  PluginContext getContext() => context;

  bool get testIsInitialized => isInitialized;

  void executeSafely(
    void Function() action, {
    void Function(Object error)? onError,
  }) {
    safeExecute('test operation', action, onError: onError);
  }

  Future<void> executeSafelyAsync(
    Future<void> Function() action, {
    void Function(Object error)? onError,
  }) async {
    await safeExecuteAsync('test async operation', action, onError: onError);
  }
}

/// Test plugin that fails during initialization
class FailingPlugin extends BaseEditorPlugin {
  final String errorMessage;

  FailingPlugin({this.errorMessage = 'Initialization failed'});

  @override
  PluginManifest get manifest => const PluginManifest(
    id: 'failing-plugin',
    name: 'Failing Plugin',
    version: '1.0.0',
    author: 'Test Author',
    description: 'A plugin that fails to initialize',
    dependencies: [],
  );

  @override
  Future<void> onInitialize(PluginContext context) async {
    throw Exception(errorMessage);
  }

  @override
  Future<void> onDispose() async {}
}

/// Test plugin that throws during disposal
class ThrowingDisposePlugin extends BaseEditorPlugin {
  @override
  PluginManifest get manifest => const PluginManifest(
    id: 'throwing-dispose-plugin',
    name: 'Throwing Dispose Plugin',
    version: '1.0.0',
    author: 'Test Author',
    description: 'A plugin that throws during disposal',
    dependencies: [],
  );

  @override
  Future<void> onInitialize(PluginContext context) async {}

  @override
  Future<void> onDispose() async {
    throw Exception('Disposal failed');
  }
}

/// Test plugin with configurable behavior
class ConfigurableTestPlugin extends BaseEditorPlugin with ConfigurablePlugin {
  @override
  PluginManifest get manifest => const PluginManifest(
    id: 'configurable-test-plugin',
    name: 'Configurable Test Plugin',
    version: '1.0.0',
    author: 'Test Author',
    description: 'A configurable test plugin',
    dependencies: [],
  );

  @override
  Future<void> onInitialize(PluginContext context) async {
    // loadConfiguration will be called manually in tests with proper storage
  }

  @override
  Future<void> onDispose() async {}

  Map<String, dynamic> get defaultConfiguration => {
    'enabled': true,
    'option1': 'default',
    'timeout': 5000,
  };

  PluginId get pluginId =>
      const PluginId(value: 'plugin.configurable-test-plugin');
}

/// Test plugin with state management
class StatefulTestPlugin extends BaseEditorPlugin with StatefulPlugin {
  @override
  PluginManifest get manifest => const PluginManifest(
    id: 'stateful-test-plugin',
    name: 'Stateful Test Plugin',
    version: '1.0.0',
    author: 'Test Author',
    description: 'A stateful test plugin',
    dependencies: [],
  );

  @override
  Future<void> onInitialize(PluginContext context) async {}

  @override
  Future<void> onDispose() async {}
}
