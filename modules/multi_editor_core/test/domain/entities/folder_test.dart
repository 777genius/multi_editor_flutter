import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_core/src/domain/entities/folder.dart';

void main() {
  group('Folder', () {
    late DateTime now;

    setUp(() {
      now = DateTime.now();
    });

    group('creation', () {
      test('should create folder with required fields', () {
        // Arrange & Act
        final folder = Folder(
          id: 'folder-1',
          name: 'src',
          createdAt: now,
          updatedAt: now,
        );

        // Assert
        expect(folder.id, equals('folder-1'));
        expect(folder.name, equals('src'));
        expect(folder.parentId, isNull);
        expect(folder.createdAt, equals(now));
        expect(folder.updatedAt, equals(now));
        expect(folder.metadata, isEmpty);
      });

      test('should create folder with parent', () {
        // Arrange & Act
        final folder = Folder(
          id: 'folder-2',
          name: 'lib',
          parentId: 'folder-1',
          createdAt: now,
          updatedAt: now,
        );

        // Assert
        expect(folder.parentId, equals('folder-1'));
        expect(folder.isRoot, isFalse);
      });

      test('should create root folder', () {
        // Arrange & Act
        final folder = Folder(
          id: 'root',
          name: 'project',
          createdAt: now,
          updatedAt: now,
        );

        // Assert
        expect(folder.parentId, isNull);
        expect(folder.isRoot, isTrue);
      });

      test('should create folder with metadata', () {
        // Arrange & Act
        final folder = Folder(
          id: 'folder-1',
          name: 'src',
          createdAt: now,
          updatedAt: now,
          metadata: {'color': 'blue', 'icon': 'folder'},
        );

        // Assert
        expect(folder.metadata, isNotEmpty);
        expect(folder.metadata['color'], equals('blue'));
        expect(folder.metadata['icon'], equals('folder'));
      });
    });

    group('rename', () {
      test('should rename folder', () {
        // Arrange
        final folder = Folder(
          id: 'folder-1',
          name: 'old_name',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final renamed = folder.rename('new_name');

        // Assert
        expect(renamed.name, equals('new_name'));
        expect(renamed.id, equals(folder.id));
        expect(renamed.updatedAt.isAfter(folder.updatedAt), isTrue);
      });

      test('should not modify original folder', () {
        // Arrange
        final folder = Folder(
          id: 'folder-1',
          name: 'old_name',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        folder.rename('new_name');

        // Assert
        expect(folder.name, equals('old_name'));
      });
    });

    group('move', () {
      test('should move folder to different parent', () {
        // Arrange
        final folder = Folder(
          id: 'folder-1',
          name: 'lib',
          parentId: 'parent-1',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final moved = folder.move('parent-2');

        // Assert
        expect(moved.parentId, equals('parent-2'));
        expect(moved.id, equals(folder.id));
        expect(moved.name, equals(folder.name));
        expect(moved.updatedAt.isAfter(folder.updatedAt), isTrue);
      });

      test('should move folder to root', () {
        // Arrange
        final folder = Folder(
          id: 'folder-1',
          name: 'lib',
          parentId: 'parent-1',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final moved = folder.move(null);

        // Assert
        expect(moved.parentId, isNull);
        expect(moved.isRoot, isTrue);
      });

      test('should not modify original folder', () {
        // Arrange
        final folder = Folder(
          id: 'folder-1',
          name: 'lib',
          parentId: 'parent-1',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        folder.move('parent-2');

        // Assert
        expect(folder.parentId, equals('parent-1'));
      });
    });

    group('isRoot', () {
      test('should detect root folder', () {
        // Arrange
        final folder = Folder(
          id: 'root',
          name: 'project',
          createdAt: now,
          updatedAt: now,
        );

        // Act & Assert
        expect(folder.isRoot, isTrue);
      });

      test('should detect non-root folder', () {
        // Arrange
        final folder = Folder(
          id: 'folder-1',
          name: 'lib',
          parentId: 'root',
          createdAt: now,
          updatedAt: now,
        );

        // Act & Assert
        expect(folder.isRoot, isFalse);
      });
    });

    group('path', () {
      test('should return root path for root folder', () {
        // Arrange
        final folder = Folder(
          id: 'root',
          name: 'project',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final path = folder.path;

        // Assert
        expect(path, equals('/'));
      });

      test('should return name with slash for non-root folder', () {
        // Arrange
        final folder = Folder(
          id: 'folder-1',
          name: 'lib',
          parentId: 'root',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final path = folder.path;

        // Assert
        expect(path, equals('/lib'));
      });
    });

    group('copyWith', () {
      test('should copy with new name', () {
        // Arrange
        final folder = Folder(
          id: 'folder-1',
          name: 'old',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final copied = folder.copyWith(name: 'new');

        // Assert
        expect(copied.name, equals('new'));
        expect(copied.id, equals(folder.id));
      });

      test('should copy with new metadata', () {
        // Arrange
        final folder = Folder(
          id: 'folder-1',
          name: 'src',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final copied = folder.copyWith(metadata: {'color': 'red'});

        // Assert
        expect(copied.metadata['color'], equals('red'));
      });
    });

    group('equality', () {
      test('should be equal with same data', () {
        // Arrange
        final folder1 = Folder(
          id: 'folder-1',
          name: 'lib',
          createdAt: now,
          updatedAt: now,
        );

        final folder2 = Folder(
          id: 'folder-1',
          name: 'lib',
          createdAt: now,
          updatedAt: now,
        );

        // Act & Assert
        expect(folder1, equals(folder2));
      });

      test('should not be equal with different IDs', () {
        // Arrange
        final folder1 = Folder(
          id: 'folder-1',
          name: 'lib',
          createdAt: now,
          updatedAt: now,
        );

        final folder2 = Folder(
          id: 'folder-2',
          name: 'lib',
          createdAt: now,
          updatedAt: now,
        );

        // Act & Assert
        expect(folder1, isNot(equals(folder2)));
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON', () {
        // Arrange
        final folder = Folder(
          id: 'folder-1',
          name: 'lib',
          parentId: 'root',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final json = folder.toJson();

        // Assert
        expect(json['id'], equals('folder-1'));
        expect(json['name'], equals('lib'));
        expect(json['parentId'], equals('root'));
      });

      test('should deserialize from JSON', () {
        // Arrange
        final json = {
          'id': 'folder-1',
          'name': 'lib',
          'parentId': 'root',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'metadata': {},
        };

        // Act
        final folder = Folder.fromJson(json);

        // Assert
        expect(folder.id, equals('folder-1'));
        expect(folder.name, equals('lib'));
        expect(folder.parentId, equals('root'));
      });
    });

    group('use cases', () {
      test('should represent typical project folder structure', () {
        // Arrange - Root folder
        final root = Folder(
          id: 'root',
          name: 'my_project',
          createdAt: now,
          updatedAt: now,
        );

        expect(root.isRoot, isTrue);
        expect(root.path, equals('/'));

        // Act - Create lib folder
        final lib = Folder(
          id: 'lib',
          name: 'lib',
          parentId: root.id,
          createdAt: now,
          updatedAt: now,
        );

        // Assert
        expect(lib.isRoot, isFalse);
        expect(lib.parentId, equals(root.id));
        expect(lib.path, equals('/lib'));
      });

      test('should handle folder operations workflow', () {
        // Arrange - Create folder
        final folder = Folder(
          id: 'folder-1',
          name: 'old_folder',
          parentId: 'root',
          createdAt: now,
          updatedAt: now,
        );

        // Act - Rename folder
        final renamed = folder.rename('new_folder');
        expect(renamed.name, equals('new_folder'));

        // Act - Move to different parent
        final moved = renamed.move('parent-2');
        expect(moved.parentId, equals('parent-2'));

        // Act - Move to root
        final movedToRoot = moved.move(null);
        expect(movedToRoot.isRoot, isTrue);
      });
    });
  });
}
