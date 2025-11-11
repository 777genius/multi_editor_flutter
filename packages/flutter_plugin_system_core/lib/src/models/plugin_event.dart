import 'package:freezed_annotation/freezed_annotation.dart';

// ============================================================================
// ⚠️ IMPORTANT: REGENERATE AFTER CHANGES
// ============================================================================
// After modifying this file, run:
//   cd packages/flutter_plugin_system_core
//   flutter pub run build_runner build --delete-conflicting-outputs
//
// This will regenerate:
//   - plugin_event.freezed.dart (freezed code generation)
//   - plugin_event.g.dart (json_serializable code generation)
// ============================================================================

part 'plugin_event.freezed.dart';
part 'plugin_event.g.dart';

/// Plugin event
///
/// Universal event structure for plugin communication.
/// Events flow from host to plugin or between plugins.
///
/// ## Event Types
///
/// Common event types:
/// - `file.opened`: File was opened
/// - `file.saved`: File was saved
/// - `file.closed`: File was closed
/// - `editor.cursor_moved`: Cursor position changed
/// - `project.opened`: Project opened
///
/// ## Example
///
/// ```dart
/// final event = PluginEvent(
///   type: 'file.opened',
///   targetPluginId: 'plugin.file-icons',
///   data: {
///     'file_id': 'file123',
///     'filename': 'main.dart',
///     'path': '/project/lib/main.dart',
///   },
/// );
///
/// final response = await plugin.handleEvent(event);
/// ```
@freezed
class PluginEvent with _$PluginEvent {
  const factory PluginEvent({
    /// Event type (namespaced dot notation)
    ///
    /// Examples: 'file.opened', 'editor.selection_changed'
    required String type,

    /// Target plugin ID
    ///
    /// If null, this is a broadcast event sent to all plugins.
    /// If specified, event is sent to specific plugin only.
    String? targetPluginId,

    /// Event payload (custom data)
    @Default({}) Map<String, dynamic> data,

    /// Event timestamp (auto-generated if not provided)
    DateTime? timestamp,

    /// Source plugin ID (if event originates from another plugin)
    String? sourcePluginId,

    /// Event priority (higher = more important)
    @Default(0) int priority,

    /// Event ID (for tracking and correlation)
    String? eventId,
  }) = _PluginEvent;

  const PluginEvent._();

  factory PluginEvent.fromJson(Map<String, dynamic> json) =>
      _$PluginEventFromJson(json);

  /// Create event with current timestamp
  factory PluginEvent.now({
    required String type,
    String? targetPluginId,
    Map<String, dynamic> data = const {},
    String? sourcePluginId,
    int priority = 0,
    String? eventId,
  }) {
    return PluginEvent(
      type: type,
      targetPluginId: targetPluginId,
      data: data,
      timestamp: DateTime.now(),
      sourcePluginId: sourcePluginId,
      priority: priority,
      eventId: eventId,
    );
  }

  /// Get data field with type safety
  T? getData<T>(String key) {
    final value = data[key];
    return value is T ? value : null;
  }

  /// Get data field or default
  T getDataOr<T>(String key, T defaultValue) {
    return getData<T>(key) ?? defaultValue;
  }
}
