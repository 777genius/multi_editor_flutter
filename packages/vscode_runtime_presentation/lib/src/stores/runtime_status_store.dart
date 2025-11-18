import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:vscode_runtime_application/vscode_runtime_application.dart';

part 'runtime_status_store.g.dart';

/// Runtime Status Store
/// Manages runtime status and update checking
@injectable
class RuntimeStatusStore = _RuntimeStatusStore with _$RuntimeStatusStore;

abstract class _RuntimeStatusStore with Store {
  final GetRuntimeStatusQueryHandler _statusHandler;
  final CheckRuntimeUpdatesCommandHandler _updateHandler;

  _RuntimeStatusStore(
    this._statusHandler,
    this._updateHandler,
  );

  /// Current runtime status
  @observable
  RuntimeStatusDto? status;

  /// Whether currently loading status
  @observable
  bool isLoading = false;

  /// Error message if loading failed
  @observable
  String? errorMessage;

  /// Last status check time
  @observable
  DateTime? lastChecked;

  /// Computed: Is runtime installed
  @computed
  bool get isInstalled => status?.isReady ?? false;

  /// Computed: Needs installation
  @computed
  bool get needsInstallation => status?.needsInstallation ?? true;

  /// Computed: Is currently installing
  @computed
  bool get isInstalling => status?.isInstalling ?? false;

  /// Computed: Status message
  @computed
  String get statusMessage {
    if (status == null) return 'Unknown';

    return status!.map(
      notInstalled: (_) => 'Not Installed',
      installed: (s) => 'Installed (v${s.version})',
      partiallyInstalled: (s) => 'Partially Installed (${s.missingModules.length} modules missing)',
      installing: (s) => 'Installing... (${(s.progress * 100).toStringAsFixed(0)}%)',
      failed: (s) => 'Failed: ${s.error}',
      updateAvailable: (s) => 'Update Available (v${s.availableVersion})',
    );
  }

  /// Load runtime status
  @action
  Future<void> loadStatus() async {
    isLoading = true;
    errorMessage = null;

    final query = GetRuntimeStatusQuery();
    final result = await _statusHandler.handle(query);

    result.fold(
      (error) {
        runInAction(() {
          errorMessage = error.message;
          isLoading = false;
        });
      },
      (statusDto) {
        runInAction(() {
          status = statusDto;
          lastChecked = DateTime.now();
          isLoading = false;
        });
      },
    );
  }

  /// Check for updates
  @action
  Future<void> checkForUpdates({bool forceCheck = false}) async {
    isLoading = true;
    errorMessage = null;

    final command = CheckRuntimeUpdatesCommand(forceCheck: forceCheck);
    final result = await _updateHandler.handle(command);

    result.fold(
      (error) {
        runInAction(() {
          errorMessage = error.message;
          isLoading = false;
        });
      },
      (statusDto) {
        runInAction(() {
          status = statusDto;
          lastChecked = DateTime.now();
          isLoading = false;
        });
      },
    );
  }

  /// Refresh status
  @action
  Future<void> refresh() => loadStatus();
}
