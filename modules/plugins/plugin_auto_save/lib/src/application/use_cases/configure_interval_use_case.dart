import '../../domain/value_objects/auto_save_config.dart';
import '../../domain/value_objects/save_interval.dart';

class ConfigureIntervalUseCase {
  Future<AutoSaveConfig> execute(
    AutoSaveConfig config,
    SaveInterval interval,
  ) async {
    if (!interval.isValid) {
      throw ArgumentError('Invalid save interval');
    }

    return config.withInterval(interval);
  }
}
