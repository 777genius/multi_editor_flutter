import 'package:freezed_annotation/freezed_annotation.dart';
import 'save_interval.dart';

part 'auto_save_config.freezed.dart';
part 'auto_save_config.g.dart';

@freezed
sealed class AutoSaveConfig with _$AutoSaveConfig {
  const AutoSaveConfig._();

  const factory AutoSaveConfig({
    required bool enabled,
    required SaveInterval interval,
    @Default(false) bool onlyWhenIdle,
    @Default(true) bool showNotifications,
  }) = _AutoSaveConfig;

  factory AutoSaveConfig.fromJson(Map<String, dynamic> json) =>
      _$AutoSaveConfigFromJson(json);

  factory AutoSaveConfig.defaultConfig() => AutoSaveConfig(
    enabled: true,
    interval: SaveInterval.defaultInterval(),
    onlyWhenIdle: false,
    showNotifications: true,
  );

  AutoSaveConfig withInterval(SaveInterval newInterval) {
    return copyWith(interval: newInterval);
  }

  AutoSaveConfig enable() => copyWith(enabled: true);

  AutoSaveConfig disable() => copyWith(enabled: false);
}
