import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_mock/multi_editor_mock.dart';

void main() {
  group('MockFileRepository', () {
    late MockFileRepository repository;

    setUp(() {
      repository = MockFileRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    group('create', () {
      test('should create a new file with all parameters', () async {
        // Arrange
        const folderId = 'folder_1';
        const name = 'test.dart';
        const content = 'void main() {}';
        const language = 'dart';
        final metadata = {'author': 'test'};

        // Act
        final result = await repository.create(
          folderId: folderId,
          name: name,
          initialContent: content,
          language: language,
          metadata: metadata,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left: $failure'),
          (file) {
            expect(file.id, isNotEmpty);
            expect(file.name, equals(name));
            expect(file.folderId, equals(folderId));
            expect(file.content, equals(content));
            expect(file.language, equals(language));
            expect(file.metadata, equals(metadata));
            expect(file.createdAt, isNotNull);
            expect(file.updatedAt, isNotNull);
          },
        );
      });

      test('should create file with default values when optional params omitted',
          () async {
        // Arrange
        const folderId = 'folder_1';
        const name = 'empty.txt';

        // Act
        final result = await repository.create(
          folderId: folderId,
          name: name,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (file) {
            expect(file.content, equals(''));
            expect(file.language, equals('plaintext'));
            expect(file.metadata, isNull);
          },
        );
      });

      test('should generate unique IDs for multiple files', () async {
        // Arrange & Act
        final result1 = await repository.create(
          folderId: 'folder_1',
          name: 'file1.txt',
        );
        final result2 = await repository.create(
          folderId: 'folder_1',
          name: 'file2.txt',
        );
        final result3 = await repository.create(
          folderId: 'folder_1',
          name: 'file3.txt',
        );

        // Assert
        final id1 = result1.getOrElse(() => throw Exception());
        final id2 = result2.getOrElse(() => throw Exception());
        final id3 = result3.getOrElse(() => throw Exception());

        expect(id1.id, isNot(equals(id2.id)));
        expect(id2.id, isNot(equals(id3.id)));
        expect(id1.id, isNot(equals(id3.id)));
      });

      test('should notify watchers when file is created', () async {
        // Arrange
        const folderId = 'folder_1';
        const name = 'test.txt';
        final createdFile = await repository.create(
          folderId: folderId,
          name: name,
        );
        final fileId = createdFile.getOrElse(() => throw Exception()).id;

        // Act
        final stream = repository.watch(fileId);
        final events = <Either<DomainFailure, FileDocument>>[];
        final subscription = stream.listen(events.add);

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(events.length, greaterThan(0));
        expect(events.first.isRight(), isTrue);

        await subscription.cancel();
      });

      test('should simulate async delay', () async {
        // Arrange
        final stopwatch = Stopwatch()..start();

        // Act
        await repository.create(
          folderId: 'folder_1',
          name: 'test.txt',
        );

        stopwatch.stop();

        // Assert - should take at least 50ms
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(40));
      });
    });

    group('load', () {
      test('should load existing file by ID', () async {
        // Arrange
        final created = await repository.create(
          folderId: 'folder_1',
          name: 'test.dart',
          initialContent: 'content',
        );
        final fileId = created.getOrElse(() => throw Exception()).id;

        // Act
        final result = await repository.load(fileId);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (file) {
            expect(file.id, equals(fileId));
            expect(file.name, equals('test.dart'));
            expect(file.content, equals('content'));
          },
        );
      });

      test('should return not found failure for non-existent file', () async {
        // Arrange
        const nonExistentId = 'file_999';

        // Act
        final result = await repository.load(nonExistentId);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<DomainFailure>());
            expect(failure.type, equals(FailureType.notFound));
            expect(failure.entityType, equals('FileDocument'));
            expect(failure.entityId, equals(nonExistentId));
          },
          (file) => fail('Expected Left but got Right'),
        );
      });

      test('should load file with all properties intact', () async {
        // Arrange
        final metadata = {'key': 'value'};
        final created = await repository.create(
          folderId: 'folder_1',
          name: 'test.js',
          initialContent: 'console.log("test")',
          language: 'javascript',
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
            expect(loaded.folderId, equals(original.folderId));
            expect(loaded.content, equals(original.content));
            expect(loaded.language, equals(original.language));
            expect(loaded.metadata, equals(original.metadata));
            expect(loaded.createdAt, equals(original.createdAt));
            expect(loaded.updatedAt, equals(original.updatedAt));
          },
        );
      });
    });

    group('save', () {
      test('should save changes to existing file', () async {
        // Arrange
        final created = await repository.create(
          folderId: 'folder_1',
          name: 'test.txt',
          initialContent: 'old content',
        );
        var file = created.getOrElse(() => throw Exception());
        final updatedFile = file.updateContent('new content');

        // Act
        final saveResult = await repository.save(updatedFile);

        // Assert
        expect(saveResult.isRight(), isTrue);

        final loadResult = await repository.load(file.id);
        loadResult.fold(
          (failure) => fail('Expected Right but got Left'),
          (loaded) {
            expect(loaded.content, equals('new content'));
          },
        );
      });

      test('should return not found failure for non-existent file', () async {
        // Arrange
        final file = FileDocument(
          id: 'non_existent',
          name: 'test.txt',
          folderId: 'folder_1',
          content: 'content',
          language: 'plaintext',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final result = await repository.save(file);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure.type, equals(FailureType.notFound));
            expect(failure.entityId, equals('non_existent'));
          },
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should notify watchers when file is saved', () async {
        // Arrange
        final created = await repository.create(
          folderId: 'folder_1',
          name: 'test.txt',
          initialContent: 'old',
        );
        var file = created.getOrElse(() => throw Exception());

        final stream = repository.watch(file.id);
        final events = <Either<DomainFailure, FileDocument>>[];
        final subscription = stream.listen(events.add);

        await Future.delayed(const Duration(milliseconds: 100));
        events.clear(); // Clear initial event

        // Act
        final updated = file.updateContent('new');
        await repository.save(updated);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(events.length, greaterThan(0));
        events.last.fold(
          (failure) => fail('Expected Right but got Left'),
          (file) {
            expect(file.content, equals('new'));
          },
        );

        await subscription.cancel();
      });
    });

    group('delete', () {
      test('should delete existing file', () async {
        // Arrange
        final created = await repository.create(
          folderId: 'folder_1',
          name: 'test.txt',
        );
        final fileId = created.getOrElse(() => throw Exception()).id;

        // Act
        final deleteResult = await repository.delete(fileId);

        // Assert
        expect(deleteResult.isRight(), isTrue);

        final loadResult = await repository.load(fileId);
        expect(loadResult.isLeft(), isTrue);
      });

      test('should return not found failure for non-existent file', () async {
        // Arrange
        const nonExistentId = 'file_999';

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

      test('should close watchers when file is deleted', () async {
        // Arrange
        final created = await repository.create(
          folderId: 'folder_1',
          name: 'test.txt',
        );
        final fileId = created.getOrElse(() => throw Exception()).id;

        final stream = repository.watch(fileId);
        var streamClosed = false;
        final subscription = stream.listen(
          (_) {},
          onDone: () => streamClosed = true,
        );

        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        await repository.delete(fileId);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(streamClosed, isTrue);

        await subscription.cancel();
      });
    });

    group('move', () {
      test('should move file to different folder', () async {
        // Arrange
        final created = await repository.create(
          folderId: 'folder_1',
          name: 'test.txt',
        );
        final file = created.getOrElse(() => throw Exception());
        const newFolderId = 'folder_2';

        // Act
        final result = await repository.move(
          fileId: file.id,
          targetFolderId: newFolderId,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (moved) {
            expect(moved.folderId, equals(newFolderId));
            expect(moved.id, equals(file.id));
            expect(moved.name, equals(file.name));
          },
        );
      });

      test('should return not found failure for non-existent file', () async {
        // Arrange
        const nonExistentId = 'file_999';

        // Act
        final result = await repository.move(
          fileId: nonExistentId,
          targetFolderId: 'folder_2',
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

      test('should notify watchers when file is moved', () async {
        // Arrange
        final created = await repository.create(
          folderId: 'folder_1',
          name: 'test.txt',
        );
        final file = created.getOrElse(() => throw Exception());

        final stream = repository.watch(file.id);
        final events = <Either<DomainFailure, FileDocument>>[];
        final subscription = stream.listen(events.add);

        await Future.delayed(const Duration(milliseconds: 100));
        events.clear();

        // Act
        await repository.move(
          fileId: file.id,
          targetFolderId: 'folder_2',
        );
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(events.length, greaterThan(0));
        events.last.fold(
          (failure) => fail('Expected Right but got Left'),
          (moved) {
            expect(moved.folderId, equals('folder_2'));
          },
        );

        await subscription.cancel();
      });
    });

    group('rename', () {
      test('should rename file', () async {
        // Arrange
        final created = await repository.create(
          folderId: 'folder_1',
          name: 'old_name.txt',
        );
        final file = created.getOrElse(() => throw Exception());
        const newName = 'new_name.txt';

        // Act
        final result = await repository.rename(
          fileId: file.id,
          newName: newName,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (renamed) {
            expect(renamed.name, equals(newName));
            expect(renamed.id, equals(file.id));
            expect(renamed.folderId, equals(file.folderId));
          },
        );
      });

      test('should return not found failure for non-existent file', () async {
        // Arrange
        const nonExistentId = 'file_999';

        // Act
        final result = await repository.rename(
          fileId: nonExistentId,
          newName: 'new_name.txt',
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure.type, equals(FailureType.notFound)),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should notify watchers when file is renamed', () async {
        // Arrange
        final created = await repository.create(
          folderId: 'folder_1',
          name: 'old.txt',
        );
        final file = created.getOrElse(() => throw Exception());

        final stream = repository.watch(file.id);
        final events = <Either<DomainFailure, FileDocument>>[];
        final subscription = stream.listen(events.add);

        await Future.delayed(const Duration(milliseconds: 100));
        events.clear();

        // Act
        await repository.rename(fileId: file.id, newName: 'new.txt');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(events.length, greaterThan(0));
        events.last.fold(
          (failure) => fail('Expected Right but got Left'),
          (renamed) {
            expect(renamed.name, equals('new.txt'));
          },
        );

        await subscription.cancel();
      });
    });

    group('duplicate', () {
      test('should duplicate file with custom name', () async {
        // Arrange
        final created = await repository.create(
          folderId: 'folder_1',
          name: 'original.txt',
          initialContent: 'test content',
          language: 'plaintext',
        );
        final original = created.getOrElse(() => throw Exception());
        const duplicateName = 'duplicate.txt';

        // Act
        final result = await repository.duplicate(
          fileId: original.id,
          newName: duplicateName,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (duplicate) {
            expect(duplicate.id, isNot(equals(original.id)));
            expect(duplicate.name, equals(duplicateName));
            expect(duplicate.folderId, equals(original.folderId));
            expect(duplicate.content, equals(original.content));
            expect(duplicate.language, equals(original.language));
          },
        );
      });

      test('should duplicate file with default name', () async {
        // Arrange
        final created = await repository.create(
          folderId: 'folder_1',
          name: 'original.txt',
        );
        final original = created.getOrElse(() => throw Exception());

        // Act
        final result = await repository.duplicate(fileId: original.id);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (duplicate) {
            expect(duplicate.name, equals('Copy of original.txt'));
          },
        );
      });

      test('should duplicate file with metadata', () async {
        // Arrange
        final metadata = {'author': 'test', 'version': '1.0'};
        final created = await repository.create(
          folderId: 'folder_1',
          name: 'original.txt',
          metadata: metadata,
        );
        final original = created.getOrElse(() => throw Exception());

        // Act
        final result = await repository.duplicate(fileId: original.id);

        // Assert
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (duplicate) {
            expect(duplicate.metadata, equals(metadata));
          },
        );
      });

      test('should return not found failure for non-existent file', () async {
        // Arrange
        const nonExistentId = 'file_999';

        // Act
        final result = await repository.duplicate(fileId: nonExistentId);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure.type, equals(FailureType.notFound)),
          (_) => fail('Expected Left but got Right'),
        );
      });
    });

    group('watch', () {
      test('should emit current file state immediately', () async {
        // Arrange
        final created = await repository.create(
          folderId: 'folder_1',
          name: 'test.txt',
        );
        final file = created.getOrElse(() => throw Exception());

        // Act
        final stream = repository.watch(file.id);
        final events = <Either<DomainFailure, FileDocument>>[];
        final subscription = stream.listen(events.add);

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(events.length, greaterThan(0));
        events.first.fold(
          (failure) => fail('Expected Right but got Left'),
          (emitted) {
            expect(emitted.id, equals(file.id));
          },
        );

        await subscription.cancel();
      });

      test('should create broadcast stream for same file', () async {
        // Arrange
        final created = await repository.create(
          folderId: 'folder_1',
          name: 'test.txt',
        );
        final file = created.getOrElse(() => throw Exception());

        // Act
        final stream1 = repository.watch(file.id);
        final stream2 = repository.watch(file.id);

        final events1 = <Either<DomainFailure, FileDocument>>[];
        final events2 = <Either<DomainFailure, FileDocument>>[];

        final sub1 = stream1.listen(events1.add);
        final sub2 = stream2.listen(events2.add);

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(events1.length, greaterThan(0));
        expect(events2.length, greaterThan(0));

        await sub1.cancel();
        await sub2.cancel();
      });

      test('should not emit for non-existent file initially', () async {
        // Arrange
        const nonExistentId = 'file_999';

        // Act
        final stream = repository.watch(nonExistentId);
        final events = <Either<DomainFailure, FileDocument>>[];
        final subscription = stream.listen(events.add);

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(events.isEmpty, isTrue);

        await subscription.cancel();
      });
    });

    group('listInFolder', () {
      test('should list all files in folder', () async {
        // Arrange
        const folderId = 'folder_1';
        await repository.create(folderId: folderId, name: 'file1.txt');
        await repository.create(folderId: folderId, name: 'file2.txt');
        await repository.create(folderId: folderId, name: 'file3.txt');
        await repository.create(folderId: 'folder_2', name: 'other.txt');

        // Act
        final result = await repository.listInFolder(folderId);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (files) {
            expect(files.length, equals(3));
            expect(files.every((f) => f.folderId == folderId), isTrue);
          },
        );
      });

      test('should return empty list for folder with no files', () async {
        // Arrange
        const emptyFolderId = 'empty_folder';

        // Act
        final result = await repository.listInFolder(emptyFolderId);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (files) {
            expect(files.isEmpty, isTrue);
          },
        );
      });
    });

    group('search', () {
      setUp(() async {
        await repository.create(
          folderId: 'folder_1',
          name: 'test.dart',
          initialContent: 'void main() {}',
          language: 'dart',
        );
        await repository.create(
          folderId: 'folder_1',
          name: 'hello.js',
          initialContent: 'console.log("hello")',
          language: 'javascript',
        );
        await repository.create(
          folderId: 'folder_2',
          name: 'test.js',
          initialContent: 'const test = true',
          language: 'javascript',
        );
      });

      test('should search by query in name', () async {
        // Act
        final result = await repository.search(query: 'test');

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (files) {
            expect(files.length, equals(2));
            expect(
              files.every((f) => f.name.toLowerCase().contains('test')),
              isTrue,
            );
          },
        );
      });

      test('should search by query in content', () async {
        // Act
        final result = await repository.search(query: 'console');

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (files) {
            expect(files.length, equals(1));
            expect(files.first.name, equals('hello.js'));
          },
        );
      });

      test('should filter by language', () async {
        // Act
        final result = await repository.search(language: 'javascript');

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (files) {
            expect(files.length, equals(2));
            expect(files.every((f) => f.language == 'javascript'), isTrue);
          },
        );
      });

      test('should filter by folder ID', () async {
        // Act
        final result = await repository.search(folderId: 'folder_1');

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (files) {
            expect(files.length, equals(2));
            expect(files.every((f) => f.folderId == 'folder_1'), isTrue);
          },
        );
      });

      test('should combine multiple filters', () async {
        // Act
        final result = await repository.search(
          query: 'test',
          language: 'javascript',
          folderId: 'folder_2',
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (files) {
            expect(files.length, equals(1));
            expect(files.first.name, equals('test.js'));
          },
        );
      });

      test('should return all files when no filters provided', () async {
        // Act
        final result = await repository.search();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (files) {
            expect(files.length, equals(3));
          },
        );
      });

      test('should be case insensitive', () async {
        // Act
        final result = await repository.search(query: 'TEST');

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (files) {
            expect(files.length, equals(2));
          },
        );
      });
    });

    group('clear', () {
      test('should clear all files', () async {
        // Arrange
        await repository.create(folderId: 'folder_1', name: 'file1.txt');
        await repository.create(folderId: 'folder_1', name: 'file2.txt');

        // Act
        repository.clear();

        // Assert
        final result = await repository.search();
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (files) {
            expect(files.isEmpty, isTrue);
          },
        );
      });

      test('should close all watchers', () async {
        // Arrange
        final created = await repository.create(
          folderId: 'folder_1',
          name: 'test.txt',
        );
        final file = created.getOrElse(() => throw Exception());

        final stream = repository.watch(file.id);
        var streamClosed = false;
        final subscription = stream.listen(
          (_) {},
          onDone: () => streamClosed = true,
        );

        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        repository.clear();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(streamClosed, isTrue);

        await subscription.cancel();
      });

      test('should reset ID counter', () async {
        // Arrange
        await repository.create(folderId: 'folder_1', name: 'file1.txt');
        await repository.create(folderId: 'folder_1', name: 'file2.txt');
        repository.clear();

        // Act
        final result = await repository.create(
          folderId: 'folder_1',
          name: 'file3.txt',
        );

        // Assert
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (file) {
            expect(file.id, equals('file_1'));
          },
        );
      });
    });

    group('concurrent operations', () {
      test('should handle concurrent creates', () async {
        // Arrange & Act
        final futures = List.generate(
          10,
          (i) => repository.create(
            folderId: 'folder_1',
            name: 'file_$i.txt',
          ),
        );

        final results = await Future.wait(futures);

        // Assert
        expect(results.every((r) => r.isRight()), isTrue);
        final ids = results
            .map((r) => r.getOrElse(() => throw Exception()).id)
            .toSet();
        expect(ids.length, equals(10)); // All IDs should be unique
      });

      test('should handle concurrent saves', () async {
        // Arrange
        final created = await repository.create(
          folderId: 'folder_1',
          name: 'test.txt',
          initialContent: 'original',
        );
        final file = created.getOrElse(() => throw Exception());

        // Act
        final futures = List.generate(
          5,
          (i) => repository.save(file.updateContent('content_$i')),
        );

        final results = await Future.wait(futures);

        // Assert
        expect(results.every((r) => r.isRight()), isTrue);
      });

      test('should handle concurrent deletes safely', () async {
        // Arrange
        final created = await repository.create(
          folderId: 'folder_1',
          name: 'test.txt',
        );
        final fileId = created.getOrElse(() => throw Exception()).id;

        // Act - try to delete same file multiple times
        final futures = List.generate(
          3,
          (_) => repository.delete(fileId),
        );

        final results = await Future.wait(futures);

        // Assert - first should succeed, others should fail
        final successes = results.where((r) => r.isRight()).length;
        final failures = results.where((r) => r.isLeft()).length;

        expect(successes, equals(1));
        expect(failures, equals(2));
      });

      test('should handle watch and update concurrently', () async {
        // Arrange
        final created = await repository.create(
          folderId: 'folder_1',
          name: 'test.txt',
          initialContent: 'original',
        );
        final file = created.getOrElse(() => throw Exception());

        final stream = repository.watch(file.id);
        final events = <Either<DomainFailure, FileDocument>>[];
        final subscription = stream.listen(events.add);

        await Future.delayed(const Duration(milliseconds: 100));

        // Act - perform multiple updates
        for (var i = 0; i < 5; i++) {
          await repository.save(file.updateContent('update_$i'));
          await Future.delayed(const Duration(milliseconds: 10));
        }

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(events.length, greaterThan(5)); // Initial + updates

        await subscription.cancel();
      });
    });

    group('dispose', () {
      test('should call clear when disposed', () async {
        // Arrange
        await repository.create(folderId: 'folder_1', name: 'test.txt');

        // Act
        repository.dispose();

        // Assert
        final result = await repository.search();
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (files) {
            expect(files.isEmpty, isTrue);
          },
        );
      });
    });
  });
}
