import '../../domain/value_objects/auto_save_config.dart';

class EnableAutoSaveUseCase {
  Future<AutoSaveConfig> execute(AutoSaveConfig config) async {
    return config.enable();
  }
}
