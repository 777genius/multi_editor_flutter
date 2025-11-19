import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_plugin_system_core/src/models/plugin_response.dart';

void main() {
  group('PluginResponse', () {
    group('constructor', () {
      test('should create instance with required fields', () {
        // Arrange & Act
        const response = PluginResponse(success: true);

        // Assert
        expect(response.success, true);
        expect(response.data, isEmpty);
        expect(response.message, isNull);
        expect(response.error, isNull);
        expect(response.stackTrace, isNull);
        expect(response.timestamp, isNull);
        expect(response.durationMs, isNull);
        expect(response.metadata, isNull);
      });

      test('should create success response with data', () {
        // Arrange & Act
        const response = PluginResponse(
          success: true,
          data: {'result': 'success', 'count': 42},
        );

        // Assert
        expect(response.success, true);
        expect(response.data, {'result': 'success', 'count': 42});
        expect(response.message, isNull);
        expect(response.error, isNull);
      });

      test('should create error response with details', () {
        // Arrange & Act
        const response = PluginResponse(
          success: false,
          message: 'Operation failed',
          error: 'NullPointerException',
          stackTrace: 'at file.dart:42',
        );

        // Assert
        expect(response.success, false);
        expect(response.message, 'Operation failed');
        expect(response.error, 'NullPointerException');
        expect(response.stackTrace, 'at file.dart:42');
      });

      test('should create response with all fields', () {
        // Arrange
        final timestamp = DateTime(2024, 1, 1, 12, 0);

        // Act
        final response = PluginResponse(
          success: true,
          data: const {'key': 'value'},
          message: 'Success message',
          error: null,
          stackTrace: null,
          timestamp: timestamp,
          durationMs: 150,
          metadata: const {'source': 'test'},
        );

        // Assert
        expect(response.success, true);
        expect(response.data, {'key': 'value'});
        expect(response.message, 'Success message');
        expect(response.timestamp, timestamp);
        expect(response.durationMs, 150);
        expect(response.metadata, {'source': 'test'});
      });
    });

    group('success factory', () {
      test('should create success response with default values', () {
        // Arrange
        final beforeCreation = DateTime.now();

        // Act
        final response = PluginResponse.success();
        final afterCreation = DateTime.now();

        // Assert
        expect(response.success, true);
        expect(response.data, isEmpty);
        expect(response.message, isNull);
        expect(response.error, isNull);
        expect(response.stackTrace, isNull);
        expect(response.timestamp, isNotNull);
        expect(response.timestamp!.isAfter(beforeCreation) ||
               response.timestamp!.isAtSameMomentAs(beforeCreation), isTrue);
        expect(response.timestamp!.isBefore(afterCreation) ||
               response.timestamp!.isAtSameMomentAs(afterCreation), isTrue);
      });

      test('should create success response with data', () {
        // Arrange & Act
        final response = PluginResponse.success(
          data: const {
            'icon_url': 'https://cdn.example.com/dart.svg',
            'cached': true,
          },
        );

        // Assert
        expect(response.success, true);
        expect(response.data, {
          'icon_url': 'https://cdn.example.com/dart.svg',
          'cached': true,
        });
        expect(response.timestamp, isNotNull);
      });

      test('should create success response with duration', () {
        // Arrange & Act
        final response = PluginResponse.success(
          data: const {'result': 'done'},
          durationMs: 250,
        );

        // Assert
        expect(response.success, true);
        expect(response.durationMs, 250);
      });

      test('should create success response with metadata', () {
        // Arrange & Act
        final response = PluginResponse.success(
          metadata: const {'version': '1.0.0', 'cached': true},
        );

        // Assert
        expect(response.success, true);
        expect(response.metadata, {'version': '1.0.0', 'cached': true});
      });
    });

    group('error factory', () {
      test('should create error response with message', () {
        // Arrange
        final beforeCreation = DateTime.now();

        // Act
        final response = PluginResponse.error(
          message: 'Failed to resolve icon',
        );
        final afterCreation = DateTime.now();

        // Assert
        expect(response.success, false);
        expect(response.message, 'Failed to resolve icon');
        expect(response.error, isNull);
        expect(response.stackTrace, isNull);
        expect(response.data, isEmpty);
        expect(response.timestamp, isNotNull);
        expect(response.timestamp!.isAfter(beforeCreation) ||
               response.timestamp!.isAtSameMomentAs(beforeCreation), isTrue);
        expect(response.timestamp!.isBefore(afterCreation) ||
               response.timestamp!.isAtSameMomentAs(afterCreation), isTrue);
      });

      test('should create error response with all error details', () {
        // Arrange & Act
        final response = PluginResponse.error(
          message: 'Failed to load plugin',
          error: 'FileNotFoundException: plugin.wasm not found',
          stackTrace: 'at PluginLoader.load (plugin_loader.dart:42)\n'
                     'at main (main.dart:10)',
        );

        // Assert
        expect(response.success, false);
        expect(response.message, 'Failed to load plugin');
        expect(response.error, 'FileNotFoundException: plugin.wasm not found');
        expect(response.stackTrace, contains('plugin_loader.dart:42'));
        expect(response.timestamp, isNotNull);
      });

      test('should create error response with duration', () {
        // Arrange & Act
        final response = PluginResponse.error(
          message: 'Timeout',
          durationMs: 5000,
        );

        // Assert
        expect(response.success, false);
        expect(response.message, 'Timeout');
        expect(response.durationMs, 5000);
      });

      test('should create error response with metadata', () {
        // Arrange & Act
        final response = PluginResponse.error(
          message: 'Error occurred',
          metadata: const {'retry_count': 3, 'last_attempt': '2024-01-01'},
        );

        // Assert
        expect(response.success, false);
        expect(response.metadata, {'retry_count': 3, 'last_attempt': '2024-01-01'});
      });
    });

    group('getData', () {
      test('should get string data with correct type', () {
        // Arrange
        final response = PluginResponse.success(
          data: const {'icon_url': 'https://example.com/icon.svg', 'count': 10},
        );

        // Act
        final iconUrl = response.getData<String>('icon_url');
        final count = response.getData<int>('count');

        // Assert
        expect(iconUrl, 'https://example.com/icon.svg');
        expect(count, 10);
      });

      test('should return null for missing keys', () {
        // Arrange
        final response = PluginResponse.success(
          data: const {'key1': 'value1'},
        );

        // Act
        final result = response.getData<String>('missing_key');

        // Assert
        expect(result, isNull);
      });

      test('should return null for wrong type', () {
        // Arrange
        final response = PluginResponse.success(
          data: const {'count': 42},
        );

        // Act
        final result = response.getData<String>('count');

        // Assert
        expect(result, isNull);
      });

      test('should get complex nested data', () {
        // Arrange
        final response = PluginResponse.success(
          data: {
            'result': {
              'status': 'completed',
              'items': [1, 2, 3],
            },
          },
        );

        // Act
        final result = response.getData<Map<String, dynamic>>('result');

        // Assert
        expect(result, isNotNull);
        expect(result!['status'], 'completed');
        expect(result['items'], [1, 2, 3]);
      });
    });

    group('getDataOr', () {
      test('should return data when key exists', () {
        // Arrange
        final response = PluginResponse.success(
          data: const {'icon_url': 'https://example.com/icon.svg'},
        );

        // Act
        final iconUrl = response.getDataOr<String>(
          'icon_url',
          'https://default.com/icon.svg',
        );

        // Assert
        expect(iconUrl, 'https://example.com/icon.svg');
      });

      test('should return default when key missing', () {
        // Arrange
        final response = PluginResponse.success(
          data: const {'other': 'value'},
        );

        // Act
        final iconUrl = response.getDataOr<String>(
          'icon_url',
          'https://default.com/icon.svg',
        );

        // Assert
        expect(iconUrl, 'https://default.com/icon.svg');
      });

      test('should return default when type mismatch', () {
        // Arrange
        final response = PluginResponse.success(
          data: const {'count': 42},
        );

        // Act
        final count = response.getDataOr<String>('count', 'default');

        // Assert
        expect(count, 'default');
      });

      test('should handle numeric defaults', () {
        // Arrange
        final response = PluginResponse.success(data: const {});

        // Act
        final count = response.getDataOr<int>('count', 0);
        final ratio = response.getDataOr<double>('ratio', 1.0);

        // Assert
        expect(count, 0);
        expect(ratio, 1.0);
      });
    });

    group('hasError getter', () {
      test('should return false when no error details', () {
        // Arrange
        final response = PluginResponse.success();

        // Act & Assert
        expect(response.hasError, false);
      });

      test('should return true when error is set', () {
        // Arrange
        final response = PluginResponse.error(
          message: 'Failed',
          error: 'Exception occurred',
        );

        // Act & Assert
        expect(response.hasError, true);
      });

      test('should return true when stackTrace is set', () {
        // Arrange
        final response = PluginResponse.error(
          message: 'Failed',
          stackTrace: 'at file.dart:10',
        );

        // Act & Assert
        expect(response.hasError, true);
      });

      test('should return true when both error and stackTrace are set', () {
        // Arrange
        final response = PluginResponse.error(
          message: 'Failed',
          error: 'Exception',
          stackTrace: 'at file.dart:10',
        );

        // Act & Assert
        expect(response.hasError, true);
      });

      test('should return false for success response', () {
        // Arrange
        final response = PluginResponse.success(
          data: const {'result': 'ok'},
        );

        // Act & Assert
        expect(response.hasError, false);
      });
    });

    group('equality', () {
      test('should be equal when all fields are the same', () {
        // Arrange
        final timestamp = DateTime(2024, 1, 1);
        final response1 = PluginResponse(
          success: true,
          data: const {'key': 'value'},
          timestamp: timestamp,
          durationMs: 100,
        );
        final response2 = PluginResponse(
          success: true,
          data: const {'key': 'value'},
          timestamp: timestamp,
          durationMs: 100,
        );

        // Act & Assert
        expect(response1, equals(response2));
        expect(response1.hashCode, equals(response2.hashCode));
      });

      test('should not be equal when success differs', () {
        // Arrange
        const response1 = PluginResponse(success: true);
        const response2 = PluginResponse(success: false);

        // Act & Assert
        expect(response1, isNot(equals(response2)));
      });

      test('should not be equal when data differs', () {
        // Arrange
        const response1 = PluginResponse(
          success: true,
          data: {'key': 'value1'},
        );
        const response2 = PluginResponse(
          success: true,
          data: {'key': 'value2'},
        );

        // Act & Assert
        expect(response1, isNot(equals(response2)));
      });
    });

    group('copyWith', () {
      test('should copy with new success value', () {
        // Arrange
        const original = PluginResponse(success: true);

        // Act
        final copied = original.copyWith(success: false);

        // Assert
        expect(copied.success, false);
        expect(original.success, true);
      });

      test('should copy with new data', () {
        // Arrange
        const original = PluginResponse(
          success: true,
          data: {'old': 'value'},
        );

        // Act
        final copied = original.copyWith(data: {'new': 'value'});

        // Assert
        expect(copied.data, {'new': 'value'});
        expect(original.data, {'old': 'value'});
      });

      test('should copy with new message', () {
        // Arrange
        final original = PluginResponse.success();

        // Act
        final copied = original.copyWith(message: 'New message');

        // Assert
        expect(copied.message, 'New message');
        expect(original.message, isNull);
      });

      test('should copy with new error details', () {
        // Arrange
        final original = PluginResponse.success();

        // Act
        final copied = original.copyWith(
          error: 'Error occurred',
          stackTrace: 'at file.dart:10',
        );

        // Assert
        expect(copied.error, 'Error occurred');
        expect(copied.stackTrace, 'at file.dart:10');
        expect(copied.hasError, true);
      });
    });

    group('JSON serialization', () {
      test('should serialize minimal response to JSON', () {
        // Arrange
        const response = PluginResponse(success: true);

        // Act
        final json = response.toJson();

        // Assert
        expect(json['success'], true);
        expect(json['data'], isEmpty);
      });

      test('should serialize success response to JSON', () {
        // Arrange
        final timestamp = DateTime(2024, 1, 1, 12, 0);
        final response = PluginResponse(
          success: true,
          data: const {'icon_url': 'https://example.com/icon.svg'},
          timestamp: timestamp,
          durationMs: 150,
        );

        // Act
        final json = response.toJson();

        // Assert
        expect(json['success'], true);
        expect(json['data'], {'icon_url': 'https://example.com/icon.svg'});
        expect(json['durationMs'], 150);
      });

      test('should serialize error response to JSON', () {
        // Arrange
        final timestamp = DateTime(2024, 1, 1, 12, 0);
        final response = PluginResponse(
          success: false,
          message: 'Failed to load',
          error: 'FileNotFoundException',
          stackTrace: 'at file.dart:42',
          timestamp: timestamp,
        );

        // Act
        final json = response.toJson();

        // Assert
        expect(json['success'], false);
        expect(json['message'], 'Failed to load');
        expect(json['error'], 'FileNotFoundException');
        expect(json['stackTrace'], 'at file.dart:42');
      });

      test('should deserialize from JSON', () {
        // Arrange
        final json = {
          'success': true,
          'data': {'key': 'value'},
          'durationMs': 200,
        };

        // Act
        final response = PluginResponse.fromJson(json);

        // Assert
        expect(response.success, true);
        expect(response.data, {'key': 'value'});
        expect(response.durationMs, 200);
      });

      test('should round-trip through JSON', () {
        // Arrange
        final timestamp = DateTime(2024, 6, 15, 10, 30);
        final original = PluginResponse(
          success: true,
          data: const {
            'result': 'success',
            'count': 42,
            'nested': {'key': 'value'},
          },
          message: 'Operation completed',
          timestamp: timestamp,
          durationMs: 300,
          metadata: const {'source': 'test', 'version': '1.0'},
        );

        // Act
        final json = original.toJson();
        final deserialized = PluginResponse.fromJson(json);

        // Assert
        expect(deserialized, equals(original));
      });
    });

    group('edge cases', () {
      test('should handle empty error message', () {
        // Arrange & Act
        final response = PluginResponse.error(message: '');

        // Assert
        expect(response.success, false);
        expect(response.message, '');
      });

      test('should handle very long error messages', () {
        // Arrange
        final longMessage = 'Error: ' * 1000;

        // Act
        final response = PluginResponse.error(message: longMessage);

        // Assert
        expect(response.message, longMessage);
        expect(response.message!.length, greaterThan(5000));
      });

      test('should handle zero duration', () {
        // Arrange & Act
        final response = PluginResponse.success(durationMs: 0);

        // Assert
        expect(response.durationMs, 0);
      });

      test('should handle negative duration', () {
        // Arrange & Act
        final response = PluginResponse.success(durationMs: -1);

        // Assert
        expect(response.durationMs, -1);
      });

      test('should handle large data payloads', () {
        // Arrange
        final largeData = Map.fromIterables(
          List.generate(1000, (i) => 'key$i'),
          List.generate(1000, (i) => 'value$i'),
        );

        // Act
        final response = PluginResponse.success(data: largeData);

        // Assert
        expect(response.data.length, 1000);
        expect(response.getData<String>('key0'), 'value0');
        expect(response.getData<String>('key999'), 'value999');
      });

      test('should handle unicode in error messages', () {
        // Arrange & Act
        final response = PluginResponse.error(
          message: 'Error: 文件不存在',
          error: 'Exception: Файл не найден',
          stackTrace: 'at file.dart:42 // 错误位置',
        );

        // Assert
        expect(response.message, contains('文件不存在'));
        expect(response.error, contains('Файл не найден'));
        expect(response.stackTrace, contains('错误位置'));
      });

      test('should handle null values in metadata', () {
        // Arrange & Act
        final response = PluginResponse.success(
          metadata: {'key1': 'value', 'key2': null},
        );

        // Assert
        expect(response.metadata!['key1'], 'value');
        expect(response.metadata!['key2'], isNull);
      });
    });

    group('practical examples', () {
      test('should represent successful icon resolution', () {
        // Arrange & Act
        final response = PluginResponse.success(
          data: const {
            'icon_url': 'https://cdn.jsdelivr.net/npm/vscode-icons/icons/file_type_dart.svg',
            'cached': true,
            'theme': 'vscode-icons',
          },
          durationMs: 50,
        );

        // Assert
        expect(response.success, true);
        expect(response.getData<String>('icon_url'), contains('dart.svg'));
        expect(response.getData<bool>('cached'), true);
        expect(response.durationMs, 50);
      });

      test('should represent failed plugin initialization', () {
        // Arrange & Act
        final response = PluginResponse.error(
          message: 'Failed to initialize plugin',
          error: 'PluginLoadException: WASM module not found',
          stackTrace: 'at PluginLoader.initialize (loader.dart:128)\n'
                     'at PluginManager.loadPlugin (manager.dart:56)',
          durationMs: 1500,
          metadata: const {
            'plugin_id': 'plugin.file-icons',
            'retry_count': 3,
          },
        );

        // Assert
        expect(response.success, false);
        expect(response.message, contains('Failed to initialize'));
        expect(response.error, contains('WASM module not found'));
        expect(response.hasError, true);
        expect(response.metadata!['retry_count'], 3);
      });

      test('should represent timeout response', () {
        // Arrange & Act
        final response = PluginResponse.error(
          message: 'Plugin execution timed out',
          durationMs: 5000,
          metadata: const {'timeout_ms': 5000, 'plugin_id': 'plugin.slow'},
        );

        // Assert
        expect(response.success, false);
        expect(response.message, contains('timed out'));
        expect(response.durationMs, 5000);
      });
    });
  });
}
