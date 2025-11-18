import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugins/src/plugin_manager/plugin_state.dart';

void main() {
  group('PluginActivationState', () {
    test('should have idle state', () {
      // Arrange & Act
      const state = PluginActivationState.idle;

      // Assert
      expect(state, equals(PluginActivationState.idle));
    });

    test('should have activating state', () {
      // Arrange & Act
      const state = PluginActivationState.activating;

      // Assert
      expect(state, equals(PluginActivationState.activating));
    });

    test('should have active state', () {
      // Arrange & Act
      const state = PluginActivationState.active;

      // Assert
      expect(state, equals(PluginActivationState.active));
    });

    test('should have error state', () {
      // Arrange & Act
      const state = PluginActivationState.error;

      // Assert
      expect(state, equals(PluginActivationState.error));
    });

    test('should have disabled state', () {
      // Arrange & Act
      const state = PluginActivationState.disabled;

      // Assert
      expect(state, equals(PluginActivationState.disabled));
    });

    test('should have all expected states', () {
      // Assert
      expect(PluginActivationState.values, hasLength(5));
      expect(PluginActivationState.values, contains(PluginActivationState.idle));
      expect(PluginActivationState.values, contains(PluginActivationState.activating));
      expect(PluginActivationState.values, contains(PluginActivationState.active));
      expect(PluginActivationState.values, contains(PluginActivationState.error));
      expect(PluginActivationState.values, contains(PluginActivationState.disabled));
    });
  });

  group('PluginStatus', () {
    const testPluginId = 'test-plugin';

    group('Construction', () {
      test('should create status with required fields', () {
        // Arrange & Act
        const status = PluginStatus(
          pluginId: testPluginId,
          state: PluginActivationState.idle,
        );

        // Assert
        expect(status.pluginId, equals(testPluginId));
        expect(status.state, equals(PluginActivationState.idle));
      });

      test('should have default errorCount of 0', () {
        // Arrange & Act
        const status = PluginStatus(
          pluginId: testPluginId,
          state: PluginActivationState.idle,
        );

        // Assert
        expect(status.errorCount, equals(0));
      });

      test('should have null optional fields by default', () {
        // Arrange & Act
        const status = PluginStatus(
          pluginId: testPluginId,
          state: PluginActivationState.idle,
        );

        // Assert
        expect(status.lastStateChange, isNull);
        expect(status.lastError, isNull);
        expect(status.lastErrorStackTrace, isNull);
        expect(status.lastErrorTime, isNull);
      });

      test('should create status with all fields', () {
        // Arrange
        final stateChange = DateTime(2024, 1, 1);
        final errorTime = DateTime(2024, 1, 2);
        final error = Exception('Test error');
        final stackTrace = StackTrace.current;

        // Act
        final status = PluginStatus(
          pluginId: testPluginId,
          state: PluginActivationState.error,
          lastStateChange: stateChange,
          lastError: error,
          lastErrorStackTrace: stackTrace,
          errorCount: 3,
          lastErrorTime: errorTime,
        );

        // Assert
        expect(status.pluginId, equals(testPluginId));
        expect(status.state, equals(PluginActivationState.error));
        expect(status.lastStateChange, equals(stateChange));
        expect(status.lastError, equals(error));
        expect(status.lastErrorStackTrace, equals(stackTrace));
        expect(status.errorCount, equals(3));
        expect(status.lastErrorTime, equals(errorTime));
      });
    });

    group('copyWith', () {
      test('should copy with updated state', () {
        // Arrange
        const original = PluginStatus(
          pluginId: testPluginId,
          state: PluginActivationState.idle,
        );

        // Act
        final updated = original.copyWith(
          state: PluginActivationState.active,
        );

        // Assert
        expect(updated.pluginId, equals(testPluginId));
        expect(updated.state, equals(PluginActivationState.active));
        expect(updated.errorCount, equals(0)); // Unchanged
      });

      test('should copy with updated lastStateChange', () {
        // Arrange
        const original = PluginStatus(
          pluginId: testPluginId,
          state: PluginActivationState.idle,
        );
        final newTime = DateTime(2024, 1, 1);

        // Act
        final updated = original.copyWith(lastStateChange: newTime);

        // Assert
        expect(updated.lastStateChange, equals(newTime));
      });

      test('should copy with updated error information', () {
        // Arrange
        const original = PluginStatus(
          pluginId: testPluginId,
          state: PluginActivationState.active,
        );
        final error = Exception('Test error');
        final stackTrace = StackTrace.current;
        final errorTime = DateTime(2024, 1, 1);

        // Act
        final updated = original.copyWith(
          state: PluginActivationState.error,
          lastError: error,
          lastErrorStackTrace: stackTrace,
          errorCount: 1,
          lastErrorTime: errorTime,
        );

        // Assert
        expect(updated.state, equals(PluginActivationState.error));
        expect(updated.lastError, equals(error));
        expect(updated.lastErrorStackTrace, equals(stackTrace));
        expect(updated.errorCount, equals(1));
        expect(updated.lastErrorTime, equals(errorTime));
      });

      test('should copy with incremented error count', () {
        // Arrange
        const original = PluginStatus(
          pluginId: testPluginId,
          state: PluginActivationState.error,
          errorCount: 1,
        );

        // Act
        final updated = original.copyWith(errorCount: 2);

        // Assert
        expect(updated.errorCount, equals(2));
      });

      test('should not modify original when copying', () {
        // Arrange
        const original = PluginStatus(
          pluginId: testPluginId,
          state: PluginActivationState.idle,
          errorCount: 0,
        );

        // Act
        final updated = original.copyWith(
          state: PluginActivationState.active,
          errorCount: 5,
        );

        // Assert
        expect(original.state, equals(PluginActivationState.idle));
        expect(original.errorCount, equals(0));
        expect(updated.state, equals(PluginActivationState.active));
        expect(updated.errorCount, equals(5));
      });
    });

    group('isActive getter', () {
      test('should return true when state is active', () {
        // Arrange
        const status = PluginStatus(
          pluginId: testPluginId,
          state: PluginActivationState.active,
        );

        // Act & Assert
        expect(status.isActive, isTrue);
      });

      test('should return false when state is not active', () {
        // Arrange
        const statuses = [
          PluginStatus(pluginId: testPluginId, state: PluginActivationState.idle),
          PluginStatus(pluginId: testPluginId, state: PluginActivationState.activating),
          PluginStatus(pluginId: testPluginId, state: PluginActivationState.error),
          PluginStatus(pluginId: testPluginId, state: PluginActivationState.disabled),
        ];

        // Act & Assert
        for (final status in statuses) {
          expect(status.isActive, isFalse, reason: 'Failed for state: ${status.state}');
        }
      });
    });

    group('isError getter', () {
      test('should return true when state is error', () {
        // Arrange
        const status = PluginStatus(
          pluginId: testPluginId,
          state: PluginActivationState.error,
        );

        // Act & Assert
        expect(status.isError, isTrue);
      });

      test('should return false when state is not error', () {
        // Arrange
        const statuses = [
          PluginStatus(pluginId: testPluginId, state: PluginActivationState.idle),
          PluginStatus(pluginId: testPluginId, state: PluginActivationState.activating),
          PluginStatus(pluginId: testPluginId, state: PluginActivationState.active),
          PluginStatus(pluginId: testPluginId, state: PluginActivationState.disabled),
        ];

        // Act & Assert
        for (final status in statuses) {
          expect(status.isError, isFalse, reason: 'Failed for state: ${status.state}');
        }
      });
    });

    group('isDisabled getter', () {
      test('should return true when state is disabled', () {
        // Arrange
        const status = PluginStatus(
          pluginId: testPluginId,
          state: PluginActivationState.disabled,
        );

        // Act & Assert
        expect(status.isDisabled, isTrue);
      });

      test('should return false when state is not disabled', () {
        // Arrange
        const statuses = [
          PluginStatus(pluginId: testPluginId, state: PluginActivationState.idle),
          PluginStatus(pluginId: testPluginId, state: PluginActivationState.activating),
          PluginStatus(pluginId: testPluginId, state: PluginActivationState.active),
          PluginStatus(pluginId: testPluginId, state: PluginActivationState.error),
        ];

        // Act & Assert
        for (final status in statuses) {
          expect(status.isDisabled, isFalse, reason: 'Failed for state: ${status.state}');
        }
      });
    });

    group('canRetry getter', () {
      test('should return true when in error state with less than 3 errors', () {
        // Arrange
        const statuses = [
          PluginStatus(
            pluginId: testPluginId,
            state: PluginActivationState.error,
            errorCount: 0,
          ),
          PluginStatus(
            pluginId: testPluginId,
            state: PluginActivationState.error,
            errorCount: 1,
          ),
          PluginStatus(
            pluginId: testPluginId,
            state: PluginActivationState.error,
            errorCount: 2,
          ),
        ];

        // Act & Assert
        for (final status in statuses) {
          expect(
            status.canRetry,
            isTrue,
            reason: 'Failed for errorCount: ${status.errorCount}',
          );
        }
      });

      test('should return false when in error state with 3 or more errors', () {
        // Arrange
        const statuses = [
          PluginStatus(
            pluginId: testPluginId,
            state: PluginActivationState.error,
            errorCount: 3,
          ),
          PluginStatus(
            pluginId: testPluginId,
            state: PluginActivationState.error,
            errorCount: 4,
          ),
        ];

        // Act & Assert
        for (final status in statuses) {
          expect(
            status.canRetry,
            isFalse,
            reason: 'Failed for errorCount: ${status.errorCount}',
          );
        }
      });

      test('should return false when not in error state', () {
        // Arrange
        const statuses = [
          PluginStatus(pluginId: testPluginId, state: PluginActivationState.idle),
          PluginStatus(pluginId: testPluginId, state: PluginActivationState.activating),
          PluginStatus(pluginId: testPluginId, state: PluginActivationState.active),
          PluginStatus(pluginId: testPluginId, state: PluginActivationState.disabled),
        ];

        // Act & Assert
        for (final status in statuses) {
          expect(status.canRetry, isFalse, reason: 'Failed for state: ${status.state}');
        }
      });
    });

    group('State Transitions', () {
      test('should transition from idle to activating', () {
        // Arrange
        const idle = PluginStatus(
          pluginId: testPluginId,
          state: PluginActivationState.idle,
        );

        // Act
        final activating = idle.copyWith(
          state: PluginActivationState.activating,
          lastStateChange: DateTime.now(),
        );

        // Assert
        expect(idle.state, equals(PluginActivationState.idle));
        expect(activating.state, equals(PluginActivationState.activating));
        expect(activating.lastStateChange, isNotNull);
      });

      test('should transition from activating to active', () {
        // Arrange
        const activating = PluginStatus(
          pluginId: testPluginId,
          state: PluginActivationState.activating,
        );

        // Act
        final active = activating.copyWith(
          state: PluginActivationState.active,
          lastStateChange: DateTime.now(),
        );

        // Assert
        expect(activating.state, equals(PluginActivationState.activating));
        expect(active.state, equals(PluginActivationState.active));
        expect(active.isActive, isTrue);
      });

      test('should transition from activating to error', () {
        // Arrange
        const activating = PluginStatus(
          pluginId: testPluginId,
          state: PluginActivationState.activating,
        );
        final error = Exception('Activation failed');

        // Act
        final errorState = activating.copyWith(
          state: PluginActivationState.error,
          lastError: error,
          errorCount: 1,
          lastErrorTime: DateTime.now(),
        );

        // Assert
        expect(activating.state, equals(PluginActivationState.activating));
        expect(errorState.state, equals(PluginActivationState.error));
        expect(errorState.isError, isTrue);
        expect(errorState.lastError, equals(error));
        expect(errorState.errorCount, equals(1));
        expect(errorState.canRetry, isTrue);
      });

      test('should transition from error to disabled after 3 errors', () {
        // Arrange
        const errorState = PluginStatus(
          pluginId: testPluginId,
          state: PluginActivationState.error,
          errorCount: 3,
        );

        // Act
        final disabled = errorState.copyWith(
          state: PluginActivationState.disabled,
        );

        // Assert
        expect(errorState.canRetry, isFalse);
        expect(disabled.state, equals(PluginActivationState.disabled));
        expect(disabled.isDisabled, isTrue);
      });

      test('should transition from active to error', () {
        // Arrange
        const active = PluginStatus(
          pluginId: testPluginId,
          state: PluginActivationState.active,
        );
        final error = Exception('Runtime error');

        // Act
        final errorState = active.copyWith(
          state: PluginActivationState.error,
          lastError: error,
          errorCount: 1,
          lastErrorTime: DateTime.now(),
        );

        // Assert
        expect(active.isActive, isTrue);
        expect(errorState.isError, isTrue);
        expect(errorState.lastError, equals(error));
      });
    });

    group('Use Cases', () {
      group('UC1: Normal plugin activation', () {
        test('should successfully activate plugin', () {
          // Arrange
          const idle = PluginStatus(
            pluginId: testPluginId,
            state: PluginActivationState.idle,
          );

          // Act - Start activation
          final activating = idle.copyWith(
            state: PluginActivationState.activating,
            lastStateChange: DateTime.now(),
          );

          // Act - Complete activation
          final active = activating.copyWith(
            state: PluginActivationState.active,
            lastStateChange: DateTime.now(),
          );

          // Assert
          expect(idle.state, equals(PluginActivationState.idle));
          expect(activating.state, equals(PluginActivationState.activating));
          expect(active.state, equals(PluginActivationState.active));
          expect(active.isActive, isTrue);
          expect(active.errorCount, equals(0));
        });
      });

      group('UC2: Plugin activation with retries', () {
        test('should retry activation after errors', () {
          // Arrange
          const idle = PluginStatus(
            pluginId: testPluginId,
            state: PluginActivationState.idle,
          );

          // Act - First attempt fails
          final error1 = idle.copyWith(
            state: PluginActivationState.error,
            lastError: Exception('Network error'),
            errorCount: 1,
            lastErrorTime: DateTime.now(),
          );

          // Act - Second attempt fails
          final error2 = error1.copyWith(
            errorCount: 2,
            lastError: Exception('Timeout error'),
            lastErrorTime: DateTime.now(),
          );

          // Act - Third attempt succeeds
          final active = error2.copyWith(
            state: PluginActivationState.active,
            lastStateChange: DateTime.now(),
          );

          // Assert
          expect(error1.canRetry, isTrue);
          expect(error1.errorCount, equals(1));

          expect(error2.canRetry, isTrue);
          expect(error2.errorCount, equals(2));

          expect(active.isActive, isTrue);
          expect(active.errorCount, equals(2)); // Error count persists
        });
      });

      group('UC3: Plugin disabled after max retries', () {
        test('should disable plugin after 3 errors', () {
          // Arrange
          const idle = PluginStatus(
            pluginId: testPluginId,
            state: PluginActivationState.idle,
          );

          // Act - Accumulate errors
          var current = idle;
          for (var i = 1; i <= 3; i++) {
            current = current.copyWith(
              state: PluginActivationState.error,
              lastError: Exception('Error $i'),
              errorCount: i,
              lastErrorTime: DateTime.now(),
            );
          }

          // Act - Disable after 3 errors
          final disabled = current.copyWith(
            state: PluginActivationState.disabled,
          );

          // Assert
          expect(current.errorCount, equals(3));
          expect(current.canRetry, isFalse);
          expect(disabled.isDisabled, isTrue);
        });
      });

      group('UC4: Plugin runtime error handling', () {
        test('should handle runtime error in active plugin', () {
          // Arrange
          const active = PluginStatus(
            pluginId: testPluginId,
            state: PluginActivationState.active,
          );

          // Act - Runtime error occurs
          final runtimeError = Exception('Runtime error');
          final errorState = active.copyWith(
            state: PluginActivationState.error,
            lastError: runtimeError,
            errorCount: 1,
            lastErrorTime: DateTime.now(),
          );

          // Assert
          expect(active.isActive, isTrue);
          expect(errorState.isError, isTrue);
          expect(errorState.lastError, equals(runtimeError));
          expect(errorState.canRetry, isTrue);
        });
      });

      group('UC5: Track activation history', () {
        test('should maintain state change timestamps', () {
          // Arrange
          final time1 = DateTime(2024, 1, 1, 10, 0, 0);
          final time2 = DateTime(2024, 1, 1, 10, 0, 5);
          final time3 = DateTime(2024, 1, 1, 10, 0, 10);

          // Act
          const idle = PluginStatus(
            pluginId: testPluginId,
            state: PluginActivationState.idle,
          );

          final activating = idle.copyWith(
            state: PluginActivationState.activating,
            lastStateChange: time1,
          );

          final active = activating.copyWith(
            state: PluginActivationState.active,
            lastStateChange: time2,
          );

          final error = active.copyWith(
            state: PluginActivationState.error,
            lastError: Exception('Error'),
            lastStateChange: time3,
            lastErrorTime: time3,
          );

          // Assert
          expect(idle.lastStateChange, isNull);
          expect(activating.lastStateChange, equals(time1));
          expect(active.lastStateChange, equals(time2));
          expect(error.lastStateChange, equals(time3));
          expect(error.lastErrorTime, equals(time3));
        });
      });
    });

    group('Edge Cases', () {
      test('should handle zero error count', () {
        // Arrange & Act
        const status = PluginStatus(
          pluginId: testPluginId,
          state: PluginActivationState.error,
          errorCount: 0,
        );

        // Assert
        expect(status.errorCount, equals(0));
        expect(status.canRetry, isTrue);
      });

      test('should handle very high error count', () {
        // Arrange & Act
        const status = PluginStatus(
          pluginId: testPluginId,
          state: PluginActivationState.error,
          errorCount: 100,
        );

        // Assert
        expect(status.errorCount, equals(100));
        expect(status.canRetry, isFalse);
      });

      test('should handle different error types', () {
        // Arrange
        final exception = Exception('Exception');
        final error = Error();
        final string = 'String error';

        // Act
        const status1 = PluginStatus(
          pluginId: testPluginId,
          state: PluginActivationState.error,
          lastError: exception,
        );

        const status2 = PluginStatus(
          pluginId: testPluginId,
          state: PluginActivationState.error,
          lastError: error,
        );

        const status3 = PluginStatus(
          pluginId: testPluginId,
          state: PluginActivationState.error,
          lastError: string,
        );

        // Assert
        expect(status1.lastError, isA<Exception>());
        expect(status2.lastError, isA<Error>());
        expect(status3.lastError, isA<String>());
      });
    });
  });
}
