/// VS Code Runtime Management - Domain Layer (Core)
library vscode_runtime_core;

// Domain Exceptions
export 'src/domain/exceptions/domain_exception.dart';

// Enums
export 'src/domain/enums/module_type.dart';
export 'src/domain/enums/installation_status.dart';
export 'src/domain/enums/installation_trigger.dart';

// Value Objects
export 'src/domain/value_objects/runtime_version.dart';
export 'src/domain/value_objects/byte_size.dart';
export 'src/domain/value_objects/sha256_hash.dart';
export 'src/domain/value_objects/module_id.dart';
export 'src/domain/value_objects/download_url.dart';
export 'src/domain/value_objects/platform_identifier.dart';
export 'src/domain/value_objects/installation_id.dart';

// Entities
export 'src/domain/entities/platform_artifact.dart';
export 'src/domain/entities/runtime_module.dart';
export 'src/domain/entities/runtime_manifest.dart';

// Aggregate Roots
export 'src/domain/aggregates/runtime_installation.dart';

// Domain Events
export 'src/domain/events/domain_event.dart';

// Specifications
export 'src/domain/specifications/specification.dart';
export 'src/domain/specifications/platform_compatible_spec.dart';
export 'src/domain/specifications/dependencies_met_spec.dart';
export 'src/domain/specifications/module_installable_spec.dart';

// Domain Services
export 'src/domain/services/i_dependency_resolver.dart';
export 'src/domain/services/dependency_resolver.dart';

// Port Interfaces - Repositories
export 'src/ports/repositories/i_runtime_repository.dart';
export 'src/ports/repositories/i_manifest_repository.dart';

// Port Interfaces - Services
export 'src/ports/services/i_download_service.dart';
export 'src/ports/services/i_extraction_service.dart';
export 'src/ports/services/i_verification_service.dart';
export 'src/ports/services/i_platform_service.dart';
export 'src/ports/services/i_file_system_service.dart';

// Port Interfaces - Events
export 'src/ports/events/i_event_bus.dart';
