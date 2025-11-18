import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';

part 'platform_info_dto.freezed.dart';
part 'platform_info_dto.g.dart';

/// Platform Info DTO
/// Information about the current platform
@freezed
class PlatformInfoDto with _$PlatformInfoDto {
  const PlatformInfoDto._();

  const factory PlatformInfoDto({
    required PlatformIdentifier identifier,
    required String osName,
    required String osVersion,
    required String architecture,
    required int numberOfProcessors,
    required ByteSize availableDiskSpace,
    required bool hasRequiredPermissions,
    required bool isSupported,
  }) = _PlatformInfoDto;

  factory PlatformInfoDto.fromJson(Map<String, dynamic> json) =>
      _$PlatformInfoDtoFromJson(json);

  /// Get display string
  String get displayString => identifier.toDisplayString();

  /// Check if sufficient disk space for installation
  /// Requires at least 1GB free space
  bool get hasSufficientSpace => availableDiskSpace.inGB >= 1.0;

  /// Check if platform can install runtime
  bool get canInstallRuntime =>
      isSupported && hasRequiredPermissions && hasSufficientSpace;

  /// Get warning message if installation is not recommended
  String? get installationWarning {
    if (!isSupported) {
      return 'Platform $displayString is not supported';
    }
    if (!hasRequiredPermissions) {
      return 'Insufficient permissions to install runtime';
    }
    if (!hasSufficientSpace) {
      return 'Insufficient disk space (requires at least 1GB)';
    }
    return null;
  }
}
