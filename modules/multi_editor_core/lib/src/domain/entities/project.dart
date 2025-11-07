import 'package:freezed_annotation/freezed_annotation.dart';

part 'project.freezed.dart';
part 'project.g.dart';

@freezed
sealed class Project with _$Project {
  const Project._();

  const factory Project({
    required String id,
    required String name,
    String? description,
    required String rootFolderId,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default({}) Map<String, dynamic> settings,
    @Default({}) Map<String, dynamic> metadata,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);

  Project updateName(String newName) {
    return copyWith(
      name: newName,
      updatedAt: DateTime.now(),
    );
  }

  Project updateDescription(String? newDescription) {
    return copyWith(
      description: newDescription,
      updatedAt: DateTime.now(),
    );
  }

  Project updateSettings(Map<String, dynamic> newSettings) {
    return copyWith(
      settings: newSettings,
      updatedAt: DateTime.now(),
    );
  }
}
