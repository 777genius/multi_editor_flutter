/// VS Code Runtime Management - Application Layer
library vscode_runtime_application;

// Exceptions
export 'src/exceptions/application_exception.dart';

// Base CQRS
export 'src/base/command.dart';
export 'src/base/query.dart';
export 'src/base/command_handler.dart';
export 'src/base/query_handler.dart';

// Commands
export 'src/commands/install_runtime_command.dart';
export 'src/commands/cancel_installation_command.dart';
export 'src/commands/uninstall_runtime_command.dart';
export 'src/commands/check_runtime_updates_command.dart';

// Command Handlers
export 'src/handlers/install_runtime_command_handler.dart';
export 'src/handlers/cancel_installation_command_handler.dart';
export 'src/handlers/uninstall_runtime_command_handler.dart';
export 'src/handlers/check_runtime_updates_command_handler.dart';

// Queries
export 'src/queries/get_runtime_status_query.dart';
export 'src/queries/get_installation_progress_query.dart';
export 'src/queries/get_available_modules_query.dart';
export 'src/queries/get_platform_info_query.dart';

// Query Handlers
export 'src/handlers/get_runtime_status_query_handler.dart';
export 'src/handlers/get_installation_progress_query_handler.dart';
export 'src/handlers/get_available_modules_query_handler.dart';
export 'src/handlers/get_platform_info_query_handler.dart';

// DTOs
export 'src/dtos/runtime_status_dto.dart';
export 'src/dtos/installation_progress_dto.dart';
export 'src/dtos/module_info_dto.dart';
export 'src/dtos/platform_info_dto.dart';

// Dependency Injection
export 'src/di/injection.dart';
