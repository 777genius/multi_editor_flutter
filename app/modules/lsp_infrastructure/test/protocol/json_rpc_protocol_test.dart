import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_infrastructure/lsp_infrastructure.dart';

void main() {
  group('JsonRpcRequest', () {
    test('should create request with required fields', () {
      // Act
      const request = JsonRpcRequest(
        id: 1,
        method: 'textDocument/completion',
      );

      // Assert
      expect(request.jsonrpc, equals('2.0'));
      expect(request.id, equals(1));
      expect(request.method, equals('textDocument/completion'));
      expect(request.params, isNull);
    });

    test('should create request with params', () {
      // Arrange
      final params = {'uri': '/test/file.dart', 'position': {'line': 10, 'character': 5}};

      // Act
      final request = JsonRpcRequest(
        id: 1,
        method: 'textDocument/hover',
        params: params,
      );

      // Assert
      expect(request.params, equals(params));
    });

    test('should support string ID', () {
      // Act
      const request = JsonRpcRequest(
        id: 'request-uuid-123',
        method: 'initialize',
      );

      // Assert
      expect(request.id, equals('request-uuid-123'));
      expect(request.id, isA<String>());
    });

    test('should support integer ID', () {
      // Act
      const request = JsonRpcRequest(
        id: 42,
        method: 'shutdown',
      );

      // Assert
      expect(request.id, equals(42));
      expect(request.id, isA<int>());
    });

    test('should serialize to JSON', () {
      // Arrange
      const request = JsonRpcRequest(
        id: 1,
        method: 'textDocument/definition',
        params: {'uri': '/test.dart'},
      );

      // Act
      final json = request.toJson();

      // Assert
      expect(json['jsonrpc'], equals('2.0'));
      expect(json['id'], equals(1));
      expect(json['method'], equals('textDocument/definition'));
      expect(json['params'], isNotNull);
    });

    test('should deserialize from JSON', () {
      // Arrange
      final json = {
        'jsonrpc': '2.0',
        'id': 5,
        'method': 'textDocument/references',
        'params': {'includeDeclaration': true},
      };

      // Act
      final request = JsonRpcRequest.fromJson(json);

      // Assert
      expect(request.id, equals(5));
      expect(request.method, equals('textDocument/references'));
      expect(request.params?['includeDeclaration'], isTrue);
    });
  });

  group('JsonRpcResponse', () {
    test('should create successful response', () {
      // Arrange
      final result = {'completions': []};

      // Act
      final response = JsonRpcResponse(
        id: 1,
        result: result,
      );

      // Assert
      expect(response.jsonrpc, equals('2.0'));
      expect(response.id, equals(1));
      expect(response.result, equals(result));
      expect(response.error, isNull);
      expect(response.isSuccess, isTrue);
      expect(response.hasError, isFalse);
    });

    test('should create error response', () {
      // Arrange
      const error = JsonRpcError(
        code: -32601,
        message: 'Method not found',
      );

      // Act
      const response = JsonRpcResponse(
        id: 1,
        error: error,
      );

      // Assert
      expect(response.error, equals(error));
      expect(response.result, isNull);
      expect(response.isSuccess, isFalse);
      expect(response.hasError, isTrue);
    });

    test('should serialize to JSON', () {
      // Arrange
      const response = JsonRpcResponse(
        id: 1,
        result: {'value': 42},
      );

      // Act
      final json = response.toJson();

      // Assert
      expect(json['jsonrpc'], equals('2.0'));
      expect(json['id'], equals(1));
      expect(json['result'], isNotNull);
    });

    test('should deserialize successful response from JSON', () {
      // Arrange
      final json = {
        'jsonrpc': '2.0',
        'id': 10,
        'result': {'locations': []},
      };

      // Act
      final response = JsonRpcResponse.fromJson(json);

      // Assert
      expect(response.id, equals(10));
      expect(response.result, isNotNull);
      expect(response.isSuccess, isTrue);
    });

    test('should deserialize error response from JSON', () {
      // Arrange
      final json = {
        'jsonrpc': '2.0',
        'id': 10,
        'error': {
          'code': -32600,
          'message': 'Invalid Request',
        },
      };

      // Act
      final response = JsonRpcResponse.fromJson(json);

      // Assert
      expect(response.id, equals(10));
      expect(response.error, isNotNull);
      expect(response.error?.code, equals(-32600));
      expect(response.hasError, isTrue);
    });
  });

  group('JsonRpcError', () {
    test('should create error with code and message', () {
      // Act
      const error = JsonRpcError(
        code: -32700,
        message: 'Parse error',
      );

      // Assert
      expect(error.code, equals(-32700));
      expect(error.message, equals('Parse error'));
      expect(error.data, isNull);
    });

    test('should create error with additional data', () {
      // Act
      const error = JsonRpcError(
        code: -32602,
        message: 'Invalid params',
        data: {'expected': 'object', 'got': 'string'},
      );

      // Assert
      expect(error.data, isNotNull);
      expect(error.data['expected'], equals('object'));
    });

    test('should serialize to JSON', () {
      // Arrange
      const error = JsonRpcError(
        code: -32603,
        message: 'Internal error',
      );

      // Act
      final json = error.toJson();

      // Assert
      expect(json['code'], equals(-32603));
      expect(json['message'], equals('Internal error'));
    });

    test('should deserialize from JSON', () {
      // Arrange
      final json = {
        'code': -32601,
        'message': 'Method not found',
        'data': 'textDocument/unknownMethod',
      };

      // Act
      final error = JsonRpcError.fromJson(json);

      // Assert
      expect(error.code, equals(-32601));
      expect(error.message, equals('Method not found'));
      expect(error.data, equals('textDocument/unknownMethod'));
    });
  });

  group('JsonRpcNotification', () {
    test('should create notification', () {
      // Act
      const notification = JsonRpcNotification(
        method: 'textDocument/didOpen',
      );

      // Assert
      expect(notification.jsonrpc, equals('2.0'));
      expect(notification.method, equals('textDocument/didOpen'));
      expect(notification.params, isNull);
    });

    test('should create notification with params', () {
      // Arrange
      final params = {'uri': '/test.dart', 'text': 'content'};

      // Act
      final notification = JsonRpcNotification(
        method: 'textDocument/didChange',
        params: params,
      );

      // Assert
      expect(notification.params, equals(params));
    });

    test('should serialize to JSON', () {
      // Arrange
      const notification = JsonRpcNotification(
        method: 'textDocument/didClose',
        params: {'uri': '/test.dart'},
      );

      // Act
      final json = notification.toJson();

      // Assert
      expect(json['jsonrpc'], equals('2.0'));
      expect(json['method'], equals('textDocument/didClose'));
      expect(json['params'], isNotNull);
      expect(json.containsKey('id'), isFalse);
    });

    test('should deserialize from JSON', () {
      // Arrange
      final json = {
        'jsonrpc': '2.0',
        'method': 'textDocument/didSave',
        'params': {'uri': '/test.dart'},
      };

      // Act
      final notification = JsonRpcNotification.fromJson(json);

      // Assert
      expect(notification.method, equals('textDocument/didSave'));
      expect(notification.params?['uri'], equals('/test.dart'));
    });
  });

  group('roundtrip serialization', () {
    test('request should roundtrip correctly', () {
      // Arrange
      const original = JsonRpcRequest(
        id: 123,
        method: 'test/method',
        params: {'key': 'value'},
      );

      // Act
      final json = original.toJson();
      final deserialized = JsonRpcRequest.fromJson(json);

      // Assert
      expect(deserialized.id, equals(original.id));
      expect(deserialized.method, equals(original.method));
      expect(deserialized.params, equals(original.params));
    });

    test('response should roundtrip correctly', () {
      // Arrange
      const original = JsonRpcResponse(
        id: 456,
        result: {'data': 'test'},
      );

      // Act
      final json = original.toJson();
      final deserialized = JsonRpcResponse.fromJson(json);

      // Assert
      expect(deserialized.id, equals(original.id));
      expect(deserialized.result, equals(original.result));
    });

    test('notification should roundtrip correctly', () {
      // Arrange
      const original = JsonRpcNotification(
        method: 'test/notification',
        params: {'value': 42},
      );

      // Act
      final json = original.toJson();
      final deserialized = JsonRpcNotification.fromJson(json);

      // Assert
      expect(deserialized.method, equals(original.method));
      expect(deserialized.params, equals(original.params));
    });
  });
}
