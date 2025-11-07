import 'package:freezed_annotation/freezed_annotation.dart';

part 'plugin_error.freezed.dart';
part 'plugin_error.g.dart';

/// Types of errors that can occur in plugins
enum PluginErrorType {
  initialization,
  disposal,
  eventHandler,
  dependency,
  configuration,
  messaging,
  runtime,
}

/// Represents an error that occurred in a plugin
@freezed
sealed class PluginError with _$PluginError {
  const PluginError._();

  const factory PluginError({
    required String pluginId,
    required String pluginName,
    required PluginErrorType type,
    required String message,
    required DateTime timestamp,
    @JsonKey(includeFromJson: false, includeToJson: false)
    StackTrace? stackTrace,
    @Default({}) Map<String, dynamic> context,
  }) = _PluginError;

  factory PluginError.fromJson(Map<String, dynamic> json) =>
      _$PluginErrorFromJson(json);

  /// Create an initialization error
  factory PluginError.initialization({
    required String pluginId,
    required String pluginName,
    required Object error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) => PluginError(
    pluginId: pluginId,
    pluginName: pluginName,
    type: PluginErrorType.initialization,
    message: error.toString(),
    timestamp: DateTime.now(),
    stackTrace: stackTrace,
    context: context ?? {},
  );

  /// Create a disposal error
  factory PluginError.disposal({
    required String pluginId,
    required String pluginName,
    required Object error,
    StackTrace? stackTrace,
  }) => PluginError(
    pluginId: pluginId,
    pluginName: pluginName,
    type: PluginErrorType.disposal,
    message: error.toString(),
    timestamp: DateTime.now(),
    stackTrace: stackTrace,
  );

  /// Create an event handler error
  factory PluginError.eventHandler({
    required String pluginId,
    required String pluginName,
    required String eventType,
    required Object error,
    StackTrace? stackTrace,
  }) => PluginError(
    pluginId: pluginId,
    pluginName: pluginName,
    type: PluginErrorType.eventHandler,
    message: error.toString(),
    timestamp: DateTime.now(),
    stackTrace: stackTrace,
    context: {'eventType': eventType},
  );

  /// Create a runtime error
  factory PluginError.runtime({
    required String pluginId,
    required String pluginName,
    required String operation,
    required Object error,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalContext,
  }) => PluginError(
    pluginId: pluginId,
    pluginName: pluginName,
    type: PluginErrorType.runtime,
    message: error.toString(),
    timestamp: DateTime.now(),
    stackTrace: stackTrace,
    context: {'operation': operation, ...?additionalContext},
  );

  /// Get a user-friendly error message
  String get displayMessage {
    switch (type) {
      case PluginErrorType.initialization:
        return 'Failed to initialize plugin: $message';
      case PluginErrorType.disposal:
        return 'Error during plugin disposal: $message';
      case PluginErrorType.eventHandler:
        final eventType = context['eventType'] ?? 'unknown';
        return 'Error in $eventType event handler: $message';
      case PluginErrorType.dependency:
        return 'Dependency error: $message';
      case PluginErrorType.configuration:
        return 'Configuration error: $message';
      case PluginErrorType.messaging:
        return 'Messaging error: $message';
      case PluginErrorType.runtime:
        final operation = context['operation'] ?? 'unknown operation';
        return 'Error during $operation: $message';
    }
  }

  /// Check if this error is critical (should auto-disable plugin)
  bool get isCritical {
    return type == PluginErrorType.initialization ||
        type == PluginErrorType.dependency;
  }
}
