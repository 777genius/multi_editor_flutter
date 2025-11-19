import 'package:json_annotation/json_annotation.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';

part 'manifest_dto.g.dart';

/// Manifest DTO for JSON serialization
/// Represents the runtime manifest with all modules
@JsonSerializable(explicitToJson: true)
class ManifestDto {
  final String version;
  final String publishedAt;
  final List<RuntimeModuleDto> modules;
  final String? minClientVersion;
  final Map<String, dynamic>? metadata;

  const ManifestDto({
    required this.version,
    required this.publishedAt,
    required this.modules,
    this.minClientVersion,
    this.metadata,
  });

  factory ManifestDto.fromJson(Map<String, dynamic> json) =>
      _$ManifestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ManifestDtoToJson(this);

  /// Convert to domain entities - returns list of modules
  List<RuntimeModule> toDomain() {
    return modules.map((dto) => dto.toDomain()).toList();
  }

  /// Convert to RuntimeManifest domain entity
  RuntimeManifest toManifest() {
    return RuntimeManifest(
      version: RuntimeVersion.fromString(version),
      modules: toDomain(),
      publishedAt: DateTime.parse(publishedAt),
      minClientVersion: minClientVersion != null
          ? RuntimeVersion.fromString(minClientVersion!)
          : null,
      metadata: metadata,
    );
  }

  /// Create from domain entities
  factory ManifestDto.fromDomain(RuntimeManifest manifest) {
    return ManifestDto(
      version: manifest.version.toString(),
      publishedAt: manifest.publishedAt.toIso8601String(),
      modules: manifest.modules.map((m) => RuntimeModuleDto.fromDomain(m)).toList(),
      minClientVersion: manifest.minClientVersion?.toString(),
      metadata: manifest.metadata,
    );
  }
}

/// Runtime Module DTO
@JsonSerializable(explicitToJson: true)
class RuntimeModuleDto {
  final String id;
  final String name;
  final String description;
  final String type;
  final String version;
  final Map<String, PlatformArtifactDto> platformArtifacts;
  final List<String> dependencies;
  final bool isOptional;
  final Map<String, dynamic>? metadata;

  const RuntimeModuleDto({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.version,
    required this.platformArtifacts,
    required this.dependencies,
    required this.isOptional,
    this.metadata,
  });

  factory RuntimeModuleDto.fromJson(Map<String, dynamic> json) =>
      _$RuntimeModuleDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RuntimeModuleDtoToJson(this);

  /// Convert to domain entity
  RuntimeModule toDomain() {
    return RuntimeModule(
      id: ModuleId(id),
      name: name,
      description: description,
      type: ModuleType.values.firstWhere(
        (t) => t.toString().split('.').last == type,
      ),
      version: RuntimeVersion.fromString(version),
      platformArtifacts: platformArtifacts.map(
        (key, value) => MapEntry(
          _parsePlatformIdentifier(key),
          value.toDomain(),
        ),
      ),
      dependencies: dependencies.map((d) => ModuleId(d)).toList(),
      isOptional: isOptional,
      metadata: metadata,
    );
  }

  /// Create from domain entity
  factory RuntimeModuleDto.fromDomain(RuntimeModule module) {
    return RuntimeModuleDto(
      id: module.id.value,
      name: module.name,
      description: module.description,
      type: module.type.toString().split('.').last,
      version: module.version.toString(),
      platformArtifacts: module.platformArtifacts.map(
        (key, value) => MapEntry(
          key.toString(),
          PlatformArtifactDto.fromDomain(value),
        ),
      ),
      dependencies: module.dependencies.map((d) => d.value).toList(),
      isOptional: module.isOptional,
      metadata: module.metadata,
    );
  }

  static PlatformIdentifier _parsePlatformIdentifier(String key) {
    final parts = key.split('-');
    if (parts.length != 2) {
      throw FormatException('Invalid platform identifier: $key');
    }
    return PlatformIdentifier(os: parts[0], architecture: parts[1]);
  }
}

/// Platform Artifact DTO
@JsonSerializable()
class PlatformArtifactDto {
  final String url;
  final String hash;
  final int sizeBytes;
  final String? compressionFormat;

  const PlatformArtifactDto({
    required this.url,
    required this.hash,
    required this.sizeBytes,
    this.compressionFormat,
  });

  factory PlatformArtifactDto.fromJson(Map<String, dynamic> json) =>
      _$PlatformArtifactDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PlatformArtifactDtoToJson(this);

  /// Convert to domain entity
  PlatformArtifact toDomain() {
    return PlatformArtifact(
      url: DownloadUrl(url),
      hash: SHA256Hash.fromString(hash),
      size: ByteSize(sizeBytes),
      compressionFormat: compressionFormat,
    );
  }

  /// Create from domain entity
  factory PlatformArtifactDto.fromDomain(PlatformArtifact artifact) {
    return PlatformArtifactDto(
      url: artifact.url.value,
      hash: artifact.hash.value,
      sizeBytes: artifact.size.bytes,
      compressionFormat: artifact.compressionFormat,
    );
  }
}
