import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';
import '../value_objects/installation_id.dart';
import '../value_objects/module_id.dart';
import '../value_objects/platform_identifier.dart';
import '../entities/runtime_module.dart';
import '../enums/installation_status.dart';
import '../enums/installation_trigger.dart';
import '../events/domain_event.dart';
import '../exceptions/domain_exception.dart';

part 'runtime_installation.freezed.dart';

/// Aggregate Root: Runtime Installation
/// Manages installation lifecycle and ensures consistency
/// All state changes emit domain events
@freezed
class RuntimeInstallation with _$RuntimeInstallation {
  const RuntimeInstallation._();

  const factory RuntimeInstallation({
    required InstallationId id,
    required List<RuntimeModule> modules,
    required PlatformIdentifier targetPlatform,
    required InstallationStatus status,
    required DateTime createdAt,
    required InstallationTrigger trigger,
    @Default([]) List<ModuleId> installedModules,
    @Default([]) List<DomainEvent> uncommittedEvents,
    ModuleId? currentModule,
    @Default(0.0) double progress,
    String? errorMessage,
    DateTime? completedAt,
    DateTime? failedAt,
  }) = _RuntimeInstallation;

  /// Factory: Create new installation
  factory RuntimeInstallation.create({
    required List<RuntimeModule> modules,
    required PlatformIdentifier platform,
    InstallationTrigger trigger = InstallationTrigger.settings,
  }) {
    final id = InstallationId.generate();
    final now = DateTime.now();

    // Validate: all modules compatible with platform
    final incompatibleModules = modules
        .where((m) => !m.isAvailableForPlatform(platform))
        .map((m) => m.id.value)
        .toList();

    if (incompatibleModules.isNotEmpty) {
      throw ValidationException(
        'Modules not compatible with platform $platform: '
        '${incompatibleModules.join(', ')}',
      );
    }

    // Validate: no circular dependencies (basic check)
    _validateDependencies(modules);

    return RuntimeInstallation(
      id: id,
      modules: modules,
      targetPlatform: platform,
      status: InstallationStatus.pending,
      createdAt: now,
      trigger: trigger,
      uncommittedEvents: [
        InstallationStarted(
          installationId: id,
          moduleCount: modules.length,
          timestamp: now,
        ),
      ],
    );
  }

  /// Command: Start installation
  RuntimeInstallation start() {
    if (!status.canStart) {
      throw InvalidStateException(
        'Cannot start installation in state: ${status.displayName}',
      );
    }

    return copyWith(
      status: InstallationStatus.inProgress,
      uncommittedEvents: [
        ...uncommittedEvents,
        InstallationProgressChanged(
          installationId: id,
          status: InstallationStatus.inProgress,
          timestamp: DateTime.now(),
          progress: 0.0,
        ),
      ],
    );
  }

  /// Command: Mark module download started
  RuntimeInstallation markModuleDownloadStarted(ModuleId moduleId) {
    _validateModuleExists(moduleId);
    _validateModuleNotInstalled(moduleId);
    _validateIsInProgress();

    return copyWith(
      currentModule: moduleId,
      uncommittedEvents: [
        ...uncommittedEvents,
        ModuleDownloadStarted(
          installationId: id,
          moduleId: moduleId,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  /// Command: Mark module as downloaded
  RuntimeInstallation markModuleDownloaded(ModuleId moduleId) {
    _validateModuleExists(moduleId);
    _validateModuleNotInstalled(moduleId);
    _validateIsInProgress();

    return copyWith(
      currentModule: moduleId,
      uncommittedEvents: [
        ...uncommittedEvents,
        ModuleDownloaded(
          installationId: id,
          moduleId: moduleId,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  /// Command: Mark module as verified
  RuntimeInstallation markModuleVerified(ModuleId moduleId) {
    _validateModuleExists(moduleId);
    _validateIsInProgress();

    return copyWith(
      uncommittedEvents: [
        ...uncommittedEvents,
        ModuleVerified(
          installationId: id,
          moduleId: moduleId,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  /// Command: Mark module extraction started
  RuntimeInstallation markModuleExtractionStarted(ModuleId moduleId) {
    _validateModuleExists(moduleId);
    _validateIsInProgress();

    return copyWith(
      uncommittedEvents: [
        ...uncommittedEvents,
        ModuleExtractionStarted(
          installationId: id,
          moduleId: moduleId,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  /// Command: Mark module as extracted/installed
  RuntimeInstallation markModuleInstalled(ModuleId moduleId) {
    _validateModuleExists(moduleId);
    _validateModuleNotInstalled(moduleId);
    _validateIsInProgress();

    final newInstalledModules = [...installedModules, moduleId];
    final isComplete = newInstalledModules.length == modules.length;
    final newStatus = isComplete
        ? InstallationStatus.completed
        : InstallationStatus.inProgress;

    final newProgress = modules.isEmpty
        ? 1.0
        : newInstalledModules.length / modules.length;

    final events = [
      ...uncommittedEvents,
      ModuleExtracted(
        installationId: id,
        moduleId: moduleId,
        timestamp: DateTime.now(),
      ),
    ];

    if (isComplete) {
      events.add(
        InstallationCompleted(
          installationId: id,
          timestamp: DateTime.now(),
        ),
      );
    }

    return copyWith(
      installedModules: newInstalledModules,
      status: newStatus,
      progress: newProgress,
      currentModule: null,
      uncommittedEvents: events,
      completedAt: isComplete ? DateTime.now() : null,
    );
  }

  /// Command: Start module installation
  RuntimeInstallation startModule(ModuleId moduleId) {
    _validateModuleExists(moduleId);
    _validateModuleNotInstalled(moduleId);
    _validateIsInProgress();

    return copyWith(
      currentModule: moduleId,
      uncommittedEvents: [
        ...uncommittedEvents,
        ModuleDownloadStarted(
          installationId: id,
          moduleId: moduleId,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  /// Command: Complete module installation
  RuntimeInstallation completeModule(ModuleId moduleId) {
    _validateModuleExists(moduleId);
    _validateModuleNotInstalled(moduleId);
    _validateIsInProgress();

    final newInstalledModules = [...installedModules, moduleId];
    final isComplete = newInstalledModules.length == modules.length;
    final newStatus = isComplete
        ? InstallationStatus.completed
        : InstallationStatus.inProgress;

    final newProgress = modules.isEmpty
        ? 1.0
        : newInstalledModules.length / modules.length;

    final events = [
      ...uncommittedEvents,
      ModuleExtracted(
        installationId: id,
        moduleId: moduleId,
        timestamp: DateTime.now(),
      ),
    ];

    if (isComplete) {
      events.add(
        InstallationCompleted(
          installationId: id,
          timestamp: DateTime.now(),
        ),
      );
    }

    return copyWith(
      installedModules: newInstalledModules,
      status: newStatus,
      progress: newProgress,
      currentModule: null,
      uncommittedEvents: events,
      completedAt: isComplete ? DateTime.now() : null,
    );
  }

  /// Command: Update progress for specific module
  RuntimeInstallation updateProgress(ModuleId moduleId, double newProgress) {
    _validateModuleExists(moduleId);
    _validateIsInProgress();

    if (newProgress < 0.0 || newProgress > 1.0) {
      throw ValidationException('Progress must be between 0.0 and 1.0');
    }

    return copyWith(
      currentModule: moduleId,
      progress: newProgress,
      uncommittedEvents: [
        ...uncommittedEvents,
        InstallationProgressChanged(
          installationId: id,
          status: status,
          timestamp: DateTime.now(),
          progress: newProgress,
        ),
      ],
    );
  }

  /// Command: Fail installation
  RuntimeInstallation fail(String error, {ModuleId? failedModule}) {
    if (status.isTerminal && status != InstallationStatus.inProgress) {
      throw InvalidStateException(
        'Cannot fail installation in terminal state: ${status.displayName}',
      );
    }

    return copyWith(
      status: InstallationStatus.failed,
      errorMessage: error,
      failedAt: DateTime.now(),
      uncommittedEvents: [
        ...uncommittedEvents,
        InstallationFailed(
          installationId: id,
          error: error,
          timestamp: DateTime.now(),
          failedModuleId: failedModule?.value,
        ),
      ],
    );
  }

  /// Command: Cancel installation
  RuntimeInstallation cancel({String? reason}) {
    if (!status.canCancel) {
      throw InvalidStateException(
        'Cannot cancel installation in state: ${status.displayName}',
      );
    }

    return copyWith(
      status: InstallationStatus.cancelled,
      uncommittedEvents: [
        ...uncommittedEvents,
        InstallationCancelled(
          installationId: id,
          timestamp: DateTime.now(),
          reason: reason,
        ),
      ],
    );
  }

  /// Query: Get next module to install
  Option<RuntimeModule> getNextModuleToInstall() {
    if (status != InstallationStatus.inProgress) {
      return none();
    }

    final notInstalled = modules
        .where((m) => !installedModules.contains(m.id))
        .toList();

    if (notInstalled.isEmpty) return none();

    // Find module whose dependencies are all installed
    for (final module in notInstalled) {
      if (_areDependenciesMet(module)) {
        return some(module);
      }
    }

    // Should never happen if dependency graph is valid
    throw const DependencyException('Circular dependency or unresolvable dependencies');
  }

  /// Query: Calculate overall progress
  double calculateProgress() {
    if (modules.isEmpty) return 1.0;
    return installedModules.length / modules.length;
  }

  /// Query: Get remaining modules
  List<RuntimeModule> getRemainingModules() {
    return modules
        .where((m) => !installedModules.contains(m.id))
        .toList();
  }

  /// Query: Get installed module objects
  List<RuntimeModule> getInstalledModuleObjects() {
    return modules
        .where((m) => installedModules.contains(m.id))
        .toList();
  }

  /// Query: Check if module is installed
  bool isModuleInstalled(ModuleId moduleId) {
    return installedModules.contains(moduleId);
  }

  /// Query: Get duration
  Duration? getDuration() {
    final endTime = completedAt ?? failedAt ?? DateTime.now();
    return endTime.difference(createdAt);
  }

  /// Clear uncommitted events (after publishing)
  RuntimeInstallation clearEvents() {
    return copyWith(uncommittedEvents: []);
  }

  // Private validation helpers

  void _validateModuleExists(ModuleId moduleId) {
    if (!modules.any((m) => m.id == moduleId)) {
      throw NotFoundException('Module not found: ${moduleId.value}');
    }
  }

  void _validateModuleNotInstalled(ModuleId moduleId) {
    if (installedModules.contains(moduleId)) {
      throw InvalidStateException('Module already installed: ${moduleId.value}');
    }
  }

  void _validateIsInProgress() {
    if (status != InstallationStatus.inProgress) {
      throw InvalidStateException(
        'Installation is not in progress (current: ${status.displayName})',
      );
    }
  }

  bool _areDependenciesMet(RuntimeModule module) {
    return module.dependencies.every(
      (dep) => installedModules.contains(dep),
    );
  }

  static void _validateDependencies(List<RuntimeModule> modules) {
    final moduleMap = {for (var m in modules) m.id: m};
    final visited = <ModuleId>{};

    for (final module in modules) {
      if (_hasCircularDependency(module, moduleMap, visited, {})) {
        throw const DependencyException('Circular dependency detected');
      }
    }
  }

  static bool _hasCircularDependency(
    RuntimeModule module,
    Map<ModuleId, RuntimeModule> moduleMap,
    Set<ModuleId> globalVisited,
    Set<ModuleId> currentPath,
  ) {
    if (currentPath.contains(module.id)) return true;
    if (globalVisited.contains(module.id)) return false;

    currentPath.add(module.id);

    for (final depId in module.dependencies) {
      final dep = moduleMap[depId];
      if (dep != null) {
        if (_hasCircularDependency(dep, moduleMap, globalVisited, currentPath)) {
          return true;
        }
      }
    }

    currentPath.remove(module.id);
    globalVisited.add(module.id);

    return false;
  }
}
