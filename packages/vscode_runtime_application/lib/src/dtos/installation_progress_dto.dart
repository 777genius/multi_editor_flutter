import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';

part 'installation_progress_dto.freezed.dart';
part 'installation_progress_dto.g.dart';

/// Installation Progress DTO
/// Detailed progress information for an installation
@freezed
class InstallationProgressDto with _$InstallationProgressDto {
  const InstallationProgressDto._();

  const factory InstallationProgressDto({
    required InstallationId installationId,
    required InstallationStatus status,
    required double overallProgress,
    required int totalModules,
    required int installedModules,
    required List<ModuleId> remainingModules,
    ModuleId? currentModule,
    double? currentModuleProgress,
    String? errorMessage,
    DateTime? startedAt,
    DateTime? completedAt,
  }) = _InstallationProgressDto;

  factory InstallationProgressDto.fromJson(Map<String, dynamic> json) =>
      _$InstallationProgressDtoFromJson(json);

  /// Create from domain aggregate
  factory InstallationProgressDto.fromDomain(RuntimeInstallation installation) {
    return InstallationProgressDto(
      installationId: installation.id,
      status: installation.status,
      overallProgress: installation.calculateProgress(),
      totalModules: installation.modules.length,
      installedModules: installation.installedModules.length,
      remainingModules: installation
          .getRemainingModules()
          .map((m) => m.id)
          .toList(),
      currentModule: installation.currentModule,
      currentModuleProgress: installation.progress,
      errorMessage: installation.errorMessage,
      startedAt: installation.createdAt,
      completedAt: installation.completedAt,
    );
  }

  /// Check if installation is complete
  bool get isCompleted => status == InstallationStatus.completed;

  /// Check if installation failed
  bool get hasFailed => status == InstallationStatus.failed;

  /// Check if installation is in progress
  bool get isInProgress => status == InstallationStatus.inProgress;

  /// Get human-readable status message
  String get statusMessage {
    return status.when(
      pending: () => 'Preparing installation...',
      inProgress: () {
        if (currentModule != null) {
          return 'Installing ${currentModule!.value}...';
        }
        return 'Installing... ($installedModules/$totalModules modules)';
      },
      completed: () => 'Installation completed successfully',
      failed: () => errorMessage ?? 'Installation failed',
      cancelled: () => 'Installation cancelled',
    );
  }
}
