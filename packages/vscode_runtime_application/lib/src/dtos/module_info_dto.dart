import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';

part 'module_info_dto.freezed.dart';
part 'module_info_dto.g.dart';

/// Module Info DTO
/// Information about an available runtime module
@freezed
class ModuleInfoDto with _$ModuleInfoDto {
  const ModuleInfoDto._();

  const factory ModuleInfoDto({
    required ModuleId id,
    required String name,
    required String description,
    required ModuleType type,
    required RuntimeVersion version,
    required List<String> supportedPlatforms,
    required List<ModuleId> dependencies,
    required bool isOptional,
    required bool isInstalled,
    ByteSize? sizeForCurrentPlatform,
    Map<String, dynamic>? metadata,
  }) = _ModuleInfoDto;

  factory ModuleInfoDto.fromJson(Map<String, dynamic> json) =>
      _$ModuleInfoDtoFromJson(json);

  /// Create from domain entity
  factory ModuleInfoDto.fromDomain({
    required RuntimeModule module,
    required PlatformIdentifier currentPlatform,
    required bool isInstalled,
  }) {
    return ModuleInfoDto(
      id: module.id,
      name: module.name,
      description: module.description,
      type: module.type,
      version: module.version,
      supportedPlatforms: module.supportedPlatforms
          .map((p) => p.toDisplayString())
          .toList(),
      dependencies: module.dependencies,
      isOptional: module.isOptional,
      isInstalled: isInstalled,
      sizeForCurrentPlatform: module
          .sizeForPlatform(currentPlatform)
          .toNullable(),
      metadata: module.metadata,
    );
  }

  /// Get display name with version
  String get displayName => '$name v$version';

  /// Check if module has dependencies
  bool get hasDependencies => dependencies.isNotEmpty;

  /// Get type display name
  String get typeDisplayName => type.toString().split('.').last;
}
