import 'package:freezed_annotation/freezed_annotation.dart';
import '../value_objects/runtime_version.dart';
import 'runtime_module.dart';

part 'runtime_manifest.freezed.dart';
part 'runtime_manifest.g.dart';

/// Entity: Runtime Manifest
/// Represents the complete manifest of available runtime modules
@freezed
class RuntimeManifest with _$RuntimeManifest {
  const RuntimeManifest._();

  const factory RuntimeManifest({
    required RuntimeVersion version,
    required List<RuntimeModule> modules,
    required DateTime publishedAt,
    RuntimeVersion? minClientVersion,
    Map<String, dynamic>? metadata,
  }) = _RuntimeManifest;

  factory RuntimeManifest.fromJson(Map<String, dynamic> json) =>
      _$RuntimeManifestFromJson(json);

  /// Business Logic: Check if manifest is stale
  bool isStale({Duration maxAge = const Duration(days: 1)}) {
    final now = DateTime.now();
    final age = now.difference(publishedAt);
    return age > maxAge;
  }

  /// Business Logic: Get module by ID
  RuntimeModule? getModuleById(String moduleId) {
    try {
      return modules.firstWhere((m) => m.id.value == moduleId);
    } catch (_) {
      return null;
    }
  }

  /// Business Logic: Count modules
  int get moduleCount => modules.length;

  /// Business Logic: Check if has modules
  bool get hasModules => modules.isNotEmpty;
}
