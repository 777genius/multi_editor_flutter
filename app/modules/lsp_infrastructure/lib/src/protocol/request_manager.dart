import 'dart:async';
import 'package:uuid/uuid.dart';
import 'json_rpc_protocol.dart';

/// Manages pending JSON-RPC requests and their responses.
///
/// This class is responsible for:
/// - Generating unique request IDs
/// - Tracking pending requests
/// - Matching responses to requests
/// - Handling timeouts
///
/// Follows SRP: One responsibility - manage request/response lifecycle.
///
/// Example:
/// ```dart
/// final manager = RequestManager();
///
/// // Create request
/// final request = manager.createRequest(
///   method: 'textDocument/completion',
///   params: {...},
/// );
///
/// // Wait for response
/// final response = await manager.waitForResponse(request.id);
/// ```
class RequestManager {
  final _uuid = const Uuid();

  /// Pending requests waiting for responses
  final Map<dynamic, Completer<JsonRpcResponse>> _pendingRequests = {};

  /// Timers for pending requests (for cancellation)
  final Map<dynamic, Timer> _requestTimers = {};

  /// Default timeout for requests
  final Duration _defaultTimeout;

  /// Request ID counter (for numeric IDs)
  int _requestIdCounter = 0;

  /// Whether to use string or numeric IDs
  final bool _useStringIds;

  RequestManager({
    Duration defaultTimeout = const Duration(seconds: 30),
    bool useStringIds = true,
  })  : _defaultTimeout = defaultTimeout,
        _useStringIds = useStringIds;

  /// Generates a unique request ID.
  ///
  /// Returns: String UUID or incremental integer
  dynamic generateId() {
    if (_useStringIds) {
      return _uuid.v4();
    } else {
      return ++_requestIdCounter;
    }
  }

  /// Creates a JSON-RPC request with a unique ID.
  ///
  /// Parameters:
  /// - [method]: LSP method name (e.g., 'textDocument/completion')
  /// - [params]: Method parameters
  ///
  /// Returns: JsonRpcRequest with unique ID
  JsonRpcRequest createRequest({
    required String method,
    Map<String, dynamic>? params,
  }) {
    final id = generateId();

    return JsonRpcRequest(
      id: id,
      method: method,
      params: params,
    );
  }

  /// Registers a pending request.
  ///
  /// This creates a Completer that will be completed when
  /// the response arrives.
  ///
  /// Parameters:
  /// - [id]: Request ID
  /// - [timeout]: Optional custom timeout
  ///
  /// Returns: Future that completes with the response
  Future<JsonRpcResponse> waitForResponse(
    dynamic id, {
    Duration? timeout,
  }) {
    final completer = Completer<JsonRpcResponse>();

    _pendingRequests[id] = completer;

    // Setup timeout
    final timeoutDuration = timeout ?? _defaultTimeout;
    final timer = Timer(timeoutDuration, () {
      if (!completer.isCompleted) {
        _pendingRequests.remove(id);
        _requestTimers.remove(id);
        completer.completeError(
          TimeoutException(
            'Request timed out after ${timeoutDuration.inSeconds}s',
            timeoutDuration,
          ),
        );
      }
    });

    // Store timer for cancellation
    _requestTimers[id] = timer;

    return completer.future;
  }

  /// Handles an incoming response.
  ///
  /// This method matches the response to a pending request
  /// and completes the corresponding Completer.
  ///
  /// Parameters:
  /// - [response]: The JSON-RPC response
  ///
  /// Returns: true if request was found and completed
  bool handleResponse(JsonRpcResponse response) {
    final completer = _pendingRequests.remove(response.id);
    final timer = _requestTimers.remove(response.id);

    // Cancel the timeout timer
    timer?.cancel();

    if (completer != null) {
      if (!completer.isCompleted) {
        completer.complete(response);
        return true;
      }
    }

    return false;
  }

  /// Cancels a pending request.
  ///
  /// Parameters:
  /// - [id]: Request ID to cancel
  ///
  /// Returns: true if request was found and cancelled
  bool cancelRequest(dynamic id) {
    final completer = _pendingRequests.remove(id);
    final timer = _requestTimers.remove(id);

    // Cancel the timeout timer
    timer?.cancel();

    if (completer != null && !completer.isCompleted) {
      completer.completeError(
        Exception('Request cancelled'),
      );
      return true;
    }

    return false;
  }

  /// Cancels all pending requests.
  ///
  /// Should be called when closing the connection.
  void cancelAllRequests() {
    // Cancel all timeout timers
    for (final timer in _requestTimers.values) {
      timer.cancel();
    }
    _requestTimers.clear();

    // Complete all pending requests with error
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(
          Exception('Connection closed'),
        );
      }
    }

    _pendingRequests.clear();
  }

  /// Gets the number of pending requests.
  ///
  /// Returns: Count of pending requests
  int get pendingCount => _pendingRequests.length;

  /// Checks if a request is pending.
  ///
  /// Parameters:
  /// - [id]: Request ID
  ///
  /// Returns: true if pending
  bool isPending(dynamic id) => _pendingRequests.containsKey(id);

  /// Gets all pending request IDs.
  ///
  /// Returns: List of pending IDs
  List<dynamic> getPendingIds() => _pendingRequests.keys.toList();

  /// Disposes the request manager.
  ///
  /// Cancels all pending requests.
  void dispose() {
    cancelAllRequests();
  }
}
