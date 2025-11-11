import 'dart:async';

import 'package:flutter/foundation.dart';

/// Base class for all plugin messages
abstract class PluginMessage {
  /// The plugin ID that sent this message
  final String senderId;

  /// Optional target plugin ID (null for broadcast)
  final String? targetId;

  /// Message timestamp
  final DateTime timestamp;

  PluginMessage({required this.senderId, this.targetId, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

/// Request message that expects a response
abstract class PluginRequest<T> extends PluginMessage {
  PluginRequest({required super.senderId, super.targetId, super.timestamp});
}

/// Response to a plugin request
class PluginResponse<T> {
  final T? data;
  final String? error;
  final bool success;

  PluginResponse.success(this.data) : error = null, success = true;

  PluginResponse.error(this.error) : data = null, success = false;

  bool get isSuccess => success;
  bool get isError => !success;
}

/// Message handler
typedef MessageHandler<T extends PluginMessage> =
    FutureOr<void> Function(T message);

/// Request handler with response
typedef RequestHandler<TReq extends PluginRequest<TRes>, TRes> =
    FutureOr<PluginResponse<TRes>> Function(TReq request);

/// Registered message handler
class _MessageHandlerRegistration<T extends PluginMessage> {
  final String pluginId;
  final MessageHandler<T> handler;
  final bool Function(T)? filter;

  _MessageHandlerRegistration({
    required this.pluginId,
    required this.handler,
    this.filter,
  });

  bool shouldHandle(T message) {
    if (filter == null) return true;
    try {
      return filter!(message);
    } catch (_) {
      return false;
    }
  }
}

/// Bus for inter-plugin messaging
class PluginMessageBus {
  final Map<Type, List<_MessageHandlerRegistration>> _handlers = {};
  final Map<String, StreamController<PluginMessage>> _pluginStreams = {};
  final _messageStreamController = StreamController<PluginMessage>.broadcast();

  /// Stream of all messages
  Stream<PluginMessage> get messages => _messageStreamController.stream;

  /// Subscribe to messages of a specific type
  void subscribe<T extends PluginMessage>({
    required String pluginId,
    required MessageHandler<T> handler,
    bool Function(T)? filter,
  }) {
    final registration = _MessageHandlerRegistration<T>(
      pluginId: pluginId,
      handler: handler,
      filter: filter,
    );

    _handlers.putIfAbsent(T, () => []);
    _handlers[T]!.add(registration);
  }

  /// Unsubscribe all handlers for a plugin
  void unsubscribe(String pluginId) {
    for (final handlers in _handlers.values) {
      handlers.removeWhere((h) => h.pluginId == pluginId);
    }

    // Close and remove the plugin's stream controller to prevent memory leak
    final stream = _pluginStreams.remove(pluginId);
    stream?.close();
  }

  /// Publish a message to subscribers
  Future<void> publish(PluginMessage message) async {
    // Add to global stream
    _messageStreamController.add(message);

    // Add to plugin-specific stream if exists
    final pluginStream = _pluginStreams[message.senderId];
    pluginStream?.add(message);

    // Dispatch to handlers
    final handlers = _handlers[message.runtimeType];
    if (handlers == null || handlers.isEmpty) {
      return;
    }

    for (final registration in handlers) {
      // Check if message is targeted to specific plugin
      if (message.targetId != null &&
          registration.pluginId != message.targetId) {
        continue;
      }

      // Check if handler should process this message
      if (!registration.shouldHandle(message as dynamic)) {
        continue;
      }

      try {
        await registration.handler(message as dynamic);
      } catch (e, stackTrace) {
        debugPrint(
          '[PluginMessageBus] Error in handler "${registration.pluginId}": $e',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  /// Send a request and wait for response
  Future<PluginResponse<TRes>> request<TReq extends PluginRequest<TRes>, TRes>(
    TReq request, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final completer = Completer<PluginResponse<TRes>>();

    // Create a one-time handler for the response
    late StreamSubscription<PluginMessage> subscription;

    subscription = messages
        .where((msg) {
          return msg is PluginResponse &&
              msg.senderId == request.targetId &&
              msg.timestamp.isAfter(request.timestamp);
        })
        .listen((msg) {
          if (!completer.isCompleted) {
            completer.complete(msg as PluginResponse<TRes>);
            subscription.cancel();
          }
        });

    // Publish the request
    await publish(request);

    // Wait for response with timeout
    try {
      final response = await completer.future.timeout(
        timeout,
        onTimeout: () {
          subscription.cancel();
          return PluginResponse<TRes>.error(
            'Request timeout after ${timeout.inSeconds}s',
          );
        },
      );
      return response;
    } catch (e) {
      subscription.cancel();
      return PluginResponse<TRes>.error('Request failed: $e');
    }
  }

  /// Get a stream of messages for a specific plugin
  Stream<PluginMessage> getPluginStream(String pluginId) {
    if (!_pluginStreams.containsKey(pluginId)) {
      _pluginStreams[pluginId] = StreamController<PluginMessage>.broadcast();
    }
    return _pluginStreams[pluginId]!.stream;
  }

  /// Get statistics about the message bus
  MessageBusStatistics get statistics {
    final totalHandlers = _handlers.values.fold<int>(
      0,
      (sum, handlers) => sum + handlers.length,
    );

    final handlersByType = <Type, int>{};
    for (final entry in _handlers.entries) {
      handlersByType[entry.key] = entry.value.length;
    }

    return MessageBusStatistics(
      totalHandlers: totalHandlers,
      messageTypes: _handlers.keys.toList(),
      handlersByType: handlersByType,
      activePluginStreams: _pluginStreams.length,
    );
  }

  /// Clear all handlers and close streams
  void dispose() {
    _handlers.clear();
    for (final stream in _pluginStreams.values) {
      stream.close();
    }
    _pluginStreams.clear();
    _messageStreamController.close();
  }
}

/// Statistics about the message bus
class MessageBusStatistics {
  final int totalHandlers;
  final List<Type> messageTypes;
  final Map<Type, int> handlersByType;
  final int activePluginStreams;

  MessageBusStatistics({
    required this.totalHandlers,
    required this.messageTypes,
    required this.handlersByType,
    required this.activePluginStreams,
  });

  @override
  String toString() {
    return '''
MessageBusStatistics:
  Total Handlers: $totalHandlers
  Message Types: ${messageTypes.length}
  Active Plugin Streams: $activePluginStreams
''';
  }
}

// ==================== Common Message Types ====================

/// Request to get data from another plugin
class GetDataRequest<T> extends PluginRequest<T> {
  final String dataKey;
  final Map<String, dynamic>? parameters;

  GetDataRequest({
    required super.senderId,
    required super.targetId,
    required this.dataKey,
    this.parameters,
  });
}

/// Notification that a plugin's state changed
class PluginStateChangedMessage extends PluginMessage {
  final String state;
  final Map<String, dynamic>? data;

  PluginStateChangedMessage({
    required super.senderId,
    required this.state,
    this.data,
  });
}

/// Request to perform an action in another plugin
class ActionRequest<T> extends PluginRequest<T> {
  final String action;
  final Map<String, dynamic>? parameters;

  ActionRequest({
    required super.senderId,
    required super.targetId,
    required this.action,
    this.parameters,
  });
}

/// Broadcast message to all plugins
class BroadcastMessage extends PluginMessage {
  final String topic;
  final Map<String, dynamic>? payload;

  BroadcastMessage({required super.senderId, required this.topic, this.payload})
    : super(targetId: null);
}
