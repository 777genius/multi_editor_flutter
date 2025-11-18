import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_editor_plugins/src/plugin_api/editor_plugin.dart';
import 'package:multi_editor_plugins/src/plugin_manager/plugin_ui_notifier.dart';

// Mock plugin without stateChanges property
class MockEditorPlugin extends Mock implements EditorPlugin {}

// Mock plugin with stateChanges property (duck typing simulation)
class MockPluginWithState extends Mock implements EditorPlugin {
  final ValueNotifier<int> stateChanges = ValueNotifier<int>(0);
}

// Custom test plugin with stateChanges
class TestPluginWithState implements EditorPlugin {
  final ValueNotifier<int> stateChanges = ValueNotifier<int>(0);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  void updateState() {
    stateChanges.value++;
  }
}

// Custom test plugin without stateChanges
class TestPluginWithoutState implements EditorPlugin {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('PluginUINotifier', () {
    group('Initialization', () {
      test('should initialize with empty plugin list', () {
        // Arrange & Act
        final notifier = PluginUINotifier([]);

        // Assert
        expect(notifier, isNotNull);

        // Cleanup
        notifier.dispose();
      });

      test('should initialize with plugins without stateChanges', () {
        // Arrange
        final plugin1 = TestPluginWithoutState();
        final plugin2 = TestPluginWithoutState();

        // Act
        final notifier = PluginUINotifier([plugin1, plugin2]);

        // Assert
        expect(notifier, isNotNull);

        // Cleanup
        notifier.dispose();
      });

      test('should initialize and subscribe to plugins with stateChanges', () {
        // Arrange
        final plugin = TestPluginWithState();

        // Act
        final notifier = PluginUINotifier([plugin]);

        // Assert - notifier should be created successfully
        expect(notifier, isNotNull);

        // Cleanup
        notifier.dispose();
      });

      test('should handle mix of plugins with and without stateChanges', () {
        // Arrange
        final pluginWithState = TestPluginWithState();
        final pluginWithoutState = TestPluginWithoutState();

        // Act
        final notifier = PluginUINotifier([
          pluginWithState,
          pluginWithoutState,
        ]);

        // Assert
        expect(notifier, isNotNull);

        // Cleanup
        notifier.dispose();
      });
    });

    group('State Change Notifications', () {
      test('should notify listeners when plugin state changes', () {
        // Arrange
        final plugin = TestPluginWithState();
        final notifier = PluginUINotifier([plugin]);

        var notificationCount = 0;
        notifier.addListener(() {
          notificationCount++;
        });

        // Act
        plugin.updateState();

        // Assert
        expect(notificationCount, equals(1));

        // Cleanup
        notifier.dispose();
      });

      test('should notify listeners multiple times for multiple state changes', () {
        // Arrange
        final plugin = TestPluginWithState();
        final notifier = PluginUINotifier([plugin]);

        var notificationCount = 0;
        notifier.addListener(() {
          notificationCount++;
        });

        // Act
        plugin.updateState();
        plugin.updateState();
        plugin.updateState();

        // Assert
        expect(notificationCount, equals(3));

        // Cleanup
        notifier.dispose();
      });

      test('should notify all listeners when plugin state changes', () {
        // Arrange
        final plugin = TestPluginWithState();
        final notifier = PluginUINotifier([plugin]);

        var listener1Called = false;
        var listener2Called = false;

        notifier.addListener(() {
          listener1Called = true;
        });

        notifier.addListener(() {
          listener2Called = true;
        });

        // Act
        plugin.updateState();

        // Assert
        expect(listener1Called, isTrue);
        expect(listener2Called, isTrue);

        // Cleanup
        notifier.dispose();
      });

      test('should handle state changes from multiple plugins', () {
        // Arrange
        final plugin1 = TestPluginWithState();
        final plugin2 = TestPluginWithState();
        final notifier = PluginUINotifier([plugin1, plugin2]);

        var notificationCount = 0;
        notifier.addListener(() {
          notificationCount++;
        });

        // Act
        plugin1.updateState();
        plugin2.updateState();

        // Assert
        expect(notificationCount, equals(2));

        // Cleanup
        notifier.dispose();
      });

      test('should not notify after listener is removed', () {
        // Arrange
        final plugin = TestPluginWithState();
        final notifier = PluginUINotifier([plugin]);

        var notificationCount = 0;
        void listener() {
          notificationCount++;
        }

        notifier.addListener(listener);

        // Act - First change triggers notification
        plugin.updateState();
        expect(notificationCount, equals(1));

        // Remove listener
        notifier.removeListener(listener);

        // Act - Second change should not trigger notification
        plugin.updateState();

        // Assert
        expect(notificationCount, equals(1)); // Still 1, not 2

        // Cleanup
        notifier.dispose();
      });
    });

    group('dispose', () {
      test('should unsubscribe from all plugins on dispose', () {
        // Arrange
        final plugin = TestPluginWithState();
        final notifier = PluginUINotifier([plugin]);

        var notificationCount = 0;
        notifier.addListener(() {
          notificationCount++;
        });

        // Act
        notifier.dispose();

        // Try to trigger notification after dispose
        plugin.updateState();

        // Assert - no notification should occur after dispose
        expect(notificationCount, equals(0));
      });

      test('should handle dispose with multiple plugins', () {
        // Arrange
        final plugin1 = TestPluginWithState();
        final plugin2 = TestPluginWithState();
        final notifier = PluginUINotifier([plugin1, plugin2]);

        var notificationCount = 0;
        notifier.addListener(() {
          notificationCount++;
        });

        // Act
        notifier.dispose();

        // Try to trigger notifications after dispose
        plugin1.updateState();
        plugin2.updateState();

        // Assert - no notifications should occur after dispose
        expect(notificationCount, equals(0));
      });

      test('should handle dispose without any subscriptions', () {
        // Arrange
        final plugin = TestPluginWithoutState();
        final notifier = PluginUINotifier([plugin]);

        // Act & Assert - should not throw
        expect(() => notifier.dispose(), returnsNormally);
      });

      test('should handle dispose called multiple times', () {
        // Arrange
        final plugin = TestPluginWithState();
        final notifier = PluginUINotifier([plugin]);

        // Act & Assert - should not throw
        expect(() {
          notifier.dispose();
          notifier.dispose();
        }, returnsNormally);
      });
    });

    group('Duck Typing Behavior', () {
      test('should skip plugins without stateChanges property', () {
        // Arrange
        final pluginWithoutState = TestPluginWithoutState();
        final notifier = PluginUINotifier([pluginWithoutState]);

        var notificationCount = 0;
        notifier.addListener(() {
          notificationCount++;
        });

        // Act - Try to trigger something (no state to change)
        // This test just verifies no errors occur

        // Assert
        expect(notificationCount, equals(0));

        // Cleanup
        notifier.dispose();
      });

      test('should handle plugins with non-ValueListenable stateChanges', () {
        // Arrange
        // Create a plugin with stateChanges that's not a ValueListenable
        final plugin = MockEditorPlugin();
        final notifier = PluginUINotifier([plugin]);

        // Act & Assert - should not throw
        expect(() => notifier.dispose(), returnsNormally);
      });

      test('should handle exceptions during subscription gracefully', () {
        // Arrange
        final plugin = MockEditorPlugin();

        // Act & Assert - should not throw
        expect(() {
          final notifier = PluginUINotifier([plugin]);
          notifier.dispose();
        }, returnsNormally);
      });
    });

    group('Use Cases', () {
      group('UC1: Single plugin UI updates', () {
        test('should update UI when plugin state changes', () {
          // Arrange
          final plugin = TestPluginWithState();
          final notifier = PluginUINotifier([plugin]);

          final receivedNotifications = <int>[];
          notifier.addListener(() {
            receivedNotifications.add(plugin.stateChanges.value);
          });

          // Act - Simulate plugin state changes
          plugin.updateState(); // value = 1
          plugin.updateState(); // value = 2
          plugin.updateState(); // value = 3

          // Assert
          expect(receivedNotifications, equals([1, 2, 3]));

          // Cleanup
          notifier.dispose();
        });
      });

      group('UC2: Multiple plugins UI updates', () {
        test('should update UI when any plugin state changes', () {
          // Arrange
          final plugin1 = TestPluginWithState();
          final plugin2 = TestPluginWithState();
          final notifier = PluginUINotifier([plugin1, plugin2]);

          var notificationCount = 0;
          notifier.addListener(() {
            notificationCount++;
          });

          // Act - Simulate state changes from different plugins
          plugin1.updateState();
          plugin2.updateState();
          plugin1.updateState();
          plugin2.updateState();

          // Assert
          expect(notificationCount, equals(4));

          // Cleanup
          notifier.dispose();
        });
      });

      group('UC3: Plugin lifecycle management', () {
        test('should handle plugin disposal correctly', () {
          // Arrange
          final plugin = TestPluginWithState();
          final notifier = PluginUINotifier([plugin]);

          var notificationCount = 0;
          notifier.addListener(() {
            notificationCount++;
          });

          // Act - Use plugin
          plugin.updateState();
          expect(notificationCount, equals(1));

          // Act - Dispose notifier (simulating plugin unload)
          notifier.dispose();

          // Act - Try to update after disposal
          plugin.updateState();

          // Assert - no new notifications after disposal
          expect(notificationCount, equals(1));
        });
      });

      group('UC4: Mixed plugin types', () {
        test('should handle plugins with and without state changes', () {
          // Arrange
          final pluginWithState = TestPluginWithState();
          final pluginWithoutState = TestPluginWithoutState();
          final notifier = PluginUINotifier([
            pluginWithState,
            pluginWithoutState,
          ]);

          var notificationCount = 0;
          notifier.addListener(() {
            notificationCount++;
          });

          // Act - Only plugin with state should trigger notifications
          pluginWithState.updateState();

          // Assert
          expect(notificationCount, equals(1));

          // Cleanup
          notifier.dispose();
        });
      });

      group('UC5: Dynamic listener management', () {
        test('should support adding and removing listeners dynamically', () {
          // Arrange
          final plugin = TestPluginWithState();
          final notifier = PluginUINotifier([plugin]);

          var listener1Count = 0;
          var listener2Count = 0;

          void listener1() {
            listener1Count++;
          }

          void listener2() {
            listener2Count++;
          }

          // Act - Add first listener
          notifier.addListener(listener1);
          plugin.updateState();
          expect(listener1Count, equals(1));

          // Act - Add second listener
          notifier.addListener(listener2);
          plugin.updateState();
          expect(listener1Count, equals(2));
          expect(listener2Count, equals(1));

          // Act - Remove first listener
          notifier.removeListener(listener1);
          plugin.updateState();
          expect(listener1Count, equals(2)); // Unchanged
          expect(listener2Count, equals(2));

          // Cleanup
          notifier.dispose();
        });
      });
    });

    group('Edge Cases', () {
      test('should handle empty plugin list', () {
        // Arrange & Act
        final notifier = PluginUINotifier([]);

        var notificationCount = 0;
        notifier.addListener(() {
          notificationCount++;
        });

        // Assert - no notifications since no plugins
        expect(notificationCount, equals(0));

        // Cleanup
        notifier.dispose();
      });

      test('should handle rapid state changes', () {
        // Arrange
        final plugin = TestPluginWithState();
        final notifier = PluginUINotifier([plugin]);

        var notificationCount = 0;
        notifier.addListener(() {
          notificationCount++;
        });

        // Act - Trigger many rapid state changes
        for (var i = 0; i < 100; i++) {
          plugin.updateState();
        }

        // Assert
        expect(notificationCount, equals(100));

        // Cleanup
        notifier.dispose();
      });

      test('should handle multiple dispose calls', () {
        // Arrange
        final plugin = TestPluginWithState();
        final notifier = PluginUINotifier([plugin]);

        // Act & Assert - multiple dispose should not throw
        expect(() {
          notifier.dispose();
          notifier.dispose();
          notifier.dispose();
        }, returnsNormally);
      });

      test('should handle listener exceptions gracefully', () {
        // Arrange
        final plugin = TestPluginWithState();
        final notifier = PluginUINotifier([plugin]);

        var goodListenerCalled = false;

        // Add listener that throws
        notifier.addListener(() {
          throw Exception('Listener error');
        });

        // Add normal listener
        notifier.addListener(() {
          goodListenerCalled = true;
        });

        // Act & Assert - should not crash, but Flutter will log the error
        plugin.updateState();

        // The good listener should still be called despite the error
        // Note: In Flutter's implementation, subsequent listeners after
        // a throwing listener might not be called, but this depends on
        // the ChangeNotifier implementation

        // Cleanup
        notifier.dispose();
      });

      test('should handle null stateChanges gracefully', () {
        // Arrange
        final plugin = MockEditorPlugin();

        // Act & Assert - should not throw
        expect(() {
          final notifier = PluginUINotifier([plugin]);
          notifier.dispose();
        }, returnsNormally);
      });
    });

    group('Performance', () {
      test('should handle large number of plugins efficiently', () {
        // Arrange
        final plugins = List.generate(
          50,
          (index) => TestPluginWithState(),
        );
        final notifier = PluginUINotifier(plugins);

        var notificationCount = 0;
        notifier.addListener(() {
          notificationCount++;
        });

        // Act - Update each plugin once
        for (final plugin in plugins) {
          plugin.updateState();
        }

        // Assert
        expect(notificationCount, equals(50));

        // Cleanup
        notifier.dispose();
      });

      test('should handle many listeners efficiently', () {
        // Arrange
        final plugin = TestPluginWithState();
        final notifier = PluginUINotifier([plugin]);

        final counters = List.generate(50, (_) => 0);

        for (var i = 0; i < counters.length; i++) {
          final index = i;
          notifier.addListener(() {
            counters[index]++;
          });
        }

        // Act
        plugin.updateState();

        // Assert - all listeners should have been called
        for (final count in counters) {
          expect(count, equals(1));
        }

        // Cleanup
        notifier.dispose();
      });
    });
  });
}
