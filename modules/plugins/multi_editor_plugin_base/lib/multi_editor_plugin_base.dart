
export 'src/domain/ports/plugin_storage_port.dart';
export 'src/domain/ports/plugin_preferences_port.dart';
export 'src/domain/value_objects/plugin_id.dart';
export 'src/domain/entities/plugin_configuration.dart';
export 'src/domain/entities/plugin_state.dart';

export 'src/application/base/base_editor_plugin.dart';
export 'src/application/mixins/configurable_plugin.dart';
export 'src/application/mixins/stateful_plugin.dart';
export 'src/application/use_cases/load_plugin_config_use_case.dart';
export 'src/application/use_cases/save_plugin_config_use_case.dart';

export 'src/infrastructure/adapters/shared_preferences_storage_adapter.dart';
export 'src/infrastructure/adapters/in_memory_storage_adapter.dart';
