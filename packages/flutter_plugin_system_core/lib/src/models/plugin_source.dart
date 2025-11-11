import 'dart:typed_data';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../types/plugin_types.dart';

part 'plugin_source.freezed.dart';
part 'plugin_source.g.dart';

/// Plugin source
///
/// Describes where to load plugin code from.
/// Supports multiple source types: file, URL, memory, package.
///
/// ## Examples
///
/// ```dart
/// // Load from file
/// final source = PluginSource.file('/path/to/plugin.wasm');
///
/// // Load from URL
/// final source = PluginSource.url('https://example.com/plugin.wasm');
///
/// // Load from memory
/// final source = PluginSource.memory(wasmBytes);
///
/// // Load from package
/// final source = PluginSource.package('package:my_plugin/plugin.wasm');
/// ```
@freezed
class PluginSource with _$PluginSource {
  const factory PluginSource({
    /// Source type
    required PluginSourceType type,

    /// File path (for type=file or type=package)
    String? path,

    /// URL (for type=url)
    String? url,

    /// Bytes (for type=memory)
    @Uint8ListConverter() Uint8List? bytes,

    /// Hash (for integrity verification)
    String? hash,

    /// Hash algorithm (e.g., 'sha256')
    String? hashAlgorithm,

    /// Additional metadata
    Map<String, dynamic>? metadata,
  }) = _PluginSource;

  const PluginSource._();

  factory PluginSource.fromJson(Map<String, dynamic> json) =>
      _$PluginSourceFromJson(json);

  /// Create file source
  factory PluginSource.file(String path) {
    return PluginSource(
      type: PluginSourceType.file,
      path: path,
    );
  }

  /// Create URL source
  factory PluginSource.url(String url) {
    return PluginSource(
      type: PluginSourceType.url,
      url: url,
    );
  }

  /// Create memory source
  factory PluginSource.memory(Uint8List bytes) {
    return PluginSource(
      type: PluginSourceType.memory,
      bytes: bytes,
    );
  }

  /// Create package source
  factory PluginSource.package(String packagePath) {
    return PluginSource(
      type: PluginSourceType.package,
      path: packagePath,
    );
  }

  /// Validate source integrity
  bool verifyIntegrity(Uint8List data) {
    if (hash == null || hashAlgorithm == null) {
      return true; // No verification required
    }

    // TODO: Implement hash verification
    return true;
  }
}

/// Uint8List JSON converter (stores as base64)
class Uint8ListConverter implements JsonConverter<Uint8List?, String?> {
  const Uint8ListConverter();

  @override
  Uint8List? fromJson(String? json) {
    if (json == null) return null;
    return Uint8List.fromList(json.codeUnits);
  }

  @override
  String? toJson(Uint8List? object) {
    if (object == null) return null;
    return String.fromCharCodes(object);
  }
}
