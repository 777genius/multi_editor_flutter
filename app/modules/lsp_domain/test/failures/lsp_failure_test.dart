import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_domain/lsp_domain.dart';

void main() {
  group('LspFailure', () {
    group('sessionNotFound', () {
      test('should create with default message', () {
        // Act
        const failure = LspFailure.sessionNotFound();

        // Assert
        expect(failure.message, equals('LSP session not found'));
      });

      test('should create with custom message', () {
        // Act
        const failure = LspFailure.sessionNotFound(
          message: 'Custom session not found message',
        );

        // Assert
        expect(failure.message, equals('Custom session not found message'));
      });

      test('should be an Exception', () {
        const failure = LspFailure.sessionNotFound();

        expect(failure, isA<Exception>());
      });
    });

    group('initializationFailed', () {
      test('should create with reason', () {
        // Act
        const failure = LspFailure.initializationFailed(
          reason: 'Server startup failed',
        );

        // Assert
        expect(failure.reason, equals('Server startup failed'));
      });

      test('should require reason', () {
        // This test ensures reason is required (compile-time check)
        const failure = LspFailure.initializationFailed(
          reason: 'Required reason',
        );

        expect(failure.reason, isNotEmpty);
      });
    });

    group('requestFailed', () {
      test('should create with method', () {
        // Act
        const failure = LspFailure.requestFailed(
          method: 'textDocument/completion',
        );

        // Assert
        expect(failure.method, equals('textDocument/completion'));
        expect(failure.reason, isNull);
      });

      test('should create with method and reason', () {
        // Act
        const failure = LspFailure.requestFailed(
          method: 'textDocument/hover',
          reason: 'Timeout after 5 seconds',
        );

        // Assert
        expect(failure.method, equals('textDocument/hover'));
        expect(failure.reason, equals('Timeout after 5 seconds'));
      });
    });

    group('serverNotResponding', () {
      test('should create with default message', () {
        // Act
        const failure = LspFailure.serverNotResponding();

        // Assert
        expect(failure.message, equals('LSP server is not responding'));
      });

      test('should create with custom message', () {
        // Act
        const failure = LspFailure.serverNotResponding(
          message: 'Server timeout',
        );

        // Assert
        expect(failure.message, equals('Server timeout'));
      });
    });

    group('unsupportedLanguage', () {
      test('should create with language ID', () {
        // Act
        const failure = LspFailure.unsupportedLanguage(
          languageId: 'cobol',
        );

        // Assert
        expect(failure.languageId, equals('cobol'));
      });

      test('should handle any language ID', () {
        const failure = LspFailure.unsupportedLanguage(
          languageId: 'custom-lang-123',
        );

        expect(failure.languageId, equals('custom-lang-123'));
      });
    });

    group('connectionFailed', () {
      test('should create with reason', () {
        // Act
        const failure = LspFailure.connectionFailed(
          reason: 'WebSocket connection refused',
        );

        // Assert
        expect(failure.reason, equals('WebSocket connection refused'));
      });

      test('should handle network errors', () {
        const failure = LspFailure.connectionFailed(
          reason: 'Network unreachable',
        );

        expect(failure.reason, contains('Network'));
      });
    });

    group('unexpected', () {
      test('should create with message', () {
        // Act
        const failure = LspFailure.unexpected(
          message: 'Unexpected error occurred',
        );

        // Assert
        expect(failure.message, equals('Unexpected error occurred'));
        expect(failure.error, isNull);
      });

      test('should create with message and error object', () {
        // Arrange
        final error = Exception('Original error');

        // Act
        final failure = LspFailure.unexpected(
          message: 'Unexpected error',
          error: error,
        );

        // Assert
        expect(failure.message, equals('Unexpected error'));
        expect(failure.error, equals(error));
      });

      test('should handle any error object', () {
        final error = StateError('Invalid state');

        final failure = LspFailure.unexpected(
          message: 'State error',
          error: error,
        );

        expect(failure.error, isA<StateError>());
      });
    });

    group('equality', () {
      test('should be equal with same type and data', () {
        const failure1 = LspFailure.sessionNotFound(message: 'Not found');
        const failure2 = LspFailure.sessionNotFound(message: 'Not found');

        expect(failure1, equals(failure2));
        expect(failure1.hashCode, equals(failure2.hashCode));
      });

      test('should not be equal with different types', () {
        const failure1 = LspFailure.sessionNotFound();
        const failure2 = LspFailure.serverNotResponding();

        expect(failure1, isNot(equals(failure2)));
      });

      test('should not be equal with different data', () {
        const failure1 = LspFailure.unsupportedLanguage(languageId: 'dart');
        const failure2 = LspFailure.unsupportedLanguage(languageId: 'rust');

        expect(failure1, isNot(equals(failure2)));
      });
    });

    group('pattern matching', () {
      test('should support pattern matching with when', () {
        // Arrange
        const failure = LspFailure.requestFailed(
          method: 'test',
          reason: 'timeout',
        );

        // Act
        final result = failure.when(
          sessionNotFound: (message) => 'session_not_found',
          initializationFailed: (reason) => 'init_failed',
          requestFailed: (method, reason) => 'request_failed: $method',
          serverNotResponding: (message) => 'server_not_responding',
          unsupportedLanguage: (languageId) => 'unsupported_language',
          connectionFailed: (reason) => 'connection_failed',
          unexpected: (message, error) => 'unexpected',
        );

        // Assert
        expect(result, equals('request_failed: test'));
      });

      test('should support maybeWhen with orElse', () {
        const failure = LspFailure.sessionNotFound();

        final result = failure.maybeWhen(
          sessionNotFound: (message) => 'handled',
          orElse: () => 'not_handled',
        );

        expect(result, equals('handled'));
      });

      test('should call orElse for unhandled cases', () {
        const failure = LspFailure.unexpected(message: 'error');

        final result = failure.maybeWhen(
          sessionNotFound: (message) => 'handled',
          orElse: () => 'default',
        );

        expect(result, equals('default'));
      });
    });

    group('error handling', () {
      test('should be throwable', () {
        const failure = LspFailure.sessionNotFound();

        expect(() => throw failure, throwsA(isA<LspFailure>()));
      });

      test('should preserve error information when caught', () {
        try {
          throw const LspFailure.requestFailed(
            method: 'test/method',
            reason: 'failed',
          );
        } catch (e) {
          expect(e, isA<LspFailure>());
          final failure = e as LspFailure;
          failure.when(
            requestFailed: (method, reason) {
              expect(method, equals('test/method'));
              expect(reason, equals('failed'));
            },
            sessionNotFound: (_) => fail('Wrong type'),
            initializationFailed: (_) => fail('Wrong type'),
            serverNotResponding: (_) => fail('Wrong type'),
            unsupportedLanguage: (_) => fail('Wrong type'),
            connectionFailed: (_) => fail('Wrong type'),
            unexpected: (_, __) => fail('Wrong type'),
          );
        }
      });
    });

    group('common use cases', () {
      test('should represent session lifecycle errors', () {
        const failures = [
          LspFailure.sessionNotFound(),
          LspFailure.initializationFailed(reason: 'timeout'),
          LspFailure.serverNotResponding(),
        ];

        expect(failures.length, equals(3));
        expect(failures[0], isA<LspFailure>());
        expect(failures[1], isA<LspFailure>());
        expect(failures[2], isA<LspFailure>());
      });

      test('should represent request errors', () {
        const failure = LspFailure.requestFailed(
          method: 'textDocument/completion',
          reason: 'Request timeout',
        );

        expect(failure.method, equals('textDocument/completion'));
        expect(failure.reason, equals('Request timeout'));
      });

      test('should represent configuration errors', () {
        const failure = LspFailure.unsupportedLanguage(
          languageId: 'unknown-language',
        );

        expect(failure.languageId, equals('unknown-language'));
      });

      test('should represent network errors', () {
        const failure = LspFailure.connectionFailed(
          reason: 'Connection refused by server',
        );

        expect(failure.reason, contains('Connection refused'));
      });
    });
  });
}
