library plugin_auto_save;

export 'src/domain/value_objects/save_interval.dart';
export 'src/domain/value_objects/auto_save_config.dart';
export 'src/domain/entities/save_task.dart';

export 'src/application/use_cases/enable_auto_save_use_case.dart';
export 'src/application/use_cases/disable_auto_save_use_case.dart';
export 'src/application/use_cases/configure_interval_use_case.dart';
export 'src/application/use_cases/trigger_save_use_case.dart';

export 'src/infrastructure/plugin/auto_save_plugin.dart';
