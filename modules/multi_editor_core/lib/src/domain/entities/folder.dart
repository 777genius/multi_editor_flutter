import 'package:freezed_annotation/freezed_annotation.dart';

part 'folder.freezed.dart';
part 'folder.g.dart';

@freezed
sealed class Folder with _$Folder {
  const Folder._();

  const factory Folder({
    required String id,
    required String name,
    String? parentId,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default({}) Map<String, dynamic> metadata,
  }) = _Folder;

  factory Folder.fromJson(Map<String, dynamic> json) =>
      _$FolderFromJson(json);

  Folder rename(String newName) {
    return copyWith(
      name: newName,
      updatedAt: DateTime.now(),
    );
  }

  Folder move(String? targetParentId) {
    return copyWith(
      parentId: targetParentId,
      updatedAt: DateTime.now(),
    );
  }

  bool get isRoot => parentId == null;

  String get path {
    if (isRoot) return '/';
    return '/$name';
  }
}
