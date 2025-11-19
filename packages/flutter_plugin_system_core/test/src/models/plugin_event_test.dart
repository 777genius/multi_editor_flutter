import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_plugin_system_core/src/models/plugin_event.dart';

void main() {
  group('PluginEvent', () {
    group('constructor', () {
      test('should create instance with required fields', () {
        // Arrange & Act
        const event = PluginEvent(
          type: 'file.opened',
        );

        // Assert
        expect(event.type, 'file.opened');
        expect(event.targetPluginId, isNull);
        expect(event.data, isEmpty);
        expect(event.timestamp, isNull);
        expect(event.sourcePluginId, isNull);
        expect(event.priority, 0);
        expect(event.eventId, isNull);
      });

      test('should create instance with all fields', () {
        // Arrange
        final timestamp = DateTime(2024, 1, 1, 12, 0);

        // Act
        final event = PluginEvent(
          type: 'file.opened',
          targetPluginId: 'plugin.file-icons',
          data: const {'filename': 'main.dart'},
          timestamp: timestamp,
          sourcePluginId: 'plugin.editor',
          priority: 10,
          eventId: 'evt-123',
        );

        // Assert
        expect(event.type, 'file.opened');
        expect(event.targetPluginId, 'plugin.file-icons');
        expect(event.data, {'filename': 'main.dart'});
        expect(event.timestamp, timestamp);
        expect(event.sourcePluginId, 'plugin.editor');
        expect(event.priority, 10);
        expect(event.eventId, 'evt-123');
      });

      test('should handle complex data payloads', () {
        // Arrange & Act
        final event = PluginEvent(
          type: 'editor.selection_changed',
          data: {
            'file_id': 'file123',
            'selection': {
              'start': {'line': 10, 'column': 5},
              'end': {'line': 10, 'column': 15},
            },
            'language': 'dart',
            'is_multiline': false,
          },
        );

        // Assert
        expect(event.data['file_id'], 'file123');
        expect(event.data['selection'], isA<Map>());
        expect(event.data['is_multiline'], false);
      });
    });

    group('now factory', () {
      test('should create event with current timestamp', () {
        // Arrange
        final beforeCreation = DateTime.now();

        // Act
        final event = PluginEvent.now(
          type: 'file.saved',
          targetPluginId: 'plugin.test',
        );
        final afterCreation = DateTime.now();

        // Assert
        expect(event.type, 'file.saved');
        expect(event.timestamp, isNotNull);
        expect(event.timestamp!.isAfter(beforeCreation) ||
               event.timestamp!.isAtSameMomentAs(beforeCreation), isTrue);
        expect(event.timestamp!.isBefore(afterCreation) ||
               event.timestamp!.isAtSameMomentAs(afterCreation), isTrue);
      });

      test('should create event with all optional parameters', () {
        // Arrange & Act
        final event = PluginEvent.now(
          type: 'custom.event',
          targetPluginId: 'plugin.target',
          data: const {'key': 'value'},
          sourcePluginId: 'plugin.source',
          priority: 5,
          eventId: 'evt-abc',
        );

        // Assert
        expect(event.type, 'custom.event');
        expect(event.targetPluginId, 'plugin.target');
        expect(event.data, {'key': 'value'});
        expect(event.sourcePluginId, 'plugin.source');
        expect(event.priority, 5);
        expect(event.eventId, 'evt-abc');
        expect(event.timestamp, isNotNull);
      });

      test('should create multiple events with different timestamps', () async {
        // Arrange & Act
        final event1 = PluginEvent.now(type: 'test.event');
        await Future.delayed(const Duration(milliseconds: 10));
        final event2 = PluginEvent.now(type: 'test.event');

        // Assert
        expect(event1.timestamp, isNotNull);
        expect(event2.timestamp, isNotNull);
        expect(event2.timestamp!.isAfter(event1.timestamp!), isTrue);
      });
    });

    group('getData', () {
      test('should get string data with correct type', () {
        // Arrange
        const event = PluginEvent(
          type: 'test',
          data: {'filename': 'test.dart', 'count': 42},
        );

        // Act
        final filename = event.getData<String>('filename');
        final count = event.getData<int>('count');

        // Assert
        expect(filename, 'test.dart');
        expect(count, 42);
      });

      test('should return null for missing keys', () {
        // Arrange
        const event = PluginEvent(
          type: 'test',
          data: {'key1': 'value1'},
        );

        // Act
        final result = event.getData<String>('missing_key');

        // Assert
        expect(result, isNull);
      });

      test('should return null for wrong type', () {
        // Arrange
        const event = PluginEvent(
          type: 'test',
          data: {'count': 42},
        );

        // Act
        final result = event.getData<String>('count');

        // Assert
        expect(result, isNull);
      });

      test('should get complex nested data', () {
        // Arrange
        final event = PluginEvent(
          type: 'test',
          data: {
            'user': {
              'name': 'John',
              'age': 30,
            },
          },
        );

        // Act
        final user = event.getData<Map<String, dynamic>>('user');

        // Assert
        expect(user, isNotNull);
        expect(user!['name'], 'John');
        expect(user['age'], 30);
      });

      test('should get list data', () {
        // Arrange
        const event = PluginEvent(
          type: 'test',
          data: {
            'tags': ['dart', 'flutter', 'mobile'],
          },
        );

        // Act
        final tags = event.getData<List>('tags');

        // Assert
        expect(tags, isNotNull);
        expect(tags, ['dart', 'flutter', 'mobile']);
      });
    });

    group('getDataOr', () {
      test('should return data when key exists', () {
        // Arrange
        const event = PluginEvent(
          type: 'test',
          data: {'filename': 'test.dart'},
        );

        // Act
        final filename = event.getDataOr<String>('filename', 'default.dart');

        // Assert
        expect(filename, 'test.dart');
      });

      test('should return default when key missing', () {
        // Arrange
        const event = PluginEvent(
          type: 'test',
          data: {'other': 'value'},
        );

        // Act
        final filename = event.getDataOr<String>('filename', 'default.dart');

        // Assert
        expect(filename, 'default.dart');
      });

      test('should return default when type mismatch', () {
        // Arrange
        const event = PluginEvent(
          type: 'test',
          data: {'count': 42},
        );

        // Act
        final count = event.getDataOr<String>('count', 'default');

        // Assert
        expect(count, 'default');
      });

      test('should handle numeric defaults', () {
        // Arrange
        const event = PluginEvent(
          type: 'test',
          data: {},
        );

        // Act
        final count = event.getDataOr<int>('count', 0);
        final ratio = event.getDataOr<double>('ratio', 1.0);

        // Assert
        expect(count, 0);
        expect(ratio, 1.0);
      });

      test('should handle boolean defaults', () {
        // Arrange
        const event = PluginEvent(
          type: 'test',
          data: {'enabled': true},
        );

        // Act
        final enabled = event.getDataOr<bool>('enabled', false);
        final disabled = event.getDataOr<bool>('disabled', false);

        // Assert
        expect(enabled, true);
        expect(disabled, false);
      });
    });

    group('equality', () {
      test('should be equal when all fields are the same', () {
        // Arrange
        final timestamp = DateTime(2024, 1, 1);
        final event1 = PluginEvent(
          type: 'test',
          targetPluginId: 'plugin.test',
          data: const {'key': 'value'},
          timestamp: timestamp,
          priority: 5,
        );
        final event2 = PluginEvent(
          type: 'test',
          targetPluginId: 'plugin.test',
          data: const {'key': 'value'},
          timestamp: timestamp,
          priority: 5,
        );

        // Act & Assert
        expect(event1, equals(event2));
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('should not be equal when type differs', () {
        // Arrange
        const event1 = PluginEvent(type: 'file.opened');
        const event2 = PluginEvent(type: 'file.saved');

        // Act & Assert
        expect(event1, isNot(equals(event2)));
      });

      test('should not be equal when data differs', () {
        // Arrange
        const event1 = PluginEvent(
          type: 'test',
          data: {'key': 'value1'},
        );
        const event2 = PluginEvent(
          type: 'test',
          data: {'key': 'value2'},
        );

        // Act & Assert
        expect(event1, isNot(equals(event2)));
      });

      test('should not be equal when priority differs', () {
        // Arrange
        const event1 = PluginEvent(type: 'test', priority: 0);
        const event2 = PluginEvent(type: 'test', priority: 10);

        // Act & Assert
        expect(event1, isNot(equals(event2)));
      });
    });

    group('copyWith', () {
      test('should copy with new type', () {
        // Arrange
        const original = PluginEvent(type: 'file.opened');

        // Act
        final copied = original.copyWith(type: 'file.saved');

        // Assert
        expect(copied.type, 'file.saved');
      });

      test('should copy with new target plugin', () {
        // Arrange
        const original = PluginEvent(
          type: 'test',
          targetPluginId: 'plugin.a',
        );

        // Act
        final copied = original.copyWith(targetPluginId: 'plugin.b');

        // Assert
        expect(copied.targetPluginId, 'plugin.b');
        expect(original.targetPluginId, 'plugin.a');
      });

      test('should copy with new data', () {
        // Arrange
        const original = PluginEvent(
          type: 'test',
          data: {'old': 'value'},
        );

        // Act
        final copied = original.copyWith(data: {'new': 'value'});

        // Assert
        expect(copied.data, {'new': 'value'});
        expect(original.data, {'old': 'value'});
      });

      test('should copy with new priority', () {
        // Arrange
        const original = PluginEvent(type: 'test', priority: 0);

        // Act
        final copied = original.copyWith(priority: 100);

        // Assert
        expect(copied.priority, 100);
        expect(original.priority, 0);
      });
    });

    group('JSON serialization', () {
      test('should serialize minimal event to JSON', () {
        // Arrange
        const event = PluginEvent(type: 'file.opened');

        // Act
        final json = event.toJson();

        // Assert
        expect(json['type'], 'file.opened');
        expect(json['data'], isEmpty);
        expect(json['priority'], 0);
      });

      test('should serialize full event to JSON', () {
        // Arrange
        final timestamp = DateTime(2024, 1, 1, 12, 30);
        final event = PluginEvent(
          type: 'file.opened',
          targetPluginId: 'plugin.file-icons',
          data: const {'filename': 'main.dart', 'size': 1024},
          timestamp: timestamp,
          sourcePluginId: 'plugin.editor',
          priority: 10,
          eventId: 'evt-123',
        );

        // Act
        final json = event.toJson();

        // Assert
        expect(json['type'], 'file.opened');
        expect(json['targetPluginId'], 'plugin.file-icons');
        expect(json['data'], {'filename': 'main.dart', 'size': 1024});
        expect(json['sourcePluginId'], 'plugin.editor');
        expect(json['priority'], 10);
        expect(json['eventId'], 'evt-123');
      });

      test('should deserialize from JSON', () {
        // Arrange
        final json = {
          'type': 'file.saved',
          'targetPluginId': 'plugin.test',
          'data': {'filename': 'test.dart'},
          'priority': 5,
        };

        // Act
        final event = PluginEvent.fromJson(json);

        // Assert
        expect(event.type, 'file.saved');
        expect(event.targetPluginId, 'plugin.test');
        expect(event.data, {'filename': 'test.dart'});
        expect(event.priority, 5);
      });

      test('should round-trip through JSON', () {
        // Arrange
        final timestamp = DateTime(2024, 6, 15, 10, 30);
        final original = PluginEvent(
          type: 'custom.event',
          targetPluginId: 'plugin.target',
          data: const {
            'key1': 'value1',
            'key2': 42,
            'key3': true,
          },
          timestamp: timestamp,
          sourcePluginId: 'plugin.source',
          priority: 15,
          eventId: 'evt-roundtrip',
        );

        // Act
        final json = original.toJson();
        final deserialized = PluginEvent.fromJson(json);

        // Assert
        expect(deserialized, equals(original));
      });

      test('should handle complex nested data in JSON', () {
        // Arrange
        final event = PluginEvent(
          type: 'test',
          data: {
            'user': {'name': 'John', 'age': 30},
            'tags': ['tag1', 'tag2'],
            'metadata': {'created': '2024-01-01'},
          },
        );

        // Act
        final json = event.toJson();
        final deserialized = PluginEvent.fromJson(json);

        // Assert
        expect(deserialized, equals(event));
        expect(deserialized.data['user'], isA<Map>());
        expect(deserialized.data['tags'], isA<List>());
      });
    });

    group('edge cases', () {
      test('should handle empty event type', () {
        // Arrange & Act
        const event = PluginEvent(type: '');

        // Assert
        expect(event.type, '');
      });

      test('should handle very long event types', () {
        // Arrange
        final longType = 'namespace.' * 100 + 'event';

        // Act
        final event = PluginEvent(type: longType);

        // Assert
        expect(event.type, longType);
      });

      test('should handle negative priority', () {
        // Arrange & Act
        const event = PluginEvent(type: 'test', priority: -10);

        // Assert
        expect(event.priority, -10);
      });

      test('should handle very high priority', () {
        // Arrange & Act
        const event = PluginEvent(type: 'test', priority: 999999);

        // Assert
        expect(event.priority, 999999);
      });

      test('should handle large data payloads', () {
        // Arrange
        final largeData = Map.fromIterables(
          List.generate(1000, (i) => 'key$i'),
          List.generate(1000, (i) => 'value$i'),
        );

        // Act
        final event = PluginEvent(type: 'test', data: largeData);

        // Assert
        expect(event.data.length, 1000);
        expect(event.data['key0'], 'value0');
        expect(event.data['key999'], 'value999');
      });

      test('should handle unicode in event data', () {
        // Arrange & Act
        const event = PluginEvent(
          type: 'test.unicode',
          data: {
            'message': 'Hello 世界',
            'emoji': '🎉🚀',
            'special': '©®™',
          },
        );

        // Assert
        expect(event.data['message'], 'Hello 世界');
        expect(event.data['emoji'], '🎉🚀');
        expect(event.data['special'], '©®™');
      });
    });

    group('practical examples', () {
      test('should represent file opened event', () {
        // Arrange & Act
        final event = PluginEvent.now(
          type: 'file.opened',
          targetPluginId: 'plugin.file-icons',
          data: const {
            'file_id': 'file123',
            'filename': 'main.dart',
            'path': '/project/lib/main.dart',
            'language': 'dart',
          },
          sourcePluginId: 'plugin.editor',
        );

        // Assert
        expect(event.type, 'file.opened');
        expect(event.getData<String>('filename'), 'main.dart');
        expect(event.getData<String>('language'), 'dart');
      });

      test('should represent editor cursor moved event', () {
        // Arrange & Act
        final event = PluginEvent.now(
          type: 'editor.cursor_moved',
          data: {
            'file_id': 'file456',
            'position': {
              'line': 42,
              'column': 15,
            },
          },
        );

        // Assert
        expect(event.type, 'editor.cursor_moved');
        final position = event.getData<Map<String, dynamic>>('position');
        expect(position!['line'], 42);
        expect(position['column'], 15);
      });

      test('should represent broadcast event', () {
        // Arrange & Act
        final event = PluginEvent.now(
          type: 'project.opened',
          targetPluginId: null, // broadcast to all plugins
          data: const {
            'project_path': '/path/to/project',
            'project_name': 'My Project',
          },
          priority: 100, // high priority
        );

        // Assert
        expect(event.targetPluginId, isNull);
        expect(event.priority, 100);
        expect(event.getData<String>('project_name'), 'My Project');
      });
    });
  });
}
