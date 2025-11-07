import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_tree_node.freezed.dart';
part 'file_tree_node.g.dart';

enum FileTreeNodeType { file, folder }

@freezed
sealed class FileTreeNode with _$FileTreeNode {
  const FileTreeNode._();

  const factory FileTreeNode({
    required String id,
    required String name,
    required FileTreeNodeType type,
    String? parentId,
    String? language,
    @Default([]) List<FileTreeNode> children,
    @Default(false) bool isExpanded,
    @Default({}) Map<String, dynamic> metadata,
  }) = _FileTreeNode;

  factory FileTreeNode.fromJson(Map<String, dynamic> json) =>
      _$FileTreeNodeFromJson(json);

  factory FileTreeNode.file({
    required String id,
    required String name,
    String? parentId,
    String? language,
    Map<String, dynamic>? metadata,
  }) {
    return FileTreeNode(
      id: id,
      name: name,
      type: FileTreeNodeType.file,
      parentId: parentId,
      language: language,
      children: [],
      metadata: metadata ?? {},
    );
  }

  factory FileTreeNode.folder({
    required String id,
    required String name,
    String? parentId,
    List<FileTreeNode>? children,
    bool isExpanded = false,
    Map<String, dynamic>? metadata,
  }) {
    return FileTreeNode(
      id: id,
      name: name,
      type: FileTreeNodeType.folder,
      parentId: parentId,
      children: children ?? [],
      isExpanded: isExpanded,
      metadata: metadata ?? {},
    );
  }

  bool get isFile => type == FileTreeNodeType.file;

  bool get isFolder => type == FileTreeNodeType.folder;

  bool get hasChildren => children.isNotEmpty;

  int get childrenCount => children.length;

  int get depth {
    if (children.isEmpty) return 0;
    return 1 + children.map((c) => c.depth).reduce((a, b) => a > b ? a : b);
  }

  FileTreeNode toggleExpanded() {
    return copyWith(isExpanded: !isExpanded);
  }

  FileTreeNode addChild(FileTreeNode child) {
    return copyWith(
      children: [...children, child.copyWith(parentId: id)],
    );
  }

  FileTreeNode removeChild(String childId) {
    return copyWith(
      children: children.where((c) => c.id != childId).toList(),
    );
  }

  FileTreeNode updateChild(FileTreeNode updatedChild) {
    return copyWith(
      children: children.map((c) {
        if (c.id == updatedChild.id) return updatedChild;
        return c;
      }).toList(),
    );
  }

  FileTreeNode? findNode(String nodeId) {
    if (id == nodeId) return this;
    for (final child in children) {
      final found = child.findNode(nodeId);
      if (found != null) return found;
    }
    return null;
  }

  List<FileTreeNode> flatten() {
    final result = <FileTreeNode>[this];
    for (final child in children) {
      result.addAll(child.flatten());
    }
    return result;
  }

  List<FileTreeNode> get allFiles {
    final result = <FileTreeNode>[];
    if (isFile) {
      result.add(this);
    }
    for (final child in children) {
      result.addAll(child.allFiles);
    }
    return result;
  }

  List<FileTreeNode> get allFolders {
    final result = <FileTreeNode>[];
    if (isFolder) {
      result.add(this);
    }
    for (final child in children) {
      result.addAll(child.allFolders);
    }
    return result;
  }
}
