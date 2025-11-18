import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_core/src/domain/entities/file_tree_node.dart';

void main() {
  group('FileTreeNode', () {
    group('factory constructors', () {
      test('should create file node', () {
        // Arrange & Act
        final node = FileTreeNode.file(
          id: 'file-1',
          name: 'main.dart',
          language: 'dart',
        );

        // Assert
        expect(node.id, equals('file-1'));
        expect(node.name, equals('main.dart'));
        expect(node.type, equals(FileTreeNodeType.file));
        expect(node.language, equals('dart'));
        expect(node.isFile, isTrue);
        expect(node.isFolder, isFalse);
        expect(node.children, isEmpty);
      });

      test('should create file node with parent', () {
        // Arrange & Act
        final node = FileTreeNode.file(
          id: 'file-1',
          name: 'main.dart',
          parentId: 'folder-1',
        );

        // Assert
        expect(node.parentId, equals('folder-1'));
      });

      test('should create file node with metadata', () {
        // Arrange & Act
        final node = FileTreeNode.file(
          id: 'file-1',
          name: 'main.dart',
          metadata: {'readonly': true},
        );

        // Assert
        expect(node.metadata, isNotEmpty);
        expect(node.metadata['readonly'], equals(true));
      });

      test('should create folder node', () {
        // Arrange & Act
        final node = FileTreeNode.folder(
          id: 'folder-1',
          name: 'lib',
        );

        // Assert
        expect(node.id, equals('folder-1'));
        expect(node.name, equals('lib'));
        expect(node.type, equals(FileTreeNodeType.folder));
        expect(node.isFolder, isTrue);
        expect(node.isFile, isFalse);
        expect(node.children, isEmpty);
        expect(node.isExpanded, isFalse);
      });

      test('should create folder node with children', () {
        // Arrange
        final file = FileTreeNode.file(id: 'file-1', name: 'main.dart');

        // Act
        final node = FileTreeNode.folder(
          id: 'folder-1',
          name: 'lib',
          children: [file],
        );

        // Assert
        expect(node.children, hasLength(1));
        expect(node.hasChildren, isTrue);
      });

      test('should create expanded folder', () {
        // Arrange & Act
        final node = FileTreeNode.folder(
          id: 'folder-1',
          name: 'lib',
          isExpanded: true,
        );

        // Assert
        expect(node.isExpanded, isTrue);
      });
    });

    group('isFile and isFolder', () {
      test('should detect file type', () {
        // Arrange
        final node = FileTreeNode.file(id: '1', name: 'file.txt');

        // Act & Assert
        expect(node.isFile, isTrue);
        expect(node.isFolder, isFalse);
      });

      test('should detect folder type', () {
        // Arrange
        final node = FileTreeNode.folder(id: '1', name: 'folder');

        // Act & Assert
        expect(node.isFolder, isTrue);
        expect(node.isFile, isFalse);
      });
    });

    group('hasChildren and childrenCount', () {
      test('should detect node with no children', () {
        // Arrange
        final node = FileTreeNode.folder(id: '1', name: 'folder');

        // Act & Assert
        expect(node.hasChildren, isFalse);
        expect(node.childrenCount, equals(0));
      });

      test('should detect node with children', () {
        // Arrange
        final child1 = FileTreeNode.file(id: 'f1', name: 'file1.dart');
        final child2 = FileTreeNode.file(id: 'f2', name: 'file2.dart');
        final node = FileTreeNode.folder(
          id: '1',
          name: 'folder',
          children: [child1, child2],
        );

        // Act & Assert
        expect(node.hasChildren, isTrue);
        expect(node.childrenCount, equals(2));
      });
    });

    group('depth', () {
      test('should return 0 for node with no children', () {
        // Arrange
        final node = FileTreeNode.folder(id: '1', name: 'folder');

        // Act
        final depth = node.depth;

        // Assert
        expect(depth, equals(0));
      });

      test('should calculate depth for single level', () {
        // Arrange
        final file = FileTreeNode.file(id: 'f1', name: 'file.dart');
        final node = FileTreeNode.folder(
          id: '1',
          name: 'folder',
          children: [file],
        );

        // Act
        final depth = node.depth;

        // Assert
        expect(depth, equals(1));
      });

      test('should calculate depth for nested structure', () {
        // Arrange
        final deepFile = FileTreeNode.file(id: 'f1', name: 'deep.dart');
        final subFolder = FileTreeNode.folder(
          id: 'sub',
          name: 'sub',
          children: [deepFile],
        );
        final node = FileTreeNode.folder(
          id: 'root',
          name: 'root',
          children: [subFolder],
        );

        // Act
        final depth = node.depth;

        // Assert
        expect(depth, equals(2));
      });

      test('should return max depth for multiple branches', () {
        // Arrange
        final shallowFile = FileTreeNode.file(id: 'f1', name: 'file.dart');
        final deepFile = FileTreeNode.file(id: 'f2', name: 'deep.dart');
        final deepFolder = FileTreeNode.folder(
          id: 'deep',
          name: 'deep',
          children: [deepFile],
        );
        final node = FileTreeNode.folder(
          id: 'root',
          name: 'root',
          children: [shallowFile, deepFolder],
        );

        // Act
        final depth = node.depth;

        // Assert
        expect(depth, equals(2));
      });
    });

    group('toggleExpanded', () {
      test('should expand collapsed folder', () {
        // Arrange
        final node = FileTreeNode.folder(
          id: '1',
          name: 'folder',
          isExpanded: false,
        );

        // Act
        final toggled = node.toggleExpanded();

        // Assert
        expect(toggled.isExpanded, isTrue);
      });

      test('should collapse expanded folder', () {
        // Arrange
        final node = FileTreeNode.folder(
          id: '1',
          name: 'folder',
          isExpanded: true,
        );

        // Act
        final toggled = node.toggleExpanded();

        // Assert
        expect(toggled.isExpanded, isFalse);
      });

      test('should not modify original node', () {
        // Arrange
        final node = FileTreeNode.folder(
          id: '1',
          name: 'folder',
          isExpanded: false,
        );

        // Act
        node.toggleExpanded();

        // Assert
        expect(node.isExpanded, isFalse);
      });
    });

    group('addChild', () {
      test('should add child to folder', () {
        // Arrange
        final folder = FileTreeNode.folder(id: '1', name: 'folder');
        final file = FileTreeNode.file(id: 'f1', name: 'file.dart');

        // Act
        final updated = folder.addChild(file);

        // Assert
        expect(updated.children, hasLength(1));
        expect(updated.children.first.id, equals('f1'));
        expect(updated.children.first.parentId, equals('1'));
      });

      test('should set parent ID on child', () {
        // Arrange
        final folder = FileTreeNode.folder(id: 'folder-1', name: 'lib');
        final file = FileTreeNode.file(id: 'file-1', name: 'main.dart');

        // Act
        final updated = folder.addChild(file);

        // Assert
        expect(updated.children.first.parentId, equals('folder-1'));
      });

      test('should not modify original node', () {
        // Arrange
        final folder = FileTreeNode.folder(id: '1', name: 'folder');
        final file = FileTreeNode.file(id: 'f1', name: 'file.dart');

        // Act
        folder.addChild(file);

        // Assert
        expect(folder.children, isEmpty);
      });

      test('should add multiple children', () {
        // Arrange
        final folder = FileTreeNode.folder(id: '1', name: 'folder');
        final file1 = FileTreeNode.file(id: 'f1', name: 'file1.dart');
        final file2 = FileTreeNode.file(id: 'f2', name: 'file2.dart');

        // Act
        final updated = folder.addChild(file1).addChild(file2);

        // Assert
        expect(updated.children, hasLength(2));
      });
    });

    group('removeChild', () {
      test('should remove child by ID', () {
        // Arrange
        final file1 = FileTreeNode.file(id: 'f1', name: 'file1.dart');
        final file2 = FileTreeNode.file(id: 'f2', name: 'file2.dart');
        final folder = FileTreeNode.folder(
          id: '1',
          name: 'folder',
          children: [file1, file2],
        );

        // Act
        final updated = folder.removeChild('f1');

        // Assert
        expect(updated.children, hasLength(1));
        expect(updated.children.first.id, equals('f2'));
      });

      test('should not modify original node', () {
        // Arrange
        final file = FileTreeNode.file(id: 'f1', name: 'file.dart');
        final folder = FileTreeNode.folder(
          id: '1',
          name: 'folder',
          children: [file],
        );

        // Act
        folder.removeChild('f1');

        // Assert
        expect(folder.children, hasLength(1));
      });

      test('should do nothing if child not found', () {
        // Arrange
        final file = FileTreeNode.file(id: 'f1', name: 'file.dart');
        final folder = FileTreeNode.folder(
          id: '1',
          name: 'folder',
          children: [file],
        );

        // Act
        final updated = folder.removeChild('non-existent');

        // Assert
        expect(updated.children, hasLength(1));
      });
    });

    group('updateChild', () {
      test('should update child node', () {
        // Arrange
        final file = FileTreeNode.file(id: 'f1', name: 'old.dart');
        final folder = FileTreeNode.folder(
          id: '1',
          name: 'folder',
          children: [file],
        );
        final updatedFile = file.copyWith(name: 'new.dart');

        // Act
        final updated = folder.updateChild(updatedFile);

        // Assert
        expect(updated.children.first.name, equals('new.dart'));
      });

      test('should not modify original node', () {
        // Arrange
        final file = FileTreeNode.file(id: 'f1', name: 'old.dart');
        final folder = FileTreeNode.folder(
          id: '1',
          name: 'folder',
          children: [file],
        );
        final updatedFile = file.copyWith(name: 'new.dart');

        // Act
        folder.updateChild(updatedFile);

        // Assert
        expect(folder.children.first.name, equals('old.dart'));
      });

      test('should update only matching child', () {
        // Arrange
        final file1 = FileTreeNode.file(id: 'f1', name: 'file1.dart');
        final file2 = FileTreeNode.file(id: 'f2', name: 'file2.dart');
        final folder = FileTreeNode.folder(
          id: '1',
          name: 'folder',
          children: [file1, file2],
        );
        final updatedFile1 = file1.copyWith(name: 'updated.dart');

        // Act
        final updated = folder.updateChild(updatedFile1);

        // Assert
        expect(updated.children[0].name, equals('updated.dart'));
        expect(updated.children[1].name, equals('file2.dart'));
      });
    });

    group('findNode', () {
      test('should find itself', () {
        // Arrange
        final node = FileTreeNode.folder(id: '1', name: 'folder');

        // Act
        final found = node.findNode('1');

        // Assert
        expect(found, equals(node));
      });

      test('should find direct child', () {
        // Arrange
        final file = FileTreeNode.file(id: 'f1', name: 'file.dart');
        final folder = FileTreeNode.folder(
          id: '1',
          name: 'folder',
          children: [file],
        );

        // Act
        final found = folder.findNode('f1');

        // Assert
        expect(found, isNotNull);
        expect(found!.id, equals('f1'));
      });

      test('should find nested child', () {
        // Arrange
        final deepFile = FileTreeNode.file(id: 'deep', name: 'deep.dart');
        final subFolder = FileTreeNode.folder(
          id: 'sub',
          name: 'sub',
          children: [deepFile],
        );
        final root = FileTreeNode.folder(
          id: 'root',
          name: 'root',
          children: [subFolder],
        );

        // Act
        final found = root.findNode('deep');

        // Assert
        expect(found, isNotNull);
        expect(found!.id, equals('deep'));
      });

      test('should return null if not found', () {
        // Arrange
        final node = FileTreeNode.folder(id: '1', name: 'folder');

        // Act
        final found = node.findNode('non-existent');

        // Assert
        expect(found, isNull);
      });
    });

    group('flatten', () {
      test('should flatten single node', () {
        // Arrange
        final node = FileTreeNode.folder(id: '1', name: 'folder');

        // Act
        final flattened = node.flatten();

        // Assert
        expect(flattened, hasLength(1));
        expect(flattened.first.id, equals('1'));
      });

      test('should flatten node with children', () {
        // Arrange
        final file1 = FileTreeNode.file(id: 'f1', name: 'file1.dart');
        final file2 = FileTreeNode.file(id: 'f2', name: 'file2.dart');
        final folder = FileTreeNode.folder(
          id: '1',
          name: 'folder',
          children: [file1, file2],
        );

        // Act
        final flattened = folder.flatten();

        // Assert
        expect(flattened, hasLength(3));
        expect(flattened.map((n) => n.id), containsAll(['1', 'f1', 'f2']));
      });

      test('should flatten nested structure', () {
        // Arrange
        final deepFile = FileTreeNode.file(id: 'deep', name: 'deep.dart');
        final subFolder = FileTreeNode.folder(
          id: 'sub',
          name: 'sub',
          children: [deepFile],
        );
        final root = FileTreeNode.folder(
          id: 'root',
          name: 'root',
          children: [subFolder],
        );

        // Act
        final flattened = root.flatten();

        // Assert
        expect(flattened, hasLength(3));
        expect(flattened.map((n) => n.id), containsAll(['root', 'sub', 'deep']));
      });
    });

    group('allFiles', () {
      test('should return empty list for folder without files', () {
        // Arrange
        final folder = FileTreeNode.folder(id: '1', name: 'folder');

        // Act
        final files = folder.allFiles;

        // Assert
        expect(files, isEmpty);
      });

      test('should return file itself', () {
        // Arrange
        final file = FileTreeNode.file(id: 'f1', name: 'file.dart');

        // Act
        final files = file.allFiles;

        // Assert
        expect(files, hasLength(1));
        expect(files.first.id, equals('f1'));
      });

      test('should return all files from folder', () {
        // Arrange
        final file1 = FileTreeNode.file(id: 'f1', name: 'file1.dart');
        final file2 = FileTreeNode.file(id: 'f2', name: 'file2.dart');
        final folder = FileTreeNode.folder(
          id: '1',
          name: 'folder',
          children: [file1, file2],
        );

        // Act
        final files = folder.allFiles;

        // Assert
        expect(files, hasLength(2));
        expect(files.map((f) => f.id), containsAll(['f1', 'f2']));
      });

      test('should return files from nested structure', () {
        // Arrange
        final file1 = FileTreeNode.file(id: 'f1', name: 'file1.dart');
        final file2 = FileTreeNode.file(id: 'f2', name: 'file2.dart');
        final subFolder = FileTreeNode.folder(
          id: 'sub',
          name: 'sub',
          children: [file2],
        );
        final root = FileTreeNode.folder(
          id: 'root',
          name: 'root',
          children: [file1, subFolder],
        );

        // Act
        final files = root.allFiles;

        // Assert
        expect(files, hasLength(2));
        expect(files.map((f) => f.id), containsAll(['f1', 'f2']));
      });

      test('should not include folders', () {
        // Arrange
        final file = FileTreeNode.file(id: 'f1', name: 'file.dart');
        final subFolder = FileTreeNode.folder(
          id: 'sub',
          name: 'sub',
          children: [file],
        );
        final root = FileTreeNode.folder(
          id: 'root',
          name: 'root',
          children: [subFolder],
        );

        // Act
        final files = root.allFiles;

        // Assert
        expect(files, hasLength(1));
        expect(files.every((n) => n.isFile), isTrue);
      });
    });

    group('allFolders', () {
      test('should return folder itself', () {
        // Arrange
        final folder = FileTreeNode.folder(id: '1', name: 'folder');

        // Act
        final folders = folder.allFolders;

        // Assert
        expect(folders, hasLength(1));
        expect(folders.first.id, equals('1'));
      });

      test('should return empty list for file', () {
        // Arrange
        final file = FileTreeNode.file(id: 'f1', name: 'file.dart');

        // Act
        final folders = file.allFolders;

        // Assert
        expect(folders, isEmpty);
      });

      test('should return all folders from nested structure', () {
        // Arrange
        final file = FileTreeNode.file(id: 'f1', name: 'file.dart');
        final subFolder = FileTreeNode.folder(
          id: 'sub',
          name: 'sub',
          children: [file],
        );
        final root = FileTreeNode.folder(
          id: 'root',
          name: 'root',
          children: [subFolder],
        );

        // Act
        final folders = root.allFolders;

        // Assert
        expect(folders, hasLength(2));
        expect(folders.map((f) => f.id), containsAll(['root', 'sub']));
      });

      test('should not include files', () {
        // Arrange
        final file = FileTreeNode.file(id: 'f1', name: 'file.dart');
        final folder = FileTreeNode.folder(
          id: '1',
          name: 'folder',
          children: [file],
        );

        // Act
        final folders = folder.allFolders;

        // Assert
        expect(folders, hasLength(1));
        expect(folders.every((n) => n.isFolder), isTrue);
      });
    });

    group('use cases', () {
      test('should represent typical project structure', () {
        // Arrange - Build tree
        final mainDart = FileTreeNode.file(
          id: 'main',
          name: 'main.dart',
          language: 'dart',
        );
        final testDart = FileTreeNode.file(
          id: 'test',
          name: 'app_test.dart',
          language: 'dart',
        );
        final libFolder = FileTreeNode.folder(
          id: 'lib',
          name: 'lib',
          children: [mainDart],
        );
        final testFolder = FileTreeNode.folder(
          id: 'test-folder',
          name: 'test',
          children: [testDart],
        );
        final root = FileTreeNode.folder(
          id: 'root',
          name: 'my_app',
          children: [libFolder, testFolder],
        );

        // Assert
        expect(root.childrenCount, equals(2));
        expect(root.allFiles, hasLength(2));
        expect(root.allFolders, hasLength(3)); // root, lib, test
        expect(root.depth, equals(2));

        // Act - Find specific file
        final found = root.findNode('main');
        expect(found, isNotNull);
        expect(found!.name, equals('main.dart'));
      });

      test('should handle tree manipulation', () {
        // Arrange - Start with empty folder
        var folder = FileTreeNode.folder(id: 'lib', name: 'lib');
        expect(folder.hasChildren, isFalse);

        // Act - Add files
        final file1 = FileTreeNode.file(id: 'f1', name: 'file1.dart');
        folder = folder.addChild(file1);
        expect(folder.childrenCount, equals(1));

        final file2 = FileTreeNode.file(id: 'f2', name: 'file2.dart');
        folder = folder.addChild(file2);
        expect(folder.childrenCount, equals(2));

        // Act - Remove file
        folder = folder.removeChild('f1');
        expect(folder.childrenCount, equals(1));
        expect(folder.children.first.id, equals('f2'));

        // Act - Update file
        final updatedFile = file2.copyWith(name: 'renamed.dart');
        folder = folder.updateChild(updatedFile);
        expect(folder.children.first.name, equals('renamed.dart'));
      });
    });
  });
}
