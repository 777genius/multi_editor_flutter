import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import 'package:multi_editor_ui/src/plugins/plugin_ui_registry.dart';

void main() {
  group('PluginUIRegistry Tests', () {
    late PluginUIRegistry registry;

    setUp(() {
      registry = PluginUIRegistry();
    });

    tearDown(() {
      registry.dispose();
    });

    group('Registration', () {
      test('should register UI descriptor', () {
        // Arrange
        final descriptor = PluginUIDescriptor(
          pluginId: 'test-plugin',
          iconCode: Icons.star.codePoint,
          tooltip: 'Test',
          uiData: const {},
        );

        // Act
        registry.registerUI(descriptor);

        // Assert
        expect(registry.hasUI('test-plugin'), isTrue);
        expect(registry.getUI('test-plugin'), equals(descriptor));
      });

      test('should update existing UI descriptor', () {
        // Arrange
        final descriptor1 = PluginUIDescriptor(
          pluginId: 'test-plugin',
          iconCode: Icons.star.codePoint,
          tooltip: 'Test 1',
          uiData: const {},
        );
        final descriptor2 = PluginUIDescriptor(
          pluginId: 'test-plugin',
          iconCode: Icons.favorite.codePoint,
          tooltip: 'Test 2',
          uiData: const {},
        );

        // Act
        registry.registerUI(descriptor1);
        registry.registerUI(descriptor2);

        // Assert
        expect(registry.getUI('test-plugin'), equals(descriptor2));
      });

      test('should emit registration event', () {
        // Arrange
        final descriptor = PluginUIDescriptor(
          pluginId: 'test-plugin',
          iconCode: Icons.star.codePoint,
          tooltip: 'Test',
          uiData: const {},
        );

        PluginUIUpdateEvent? event;
        registry.updates.listen((e) => event = e);

        // Act
        registry.registerUI(descriptor);

        // Assert
        expect(event, isNotNull);
        expect(event!.type, equals(PluginUIUpdateType.registered));
        expect(event!.descriptor, equals(descriptor));
      });
    });

    group('Unregistration', () {
      test('should unregister UI descriptor', () {
        // Arrange
        final descriptor = PluginUIDescriptor(
          pluginId: 'test-plugin',
          iconCode: Icons.star.codePoint,
          tooltip: 'Test',
          uiData: const {},
        );
        registry.registerUI(descriptor);

        // Act
        registry.unregisterUI('test-plugin');

        // Assert
        expect(registry.hasUI('test-plugin'), isFalse);
        expect(registry.getUI('test-plugin'), isNull);
      });

      test('should emit unregistration event', () {
        // Arrange
        final descriptor = PluginUIDescriptor(
          pluginId: 'test-plugin',
          iconCode: Icons.star.codePoint,
          tooltip: 'Test',
          uiData: const {},
        );
        registry.registerUI(descriptor);

        PluginUIUpdateEvent? event;
        final subscription = registry.updates.listen((e) {
          if (e.type == PluginUIUpdateType.unregistered) {
            event = e;
          }
        });

        // Act
        registry.unregisterUI('test-plugin');

        // Assert
        expect(event, isNotNull);
        expect(event!.type, equals(PluginUIUpdateType.unregistered));

        subscription.cancel();
      });

      test('should handle unregistering non-existent plugin', () {
        // Act & Assert - should not throw
        expect(() => registry.unregisterUI('non-existent'), returnsNormally);
      });
    });

    group('Query', () {
      test('should return all registered UIs', () {
        // Arrange
        final descriptor1 = PluginUIDescriptor(
          pluginId: 'plugin-1',
          iconCode: Icons.star.codePoint,
          tooltip: 'Plugin 1',
          priority: 1,
          uiData: const {},
        );
        final descriptor2 = PluginUIDescriptor(
          pluginId: 'plugin-2',
          iconCode: Icons.favorite.codePoint,
          tooltip: 'Plugin 2',
          priority: 2,
          uiData: const {},
        );

        registry.registerUI(descriptor1);
        registry.registerUI(descriptor2);

        // Act
        final uis = registry.getRegisteredUIs();

        // Assert
        expect(uis.length, equals(2));
        expect(uis, contains(descriptor1));
        expect(uis, contains(descriptor2));
      });

      test('should sort UIs by priority', () {
        // Arrange
        final descriptor1 = PluginUIDescriptor(
          pluginId: 'plugin-1',
          iconCode: Icons.star.codePoint,
          tooltip: 'Plugin 1',
          priority: 2,
          uiData: const {},
        );
        final descriptor2 = PluginUIDescriptor(
          pluginId: 'plugin-2',
          iconCode: Icons.favorite.codePoint,
          tooltip: 'Plugin 2',
          priority: 1,
          uiData: const {},
        );

        registry.registerUI(descriptor1);
        registry.registerUI(descriptor2);

        // Act
        final uis = registry.getRegisteredUIs();

        // Assert
        expect(uis[0].pluginId, equals('plugin-2')); // Lower priority first
        expect(uis[1].pluginId, equals('plugin-1'));
      });

      test('should check if plugin has UI', () {
        // Arrange
        final descriptor = PluginUIDescriptor(
          pluginId: 'test-plugin',
          iconCode: Icons.star.codePoint,
          tooltip: 'Test',
          uiData: const {},
        );
        registry.registerUI(descriptor);

        // Act & Assert
        expect(registry.hasUI('test-plugin'), isTrue);
        expect(registry.hasUI('non-existent'), isFalse);
      });
    });

    group('Statistics', () {
      test('should return statistics', () {
        // Arrange
        final descriptor = PluginUIDescriptor(
          pluginId: 'test-plugin',
          iconCode: Icons.star.codePoint,
          tooltip: 'Test',
          uiData: const {},
        );
        registry.registerUI(descriptor);

        // Act
        final stats = registry.getStatistics();

        // Assert
        expect(stats['totalRegistered'], equals(1));
        expect(stats['plugins'], contains('test-plugin'));
      });
    });

    group('Use Cases', () {
      test('UC1: Register multiple plugin UIs', () {
        // Arrange
        final recentFiles = PluginUIDescriptor(
          pluginId: 'recent-files',
          iconCode: Icons.history.codePoint,
          tooltip: 'Recent Files',
          priority: 1,
          uiData: const {},
        );
        final search = PluginUIDescriptor(
          pluginId: 'search',
          iconCode: Icons.search.codePoint,
          tooltip: 'Search',
          priority: 2,
          uiData: const {},
        );

        // Act
        registry.registerUI(recentFiles);
        registry.registerUI(search);

        // Assert
        final uis = registry.getRegisteredUIs();
        expect(uis.length, equals(2));
        expect(uis[0].pluginId, equals('recent-files'));
        expect(uis[1].pluginId, equals('search'));
      });

      test('UC2: Update plugin UI dynamically', () {
        // Arrange
        final original = PluginUIDescriptor(
          pluginId: 'dynamic-plugin',
          iconCode: Icons.widgets.codePoint,
          tooltip: 'Original',
          uiData: const {'items': []},
        );
        registry.registerUI(original);

        final updated = PluginUIDescriptor(
          pluginId: 'dynamic-plugin',
          iconCode: Icons.widgets.codePoint,
          tooltip: 'Updated',
          uiData: const {
            'items': [
              {'id': '1', 'title': 'New Item'},
            ],
          },
        );

        // Act
        registry.registerUI(updated);

        // Assert
        final current = registry.getUI('dynamic-plugin');
        expect(current?.tooltip, equals('Updated'));
        expect(current?.uiData['items'], isNotEmpty);
      });

      test('UC3: Listen to plugin UI updates', () async {
        // Arrange
        final events = <PluginUIUpdateEvent>[];
        final subscription = registry.updates.listen(events.add);

        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.star.codePoint,
          tooltip: 'Test',
          uiData: const {},
        );

        // Act
        registry.registerUI(descriptor);
        await Future.delayed(const Duration(milliseconds: 10));
        registry.unregisterUI('test');
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events.length, equals(2));
        expect(events[0].type, equals(PluginUIUpdateType.registered));
        expect(events[1].type, equals(PluginUIUpdateType.unregistered));

        await subscription.cancel();
      });
    });

    group('Dispose', () {
      test('should close stream controller on dispose', () async {
        // Arrange
        final testRegistry = PluginUIRegistry();
        bool streamClosed = false;

        testRegistry.updates.listen(
          (_) {},
          onDone: () => streamClosed = true,
        );

        // Act
        testRegistry.dispose();
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(streamClosed, isTrue);
      });

      test('should clear registry on dispose', () {
        // Arrange
        final testRegistry = PluginUIRegistry();
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.star.codePoint,
          tooltip: 'Test',
          uiData: const {},
        );
        testRegistry.registerUI(descriptor);

        // Act
        testRegistry.dispose();

        // Assert
        final stats = testRegistry.getStatistics();
        expect(stats['totalRegistered'], equals(0));
        expect(stats['plugins'], isEmpty);
      });

      test('should handle multiple dispose calls gracefully', () {
        // Arrange
        final testRegistry = PluginUIRegistry();

        // Act & Assert - Should not throw
        expect(() {
          testRegistry.dispose();
          testRegistry.dispose();
        }, returnsNormally);
      });
    });

    group('Edge Cases', () {
      test('should handle empty plugin ID', () {
        // Arrange
        final descriptor = PluginUIDescriptor(
          pluginId: '',
          iconCode: Icons.star.codePoint,
          tooltip: 'Test',
          uiData: const {},
        );

        // Act
        registry.registerUI(descriptor);

        // Assert
        expect(registry.hasUI(''), isTrue);
        expect(registry.getUI(''), equals(descriptor));
      });

      test('should handle special characters in plugin ID', () {
        // Arrange
        final descriptor = PluginUIDescriptor(
          pluginId: 'test@plugin#123-v1.0',
          iconCode: Icons.star.codePoint,
          tooltip: 'Test',
          uiData: const {},
        );

        // Act
        registry.registerUI(descriptor);

        // Assert
        expect(registry.hasUI('test@plugin#123-v1.0'), isTrue);
      });

      test('should handle very long plugin ID', () {
        // Arrange
        final longId = 'a' * 1000;
        final descriptor = PluginUIDescriptor(
          pluginId: longId,
          iconCode: Icons.star.codePoint,
          tooltip: 'Test',
          uiData: const {},
        );

        // Act
        registry.registerUI(descriptor);

        // Assert
        expect(registry.hasUI(longId), isTrue);
      });

      test('should handle empty uiData', () {
        // Arrange
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.star.codePoint,
          tooltip: 'Test',
          uiData: const {},
        );

        // Act
        registry.registerUI(descriptor);

        // Assert
        final retrieved = registry.getUI('test');
        expect(retrieved?.uiData, isEmpty);
      });

      test('should handle null tooltip', () {
        // Arrange
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.star.codePoint,
          tooltip: null,
          uiData: const {},
        );

        // Act
        registry.registerUI(descriptor);

        // Assert
        final retrieved = registry.getUI('test');
        expect(retrieved?.tooltip, isNull);
      });

      test('should handle very large number of registrations', () {
        // Arrange & Act
        for (int i = 0; i < 100; i++) {
          final descriptor = PluginUIDescriptor(
            pluginId: 'plugin-$i',
            iconCode: Icons.star.codePoint,
            tooltip: 'Plugin $i',
            priority: i,
            uiData: const {},
          );
          registry.registerUI(descriptor);
        }

        // Assert
        final uis = registry.getRegisteredUIs();
        expect(uis.length, equals(100));
        // Verify sorted by priority
        for (int i = 0; i < uis.length - 1; i++) {
          expect(uis[i].priority, lessThanOrEqualTo(uis[i + 1].priority));
        }
      });

      test('should handle negative priority values', () {
        // Arrange
        final descriptor1 = PluginUIDescriptor(
          pluginId: 'plugin-1',
          iconCode: Icons.star.codePoint,
          tooltip: 'Plugin 1',
          priority: -10,
          uiData: const {},
        );
        final descriptor2 = PluginUIDescriptor(
          pluginId: 'plugin-2',
          iconCode: Icons.favorite.codePoint,
          tooltip: 'Plugin 2',
          priority: 5,
          uiData: const {},
        );

        registry.registerUI(descriptor1);
        registry.registerUI(descriptor2);

        // Act
        final uis = registry.getRegisteredUIs();

        // Assert
        expect(uis[0].pluginId, equals('plugin-1')); // Negative priority comes first
        expect(uis[1].pluginId, equals('plugin-2'));
      });

      test('should handle same priority values', () {
        // Arrange
        final descriptor1 = PluginUIDescriptor(
          pluginId: 'plugin-1',
          iconCode: Icons.star.codePoint,
          tooltip: 'Plugin 1',
          priority: 5,
          uiData: const {},
        );
        final descriptor2 = PluginUIDescriptor(
          pluginId: 'plugin-2',
          iconCode: Icons.favorite.codePoint,
          tooltip: 'Plugin 2',
          priority: 5,
          uiData: const {},
        );

        registry.registerUI(descriptor1);
        registry.registerUI(descriptor2);

        // Act
        final uis = registry.getRegisteredUIs();

        // Assert
        expect(uis.length, equals(2));
        expect(uis[0].priority, equals(5));
        expect(uis[1].priority, equals(5));
      });
    });

    group('Stream Updates', () {
      test('should emit correct event type for registration', () async {
        // Arrange
        final events = <PluginUIUpdateEvent>[];
        final subscription = registry.updates.listen(events.add);

        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.star.codePoint,
          tooltip: 'Test',
          uiData: const {},
        );

        // Act
        registry.registerUI(descriptor);
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events.length, equals(1));
        expect(events[0].type, equals(PluginUIUpdateType.registered));
        expect(events[0].descriptor.pluginId, equals('test'));

        await subscription.cancel();
      });

      test('should emit correct event type for update', () async {
        // Arrange
        final descriptor1 = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.star.codePoint,
          tooltip: 'Original',
          uiData: const {},
        );
        registry.registerUI(descriptor1);

        final events = <PluginUIUpdateEvent>[];
        final subscription = registry.updates.listen(events.add);

        final descriptor2 = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.favorite.codePoint,
          tooltip: 'Updated',
          uiData: const {},
        );

        // Act
        registry.registerUI(descriptor2);
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events.length, equals(1));
        expect(events[0].type, equals(PluginUIUpdateType.updated));
        expect(events[0].descriptor.tooltip, equals('Updated'));

        await subscription.cancel();
      });

      test('should support multiple stream subscribers', () async {
        // Arrange
        final events1 = <PluginUIUpdateEvent>[];
        final events2 = <PluginUIUpdateEvent>[];
        final subscription1 = registry.updates.listen(events1.add);
        final subscription2 = registry.updates.listen(events2.add);

        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.star.codePoint,
          tooltip: 'Test',
          uiData: const {},
        );

        // Act
        registry.registerUI(descriptor);
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events1.length, equals(1));
        expect(events2.length, equals(1));
        expect(events1[0].descriptor.pluginId, equals('test'));
        expect(events2[0].descriptor.pluginId, equals('test'));

        await subscription1.cancel();
        await subscription2.cancel();
      });

      test('should continue emitting after subscriber cancels', () async {
        // Arrange
        final events1 = <PluginUIUpdateEvent>[];
        final events2 = <PluginUIUpdateEvent>[];
        final subscription1 = registry.updates.listen(events1.add);
        final subscription2 = registry.updates.listen(events2.add);

        final descriptor1 = PluginUIDescriptor(
          pluginId: 'test1',
          iconCode: Icons.star.codePoint,
          tooltip: 'Test 1',
          uiData: const {},
        );

        registry.registerUI(descriptor1);
        await Future.delayed(const Duration(milliseconds: 10));

        // Act - Cancel first subscription
        await subscription1.cancel();

        final descriptor2 = PluginUIDescriptor(
          pluginId: 'test2',
          iconCode: Icons.favorite.codePoint,
          tooltip: 'Test 2',
          uiData: const {},
        );
        registry.registerUI(descriptor2);
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events1.length, equals(1)); // Only received first event
        expect(events2.length, equals(2)); // Received both events

        await subscription2.cancel();
      });

      test('should emit events in correct order', () async {
        // Arrange
        final events = <PluginUIUpdateEvent>[];
        final subscription = registry.updates.listen(events.add);

        // Act - Register, update, unregister
        final descriptor1 = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.star.codePoint,
          tooltip: 'Original',
          uiData: const {},
        );
        registry.registerUI(descriptor1);
        await Future.delayed(const Duration(milliseconds: 10));

        final descriptor2 = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.favorite.codePoint,
          tooltip: 'Updated',
          uiData: const {},
        );
        registry.registerUI(descriptor2);
        await Future.delayed(const Duration(milliseconds: 10));

        registry.unregisterUI('test');
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events.length, equals(3));
        expect(events[0].type, equals(PluginUIUpdateType.registered));
        expect(events[1].type, equals(PluginUIUpdateType.updated));
        expect(events[2].type, equals(PluginUIUpdateType.unregistered));

        await subscription.cancel();
      });
    });

    group('Concurrent Operations', () {
      test('should handle rapid registrations', () async {
        // Arrange
        final events = <PluginUIUpdateEvent>[];
        final subscription = registry.updates.listen(events.add);

        // Act - Rapidly register multiple plugins
        for (int i = 0; i < 10; i++) {
          final descriptor = PluginUIDescriptor(
            pluginId: 'plugin-$i',
            iconCode: Icons.star.codePoint,
            tooltip: 'Plugin $i',
            uiData: const {},
          );
          registry.registerUI(descriptor);
        }
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events.length, equals(10));
        expect(registry.getRegisteredUIs().length, equals(10));

        await subscription.cancel();
      });

      test('should handle interleaved register/unregister operations', () async {
        // Arrange & Act
        registry.registerUI(PluginUIDescriptor(
          pluginId: 'plugin-1',
          iconCode: Icons.star.codePoint,
          tooltip: 'Plugin 1',
          uiData: const {},
        ));

        registry.registerUI(PluginUIDescriptor(
          pluginId: 'plugin-2',
          iconCode: Icons.favorite.codePoint,
          tooltip: 'Plugin 2',
          uiData: const {},
        ));

        registry.unregisterUI('plugin-1');

        registry.registerUI(PluginUIDescriptor(
          pluginId: 'plugin-3',
          iconCode: Icons.settings.codePoint,
          tooltip: 'Plugin 3',
          uiData: const {},
        ));

        registry.unregisterUI('plugin-2');

        // Assert
        final uis = registry.getRegisteredUIs();
        expect(uis.length, equals(1));
        expect(uis[0].pluginId, equals('plugin-3'));
      });
    });

    group('Query Edge Cases', () {
      test('should return empty list when no UIs registered', () {
        // Act
        final uis = registry.getRegisteredUIs();

        // Assert
        expect(uis, isEmpty);
      });

      test('should return null for non-existent plugin', () {
        // Act
        final ui = registry.getUI('non-existent');

        // Assert
        expect(ui, isNull);
      });

      test('should return false for hasUI with non-existent plugin', () {
        // Act
        final hasUI = registry.hasUI('non-existent');

        // Assert
        expect(hasUI, isFalse);
      });

      test('should return correct statistics for empty registry', () {
        // Act
        final stats = registry.getStatistics();

        // Assert
        expect(stats['totalRegistered'], equals(0));
        expect(stats['plugins'], isEmpty);
      });
    });

    group('Complex uiData', () {
      test('should handle nested map in uiData', () {
        // Arrange
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.star.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'list',
            'items': [
              {
                'id': '1',
                'title': 'Item 1',
                'metadata': {'key': 'value'},
              },
            ],
          },
        );

        // Act
        registry.registerUI(descriptor);

        // Assert
        final retrieved = registry.getUI('test');
        expect(retrieved?.uiData['type'], equals('list'));
        final items = retrieved?.uiData['items'] as List;
        expect(items.length, equals(1));
      });

      test('should handle large uiData payload', () {
        // Arrange
        final largeList = List.generate(
          1000,
          (i) => {'id': 'item-$i', 'title': 'Item $i'},
        );
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.star.codePoint,
          tooltip: 'Test',
          uiData: {
            'type': 'list',
            'items': largeList,
          },
        );

        // Act
        registry.registerUI(descriptor);

        // Assert
        final retrieved = registry.getUI('test');
        final items = retrieved?.uiData['items'] as List;
        expect(items.length, equals(1000));
      });
    });
  });
}
