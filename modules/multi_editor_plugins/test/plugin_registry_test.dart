import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_editor_plugins/src/plugin_api/editor_plugin.dart';
import 'package:multi_editor_plugins/src/plugin_api/plugin_manifest.dart';
import 'package:multi_editor_plugins/src/plugin_manager/plugin_registry.dart';

// Mock plugin for testing
class MockEditorPlugin extends Mock implements EditorPlugin {}

void main() {
  group('PluginRegistry', () {
    late PluginRegistry registry;

    // Test data
    final testManifest1 = PluginManifest(
      id: 'plugin-1',
      name: 'Test Plugin 1',
      version: '1.0.0',
      description: 'A test plugin for Dart',
      author: 'Test Author',
      dependencies: [],
      capabilities: {'language': 'dart'},
      activationEvents: ['onFileOpen'],
      metadata: {'tags': ['dart', 'testing']},
    );

    final testManifest2 = PluginManifest(
      id: 'plugin-2',
      name: 'Test Plugin 2',
      version: '2.0.0',
      description: 'Another test plugin for Python',
      author: 'Another Author',
      dependencies: ['plugin-1'],
      capabilities: {'language': 'python'},
      activationEvents: ['onStartup'],
      metadata: {'tags': ['python']},
    );

    setUp(() {
      registry = PluginRegistry();
    });

    tearDown(() {
      registry.dispose();
    });

    group('Initialization', () {
      test('should initialize with empty entries', () {
        // Assert
        expect(registry.allEntries, isEmpty);
      });

      test('should initialize with empty instances', () {
        // Arrange
        final plugin = MockEditorPlugin();

        // Act - Try to get instance without registration
        expect(
          () => registry.getInstance('plugin-1'),
          throwsA(isA<PluginRegistryException>()),
        );
      });
    });

    group('register', () {
      test('should register plugin successfully', () {
        // Arrange
        final factory = () => MockEditorPlugin();

        // Track listener calls
        var listenerCalled = false;
        registry.addListener(() {
          listenerCalled = true;
        });

        // Act
        registry.register(
          manifest: testManifest1,
          factory: factory,
        );

        // Assert
        expect(registry.allEntries.length, equals(1));
        expect(registry.isRegistered('plugin-1'), isTrue);
        expect(listenerCalled, isTrue);
      });

      test('should register plugin with autoLoad flag', () {
        // Arrange
        final factory = () => MockEditorPlugin();

        // Act
        registry.register(
          manifest: testManifest1,
          factory: factory,
          autoLoad: true,
        );

        // Assert
        final entry = registry.getEntry('plugin-1');
        expect(entry, isNotNull);
        expect(entry?.autoLoad, isTrue);
      });

      test('should throw exception when registering duplicate plugin', () {
        // Arrange
        final factory = () => MockEditorPlugin();
        registry.register(manifest: testManifest1, factory: factory);

        // Act & Assert
        expect(
          () => registry.register(manifest: testManifest1, factory: factory),
          throwsA(isA<PluginRegistryException>()),
        );
      });

      test('should store registration timestamp', () {
        // Arrange
        final factory = () => MockEditorPlugin();
        final beforeRegistration = DateTime.now();

        // Act
        registry.register(manifest: testManifest1, factory: factory);

        // Assert
        final entry = registry.getEntry('plugin-1');
        expect(entry?.registeredAt, isNotNull);
        expect(
          entry!.registeredAt.isAfter(beforeRegistration.subtract(const Duration(seconds: 1))),
          isTrue,
        );
      });

      test('should notify listeners when plugin is registered', () {
        // Arrange
        final factory = () => MockEditorPlugin();
        var notificationCount = 0;
        registry.addListener(() {
          notificationCount++;
        });

        // Act
        registry.register(manifest: testManifest1, factory: factory);

        // Assert
        expect(notificationCount, equals(1));
      });
    });

    group('unregister', () {
      test('should unregister plugin successfully', () {
        // Arrange
        final factory = () => MockEditorPlugin();
        registry.register(manifest: testManifest1, factory: factory);

        // Act
        registry.unregister('plugin-1');

        // Assert
        expect(registry.isRegistered('plugin-1'), isFalse);
        expect(registry.allEntries, isEmpty);
      });

      test('should remove plugin instance when unregistering', () async {
        // Arrange
        final factory = () => MockEditorPlugin();
        registry.register(manifest: testManifest1, factory: factory);
        await registry.getInstance('plugin-1'); // Create instance

        // Act
        registry.unregister('plugin-1');

        // Assert
        expect(
          () => registry.getInstance('plugin-1'),
          throwsA(isA<PluginRegistryException>()),
        );
      });

      test('should notify listeners when plugin is unregistered', () {
        // Arrange
        final factory = () => MockEditorPlugin();
        registry.register(manifest: testManifest1, factory: factory);

        var notificationCount = 0;
        registry.addListener(() {
          notificationCount++;
        });

        // Act
        registry.unregister('plugin-1');

        // Assert
        expect(notificationCount, equals(1));
      });

      test('should handle unregistering non-existent plugin gracefully', () {
        // Act & Assert
        expect(() => registry.unregister('non-existent'), returnsNormally);
      });
    });

    group('isRegistered', () {
      test('should return true for registered plugin', () {
        // Arrange
        final factory = () => MockEditorPlugin();
        registry.register(manifest: testManifest1, factory: factory);

        // Act & Assert
        expect(registry.isRegistered('plugin-1'), isTrue);
      });

      test('should return false for non-registered plugin', () {
        // Act & Assert
        expect(registry.isRegistered('non-existent'), isFalse);
      });
    });

    group('getEntry', () {
      test('should return entry for registered plugin', () {
        // Arrange
        final factory = () => MockEditorPlugin();
        registry.register(manifest: testManifest1, factory: factory);

        // Act
        final entry = registry.getEntry('plugin-1');

        // Assert
        expect(entry, isNotNull);
        expect(entry?.id, equals('plugin-1'));
        expect(entry?.name, equals('Test Plugin 1'));
        expect(entry?.version, equals('1.0.0'));
      });

      test('should return null for non-registered plugin', () {
        // Act
        final entry = registry.getEntry('non-existent');

        // Assert
        expect(entry, isNull);
      });

      test('should provide access to manifest', () {
        // Arrange
        final factory = () => MockEditorPlugin();
        registry.register(manifest: testManifest1, factory: factory);

        // Act
        final entry = registry.getEntry('plugin-1');

        // Assert
        expect(entry?.manifest, equals(testManifest1));
      });
    });

    group('allEntries', () {
      test('should return all registered entries', () {
        // Arrange
        final factory1 = () => MockEditorPlugin();
        final factory2 = () => MockEditorPlugin();

        registry.register(manifest: testManifest1, factory: factory1);
        registry.register(manifest: testManifest2, factory: factory2);

        // Act
        final entries = registry.allEntries;

        // Assert
        expect(entries.length, equals(2));
        expect(entries.map((e) => e.id), containsAll(['plugin-1', 'plugin-2']));
      });

      test('should return empty list when no plugins registered', () {
        // Act
        final entries = registry.allEntries;

        // Assert
        expect(entries, isEmpty);
      });
    });

    group('autoLoadEntries', () {
      test('should return only auto-load entries', () {
        // Arrange
        final factory1 = () => MockEditorPlugin();
        final factory2 = () => MockEditorPlugin();

        registry.register(
          manifest: testManifest1,
          factory: factory1,
          autoLoad: true,
        );
        registry.register(
          manifest: testManifest2,
          factory: factory2,
          autoLoad: false,
        );

        // Act
        final autoLoadEntries = registry.autoLoadEntries;

        // Assert
        expect(autoLoadEntries.length, equals(1));
        expect(autoLoadEntries.first.id, equals('plugin-1'));
      });

      test('should return empty list when no auto-load plugins', () {
        // Arrange
        final factory = () => MockEditorPlugin();
        registry.register(
          manifest: testManifest1,
          factory: factory,
          autoLoad: false,
        );

        // Act
        final autoLoadEntries = registry.autoLoadEntries;

        // Assert
        expect(autoLoadEntries, isEmpty);
      });
    });

    group('getInstance', () {
      test('should create and return plugin instance', () async {
        // Arrange
        final mockPlugin = MockEditorPlugin();
        final factory = () => mockPlugin;
        registry.register(manifest: testManifest1, factory: factory);

        // Act
        final instance = await registry.getInstance('plugin-1');

        // Assert
        expect(instance, equals(mockPlugin));
      });

      test('should return cached instance on subsequent calls', () async {
        // Arrange
        final mockPlugin = MockEditorPlugin();
        final factory = () => mockPlugin;
        registry.register(manifest: testManifest1, factory: factory);

        // Act
        final instance1 = await registry.getInstance('plugin-1');
        final instance2 = await registry.getInstance('plugin-1');

        // Assert
        expect(instance1, equals(instance2));
        expect(identical(instance1, instance2), isTrue);
      });

      test('should throw exception for non-registered plugin', () async {
        // Act & Assert
        expect(
          () => registry.getInstance('non-existent'),
          throwsA(isA<PluginRegistryException>()),
        );
      });

      test('should handle async factory', () async {
        // Arrange
        final mockPlugin = MockEditorPlugin();
        Future<EditorPlugin> asyncFactory() async {
          await Future.delayed(const Duration(milliseconds: 10));
          return mockPlugin;
        }
        registry.register(manifest: testManifest1, factory: asyncFactory);

        // Act
        final instance = await registry.getInstance('plugin-1');

        // Assert
        expect(instance, equals(mockPlugin));
      });

      test('should rethrow factory exceptions', () async {
        // Arrange
        EditorPlugin failingFactory() {
          throw Exception('Factory failed');
        }
        registry.register(manifest: testManifest1, factory: failingFactory);

        // Act & Assert
        expect(
          () => registry.getInstance('plugin-1'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('query', () {
      setUp(() {
        final factory1 = () => MockEditorPlugin();
        final factory2 = () => MockEditorPlugin();

        registry.register(manifest: testManifest1, factory: factory1);
        registry.register(manifest: testManifest2, factory: factory2);
      });

      test('should query by name pattern', () {
        // Act
        final results = registry.query(namePattern: 'Plugin 1');

        // Assert
        expect(results.length, equals(1));
        expect(results.first.id, equals('plugin-1'));
      });

      test('should query by name pattern case-insensitively', () {
        // Act
        final results = registry.query(namePattern: 'plugin 1');

        // Assert
        expect(results.length, equals(1));
        expect(results.first.id, equals('plugin-1'));
      });

      test('should query by author', () {
        // Act
        final results = registry.query(author: 'Test Author');

        // Assert
        expect(results.length, equals(1));
        expect(results.first.id, equals('plugin-1'));
      });

      test('should query by tags', () {
        // Act
        final results = registry.query(tags: ['dart']);

        // Assert
        expect(results.length, equals(1));
        expect(results.first.id, equals('plugin-1'));
      });

      test('should query by multiple tags', () {
        // Act
        final results = registry.query(tags: ['python', 'dart']);

        // Assert
        expect(results.length, equals(2));
      });

      test('should query by autoLoad flag', () {
        // Arrange - Re-register with autoLoad
        registry.unregister('plugin-1');
        final factory1 = () => MockEditorPlugin();
        registry.register(
          manifest: testManifest1,
          factory: factory1,
          autoLoad: true,
        );

        // Act
        final results = registry.query(autoLoad: true);

        // Assert
        expect(results.length, equals(1));
        expect(results.first.id, equals('plugin-1'));
      });

      test('should combine multiple query criteria', () {
        // Act
        final results = registry.query(
          author: 'Test Author',
          tags: ['dart'],
        );

        // Assert
        expect(results.length, equals(1));
        expect(results.first.id, equals('plugin-1'));
      });

      test('should return empty list when no matches', () {
        // Act
        final results = registry.query(namePattern: 'Non-existent');

        // Assert
        expect(results, isEmpty);
      });
    });

    group('getByLanguage', () {
      setUp(() {
        final factory1 = () => MockEditorPlugin();
        final factory2 = () => MockEditorPlugin();

        registry.register(manifest: testManifest1, factory: factory1);
        registry.register(manifest: testManifest2, factory: factory2);
      });

      test('should find plugins by language tag', () {
        // Act
        final results = registry.getByLanguage('dart');

        // Assert
        expect(results.length, equals(1));
        expect(results.first.id, equals('plugin-1'));
      });

      test('should find plugins by language in description', () {
        // Act
        final results = registry.getByLanguage('python');

        // Assert
        expect(results.length, equals(1));
        expect(results.first.id, equals('plugin-2'));
      });

      test('should be case-insensitive', () {
        // Act
        final results = registry.getByLanguage('DART');

        // Assert
        expect(results.length, equals(1));
        expect(results.first.id, equals('plugin-1'));
      });

      test('should return empty list when no matches', () {
        // Act
        final results = registry.getByLanguage('javascript');

        // Assert
        expect(results, isEmpty);
      });
    });

    group('getDependencyGraph', () {
      test('should return dependency graph', () {
        // Arrange
        final factory1 = () => MockEditorPlugin();
        final factory2 = () => MockEditorPlugin();

        registry.register(manifest: testManifest1, factory: factory1);
        registry.register(manifest: testManifest2, factory: factory2);

        // Act
        final graph = registry.getDependencyGraph();

        // Assert
        expect(graph.length, equals(2));
        expect(graph['plugin-1'], isEmpty);
        expect(graph['plugin-2'], equals(['plugin-1']));
      });

      test('should return empty map for empty registry', () {
        // Act
        final graph = registry.getDependencyGraph();

        // Assert
        expect(graph, isEmpty);
      });
    });

    group('clear', () {
      test('should clear all entries and instances', () async {
        // Arrange
        final factory = () => MockEditorPlugin();
        registry.register(manifest: testManifest1, factory: factory);
        await registry.getInstance('plugin-1');

        // Act
        registry.clear();

        // Assert
        expect(registry.allEntries, isEmpty);
        expect(registry.isRegistered('plugin-1'), isFalse);
      });

      test('should notify listeners when cleared', () {
        // Arrange
        final factory = () => MockEditorPlugin();
        registry.register(manifest: testManifest1, factory: factory);

        var notificationCount = 0;
        registry.addListener(() {
          notificationCount++;
        });

        // Act
        registry.clear();

        // Assert
        expect(notificationCount, equals(1));
      });
    });

    group('statistics', () {
      test('should return correct statistics for empty registry', () {
        // Act
        final stats = registry.statistics;

        // Assert
        expect(stats.totalPlugins, equals(0));
        expect(stats.autoLoadPlugins, equals(0));
        expect(stats.loadedInstances, equals(0));
        expect(stats.byAuthor, isEmpty);
        expect(stats.byTags, isEmpty);
      });

      test('should return correct total plugins count', () {
        // Arrange
        final factory1 = () => MockEditorPlugin();
        final factory2 = () => MockEditorPlugin();

        registry.register(manifest: testManifest1, factory: factory1);
        registry.register(manifest: testManifest2, factory: factory2);

        // Act
        final stats = registry.statistics;

        // Assert
        expect(stats.totalPlugins, equals(2));
      });

      test('should return correct auto-load plugins count', () {
        // Arrange
        final factory1 = () => MockEditorPlugin();
        final factory2 = () => MockEditorPlugin();

        registry.register(
          manifest: testManifest1,
          factory: factory1,
          autoLoad: true,
        );
        registry.register(
          manifest: testManifest2,
          factory: factory2,
          autoLoad: false,
        );

        // Act
        final stats = registry.statistics;

        // Assert
        expect(stats.autoLoadPlugins, equals(1));
      });

      test('should return correct loaded instances count', () async {
        // Arrange
        final factory1 = () => MockEditorPlugin();
        final factory2 = () => MockEditorPlugin();

        registry.register(manifest: testManifest1, factory: factory1);
        registry.register(manifest: testManifest2, factory: factory2);

        await registry.getInstance('plugin-1');

        // Act
        final stats = registry.statistics;

        // Assert
        expect(stats.loadedInstances, equals(1));
      });

      test('should return correct author statistics', () {
        // Arrange
        final factory1 = () => MockEditorPlugin();
        final factory2 = () => MockEditorPlugin();

        registry.register(manifest: testManifest1, factory: factory1);
        registry.register(manifest: testManifest2, factory: factory2);

        // Act
        final stats = registry.statistics;

        // Assert
        expect(stats.byAuthor['Test Author'], equals(1));
        expect(stats.byAuthor['Another Author'], equals(1));
      });

      test('should return correct tag statistics', () {
        // Arrange
        final factory1 = () => MockEditorPlugin();
        final factory2 = () => MockEditorPlugin();

        registry.register(manifest: testManifest1, factory: factory1);
        registry.register(manifest: testManifest2, factory: factory2);

        // Act
        final stats = registry.statistics;

        // Assert
        expect(stats.byTags['dart'], equals(1));
        expect(stats.byTags['python'], equals(1));
        expect(stats.byTags['testing'], equals(1));
      });

      test('should handle plugins without author', () {
        // Arrange
        final manifestNoAuthor = PluginManifest(
          id: 'plugin-3',
          name: 'No Author Plugin',
          version: '1.0.0',
        );
        final factory = () => MockEditorPlugin();
        registry.register(manifest: manifestNoAuthor, factory: factory);

        // Act
        final stats = registry.statistics;

        // Assert
        expect(stats.byAuthor['Unknown'], equals(1));
      });
    });

    group('Use Cases', () {
      group('UC1: Plugin discovery and loading', () {
        test('should register, discover, and load plugin', () async {
          // Arrange
          final mockPlugin = MockEditorPlugin();
          final factory = () => mockPlugin;

          // Act - Register
          registry.register(
            manifest: testManifest1,
            factory: factory,
            autoLoad: true,
          );

          // Act - Discover
          final autoLoadPlugins = registry.autoLoadEntries;

          // Act - Load
          final instance = await registry.getInstance('plugin-1');

          // Assert
          expect(autoLoadPlugins.length, equals(1));
          expect(instance, equals(mockPlugin));
        });
      });

      group('UC2: Query plugins by criteria', () {
        test('should find plugins for specific language', () {
          // Arrange
          final factory1 = () => MockEditorPlugin();
          final factory2 = () => MockEditorPlugin();

          registry.register(manifest: testManifest1, factory: factory1);
          registry.register(manifest: testManifest2, factory: factory2);

          // Act
          final dartPlugins = registry.getByLanguage('dart');
          final pythonPlugins = registry.query(tags: ['python']);

          // Assert
          expect(dartPlugins.length, equals(1));
          expect(dartPlugins.first.id, equals('plugin-1'));

          expect(pythonPlugins.length, equals(1));
          expect(pythonPlugins.first.id, equals('plugin-2'));
        });
      });

      group('UC3: Plugin lifecycle management', () {
        test('should register, load, and unregister plugin', () async {
          // Arrange
          final mockPlugin = MockEditorPlugin();
          final factory = () => mockPlugin;

          // Act - Register
          registry.register(manifest: testManifest1, factory: factory);
          expect(registry.isRegistered('plugin-1'), isTrue);

          // Act - Load
          final instance = await registry.getInstance('plugin-1');
          expect(instance, equals(mockPlugin));

          // Act - Unregister
          registry.unregister('plugin-1');
          expect(registry.isRegistered('plugin-1'), isFalse);
        });
      });

      group('UC4: Analyze plugin ecosystem', () {
        test('should provide statistics and dependency graph', () {
          // Arrange
          final factory1 = () => MockEditorPlugin();
          final factory2 = () => MockEditorPlugin();

          registry.register(
            manifest: testManifest1,
            factory: factory1,
            autoLoad: true,
          );
          registry.register(manifest: testManifest2, factory: factory2);

          // Act
          final stats = registry.statistics;
          final depGraph = registry.getDependencyGraph();

          // Assert
          expect(stats.totalPlugins, equals(2));
          expect(stats.autoLoadPlugins, equals(1));
          expect(stats.byAuthor.length, equals(2));

          expect(depGraph['plugin-2'], equals(['plugin-1']));
        });
      });
    });
  });
}
