import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_editor_plugins/src/services/plugin_ui_service.dart';
import 'package:multi_editor_plugins/src/ui/plugin_ui_descriptor.dart';

// Concrete implementation for testing
class TestPluginUIService implements PluginUIService {
  final Map<String, PluginUIDescriptor> _descriptors = {};
  final StreamController<PluginUIUpdateEvent> _updatesController =
      StreamController<PluginUIUpdateEvent>.broadcast();

  @override
  void registerUI(PluginUIDescriptor descriptor) {
    final isUpdate = _descriptors.containsKey(descriptor.pluginId);
    _descriptors[descriptor.pluginId] = descriptor;

    final eventType = isUpdate
        ? PluginUIUpdateType.updated
        : PluginUIUpdateType.registered;

    _updatesController.add(PluginUIUpdateEvent(
      type: eventType,
      descriptor: descriptor,
    ));
  }

  @override
  void unregisterUI(String pluginId) {
    final descriptor = _descriptors.remove(pluginId);
    if (descriptor != null) {
      _updatesController.add(PluginUIUpdateEvent(
        type: PluginUIUpdateType.unregistered,
        descriptor: descriptor,
      ));
    }
  }

  @override
  List<PluginUIDescriptor> getRegisteredUIs() {
    final list = _descriptors.values.toList();
    list.sort((a, b) => a.priority.compareTo(b.priority));
    return list;
  }

  @override
  PluginUIDescriptor? getUI(String pluginId) {
    return _descriptors[pluginId];
  }

  @override
  Stream<PluginUIUpdateEvent> get updates => _updatesController.stream;

  @override
  bool hasUI(String pluginId) {
    return _descriptors.containsKey(pluginId);
  }

  void dispose() {
    _updatesController.close();
  }
}

class MockPluginUIService extends Mock implements PluginUIService {}

void main() {
  setUpAll(() {
    registerFallbackValue(PluginUIDescriptor(
      pluginId: 'fallback',
      iconCode: 0,
      tooltip: 'fallback',
      uiData: {},
    ));
  });

  group('PluginUIService', () {
    group('concrete implementation', () {
      late TestPluginUIService service;
      late PluginUIDescriptor testDescriptor;

      setUp(() {
        service = TestPluginUIService();
        testDescriptor = PluginUIDescriptor(
          pluginId: 'test-plugin',
          iconCode: 0xe3a8,
          iconFamily: 'MaterialIcons',
          tooltip: 'Test Plugin',
          label: 'Test',
          uiData: {'type': 'list', 'items': []},
          priority: 100,
        );
      });

      tearDown(() {
        service.dispose();
      });

      group('registerUI', () {
        test('should register new plugin UI', () {
          // Act
          service.registerUI(testDescriptor);

          // Assert
          expect(service.hasUI('test-plugin'), true);
          expect(service.getUI('test-plugin'), equals(testDescriptor));
        });

        test('should emit registered event on new registration', () async {
          // Arrange
          final events = <PluginUIUpdateEvent>[];
          service.updates.listen(events.add);

          // Act
          service.registerUI(testDescriptor);
          await Future.delayed(Duration.zero);

          // Assert
          expect(events.length, 1);
          expect(events[0].type, PluginUIUpdateType.registered);
          expect(events[0].descriptor, testDescriptor);
        });

        test('should replace existing UI when registering same plugin',
            () {
          // Arrange
          service.registerUI(testDescriptor);
          final updatedDescriptor = testDescriptor.copyWith(
            label: 'Updated Test',
          );

          // Act
          service.registerUI(updatedDescriptor);

          // Assert
          expect(service.getUI('test-plugin'), equals(updatedDescriptor));
          expect(service.getUI('test-plugin')!.label, 'Updated Test');
        });

        test('should emit updated event when replacing existing UI', () async {
          // Arrange
          service.registerUI(testDescriptor);
          final events = <PluginUIUpdateEvent>[];
          service.updates.listen(events.add);

          final updatedDescriptor = testDescriptor.copyWith(
            label: 'Updated Test',
          );

          // Act
          service.registerUI(updatedDescriptor);
          await Future.delayed(Duration.zero);

          // Assert
          expect(events.length, 1);
          expect(events[0].type, PluginUIUpdateType.updated);
          expect(events[0].descriptor, updatedDescriptor);
        });

        test('should handle multiple plugin registrations', () {
          // Arrange
          final descriptors = List.generate(
            5,
            (i) => PluginUIDescriptor(
              pluginId: 'plugin-$i',
              iconCode: 0xe000 + i,
              tooltip: 'Plugin $i',
              uiData: {},
            ),
          );

          // Act
          for (final descriptor in descriptors) {
            service.registerUI(descriptor);
          }

          // Assert
          expect(service.getRegisteredUIs().length, 5);
          for (var i = 0; i < 5; i++) {
            expect(service.hasUI('plugin-$i'), true);
          }
        });

        test('should handle UI with minimal properties', () {
          // Arrange
          final minimalDescriptor = PluginUIDescriptor(
            pluginId: 'minimal',
            iconCode: 0xe000,
            tooltip: 'Minimal',
            uiData: {},
          );

          // Act
          service.registerUI(minimalDescriptor);

          // Assert
          expect(service.hasUI('minimal'), true);
          final registered = service.getUI('minimal');
          expect(registered!.iconFamily, null);
          expect(registered.label, null);
        });

        test('should handle UI with all properties', () {
          // Arrange
          final fullDescriptor = PluginUIDescriptor(
            pluginId: 'full',
            iconCode: 0xe000,
            iconFamily: 'CustomFont',
            tooltip: 'Full descriptor',
            label: 'Full',
            uiData: {'key': 'value', 'nested': {'data': 'here'}},
            priority: 50,
          );

          // Act
          service.registerUI(fullDescriptor);

          // Assert
          final registered = service.getUI('full');
          expect(registered!.iconFamily, 'CustomFont');
          expect(registered.label, 'Full');
          expect(registered.uiData['nested'], {'data': 'here'});
          expect(registered.priority, 50);
        });
      });

      group('unregisterUI', () {
        test('should remove registered UI', () {
          // Arrange
          service.registerUI(testDescriptor);

          // Act
          service.unregisterUI('test-plugin');

          // Assert
          expect(service.hasUI('test-plugin'), false);
          expect(service.getUI('test-plugin'), null);
        });

        test('should emit unregistered event', () async {
          // Arrange
          service.registerUI(testDescriptor);
          final events = <PluginUIUpdateEvent>[];
          service.updates.listen(events.add);

          // Act
          service.unregisterUI('test-plugin');
          await Future.delayed(Duration.zero);

          // Assert
          expect(events.length, 1);
          expect(events[0].type, PluginUIUpdateType.unregistered);
          expect(events[0].descriptor.pluginId, 'test-plugin');
        });

        test('should be safe to call for non-existent plugin', () {
          // Act & Assert - Should not throw
          service.unregisterUI('nonexistent-plugin');
          expect(service.hasUI('nonexistent-plugin'), false);
        });

        test('should not emit event when unregistering non-existent UI',
            () async {
          // Arrange
          final events = <PluginUIUpdateEvent>[];
          service.updates.listen(events.add);

          // Act
          service.unregisterUI('nonexistent');
          await Future.delayed(Duration.zero);

          // Assert
          expect(events, isEmpty);
        });

        test('should handle unregistering all plugins', () {
          // Arrange
          for (var i = 0; i < 5; i++) {
            service.registerUI(PluginUIDescriptor(
              pluginId: 'plugin-$i',
              iconCode: 0xe000,
              tooltip: 'Plugin $i',
              uiData: {},
            ));
          }

          // Act
          for (var i = 0; i < 5; i++) {
            service.unregisterUI('plugin-$i');
          }

          // Assert
          expect(service.getRegisteredUIs(), isEmpty);
        });
      });

      group('getRegisteredUIs', () {
        test('should return empty list when no UIs registered', () {
          // Act
          final result = service.getRegisteredUIs();

          // Assert
          expect(result, isEmpty);
        });

        test('should return all registered UIs', () {
          // Arrange
          final descriptors = List.generate(
            3,
            (i) => PluginUIDescriptor(
              pluginId: 'plugin-$i',
              iconCode: 0xe000,
              tooltip: 'Plugin $i',
              uiData: {},
            ),
          );
          for (final descriptor in descriptors) {
            service.registerUI(descriptor);
          }

          // Act
          final result = service.getRegisteredUIs();

          // Assert
          expect(result.length, 3);
        });

        test('should return UIs sorted by priority (lower first)', () {
          // Arrange
          service.registerUI(PluginUIDescriptor(
            pluginId: 'high-priority',
            iconCode: 0xe000,
            tooltip: 'High',
            uiData: {},
            priority: 10,
          ));
          service.registerUI(PluginUIDescriptor(
            pluginId: 'low-priority',
            iconCode: 0xe000,
            tooltip: 'Low',
            uiData: {},
            priority: 100,
          ));
          service.registerUI(PluginUIDescriptor(
            pluginId: 'medium-priority',
            iconCode: 0xe000,
            tooltip: 'Medium',
            uiData: {},
            priority: 50,
          ));

          // Act
          final result = service.getRegisteredUIs();

          // Assert
          expect(result[0].pluginId, 'high-priority');
          expect(result[1].pluginId, 'medium-priority');
          expect(result[2].pluginId, 'low-priority');
        });

        test('should handle equal priorities', () {
          // Arrange
          service.registerUI(PluginUIDescriptor(
            pluginId: 'plugin-a',
            iconCode: 0xe000,
            tooltip: 'A',
            uiData: {},
            priority: 50,
          ));
          service.registerUI(PluginUIDescriptor(
            pluginId: 'plugin-b',
            iconCode: 0xe000,
            tooltip: 'B',
            uiData: {},
            priority: 50,
          ));

          // Act
          final result = service.getRegisteredUIs();

          // Assert
          expect(result.length, 2);
          expect(result.every((d) => d.priority == 50), true);
        });
      });

      group('getUI', () {
        test('should return UI for registered plugin', () {
          // Arrange
          service.registerUI(testDescriptor);

          // Act
          final result = service.getUI('test-plugin');

          // Assert
          expect(result, equals(testDescriptor));
        });

        test('should return null for non-existent plugin', () {
          // Act
          final result = service.getUI('nonexistent');

          // Assert
          expect(result, null);
        });

        test('should return updated UI after re-registration', () {
          // Arrange
          service.registerUI(testDescriptor);
          final updatedDescriptor = testDescriptor.copyWith(
            label: 'Updated',
          );
          service.registerUI(updatedDescriptor);

          // Act
          final result = service.getUI('test-plugin');

          // Assert
          expect(result!.label, 'Updated');
        });
      });

      group('hasUI', () {
        test('should return true for registered plugin', () {
          // Arrange
          service.registerUI(testDescriptor);

          // Act
          final result = service.hasUI('test-plugin');

          // Assert
          expect(result, true);
        });

        test('should return false for non-existent plugin', () {
          // Act
          final result = service.hasUI('nonexistent');

          // Assert
          expect(result, false);
        });

        test('should return false after unregistering', () {
          // Arrange
          service.registerUI(testDescriptor);
          service.unregisterUI('test-plugin');

          // Act
          final result = service.hasUI('test-plugin');

          // Assert
          expect(result, false);
        });
      });

      group('updates stream', () {
        test('should emit events in correct order', () async {
          // Arrange
          final events = <PluginUIUpdateEvent>[];
          service.updates.listen(events.add);

          // Act
          service.registerUI(testDescriptor);
          await Future.delayed(Duration.zero);

          final updated = testDescriptor.copyWith(label: 'Updated');
          service.registerUI(updated);
          await Future.delayed(Duration.zero);

          service.unregisterUI('test-plugin');
          await Future.delayed(Duration.zero);

          // Assert
          expect(events.length, 3);
          expect(events[0].type, PluginUIUpdateType.registered);
          expect(events[1].type, PluginUIUpdateType.updated);
          expect(events[2].type, PluginUIUpdateType.unregistered);
        });

        test('should support multiple listeners', () async {
          // Arrange
          final events1 = <PluginUIUpdateEvent>[];
          final events2 = <PluginUIUpdateEvent>[];
          service.updates.listen(events1.add);
          service.updates.listen(events2.add);

          // Act
          service.registerUI(testDescriptor);
          await Future.delayed(Duration.zero);

          // Assert
          expect(events1.length, 1);
          expect(events2.length, 1);
        });

        test('should handle listener added after registration', () async {
          // Arrange
          service.registerUI(testDescriptor);

          final events = <PluginUIUpdateEvent>[];
          service.updates.listen(events.add);

          // Act
          service.unregisterUI('test-plugin');
          await Future.delayed(Duration.zero);

          // Assert
          expect(events.length, 1);
          expect(events[0].type, PluginUIUpdateType.unregistered);
        });
      });

      group('integration scenarios', () {
        test('should handle complete lifecycle', () async {
          // Arrange
          final events = <PluginUIUpdateEvent>[];
          service.updates.listen(events.add);

          // Act & Assert - Register
          service.registerUI(testDescriptor);
          await Future.delayed(Duration.zero);
          expect(service.hasUI('test-plugin'), true);
          expect(events.length, 1);

          // Act & Assert - Update
          final updated = testDescriptor.copyWith(label: 'Updated');
          service.registerUI(updated);
          await Future.delayed(Duration.zero);
          expect(service.getUI('test-plugin')!.label, 'Updated');
          expect(events.length, 2);

          // Act & Assert - Unregister
          service.unregisterUI('test-plugin');
          await Future.delayed(Duration.zero);
          expect(service.hasUI('test-plugin'), false);
          expect(events.length, 3);
        });

        test('should handle multiple plugins with different priorities',
            () async {
          // Arrange
          final plugins = [
            PluginUIDescriptor(
              pluginId: 'sidebar',
              iconCode: 0xe000,
              tooltip: 'Sidebar',
              uiData: {},
              priority: 10,
            ),
            PluginUIDescriptor(
              pluginId: 'toolbar',
              iconCode: 0xe001,
              tooltip: 'Toolbar',
              uiData: {},
              priority: 5,
            ),
            PluginUIDescriptor(
              pluginId: 'panel',
              iconCode: 0xe002,
              tooltip: 'Panel',
              uiData: {},
              priority: 20,
            ),
          ];

          // Act
          for (final plugin in plugins) {
            service.registerUI(plugin);
          }

          // Assert
          final registered = service.getRegisteredUIs();
          expect(registered[0].pluginId, 'toolbar'); // Priority 5
          expect(registered[1].pluginId, 'sidebar'); // Priority 10
          expect(registered[2].pluginId, 'panel'); // Priority 20
        });
      });

      group('edge cases', () {
        test('should handle plugin IDs with special characters', () {
          // Arrange
          final descriptor = PluginUIDescriptor(
            pluginId: 'plugin.with-special_chars:123',
            iconCode: 0xe000,
            tooltip: 'Special',
            uiData: {},
          );

          // Act
          service.registerUI(descriptor);

          // Assert
          expect(service.hasUI('plugin.with-special_chars:123'), true);
        });

        test('should handle empty uiData', () {
          // Arrange
          final descriptor = PluginUIDescriptor(
            pluginId: 'empty-data',
            iconCode: 0xe000,
            tooltip: 'Empty',
            uiData: {},
          );

          // Act
          service.registerUI(descriptor);

          // Assert
          expect(service.getUI('empty-data')!.uiData, isEmpty);
        });

        test('should handle complex nested uiData', () {
          // Arrange
          final descriptor = PluginUIDescriptor(
            pluginId: 'complex',
            iconCode: 0xe000,
            tooltip: 'Complex',
            uiData: {
              'type': 'list',
              'items': [
                {'id': '1', 'nested': {'deep': 'value'}},
                {'id': '2', 'array': [1, 2, 3]},
              ],
              'metadata': {'version': '1.0'},
            },
          );

          // Act
          service.registerUI(descriptor);

          // Assert
          final registered = service.getUI('complex');
          expect(registered!.uiData['items'], hasLength(2));
          expect(registered.uiData['metadata']['version'], '1.0');
        });

        test('should handle rapid register/unregister cycles', () async {
          // Act
          for (var i = 0; i < 100; i++) {
            service.registerUI(testDescriptor);
            if (i % 2 == 0) {
              service.unregisterUI('test-plugin');
            }
          }

          // Assert
          expect(service.hasUI('test-plugin'), true); // Last was register
        });
      });
    });

    group('mock implementation', () {
      late MockPluginUIService mockService;

      setUp(() {
        mockService = MockPluginUIService();
      });

      test('should allow mocking registerUI', () {
        // Arrange
        when(() => mockService.registerUI(any())).thenReturn(null);

        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: 0xe000,
          tooltip: 'Test',
          uiData: {},
        );

        // Act
        mockService.registerUI(descriptor);

        // Assert
        verify(() => mockService.registerUI(descriptor)).called(1);
      });

      test('should allow mocking getUI', () {
        // Arrange
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: 0xe000,
          tooltip: 'Test',
          uiData: {},
        );
        when(() => mockService.getUI('test')).thenReturn(descriptor);

        // Act
        final result = mockService.getUI('test');

        // Assert
        expect(result, descriptor);
      });

      test('should allow mocking hasUI', () {
        // Arrange
        when(() => mockService.hasUI('test')).thenReturn(true);

        // Act
        final result = mockService.hasUI('test');

        // Assert
        expect(result, true);
      });

      test('should allow mocking updates stream', () {
        // Arrange
        final controller = StreamController<PluginUIUpdateEvent>();
        when(() => mockService.updates).thenAnswer((_) => controller.stream);

        // Act
        final stream = mockService.updates;

        // Assert
        expect(stream, isA<Stream<PluginUIUpdateEvent>>());

        controller.close();
      });
    });
  });
}
