import 'package:injectable/injectable.dart';
import 'package:mobx/mobx.dart';
import 'package:vscode_runtime_application/vscode_runtime_application.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';

part 'module_list_store.g.dart';

/// Module List Store
/// Manages available modules and selection
@injectable
class ModuleListStore = _ModuleListStore with _$ModuleListStore;

abstract class _ModuleListStore with Store {
  final GetAvailableModulesQueryHandler _modulesHandler;
  final GetPlatformInfoQueryHandler _platformHandler;

  _ModuleListStore(
    this._modulesHandler,
    this._platformHandler,
  );

  /// Available modules
  @observable
  ObservableList<ModuleInfoDto> modules = ObservableList<ModuleInfoDto>();

  /// Selected modules for installation
  @observable
  ObservableSet<ModuleId> selectedModules = ObservableSet<ModuleId>();

  /// Platform information
  @observable
  PlatformInfoDto? platformInfo;

  /// Whether currently loading
  @observable
  bool isLoading = false;

  /// Error message if loading failed
  @observable
  String? errorMessage;

  /// Filter: Show only compatible modules
  @observable
  bool showOnlyCompatible = true;

  /// Filter: Show optional modules
  @observable
  bool showOptional = true;

  /// Computed: Critical modules
  @computed
  List<ModuleInfoDto> get criticalModules =>
      modules.where((m) => !m.isOptional).toList();

  /// Computed: Optional modules
  @computed
  List<ModuleInfoDto> get optionalModules =>
      modules.where((m) => m.isOptional).toList();

  /// Computed: Installed modules
  @computed
  List<ModuleInfoDto> get installedModules =>
      modules.where((m) => m.isInstalled).toList();

  /// Computed: Not installed modules
  @computed
  List<ModuleInfoDto> get notInstalledModules =>
      modules.where((m) => !m.isInstalled).toList();

  /// Computed: Total size of selected modules
  @computed
  ByteSize get selectedSize {
    int totalBytes = 0;
    for (final moduleId in selectedModules) {
      final module = modules.firstWhere((m) => m.id == moduleId);
      if (module.sizeForCurrentPlatform != null) {
        totalBytes += module.sizeForCurrentPlatform!.bytes;
      }
    }
    return ByteSize(bytes: totalBytes);
  }

  /// Computed: Number of selected modules
  @computed
  int get selectedCount => selectedModules.length;

  /// Load modules
  @action
  Future<void> loadModules() async {
    isLoading = true;
    errorMessage = null;

    final query = GetAvailableModulesQuery(
      includeOptional: showOptional,
      platformOnly: showOnlyCompatible,
    );

    final result = await _modulesHandler.handle(query);

    result.fold(
      (error) {
        runInAction(() {
          errorMessage = error.message;
          isLoading = false;
        });
      },
      (moduleList) {
        runInAction(() {
          modules = ObservableList.of(moduleList);
          isLoading = false;
        });
      },
    );
  }

  /// Load platform info
  @action
  Future<void> loadPlatformInfo() async {
    final query = GetPlatformInfoQuery();
    final result = await _platformHandler.handle(query);

    result.fold(
      (error) {
        runInAction(() {
          errorMessage = error.message;
        });
      },
      (info) {
        runInAction(() {
          platformInfo = info;
        });
      },
    );
  }

  /// Toggle module selection
  @action
  void toggleModule(ModuleId moduleId) {
    if (selectedModules.contains(moduleId)) {
      selectedModules.remove(moduleId);
    } else {
      selectedModules.add(moduleId);
    }
  }

  /// Select all critical modules
  @action
  void selectAllCritical() {
    selectedModules.clear();
    selectedModules.addAll(criticalModules.map((m) => m.id));
  }

  /// Clear selection
  @action
  void clearSelection() {
    selectedModules.clear();
  }

  /// Toggle filter: show only compatible
  @action
  void toggleShowOnlyCompatible() {
    showOnlyCompatible = !showOnlyCompatible;
    loadModules();
  }

  /// Toggle filter: show optional
  @action
  void toggleShowOptional() {
    showOptional = !showOptional;
    loadModules();
  }

  /// Initialize
  @action
  Future<void> initialize() async {
    await loadPlatformInfo();
    await loadModules();
    selectAllCritical();
  }
}
