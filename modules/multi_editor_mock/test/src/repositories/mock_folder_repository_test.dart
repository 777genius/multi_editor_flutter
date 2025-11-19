import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_mock/multi_editor_mock.dart';

void main() {
  group('MockFolderRepository', () {
    late MockFolderRepository repository;

    setUp(() {
      repository = MockFolderRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    group('initialization', () {
      test('should initialize with root folder', () async {
        // Act
        final result = await repository.getRoot();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (root) {
            expect(root.id, equals('root'));
            expect(root.name, equals('root'));
            expect(root.parentId, isNull);
          },
        );
      });

      test('should include root in listAll', () async {
        // Act
        final result = await repository.listAll();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (folders) {
            expect(folders.length, equals(1));
            expect(folders.first.id, equals('root'));
          },
        );
      });
    });

    group('create', () {
      test('should create a new folder with all parameters', () async {
        // Arrange
        const name = 'src';
        const parentId = 'root';
        final metadata = {'type': 'source'};

        // Act
        final result = await repository.create(
          name: name,
          parentId: parentId,
          metadata: metadata,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left: $failure'),
          (folder) {
            expect(folder.id, isNotEmpty);
            expect(folder.name, equals(name));
            expect(folder.parentId, equals(parentId));
            expect(folder.metadata, equals(metadata));
            expect(folder.createdAt, isNotNull);
            expect(folder.updatedAt, isNotNull);
          },
        );
      });

      test('should create folder with default values when optional params omitted',
          () async {
        // Arrange
        const name = 'test_folder';

        // Act
        final result = await repository.create(name: name);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (folder) {
            expect(folder.parentId, isNull);
            expect(folder.metadata, equals({}));
          },
        );
      });

      test('should generate unique IDs for multiple folders', () async {
        // Arrange & Act
        final result1 = await repository.create(name: 'folder1');
        final result2 = await repository.create(name: 'folder2');
        final result3 = await repository.create(name: 'folder3');

        // Assert
        final id1 = result1.getOrElse(() => throw Exception());
        final id2 = result2.getOrElse(() => throw Exception());
        final id3 = result3.getOrElse(() => throw Exception());

        expect(id1.id, isNot(equals(id2.id)));
        expect(id2.id, isNot(equals(id3.id)));
        expect(id1.id, isNot(equals(id3.id)));
      });

      test('should create folder under root', () async {
        // Arrange
        const name = 'lib';

        // Act
        final result = await repository.create(
          name: name,
          parentId: 'root',
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (folder) {
            expect(folder.parentId, equals('root'));
          },
        );
      });

      test('should create nested folders', () async {
        // Arrange
        final parent = await repository.create(
          name: 'parent',
          parentId: 'root',
        );
        final parentId = parent.getOrElse(() => throw Exception()).id;

        // Act
        final result = await repository.create(
          name: 'child',
          parentId: parentId,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (folder) {
            expect(folder.parentId, equals(parentId));
          },
        );
      });

      test('should simulate async delay', () async {
        // Arrange
        final stopwatch = Stopwatch()..start();

        // Act
        await repository.create(name: 'test');

        stopwatch.stop();

        // Assert - should take at least 50ms
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(40));
      });
    });

    group('load', () {
      test('should load existing folder by ID', () async {
        // Arrange
        final created = await repository.create(
          name: 'src',
          parentId: 'root',
        );
        final folderId = created.getOrElse(() => throw Exception()).id;

        // Act
        final result = await repository.load(folderId);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (folder) {
            expect(folder.id, equals(folderId));
            expect(folder.name, equals('src'));
            expect(folder.parentId, equals('root'));
          },
        );
      });

      test('should load root folder', () async {
        // Act
        final result = await repository.load('root');

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (folder) {
            expect(folder.id, equals('root'));
            expect(folder.name, equals('root'));
          },
        );
      });

      test('should return not found failure for non-existent folder', () async {
        // Arrange
        const nonExistentId = 'folder_999';

        // Act
        final result = await repository.load(nonExistentId);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<DomainFailure>());
            expect(failure.type, equals(FailureType.notFound));
            expect(failure.entityType, equals('Folder'));
            expect(failure.entityId, equals(nonExistentId));
          },
          (folder) => fail('Expected Left but got Right'),
        );
      });

      test('should load folder with all properties intact', () async {
        // Arrange
        final metadata = {'key': 'value', 'number': 42};
        final created = await repository.create(
          name: 'test_folder',
          parentId: 'root',
          metadata: metadata,
        );
        final original = created.getOrElse(() => throw Exception());

        // Act
        final result = await repository.load(original.id);

        // Assert
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (loaded) {
            expect(loaded.id, equals(original.id));
            expect(loaded.name, equals(original.name));
            expect(loaded.parentId, equals(original.parentId));
            expect(loaded.metadata, equals(original.metadata));
            expect(loaded.createdAt, equals(original.createdAt));
            expect(loaded.updatedAt, equals(original.updatedAt));
          },
        );
      });
    });

    group('delete', () {
      test('should delete existing folder', () async {
        // Arrange
        final created = await repository.create(name: 'temp');
        final folderId = created.getOrElse(() => throw Exception()).id;

        // Act
        final deleteResult = await repository.delete(folderId);

        // Assert
        expect(deleteResult.isRight(), isTrue);

        final loadResult = await repository.load(folderId);
        expect(loadResult.isLeft(), isTrue);
      });

      test('should return not found failure for non-existent folder', () async {
        // Arrange
        const nonExistentId = 'folder_999';

        // Act
        final result = await repository.delete(nonExistentId);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure.type, equals(FailureType.notFound));
            expect(failure.entityId, equals(nonExistentId));
          },
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should remove folder from list', () async {
        // Arrange
        final created = await repository.create(
          name: 'temp',
          parentId: 'root',
        );
        final folderId = created.getOrElse(() => throw Exception()).id;

        final beforeDelete = await repository.listAll();
        final countBefore = beforeDelete.getOrElse(() => []).length;

        // Act
        await repository.delete(folderId);

        // Assert
        final afterDelete = await repository.listAll();
        final countAfter = afterDelete.getOrElse(() => []).length;

        expect(countAfter, equals(countBefore - 1));
      });
    });

    group('move', () {
      test('should move folder to different parent', () async {
        // Arrange
        final parent1 = await repository.create(
          name: 'parent1',
          parentId: 'root',
        );
        final parent2 = await repository.create(
          name: 'parent2',
          parentId: 'root',
        );
        final folder = await repository.create(
          name: 'child',
          parentId: parent1.getOrElse(() => throw Exception()).id,
        );

        final folderId = folder.getOrElse(() => throw Exception()).id;
        final newParentId = parent2.getOrElse(() => throw Exception()).id;

        // Act
        final result = await repository.move(
          folderId: folderId,
          targetParentId: newParentId,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (moved) {
            expect(moved.parentId, equals(newParentId));
            expect(moved.id, equals(folderId));
            expect(moved.name, equals('child'));
          },
        );
      });

      test('should move folder to root', () async {
        // Arrange
        final parent = await repository.create(
          name: 'parent',
          parentId: 'root',
        );
        final folder = await repository.create(
          name: 'child',
          parentId: parent.getOrElse(() => throw Exception()).id,
        );
        final folderId = folder.getOrElse(() => throw Exception()).id;

        // Act
        final result = await repository.move(
          folderId: folderId,
          targetParentId: null,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (moved) {
            expect(moved.parentId, isNull);
          },
        );
      });

      test('should return not found failure for non-existent folder', () async {
        // Arrange
        const nonExistentId = 'folder_999';

        // Act
        final result = await repository.move(
          folderId: nonExistentId,
          targetParentId: 'root',
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure.type, equals(FailureType.notFound));
            expect(failure.entityId, equals(nonExistentId));
          },
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should persist moved folder', () async {
        // Arrange
        final folder = await repository.create(
          name: 'test',
          parentId: 'root',
        );
        final folderId = folder.getOrElse(() => throw Exception()).id;

        // Act
        await repository.move(
          folderId: folderId,
          targetParentId: null,
        );

        // Assert
        final loaded = await repository.load(folderId);
        loaded.fold(
          (failure) => fail('Expected Right but got Left'),
          (folder) {
            expect(folder.parentId, isNull);
          },
        );
      });
    });

    group('rename', () {
      test('should rename folder', () async {
        // Arrange
        final created = await repository.create(
          name: 'old_name',
          parentId: 'root',
        );
        final folderId = created.getOrElse(() => throw Exception()).id;
        const newName = 'new_name';

        // Act
        final result = await repository.rename(
          folderId: folderId,
          newName: newName,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (renamed) {
            expect(renamed.name, equals(newName));
            expect(renamed.id, equals(folderId));
          },
        );
      });

      test('should return not found failure for non-existent folder', () async {
        // Arrange
        const nonExistentId = 'folder_999';

        // Act
        final result = await repository.rename(
          folderId: nonExistentId,
          newName: 'new_name',
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure.type, equals(FailureType.notFound)),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should persist renamed folder', () async {
        // Arrange
        final created = await repository.create(name: 'old');
        final folderId = created.getOrElse(() => throw Exception()).id;

        // Act
        await repository.rename(folderId: folderId, newName: 'new');

        // Assert
        final loaded = await repository.load(folderId);
        loaded.fold(
          (failure) => fail('Expected Right but got Left'),
          (folder) {
            expect(folder.name, equals('new'));
          },
        );
      });
    });

    group('watch', () {
      test('should emit current folder state', () async {
        // Arrange
        final created = await repository.create(name: 'test');
        final folder = created.getOrElse(() => throw Exception());

        // Act
        final stream = repository.watch(folder.id);
        final events = await stream.take(1).toList();

        // Assert
        expect(events.length, equals(1));
        expect(events.first.isRight(), isTrue);
        events.first.fold(
          (failure) => fail('Expected Right but got Left'),
          (emitted) {
            expect(emitted.id, equals(folder.id));
            expect(emitted.name, equals(folder.name));
          },
        );
      });

      test('should not emit for non-existent folder', () async {
        // Arrange
        const nonExistentId = 'folder_999';

        // Act
        final stream = repository.watch(nonExistentId);
        final hasEvents = await stream.isEmpty.timeout(
          const Duration(milliseconds: 200),
          onTimeout: () => true,
        );

        // Assert
        expect(hasEvents, isTrue);
      });

      test('should emit for root folder', () async {
        // Act
        final stream = repository.watch('root');
        final events = await stream.take(1).toList();

        // Assert
        expect(events.length, equals(1));
        events.first.fold(
          (failure) => fail('Expected Right but got Left'),
          (root) {
            expect(root.id, equals('root'));
          },
        );
      });
    });

    group('listInFolder', () {
      test('should list all folders with specific parent', () async {
        // Arrange
        await repository.create(name: 'folder1', parentId: 'root');
        await repository.create(name: 'folder2', parentId: 'root');
        await repository.create(name: 'folder3', parentId: 'root');

        final other = await repository.create(name: 'other');
        final otherId = other.getOrElse(() => throw Exception()).id;
        await repository.create(name: 'nested', parentId: otherId);

        // Act
        final result = await repository.listInFolder('root');

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (folders) {
            expect(folders.length, equals(4)); // folder1, folder2, folder3, other
            expect(folders.every((f) => f.parentId == 'root'), isTrue);
          },
        );
      });

      test('should list folders with null parent', () async {
        // Arrange
        await repository.create(name: 'folder1');
        await repository.create(name: 'folder2');
        await repository.create(name: 'folder3', parentId: 'root');

        // Act
        final result = await repository.listInFolder(null);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (folders) {
            expect(folders.length, equals(2)); // folder1, folder2
            expect(folders.every((f) => f.parentId == null), isTrue);
          },
        );
      });

      test('should return empty list for parent with no children', () async {
        // Arrange
        final parent = await repository.create(name: 'empty_parent');
        final parentId = parent.getOrElse(() => throw Exception()).id;

        // Act
        final result = await repository.listInFolder(parentId);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (folders) {
            expect(folders.isEmpty, isTrue);
          },
        );
      });

      test('should list nested folder structure correctly', () async {
        // Arrange
        final parent = await repository.create(
          name: 'parent',
          parentId: 'root',
        );
        final parentId = parent.getOrElse(() => throw Exception()).id;

        await repository.create(name: 'child1', parentId: parentId);
        await repository.create(name: 'child2', parentId: parentId);

        // Act
        final result = await repository.listInFolder(parentId);

        // Assert
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (folders) {
            expect(folders.length, equals(2));
            expect(folders.every((f) => f.parentId == parentId), isTrue);
          },
        );
      });
    });

    group('listAll', () {
      test('should list all folders including root', () async {
        // Arrange
        await repository.create(name: 'folder1');
        await repository.create(name: 'folder2');
        await repository.create(name: 'folder3');

        // Act
        final result = await repository.listAll();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (folders) {
            expect(folders.length, equals(4)); // 3 created + root
            expect(folders.any((f) => f.id == 'root'), isTrue);
          },
        );
      });

      test('should return only root when no folders created', () async {
        // Act
        final result = await repository.listAll();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (folders) {
            expect(folders.length, equals(1));
            expect(folders.first.id, equals('root'));
          },
        );
      });
    });

    group('getRoot', () {
      test('should return root folder', () async {
        // Act
        final result = await repository.getRoot();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (root) {
            expect(root.id, equals('root'));
            expect(root.name, equals('root'));
            expect(root.parentId, isNull);
          },
        );
      });

      test('should return same root instance', () async {
        // Act
        final result1 = await repository.getRoot();
        final result2 = await repository.getRoot();

        // Assert
        final root1 = result1.getOrElse(() => throw Exception());
        final root2 = result2.getOrElse(() => throw Exception());

        expect(root1.id, equals(root2.id));
        expect(root1.createdAt, equals(root2.createdAt));
      });
    });

    group('clear', () {
      test('should clear all folders except root', () async {
        // Arrange
        await repository.create(name: 'folder1');
        await repository.create(name: 'folder2');
        await repository.create(name: 'folder3');

        // Act
        repository.clear();

        // Assert
        final result = await repository.listAll();
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (folders) {
            expect(folders.length, equals(1));
            expect(folders.first.id, equals('root'));
          },
        );
      });

      test('should reset ID counter', () async {
        // Arrange
        await repository.create(name: 'folder1');
        await repository.create(name: 'folder2');
        repository.clear();

        // Act
        final result = await repository.create(name: 'folder3');

        // Assert
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (folder) {
            expect(folder.id, equals('folder_1'));
          },
        );
      });

      test('should recreate root folder', () async {
        // Arrange
        repository.clear();

        // Act
        final result = await repository.getRoot();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (root) {
            expect(root.id, equals('root'));
          },
        );
      });
    });

    group('concurrent operations', () {
      test('should handle concurrent creates', () async {
        // Arrange & Act
        final futures = List.generate(
          10,
          (i) => repository.create(name: 'folder_$i'),
        );

        final results = await Future.wait(futures);

        // Assert
        expect(results.every((r) => r.isRight()), isTrue);
        final ids = results
            .map((r) => r.getOrElse(() => throw Exception()).id)
            .toSet();
        expect(ids.length, equals(10)); // All IDs should be unique
      });

      test('should handle concurrent moves', () async {
        // Arrange
        final folder = await repository.create(name: 'test');
        final folderId = folder.getOrElse(() => throw Exception()).id;

        final targets = await Future.wait([
          repository.create(name: 'target1'),
          repository.create(name: 'target2'),
          repository.create(name: 'target3'),
        ]);

        // Act
        final futures = targets.map((target) {
          final targetId = target.getOrElse(() => throw Exception()).id;
          return repository.move(
            folderId: folderId,
            targetParentId: targetId,
          );
        }).toList();

        final results = await Future.wait(futures);

        // Assert
        expect(results.every((r) => r.isRight()), isTrue);
      });

      test('should handle concurrent deletes safely', () async {
        // Arrange
        final created = await repository.create(name: 'test');
        final folderId = created.getOrElse(() => throw Exception()).id;

        // Act - try to delete same folder multiple times
        final futures = List.generate(
          3,
          (_) => repository.delete(folderId),
        );

        final results = await Future.wait(futures);

        // Assert - first should succeed, others should fail
        final successes = results.where((r) => r.isRight()).length;
        final failures = results.where((r) => r.isLeft()).length;

        expect(successes, equals(1));
        expect(failures, equals(2));
      });
    });

    group('dispose', () {
      test('should call clear when disposed', () async {
        // Arrange
        await repository.create(name: 'test');

        // Act
        repository.dispose();

        // Assert
        final result = await repository.listAll();
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (folders) {
            expect(folders.length, equals(1)); // Only root
          },
        );
      });
    });

    group('edge cases', () {
      test('should handle creating folder with same name', () async {
        // Arrange & Act
        final result1 = await repository.create(
          name: 'duplicate',
          parentId: 'root',
        );
        final result2 = await repository.create(
          name: 'duplicate',
          parentId: 'root',
        );

        // Assert - both should succeed with different IDs
        expect(result1.isRight(), isTrue);
        expect(result2.isRight(), isTrue);

        final folder1 = result1.getOrElse(() => throw Exception());
        final folder2 = result2.getOrElse(() => throw Exception());

        expect(folder1.id, isNot(equals(folder2.id)));
        expect(folder1.name, equals(folder2.name));
      });

      test('should handle deep nesting', () async {
        // Arrange
        var parentId = 'root';

        // Create 10 levels of nesting
        for (var i = 0; i < 10; i++) {
          final result = await repository.create(
            name: 'level_$i',
            parentId: parentId,
          );
          parentId = result.getOrElse(() => throw Exception()).id;
        }

        // Act
        final deepest = await repository.load(parentId);

        // Assert
        expect(deepest.isRight(), isTrue);
        deepest.fold(
          (failure) => fail('Expected Right but got Left'),
          (folder) {
            expect(folder.name, equals('level_9'));
          },
        );
      });

      test('should handle empty metadata', () async {
        // Arrange & Act
        final result = await repository.create(
          name: 'test',
          metadata: {},
        );

        // Assert
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (folder) {
            expect(folder.metadata, equals({}));
          },
        );
      });
    });
  });
}
