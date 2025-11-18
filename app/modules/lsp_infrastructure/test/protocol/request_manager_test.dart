import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_infrastructure/lsp_infrastructure.dart';

void main() {
  group('RequestManager', () {
    late RequestManager manager;

    setUp(() {
      manager = RequestManager();
    });

    tearDown(() {
      manager.dispose();
    });

    group('generateId', () {
      test('should generate unique string IDs by default', () {
        // Act
        final id1 = manager.generateId();
        final id2 = manager.generateId();

        // Assert
        expect(id1, isA<String>());
        expect(id2, isA<String>());
        expect(id1, isNot(equals(id2)));
      });

      test('should generate unique numeric IDs when configured', () {
        // Arrange
        final numericManager = RequestManager(useStringIds: false);

        // Act
        final id1 = numericManager.generateId();
        final id2 = numericManager.generateId();
        final id3 = numericManager.generateId();

        // Assert
        expect(id1, isA<int>());
        expect(id2, isA<int>());
        expect(id1, equals(1));
        expect(id2, equals(2));
        expect(id3, equals(3));

        numericManager.dispose();
      });

      test('should generate many unique IDs', () {
        // Act
        final ids = List.generate(100, (_) => manager.generateId());

        // Assert
        final uniqueIds = ids.toSet();
        expect(uniqueIds.length, equals(100));
      });
    });

    group('createRequest', () {
      test('should create request with generated ID', () {
        // Act
        final request = manager.createRequest(
          method: 'textDocument/completion',
        );

        // Assert
        expect(request.id, isNotNull);
        expect(request.method, equals('textDocument/completion'));
        expect(request.jsonrpc, equals('2.0'));
      });

      test('should create request with params', () {
        // Arrange
        final params = {
          'uri': '/test/file.dart',
          'position': {'line': 10, 'character': 5},
        };

        // Act
        final request = manager.createRequest(
          method: 'textDocument/hover',
          params: params,
        );

        // Assert
        expect(request.params, equals(params));
      });

      test('should create multiple requests with unique IDs', () {
        // Act
        final request1 = manager.createRequest(method: 'method1');
        final request2 = manager.createRequest(method: 'method2');

        // Assert
        expect(request1.id, isNot(equals(request2.id)));
      });
    });

    group('waitForResponse', () {
      test('should complete when response is handled', () async {
        // Arrange
        const requestId = 'test-id';
        const response = JsonRpcResponse(
          id: requestId,
          result: {'value': 42},
        );

        // Act
        final responseFuture = manager.waitForResponse(requestId);
        manager.handleResponse(response);

        // Assert
        final receivedResponse = await responseFuture;
        expect(receivedResponse.id, equals(requestId));
        expect(receivedResponse.result?['value'], equals(42));
      });

      test('should timeout if response not received', () async {
        // Arrange
        const requestId = 'test-id';
        final shortTimeout = RequestManager(
          defaultTimeout: const Duration(milliseconds: 100),
        );

        // Act & Assert
        expect(
          () => shortTimeout.waitForResponse(requestId),
          throwsA(isA<TimeoutException>()),
        );

        await Future.delayed(const Duration(milliseconds: 150));
        shortTimeout.dispose();
      });

      test('should use custom timeout when provided', () async {
        // Arrange
        const requestId = 'test-id';

        // Act & Assert
        expect(
          () => manager.waitForResponse(
            requestId,
            timeout: const Duration(milliseconds: 50),
          ),
          throwsA(isA<TimeoutException>()),
        );

        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('should handle multiple pending requests', () async {
        // Arrange
        const id1 = 'request-1';
        const id2 = 'request-2';
        const response1 = JsonRpcResponse(id: id1, result: {'a': 1});
        const response2 = JsonRpcResponse(id: id2, result: {'b': 2});

        // Act
        final future1 = manager.waitForResponse(id1);
        final future2 = manager.waitForResponse(id2);

        manager.handleResponse(response1);
        manager.handleResponse(response2);

        // Assert
        final result1 = await future1;
        final result2 = await future2;

        expect(result1.result?['a'], equals(1));
        expect(result2.result?['b'], equals(2));
      });
    });

    group('handleResponse', () {
      test('should ignore response with unknown ID', () {
        // Arrange
        const response = JsonRpcResponse(
          id: 'unknown-id',
          result: {},
        );

        // Act & Assert
        // Should not throw
        manager.handleResponse(response);
      });

      test('should handle error responses', () async {
        // Arrange
        const requestId = 'test-id';
        const response = JsonRpcResponse(
          id: requestId,
          error: JsonRpcError(
            code: -32601,
            message: 'Method not found',
          ),
        );

        // Act
        final responseFuture = manager.waitForResponse(requestId);
        manager.handleResponse(response);

        // Assert
        final receivedResponse = await responseFuture;
        expect(receivedResponse.hasError, isTrue);
        expect(receivedResponse.error?.code, equals(-32601));
      });
    });

    group('cancelRequest', () {
      test('should cancel pending request', () async {
        // Arrange
        const requestId = 'test-id';
        manager.waitForResponse(requestId);

        // Act
        final cancelled = manager.cancelRequest(requestId);

        // Assert
        expect(cancelled, isTrue);
        expect(manager.hasPendingRequest(requestId), isFalse);
      });

      test('should return false when cancelling non-existent request', () {
        // Act
        final cancelled = manager.cancelRequest('non-existent');

        // Assert
        expect(cancelled, isFalse);
      });

      test('should prevent response from completing after cancellation',
          () async {
        // Arrange
        const requestId = 'test-id';
        const response = JsonRpcResponse(id: requestId, result: {});

        // Act
        manager.waitForResponse(requestId);
        manager.cancelRequest(requestId);
        manager.handleResponse(response);

        // Assert
        expect(manager.hasPendingRequest(requestId), isFalse);
      });
    });

    group('hasPendingRequest', () {
      test('should return true for pending request', () {
        // Arrange
        const requestId = 'test-id';
        manager.waitForResponse(requestId);

        // Act & Assert
        expect(manager.hasPendingRequest(requestId), isTrue);
      });

      test('should return false for completed request', () async {
        // Arrange
        const requestId = 'test-id';
        const response = JsonRpcResponse(id: requestId, result: {});

        // Act
        final future = manager.waitForResponse(requestId);
        manager.handleResponse(response);
        await future;

        // Assert
        expect(manager.hasPendingRequest(requestId), isFalse);
      });

      test('should return false for non-existent request', () {
        // Act & Assert
        expect(manager.hasPendingRequest('non-existent'), isFalse);
      });
    });

    group('pendingRequestCount', () {
      test('should return count of pending requests', () {
        // Arrange
        manager.waitForResponse('id1');
        manager.waitForResponse('id2');
        manager.waitForResponse('id3');

        // Act & Assert
        expect(manager.pendingRequestCount, equals(3));
      });

      test('should update count when requests complete', () async {
        // Arrange
        manager.waitForResponse('id1');
        final future = manager.waitForResponse('id2');
        expect(manager.pendingRequestCount, equals(2));

        // Act
        manager.handleResponse(const JsonRpcResponse(id: 'id2', result: {}));
        await future;

        // Assert
        expect(manager.pendingRequestCount, equals(1));
      });
    });

    group('dispose', () {
      test('should cancel all pending requests', () {
        // Arrange
        manager.waitForResponse('id1');
        manager.waitForResponse('id2');
        expect(manager.pendingRequestCount, equals(2));

        // Act
        manager.dispose();

        // Assert
        expect(manager.pendingRequestCount, equals(0));
      });

      test('should prevent new requests after disposal', () {
        // Act
        manager.dispose();

        // Assert
        expect(
          () => manager.waitForResponse('test-id'),
          throwsA(isA<StateError>()),
        );
      });
    });
  });
}
