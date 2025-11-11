import 'dart:typed_data';
import 'package:msgpack_dart/msgpack_dart.dart' as msgpack;
import 'plugin_serializer.dart';

/// MessagePack plugin serializer
///
/// Binary serializer for production use with better performance than JSON.
///
/// ## Advantages
///
/// - ✅ Smaller payload size (~30-50% smaller than JSON)
/// - ✅ Faster serialization/deserialization
/// - ✅ Preserves types (integers, floats, binary data)
/// - ✅ Efficient for large data
///
/// ## Disadvantages
///
/// - ❌ Not human-readable (harder to debug)
/// - ❌ Requires MessagePack library on both sides
///
/// ## Example
///
/// ```dart
/// final serializer = MessagePackPluginSerializer();
///
/// final data = {
///   'type': 'file.opened',
///   'filename': 'main.dart',
///   'size': 1024,
///   'binary_data': Uint8List.fromList([1, 2, 3, 4]),
/// };
///
/// final bytes = serializer.serialize(data);
/// // bytes = MessagePack binary format (much smaller than JSON)
///
/// final result = serializer.deserialize(bytes);
/// // result preserves types including Uint8List
/// ```
class MessagePackPluginSerializer implements PluginSerializer {
  /// Create MessagePack serializer
  const MessagePackPluginSerializer();

  @override
  String get name => 'messagepack';

  @override
  Uint8List serialize(Map<String, dynamic> data) {
    try {
      final packed = msgpack.serialize(data);
      return Uint8List.fromList(packed);
    } catch (e) {
      throw SerializationException(
        'Failed to serialize data to MessagePack',
        originalError: e,
      );
    }
  }

  @override
  Map<String, dynamic> deserialize(Uint8List bytes) {
    try {
      final unpacked = msgpack.deserialize(bytes);

      if (unpacked is! Map) {
        throw SerializationException(
          'Deserialized MessagePack is not a Map',
        );
      }

      // Convert Map to Map<String, dynamic>
      return _convertMap(unpacked);
    } catch (e) {
      if (e is SerializationException) rethrow;
      throw SerializationException(
        'Failed to deserialize MessagePack data',
        originalError: e,
      );
    }
  }

  /// Convert msgpack Map to Map<String, dynamic>
  ///
  /// MessagePack deserializer may return Map with non-String keys,
  /// so we need to ensure all keys are Strings.
  Map<String, dynamic> _convertMap(Map map) {
    final result = <String, dynamic>{};

    for (final entry in map.entries) {
      final key = entry.key.toString();
      final value = entry.value;

      // Recursively convert nested maps
      if (value is Map) {
        result[key] = _convertMap(value);
      }
      // Convert lists with nested maps
      else if (value is List) {
        result[key] = _convertList(value);
      }
      // Keep other values as-is
      else {
        result[key] = value;
      }
    }

    return result;
  }

  /// Convert list with nested maps
  List<dynamic> _convertList(List list) {
    return list.map((item) {
      if (item is Map) {
        return _convertMap(item);
      } else if (item is List) {
        return _convertList(item);
      } else {
        return item;
      }
    }).toList();
  }
}

/// Hybrid plugin serializer
///
/// Uses different serializers based on configuration.
/// Useful for switching between development (JSON) and production (MessagePack).
///
/// ## Example
///
/// ```dart
/// final serializer = HybridPluginSerializer(
///   useMessagePack: !kDebugMode,
/// );
///
/// // In debug: uses JSON (easy debugging)
/// // In release: uses MessagePack (performance)
/// ```
class HybridPluginSerializer implements PluginSerializer {
  final PluginSerializer _serializer;

  /// Create hybrid serializer
  ///
  /// ## Parameters
  ///
  /// - `useMessagePack`: If true, uses MessagePack; otherwise uses JSON
  HybridPluginSerializer({bool useMessagePack = false})
      : _serializer = useMessagePack
            ? const MessagePackPluginSerializer()
            : const JsonPluginSerializer();

  @override
  String get name => _serializer.name;

  @override
  Uint8List serialize(Map<String, dynamic> data) {
    return _serializer.serialize(data);
  }

  @override
  Map<String, dynamic> deserialize(Uint8List bytes) {
    return _serializer.deserialize(bytes);
  }
}
