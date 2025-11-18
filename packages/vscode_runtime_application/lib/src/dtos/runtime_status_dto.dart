import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';

part 'runtime_status_dto.freezed.dart';
part 'runtime_status_dto.g.dart';

/// Runtime Status DTO
/// Represents the current state of the runtime installation
@freezed
class RuntimeStatusDto with _$RuntimeStatusDto {
  const RuntimeStatusDto._();

  /// Runtime not installed
  const factory RuntimeStatusDto.notInstalled() = _NotInstalled;

  /// Runtime fully installed
  const factory RuntimeStatusDto.installed({
    required RuntimeVersion version,
    required DateTime installedAt,
    required List<ModuleId> installedModules,
  }) = _Installed;

  /// Runtime partially installed (some modules missing)
  const factory RuntimeStatusDto.partiallyInstalled({
    required RuntimeVersion version,
    required List<ModuleId> installedModules,
    required List<ModuleId> missingModules,
  }) = _PartiallyInstalled;

  /// Installation in progress
  const factory RuntimeStatusDto.installing({
    required InstallationId installationId,
    required double progress,
    ModuleId? currentModule,
  }) = _Installing;

  /// Installation failed
  const factory RuntimeStatusDto.failed({
    required String error,
    ModuleId? failedModule,
  }) = _Failed;

  /// Update available
  const factory RuntimeStatusDto.updateAvailable({
    required RuntimeVersion currentVersion,
    required RuntimeVersion availableVersion,
  }) = _UpdateAvailable;

  factory RuntimeStatusDto.fromJson(Map<String, dynamic> json) =>
      _$RuntimeStatusDtoFromJson(json);

  /// Check if runtime is ready to use
  bool get isReady => maybeMap(
        installed: (_) => true,
        orElse: () => false,
      );

  /// Check if installation is needed
  bool get needsInstallation => maybeMap(
        notInstalled: (_) => true,
        partiallyInstalled: (_) => true,
        failed: (_) => true,
        orElse: () => false,
      );

  /// Check if currently installing
  bool get isInstalling => maybeMap(
        installing: (_) => true,
        orElse: () => false,
      );
}
