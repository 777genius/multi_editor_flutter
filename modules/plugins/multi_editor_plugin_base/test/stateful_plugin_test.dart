import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_plugins.dart';

void main() {
  late StatefulTestPlugin plugin;

  setUp(() {
    plugin = StatefulTestPlugin();
  });

  group('StatefulPlugin', () {
    group('Get/Set State', () {
      test('should set and get state value', () {
        plugin.setState('testKey', 'testValue');

        expect(plugin.getState<String>('testKey'), 'testValue');
      });

      test('should return null for non-existent key', () {
        expect(plugin.getState<String>('nonexistent'), isNull);
      });

      test('should return null for wrong type', () {
        plugin.setState('intKey', 42);

        expect(plugin.getState<String>('intKey'), isNull);
        expect(plugin.getState<int>('intKey'), 42);
      });

      test('should support different value types', () {
        plugin.setState('stringKey', 'text');
        plugin.setState('intKey', 42);
        plugin.setState('boolKey', true);
        plugin.setState('doubleKey', 3.14);
        plugin.setState('listKey', [1, 2, 3]);
        plugin.setState('mapKey', {'foo': 'bar'});

        expect(plugin.getState<String>('stringKey'), 'text');
        expect(plugin.getState<int>('intKey'), 42);
        expect(plugin.getState<bool>('boolKey'), true);
        expect(plugin.getState<double>('doubleKey'), 3.14);
        expect(plugin.getState<List>('listKey'), [1, 2, 3]);
        expect(plugin.getState<Map>('mapKey'), {'foo': 'bar'});
      });

      test('should overwrite existing value', () {
        plugin.setState('key', 'value1');
        plugin.setState('key', 'value2');

        expect(plugin.getState<String>('key'), 'value2');
      });
    });

    group('Remove State', () {
      test('should remove state value', () {
        plugin.setState('key', 'value');
        plugin.removeState('key');

        expect(plugin.hasState('key'), false);
        expect(plugin.getState<String>('key'), isNull);
      });

      test('should not error when removing non-existent key', () {
        expect(() => plugin.removeState('nonexistent'), returnsNormally);
      });
    });

    group('Clear State', () {
      test('should clear all state', () {
        plugin.setState('key1', 'value1');
        plugin.setState('key2', 'value2');
        plugin.setState('key3', 'value3');

        plugin.clearState();

        expect(plugin.hasState('key1'), false);
        expect(plugin.hasState('key2'), false);
        expect(plugin.hasState('key3'), false);
        expect(plugin.getAllState(), isEmpty);
      });
    });

    group('Has State', () {
      test('should return true for existing key', () {
        plugin.setState('key', 'value');

        expect(plugin.hasState('key'), true);
      });

      test('should return false for non-existent key', () {
        expect(plugin.hasState('nonexistent'), false);
      });
    });

    group('Get All State', () {
      test('should return all state', () {
        plugin.setState('key1', 'value1');
        plugin.setState('key2', 42);
        plugin.setState('key3', true);

        final allState = plugin.getAllState();

        expect(allState, {'key1': 'value1', 'key2': 42, 'key3': true});
      });

      test('should return empty map when no state', () {
        expect(plugin.getAllState(), isEmpty);
      });

      test('should return copy of state (not reference)', () {
        plugin.setState('key', 'value');

        final state1 = plugin.getAllState();
        state1['key'] = 'modified';

        // Original state should not be modified
        expect(plugin.getState<String>('key'), 'value');
      });
    });

    group('State Change Notifications', () {
      test('should notify on setState', () {
        final changes = <int>[];

        plugin.stateChanges.addListener(() {
          changes.add(plugin.stateChanges.value);
        });

        plugin.setState('key1', 'value1');
        plugin.setState('key2', 'value2');

        expect(changes.length, 2);
      });

      test('should notify on removeState', () {
        plugin.setState('key', 'value');
        final changes = <int>[];

        plugin.stateChanges.addListener(() {
          changes.add(plugin.stateChanges.value);
        });

        plugin.removeState('key');

        expect(changes.length, 1);
      });

      test('should notify on clearState', () {
        plugin.setState('key1', 'value1');
        plugin.setState('key2', 'value2');
        final changes = <int>[];

        plugin.stateChanges.addListener(() {
          changes.add(plugin.stateChanges.value);
        });

        plugin.clearState();

        expect(changes.length, 1);
      });

      test('should increment notifier value on changes', () {
        final initialValue = plugin.stateChanges.value;

        plugin.setState('key', 'value');
        expect(plugin.stateChanges.value, initialValue + 1);

        plugin.setState('key2', 'value2');
        expect(plugin.stateChanges.value, initialValue + 2);

        plugin.removeState('key');
        expect(plugin.stateChanges.value, initialValue + 3);

        plugin.clearState();
        expect(plugin.stateChanges.value, initialValue + 4);
      });
    });

    group('Dispose', () {
      test('should clear state on disposeStateful', () {
        plugin.setState('key', 'value');

        plugin.disposeStateful();

        expect(plugin.getAllState(), isEmpty);
      });
    });
  });
}
