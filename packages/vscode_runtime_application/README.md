# VS Code Runtime Application Layer

Application layer package implementing use cases and orchestration logic.

## Overview

This package implements the Application Layer following CQRS (Command Query Responsibility Segregation) pattern:

- **Commands**: Write operations that change state
- **Queries**: Read operations that return data
- **Command Handlers**: Execute commands with business logic
- **Query Handlers**: Execute queries and return DTOs
- **DTOs**: Data Transfer Objects for cross-layer communication

## Architecture

### CQRS Pattern

```
Commands (Write)              Queries (Read)
     ↓                              ↓
Command Handlers            Query Handlers
     ↓                              ↓
Domain Layer                 Domain Layer
     ↓                              ↓
Infrastructure              Infrastructure
```

## Commands

### InstallRuntimeCommand
Installs the VS Code runtime with all dependencies.

**Parameters:**
- `moduleIds`: List of modules to install (empty = all critical modules)
- `trigger`: What initiated the installation
- `onProgress`: Progress callback
- `cancelToken`: Cancellation support

### CancelInstallationCommand
Cancels an ongoing installation.

**Parameters:**
- `installationId`: Installation to cancel
- `reason`: Cancellation reason

### UninstallRuntimeCommand
Removes runtime modules from the system.

**Parameters:**
- `moduleIds`: Modules to uninstall (empty = everything)
- `keepDownloads`: Whether to keep downloaded files

### CheckRuntimeUpdatesCommand
Checks for available runtime updates.

**Parameters:**
- `forceCheck`: Force check even if recently checked

## Queries

### GetRuntimeStatusQuery
Returns current runtime installation status.

**Returns:** `RuntimeStatusDto`
- notInstalled
- installed
- partiallyInstalled
- installing
- failed
- updateAvailable

### GetInstallationProgressQuery
Returns detailed progress for an installation.

**Parameters:**
- `installationId`: Installation to query

**Returns:** `InstallationProgressDto`

### GetAvailableModulesQuery
Returns list of available modules.

**Parameters:**
- `includeOptional`: Include optional modules
- `platformOnly`: Only platform-compatible modules

**Returns:** `List<ModuleInfoDto>`

### GetPlatformInfoQuery
Returns information about current platform.

**Returns:** `PlatformInfoDto`

## DTOs

### RuntimeStatusDto
Current runtime status with variants:
- `notInstalled()`
- `installed(version, installedAt, installedModules)`
- `partiallyInstalled(version, installedModules, missingModules)`
- `installing(installationId, progress, currentModule)`
- `failed(error, failedModule)`
- `updateAvailable(currentVersion, availableVersion)`

### InstallationProgressDto
Detailed installation progress:
- Overall progress (0.0-1.0)
- Current module
- Installed/remaining modules
- Status and error messages

### ModuleInfoDto
Module metadata:
- ID, name, description
- Type and version
- Platform support
- Dependencies
- Installation status
- Size for current platform

### PlatformInfoDto
Platform information:
- OS and architecture
- System resources
- Disk space
- Permissions
- Support status

## Usage Example

```dart
import 'package:vscode_runtime_application/vscode_runtime_application.dart';

// Initialize dependency injection
await configureDependencies();

// Get handler from DI
final installHandler = getIt<InstallRuntimeCommandHandler>();

// Create command
final command = InstallRuntimeCommand(
  moduleIds: [], // Install all critical modules
  trigger: InstallationTrigger.settings,
  onProgress: (moduleId, progress) {
    print('${moduleId.value}: ${(progress * 100).toStringAsFixed(1)}%');
  },
);

// Execute command
final result = await installHandler.handle(command);

result.fold(
  (error) => print('Installation failed: ${error.message}'),
  (_) => print('Installation completed successfully!'),
);

// Query status
final statusHandler = getIt<GetRuntimeStatusQueryHandler>();
final statusQuery = GetRuntimeStatusQuery();

final statusResult = await statusHandler.handle(statusQuery);

statusResult.fold(
  (error) => print('Query failed: ${error.message}'),
  (status) {
    status.map(
      notInstalled: (_) => print('Runtime not installed'),
      installed: (s) => print('Runtime v${s.version} installed'),
      // ... other variants
    );
  },
);
```

## Error Handling

All handlers return `Either<ApplicationException, TResult>`:

**Left (Error):**
- `ApplicationException` - General application error
- `NotFoundException` - Resource not found
- `InvalidOperationException` - Operation not allowed
- `OperationCancelledException` - User cancelled
- `NetworkException` - Network operation failed
- `FileSystemException` - File system operation failed
- `ValidationException` - Validation errors

**Right (Success):**
- Command results: `Unit` (void)
- Query results: DTOs

## Dependencies

- `vscode_runtime_core` - Domain layer
- `vscode_runtime_infrastructure` - Infrastructure layer
- `dartz` - Functional programming (Either, Option)
- `freezed` - Immutable data classes
- `injectable` - Dependency injection
- `get_it` - Service locator

## Testing

All handlers should be tested with:
- Success scenarios
- Error scenarios
- Edge cases
- Cancellation (where applicable)

Example:

```dart
test('InstallRuntimeCommand succeeds for valid modules', () async {
  // Arrange
  final mockRepository = MockRuntimeRepository();
  final mockManifest = MockManifestRepository();
  // ... setup mocks

  final handler = InstallRuntimeCommandHandler(
    mockRepository,
    mockManifest,
    // ... other dependencies
  );

  final command = InstallRuntimeCommand(moduleIds: []);

  // Act
  final result = await handler.handle(command);

  // Assert
  expect(result.isRight(), isTrue);
  verify(() => mockRepository.saveInstallation(any())).called(greaterThan(0));
});
```

## Code Generation

Run code generation for freezed classes:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Dependency Injection Setup

```dart
// In main app
import 'package:vscode_runtime_application/vscode_runtime_application.dart';
import 'package:vscode_runtime_infrastructure/vscode_runtime_infrastructure.dart';

void main() async {
  // Register infrastructure implementations
  getIt.registerLazySingleton<IFileSystemService>(
    () => FileSystemService(),
  );
  getIt.registerLazySingleton<IPlatformService>(
    () => PlatformService(),
  );
  // ... register all services

  // Configure application layer DI
  await configureDependencies();

  runApp(MyApp());
}
```
