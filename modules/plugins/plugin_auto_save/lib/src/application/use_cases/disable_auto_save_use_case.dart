import '../../domain/value_objects/auto_save_config.dart';

class DisableAutoSaveUseCase {
  Future<AutoSaveConfig> execute(AutoSaveConfig config) async {
    return config.disable();
  }
}
