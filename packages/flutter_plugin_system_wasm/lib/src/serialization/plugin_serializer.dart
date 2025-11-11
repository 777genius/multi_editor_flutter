import 'dart:convert';
import 'dart:typed_data';

/// Plugin serializer interface
///
/// Provides serialization/deserialization for data exchange between
/// Dart (host) and WASM (plugin).
///
/// ## Implementations
///
/// - **JsonPluginSerializer**: JSON-based (development, easy debugging)
/// - **MessagePackPluginSerializer**: MessagePack-based (production, performance)
///
/// ## Example
///
/// ```dart
/// final serializer = config.isDebug
///     ? JsonPluginSerializer()
///     : MessagePackPluginSerializer();
///
/// // Serialize
/// final data = {'filename': 'main.dart', 'line': 42};
/// final bytes = serializer.serialize(data);
///
/// // Deserialize
/// final result = serializer.deserialize(bytes);
/// ```
abstract class PluginSerializer {
  /// Serialize data to bytes
  ///
  /// Converts a Dart map to bytes for transfer to WASM.
  ///
  /// ## Parameters
  ///
  /// - `data`: Data to serialize
  ///
  /// ## Returns
  ///
  /// Serialized bytes
  ///
  /// ## Throws
  ///
  /// - [SerializationException] if serialization fails
  Uint8List serialize(Map<String, dynamic> data);

  /// Deserialize bytes to data
  ///
  /// Converts bytes from WASM to a Dart map.
  ///
  /// ## Parameters
  ///
  /// - `bytes`: Serialized bytes
  ///
  /// ## Returns
  ///
  /// Deserialized data
  ///
  /// ## Throws
  ///
  /// - [SerializationException] if deserialization fails
  Map<String, dynamic> deserialize(Uint8List bytes);

  /// Get serializer name
  ///
  /// Returns the name of this serializer implementation.
  String get name;
}

/// Serialization exception
///
/// Thrown when serialization or deserialization fails.
class SerializationException implements Exception {
  final String message;
  final Object? originalError;

  const SerializationException(this.message, {this.originalError});

  @override
  String toString() {
    if (originalError != null) {
      return 'SerializationException: $message\nCaused by: $originalError';
    }
    return 'SerializationException: $message';
  }
}

/// JSON plugin serializer
///
/// JSON-based serializer for development and debugging.
///
/// ## Advantages
///
/// - ✅ Easy to debug (human-readable)
/// - ✅ Wide compatibility
/// - ✅ Simple implementation
///
/// ## Disadvantages
///
/// - ❌ Larger payload size
/// - ❌ Slower than binary formats
///
/// ## Example
///
/// ```dart
/// final serializer = JsonPluginSerializer();
///
/// final data = {'type': 'file.opened', 'filename': 'main.dart'};
/// final bytes = serializer.serialize(data);
/// // bytes = UTF-8 encoded JSON: {"type":"file.opened","filename":"main.dart"}
///
/// final result = serializer.deserialize(bytes);
/// // result = {'type': 'file.opened', 'filename': 'main.dart'}
/// ```
class JsonPluginSerializer implements PluginSerializer {
  /// Create JSON serializer
  const JsonPluginSerializer();

  @override
  String get name => 'json';

  @override
  Uint8List serialize(Map<String, dynamic> data) {
    try {
      final json = jsonEncode(data);
      return Uint8List.fromList(utf8.encode(json));
    } catch (e) {
      throw SerializationException(
        'Failed to serialize data to JSON',
        originalError: e,
      );
    }
  }

  @override
  Map<String, dynamic> deserialize(Uint8List bytes) {
    try {
      final json = utf8.decode(bytes);
      final result = jsonDecode(json);

      if (result is! Map<String, dynamic>) {
        throw SerializationException(
          'Deserialized JSON is not a Map<String, dynamic>',
        );
      }

      return result;
    } catch (e) {
      if (e is SerializationException) rethrow;
      throw SerializationException(
        'Failed to deserialize JSON data',
        originalError: e,
      );
    }
  }
}
