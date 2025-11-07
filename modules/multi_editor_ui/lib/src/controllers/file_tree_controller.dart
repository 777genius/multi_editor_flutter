import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import '../state/file_tree_state.dart';

class FileTreeController extends ValueNotifier<FileTreeState> {
  final FolderRepository _folderRepository;
  final FileRepository _fileRepository;
  final EventBus _eventBus;
  Timer? _refreshTimer;

  FileTreeController({
    required FolderRepository folderRepository,
    required FileRepository fileRepository,
    required EventBus eventBus,
  }) : _folderRepository = folderRepository,
       _fileRepository = fileRepository,
       _eventBus = eventBus,
       super(const FileTreeState.initial());

  Future<void> load({String? rootId}) async {
    value = const FileTreeState.loading();

    try {
      final rootNode = await _buildTree(rootId);
      value = FileTreeState.loaded(rootNode: rootNode);

      _startPeriodicRefresh();
    } catch (e) {
      value = FileTreeState.error(message: 'Failed to load tree: $e');
    }
  }

  Future<FileTreeNode> _buildTree(String? rootId) async {
    final foldersResult = await _folderRepository.listAll();
    final filesResult = await _fileRepository.search();

    return await foldersResult.fold(
      (failure) => throw Exception(failure.displayMessage),
      (folders) async {
        return await filesResult.fold(
          (failure) => throw Exception(failure.displayMessage),
          (files) {
            final actualRootId = rootId ?? 'root';
            return _buildTreeRecursive(actualRootId, folders, files);
          },
        );
      },
    );
  }

  FileTreeNode _buildTreeRecursive(
    String folderId,
    List<Folder> allFolders,
    List<FileDocument> allFiles,
  ) {
    final folder = allFolders.firstWhere(
      (f) => f.id == folderId,
      orElse: () => Folder(
        id: folderId,
        name: 'root',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final childFolders = allFolders.where((f) => f.parentId == folderId);
    final childFiles = allFiles.where((f) => f.folderId == folderId);

    // Sort folders alphabetically (case-insensitive)
    final sortedFolders = childFolders.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // Sort files alphabetically (case-insensitive)
    final sortedFiles = childFiles.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final children = <FileTreeNode>[
      ...sortedFolders.map(
        (f) => _buildTreeRecursive(f.id, allFolders, allFiles),
      ),
      ...sortedFiles.map(
        (f) => FileTreeNode.file(
          id: f.id,
          name: f.name,
          parentId: folderId,
          language: f.language,
        ),
      ),
    ];

    return FileTreeNode.folder(
      id: folder.id,
      name: folder.name,
      parentId: folder.parentId,
      children: children,
      isExpanded: value.isFolderExpanded(folder.id),
    );
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => refresh(),
    );
  }

  Future<void> refresh() async {
    value.mapOrNull(
      loaded: (state) async {
        try {
          final rootNode = await _buildTree(state.rootNode.parentId);
          value = state.copyWith(rootNode: rootNode);
        } catch (e) {
          // Silent fail on refresh
        }
      },
    );
  }

  Future<void> createFile({
    required String folderId,
    required String name,
  }) async {
    try {
      final result = await _fileRepository.create(
        folderId: folderId,
        name: name,
      );

      result.fold(
        (failure) {
          value = FileTreeState.error(
            message: 'Failed to create file: ${failure.displayMessage}',
          );
        },
        (file) {
          _eventBus.publish(EditorEvent.fileCreated(file: file));
          refresh();
        },
      );
    } catch (e) {
      value = FileTreeState.error(message: 'Failed to create file: $e');
    }
  }

  Future<void> createFolder({required String name, String? parentId}) async {
    try {
      final result = await _folderRepository.create(
        name: name,
        parentId: parentId,
      );

      result.fold(
        (failure) {
          value = FileTreeState.error(
            message: 'Failed to create folder: ${failure.displayMessage}',
          );
        },
        (folder) {
          _eventBus.publish(EditorEvent.folderCreated(folder: folder));
          refresh();
        },
      );
    } catch (e) {
      value = FileTreeState.error(message: 'Failed to create folder: $e');
    }
  }

  Future<void> deleteFile(String fileId) async {
    try {
      final result = await _fileRepository.delete(fileId);

      result.fold(
        (failure) {
          value = FileTreeState.error(
            message: 'Failed to delete file: ${failure.displayMessage}',
          );
        },
        (_) {
          _eventBus.publish(EditorEvent.fileDeleted(fileId: fileId));
          refresh();
        },
      );
    } catch (e) {
      value = FileTreeState.error(message: 'Failed to delete file: $e');
    }
  }

  Future<void> deleteFolder(String folderId) async {
    try {
      final result = await _folderRepository.delete(folderId);

      result.fold(
        (failure) {
          value = FileTreeState.error(
            message: 'Failed to delete folder: ${failure.displayMessage}',
          );
        },
        (_) {
          _eventBus.publish(EditorEvent.folderDeleted(folderId: folderId));
          refresh();
        },
      );
    } catch (e) {
      value = FileTreeState.error(message: 'Failed to delete folder: $e');
    }
  }

  Future<void> moveFile(String fileId, String targetFolderId) async {
    try {
      final result = await _fileRepository.move(
        fileId: fileId,
        targetFolderId: targetFolderId,
      );

      result.fold(
        (failure) {
          value = FileTreeState.error(
            message: 'Failed to move file: ${failure.displayMessage}',
          );
        },
        (file) {
          _eventBus.publish(
            EditorEvent.fileMoved(
              fileId: fileId,
              oldFolderId: file.folderId,
              newFolderId: targetFolderId,
            ),
          );
          refresh();
        },
      );
    } catch (e) {
      value = FileTreeState.error(message: 'Failed to move file: $e');
    }
  }

  Future<void> moveFolder(String folderId, String targetFolderId) async {
    try {
      final result = await _folderRepository.move(
        folderId: folderId,
        targetParentId: targetFolderId,
      );

      result.fold(
        (failure) {
          value = FileTreeState.error(
            message: 'Failed to move folder: ${failure.displayMessage}',
          );
        },
        (folder) {
          _eventBus.publish(
            EditorEvent.folderMoved(
              folderId: folderId,
              oldParentId: folder.parentId,
              newParentId: targetFolderId,
            ),
          );
          refresh();
        },
      );
    } catch (e) {
      value = FileTreeState.error(message: 'Failed to move folder: $e');
    }
  }

  Future<void> renameFile(String fileId, String newName) async {
    try {
      final result = await _fileRepository.rename(
        fileId: fileId,
        newName: newName,
      );

      result.fold(
        (failure) {
          value = FileTreeState.error(
            message: 'Failed to rename file: ${failure.displayMessage}',
          );
        },
        (file) {
          _eventBus.publish(
            EditorEvent.fileRenamed(
              fileId: fileId,
              oldName: file.name,
              newName: newName,
            ),
          );
          refresh();
        },
      );
    } catch (e) {
      value = FileTreeState.error(message: 'Failed to rename file: $e');
    }
  }

  Future<void> renameFolder(String folderId, String newName) async {
    try {
      final result = await _folderRepository.rename(
        folderId: folderId,
        newName: newName,
      );

      result.fold(
        (failure) {
          value = FileTreeState.error(
            message: 'Failed to rename folder: ${failure.displayMessage}',
          );
        },
        (folder) {
          _eventBus.publish(
            EditorEvent.folderRenamed(
              folderId: folderId,
              oldName: folder.name,
              newName: newName,
            ),
          );
          refresh();
        },
      );
    } catch (e) {
      value = FileTreeState.error(message: 'Failed to rename folder: $e');
    }
  }

  void selectNode(String? nodeId) {
    value.mapOrNull(
      loaded: (state) {
        value = state.copyWith(selectedNodeId: nodeId);
      },
    );
  }

  void toggleFolder(String folderId) {
    value.mapOrNull(
      loaded: (state) {
        final expanded = List<String>.from(state.expandedFolderIds);
        if (expanded.contains(folderId)) {
          expanded.remove(folderId);
        } else {
          expanded.add(folderId);
        }
        value = state.copyWith(
          expandedFolderIds: expanded,
          selectedNodeId: folderId,
        );
      },
    );
  }

  String? getSelectedParentFolderId() {
    return value.maybeMap(
      loaded: (state) {
        if (state.selectedNodeId == null) {
          return state.rootNode.id;
        }

        final selectedNode = state.rootNode.findNode(state.selectedNodeId!);
        if (selectedNode == null) {
          return state.rootNode.id;
        }

        if (selectedNode.isFolder) {
          return selectedNode.id;
        }

        return selectedNode.parentId ?? state.rootNode.id;
      },
      orElse: () => null,
    );
  }

  void expandAll() {
    value.mapOrNull(
      loaded: (state) {
        final allFolderIds = state.rootNode.allFolders
            .map((f) => f.id)
            .toList();
        value = state.copyWith(expandedFolderIds: allFolderIds);
      },
    );
  }

  void collapseAll() {
    value.mapOrNull(
      loaded: (state) {
        value = state.copyWith(expandedFolderIds: []);
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
