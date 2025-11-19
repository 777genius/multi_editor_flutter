import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_mock/multi_editor_mock.dart';

void main() {
  group('MockProjectRepository', () {
    late MockProjectRepository repository;

    setUp(() {
      repository = MockProjectRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    group('create', () {
      test('should create a new project with all parameters', () async {
        // Arrange
        const name = 'My Project';
        const description = 'A test project';
        final settings = {'theme': 'dark', 'fontSize': 14};
        final metadata = {'author': 'test', 'version': '1.0'};

        // Act
        final result = await repository.create(
          name: name,
          description: description,
          settings: settings,
          metadata: metadata,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left: $failure'),
          (project) {
            expect(project.id, isNotEmpty);
            expect(project.name, equals(name));
            expect(project.description, equals(description));
            expect(project.rootFolderId, equals('root'));
            expect(project.settings, equals(settings));
            expect(project.metadata, equals(metadata));
            expect(project.createdAt, isNotNull);
            expect(project.updatedAt, isNotNull);
          },
        );
      });

      test('should create project with default values when optional params omitted',
          () async {
        // Arrange
        const name = 'Simple Project';

        // Act
        final result = await repository.create(name: name);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (project) {
            expect(project.description, isNull);
            expect(project.settings, equals({}));
            expect(project.metadata, equals({}));
          },
        );
      });

      test('should generate unique IDs for multiple projects', () async {
        // Arrange & Act
        final result1 = await repository.create(name: 'Project 1');
        final result2 = await repository.create(name: 'Project 2');
        final result3 = await repository.create(name: 'Project 3');

        // Assert
        final project1 = result1.getOrElse(() => throw Exception());
        final project2 = result2.getOrElse(() => throw Exception());
        final project3 = result3.getOrElse(() => throw Exception());

        expect(project1.id, isNot(equals(project2.id)));
        expect(project2.id, isNot(equals(project3.id)));
        expect(project1.id, isNot(equals(project3.id)));
      });

      test('should set first project as current automatically', () async {
        // Arrange & Act
        final created = await repository.create(name: 'First Project');
        final projectId = created.getOrElse(() => throw Exception()).id;

        // Assert
        final current = await repository.getCurrent();
        current.fold(
          (failure) => fail('Expected Right but got Left'),
          (project) {
            expect(project.id, equals(projectId));
          },
        );
      });

      test('should not change current when creating second project', () async {
        // Arrange
        final first = await repository.create(name: 'First Project');
        final firstId = first.getOrElse(() => throw Exception()).id;

        // Act
        await repository.create(name: 'Second Project');

        // Assert
        final current = await repository.getCurrent();
        current.fold(
          (failure) => fail('Expected Right but got Left'),
          (project) {
            expect(project.id, equals(firstId));
          },
        );
      });

      test('should notify watchers when project is created', () async {
        // Arrange
        final created = await repository.create(name: 'Test Project');
        final projectId = created.getOrElse(() => throw Exception()).id;

        // Act
        final stream = repository.watch(projectId);
        final events = <Either<DomainFailure, Project>>[];
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
        await repository.create(name: 'Test Project');

        stopwatch.stop();

        // Assert - should take at least 50ms
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(40));
      });
    });

    group('load', () {
      test('should load existing project by ID', () async {
        // Arrange
        final created = await repository.create(
          name: 'Test Project',
          description: 'A test',
        );
        final projectId = created.getOrElse(() => throw Exception()).id;

        // Act
        final result = await repository.load(projectId);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (project) {
            expect(project.id, equals(projectId));
            expect(project.name, equals('Test Project'));
            expect(project.description, equals('A test'));
          },
        );
      });

      test('should return not found failure for non-existent project', () async {
        // Arrange
        const nonExistentId = 'project_999';

        // Act
        final result = await repository.load(nonExistentId);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<DomainFailure>());
            expect(failure.type, equals(FailureType.notFound));
            expect(failure.entityType, equals('Project'));
            expect(failure.entityId, equals(nonExistentId));
            expect(failure.message, contains('not found'));
          },
          (project) => fail('Expected Left but got Right'),
        );
      });

      test('should load project with all properties intact', () async {
        // Arrange
        final settings = {'key1': 'value1'};
        final metadata = {'key2': 'value2'};
        final created = await repository.create(
          name: 'Full Project',
          description: 'Complete project',
          settings: settings,
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
            expect(loaded.description, equals(original.description));
            expect(loaded.rootFolderId, equals(original.rootFolderId));
            expect(loaded.settings, equals(original.settings));
            expect(loaded.metadata, equals(original.metadata));
            expect(loaded.createdAt, equals(original.createdAt));
            expect(loaded.updatedAt, equals(original.updatedAt));
          },
        );
      });
    });

    group('save', () {
      test('should save changes to existing project', () async {
        // Arrange
        final created = await repository.create(
          name: 'Original Name',
          description: 'Original description',
        );
        var project = created.getOrElse(() => throw Exception());
        final updatedProject = project.copyWith(
          name: 'Updated Name',
          description: 'Updated description',
        );

        // Act
        final saveResult = await repository.save(updatedProject);

        // Assert
        expect(saveResult.isRight(), isTrue);

        final loadResult = await repository.load(project.id);
        loadResult.fold(
          (failure) => fail('Expected Right but got Left'),
          (loaded) {
            expect(loaded.name, equals('Updated Name'));
            expect(loaded.description, equals('Updated description'));
          },
        );
      });

      test('should update updatedAt timestamp when saving', () async {
        // Arrange
        final created = await repository.create(name: 'Test Project');
        var project = created.getOrElse(() => throw Exception());
        final originalUpdatedAt = project.updatedAt;

        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        final updated = project.copyWith(name: 'New Name');
        await repository.save(updated);

        // Assert
        final loadResult = await repository.load(project.id);
        loadResult.fold(
          (failure) => fail('Expected Right but got Left'),
          (loaded) {
            expect(loaded.updatedAt.isAfter(originalUpdatedAt), isTrue);
          },
        );
      });

      test('should return not found failure for non-existent project', () async {
        // Arrange
        final project = Project(
          id: 'non_existent',
          name: 'Test',
          rootFolderId: 'root',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final result = await repository.save(project);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure.type, equals(FailureType.notFound));
            expect(failure.entityId, equals('non_existent'));
            expect(failure.message, contains('not found'));
          },
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should notify watchers when project is saved', () async {
        // Arrange
        final created = await repository.create(name: 'Test Project');
        var project = created.getOrElse(() => throw Exception());

        final stream = repository.watch(project.id);
        final events = <Either<DomainFailure, Project>>[];
        final subscription = stream.listen(events.add);

        await Future.delayed(const Duration(milliseconds: 100));
        events.clear(); // Clear initial event

        // Act
        final updated = project.copyWith(name: 'Updated');
        await repository.save(updated);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(events.length, greaterThan(0));
        events.last.fold(
          (failure) => fail('Expected Right but got Left'),
          (proj) {
            expect(proj.name, equals('Updated'));
          },
        );

        await subscription.cancel();
      });

      test('should save settings changes', () async {
        // Arrange
        final created = await repository.create(
          name: 'Test',
          settings: {'theme': 'light'},
        );
        var project = created.getOrElse(() => throw Exception());

        // Act
        final updated = project.copyWith(
          settings: {'theme': 'dark', 'fontSize': 16},
        );
        await repository.save(updated);

        // Assert
        final loaded = await repository.load(project.id);
        loaded.fold(
          (failure) => fail('Expected Right but got Left'),
          (proj) {
            expect(proj.settings['theme'], equals('dark'));
            expect(proj.settings['fontSize'], equals(16));
          },
        );
      });
    });

    group('delete', () {
      test('should delete existing project', () async {
        // Arrange
        final created = await repository.create(name: 'Test Project');
        final projectId = created.getOrElse(() => throw Exception()).id;

        // Act
        final deleteResult = await repository.delete(projectId);

        // Assert
        expect(deleteResult.isRight(), isTrue);

        final loadResult = await repository.load(projectId);
        expect(loadResult.isLeft(), isTrue);
      });

      test('should return not found failure for non-existent project', () async {
        // Arrange
        const nonExistentId = 'project_999';

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

      test('should update current project when deleting current', () async {
        // Arrange
        final first = await repository.create(name: 'First');
        final second = await repository.create(name: 'Second');
        final firstId = first.getOrElse(() => throw Exception()).id;
        final secondId = second.getOrElse(() => throw Exception()).id;

        // Act - delete current project (first one)
        await repository.delete(firstId);

        // Assert - current should switch to second
        final current = await repository.getCurrent();
        current.fold(
          (failure) => fail('Expected Right but got Left'),
          (project) {
            expect(project.id, equals(secondId));
          },
        );
      });

      test('should clear current when deleting last project', () async {
        // Arrange
        final created = await repository.create(name: 'Only Project');
        final projectId = created.getOrElse(() => throw Exception()).id;

        // Act
        await repository.delete(projectId);

        // Assert
        final current = await repository.getCurrent();
        expect(current.isLeft(), isTrue);
        current.fold(
          (failure) {
            expect(failure.type, equals(FailureType.notFound));
            expect(failure.message, contains('No current project set'));
          },
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should close watchers when project is deleted', () async {
        // Arrange
        final created = await repository.create(name: 'Test Project');
        final projectId = created.getOrElse(() => throw Exception()).id;

        final stream = repository.watch(projectId);
        var streamClosed = false;
        final subscription = stream.listen(
          (_) {},
          onDone: () => streamClosed = true,
        );

        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        await repository.delete(projectId);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(streamClosed, isTrue);

        await subscription.cancel();
      });
    });

    group('watch', () {
      test('should emit current project state immediately', () async {
        // Arrange
        final created = await repository.create(name: 'Test Project');
        final project = created.getOrElse(() => throw Exception());

        // Act
        final stream = repository.watch(project.id);
        final events = <Either<DomainFailure, Project>>[];
        final subscription = stream.listen(events.add);

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(events.length, greaterThan(0));
        events.first.fold(
          (failure) => fail('Expected Right but got Left'),
          (emitted) {
            expect(emitted.id, equals(project.id));
          },
        );

        await subscription.cancel();
      });

      test('should create broadcast stream for same project', () async {
        // Arrange
        final created = await repository.create(name: 'Test Project');
        final project = created.getOrElse(() => throw Exception());

        // Act
        final stream1 = repository.watch(project.id);
        final stream2 = repository.watch(project.id);

        final events1 = <Either<DomainFailure, Project>>[];
        final events2 = <Either<DomainFailure, Project>>[];

        final sub1 = stream1.listen(events1.add);
        final sub2 = stream2.listen(events2.add);

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(events1.length, greaterThan(0));
        expect(events2.length, greaterThan(0));

        await sub1.cancel();
        await sub2.cancel();
      });

      test('should not emit for non-existent project initially', () async {
        // Arrange
        const nonExistentId = 'project_999';

        // Act
        final stream = repository.watch(nonExistentId);
        final events = <Either<DomainFailure, Project>>[];
        final subscription = stream.listen(events.add);

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(events.isEmpty, isTrue);

        await subscription.cancel();
      });

      test('should reuse existing stream controller', () async {
        // Arrange
        final created = await repository.create(name: 'Test');
        final projectId = created.getOrElse(() => throw Exception()).id;

        // Act
        final stream1 = repository.watch(projectId);
        final stream2 = repository.watch(projectId);

        // Assert - should be same stream
        expect(identical(stream1, stream2), isTrue);
      });
    });

    group('listAll', () {
      test('should list all projects', () async {
        // Arrange
        await repository.create(name: 'Project 1');
        await repository.create(name: 'Project 2');
        await repository.create(name: 'Project 3');

        // Act
        final result = await repository.listAll();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (projects) {
            expect(projects.length, equals(3));
            expect(
              projects.map((p) => p.name).toSet(),
              equals({'Project 1', 'Project 2', 'Project 3'}),
            );
          },
        );
      });

      test('should return empty list when no projects exist', () async {
        // Act
        final result = await repository.listAll();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (projects) {
            expect(projects.isEmpty, isTrue);
          },
        );
      });

      test('should reflect deleted projects', () async {
        // Arrange
        await repository.create(name: 'Project 1');
        final toDelete = await repository.create(name: 'Project 2');
        await repository.create(name: 'Project 3');

        final deleteId = toDelete.getOrElse(() => throw Exception()).id;
        await repository.delete(deleteId);

        // Act
        final result = await repository.listAll();

        // Assert
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (projects) {
            expect(projects.length, equals(2));
            expect(projects.any((p) => p.name == 'Project 2'), isFalse);
          },
        );
      });
    });

    group('getCurrent', () {
      test('should return current project', () async {
        // Arrange
        final created = await repository.create(name: 'Current Project');
        final projectId = created.getOrElse(() => throw Exception()).id;

        // Act
        final result = await repository.getCurrent();

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (project) {
            expect(project.id, equals(projectId));
            expect(project.name, equals('Current Project'));
          },
        );
      });

      test('should return failure when no projects exist', () async {
        // Act
        final result = await repository.getCurrent();

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure.type, equals(FailureType.notFound));
            expect(failure.message, contains('No current project set'));
          },
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should maintain current project across operations', () async {
        // Arrange
        final first = await repository.create(name: 'First');
        await repository.create(name: 'Second');
        await repository.create(name: 'Third');

        final firstId = first.getOrElse(() => throw Exception()).id;

        // Act & Assert - should still be first
        final current = await repository.getCurrent();
        current.fold(
          (failure) => fail('Expected Right but got Left'),
          (project) {
            expect(project.id, equals(firstId));
          },
        );
      });

      test('should switch current when current is deleted', () async {
        // Arrange
        final first = await repository.create(name: 'First');
        final second = await repository.create(name: 'Second');

        final firstId = first.getOrElse(() => throw Exception()).id;
        final secondId = second.getOrElse(() => throw Exception()).id;

        // Act
        await repository.delete(firstId);

        // Assert
        final current = await repository.getCurrent();
        current.fold(
          (failure) => fail('Expected Right but got Left'),
          (project) {
            expect(project.id, equals(secondId));
          },
        );
      });
    });

    group('dispose', () {
      test('should close all watchers', () async {
        // Arrange
        final project1 = await repository.create(name: 'Project 1');
        final project2 = await repository.create(name: 'Project 2');

        final id1 = project1.getOrElse(() => throw Exception()).id;
        final id2 = project2.getOrElse(() => throw Exception()).id;

        final stream1 = repository.watch(id1);
        final stream2 = repository.watch(id2);

        var stream1Closed = false;
        var stream2Closed = false;

        final sub1 = stream1.listen(
          (_) {},
          onDone: () => stream1Closed = true,
        );
        final sub2 = stream2.listen(
          (_) {},
          onDone: () => stream2Closed = true,
        );

        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        repository.dispose();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(stream1Closed, isTrue);
        expect(stream2Closed, isTrue);

        await sub1.cancel();
        await sub2.cancel();
      });

      test('should clear all projects', () async {
        // Arrange
        await repository.create(name: 'Project 1');
        await repository.create(name: 'Project 2');

        // Act
        repository.dispose();

        // Assert
        final result = await repository.listAll();
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (projects) {
            expect(projects.isEmpty, isTrue);
          },
        );
      });
    });

    group('concurrent operations', () {
      test('should handle concurrent creates', () async {
        // Arrange & Act
        final futures = List.generate(
          10,
          (i) => repository.create(name: 'Project $i'),
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
        final created = await repository.create(name: 'Test Project');
        final project = created.getOrElse(() => throw Exception());

        // Act
        final futures = List.generate(
          5,
          (i) => repository.save(project.copyWith(name: 'Version $i')),
        );

        final results = await Future.wait(futures);

        // Assert
        expect(results.every((r) => r.isRight()), isTrue);
      });

      test('should handle concurrent deletes safely', () async {
        // Arrange
        final created = await repository.create(name: 'Test Project');
        final projectId = created.getOrElse(() => throw Exception()).id;

        // Act - try to delete same project multiple times
        final futures = List.generate(
          3,
          (_) => repository.delete(projectId),
        );

        final results = await Future.wait(futures);

        // Assert - first should succeed, others should fail
        final successes = results.where((r) => r.isRight()).length;
        final failures = results.where((r) => r.isLeft()).length;

        expect(successes, equals(1));
        expect(failures, equals(2));
      });

      test('should handle watch and save concurrently', () async {
        // Arrange
        final created = await repository.create(name: 'Test Project');
        final project = created.getOrElse(() => throw Exception());

        final stream = repository.watch(project.id);
        final events = <Either<DomainFailure, Project>>[];
        final subscription = stream.listen(events.add);

        await Future.delayed(const Duration(milliseconds: 100));

        // Act - perform multiple saves
        for (var i = 0; i < 5; i++) {
          await repository.save(project.copyWith(name: 'Update $i'));
          await Future.delayed(const Duration(milliseconds: 10));
        }

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(events.length, greaterThan(5)); // Initial + updates

        await subscription.cancel();
      });
    });

    group('edge cases', () {
      test('should handle project with same name', () async {
        // Arrange & Act
        final result1 = await repository.create(name: 'Duplicate');
        final result2 = await repository.create(name: 'Duplicate');

        // Assert - both should succeed with different IDs
        expect(result1.isRight(), isTrue);
        expect(result2.isRight(), isTrue);

        final project1 = result1.getOrElse(() => throw Exception());
        final project2 = result2.getOrElse(() => throw Exception());

        expect(project1.id, isNot(equals(project2.id)));
        expect(project1.name, equals(project2.name));
      });

      test('should handle empty settings and metadata', () async {
        // Arrange & Act
        final result = await repository.create(
          name: 'Test',
          settings: {},
          metadata: {},
        );

        // Assert
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (project) {
            expect(project.settings, equals({}));
            expect(project.metadata, equals({}));
          },
        );
      });

      test('should handle saving project with null description', () async {
        // Arrange
        final created = await repository.create(name: 'Test');
        var project = created.getOrElse(() => throw Exception());

        // Act
        final updated = project.copyWith(description: null);
        await repository.save(updated);

        // Assert
        final loaded = await repository.load(project.id);
        loaded.fold(
          (failure) => fail('Expected Right but got Left'),
          (proj) {
            expect(proj.description, isNull);
          },
        );
      });

      test('should handle complex settings structures', () async {
        // Arrange
        final complexSettings = {
          'editor': {
            'theme': 'dark',
            'fontSize': 14,
            'tabSize': 2,
          },
          'features': ['autocomplete', 'syntax-highlighting'],
          'enabled': true,
        };

        // Act
        final result = await repository.create(
          name: 'Test',
          settings: complexSettings,
        );

        // Assert
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (project) {
            expect(project.settings, equals(complexSettings));
          },
        );
      });

      test('should maintain project order in listAll', () async {
        // Arrange
        final names = ['Alpha', 'Beta', 'Gamma', 'Delta'];
        for (final name in names) {
          await repository.create(name: name);
        }

        // Act
        final result = await repository.listAll();

        // Assert
        result.fold(
          (failure) => fail('Expected Right but got Left'),
          (projects) {
            expect(projects.length, equals(4));
            // Order may not be guaranteed in a map, but all should be present
            final loadedNames = projects.map((p) => p.name).toSet();
            expect(loadedNames, equals(names.toSet()));
          },
        );
      });
    });
  });
}
