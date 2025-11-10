import 'package:freezed_annotation/freezed_annotation.dart';

part 'plugin_response.freezed.dart';
part 'plugin_response.g.dart';

/// Plugin response
///
/// Standard response structure from plugin event handlers.
///
/// ## Example
///
/// ```dart
/// // Success response
/// return PluginResponse.success(
///   data: {
///     'icon_url': 'https://cdn.example.com/dart.svg',
///     'cached': true,
///   },
/// );
///
/// // Error response
/// return PluginResponse.error(
///   message: 'Failed to resolve icon',
///   error: exception.toString(),
/// );
/// ```
@freezed
class PluginResponse with _$PluginResponse {
  const factory PluginResponse({
    /// Whether the operation succeeded
    required bool success,

    /// Response data (on success)
    @Default({}) Map<String, dynamic> data,

    /// Error message (on failure)
    String? message,

    /// Error details (on failure)
    String? error,

    /// Error stack trace (on failure)
    String? stackTrace,

    /// Response timestamp
    DateTime? timestamp,

    /// Processing duration (milliseconds)
    int? durationMs,

    /// Additional metadata
    Map<String, dynamic>? metadata,
  }) = _PluginResponse;

  const PluginResponse._();

  factory PluginResponse.fromJson(Map<String, dynamic> json) =>
      _$PluginResponseFromJson(json);

  /// Create success response
  factory PluginResponse.success({
    Map<String, dynamic> data = const {},
    int? durationMs,
    Map<String, dynamic>? metadata,
  }) {
    return PluginResponse(
      success: true,
      data: data,
      timestamp: DateTime.now(),
      durationMs: durationMs,
      metadata: metadata,
    );
  }

  /// Create error response
  factory PluginResponse.error({
    required String message,
    String? error,
    String? stackTrace,
    int? durationMs,
    Map<String, dynamic>? metadata,
  }) {
    return PluginResponse(
      success: false,
      message: message,
      error: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
      durationMs: durationMs,
      metadata: metadata,
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

  /// Check if response has error details
  bool get hasError => error != null || stackTrace != null;
}
