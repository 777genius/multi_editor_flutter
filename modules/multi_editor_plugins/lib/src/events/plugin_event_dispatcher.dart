import 'dart:async';

import 'package:multi_editor_core/multi_editor_core.dart';
import '../plugin_api/editor_plugin.dart';

/// Priority for event handlers
enum EventPriority {
  highest(0),
  high(1),
  normal(2),
  low(3),
  lowest(4);

  final int value;
  const EventPriority(this.value);
}

/// Wrapper for event with cancellation and propagation control
class PluginEventContext<T extends EditorEvent> {
  final T event;
  bool _cancelled = false;
  bool _propagationStopped = false;

  PluginEventContext(this.event);

  /// Cancel the event (prevent default behavior)
  void cancel() {
    _cancelled = true;
  }

  /// Stop propagation to lower-priority handlers
  void stopPropagation() {
    _propagationStopped = true;
  }

  bool get isCancelled => _cancelled;
  bool get isPropagationStopped => _propagationStopped;
}

/// Handler function for plugin events
typedef PluginEventHandler<T extends EditorEvent> =
    FutureOr<void> Function(PluginEventContext<T> context);

/// Registered event handler with metadata
class _EventHandlerRegistration<T extends EditorEvent> {
  final String pluginId;
  final Function handler; // Store as Function to avoid type issues with List
  final EventPriority priority;
  final bool Function(T)? filter;
  final Duration? throttle;
  final Duration? debounce;

  DateTime? _lastExecutionTime;
  Timer? _debounceTimer;

  _EventHandlerRegistration({
    required this.pluginId,
    required this.handler,
    required this.priority,
    this.filter,
    this.throttle,
    this.debounce,
  });

  bool shouldHandle(T event) {
    if (filter == null) return true;
    try {
      return filter!(event);
    } catch (_) {
      return false;
    }
  }

  /// Check if handler can execute based on throttle
  bool canExecuteThrottled() {
    if (throttle == null) return true;

    final now = DateTime.now();
    if (_lastExecutionTime == null) {
      return true;
    }

    final timeSinceLastExecution = now.difference(_lastExecutionTime!);
    return timeSinceLastExecution >= throttle!;
  }

  /// Update last execution time for throttling
  void markExecuted() {
    _lastExecutionTime = DateTime.now();
  }

  /// Dispose resources (timers)
  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }
}

/// Dispatches events to plugins with priority and filtering
class PluginEventDispatcher {
  final Map<Type, List<_EventHandlerRegistration>> _handlers = {};
  final Map<String, List<StreamSubscription>> _subscriptions = {};
  final EventBus _eventBus;

  PluginEventDispatcher(this._eventBus);

  /// Register a handler for a specific event type
  void registerHandler<T extends EditorEvent>({
    required String pluginId,
    required PluginEventHandler<T> handler,
    EventPriority priority = EventPriority.normal,
    bool Function(T)? filter,
    Duration? throttle,
    Duration? debounce,
  }) {
    // Validate: can't use both throttle and debounce
    assert(
      throttle == null || debounce == null,
      'Cannot use both throttle and debounce on the same handler',
    );

    final registration = _EventHandlerRegistration<T>(
      pluginId: pluginId,
      handler: handler,
      priority: priority,
      filter: filter,
      throttle: throttle,
      debounce: debounce,
    );

    _handlers.putIfAbsent(T, () => []);
    _handlers[T]!.add(registration);

    // Sort by priority after adding
    _handlers[T]!.sort((a, b) => a.priority.value.compareTo(b.priority.value));
  }

  /// Remove all handlers for a plugin
  void removeHandlers(String pluginId) {
    for (final handlers in _handlers.values) {
      // Dispose timers before removing
      handlers.where((h) => h.pluginId == pluginId).forEach((h) => h.dispose());
      handlers.removeWhere((h) => h.pluginId == pluginId);
    }
  }

  /// Dispatch an event to registered handlers
  Future<PluginEventContext<T>> dispatch<T extends EditorEvent>(T event) async {
    final context = PluginEventContext<T>(event);
    final handlers = _handlers[T];

    if (handlers == null || handlers.isEmpty) {
      return context;
    }

    for (final registration in handlers) {
      // Check if propagation was stopped
      if (context.isPropagationStopped) {
        break;
      }

      // Check if handler should process this event
      if (!registration.shouldHandle(event)) {
        continue;
      }

      try {
        // Handle debouncing
        if (registration.debounce != null) {
          _scheduleDebounced(registration, context);
          continue;
        }

        // Handle throttling
        if (registration.throttle != null) {
          if (!registration.canExecuteThrottled()) {
            continue; // Skip this event
          }
        }

        // Execute handler
        await (registration.handler as dynamic)(context);

        // Mark execution time for throttling
        if (registration.throttle != null) {
          registration.markExecuted();
        }
      } catch (e) {
        // Errors are handled by plugin manager's safe execute
        rethrow;
      }
    }

    return context;
  }

  /// Schedule debounced handler execution
  void _scheduleDebounced<T extends EditorEvent>(
    _EventHandlerRegistration<T> registration,
    PluginEventContext<T> context,
  ) {
    // Cancel existing timer
    registration._debounceTimer?.cancel();

    // Schedule new execution
    registration._debounceTimer = Timer(registration.debounce!, () async {
      try {
        await (registration.handler as dynamic)(context);
      } catch (e) {
        // Errors are handled by plugin manager's safe execute
        // In debounced case, we just ignore errors since we can't rethrow
      }
    });
  }

  /// Subscribe to EventBus events and dispatch to plugin handlers
  void subscribeToEventBus<T extends EditorEvent>() {
    final subscription = _eventBus.on<T>().listen((event) async {
      await dispatch<T>(event);
    });

    _subscriptions.putIfAbsent('_dispatcher', () => []);
    _subscriptions['_dispatcher']!.add(subscription);
  }

  /// Unsubscribe from all EventBus events
  Future<void> unsubscribeAll() async {
    for (final subs in _subscriptions.values) {
      for (final sub in subs) {
        await sub.cancel();
      }
    }
    _subscriptions.clear();
  }

  /// Get handlers for a specific event type (for debugging)
  List<String> getHandlersForEvent<T extends EditorEvent>() {
    final handlers = _handlers[T];
    if (handlers == null) return [];
    return handlers.map((h) => h.pluginId).toList();
  }

  /// Get all registered event types
  List<Type> getRegisteredEventTypes() {
    return _handlers.keys.toList();
  }

  /// Dispose event dispatcher and cleanup all resources
  ///
  /// Cancels all subscriptions and disposes all handlers.
  /// This method is async to ensure all subscriptions are properly cancelled.
  Future<void> dispose() async {
    // Dispose all handler timers
    for (final handlers in _handlers.values) {
      for (final handler in handlers) {
        handler.dispose();
      }
    }
    // Wait for all subscriptions to be cancelled to avoid memory leaks
    await unsubscribeAll();
    _handlers.clear();
  }
}

/// Extension methods for EditorPlugin to simplify event registration
extension PluginEventRegistration on EditorPlugin {
  /// Register a handler for file open events
  void onFileOpenEvent(
    PluginEventDispatcher dispatcher, {
    EventPriority priority = EventPriority.normal,
    bool Function(FileOpened)? filter,
  }) {
    dispatcher.registerHandler<FileOpened>(
      pluginId: manifest.id,
      priority: priority,
      filter: filter,
      handler: (context) => onFileOpen(context.event.file),
    );
  }

  /// Register a handler for file close events
  void onFileCloseEvent(
    PluginEventDispatcher dispatcher, {
    EventPriority priority = EventPriority.normal,
    bool Function(FileClosed)? filter,
  }) {
    dispatcher.registerHandler<FileClosed>(
      pluginId: manifest.id,
      priority: priority,
      filter: filter,
      handler: (context) => onFileClose(context.event.fileId),
    );
  }

  /// Register a handler for file save events
  void onFileSaveEvent(
    PluginEventDispatcher dispatcher, {
    EventPriority priority = EventPriority.normal,
    bool Function(FileSaved)? filter,
  }) {
    dispatcher.registerHandler<FileSaved>(
      pluginId: manifest.id,
      priority: priority,
      filter: filter,
      handler: (context) => onFileSave(context.event.file),
    );
  }

  /// Register a handler for file content change events
  void onFileContentChangeEvent(
    PluginEventDispatcher dispatcher, {
    EventPriority priority = EventPriority.normal,
    bool Function(FileContentChanged)? filter,
  }) {
    dispatcher.registerHandler<FileContentChanged>(
      pluginId: manifest.id,
      priority: priority,
      filter: filter,
      handler: (context) =>
          onFileContentChange(context.event.fileId, context.event.content),
    );
  }

  /// Register a handler for file create events
  void onFileCreateEvent(
    PluginEventDispatcher dispatcher, {
    EventPriority priority = EventPriority.normal,
    bool Function(FileCreated)? filter,
  }) {
    dispatcher.registerHandler<FileCreated>(
      pluginId: manifest.id,
      priority: priority,
      filter: filter,
      handler: (context) => onFileCreate(context.event.file),
    );
  }

  /// Register a handler for file delete events
  void onFileDeleteEvent(
    PluginEventDispatcher dispatcher, {
    EventPriority priority = EventPriority.normal,
    bool Function(FileDeleted)? filter,
  }) {
    dispatcher.registerHandler<FileDeleted>(
      pluginId: manifest.id,
      priority: priority,
      filter: filter,
      handler: (context) => onFileDelete(context.event.fileId),
    );
  }

  /// Register a handler for folder create events
  void onFolderCreateEvent(
    PluginEventDispatcher dispatcher, {
    EventPriority priority = EventPriority.normal,
    bool Function(FolderCreated)? filter,
  }) {
    dispatcher.registerHandler<FolderCreated>(
      pluginId: manifest.id,
      priority: priority,
      filter: filter,
      handler: (context) => onFolderCreate(context.event.folder),
    );
  }

  /// Register a handler for folder delete events
  void onFolderDeleteEvent(
    PluginEventDispatcher dispatcher, {
    EventPriority priority = EventPriority.normal,
    bool Function(FolderDeleted)? filter,
  }) {
    dispatcher.registerHandler<FolderDeleted>(
      pluginId: manifest.id,
      priority: priority,
      filter: filter,
      handler: (context) => onFolderDelete(context.event.folderId),
    );
  }
}
