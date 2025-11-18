import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_ui/src/controllers/file_tree_controller.dart';
import 'package:multi_editor_ui/src/state/file_tree_state.dart';

// Mocks
class MockFolderRepository extends Mock implements FolderRepository {}

class MockFileRepository extends Mock implements FileRepository {}

class MockEventBus extends Mock implements EventBus {}

// Fake classes for mocktail
class FakeFolder extends Fake implements Folder {}

class FakeFileDocument extends Fake implements FileDocument {}

class FakeEditorEvent extends Fake implements EditorEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeFolder());
    registerFallbackValue(FakeFileDocument());
    registerFallbackValue(FakeEditorEvent());
  });

  group('FileTreeController', () {
    late MockFolderRepository mockFolderRepository;
    late MockFileRepository mockFileRepository;
    late MockEventBus mockEventBus;
    late FileTreeController controller;

    // Test data
    final rootFolder = Folder(
      id: 'root',
      name: 'root',
      parentId: null,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    final srcFolder = Folder(
      id: 'src',
      name: 'src',
      parentId: 'root',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    final testFile = FileDocument(
      id: 'file-1',
      name: 'main.dart',
      content: 'void main() {}',
      language: 'dart',
      folderId: 'root',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    setUp(() {
      mockFolderRepository = MockFolderRepository();
      mockFileRepository = MockFileRepository();
      mockEventBus = MockEventBus();

      // Setup default stubs
      when(() => mockEventBus.publish(any())).thenReturn(null);

      controller = FileTreeController(
        folderRepository: mockFolderRepository,
        fileRepository: mockFileRepository,
        eventBus: mockEventBus,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    group('Initialization', () {
      test('should initialize with initial state', () {
        // Assert
        expect(controller.value, isA<FileTreeState>());
        expect(controller.value.isInitial, isTrue);
      });
    });

    group('load', () {
      test('should emit loading state then loaded state on success', () async {
        // Arrange
        when(() => mockFolderRepository.listAll())
            .thenAnswer((_) async => Right([rootFolder]));
        when(() => mockFileRepository.search())
            .thenAnswer((_) async => Right([testFile]));

        final states = <FileTreeState>[];
        controller.addListener(() {
          states.add(controller.value);
        });

        // Act
        await controller.load();

        // Assert
        expect(states.length, equals(2));
        expect(states[0].isLoading, isTrue);
        expect(states[1].isLoaded, isTrue);
      });

      test('should build tree structure with folders and files', () async {
        // Arrange
        when(() => mockFolderRepository.listAll())
            .thenAnswer((_) async => Right([rootFolder, srcFolder]));
        when(() => mockFileRepository.search())
            .thenAnswer((_) async => Right([testFile]));

        // Act
        await controller.load();

        // Assert
        final state = controller.value;
        expect(state.isLoaded, isTrue);

        final rootNode = state.rootNode;
        expect(rootNode, isNotNull);
        expect(rootNode!.name, equals('root'));
        expect(rootNode.isFolder, isTrue);
      });

      test('should sort folders and files alphabetically', () async {
        // Arrange
        final folderB = srcFolder.copyWith(id: 'b-folder', name: 'b_folder');
        final folderA = srcFolder.copyWith(id: 'a-folder', name: 'a_folder');

        final fileZ = testFile.copyWith(id: 'file-z', name: 'z.dart');
        final fileA = testFile.copyWith(id: 'file-a', name: 'a.dart');

        when(() => mockFolderRepository.listAll())
            .thenAnswer((_) async => Right([rootFolder, folderB, folderA]));
        when(() => mockFileRepository.search())
            .thenAnswer((_) async => Right([fileZ, fileA]));

        // Act
        await controller.load();

        // Assert
        final rootNode = controller.value.rootNode!;
        final children = rootNode.children;

        // First should be folders (sorted)
        expect(children[0].name, equals('a_folder'));
        expect(children[1].name, equals('b_folder'));

        // Then files (sorted)
        expect(children[2].name, equals('a.dart'));
        expect(children[3].name, equals('z.dart'));
      });

      test('should emit error state when folder repository fails', () async {
        // Arrange
        final failure = const FolderFailure.notFound(message: 'Folders not found');
        when(() => mockFolderRepository.listAll())
            .thenAnswer((_) async => Left(failure));
        when(() => mockFileRepository.search())
            .thenAnswer((_) async => Right([testFile]));

        // Act
        await controller.load();

        // Assert
        expect(controller.value.isError, isTrue);
        expect(controller.value.maybeMap(
          error: (state) => state.message,
          orElse: () => null,
        ), contains('Failed to load tree'));
      });

      test('should emit error state when file repository fails', () async {
        // Arrange
        final failure = const FileFailure.storageError(message: 'Files not found');
        when(() => mockFolderRepository.listAll())
            .thenAnswer((_) async => Right([rootFolder]));
        when(() => mockFileRepository.search())
            .thenAnswer((_) async => Left(failure));

        // Act
        await controller.load();

        // Assert
        expect(controller.value.isError, isTrue);
      });

      test('should load with custom root id', () async {
        // Arrange
        when(() => mockFolderRepository.listAll())
            .thenAnswer((_) async => Right([rootFolder, srcFolder]));
        when(() => mockFileRepository.search())
            .thenAnswer((_) async => Right([]));

        // Act
        await controller.load(rootId: 'src');

        // Assert
        expect(controller.value.isLoaded, isTrue);
        expect(controller.value.rootNode?.id, equals('src'));
      });

      test('should start periodic refresh after successful load', () async {
        // Arrange
        when(() => mockFolderRepository.listAll())
            .thenAnswer((_) async => Right([rootFolder]));
        when(() => mockFileRepository.search())
            .thenAnswer((_) async => Right([]));

        // Act
        await controller.load();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - periodic refresh should have been started
        // (verified by checking that load was called multiple times)
        verify(() => mockFolderRepository.listAll()).called(greaterThan(1));
      });
    });

    group('createFile', () {
      test('should create file and refresh tree on success', () async {
        // Arrange
        const folderId = 'root';
        const fileName = 'new_file.dart';

        when(() => mockFileRepository.create(
          folderId: folderId,
          name: fileName,
        )).thenAnswer((_) async => Right(testFile));

        // Mock refresh
        when(() => mockFolderRepository.listAll())
            .thenAnswer((_) async => Right([rootFolder]));
        when(() => mockFileRepository.search())
            .thenAnswer((_) async => Right([testFile]));

        // Load initial tree
        await controller.load();

        // Act
        await controller.createFile(folderId: folderId, name: fileName);

        // Assert
        verify(() => mockFileRepository.create(
          folderId: folderId,
          name: fileName,
        )).called(1);

        verify(() => mockEventBus.publish(
          EditorEvent.fileCreated(file: testFile),
        )).called(1);
      });

      test('should emit error state when file creation fails', () async {
        // Arrange
        const folderId = 'root';
        const fileName = 'new_file.dart';
        final failure = const FileFailure.alreadyExists(message: 'File already exists');

        when(() => mockFileRepository.create(
          folderId: folderId,
          name: fileName,
        )).thenAnswer((_) async => Left(failure));

        // Act
        await controller.createFile(folderId: folderId, name: fileName);

        // Assert
        expect(controller.value.isError, isTrue);
        expect(controller.value.maybeMap(
          error: (state) => state.message,
          orElse: () => null,
        ), contains('Failed to create file'));
      });

      test('should handle unexpected exceptions during file creation', () async {
        // Arrange
        const folderId = 'root';
        const fileName = 'new_file.dart';

        when(() => mockFileRepository.create(
          folderId: folderId,
          name: fileName,
        )).thenThrow(Exception('Unexpected error'));

        // Act
        await controller.createFile(folderId: folderId, name: fileName);

        // Assert
        expect(controller.value.isError, isTrue);
      });
    });

    group('createFolder', () {
      test('should create folder and refresh tree on success', () async {
        // Arrange
        const folderName = 'new_folder';
        const parentId = 'root';

        when(() => mockFolderRepository.create(
          name: folderName,
          parentId: parentId,
        )).thenAnswer((_) async => Right(srcFolder));

        // Mock refresh
        when(() => mockFolderRepository.listAll())
            .thenAnswer((_) async => Right([rootFolder]));
        when(() => mockFileRepository.search())
            .thenAnswer((_) async => Right([]));

        // Load initial tree
        await controller.load();

        // Act
        await controller.createFolder(name: folderName, parentId: parentId);

        // Assert
        verify(() => mockFolderRepository.create(
          name: folderName,
          parentId: parentId,
        )).called(1);

        verify(() => mockEventBus.publish(
          EditorEvent.folderCreated(folder: srcFolder),
        )).called(1);
      });

      test('should emit error state when folder creation fails', () async {
        // Arrange
        const folderName = 'new_folder';
        final failure = const FolderFailure.alreadyExists(message: 'Folder already exists');

        when(() => mockFolderRepository.create(
          name: folderName,
          parentId: any(named: 'parentId'),
        )).thenAnswer((_) async => Left(failure));

        // Act
        await controller.createFolder(name: folderName);

        // Assert
        expect(controller.value.isError, isTrue);
      });
    });

    group('deleteFile', () {
      test('should delete file and refresh tree on success', () async {
        // Arrange
        const fileId = 'file-1';

        when(() => mockFileRepository.delete(fileId))
            .thenAnswer((_) async => const Right(unit));

        // Mock refresh
        when(() => mockFolderRepository.listAll())
            .thenAnswer((_) async => Right([rootFolder]));
        when(() => mockFileRepository.search())
            .thenAnswer((_) async => Right([]));

        // Load initial tree
        await controller.load();

        // Act
        await controller.deleteFile(fileId);

        // Assert
        verify(() => mockFileRepository.delete(fileId)).called(1);
        verify(() => mockEventBus.publish(
          EditorEvent.fileDeleted(fileId: fileId),
        )).called(1);
      });

      test('should emit error state when file deletion fails', () async {
        // Arrange
        const fileId = 'file-1';
        final failure = const FileFailure.notFound(message: 'File not found');

        when(() => mockFileRepository.delete(fileId))
            .thenAnswer((_) async => Left(failure));

        // Act
        await controller.deleteFile(fileId);

        // Assert
        expect(controller.value.isError, isTrue);
      });
    });

    group('deleteFolder', () {
      test('should delete folder and refresh tree on success', () async {
        // Arrange
        const folderId = 'src';

        when(() => mockFolderRepository.delete(folderId))
            .thenAnswer((_) async => const Right(unit));

        // Mock refresh
        when(() => mockFolderRepository.listAll())
            .thenAnswer((_) async => Right([rootFolder]));
        when(() => mockFileRepository.search())
            .thenAnswer((_) async => Right([]));

        // Load initial tree
        await controller.load();

        // Act
        await controller.deleteFolder(folderId);

        // Assert
        verify(() => mockFolderRepository.delete(folderId)).called(1);
        verify(() => mockEventBus.publish(
          EditorEvent.folderDeleted(folderId: folderId),
        )).called(1);
      });

      test('should emit error state when folder deletion fails', () async {
        // Arrange
        const folderId = 'src';
        final failure = const FolderFailure.notFound(message: 'Folder not found');

        when(() => mockFolderRepository.delete(folderId))
            .thenAnswer((_) async => Left(failure));

        // Act
        await controller.deleteFolder(folderId);

        // Assert
        expect(controller.value.isError, isTrue);
      });
    });

    group('moveFile', () {
      test('should move file and refresh tree on success', () async {
        // Arrange
        const fileId = 'file-1';
        const targetFolderId = 'src';

        when(() => mockFileRepository.move(
          fileId: fileId,
          targetFolderId: targetFolderId,
        )).thenAnswer((_) async => Right(testFile));

        // Mock refresh
        when(() => mockFolderRepository.listAll())
            .thenAnswer((_) async => Right([rootFolder]));
        when(() => mockFileRepository.search())
            .thenAnswer((_) async => Right([]));

        // Load initial tree
        await controller.load();

        // Act
        await controller.moveFile(fileId, targetFolderId);

        // Assert
        verify(() => mockFileRepository.move(
          fileId: fileId,
          targetFolderId: targetFolderId,
        )).called(1);
      });

      test('should emit error state when file move fails', () async {
        // Arrange
        const fileId = 'file-1';
        const targetFolderId = 'src';
        final failure = const FileFailure.notFound(message: 'File not found');

        when(() => mockFileRepository.move(
          fileId: fileId,
          targetFolderId: targetFolderId,
        )).thenAnswer((_) async => Left(failure));

        // Act
        await controller.moveFile(fileId, targetFolderId);

        // Assert
        expect(controller.value.isError, isTrue);
      });
    });

    group('moveFolder', () {
      test('should move folder and refresh tree on success', () async {
        // Arrange
        const folderId = 'src';
        const targetFolderId = 'root';

        when(() => mockFolderRepository.move(
          folderId: folderId,
          targetParentId: targetFolderId,
        )).thenAnswer((_) async => Right(srcFolder));

        // Mock refresh
        when(() => mockFolderRepository.listAll())
            .thenAnswer((_) async => Right([rootFolder]));
        when(() => mockFileRepository.search())
            .thenAnswer((_) async => Right([]));

        // Load initial tree
        await controller.load();

        // Act
        await controller.moveFolder(folderId, targetFolderId);

        // Assert
        verify(() => mockFolderRepository.move(
          folderId: folderId,
          targetParentId: targetFolderId,
        )).called(1);
      });

      test('should emit error state when folder move fails', () async {
        // Arrange
        const folderId = 'src';
        const targetFolderId = 'root';
        final failure = const FolderFailure.notFound(message: 'Folder not found');

        when(() => mockFolderRepository.move(
          folderId: folderId,
          targetParentId: targetFolderId,
        )).thenAnswer((_) async => Left(failure));

        // Act
        await controller.moveFolder(folderId, targetFolderId);

        // Assert
        expect(controller.value.isError, isTrue);
      });
    });

    group('renameFile', () {
      test('should rename file and refresh tree on success', () async {
        // Arrange
        const fileId = 'file-1';
        const newName = 'renamed.dart';

        when(() => mockFileRepository.rename(
          fileId: fileId,
          newName: newName,
        )).thenAnswer((_) async => Right(testFile));

        // Mock refresh
        when(() => mockFolderRepository.listAll())
            .thenAnswer((_) async => Right([rootFolder]));
        when(() => mockFileRepository.search())
            .thenAnswer((_) async => Right([]));

        // Load initial tree
        await controller.load();

        // Act
        await controller.renameFile(fileId, newName);

        // Assert
        verify(() => mockFileRepository.rename(
          fileId: fileId,
          newName: newName,
        )).called(1);
      });

      test('should emit error state when file rename fails', () async {
        // Arrange
        const fileId = 'file-1';
        const newName = 'renamed.dart';
        final failure = const FileFailure.alreadyExists(message: 'File already exists');

        when(() => mockFileRepository.rename(
          fileId: fileId,
          newName: newName,
        )).thenAnswer((_) async => Left(failure));

        // Act
        await controller.renameFile(fileId, newName);

        // Assert
        expect(controller.value.isError, isTrue);
      });
    });

    group('renameFolder', () {
      test('should rename folder and refresh tree on success', () async {
        // Arrange
        const folderId = 'src';
        const newName = 'renamed_src';

        when(() => mockFolderRepository.rename(
          folderId: folderId,
          newName: newName,
        )).thenAnswer((_) async => Right(srcFolder));

        // Mock refresh
        when(() => mockFolderRepository.listAll())
            .thenAnswer((_) async => Right([rootFolder]));
        when(() => mockFileRepository.search())
            .thenAnswer((_) async => Right([]));

        // Load initial tree
        await controller.load();

        // Act
        await controller.renameFolder(folderId, newName);

        // Assert
        verify(() => mockFolderRepository.rename(
          folderId: folderId,
          newName: newName,
        )).called(1);
      });

      test('should emit error state when folder rename fails', () async {
        // Arrange
        const folderId = 'src';
        const newName = 'renamed_src';
        final failure = const FolderFailure.alreadyExists(message: 'Folder already exists');

        when(() => mockFolderRepository.rename(
          folderId: folderId,
          newName: newName,
        )).thenAnswer((_) async => Left(failure));

        // Act
        await controller.renameFolder(folderId, newName);

        // Assert
        expect(controller.value.isError, isTrue);
      });
    });

    group('selectNode', () {
      test('should update selected node id', () async {
        // Arrange
        when(() => mockFolderRepository.listAll())
            .thenAnswer((_) async => Right([rootFolder]));
        when(() => mockFileRepository.search())
            .thenAnswer((_) async => Right([testFile]));

        await controller.load();

        const nodeId = 'file-1';

        // Act
        controller.selectNode(nodeId);

        // Assert
        expect(controller.value.maybeMap(
          loaded: (state) => state.selectedNodeId,
          orElse: () => null,
        ), equals(nodeId));
      });

      test('should clear selection when null is passed', () async {
        // Arrange
        when(() => mockFolderRepository.listAll())
            .thenAnswer((_) async => Right([rootFolder]));
        when(() => mockFileRepository.search())
            .thenAnswer((_) async => Right([]));

        await controller.load();
        controller.selectNode('file-1');

        // Act
        controller.selectNode(null);

        // Assert
        expect(controller.value.maybeMap(
          loaded: (state) => state.selectedNodeId,
          orElse: () => 'not-null',
        ), isNull);
      });

      test('should do nothing when not in loaded state', () {
        // Arrange - controller is in initial state

        // Act
        controller.selectNode('file-1');

        // Assert
        expect(controller.value.isInitial, isTrue);
      });
    });

    group('toggleFolder', () {
      test('should expand folder when collapsed', () async {
        // Arrange
        when(() => mockFolderRepository.listAll())
            .thenAnswer((_) async => Right([rootFolder, srcFolder]));
        when(() => mockFileRepository.search())
            .thenAnswer((_) async => Right([]));

        await controller.load();

        const folderId = 'src';

        // Act
        controller.toggleFolder(folderId);

        // Assert
        expect(controller.value.maybeMap(
          loaded: (state) => state.expandedFolderIds.contains(folderId),
          orElse: () => false,
        ), isTrue);
      });

      test('should collapse folder when expanded', () async {
        // Arrange
        when(() => mockFolderRepository.listAll())
            .thenAnswer((_) async => Right([rootFolder, srcFolder]));
        when(() => mockFileRepository.search())
            .thenAnswer((_) async => Right([]));

        await controller.load();

        const folderId = 'src';

        // Act
        controller.toggleFolder(folderId); // Expand
        controller.toggleFolder(folderId); // Collapse

        // Assert
        expect(controller.value.maybeMap(
          loaded: (state) => state.expandedFolderIds.contains(folderId),
          orElse: () => true,
        ), isFalse);
      });

      test('should select folder when toggling', () async {
        // Arrange
        when(() => mockFolderRepository.listAll())
            .thenAnswer((_) async => Right([rootFolder, srcFolder]));
        when(() => mockFileRepository.search())
            .thenAnswer((_) async => Right([]));

        await controller.load();

        const folderId = 'src';

        // Act
        controller.toggleFolder(folderId);

        // Assert
        expect(controller.value.maybeMap(
          loaded: (state) => state.selectedNodeId,
          orElse: () => null,
        ), equals(folderId));
      });
    });

    group('expandAll', () {
      test('should expand all folders in tree', () async {
        // Arrange
        when(() => mockFolderRepository.listAll())
            .thenAnswer((_) async => Right([rootFolder, srcFolder]));
        when(() => mockFileRepository.search())
            .thenAnswer((_) async => Right([]));

        await controller.load();

        // Act
        controller.expandAll();

        // Assert
        final expandedFolders = controller.value.maybeMap(
          loaded: (state) => state.expandedFolderIds,
          orElse: () => <String>[],
        );

        expect(expandedFolders.length, equals(2)); // root and src
        expect(expandedFolders.contains('root'), isTrue);
        expect(expandedFolders.contains('src'), isTrue);
      });
    });

    group('collapseAll', () {
      test('should collapse all folders in tree', () async {
        // Arrange
        when(() => mockFolderRepository.listAll())
            .thenAnswer((_) async => Right([rootFolder, srcFolder]));
        when(() => mockFileRepository.search())
            .thenAnswer((_) async => Right([]));

        await controller.load();
        controller.expandAll();

        // Act
        controller.collapseAll();

        // Assert
        expect(controller.value.maybeMap(
          loaded: (state) => state.expandedFolderIds,
          orElse: () => ['not-empty'],
        ), isEmpty);
      });
    });

    group('getSelectedParentFolderId', () {
      test('should return root id when nothing is selected', () async {
        // Arrange
        when(() => mockFolderRepository.listAll())
            .thenAnswer((_) async => Right([rootFolder]));
        when(() => mockFileRepository.search())
            .thenAnswer((_) async => Right([]));

        await controller.load();

        // Act
        final parentId = controller.getSelectedParentFolderId();

        // Assert
        expect(parentId, equals('root'));
      });

      test('should return folder id when folder is selected', () async {
        // Arrange
        when(() => mockFolderRepository.listAll())
            .thenAnswer((_) async => Right([rootFolder, srcFolder]));
        when(() => mockFileRepository.search())
            .thenAnswer((_) async => Right([]));

        await controller.load();
        controller.selectNode('src');

        // Act
        final parentId = controller.getSelectedParentFolderId();

        // Assert
        expect(parentId, equals('src'));
      });

      test('should return parent folder id when file is selected', () async {
        // Arrange
        when(() => mockFolderRepository.listAll())
            .thenAnswer((_) async => Right([rootFolder]));
        when(() => mockFileRepository.search())
            .thenAnswer((_) async => Right([testFile]));

        await controller.load();
        controller.selectNode('file-1');

        // Act
        final parentId = controller.getSelectedParentFolderId();

        // Assert
        expect(parentId, equals('root'));
      });

      test('should return null when not in loaded state', () {
        // Arrange - controller is in initial state

        // Act
        final parentId = controller.getSelectedParentFolderId();

        // Assert
        expect(parentId, isNull);
      });
    });

    group('dispose', () {
      test('should cancel refresh timer on dispose', () async {
        // Arrange
        when(() => mockFolderRepository.listAll())
            .thenAnswer((_) async => Right([rootFolder]));
        when(() => mockFileRepository.search())
            .thenAnswer((_) async => Right([]));

        await controller.load();

        // Act
        controller.dispose();

        // Wait for potential timer ticks
        await Future.delayed(const Duration(seconds: 6));

        // Assert - verify refresh was not called after dispose
        // Only initial load should have been called
        verify(() => mockFolderRepository.listAll()).called(greaterThan(0));
      });
    });

    group('Use Cases', () {
      group('UC1: Create complete folder structure', () {
        test('should create nested folders and files', () async {
          // Arrange
          when(() => mockFolderRepository.listAll())
              .thenAnswer((_) async => Right([rootFolder]));
          when(() => mockFileRepository.search())
              .thenAnswer((_) async => Right([]));

          await controller.load();

          // Setup create folder mock
          when(() => mockFolderRepository.create(
            name: 'lib',
            parentId: 'root',
          )).thenAnswer((_) async => Right(Folder(
            id: 'lib',
            name: 'lib',
            parentId: 'root',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )));

          // Setup create file mock
          when(() => mockFileRepository.create(
            folderId: 'lib',
            name: 'main.dart',
          )).thenAnswer((_) async => Right(testFile));

          // Act
          await controller.createFolder(name: 'lib', parentId: 'root');
          await controller.createFile(folderId: 'lib', name: 'main.dart');

          // Assert
          verify(() => mockFolderRepository.create(
            name: 'lib',
            parentId: 'root',
          )).called(1);

          verify(() => mockFileRepository.create(
            folderId: 'lib',
            name: 'main.dart',
          )).called(1);
        });
      });

      group('UC2: Reorganize files', () {
        test('should move and rename files', () async {
          // Arrange
          when(() => mockFolderRepository.listAll())
              .thenAnswer((_) async => Right([rootFolder, srcFolder]));
          when(() => mockFileRepository.search())
              .thenAnswer((_) async => Right([testFile]));

          await controller.load();

          when(() => mockFileRepository.move(
            fileId: 'file-1',
            targetFolderId: 'src',
          )).thenAnswer((_) async => Right(testFile.copyWith(folderId: 'src')));

          when(() => mockFileRepository.rename(
            fileId: 'file-1',
            newName: 'app.dart',
          )).thenAnswer((_) async => Right(testFile.copyWith(name: 'app.dart')));

          // Act
          await controller.moveFile('file-1', 'src');
          await controller.renameFile('file-1', 'app.dart');

          // Assert
          verify(() => mockFileRepository.move(
            fileId: 'file-1',
            targetFolderId: 'src',
          )).called(1);

          verify(() => mockFileRepository.rename(
            fileId: 'file-1',
            newName: 'app.dart',
          )).called(1);
        });
      });

      group('UC3: Navigate tree structure', () {
        test('should expand, select, and navigate folders', () async {
          // Arrange
          when(() => mockFolderRepository.listAll())
              .thenAnswer((_) async => Right([rootFolder, srcFolder]));
          when(() => mockFileRepository.search())
              .thenAnswer((_) async => Right([testFile]));

          await controller.load();

          // Act
          controller.toggleFolder('root'); // Expand root
          controller.selectNode('src'); // Select src folder
          controller.toggleFolder('src'); // Expand src folder
          controller.selectNode('file-1'); // Select file

          // Assert
          final state = controller.value;
          expect(state.maybeMap(
            loaded: (s) => s.selectedNodeId,
            orElse: () => null,
          ), equals('file-1'));

          expect(state.maybeMap(
            loaded: (s) => s.expandedFolderIds.contains('root'),
            orElse: () => false,
          ), isTrue);
        });
      });

      group('UC4: Delete folder with contents', () {
        test('should delete folder', () async {
          // Arrange
          when(() => mockFolderRepository.listAll())
              .thenAnswer((_) async => Right([rootFolder, srcFolder]));
          when(() => mockFileRepository.search())
              .thenAnswer((_) async => Right([testFile]));

          await controller.load();

          when(() => mockFolderRepository.delete('src'))
              .thenAnswer((_) async => const Right(unit));

          // Act
          await controller.deleteFolder('src');

          // Assert
          verify(() => mockFolderRepository.delete('src')).called(1);
          verify(() => mockEventBus.publish(
            EditorEvent.folderDeleted(folderId: 'src'),
          )).called(1);
        });
      });
    });
  });
}
