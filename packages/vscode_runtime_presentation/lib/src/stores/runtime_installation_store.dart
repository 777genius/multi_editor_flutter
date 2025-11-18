import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:vscode_runtime_application/vscode_runtime_application.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';

part 'runtime_installation_store.g.dart';

/// Runtime Installation Store
/// Manages installation state and progress using MobX
@injectable
class RuntimeInstallationStore = _RuntimeInstallationStore with _$RuntimeInstallationStore;

abstract class _RuntimeInstallationStore with Store {
  final InstallRuntimeCommandHandler _installHandler;
  final CancelInstallationCommandHandler _cancelHandler;
  final GetInstallationProgressQueryHandler _progressHandler;

  _RuntimeInstallationStore(
    this._installHandler,
    this._cancelHandler,
    this._progressHandler,
  );

  /// Current installation ID
  @observable
  InstallationId? currentInstallationId;

  /// Installation status
  @observable
  InstallationStatus status = InstallationStatus.pending;

  /// Overall progress (0.0 - 1.0)
  @observable
  double overallProgress = 0.0;

  /// Current module being installed
  @observable
  ModuleId? currentModule;

  /// Current module progress (0.0 - 1.0)
  @observable
  double currentModuleProgress = 0.0;

  /// Total modules to install
  @observable
  int totalModules = 0;

  /// Installed modules count
  @observable
  int installedModules = 0;

  /// Error message if installation failed
  @observable
  String? errorMessage;

  /// Cancellation token
  CancelToken? _cancelToken;

  /// Computed: Is currently installing
  @computed
  bool get isInstalling => status == InstallationStatus.inProgress;

  /// Computed: Is completed
  @computed
  bool get isCompleted => status == InstallationStatus.completed;

  /// Computed: Has failed
  @computed
  bool get hasFailed => status == InstallationStatus.failed;

  /// Computed: Can be cancelled
  @computed
  bool get canCancel =>
      status == InstallationStatus.pending ||
      status == InstallationStatus.inProgress;

  /// Computed: Progress percentage string
  @computed
  String get progressText => '${(overallProgress * 100).toStringAsFixed(0)}%';

  /// Computed: Status message
  @computed
  String get statusMessage {
    return status.when(
      pending: () => 'Preparing installation...',
      inProgress: () {
        if (currentModule != null) {
          return 'Installing ${currentModule!.value}... ($installedModules/$totalModules)';
        }
        return 'Installing... ($installedModules/$totalModules modules)';
      },
      completed: () => 'Installation completed successfully!',
      failed: () => errorMessage ?? 'Installation failed',
      cancelled: () => 'Installation cancelled',
    );
  }

  /// Start installation
  @action
  Future<void> install({
    List<ModuleId> moduleIds = const [],
    InstallationTrigger trigger = InstallationTrigger.manual,
  }) async {
    // Reset state
    status = InstallationStatus.pending;
    overallProgress = 0.0;
    currentModule = null;
    currentModuleProgress = 0.0;
    errorMessage = null;
    _cancelToken = CancelToken();

    // Create and execute command
    final command = InstallRuntimeCommand(
      moduleIds: moduleIds,
      trigger: trigger,
      onProgress: _onProgress,
      cancelToken: _cancelToken,
    );

    status = InstallationStatus.inProgress;

    final result = await _installHandler.handle(command);

    result.fold(
      (error) {
        // Installation failed
        runInAction(() {
          status = InstallationStatus.failed;
          errorMessage = error.message;
        });
      },
      (_) {
        // Installation completed
        runInAction(() {
          status = InstallationStatus.completed;
          overallProgress = 1.0;
          currentModule = null;
        });
      },
    );
  }

  /// Cancel installation
  @action
  Future<void> cancel({String? reason}) async {
    if (currentInstallationId == null) return;
    if (!canCancel) return;

    // Cancel via command
    final command = CancelInstallationCommand(
      installationId: currentInstallationId!,
      reason: reason,
    );

    await _cancelHandler.handle(command);

    // Also cancel network operations
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel('Cancelled by user');
    }

    runInAction(() {
      status = InstallationStatus.cancelled;
    });
  }

  /// Reset state
  @action
  void reset() {
    currentInstallationId = null;
    status = InstallationStatus.pending;
    overallProgress = 0.0;
    currentModule = null;
    currentModuleProgress = 0.0;
    totalModules = 0;
    installedModules = 0;
    errorMessage = null;
    _cancelToken = null;
  }

  /// Progress callback from install command
  @action
  void _onProgress(ModuleId moduleId, double progress) {
    runInAction(() {
      currentModule = moduleId;
      currentModuleProgress = progress;

      // Update installed count when module completes
      if (progress >= 1.0) {
        installedModules++;
      }

      // Calculate overall progress
      if (totalModules > 0) {
        overallProgress = (installedModules + currentModuleProgress) / totalModules;
      }
    });
  }

  /// Load progress for existing installation
  @action
  Future<void> loadProgress(InstallationId installationId) async {
    final query = GetInstallationProgressQuery(
      installationId: installationId,
    );

    final result = await _progressHandler.handle(query);

    result.fold(
      (error) {
        // Failed to load progress
        runInAction(() {
          errorMessage = 'Failed to load progress: ${error.message}';
        });
      },
      (progress) {
        runInAction(() {
          currentInstallationId = progress.installationId;
          status = progress.status;
          overallProgress = progress.overallProgress;
          totalModules = progress.totalModules;
          installedModules = progress.installedModules;
          currentModule = progress.currentModule;
          currentModuleProgress = progress.currentModuleProgress ?? 0.0;
          errorMessage = progress.errorMessage;
        });
      },
    );
  }
}
