# VS Code Runtime Presentation Layer

Presentation layer package with MobX state management and UI widgets.

## Overview

This package implements the Presentation Layer with:

- **MobX Stores**: Reactive state management
- **UI Widgets**: Reusable Flutter widgets
- **Installation UI**: Complete installation flow
- **Status Display**: Runtime status and platform info

## MobX Stores

### RuntimeInstallationStore
Manages installation state and progress.

**Observables:**
- `status`: Current installation status
- `overallProgress`: Overall progress (0.0-1.0)
- `currentModule`: Module being installed
- `currentModuleProgress`: Current module progress
- `errorMessage`: Error if failed

**Computed:**
- `isInstalling`: Whether currently installing
- `isCompleted`: Whether completed
- `hasFailed`: Whether failed
- `canCancel`: Can be cancelled
- `progressText`: Progress as percentage string
- `statusMessage`: Human-readable status

**Actions:**
- `install()`: Start installation
- `cancel()`: Cancel installation
- `reset()`: Reset state
- `loadProgress()`: Load existing installation progress

### RuntimeStatusStore
Manages runtime status and updates.

**Observables:**
- `status`: Current runtime status
- `isLoading`: Whether loading
- `errorMessage`: Error message
- `lastChecked`: Last status check time

**Computed:**
- `isInstalled`: Runtime is installed
- `needsInstallation`: Installation needed
- `isInstalling`: Currently installing
- `statusMessage`: Human-readable status

**Actions:**
- `loadStatus()`: Load current status
- `checkForUpdates()`: Check for updates
- `refresh()`: Refresh status

### ModuleListStore
Manages available modules and selection.

**Observables:**
- `modules`: Available modules
- `selectedModules`: Selected module IDs
- `platformInfo`: Platform information
- `showOnlyCompatible`: Filter flag
- `showOptional`: Filter flag

**Computed:**
- `criticalModules`: Non-optional modules
- `optionalModules`: Optional modules
- `installedModules`: Already installed
- `notInstalledModules`: Not installed
- `selectedSize`: Total size of selection
- `selectedCount`: Number selected

**Actions:**
- `loadModules()`: Load available modules
- `loadPlatformInfo()`: Load platform info
- `toggleModule()`: Toggle module selection
- `selectAllCritical()`: Select all critical modules
- `clearSelection()`: Clear selection
- `initialize()`: Initialize store

## UI Widgets

### RuntimeInstallationDialog
Full-featured installation dialog.

**Features:**
- Module selection with filters
- Installation progress tracking
- Error handling
- Cancellation support

**Usage:**
```dart
final result = await RuntimeInstallationDialog.show(
  context,
  installationStore: getIt<RuntimeInstallationStore>(),
  moduleListStore: getIt<ModuleListStore>(),
  trigger: InstallationTrigger.settings,
);

if (result == true) {
  print('Installation completed!');
}
```

### InstallationProgressWidget
Shows detailed installation progress.

**Displays:**
- Overall progress bar
- Current module progress
- Module count
- Status messages
- Success/error states

### ModuleListWidget
Selectable module list with metadata.

**Features:**
- Checkboxes for selection
- Module metadata (type, size, dependencies)
- Installed/not installed indication
- Quick select/deselect actions
- Filters for optional modules

### RuntimeStatusWidget
Status display with action buttons.

**Displays:**
- Not installed
- Installed (with version)
- Partially installed
- Installing (with progress)
- Failed (with error)
- Update available

**Actions:**
- Install button
- Update button
- Retry button
- Check for updates

### PlatformInfoWidget
Platform information and compatibility.

**Shows:**
- Platform name and architecture
- OS version
- Number of processors
- Available disk space
- Compatibility status
- Installation warnings

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:vscode_runtime_presentation/vscode_runtime_presentation.dart';
import 'package:vscode_runtime_application/vscode_runtime_application.dart';

class RuntimeSettingsPage extends StatefulWidget {
  @override
  State<RuntimeSettingsPage> createState() => _RuntimeSettingsPageState();
}

class _RuntimeSettingsPageState extends State<RuntimeSettingsPage> {
  late final RuntimeStatusStore _statusStore;
  late final RuntimeInstallationStore _installationStore;
  late final ModuleListStore _moduleListStore;

  @override
  void initState() {
    super.initState();

    // Get stores from DI
    _statusStore = getIt<RuntimeStatusStore>();
    _installationStore = getIt<RuntimeInstallationStore>();
    _moduleListStore = getIt<ModuleListStore>();

    // Load initial status
    _statusStore.loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VS Code Runtime'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status widget
            RuntimeStatusWidget(
              store: _statusStore,
              onInstallRequested: _showInstallDialog,
              onUpdateRequested: _showInstallDialog,
            ),

            const SizedBox(height: 16),

            // Platform info
            Observer(
              builder: (_) {
                if (_moduleListStore.platformInfo != null) {
                  return PlatformInfoWidget(
                    platformInfo: _moduleListStore.platformInfo!,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showInstallDialog() async {
    final result = await RuntimeInstallationDialog.show(
      context,
      installationStore: _installationStore,
      moduleListStore: _moduleListStore,
      trigger: InstallationTrigger.settings,
    );

    if (result == true) {
      // Refresh status after successful installation
      await _statusStore.loadStatus();
    }
  }
}
```

## Code Generation

Run code generation for MobX:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Dependencies

- `flutter` - Flutter SDK
- `vscode_runtime_application` - Application layer
- `vscode_runtime_core` - Domain layer
- `mobx` - Reactive state management
- `flutter_mobx` - Flutter integration for MobX
- `injectable` - Dependency injection
- `get_it` - Service locator

## Testing

Test stores with:

```dart
test('RuntimeInstallationStore starts installation', () async {
  // Arrange
  final mockHandler = MockInstallRuntimeCommandHandler();
  when(() => mockHandler.handle(any())).thenAnswer(
    (_) async => right(unit),
  );

  final store = RuntimeInstallationStore(
    mockHandler,
    mockCancelHandler,
    mockProgressHandler,
  );

  // Act
  await store.install();

  // Assert
  expect(store.isCompleted, isTrue);
  expect(store.overallProgress, 1.0);
});
```

## Dependency Injection Setup

```dart
import 'package:vscode_runtime_presentation/vscode_runtime_presentation.dart';
import 'package:vscode_runtime_application/vscode_runtime_application.dart';

void main() async {
  // Configure all layers
  await configureDependencies(); // Application layer
  await configureDependencies(); // Presentation layer

  runApp(MyApp());
}
```

## Architecture

```
Presentation Layer (MobX Stores + Widgets)
           ↓
Application Layer (Commands + Queries)
           ↓
Domain Layer (Business Logic)
           ↓
Infrastructure Layer (Services + Repositories)
```

## Key Features

✅ Reactive state management with MobX
✅ Complete installation flow UI
✅ Progress tracking with cancellation
✅ Module selection with filters
✅ Platform compatibility checking
✅ Error handling and retry logic
✅ Update checking
✅ Clean separation of concerns
✅ Dependency injection ready
✅ Fully testable
