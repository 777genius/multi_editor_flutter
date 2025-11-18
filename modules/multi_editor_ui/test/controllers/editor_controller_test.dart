import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_ui/src/controllers/editor_controller.dart';
import 'package:multi_editor_ui/src/state/editor_state.dart';

// Mocks
class MockFileRepository extends Mock implements FileRepository {}

class MockEventBus extends Mock implements EventBus {}

// Fake classes for mocktail
class FakeFileDocument extends Fake implements FileDocument {}

class FakeEditorEvent extends Fake implements EditorEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeFileDocument());
    registerFallbackValue(FakeEditorEvent());
  });

  group('EditorController', () {
    late MockFileRepository mockFileRepository;
    late MockEventBus mockEventBus;
    late EditorController controller;

    setUp(() {
      mockFileRepository = MockFileRepository();
      mockEventBus = MockEventBus();

      // Setup default stub for publish to avoid errors
      when(() => mockEventBus.publish(any())).thenReturn(null);

      controller = EditorController(
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
        expect(controller.value, isA<EditorState>());
        expect(controller.value.isInitial, isTrue);
      });
    });

    group('loadFile', () {
      const testFileId = 'test-file-id';
      final testFile = FileDocument(
        id: testFileId,
        name: 'test.dart',
        content: 'void main() {}',
        language: 'dart',
        folderId: 'folder-1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      test('should emit loading state then loaded state on success', () async {
        // Arrange
        when(() => mockFileRepository.load(testFileId))
            .thenAnswer((_) async => Right(testFile));
        when(() => mockFileRepository.watch(testFileId))
            .thenAnswer((_) => const Stream.empty());

        final states = <EditorState>[];
        controller.addListener(() {
          states.add(controller.value);
        });

        // Act
        await controller.loadFile(testFileId);

        // Assert
        expect(states.length, equals(2));
        expect(states[0].isLoading, isTrue);
        expect(states[1].isLoaded, isTrue);
        expect(states[1].maybeMap(
          loaded: (state) => state.file,
          orElse: () => null,
        ), equals(testFile));
      });

      test('should publish EditorEvent.fileOpened when file loads successfully', () async {
        // Arrange
        when(() => mockFileRepository.load(testFileId))
            .thenAnswer((_) async => Right(testFile));
        when(() => mockFileRepository.watch(testFileId))
            .thenAnswer((_) => const Stream.empty());

        // Act
        await controller.loadFile(testFileId);

        // Assert
        verify(() => mockEventBus.publish(
          EditorEvent.fileOpened(file: testFile),
        )).called(1);
      });

      test('should emit error state when load fails', () async {
        // Arrange
        final failure = const FileFailure.notFound(message: 'File not found');
        when(() => mockFileRepository.load(testFileId))
            .thenAnswer((_) async => Left(failure));

        // Act
        await controller.loadFile(testFileId);

        // Assert
        expect(controller.value.isError, isTrue);
        expect(controller.value.maybeMap(
          error: (state) => state.message,
          orElse: () => null,
        ), equals(failure.displayMessage));
      });

      test('should handle unexpected exceptions during load', () async {
        // Arrange
        when(() => mockFileRepository.load(testFileId))
            .thenThrow(Exception('Unexpected error'));

        // Act
        await controller.loadFile(testFileId);

        // Assert
        expect(controller.value.isError, isTrue);
        expect(controller.value.maybeMap(
          error: (state) => state.message,
          orElse: () => null,
        ), contains('Unexpected error'));
      });

      test('should subscribe to file watch stream when file loads', () async {
        // Arrange
        final updatedFile = testFile.updateContent('// Updated content');
        final streamController = StreamController<Either<FileFailure, FileDocument>>();

        when(() => mockFileRepository.load(testFileId))
            .thenAnswer((_) async => Right(testFile));
        when(() => mockFileRepository.watch(testFileId))
            .thenAnswer((_) => streamController.stream);

        // Act
        await controller.loadFile(testFileId);

        // File is loaded, now emit updated file from watch stream
        streamController.add(Right(updatedFile));
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(controller.value.maybeMap(
          loaded: (state) => state.file.content,
          orElse: () => null,
        ), equals('// Updated content'));

        // Cleanup
        await streamController.close();
      });

      test('should not update content from watch stream if file is dirty', () async {
        // Arrange
        final updatedFile = testFile.updateContent('// Updated content');
        final streamController = StreamController<Either<FileFailure, FileDocument>>();

        when(() => mockFileRepository.load(testFileId))
            .thenAnswer((_) async => Right(testFile));
        when(() => mockFileRepository.watch(testFileId))
            .thenAnswer((_) => streamController.stream);

        // Act
        await controller.loadFile(testFileId);

        // Make file dirty
        controller.updateContent('// User content');

        // Emit updated file from watch stream
        streamController.add(Right(updatedFile));
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert - should still have user content, not updated content
        expect(controller.value.maybeMap(
          loaded: (state) => state.file.content,
          orElse: () => null,
        ), equals('// User content'));

        // Cleanup
        await streamController.close();
      });

      test('should cancel previous watch subscription when loading new file', () async {
        // Arrange
        final file1 = testFile.copyWith(id: 'file-1');
        final file2 = testFile.copyWith(id: 'file-2');

        when(() => mockFileRepository.load('file-1'))
            .thenAnswer((_) async => Right(file1));
        when(() => mockFileRepository.load('file-2'))
            .thenAnswer((_) async => Right(file2));
        when(() => mockFileRepository.watch('file-1'))
            .thenAnswer((_) => const Stream.empty());
        when(() => mockFileRepository.watch('file-2'))
            .thenAnswer((_) => const Stream.empty());

        // Act
        await controller.loadFile('file-1');
        await controller.loadFile('file-2');

        // Assert - should load second file successfully
        expect(controller.value.maybeMap(
          loaded: (state) => state.file.id,
          orElse: () => null,
        ), equals('file-2'));
      });
    });

    group('updateContent', () {
      const testFileId = 'test-file-id';
      final testFile = FileDocument(
        id: testFileId,
        name: 'test.dart',
        content: 'void main() {}',
        language: 'dart',
        folderId: 'folder-1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      test('should update content and mark file as dirty', () async {
        // Arrange
        when(() => mockFileRepository.load(testFileId))
            .thenAnswer((_) async => Right(testFile));
        when(() => mockFileRepository.watch(testFileId))
            .thenAnswer((_) => const Stream.empty());

        await controller.loadFile(testFileId);

        const newContent = '// New content\nvoid main() {}';

        // Act
        controller.updateContent(newContent);

        // Assert
        final state = controller.value;
        expect(state.isLoaded, isTrue);
        state.mapOrNull(
          loaded: (s) {
            expect(s.file.content, equals(newContent));
            expect(s.isDirty, isTrue);
          },
        );
      });

      test('should publish EditorEvent.fileContentChanged when content updates', () async {
        // Arrange
        when(() => mockFileRepository.load(testFileId))
            .thenAnswer((_) async => Right(testFile));
        when(() => mockFileRepository.watch(testFileId))
            .thenAnswer((_) => const Stream.empty());

        await controller.loadFile(testFileId);

        const newContent = '// New content';

        // Act
        controller.updateContent(newContent);

        // Assert
        verify(() => mockEventBus.publish(
          EditorEvent.fileContentChanged(
            fileId: testFileId,
            content: newContent,
          ),
        )).called(1);
      });

      test('should do nothing when not in loaded state', () {
        // Arrange - controller is in initial state
        const newContent = '// New content';

        // Act
        controller.updateContent(newContent);

        // Assert - state should remain initial
        expect(controller.value.isInitial, isTrue);
      });
    });

    group('save', () {
      const testFileId = 'test-file-id';
      final testFile = FileDocument(
        id: testFileId,
        name: 'test.dart',
        content: 'void main() {}',
        language: 'dart',
        folderId: 'folder-1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      test('should save file and clear dirty flag on success', () async {
        // Arrange
        when(() => mockFileRepository.load(testFileId))
            .thenAnswer((_) async => Right(testFile));
        when(() => mockFileRepository.watch(testFileId))
            .thenAnswer((_) => const Stream.empty());
        when(() => mockFileRepository.save(any()))
            .thenAnswer((_) async => const Right(unit));

        await controller.loadFile(testFileId);
        controller.updateContent('// Updated content');

        // Act
        await controller.save();

        // Assert
        final state = controller.value;
        expect(state.isLoaded, isTrue);
        state.mapOrNull(
          loaded: (s) {
            expect(s.isDirty, isFalse);
            expect(s.isSaving, isFalse);
          },
        );
      });

      test('should set isSaving flag during save operation', () async {
        // Arrange
        final completer = Completer<Either<FileFailure, Unit>>();
        when(() => mockFileRepository.load(testFileId))
            .thenAnswer((_) async => Right(testFile));
        when(() => mockFileRepository.watch(testFileId))
            .thenAnswer((_) => const Stream.empty());
        when(() => mockFileRepository.save(any()))
            .thenAnswer((_) => completer.future);

        await controller.loadFile(testFileId);
        controller.updateContent('// Updated content');

        final states = <EditorState>[];
        controller.addListener(() {
          states.add(controller.value);
        });

        // Act
        final saveFuture = controller.save();

        // Give time for save to start
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert - isSaving should be true
        expect(states.any((s) => s.maybeMap(
          loaded: (state) => state.isSaving,
          orElse: () => false,
        )), isTrue);

        // Complete save
        completer.complete(const Right(unit));
        await saveFuture;
      });

      test('should publish EditorEvent.fileSaved on successful save', () async {
        // Arrange
        when(() => mockFileRepository.load(testFileId))
            .thenAnswer((_) async => Right(testFile));
        when(() => mockFileRepository.watch(testFileId))
            .thenAnswer((_) => const Stream.empty());
        when(() => mockFileRepository.save(any()))
            .thenAnswer((_) async => const Right(unit));

        await controller.loadFile(testFileId);
        controller.updateContent('// Updated content');

        // Act
        await controller.save();

        // Assert
        verify(() => mockEventBus.publish(
          any(that: isA<EditorEvent>()),
        )).called(greaterThan(1)); // Called for fileOpened and fileSaved
      });

      test('should emit error state when save fails', () async {
        // Arrange
        final failure = const FileFailure.storageError(message: 'Save failed');
        when(() => mockFileRepository.load(testFileId))
            .thenAnswer((_) async => Right(testFile));
        when(() => mockFileRepository.watch(testFileId))
            .thenAnswer((_) => const Stream.empty());
        when(() => mockFileRepository.save(any()))
            .thenAnswer((_) async => Left(failure));

        await controller.loadFile(testFileId);
        controller.updateContent('// Updated content');

        // Act
        await controller.save();

        // Assert
        expect(controller.value.isError, isTrue);
        expect(controller.value.maybeMap(
          error: (state) => state.message,
          orElse: () => null,
        ), contains('Save failed'));
      });

      test('should handle unexpected exceptions during save', () async {
        // Arrange
        when(() => mockFileRepository.load(testFileId))
            .thenAnswer((_) async => Right(testFile));
        when(() => mockFileRepository.watch(testFileId))
            .thenAnswer((_) => const Stream.empty());
        when(() => mockFileRepository.save(any()))
            .thenThrow(Exception('Unexpected save error'));

        await controller.loadFile(testFileId);
        controller.updateContent('// Updated content');

        // Act
        await controller.save();

        // Assert
        expect(controller.value.isError, isTrue);
        expect(controller.value.maybeMap(
          error: (state) => state.message,
          orElse: () => null,
        ), contains('Save failed'));
      });

      test('should not save when file is not dirty', () async {
        // Arrange
        when(() => mockFileRepository.load(testFileId))
            .thenAnswer((_) async => Right(testFile));
        when(() => mockFileRepository.watch(testFileId))
            .thenAnswer((_) => const Stream.empty());

        await controller.loadFile(testFileId);
        // Don't update content - file is not dirty

        // Act
        await controller.save();

        // Assert
        verifyNever(() => mockFileRepository.save(any()));
      });

      test('should do nothing when not in loaded state', () async {
        // Arrange - controller is in initial state

        // Act
        await controller.save();

        // Assert
        verifyNever(() => mockFileRepository.save(any()));
        expect(controller.value.isInitial, isTrue);
      });
    });

    group('close', () {
      const testFileId = 'test-file-id';
      final testFile = FileDocument(
        id: testFileId,
        name: 'test.dart',
        content: 'void main() {}',
        language: 'dart',
        folderId: 'folder-1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      test('should close file and reset to initial state', () async {
        // Arrange
        when(() => mockFileRepository.load(testFileId))
            .thenAnswer((_) async => Right(testFile));
        when(() => mockFileRepository.watch(testFileId))
            .thenAnswer((_) => const Stream.empty());

        await controller.loadFile(testFileId);

        // Act
        controller.close();

        // Assert
        expect(controller.value.isInitial, isTrue);
      });

      test('should publish EditorEvent.fileClosed when closing file', () async {
        // Arrange
        when(() => mockFileRepository.load(testFileId))
            .thenAnswer((_) async => Right(testFile));
        when(() => mockFileRepository.watch(testFileId))
            .thenAnswer((_) => const Stream.empty());

        await controller.loadFile(testFileId);

        // Act
        controller.close();

        // Assert
        verify(() => mockEventBus.publish(
          EditorEvent.fileClosed(fileId: testFileId),
        )).called(1);
      });

      test('should cancel file watch subscription when closing', () async {
        // Arrange
        final streamController = StreamController<Either<FileFailure, FileDocument>>();
        when(() => mockFileRepository.load(testFileId))
            .thenAnswer((_) async => Right(testFile));
        when(() => mockFileRepository.watch(testFileId))
            .thenAnswer((_) => streamController.stream);

        await controller.loadFile(testFileId);

        // Act
        controller.close();

        // Try to add to stream - subscription should be cancelled
        streamController.add(Right(testFile));
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert - state should remain initial, not update from stream
        expect(controller.value.isInitial, isTrue);

        // Cleanup
        await streamController.close();
      });

      test('should do nothing when not in loaded state', () {
        // Arrange - controller is in initial state

        // Act
        controller.close();

        // Assert
        verifyNever(() => mockEventBus.publish(any()));
        expect(controller.value.isInitial, isTrue);
      });
    });

    group('dispose', () {
      test('should cancel watch subscription on dispose', () async {
        // Arrange
        const testFileId = 'test-file-id';
        final testFile = FileDocument(
          id: testFileId,
          name: 'test.dart',
          content: 'void main() {}',
          language: 'dart',
          folderId: 'folder-1',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final streamController = StreamController<Either<FileFailure, FileDocument>>();
        when(() => mockFileRepository.load(testFileId))
            .thenAnswer((_) async => Right(testFile));
        when(() => mockFileRepository.watch(testFileId))
            .thenAnswer((_) => streamController.stream);

        await controller.loadFile(testFileId);

        // Act
        controller.dispose();

        // Assert - should not throw when closing stream
        expect(() => streamController.close(), returnsNormally);
      });
    });

    group('Use Cases', () {
      group('UC1: User opens file, edits, and saves', () {
        test('should handle complete edit workflow', () async {
          // Arrange
          const testFileId = 'test-file-id';
          final testFile = FileDocument(
            id: testFileId,
            name: 'test.dart',
            content: 'void main() {}',
            language: 'dart',
            folderId: 'folder-1',
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          );

          when(() => mockFileRepository.load(testFileId))
              .thenAnswer((_) async => Right(testFile));
          when(() => mockFileRepository.watch(testFileId))
              .thenAnswer((_) => const Stream.empty());
          when(() => mockFileRepository.save(any()))
              .thenAnswer((_) async => const Right(unit));

          // Act & Assert
          // 1. Load file
          await controller.loadFile(testFileId);
          expect(controller.value.isLoaded, isTrue);
          expect(controller.value.canSave, isFalse);

          // 2. Edit content
          controller.updateContent('// New content\nvoid main() {}');
          expect(controller.value.canSave, isTrue);

          // 3. Save
          await controller.save();
          expect(controller.value.canSave, isFalse);

          // Verify event sequence
          verify(() => mockEventBus.publish(
            EditorEvent.fileOpened(file: testFile),
          )).called(1);
          verify(() => mockEventBus.publish(
            any(that: isA<EditorEvent>()),
          )).called(greaterThan(1));
        });
      });

      group('UC2: User opens file and closes without saving', () {
        test('should handle open and close without save', () async {
          // Arrange
          const testFileId = 'test-file-id';
          final testFile = FileDocument(
            id: testFileId,
            name: 'test.dart',
            content: 'void main() {}',
            language: 'dart',
            folderId: 'folder-1',
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          );

          when(() => mockFileRepository.load(testFileId))
              .thenAnswer((_) async => Right(testFile));
          when(() => mockFileRepository.watch(testFileId))
              .thenAnswer((_) => const Stream.empty());

          // Act
          await controller.loadFile(testFileId);
          controller.updateContent('// Modified content');
          controller.close();

          // Assert
          expect(controller.value.isInitial, isTrue);
          verifyNever(() => mockFileRepository.save(any()));
        });
      });

      group('UC3: External file modification while editing', () {
        test('should not update content when file is dirty', () async {
          // Arrange
          const testFileId = 'test-file-id';
          final testFile = FileDocument(
            id: testFileId,
            name: 'test.dart',
            content: 'void main() {}',
            language: 'dart',
            folderId: 'folder-1',
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          );
          final externalUpdate = testFile.updateContent('// External change');

          final streamController = StreamController<Either<FileFailure, FileDocument>>();
          when(() => mockFileRepository.load(testFileId))
              .thenAnswer((_) async => Right(testFile));
          when(() => mockFileRepository.watch(testFileId))
              .thenAnswer((_) => streamController.stream);

          // Act
          await controller.loadFile(testFileId);
          controller.updateContent('// User change');

          // External modification
          streamController.add(Right(externalUpdate));
          await Future.delayed(const Duration(milliseconds: 10));

          // Assert - should keep user's content
          expect(controller.value.maybeMap(
            loaded: (state) => state.file.content,
            orElse: () => null,
          ), equals('// User change'));

          await streamController.close();
        });
      });
    });
  });
}
