import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:multi_editor_core/multi_editor_core.dart';

part 'file_tree_state.freezed.dart';

@freezed
sealed class FileTreeState with _$FileTreeState {
  const FileTreeState._();

  const factory FileTreeState.initial() = _Initial;

  const factory FileTreeState.loading() = _Loading;

  const factory FileTreeState.loaded({
    required FileTreeNode rootNode,
    String? selectedNodeId,
    @Default([]) List<String> expandedFolderIds,
  }) = _Loaded;

  const factory FileTreeState.error({required String message}) = _Error;

  bool get isInitial => this is _Initial;
  bool get isLoading => this is _Loading;
  bool get isLoaded => this is _Loaded;
  bool get isError => this is _Error;

  bool isFolderExpanded(String folderId) => maybeMap(
    loaded: (state) => state.expandedFolderIds.contains(folderId),
    orElse: () => false,
  );

  bool isNodeSelected(String nodeId) => maybeMap(
    loaded: (state) => state.selectedNodeId == nodeId,
    orElse: () => false,
  );

  bool isFileSelected(String fileId) => isNodeSelected(fileId);

  FileTreeNode? get rootNode =>
      maybeMap(loaded: (state) => state.rootNode, orElse: () => null);

  int get treeDepth =>
      maybeMap(loaded: (state) => state.rootNode.depth, orElse: () => 0);

  int get totalFiles => maybeMap(
    loaded: (state) => state.rootNode.allFiles.length,
    orElse: () => 0,
  );

  int get totalFolders => maybeMap(
    loaded: (state) => state.rootNode.allFolders.length,
    orElse: () => 0,
  );
}
