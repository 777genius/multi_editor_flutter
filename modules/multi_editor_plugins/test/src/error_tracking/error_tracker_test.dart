import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugins/src/error_tracking/error_tracker.dart';
import 'package:multi_editor_plugins/src/error_tracking/plugin_error.dart';

void main() {
  group('ErrorTracker', () {
    late ErrorTracker errorTracker;

    setUp(() {
      errorTracker = ErrorTracker();
    });

    tearDown(() {
      errorTracker.dispose();
    });

    group('initialization', () {
      test('should initialize with empty error list', () {
        // Arrange & Act
        final tracker = ErrorTracker();

        // Assert
        expect(tracker.errors, isEmpty);
        expect(tracker.maxErrors, 100);

        tracker.dispose();
      });

      test('should allow custom maxErrors', () {
        // Arrange & Act
        final tracker = ErrorTracker(maxErrors: 50);

        // Assert
        expect(tracker.maxErrors, 50);

        tracker.dispose();
      });
    });

    group('recordError', () {
      test('should add error to the list', () {
        // Arrange
        final error = PluginError(
          pluginId: 'test-plugin',
          pluginName: 'Test Plugin',
          type: PluginErrorType.runtime,
          message: 'Test error',
          timestamp: DateTime.now(),
        );

        // Act
        errorTracker.recordError(error);

        // Assert
        expect(errorTracker.errors.length, 1);
        expect(errorTracker.errors.first, error);
      });

      test('should notify listeners when error is recorded', () {
        // Arrange
        final error = PluginError(
          pluginId: 'test-plugin',
          pluginName: 'Test Plugin',
          type: PluginErrorType.runtime,
          message: 'Test error',
          timestamp: DateTime.now(),
        );
        var notified = false;
        errorTracker.addListener(() => notified = true);

        // Act
        errorTracker.recordError(error);

        // Assert
        expect(notified, true);
      });

      test('should maintain maxErrors limit by removing oldest', () {
        // Arrange
        final tracker = ErrorTracker(maxErrors: 3);
        final errors = List.generate(
          5,
          (i) => PluginError(
            pluginId: 'plugin-$i',
            pluginName: 'Plugin $i',
            type: PluginErrorType.runtime,
            message: 'Error $i',
            timestamp: DateTime.now(),
          ),
        );

        // Act
        for (final error in errors) {
          tracker.recordError(error);
        }

        // Assert
        expect(tracker.errors.length, 3);
        expect(tracker.errors[0].pluginId, 'plugin-2'); // Oldest kept
        expect(tracker.errors[1].pluginId, 'plugin-3');
        expect(tracker.errors[2].pluginId, 'plugin-4'); // Most recent

        tracker.dispose();
      });

      test('should handle recording multiple errors for same plugin', () {
        // Arrange
        final error1 = PluginError(
          pluginId: 'test-plugin',
          pluginName: 'Test Plugin',
          type: PluginErrorType.runtime,
          message: 'Error 1',
          timestamp: DateTime.now(),
        );
        final error2 = PluginError(
          pluginId: 'test-plugin',
          pluginName: 'Test Plugin',
          type: PluginErrorType.initialization,
          message: 'Error 2',
          timestamp: DateTime.now(),
        );

        // Act
        errorTracker.recordError(error1);
        errorTracker.recordError(error2);

        // Assert
        expect(errorTracker.errors.length, 2);
        expect(errorTracker.getErrorCount('test-plugin'), 2);
      });
    });

    group('getErrorsForPlugin', () {
      test('should return errors for specific plugin', () {
        // Arrange
        final error1 = PluginError(
          pluginId: 'plugin-a',
          pluginName: 'Plugin A',
          type: PluginErrorType.runtime,
          message: 'Error 1',
          timestamp: DateTime.now(),
        );
        final error2 = PluginError(
          pluginId: 'plugin-b',
          pluginName: 'Plugin B',
          type: PluginErrorType.runtime,
          message: 'Error 2',
          timestamp: DateTime.now(),
        );
        final error3 = PluginError(
          pluginId: 'plugin-a',
          pluginName: 'Plugin A',
          type: PluginErrorType.runtime,
          message: 'Error 3',
          timestamp: DateTime.now(),
        );

        errorTracker.recordError(error1);
        errorTracker.recordError(error2);
        errorTracker.recordError(error3);

        // Act
        final pluginAErrors = errorTracker.getErrorsForPlugin('plugin-a');

        // Assert
        expect(pluginAErrors.length, 2);
        expect(pluginAErrors.every((e) => e.pluginId == 'plugin-a'), true);
      });

      test('should return empty list for plugin with no errors', () {
        // Arrange
        final error = PluginError(
          pluginId: 'plugin-a',
          pluginName: 'Plugin A',
          type: PluginErrorType.runtime,
          message: 'Error',
          timestamp: DateTime.now(),
        );
        errorTracker.recordError(error);

        // Act
        final result = errorTracker.getErrorsForPlugin('plugin-b');

        // Assert
        expect(result, isEmpty);
      });
    });

    group('getRecentErrors', () {
      test('should return most recent errors first', () async {
        // Arrange
        final now = DateTime.now();
        final error1 = PluginError(
          pluginId: 'plugin-1',
          pluginName: 'Plugin 1',
          type: PluginErrorType.runtime,
          message: 'Old error',
          timestamp: now.subtract(const Duration(hours: 2)),
        );
        final error2 = PluginError(
          pluginId: 'plugin-2',
          pluginName: 'Plugin 2',
          type: PluginErrorType.runtime,
          message: 'Recent error',
          timestamp: now.subtract(const Duration(minutes: 5)),
        );
        final error3 = PluginError(
          pluginId: 'plugin-3',
          pluginName: 'Plugin 3',
          type: PluginErrorType.runtime,
          message: 'Latest error',
          timestamp: now,
        );

        errorTracker.recordError(error1);
        await Future.delayed(const Duration(milliseconds: 10));
        errorTracker.recordError(error2);
        await Future.delayed(const Duration(milliseconds: 10));
        errorTracker.recordError(error3);

        // Act
        final recent = errorTracker.getRecentErrors(limit: 2);

        // Assert
        expect(recent.length, 2);
        expect(recent[0].message, 'Latest error');
        expect(recent[1].message, 'Recent error');
      });

      test('should respect limit parameter', () {
        // Arrange
        for (var i = 0; i < 15; i++) {
          errorTracker.recordError(PluginError(
            pluginId: 'plugin-$i',
            pluginName: 'Plugin $i',
            type: PluginErrorType.runtime,
            message: 'Error $i',
            timestamp: DateTime.now(),
          ));
        }

        // Act
        final recent = errorTracker.getRecentErrors(limit: 5);

        // Assert
        expect(recent.length, 5);
      });

      test('should use default limit of 10', () {
        // Arrange
        for (var i = 0; i < 15; i++) {
          errorTracker.recordError(PluginError(
            pluginId: 'plugin-$i',
            pluginName: 'Plugin $i',
            type: PluginErrorType.runtime,
            message: 'Error $i',
            timestamp: DateTime.now(),
          ));
        }

        // Act
        final recent = errorTracker.getRecentErrors();

        // Assert
        expect(recent.length, 10);
      });
    });

    group('getErrorsByType', () {
      test('should return errors of specific type', () {
        // Arrange
        final runtimeError = PluginError(
          pluginId: 'plugin-1',
          pluginName: 'Plugin 1',
          type: PluginErrorType.runtime,
          message: 'Runtime error',
          timestamp: DateTime.now(),
        );
        final initError = PluginError(
          pluginId: 'plugin-2',
          pluginName: 'Plugin 2',
          type: PluginErrorType.initialization,
          message: 'Init error',
          timestamp: DateTime.now(),
        );
        final anotherRuntimeError = PluginError(
          pluginId: 'plugin-3',
          pluginName: 'Plugin 3',
          type: PluginErrorType.runtime,
          message: 'Another runtime error',
          timestamp: DateTime.now(),
        );

        errorTracker.recordError(runtimeError);
        errorTracker.recordError(initError);
        errorTracker.recordError(anotherRuntimeError);

        // Act
        final runtimeErrors =
            errorTracker.getErrorsByType(PluginErrorType.runtime);

        // Assert
        expect(runtimeErrors.length, 2);
        expect(
            runtimeErrors.every((e) => e.type == PluginErrorType.runtime), true);
      });

      test('should return empty list for type with no errors', () {
        // Arrange
        final error = PluginError(
          pluginId: 'plugin-1',
          pluginName: 'Plugin 1',
          type: PluginErrorType.runtime,
          message: 'Error',
          timestamp: DateTime.now(),
        );
        errorTracker.recordError(error);

        // Act
        final result = errorTracker.getErrorsByType(PluginErrorType.messaging);

        // Assert
        expect(result, isEmpty);
      });
    });

    group('getErrorStatistics', () {
      test('should return error count by plugin ID', () {
        // Arrange
        errorTracker.recordError(PluginError(
          pluginId: 'plugin-a',
          pluginName: 'Plugin A',
          type: PluginErrorType.runtime,
          message: 'Error 1',
          timestamp: DateTime.now(),
        ));
        errorTracker.recordError(PluginError(
          pluginId: 'plugin-a',
          pluginName: 'Plugin A',
          type: PluginErrorType.runtime,
          message: 'Error 2',
          timestamp: DateTime.now(),
        ));
        errorTracker.recordError(PluginError(
          pluginId: 'plugin-b',
          pluginName: 'Plugin B',
          type: PluginErrorType.runtime,
          message: 'Error 3',
          timestamp: DateTime.now(),
        ));

        // Act
        final stats = errorTracker.getErrorStatistics();

        // Assert
        expect(stats['plugin-a'], 2);
        expect(stats['plugin-b'], 1);
        expect(stats.length, 2);
      });

      test('should return empty map when no errors', () {
        // Act
        final stats = errorTracker.getErrorStatistics();

        // Assert
        expect(stats, isEmpty);
      });
    });

    group('getErrorCount', () {
      test('should return correct error count for plugin', () {
        // Arrange
        for (var i = 0; i < 3; i++) {
          errorTracker.recordError(PluginError(
            pluginId: 'test-plugin',
            pluginName: 'Test Plugin',
            type: PluginErrorType.runtime,
            message: 'Error $i',
            timestamp: DateTime.now(),
          ));
        }

        // Act
        final count = errorTracker.getErrorCount('test-plugin');

        // Assert
        expect(count, 3);
      });

      test('should return 0 for plugin with no errors', () {
        // Act
        final count = errorTracker.getErrorCount('nonexistent-plugin');

        // Assert
        expect(count, 0);
      });
    });

    group('clearPluginErrors', () {
      test('should remove all errors for specific plugin', () {
        // Arrange
        errorTracker.recordError(PluginError(
          pluginId: 'plugin-a',
          pluginName: 'Plugin A',
          type: PluginErrorType.runtime,
          message: 'Error 1',
          timestamp: DateTime.now(),
        ));
        errorTracker.recordError(PluginError(
          pluginId: 'plugin-b',
          pluginName: 'Plugin B',
          type: PluginErrorType.runtime,
          message: 'Error 2',
          timestamp: DateTime.now(),
        ));
        errorTracker.recordError(PluginError(
          pluginId: 'plugin-a',
          pluginName: 'Plugin A',
          type: PluginErrorType.runtime,
          message: 'Error 3',
          timestamp: DateTime.now(),
        ));

        // Act
        errorTracker.clearPluginErrors('plugin-a');

        // Assert
        expect(errorTracker.errors.length, 1);
        expect(errorTracker.errors.first.pluginId, 'plugin-b');
        expect(errorTracker.getErrorCount('plugin-a'), 0);
      });

      test('should notify listeners when clearing plugin errors', () {
        // Arrange
        errorTracker.recordError(PluginError(
          pluginId: 'test-plugin',
          pluginName: 'Test Plugin',
          type: PluginErrorType.runtime,
          message: 'Error',
          timestamp: DateTime.now(),
        ));
        var notified = false;
        errorTracker.addListener(() => notified = true);

        // Act
        errorTracker.clearPluginErrors('test-plugin');

        // Assert
        expect(notified, true);
      });

      test('should be safe to call for non-existent plugin', () {
        // Arrange
        errorTracker.recordError(PluginError(
          pluginId: 'plugin-a',
          pluginName: 'Plugin A',
          type: PluginErrorType.runtime,
          message: 'Error',
          timestamp: DateTime.now(),
        ));

        // Act
        errorTracker.clearPluginErrors('plugin-b');

        // Assert
        expect(errorTracker.errors.length, 1);
      });
    });

    group('clearAllErrors', () {
      test('should remove all errors', () {
        // Arrange
        for (var i = 0; i < 5; i++) {
          errorTracker.recordError(PluginError(
            pluginId: 'plugin-$i',
            pluginName: 'Plugin $i',
            type: PluginErrorType.runtime,
            message: 'Error $i',
            timestamp: DateTime.now(),
          ));
        }

        // Act
        errorTracker.clearAllErrors();

        // Assert
        expect(errorTracker.errors, isEmpty);
      });

      test('should notify listeners when clearing all errors', () {
        // Arrange
        errorTracker.recordError(PluginError(
          pluginId: 'test-plugin',
          pluginName: 'Test Plugin',
          type: PluginErrorType.runtime,
          message: 'Error',
          timestamp: DateTime.now(),
        ));
        var notified = false;
        errorTracker.addListener(() => notified = true);

        // Act
        errorTracker.clearAllErrors();

        // Assert
        expect(notified, true);
      });
    });

    group('clearOldErrors', () {
      test('should remove errors older than specified duration', () {
        // Arrange
        final now = DateTime.now();
        final oldError = PluginError(
          pluginId: 'plugin-1',
          pluginName: 'Plugin 1',
          type: PluginErrorType.runtime,
          message: 'Old error',
          timestamp: now.subtract(const Duration(hours: 2)),
        );
        final recentError = PluginError(
          pluginId: 'plugin-2',
          pluginName: 'Plugin 2',
          type: PluginErrorType.runtime,
          message: 'Recent error',
          timestamp: now.subtract(const Duration(minutes: 30)),
        );

        errorTracker.recordError(oldError);
        errorTracker.recordError(recentError);

        // Act
        errorTracker.clearOldErrors(const Duration(hours: 1));

        // Assert
        expect(errorTracker.errors.length, 1);
        expect(errorTracker.errors.first.message, 'Recent error');
      });

      test('should notify listeners when clearing old errors', () {
        // Arrange
        errorTracker.recordError(PluginError(
          pluginId: 'test-plugin',
          pluginName: 'Test Plugin',
          type: PluginErrorType.runtime,
          message: 'Old error',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ));
        var notified = false;
        errorTracker.addListener(() => notified = true);

        // Act
        errorTracker.clearOldErrors(const Duration(hours: 1));

        // Assert
        expect(notified, true);
      });

      test('should keep all errors if none are old enough', () {
        // Arrange
        for (var i = 0; i < 3; i++) {
          errorTracker.recordError(PluginError(
            pluginId: 'plugin-$i',
            pluginName: 'Plugin $i',
            type: PluginErrorType.runtime,
            message: 'Error $i',
            timestamp: DateTime.now(),
          ));
        }

        // Act
        errorTracker.clearOldErrors(const Duration(hours: 1));

        // Assert
        expect(errorTracker.errors.length, 3);
      });
    });

    group('getPluginsWithCriticalErrors', () {
      test('should return plugins with initialization errors', () {
        // Arrange
        errorTracker.recordError(PluginError(
          pluginId: 'plugin-a',
          pluginName: 'Plugin A',
          type: PluginErrorType.initialization,
          message: 'Init error',
          timestamp: DateTime.now(),
        ));
        errorTracker.recordError(PluginError(
          pluginId: 'plugin-b',
          pluginName: 'Plugin B',
          type: PluginErrorType.runtime,
          message: 'Runtime error',
          timestamp: DateTime.now(),
        ));

        // Act
        final critical = errorTracker.getPluginsWithCriticalErrors();

        // Assert
        expect(critical.length, 1);
        expect(critical.contains('plugin-a'), true);
      });

      test('should return plugins with dependency errors', () {
        // Arrange
        errorTracker.recordError(PluginError(
          pluginId: 'plugin-a',
          pluginName: 'Plugin A',
          type: PluginErrorType.dependency,
          message: 'Dependency error',
          timestamp: DateTime.now(),
        ));

        // Act
        final critical = errorTracker.getPluginsWithCriticalErrors();

        // Assert
        expect(critical.length, 1);
        expect(critical.contains('plugin-a'), true);
      });

      test('should not return duplicates for multiple critical errors', () {
        // Arrange
        errorTracker.recordError(PluginError(
          pluginId: 'plugin-a',
          pluginName: 'Plugin A',
          type: PluginErrorType.initialization,
          message: 'Error 1',
          timestamp: DateTime.now(),
        ));
        errorTracker.recordError(PluginError(
          pluginId: 'plugin-a',
          pluginName: 'Plugin A',
          type: PluginErrorType.dependency,
          message: 'Error 2',
          timestamp: DateTime.now(),
        ));

        // Act
        final critical = errorTracker.getPluginsWithCriticalErrors();

        // Assert
        expect(critical.length, 1);
      });

      test('should return empty set when no critical errors', () {
        // Arrange
        errorTracker.recordError(PluginError(
          pluginId: 'plugin-a',
          pluginName: 'Plugin A',
          type: PluginErrorType.runtime,
          message: 'Runtime error',
          timestamp: DateTime.now(),
        ));

        // Act
        final critical = errorTracker.getPluginsWithCriticalErrors();

        // Assert
        expect(critical, isEmpty);
      });
    });

    group('hasExceededThreshold', () {
      test('should return true when error count exceeds threshold', () {
        // Arrange
        for (var i = 0; i < 5; i++) {
          errorTracker.recordError(PluginError(
            pluginId: 'test-plugin',
            pluginName: 'Test Plugin',
            type: PluginErrorType.runtime,
            message: 'Error $i',
            timestamp: DateTime.now(),
          ));
        }

        // Act
        final exceeded = errorTracker.hasExceededThreshold('test-plugin', 3);

        // Assert
        expect(exceeded, true);
      });

      test('should return true when error count equals threshold', () {
        // Arrange
        for (var i = 0; i < 3; i++) {
          errorTracker.recordError(PluginError(
            pluginId: 'test-plugin',
            pluginName: 'Test Plugin',
            type: PluginErrorType.runtime,
            message: 'Error $i',
            timestamp: DateTime.now(),
          ));
        }

        // Act
        final exceeded = errorTracker.hasExceededThreshold('test-plugin', 3);

        // Assert
        expect(exceeded, true);
      });

      test('should return false when error count below threshold', () {
        // Arrange
        errorTracker.recordError(PluginError(
          pluginId: 'test-plugin',
          pluginName: 'Test Plugin',
          type: PluginErrorType.runtime,
          message: 'Error',
          timestamp: DateTime.now(),
        ));

        // Act
        final exceeded = errorTracker.hasExceededThreshold('test-plugin', 5);

        // Assert
        expect(exceeded, false);
      });

      test('should return false for plugin with no errors', () {
        // Act
        final exceeded =
            errorTracker.hasExceededThreshold('nonexistent-plugin', 1);

        // Assert
        expect(exceeded, false);
      });
    });

    group('dispose', () {
      test('should clear all errors on dispose', () {
        // Arrange
        for (var i = 0; i < 3; i++) {
          errorTracker.recordError(PluginError(
            pluginId: 'plugin-$i',
            pluginName: 'Plugin $i',
            type: PluginErrorType.runtime,
            message: 'Error $i',
            timestamp: DateTime.now(),
          ));
        }

        // Act
        errorTracker.dispose();

        // Assert
        expect(errorTracker.errors, isEmpty);
      });
    });

    group('edge cases', () {
      test('should handle errors list being unmodifiable', () {
        // Arrange
        errorTracker.recordError(PluginError(
          pluginId: 'test-plugin',
          pluginName: 'Test Plugin',
          type: PluginErrorType.runtime,
          message: 'Error',
          timestamp: DateTime.now(),
        ));

        // Act
        final errors = errorTracker.errors;

        // Assert
        expect(() => errors.add(PluginError(
          pluginId: 'another-plugin',
          pluginName: 'Another Plugin',
          type: PluginErrorType.runtime,
          message: 'Another error',
          timestamp: DateTime.now(),
        )), throwsUnsupportedError);
      });

      test('should handle concurrent error recording', () async {
        // Arrange
        final futures = <Future>[];

        // Act
        for (var i = 0; i < 10; i++) {
          futures.add(Future(() {
            errorTracker.recordError(PluginError(
              pluginId: 'plugin-$i',
              pluginName: 'Plugin $i',
              type: PluginErrorType.runtime,
              message: 'Error $i',
              timestamp: DateTime.now(),
            ));
          }));
        }
        await Future.wait(futures);

        // Assert
        expect(errorTracker.errors.length, 10);
      });
    });
  });
}
