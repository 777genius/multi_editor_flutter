import 'package:freezed_annotation/freezed_annotation.dart';
import 'plugin_manifest.dart';

part 'plugin_config.freezed.dart';
part 'plugin_config.g.dart';

/// Plugin configuration
///
/// Runtime configuration for a plugin instance.
/// Combines manifest defaults with user overrides.
///
/// ## Example
///
/// ```dart
/// final config = PluginConfig(
///   settings: {
///     'theme': 'dark',
///     'cache_size': 100,
///   },
///   enabled: true,
/// );
/// ```
@freezed
class PluginConfig with _$PluginConfig {
  const factory PluginConfig({
    /// Plugin settings (key-value pairs)
    ///
    /// Keys should match the config schema defined in manifest.
    @Default({}) Map<String, dynamic> settings,

    /// Whether plugin is enabled
    @Default(true) bool enabled,

    /// Plugin load priority (lower = higher priority)
    ///
    /// Used for dependency resolution and initialization order.
    @Default(100) int priority,

    /// Auto-reload plugin on file change (development mode)
    @Default(false) bool autoReload,

    /// Additional metadata
    Map<String, dynamic>? metadata,
  }) = _PluginConfig;

  const PluginConfig._();

  factory PluginConfig.fromJson(Map<String, dynamic> json) =>
      _$PluginConfigFromJson(json);

  /// Create config from manifest defaults
  factory PluginConfig.fromManifest(PluginManifest manifest) {
    final settings = <String, dynamic>{};

    // Extract default values from config schema
    final schema = manifest.configSchema;
    if (schema != null && schema['properties'] is Map) {
      final properties = schema['properties'] as Map;
      properties.forEach((key, value) {
        if (value is Map && value.containsKey('default')) {
          settings[key.toString()] = value['default'];
        }
      });
    }

    return PluginConfig(settings: settings);
  }

  /// Get setting value with type safety
  T? getSetting<T>(String key) {
    final value = settings[key];
    return value is T ? value : null;
  }

  /// Get setting value or default
  T getSettingOr<T>(String key, T defaultValue) {
    return getSetting<T>(key) ?? defaultValue;
  }

  /// Update settings
  PluginConfig updateSettings(Map<String, dynamic> newSettings) {
    return copyWith(
      settings: {...settings, ...newSettings},
    );
  }
}
