import 'package:freezed_annotation/freezed_annotation.dart';
import '../types/plugin_types.dart';

part 'plugin_manifest.freezed.dart';
part 'plugin_manifest.g.dart';

/// Plugin manifest
///
/// Describes a plugin's metadata, runtime requirements, permissions, and capabilities.
/// This is the primary descriptor that defines how a plugin integrates with the host system.
///
/// ## Example
///
/// ```dart
/// final manifest = PluginManifest(
///   id: 'plugin.file-icons',
///   name: 'File Icons',
///   version: '1.0.0',
///   description: 'Beautiful file icons',
///   runtime: PluginRuntimeType.wasm,
///   author: 'Editor Team',
/// );
/// ```
///
/// ## Manifest File (YAML)
///
/// ```yaml
/// id: plugin.file-icons
/// name: File Icons
/// version: 1.0.0
/// description: Beautiful colorful icons for 150+ file types
/// runtime: wasm
/// author: Editor Team
/// homepage: https://example.com
/// permissions:
///   host_functions:
///     - get_file_extension
///     - log_info
/// ```
@freezed
class PluginManifest with _$PluginManifest {
  const factory PluginManifest({
    /// Unique plugin identifier (reverse domain notation recommended)
    ///
    /// Example: `plugin.file-icons`, `com.example.my-plugin`
    required String id,

    /// Human-readable plugin name
    required String name,

    /// Semantic version (e.g., "1.0.0", "2.1.3-beta")
    required String version,

    /// Brief description of plugin functionality
    required String description,

    /// Runtime type that will execute this plugin
    required PluginRuntimeType runtime,

    /// Plugin author/organization
    String? author,

    /// Plugin homepage URL
    String? homepage,

    /// Plugin repository URL
    String? repository,

    /// License identifier (SPDX format recommended)
    ///
    /// Example: "MIT", "Apache-2.0", "GPL-3.0"
    String? license,

    /// List of plugin IDs this plugin depends on
    ///
    /// Dependencies must be loaded before this plugin.
    @Default([]) List<String> dependencies,

    /// Custom configuration schema (JSON Schema)
    Map<String, dynamic>? configSchema,

    /// Required host functions (permission system)
    ///
    /// Plugin can only call host functions listed here.
    @Default([]) List<String> requiredHostFunctions,

    /// Events this plugin can emit
    @Default([]) List<String> providedEvents,

    /// Events this plugin subscribes to
    @Default([]) List<String> subscribesTo,

    /// Minimum host system version required
    String? minHostVersion,

    /// Maximum host system version supported
    String? maxHostVersion,

    /// Additional metadata (custom fields)
    Map<String, dynamic>? metadata,
  }) = _PluginManifest;

  factory PluginManifest.fromJson(Map<String, dynamic> json) =>
      _$PluginManifestFromJson(json);
}

/// Plugin permissions
///
/// Defines what capabilities a plugin requires from the host system.
/// Used for security and sandboxing.
@freezed
class PluginPermissions with _$PluginPermissions {
  const factory PluginPermissions({
    /// Allowed host function names
    @Default([]) List<String> allowedHostFunctions,

    /// Maximum execution time per call
    @Default(Duration(seconds: 5)) Duration maxExecutionTime,

    /// Maximum memory allocation (bytes)
    @Default(52428800) int maxMemoryBytes, // 50 MB

    /// Maximum call stack depth
    @Default(100) int maxCallDepth,

    /// Network access permission
    @Default(false) bool canAccessNetwork,

    /// Filesystem access level
    @Default(FilesystemAccessLevel.none) FilesystemAccessLevel filesystemAccess,

    /// Custom resource limits
    Map<String, dynamic>? customLimits,
  }) = _PluginPermissions;

  factory PluginPermissions.fromJson(Map<String, dynamic> json) =>
      _$PluginPermissionsFromJson(json);
}

/// Filesystem access level
enum FilesystemAccessLevel {
  /// No filesystem access
  none,

  /// Read-only access
  readOnly,

  /// Read and write access
  readWrite,

  /// Full access (including delete)
  full,
}
