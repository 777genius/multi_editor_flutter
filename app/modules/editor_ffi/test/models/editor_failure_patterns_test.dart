import 'package:flutter_test/flutter_test.dart';
import 'package:editor_core/editor_core.dart';

void main() {
  group('EditorFailure Patterns (FFI Context)', () {
    group('notInitialized', () {
      test('should create not initialized failure with default message', () {
        // Act
        const failure = EditorFailure.notInitialized();

        // Assert
        expect(failure.message, equals('Editor is not initialized'));
      });

      test('should create not initialized failure with custom message', () {
        // Act
        const failure = EditorFailure.notInitialized(
          message: 'Failed to create native editor',
        );

        // Assert
        expect(failure.message, equals('Failed to create native editor'));
      });

      test('should support pattern matching', () {
        // Arrange
        const failure = EditorFailure.notInitialized();
        late bool matchedCorrectly;

        // Act
        failure.when(
          notInitialized: (_) => matchedCorrectly = true,
          invalidPosition: (_) => matchedCorrectly = false,
          invalidRange: (_) => matchedCorrectly = false,
          documentNotFound: (_) => matchedCorrectly = false,
          operationFailed: (_, __) => matchedCorrectly = false,
          unsupportedOperation: (_) => matchedCorrectly = false,
          unexpected: (_, __) => matchedCorrectly = false,
        );

        // Assert
        expect(matchedCorrectly, isTrue);
      });

      test('should be used when FFI handle is null', () {
        // This represents the failure returned when _editorHandle is null
        // Act
        const failure = EditorFailure.notInitialized(
          message: 'Not connected to native editor',
        );

        // Assert
        expect(failure, isA<EditorFailure>());
        expect(failure.message, contains('native editor'));
      });
    });

    group('operationFailed', () {
      test('should create operation failed failure with operation name', () {
        // Act
        const failure = EditorFailure.operationFailed(
          operation: 'setContent',
        );

        // Assert
        expect(failure.message, contains('setContent'));
        expect(failure.message, contains('failed'));
      });

      test('should create operation failed failure with reason', () {
        // Act
        const failure = EditorFailure.operationFailed(
          operation: 'insertText',
          reason: 'Invalid UTF-8 encoding',
        );

        // Assert
        expect(failure.message, contains('insertText'));
        expect(failure.message, contains('Invalid UTF-8 encoding'));
      });

      test('should handle native operation failures', () {
        // Typical FFI failures
        final operations = [
          ('setContent', 'Native returned error code'),
          ('insertText', 'Failed to encode text'),
          ('getCursorPosition', 'Invalid cursor state'),
          ('setSelection', 'Selection bounds invalid'),
          ('undo', 'Nothing to undo'),
          ('redo', 'Nothing to redo'),
        ];

        for (final (operation, reason) in operations) {
          // Act
          final failure = EditorFailure.operationFailed(
            operation: operation,
            reason: reason,
          );

          // Assert
          expect(failure.message, contains(operation));
          expect(failure.message, contains(reason));
        }
      });

      test('should work without reason', () {
        // Act
        const failure = EditorFailure.operationFailed(
          operation: 'delete',
        );

        // Assert
        expect(failure.message, equals('Operation "delete" failed'));
      });
    });

    group('invalidPosition', () {
      test('should create invalid position failure', () {
        // Act
        const failure = EditorFailure.invalidPosition(
          message: 'Position (100, 500) is out of bounds',
        );

        // Assert
        expect(failure.message, contains('out of bounds'));
      });

      test('should describe position validation errors', () {
        // Act
        const failure = EditorFailure.invalidPosition(
          message: 'Line 50 exceeds document length of 30',
        );

        // Assert
        expect(failure.message, contains('exceeds document length'));
      });
    });

    group('invalidRange', () {
      test('should create invalid range failure', () {
        // Act
        const failure = EditorFailure.invalidRange(
          message: 'Range start is after end',
        );

        // Assert
        expect(failure.message, contains('start is after end'));
      });

      test('should describe selection range errors', () {
        // Act
        const failure = EditorFailure.invalidRange(
          message: 'Selection range exceeds document bounds',
        );

        // Assert
        expect(failure.message, contains('exceeds document bounds'));
      });
    });

    group('documentNotFound', () {
      test('should create document not found failure with default message', () {
        // Act
        const failure = EditorFailure.documentNotFound();

        // Assert
        expect(failure.message, equals('Document not found'));
      });

      test('should create document not found failure with custom message', () {
        // Act
        const failure = EditorFailure.documentNotFound(
          message: 'No document is currently open',
        );

        // Assert
        expect(failure.message, equals('No document is currently open'));
      });

      test('should be used when current document is null', () {
        // This represents the failure when _currentDocument is null
        // Act
        const failure = EditorFailure.documentNotFound(
          message: 'No active document in editor',
        );

        // Assert
        expect(failure.message, contains('No active document'));
      });
    });

    group('unsupportedOperation', () {
      test('should create unsupported operation failure', () {
        // Act
        const failure = EditorFailure.unsupportedOperation(
          operation: 'getTheme',
        );

        // Assert
        expect(failure.message, contains('getTheme'));
        expect(failure.message, contains('not supported'));
      });

      test('should identify operations not available in FFI', () {
        // Operations that are not supported in native FFI implementation
        final unsupportedOps = [
          'getTheme',
          'formatDocument - use LSP',
          'find',
          'replace',
          'getSelection',
        ];

        for (final operation in unsupportedOps) {
          // Act
          final failure = EditorFailure.unsupportedOperation(
            operation: operation,
          );

          // Assert
          expect(failure.message, contains(operation));
          expect(failure.message, contains('not supported'));
        }
      });
    });

    group('unexpected', () {
      test('should create unexpected failure with message', () {
        // Act
        const failure = EditorFailure.unexpected(
          message: 'Unexpected native exception',
        );

        // Assert
        expect(failure.message, equals('Unexpected native exception'));
      });

      test('should create unexpected failure with error object', () {
        // Arrange
        final error = Exception('FFI call failed');

        // Act
        final failure = EditorFailure.unexpected(
          message: 'Failed to call native function',
          error: error,
        );

        // Assert
        expect(failure.message, equals('Failed to call native function'));
        failure.maybeWhen(
          unexpected: (_, err) => expect(err, equals(error)),
          orElse: () => fail('Should match unexpected'),
        );
      });

      test('should handle FFI exceptions', () {
        // Simulate various FFI-related exceptions
        final exceptions = [
          'ArgumentError: Invalid native type',
          'StateError: Pointer has been freed',
          'FfiException: Native call failed',
        ];

        for (final errorMsg in exceptions) {
          // Act
          final failure = EditorFailure.unexpected(
            message: 'Native operation error',
            error: Exception(errorMsg),
          );

          // Assert
          expect(failure.message, contains('Native operation error'));
        }
      });
    });

    group('pattern matching', () {
      test('should support when pattern matching', () {
        // Arrange
        final failures = [
          const EditorFailure.notInitialized(),
          const EditorFailure.invalidPosition(message: 'test'),
          const EditorFailure.invalidRange(message: 'test'),
          const EditorFailure.documentNotFound(),
          const EditorFailure.operationFailed(operation: 'test'),
          const EditorFailure.unsupportedOperation(operation: 'test'),
          const EditorFailure.unexpected(message: 'test'),
        ];

        // Act & Assert
        for (final failure in failures) {
          final result = failure.when(
            notInitialized: (_) => 'notInitialized',
            invalidPosition: (_) => 'invalidPosition',
            invalidRange: (_) => 'invalidRange',
            documentNotFound: (_) => 'documentNotFound',
            operationFailed: (_, __) => 'operationFailed',
            unsupportedOperation: (_) => 'unsupportedOperation',
            unexpected: (_, __) => 'unexpected',
          );

          expect(result, isA<String>());
          expect(result, isNotEmpty);
        }
      });

      test('should support maybeWhen pattern matching', () {
        // Arrange
        const failure = EditorFailure.operationFailed(
          operation: 'setContent',
          reason: 'Native error',
        );

        // Act
        final result = failure.maybeWhen(
          operationFailed: (op, reason) => 'Failed: $op - $reason',
          orElse: () => 'Other failure',
        );

        // Assert
        expect(result, equals('Failed: setContent - Native error'));
      });

      test('should support map pattern matching', () {
        // Arrange
        const failure = EditorFailure.notInitialized();

        // Act
        final result = failure.map(
          notInitialized: (_) => 'needs initialization',
          invalidPosition: (_) => 'position error',
          invalidRange: (_) => 'range error',
          documentNotFound: (_) => 'document error',
          operationFailed: (_) => 'operation error',
          unsupportedOperation: (_) => 'unsupported error',
          unexpected: (_) => 'unexpected error',
        );

        // Assert
        expect(result, equals('needs initialization'));
      });
    });

    group('equality and comparison', () {
      test('should support equality comparison', () {
        // Arrange
        const failure1 = EditorFailure.notInitialized();
        const failure2 = EditorFailure.notInitialized();
        const failure3 = EditorFailure.documentNotFound();

        // Assert
        expect(failure1, equals(failure2));
        expect(failure1, isNot(equals(failure3)));
      });

      test('should consider parameters in equality', () {
        // Arrange
        const failure1 = EditorFailure.operationFailed(operation: 'undo');
        const failure2 = EditorFailure.operationFailed(operation: 'undo');
        const failure3 = EditorFailure.operationFailed(operation: 'redo');

        // Assert
        expect(failure1, equals(failure2));
        expect(failure1, isNot(equals(failure3)));
      });
    });

    group('message generation', () {
      test('should generate correct messages for all failure types', () {
        // Arrange & Act & Assert
        expect(
          const EditorFailure.notInitialized().message,
          equals('Editor is not initialized'),
        );

        expect(
          const EditorFailure.invalidPosition(message: 'pos error').message,
          equals('pos error'),
        );

        expect(
          const EditorFailure.invalidRange(message: 'range error').message,
          equals('range error'),
        );

        expect(
          const EditorFailure.documentNotFound().message,
          equals('Document not found'),
        );

        expect(
          const EditorFailure.operationFailed(operation: 'test').message,
          equals('Operation "test" failed'),
        );

        expect(
          const EditorFailure.operationFailed(
            operation: 'test',
            reason: 'because',
          ).message,
          equals('Operation "test" failed: because'),
        );

        expect(
          const EditorFailure.unsupportedOperation(operation: 'test').message,
          equals('Operation "test" is not supported'),
        );

        expect(
          const EditorFailure.unexpected(message: 'error').message,
          equals('error'),
        );
      });
    });

    group('FFI-specific scenarios', () {
      test('should handle null pointer scenarios', () {
        // Act
        const failure = EditorFailure.operationFailed(
          operation: 'getContent',
          reason: 'Received null pointer from native',
        );

        // Assert
        expect(failure.message, contains('null pointer'));
      });

      test('should handle encoding errors', () {
        // Act
        const failure = EditorFailure.operationFailed(
          operation: 'setContent',
          reason: 'Failed to encode UTF-8',
        );

        // Assert
        expect(failure.message, contains('UTF-8'));
      });

      test('should handle memory allocation errors', () {
        // Act
        const failure = EditorFailure.unexpected(
          message: 'Failed to allocate native memory',
        );

        // Assert
        expect(failure.message, contains('allocate'));
      });

      test('should handle native library loading errors', () {
        // Act
        const failure = EditorFailure.unexpected(
          message: 'Failed to load native library',
          error: 'UnsupportedError: Platform not supported',
        );

        // Assert
        expect(failure.message, contains('native library'));
      });
    });
  });
}
