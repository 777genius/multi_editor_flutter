import 'dart:async';
import 'package:flutter_plugin_system_core/flutter_plugin_system_core.dart';
import 'package:rxdart/rxdart.dart';

/// Event dispatcher
///
/// Pub/Sub system for plugin events. Allows plugins and host to publish and subscribe to events.
/// Uses RxDart for reactive streams with buffering and filtering.
///
/// ## Design Principles
///
/// - **Pub/Sub Pattern**: Loose coupling between publishers and subscribers
/// - **Type Safety**: Strongly typed events
/// - **Filtering**: Subscribe to specific event types or all events
/// - **Buffering**: Replay recent events for late subscribers
///
/// ## Example
///
/// ```dart
/// final dispatcher = EventDispatcher();
///
/// // Subscribe to all events
/// final subscription = dispatcher.stream.listen((event) {
///   print('Event: ${event.type}');
/// });
///
/// // Subscribe to specific event type
/// dispatcher.streamFor('file.opened').listen((event) {
///   print('File opened: ${event.data['filename']}');
/// });
///
/// // Dispatch event
/// dispatcher.dispatch(PluginEvent(
///   type: 'file.opened',
///   targetPluginId: 'plugin.file-icons',
///   data: {'filename': 'main.dart'},
/// ));
///
/// // Cleanup
/// subscription.cancel();
/// dispatcher.dispose();
/// ```
class EventDispatcher {
  /// Event stream controller (BehaviorSubject for replay)
  late final BehaviorSubject<PluginEvent> _controller;

  /// Replay buffer size
  final int replayBufferSize;

  /// Event statistics
  final Map<String, int> _eventCounts = {};

  /// Total dispatched events
  int _totalDispatched = 0;

  /// Create event dispatcher
  ///
  /// ## Parameters
  ///
  /// - `replayBufferSize`: Number of recent events to replay for new subscribers (default: 10)
  EventDispatcher({
    this.replayBufferSize = 10,
  }) {
    _controller = BehaviorSubject<PluginEvent>(
      onListen: _onListen,
      onCancel: _onCancel,
    );
  }

  /// Event stream
  ///
  /// Stream of all dispatched events.
  /// New subscribers receive recent events (up to replayBufferSize).
  Stream<PluginEvent> get stream => _controller.stream;

  /// Stream for specific event type
  ///
  /// Filters events by type.
  ///
  /// ## Parameters
  ///
  /// - `eventType`: Event type to filter (e.g., 'file.opened')
  ///
  /// ## Returns
  ///
  /// Stream of events matching the type
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Listen to file events only
  /// dispatcher.streamFor('file.opened').listen((event) {
  ///   print('File opened: ${event.data['filename']}');
  /// });
  /// ```
  Stream<PluginEvent> streamFor(String eventType) {
    return _controller.stream.where((event) => event.type == eventType);
  }

  /// Stream for multiple event types
  ///
  /// Filters events by multiple types.
  ///
  /// ## Parameters
  ///
  /// - `eventTypes`: Event types to filter
  ///
  /// ## Returns
  ///
  /// Stream of events matching any of the types
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Listen to file and editor events
  /// dispatcher.streamForAny(['file.opened', 'file.closed', 'editor.changed'])
  ///   .listen((event) {
  ///     print('Event: ${event.type}');
  ///   });
  /// ```
  Stream<PluginEvent> streamForAny(List<String> eventTypes) {
    final Set<String> types = eventTypes.toSet();
    return _controller.stream.where((event) => types.contains(event.type));
  }

  /// Stream for event type pattern
  ///
  /// Filters events by type pattern (supports wildcards).
  ///
  /// ## Parameters
  ///
  /// - `pattern`: Pattern to match (e.g., 'file.*' matches 'file.opened', 'file.closed')
  ///
  /// ## Returns
  ///
  /// Stream of events matching the pattern
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Listen to all file events
  /// dispatcher.streamForPattern('file.*').listen((event) {
  ///   print('File event: ${event.type}');
  /// });
  ///
  /// // Listen to all LSP events
  /// dispatcher.streamForPattern('lsp.*').listen((event) {
  ///   print('LSP event: ${event.type}');
  /// });
  /// ```
  Stream<PluginEvent> streamForPattern(String pattern) {
    final regex = RegExp('^${pattern.replaceAll('*', '.*')}\$');
    return _controller.stream.where((event) => regex.hasMatch(event.type));
  }

  /// Dispatch event
  ///
  /// Publishes event to all subscribers.
  ///
  /// ## Parameters
  ///
  /// - `event`: Event to dispatch
  ///
  /// ## Example
  ///
  /// ```dart
  /// dispatcher.dispatch(PluginEvent(
  ///   type: 'file.opened',
  ///   targetPluginId: 'all',
  ///   data: {'filename': 'main.dart'},
  /// ));
  /// ```
  void dispatch(PluginEvent event) {
    if (_controller.isClosed) {
      throw StateError('EventDispatcher is disposed');
    }

    // Add to stream
    _controller.add(event);

    // Update statistics
    _eventCounts[event.type] = (_eventCounts[event.type] ?? 0) + 1;
    _totalDispatched++;
  }

  /// Dispatch multiple events
  ///
  /// Batch publishes multiple events.
  ///
  /// ## Parameters
  ///
  /// - `events`: Events to dispatch
  void dispatchAll(List<PluginEvent> events) {
    for (final event in events) {
      dispatch(event);
    }
  }

  /// Get event count for type
  ///
  /// ## Parameters
  ///
  /// - `eventType`: Event type
  ///
  /// ## Returns
  ///
  /// Number of times this event type was dispatched
  int getEventCount(String eventType) {
    return _eventCounts[eventType] ?? 0;
  }

  /// Get all event counts
  ///
  /// ## Returns
  ///
  /// Map of event type → count
  Map<String, int> getAllEventCounts() {
    return Map.from(_eventCounts);
  }

  /// Reset event count for type
  ///
  /// ## Parameters
  ///
  /// - `eventType`: Event type
  void resetEventCount(String eventType) {
    _eventCounts[eventType] = 0;
  }

  /// Reset all event counts
  void resetAllEventCounts() {
    _eventCounts.clear();
    _totalDispatched = 0;
  }

  /// Get total dispatched events
  int get totalDispatched => _totalDispatched;

  /// Check if has active subscribers
  bool get hasListeners => _controller.hasListener;

  /// Get number of active subscribers
  int get listenerCount => _controller.hasListener ? 1 : 0;

  /// Get statistics
  ///
  /// ## Returns
  ///
  /// Map with dispatcher statistics:
  /// - `total_dispatched`: Total events dispatched
  /// - `unique_types`: Number of unique event types
  /// - `has_listeners`: Whether there are active subscribers
  /// - `most_common`: Most frequently dispatched event type
  Map<String, dynamic> getStatistics() {
    String? mostCommon;
    int maxCount = 0;
    for (final entry in _eventCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostCommon = entry.key;
      }
    }

    return {
      'total_dispatched': _totalDispatched,
      'unique_types': _eventCounts.length,
      'has_listeners': hasListeners,
      if (mostCommon != null) 'most_common': mostCommon,
      if (mostCommon != null) 'most_common_count': maxCount,
    };
  }

  /// Called when first listener subscribes
  void _onListen() {
    // Can be used for logging or metrics
  }

  /// Called when last listener unsubscribes
  void _onCancel() {
    // Can be used for logging or metrics
  }

  /// Dispose dispatcher
  ///
  /// Closes the stream and releases resources.
  /// After disposing, no more events can be dispatched.
  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  String toString() {
    final stats = getStatistics();
    return 'EventDispatcher(${stats['total_dispatched']} events, ${stats['unique_types']} types)';
  }
}
