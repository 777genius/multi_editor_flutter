import 'package:freezed_annotation/freezed_annotation.dart';

part 'save_interval.freezed.dart';
part 'save_interval.g.dart';

@freezed
sealed class SaveInterval with _$SaveInterval {
  const SaveInterval._();

  const factory SaveInterval({required int seconds}) = _SaveInterval;

  factory SaveInterval.fromJson(Map<String, dynamic> json) =>
      _$SaveIntervalFromJson(json);

  factory SaveInterval.fromSeconds(int seconds) {
    if (seconds < 1 || seconds > 60) {
      throw ArgumentError('Save interval must be between 1 and 60 seconds');
    }
    return SaveInterval(seconds: seconds);
  }

  factory SaveInterval.defaultInterval() => const SaveInterval(seconds: 5);

  Duration get duration => Duration(seconds: seconds);

  bool get isValid => seconds >= 1 && seconds <= 60;

  String get displayText => '$seconds second${seconds == 1 ? '' : 's'}';
}
