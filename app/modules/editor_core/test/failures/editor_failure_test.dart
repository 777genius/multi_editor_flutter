import 'package:flutter_test/flutter_test.dart';
import 'package:editor_core/editor_core.dart';

void main() {
  group('EditorFailure', () {
    group('notInitialized', () {
      test('should create with default message', () {
        // Act
        const failure = EditorFailure.notInitialized();

        // Assert
        expect(failure.message, equals('Editor is not initialized'));
      });

      test('should create with custom message', () {
        // Act
        const failure = EditorFailure.notInitialized(
          message: 'Custom not initialized message',
        );

        // Assert
        expect(failure.message, equals('Custom not initialized message'));
      });

      test('should be an Exception', () {
        const failure = EditorFailure.notInitialized();

        expect(failure, isA<Exception>());
      });
    });

    group('invalidPosition', () {
      test('should create with message', () {
        // Act
        const failure = EditorFailure.invalidPosition(
          message: 'Line must be >= 0',
        );

        // Assert
        expect(failure.message, equals('Line must be >= 0'));
      });

      test('should require message', () {
        // This test ensures message is required (compile-time check)
        const failure = EditorFailure.invalidPosition(
          message: 'Required message',
        );

        expect(failure.message, isNotEmpty);
      });
    });

    group('invalidRange', () {
      test('should create with message', () {
        // Act
        const failure = EditorFailure.invalidRange(
          message: 'Start must be before end',
        );

        // Assert
        expect(failure.message, equals('Start must be before end'));
      });
    });

    group('documentNotFound', () {
      test('should create with default message', () {
        // Act
        const failure = EditorFailure.documentNotFound();

        // Assert
        expect(failure.message, equals('Document not found'));
      });

      test('should create with custom message', () {
        // Act
        const failure = EditorFailure.documentNotFound(
          message: 'File does not exist',
        );

        // Assert
        expect(failure.message, equals('File does not exist'));
      });
    });

    group('operationFailed', () {
      test('should create with operation name', () {
        // Act
        const failure = EditorFailure.operationFailed(
          operation: 'save',
        );

        // Assert
        expect(failure.message, contains('save'));
        expect(failure.message, contains('failed'));
      });

      test('should create with operation and reason', () {
        // Act
        const failure = EditorFailure.operationFailed(
          operation: 'save',
          reason: 'Disk full',
        );

        // Assert
        expect(failure.message, contains('save'));
        expect(failure.message, contains('Disk full'));
      });

      test('should format message correctly without reason', () {
        const failure = EditorFailure.operationFailed(
          operation: 'load',
        );

        expect(failure.message, equals('Operation "load" failed'));
      });

      test('should format message correctly with reason', () {
        const failure = EditorFailure.operationFailed(
          operation: 'load',
          reason: 'File corrupted',
        );

        expect(failure.message, equals('Operation "load" failed: File corrupted'));
      });
    });

    group('unsupportedOperation', () {
      test('should create with operation name', () {
        // Act
        const failure = EditorFailure.unsupportedOperation(
          operation: 'undo',
        );

        // Assert
        expect(failure.message, contains('undo'));
        expect(failure.message, contains('not supported'));
      });

      test('should format message correctly', () {
        const failure = EditorFailure.unsupportedOperation(
          operation: 'macroRecording',
        );

        expect(
          failure.message,
          equals('Operation "macroRecording" is not supported'),
        );
      });
    });

    group('unexpected', () {
      test('should create with message', () {
        // Act
        const failure = EditorFailure.unexpected(
          message: 'Unexpected error occurred',
        );

        // Assert
        expect(failure.message, equals('Unexpected error occurred'));
      });

      test('should create with message and error object', () {
        // Arrange
        final error = Exception('Original error');

        // Act
        final failure = EditorFailure.unexpected(
          message: 'Unexpected error',
          error: error,
        );

        // Assert
        expect(failure.message, equals('Unexpected error'));
        failure.when(
          notInitialized: (_) => fail('Wrong type'),
          invalidPosition: (_) => fail('Wrong type'),
          invalidRange: (_) => fail('Wrong type'),
          documentNotFound: (_) => fail('Wrong type'),
          operationFailed: (_, __) => fail('Wrong type'),
          unsupportedOperation: (_) => fail('Wrong type'),
          unexpected: (msg, err) {
            expect(err, equals(error));
          },
        );
      });

      test('should handle any error object', () {
        final error = StateError('Invalid state');

        final failure = EditorFailure.unexpected(
          message: 'State error',
          error: error,
        );

        failure.when(
          notInitialized: (_) => fail('Wrong type'),
          invalidPosition: (_) => fail('Wrong type'),
          invalidRange: (_) => fail('Wrong type'),
          documentNotFound: (_) => fail('Wrong type'),
          operationFailed: (_, __) => fail('Wrong type'),
          unsupportedOperation: (_) => fail('Wrong type'),
          unexpected: (msg, err) {
            expect(err, isA<StateError>());
          },
        );
      });
    });

    group('equality', () {
      test('should be equal with same type and data', () {
        const failure1 = EditorFailure.invalidPosition(
          message: 'Invalid line',
        );
        const failure2 = EditorFailure.invalidPosition(
          message: 'Invalid line',
        );

        expect(failure1, equals(failure2));
        expect(failure1.hashCode, equals(failure2.hashCode));
      });

      test('should not be equal with different types', () {
        const failure1 = EditorFailure.notInitialized();
        const failure2 = EditorFailure.documentNotFound();

        expect(failure1, isNot(equals(failure2)));
      });

      test('should not be equal with different data', () {
        const failure1 = EditorFailure.operationFailed(operation: 'save');
        const failure2 = EditorFailure.operationFailed(operation: 'load');

        expect(failure1, isNot(equals(failure2)));
      });
    });

    group('pattern matching', () {
      test('should support pattern matching with when', () {
        // Arrange
        const failure = EditorFailure.operationFailed(
          operation: 'save',
          reason: 'permission denied',
        );

        // Act
        final result = failure.when(
          notInitialized: (_) => 'not_init',
          invalidPosition: (_) => 'invalid_pos',
          invalidRange: (_) => 'invalid_range',
          documentNotFound: (_) => 'not_found',
          operationFailed: (op, reason) => 'op_failed: $op',
          unsupportedOperation: (_) => 'unsupported',
          unexpected: (_, __) => 'unexpected',
        );

        // Assert
        expect(result, equals('op_failed: save'));
      });

      test('should support maybeWhen with orElse', () {
        const failure = EditorFailure.notInitialized();

        final result = failure.maybeWhen(
          notInitialized: (_) => 'handled',
          orElse: () => 'not_handled',
        );

        expect(result, equals('handled'));
      });

      test('should call orElse for unhandled cases', () {
        const failure = EditorFailure.unexpected(message: 'error');

        final result = failure.maybeWhen(
          notInitialized: (_) => 'handled',
          orElse: () => 'default',
        );

        expect(result, equals('default'));
      });
    });

    group('error handling', () {
      test('should be throwable', () {
        const failure = EditorFailure.notInitialized();

        expect(() => throw failure, throwsA(isA<EditorFailure>()));
      });

      test('should preserve error information when caught', () {
        try {
          throw const EditorFailure.operationFailed(
            operation: 'test',
            reason: 'failed',
          );
        } catch (e) {
          expect(e, isA<EditorFailure>());
          final failure = e as EditorFailure;
          expect(failure.message, contains('test'));
          expect(failure.message, contains('failed'));
        }
      });
    });

    group('message getter', () {
      test('should return correct message for each variant', () {
        final failures = [
          const EditorFailure.notInitialized(),
          const EditorFailure.invalidPosition(message: 'pos error'),
          const EditorFailure.invalidRange(message: 'range error'),
          const EditorFailure.documentNotFound(),
          const EditorFailure.operationFailed(operation: 'save'),
          const EditorFailure.unsupportedOperation(operation: 'undo'),
          const EditorFailure.unexpected(message: 'unexpected'),
        ];

        for (final failure in failures) {
          expect(failure.message, isNotEmpty);
        }
      });

      test('should work with all failure types', () {
        final messages = [
          const EditorFailure.notInitialized().message,
          const EditorFailure.invalidPosition(message: 'test').message,
          const EditorFailure.invalidRange(message: 'test').message,
          const EditorFailure.documentNotFound().message,
          const EditorFailure.operationFailed(operation: 'test').message,
          const EditorFailure.unsupportedOperation(operation: 'test').message,
          const EditorFailure.unexpected(message: 'test').message,
        ];

        expect(messages.every((msg) => msg.isNotEmpty), isTrue);
      });
    });

    group('common use cases', () {
      test('should represent initialization errors', () {
        const failure = EditorFailure.notInitialized();

        expect(failure.message, contains('not initialized'));
      });

      test('should represent validation errors', () {
        const failure = EditorFailure.invalidPosition(
          message: 'Line -1 is invalid',
        );

        expect(failure.message, contains('invalid'));
      });

      test('should represent file errors', () {
        const failure = EditorFailure.documentNotFound(
          message: '/path/to/file.dart not found',
        );

        expect(failure.message, contains('not found'));
      });

      test('should represent operation errors', () {
        const failure = EditorFailure.operationFailed(
          operation: 'save',
          reason: 'Permission denied',
        );

        expect(failure.message, contains('save'));
        expect(failure.message, contains('Permission denied'));
      });

      test('should represent unsupported features', () {
        const failure = EditorFailure.unsupportedOperation(
          operation: 'split-editor',
        );

        expect(failure.message, contains('not supported'));
      });
    });
  });
}
