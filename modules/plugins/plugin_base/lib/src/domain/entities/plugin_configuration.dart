import 'package:freezed_annotation/freezed_annotation.dart';
import '../value_objects/plugin_id.dart';

part 'plugin_configuration.freezed.dart';
part 'plugin_configuration.g.dart';

@freezed
sealed class PluginConfiguration with _$PluginConfiguration {
  const PluginConfiguration._();

  const factory PluginConfiguration({
    required PluginId pluginId,
    required bool enabled,
    @Default({}) Map<String, dynamic> settings,
    DateTime? lastModified,
  }) = _PluginConfiguration;

  factory PluginConfiguration.fromJson(Map<String, dynamic> json) =>
      _$PluginConfigurationFromJson(json);

  factory PluginConfiguration.create(PluginId pluginId) {
    return PluginConfiguration(
      pluginId: pluginId,
      enabled: true,
      settings: {},
      lastModified: DateTime.now(),
    );
  }

  PluginConfiguration enable() {
    return copyWith(enabled: true, lastModified: DateTime.now());
  }

  PluginConfiguration disable() {
    return copyWith(enabled: false, lastModified: DateTime.now());
  }

  PluginConfiguration updateSetting(String key, dynamic value) {
    final newSettings = Map<String, dynamic>.from(settings);
    newSettings[key] = value;
    return copyWith(settings: newSettings, lastModified: DateTime.now());
  }

  PluginConfiguration removeSetting(String key) {
    final newSettings = Map<String, dynamic>.from(settings);
    newSettings.remove(key);
    return copyWith(settings: newSettings, lastModified: DateTime.now());
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    final value = settings[key];
    if (value is T) {
      return value;
    }
    return defaultValue;
  }

  bool hasSetting(String key) => settings.containsKey(key);
}
