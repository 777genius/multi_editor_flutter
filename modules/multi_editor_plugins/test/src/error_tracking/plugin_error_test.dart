import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugins/src/error_tracking/plugin_error.dart';

void main() {
  group('PluginErrorType', () {
    test('should have all expected error types', () {
      // Assert
      expect(PluginErrorType.values, contains(PluginErrorType.initialization));
      expect(PluginErrorType.values, contains(PluginErrorType.disposal));
      expect(PluginErrorType.values, contains(PluginErrorType.eventHandler));
      expect(PluginErrorType.values, contains(PluginErrorType.dependency));
      expect(PluginErrorType.values, contains(PluginErrorType.configuration));
      expect(PluginErrorType.values, contains(PluginErrorType.messaging));
      expect(PluginErrorType.values, contains(PluginErrorType.runtime));
    });
  });

  group('PluginError', () {
    group('constructor', () {
      test('should create error with all fields', () {
        // Arrange
        final timestamp = DateTime.now();
        final stackTrace = StackTrace.current;

        // Act
        final error = PluginError(
          pluginId: 'test-plugin',
          pluginName: 'Test Plugin',
          type: PluginErrorType.runtime,
          message: 'Test error message',
          timestamp: timestamp,
          stackTrace: stackTrace,
          context: {'key': 'value'},
        );

        // Assert
        expect(error.pluginId, 'test-plugin');
        expect(error.pluginName, 'Test Plugin');
        expect(error.type, PluginErrorType.runtime);
        expect(error.message, 'Test error message');
        expect(error.timestamp, timestamp);
        expect(error.stackTrace, stackTrace);
        expect(error.context, {'key': 'value'});
      });

      test('should create error with minimal fields', () {
        // Arrange
        final timestamp = DateTime.now();

        // Act
        final error = PluginError(
          pluginId: 'minimal',
          pluginName: 'Minimal',
          type: PluginErrorType.runtime,
          message: 'Error',
          timestamp: timestamp,
        );

        // Assert
        expect(error.pluginId, 'minimal');
        expect(error.stackTrace, null);
        expect(error.context, isEmpty);
      });
    });

    group('factory constructors', () {
      group('initialization error', () {
        test('should create initialization error', () {
          // Arrange
          final exception = Exception('Init failed');
          final stackTrace = StackTrace.current;

          // Act
          final error = PluginError.initialization(
            pluginId: 'test-plugin',
            pluginName: 'Test Plugin',
            error: exception,
            stackTrace: stackTrace,
          );

          // Assert
          expect(error.pluginId, 'test-plugin');
          expect(error.pluginName, 'Test Plugin');
          expect(error.type, PluginErrorType.initialization);
          expect(error.message, exception.toString());
          expect(error.stackTrace, stackTrace);
          expect(error.timestamp, isNotNull);
        });

        test('should create initialization error with context', () {
          // Arrange
          final context = {'reason': 'missing config'};

          // Act
          final error = PluginError.initialization(
            pluginId: 'test',
            pluginName: 'Test',
            error: Exception('Failed'),
            context: context,
          );

          // Assert
          expect(error.context, context);
        });

        test('should handle various error types', () {
          // Arrange & Act
          final stringError = PluginError.initialization(
            pluginId: 'test',
            pluginName: 'Test',
            error: 'String error',
          );
          final intError = PluginError.initialization(
            pluginId: 'test',
            pluginName: 'Test',
            error: 42,
          );

          // Assert
          expect(stringError.message, 'String error');
          expect(intError.message, '42');
        });
      });

      group('disposal error', () {
        test('should create disposal error', () {
          // Arrange
          final exception = Exception('Disposal failed');
          final stackTrace = StackTrace.current;

          // Act
          final error = PluginError.disposal(
            pluginId: 'test-plugin',
            pluginName: 'Test Plugin',
            error: exception,
            stackTrace: stackTrace,
          );

          // Assert
          expect(error.type, PluginErrorType.disposal);
          expect(error.message, exception.toString());
          expect(error.stackTrace, stackTrace);
        });
      });

      group('event handler error', () {
        test('should create event handler error with event type', () {
          // Arrange
          final exception = Exception('Handler failed');
          final stackTrace = StackTrace.current;

          // Act
          final error = PluginError.eventHandler(
            pluginId: 'test-plugin',
            pluginName: 'Test Plugin',
            eventType: 'onFileOpen',
            error: exception,
            stackTrace: stackTrace,
          );

          // Assert
          expect(error.type, PluginErrorType.eventHandler);
          expect(error.message, exception.toString());
          expect(error.context['eventType'], 'onFileOpen');
          expect(error.stackTrace, stackTrace);
        });

        test('should store event type in context', () {
          // Act
          final error = PluginError.eventHandler(
            pluginId: 'test',
            pluginName: 'Test',
            eventType: 'customEvent',
            error: Exception('Failed'),
          );

          // Assert
          expect(error.context.containsKey('eventType'), true);
          expect(error.context['eventType'], 'customEvent');
        });
      });

      group('runtime error', () {
        test('should create runtime error with operation', () {
          // Arrange
          final exception = Exception('Runtime failed');
          final stackTrace = StackTrace.current;

          // Act
          final error = PluginError.runtime(
            pluginId: 'test-plugin',
            pluginName: 'Test Plugin',
            operation: 'processFile',
            error: exception,
            stackTrace: stackTrace,
          );

          // Assert
          expect(error.type, PluginErrorType.runtime);
          expect(error.message, exception.toString());
          expect(error.context['operation'], 'processFile');
          expect(error.stackTrace, stackTrace);
        });

        test('should merge additional context', () {
          // Arrange
          final additionalContext = {
            'file': 'test.dart',
            'line': 42,
          };

          // Act
          final error = PluginError.runtime(
            pluginId: 'test',
            pluginName: 'Test',
            operation: 'parse',
            error: Exception('Failed'),
            additionalContext: additionalContext,
          );

          // Assert
          expect(error.context['operation'], 'parse');
          expect(error.context['file'], 'test.dart');
          expect(error.context['line'], 42);
        });

        test('should handle null additional context', () {
          // Act
          final error = PluginError.runtime(
            pluginId: 'test',
            pluginName: 'Test',
            operation: 'test',
            error: Exception('Failed'),
            additionalContext: null,
          );

          // Assert
          expect(error.context, {'operation': 'test'});
        });
      });
    });

    group('displayMessage', () {
      test('should format initialization error message', () {
        // Arrange
        final error = PluginError.initialization(
          pluginId: 'test',
          pluginName: 'Test',
          error: Exception('Config missing'),
        );

        // Act
        final message = error.displayMessage;

        // Assert
        expect(message, contains('Failed to initialize plugin'));
        expect(message, contains('Config missing'));
      });

      test('should format disposal error message', () {
        // Arrange
        final error = PluginError.disposal(
          pluginId: 'test',
          pluginName: 'Test',
          error: Exception('Cleanup failed'),
        );

        // Act
        final message = error.displayMessage;

        // Assert
        expect(message, contains('Error during plugin disposal'));
        expect(message, contains('Cleanup failed'));
      });

      test('should format event handler error message with event type', () {
        // Arrange
        final error = PluginError.eventHandler(
          pluginId: 'test',
          pluginName: 'Test',
          eventType: 'onSave',
          error: Exception('Save failed'),
        );

        // Act
        final message = error.displayMessage;

        // Assert
        expect(message, contains('Error in onSave event handler'));
        expect(message, contains('Save failed'));
      });

      test('should format event handler error with unknown event type', () {
        // Arrange
        final error = PluginError(
          pluginId: 'test',
          pluginName: 'Test',
          type: PluginErrorType.eventHandler,
          message: 'Error',
          timestamp: DateTime.now(),
          context: {}, // No eventType
        );

        // Act
        final message = error.displayMessage;

        // Assert
        expect(message, contains('unknown event handler'));
      });

      test('should format dependency error message', () {
        // Arrange
        final error = PluginError(
          pluginId: 'test',
          pluginName: 'Test',
          type: PluginErrorType.dependency,
          message: 'Missing dep',
          timestamp: DateTime.now(),
        );

        // Act
        final message = error.displayMessage;

        // Assert
        expect(message, contains('Dependency error'));
        expect(message, contains('Missing dep'));
      });

      test('should format configuration error message', () {
        // Arrange
        final error = PluginError(
          pluginId: 'test',
          pluginName: 'Test',
          type: PluginErrorType.configuration,
          message: 'Invalid config',
          timestamp: DateTime.now(),
        );

        // Act
        final message = error.displayMessage;

        // Assert
        expect(message, contains('Configuration error'));
        expect(message, contains('Invalid config'));
      });

      test('should format messaging error message', () {
        // Arrange
        final error = PluginError(
          pluginId: 'test',
          pluginName: 'Test',
          type: PluginErrorType.messaging,
          message: 'Message failed',
          timestamp: DateTime.now(),
        );

        // Act
        final message = error.displayMessage;

        // Assert
        expect(message, contains('Messaging error'));
        expect(message, contains('Message failed'));
      });

      test('should format runtime error message with operation', () {
        // Arrange
        final error = PluginError.runtime(
          pluginId: 'test',
          pluginName: 'Test',
          operation: 'fileProcessing',
          error: Exception('Failed'),
        );

        // Act
        final message = error.displayMessage;

        // Assert
        expect(message, contains('Error during fileProcessing'));
        expect(message, contains('Failed'));
      });

      test('should format runtime error with unknown operation', () {
        // Arrange
        final error = PluginError(
          pluginId: 'test',
          pluginName: 'Test',
          type: PluginErrorType.runtime,
          message: 'Error',
          timestamp: DateTime.now(),
          context: {}, // No operation
        );

        // Act
        final message = error.displayMessage;

        // Assert
        expect(message, contains('unknown operation'));
      });
    });

    group('isCritical', () {
      test('should return true for initialization errors', () {
        // Arrange
        final error = PluginError.initialization(
          pluginId: 'test',
          pluginName: 'Test',
          error: Exception('Failed'),
        );

        // Act & Assert
        expect(error.isCritical, true);
      });

      test('should return true for dependency errors', () {
        // Arrange
        final error = PluginError(
          pluginId: 'test',
          pluginName: 'Test',
          type: PluginErrorType.dependency,
          message: 'Missing dependency',
          timestamp: DateTime.now(),
        );

        // Act & Assert
        expect(error.isCritical, true);
      });

      test('should return false for runtime errors', () {
        // Arrange
        final error = PluginError.runtime(
          pluginId: 'test',
          pluginName: 'Test',
          operation: 'test',
          error: Exception('Failed'),
        );

        // Act & Assert
        expect(error.isCritical, false);
      });

      test('should return false for event handler errors', () {
        // Arrange
        final error = PluginError.eventHandler(
          pluginId: 'test',
          pluginName: 'Test',
          eventType: 'onEvent',
          error: Exception('Failed'),
        );

        // Act & Assert
        expect(error.isCritical, false);
      });

      test('should return false for disposal errors', () {
        // Arrange
        final error = PluginError.disposal(
          pluginId: 'test',
          pluginName: 'Test',
          error: Exception('Failed'),
        );

        // Act & Assert
        expect(error.isCritical, false);
      });

      test('should return false for configuration errors', () {
        // Arrange
        final error = PluginError(
          pluginId: 'test',
          pluginName: 'Test',
          type: PluginErrorType.configuration,
          message: 'Invalid',
          timestamp: DateTime.now(),
        );

        // Act & Assert
        expect(error.isCritical, false);
      });

      test('should return false for messaging errors', () {
        // Arrange
        final error = PluginError(
          pluginId: 'test',
          pluginName: 'Test',
          type: PluginErrorType.messaging,
          message: 'Failed',
          timestamp: DateTime.now(),
        );

        // Act & Assert
        expect(error.isCritical, false);
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON', () {
        // Arrange
        final timestamp = DateTime.now();
        final error = PluginError(
          pluginId: 'json-test',
          pluginName: 'JSON Test',
          type: PluginErrorType.runtime,
          message: 'Test message',
          timestamp: timestamp,
          context: {'key': 'value'},
        );

        // Act
        final json = error.toJson();

        // Assert
        expect(json['pluginId'], 'json-test');
        expect(json['pluginName'], 'JSON Test');
        expect(json['type'], 'runtime');
        expect(json['message'], 'Test message');
        expect(json['context'], {'key': 'value'});
        // stackTrace should not be included in JSON
        expect(json.containsKey('stackTrace'), false);
      });

      test('should deserialize from JSON', () {
        // Arrange
        final json = {
          'pluginId': 'json-test',
          'pluginName': 'JSON Test',
          'type': 'initialization',
          'message': 'Test message',
          'timestamp': DateTime.now().toIso8601String(),
          'context': {'reason': 'test'},
        };

        // Act
        final error = PluginError.fromJson(json);

        // Assert
        expect(error.pluginId, 'json-test');
        expect(error.pluginName, 'JSON Test');
        expect(error.type, PluginErrorType.initialization);
        expect(error.message, 'Test message');
        expect(error.context, {'reason': 'test'});
      });

      test('should round-trip through JSON', () {
        // Arrange
        final original = PluginError(
          pluginId: 'roundtrip',
          pluginName: 'Roundtrip',
          type: PluginErrorType.runtime,
          message: 'Test',
          timestamp: DateTime.now(),
          context: {'data': 'value'},
        );

        // Act
        final json = original.toJson();
        final deserialized = PluginError.fromJson(json);

        // Assert
        expect(deserialized.pluginId, original.pluginId);
        expect(deserialized.pluginName, original.pluginName);
        expect(deserialized.type, original.type);
        expect(deserialized.message, original.message);
        expect(deserialized.context, original.context);
      });

      test('should not serialize stackTrace', () {
        // Arrange
        final error = PluginError(
          pluginId: 'test',
          pluginName: 'Test',
          type: PluginErrorType.runtime,
          message: 'Error',
          timestamp: DateTime.now(),
          stackTrace: StackTrace.current,
        );

        // Act
        final json = error.toJson();

        // Assert
        expect(json.containsKey('stackTrace'), false);
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        // Arrange
        final timestamp = DateTime(2024, 1, 1);
        final error1 = PluginError(
          pluginId: 'test',
          pluginName: 'Test',
          type: PluginErrorType.runtime,
          message: 'Error',
          timestamp: timestamp,
        );
        final error2 = PluginError(
          pluginId: 'test',
          pluginName: 'Test',
          type: PluginErrorType.runtime,
          message: 'Error',
          timestamp: timestamp,
        );

        // Act & Assert
        expect(error1, equals(error2));
      });

      test('should not be equal when messages differ', () {
        // Arrange
        final timestamp = DateTime.now();
        final error1 = PluginError(
          pluginId: 'test',
          pluginName: 'Test',
          type: PluginErrorType.runtime,
          message: 'Error 1',
          timestamp: timestamp,
        );
        final error2 = PluginError(
          pluginId: 'test',
          pluginName: 'Test',
          type: PluginErrorType.runtime,
          message: 'Error 2',
          timestamp: timestamp,
        );

        // Act & Assert
        expect(error1, isNot(equals(error2)));
      });
    });

    group('edge cases', () {
      test('should handle empty strings', () {
        // Act
        final error = PluginError(
          pluginId: '',
          pluginName: '',
          type: PluginErrorType.runtime,
          message: '',
          timestamp: DateTime.now(),
        );

        // Assert
        expect(error.pluginId, '');
        expect(error.pluginName, '');
        expect(error.message, '');
      });

      test('should handle very long messages', () {
        // Arrange
        final longMessage = 'Error: ' * 1000;

        // Act
        final error = PluginError(
          pluginId: 'test',
          pluginName: 'Test',
          type: PluginErrorType.runtime,
          message: longMessage,
          timestamp: DateTime.now(),
        );

        // Assert
        expect(error.message.length, greaterThan(5000));
      });

      test('should handle special characters in messages', () {
        // Act
        final error = PluginError(
          pluginId: 'test',
          pluginName: 'Test',
          type: PluginErrorType.runtime,
          message: 'Error with "quotes", \'apostrophes\', and\nnewlines',
          timestamp: DateTime.now(),
        );

        // Assert
        expect(error.message, contains('"'));
        expect(error.message, contains('\''));
        expect(error.message, contains('\n'));
      });

      test('should handle unicode in messages', () {
        // Act
        final error = PluginError(
          pluginId: 'test',
          pluginName: 'Test',
          type: PluginErrorType.runtime,
          message: 'Ошибка: 错误 🔥',
          timestamp: DateTime.now(),
        );

        // Assert
        expect(error.message, contains('Ошибка'));
        expect(error.message, contains('错误'));
        expect(error.message, contains('🔥'));
      });

      test('should handle complex context data', () {
        // Arrange
        final context = {
          'nested': {
            'deep': {'value': 123}
          },
          'array': [1, 2, 3],
          'null': null,
          'bool': true,
        };

        // Act
        final error = PluginError(
          pluginId: 'test',
          pluginName: 'Test',
          type: PluginErrorType.runtime,
          message: 'Error',
          timestamp: DateTime.now(),
          context: context,
        );

        // Assert
        expect(error.context['nested']['deep']['value'], 123);
        expect(error.context['array'], [1, 2, 3]);
        expect(error.context['null'], null);
        expect(error.context['bool'], true);
      });

      test('should handle timestamps in different timezones', () {
        // Arrange
        final utcTime = DateTime.utc(2024, 1, 1, 12, 0, 0);
        final localTime = DateTime(2024, 1, 1, 12, 0, 0);

        // Act
        final utcError = PluginError(
          pluginId: 'test',
          pluginName: 'Test',
          type: PluginErrorType.runtime,
          message: 'UTC',
          timestamp: utcTime,
        );
        final localError = PluginError(
          pluginId: 'test',
          pluginName: 'Test',
          type: PluginErrorType.runtime,
          message: 'Local',
          timestamp: localTime,
        );

        // Assert
        expect(utcError.timestamp.isUtc, true);
        expect(localError.timestamp.isUtc, false);
      });
    });

    group('copyWith', () {
      test('should create copy with updated message', () {
        // Arrange
        final original = PluginError(
          pluginId: 'test',
          pluginName: 'Test',
          type: PluginErrorType.runtime,
          message: 'Original',
          timestamp: DateTime.now(),
        );

        // Act
        final copy = original.copyWith(message: 'Updated');

        // Assert
        expect(copy.message, 'Updated');
        expect(copy.pluginId, original.pluginId);
        expect(copy.type, original.type);
      });
    });

    group('toString', () {
      test('should provide readable string representation', () {
        // Arrange
        final error = PluginError(
          pluginId: 'test',
          pluginName: 'Test Plugin',
          type: PluginErrorType.runtime,
          message: 'Test error',
          timestamp: DateTime.now(),
        );

        // Act
        final str = error.toString();

        // Assert
        expect(str, contains('PluginError'));
      });
    });
  });
}
