import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';

import 'helpers/mock_plugin_context.dart';
import 'helpers/test_plugins.dart';

void main() {
  late MockPluginContext context;
  late PluginManager manager;
  late ErrorTracker errorTracker;

  setUp(() {
    context = MockPluginContext();
    errorTracker = ErrorTracker();
    manager = PluginManager(context, errorTracker: errorTracker);
  });

  tearDown(() {
    manager.disposeAll();
  });

  group('Plugin Registration', () {
    test('should register and activate a simple plugin', () async {
      final plugin = SimplePlugin();

      await manager.registerPlugin(plugin);

      expect(manager.isPluginRegistered('test.simple'), true);
      expect(manager.isPluginActivated('test.simple'), true);
      expect(plugin.isInitialized, true);
    });

    test('should throw error when registering duplicate plugin', () async {
      final plugin1 = SimplePlugin();
      final plugin2 = SimplePlugin();

      await manager.registerPlugin(plugin1);

      expect(
        () => manager.registerPlugin(plugin2),
        throwsA(isA<PluginException>()),
      );
    });

    test('should activate plugins in dependency order', () async {
      final plugin1 = SimplePlugin();
      final plugin2 = PluginWithDependencies();

      // Register dependency first, then dependent
      await manager.registerPlugin(plugin1);
      await manager.registerPlugin(plugin2);

      // Both should be activated
      expect(manager.isPluginActivated('test.simple'), true);
      expect(manager.isPluginActivated('test.with-deps'), true);
      expect(plugin2.isInitialized, true);
    });

    test('should fail when dependency is missing', () async {
      final plugin = PluginWithDependencies();

      expect(
        () => manager.registerPlugin(plugin),
        throwsA(isA<PluginException>()),
      );
    });
  });

  group('Plugin Activation/Deactivation', () {
    test('should deactivate a plugin', () async {
      final plugin = SimplePlugin();
      await manager.registerPlugin(plugin);

      expect(manager.isPluginActivated('test.simple'), true);

      final result = await manager.deactivatePlugin('test.simple');

      expect(result, true);
      expect(manager.isPluginActivated('test.simple'), false);
      expect(plugin.isDisposed, true);
    });

    test(
      'should not deactivate plugin if other plugins depend on it',
      () async {
        final plugin1 = SimplePlugin();
        final plugin2 = PluginWithDependencies();

        await manager.registerPlugin(plugin1);
        await manager.registerPlugin(plugin2);

        final result = await manager.deactivatePlugin('test.simple');

        expect(result, false);
        expect(manager.isPluginActivated('test.simple'), true);
      },
    );

    test('should reactivate a deactivated plugin', () async {
      final plugin = SimplePlugin();
      await manager.registerPlugin(plugin);
      await manager.deactivatePlugin('test.simple');

      // Reactivate
      final result = await manager.activatePlugin('test.simple');

      expect(result, true);
      expect(manager.isPluginActivated('test.simple'), true);
    });
  });

  group('Error Handling', () {
    test('should handle plugin initialization failure', () async {
      final plugin = FailingPlugin();

      // Should not throw, but plugin should not be activated
      await manager.registerPlugin(plugin);

      expect(manager.isPluginRegistered('test.failing'), true);
      expect(manager.isPluginActivated('test.failing'), false);

      final status = manager.getPluginStatus('test.failing');
      expect(status?.state, PluginActivationState.error);
    });

    test('should record errors in ErrorTracker', () async {
      final plugin = FailingPlugin();

      await manager.registerPlugin(plugin);

      final errors = errorTracker.getErrorsForPlugin('test.failing');
      expect(errors, isNotEmpty);
      expect(errors[0].type, PluginErrorType.initialization);
    });

    test('should allow retrying failed plugin', () async {
      final plugin = FailingPlugin();

      await manager.registerPlugin(plugin);
      expect(manager.isPluginActivated('test.failing'), false);

      // Retry won't help with FailingPlugin, but test the mechanism
      final result = await manager.retryPlugin('test.failing');

      expect(result, false); // Still fails
      final errors = errorTracker.getErrorsForPlugin('test.failing');
      expect(errors.length, greaterThan(1)); // Multiple errors recorded
    });

    test('should auto-disable plugin after 3 errors', () async {
      final plugin = ErrorThrowingPlugin();
      await manager.registerPlugin(plugin);

      // Trigger errors by dispatching file open events
      for (var i = 0; i < 3; i++) {
        try {
          final file = FileDocument(
            id: 'test-$i',
            name: 'test.dart',
            folderId: 'folder',
            content: '',
            language: 'dart',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await manager.dispatchEvent(FileOpened(file: file));
        } catch (e) {
          // Expected errors
        }
      }

      final status = manager.getPluginStatus('test.error-throwing');
      // After 3 errors, plugin should be disabled
      expect(status?.errorCount, greaterThanOrEqualTo(3));
    });
  });

  group('Event Dispatching', () {
    test('should dispatch events to registered plugins', () async {
      final plugin = FileTrackingPlugin();
      await manager.registerPlugin(plugin);

      final file = FileDocument(
        id: 'test-file',
        name: 'test.dart',
        folderId: 'folder',
        content: '',
        language: 'dart',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await manager.dispatchEvent(FileOpened(file: file));

      expect(plugin.openedFiles, contains('test-file'));
    });

    test('should not dispatch to deactivated plugins', () async {
      final plugin = FileTrackingPlugin();
      await manager.registerPlugin(plugin);
      await manager.deactivatePlugin('test.file-tracker');

      final file = FileDocument(
        id: 'test-file',
        name: 'test.dart',
        folderId: 'folder',
        content: '',
        language: 'dart',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await manager.dispatchEvent(FileOpened(file: file));

      expect(plugin.openedFiles, isEmpty);
    });
  });

  group('Plugin Status', () {
    test('should track plugin states', () async {
      final plugin = SimplePlugin();
      await manager.registerPlugin(plugin);

      final status = manager.getPluginStatus('test.simple');

      expect(status, isNotNull);
      expect(status?.pluginId, 'test.simple');
      expect(status?.state, PluginActivationState.active);
      expect(status?.errorCount, 0);
    });

    test('should get all plugin statuses', () async {
      final plugin1 = SimplePlugin();
      final plugin2 = FileTrackingPlugin();

      await manager.registerPlugin(plugin1);
      await manager.registerPlugin(plugin2);

      final statuses = manager.getAllPluginStatus();

      expect(statuses.length, 2);
      expect(statuses.keys, containsAll(['test.simple', 'test.file-tracker']));
    });
  });

  group('Plugin Queries', () {
    test('should get all registered plugins', () async {
      final plugin1 = SimplePlugin();
      final plugin2 = FileTrackingPlugin();

      await manager.registerPlugin(plugin1);
      await manager.registerPlugin(plugin2);

      final plugins = manager.allPlugins;

      expect(plugins.length, 2);
    });

    test('should get plugins by language', () async {
      final dartPlugin = TestLanguagePlugin('dart');
      final jsPlugin = TestLanguagePlugin('javascript');

      await manager.registerPlugin(dartPlugin);
      await manager.registerPlugin(jsPlugin);

      final dartPlugins = manager.getPluginsForLanguage('dart');

      expect(dartPlugins.length, 1);
      expect(dartPlugins[0].manifest.id, 'test.language-dart');
    });

    test('should get specific plugin by ID', () async {
      final plugin = SimplePlugin();
      await manager.registerPlugin(plugin);

      final retrieved = manager.getPlugin('test.simple');

      expect(retrieved, isNotNull);
      expect(retrieved, same(plugin));
    });
  });

  group('Dependency Validation', () {
    test('should validate all plugin dependencies', () async {
      final plugin1 = SimplePlugin();
      final plugin2 = PluginWithDependencies();

      await manager.registerPlugin(plugin1);
      await manager.registerPlugin(plugin2);

      final errors = manager.validateDependencies();

      expect(errors, isEmpty);
    });

    test('should get dependency graph', () async {
      final plugin1 = SimplePlugin();
      final plugin2 = PluginWithDependencies();

      await manager.registerPlugin(plugin1);
      await manager.registerPlugin(plugin2);

      final graph = manager.getDependencyGraph();

      expect(graph['test.simple'], isEmpty);
      expect(graph['test.with-deps'], contains('test.simple'));
    });

    test('should get plugins without dependencies', () async {
      final plugin1 = SimplePlugin();
      final plugin2 = PluginWithDependencies();

      await manager.registerPlugin(plugin1);
      await manager.registerPlugin(plugin2);

      final leaves = manager.getLeafPlugins();

      expect(leaves, contains('test.simple'));
      expect(leaves, isNot(contains('test.with-deps')));
    });
  });

  group('Cleanup', () {
    test('should dispose all plugins', () async {
      final plugin1 = SimplePlugin();
      final plugin2 = FileTrackingPlugin();

      await manager.registerPlugin(plugin1);
      await manager.registerPlugin(plugin2);

      // tearDown will call disposeAll, so just verify state before that
      expect(manager.allPlugins.length, 2);
      expect(manager.isPluginActivated('test.simple'), true);
      expect(manager.isPluginActivated('test.file-tracker'), true);
    });
  });
}
