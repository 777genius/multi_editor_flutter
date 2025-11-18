import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_ui/src/state/editor_state.dart';

void main() {
  group('EditorState', () {
    // Test data
    final testFile = FileDocument(
      id: 'test-file-id',
      name: 'test.dart',
      content: 'void main() {}',
      language: 'dart',
      folderId: 'folder-1',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    group('Initial State', () {
      test('should create initial state', () {
        // Arrange & Act
        const state = EditorState.initial();

        // Assert
        expect(state.isInitial, isTrue);
        expect(state.isLoading, isFalse);
        expect(state.isLoaded, isFalse);
        expect(state.isError, isFalse);
      });

      test('should have canSave as false in initial state', () {
        // Arrange & Act
        const state = EditorState.initial();

        // Assert
        expect(state.canSave, isFalse);
      });

      test('should have null fileName in initial state', () {
        // Arrange & Act
        const state = EditorState.initial();

        // Assert
        expect(state.fileName, isNull);
      });

      test('should have null fileId in initial state', () {
        // Arrange & Act
        const state = EditorState.initial();

        // Assert
        expect(state.fileId, isNull);
      });
    });

    group('Loading State', () {
      test('should create loading state', () {
        // Arrange & Act
        const state = EditorState.loading();

        // Assert
        expect(state.isLoading, isTrue);
        expect(state.isInitial, isFalse);
        expect(state.isLoaded, isFalse);
        expect(state.isError, isFalse);
      });

      test('should have canSave as false in loading state', () {
        // Arrange & Act
        const state = EditorState.loading();

        // Assert
        expect(state.canSave, isFalse);
      });

      test('should have null fileName in loading state', () {
        // Arrange & Act
        const state = EditorState.loading();

        // Assert
        expect(state.fileName, isNull);
      });

      test('should have null fileId in loading state', () {
        // Arrange & Act
        const state = EditorState.loading();

        // Assert
        expect(state.fileId, isNull);
      });
    });

    group('Loaded State', () {
      test('should create loaded state with file', () {
        // Arrange & Act
        final state = EditorState.loaded(file: testFile);

        // Assert
        expect(state.isLoaded, isTrue);
        expect(state.isInitial, isFalse);
        expect(state.isLoading, isFalse);
        expect(state.isError, isFalse);
      });

      test('should have isDirty as false by default', () {
        // Arrange & Act
        final state = EditorState.loaded(file: testFile);

        // Assert
        state.mapOrNull(
          loaded: (s) => expect(s.isDirty, isFalse),
        );
      });

      test('should have isSaving as false by default', () {
        // Arrange & Act
        final state = EditorState.loaded(file: testFile);

        // Assert
        state.mapOrNull(
          loaded: (s) => expect(s.isSaving, isFalse),
        );
      });

      test('should create loaded state with isDirty true', () {
        // Arrange & Act
        final state = EditorState.loaded(
          file: testFile,
          isDirty: true,
        );

        // Assert
        state.mapOrNull(
          loaded: (s) => expect(s.isDirty, isTrue),
        );
      });

      test('should create loaded state with isSaving true', () {
        // Arrange & Act
        final state = EditorState.loaded(
          file: testFile,
          isSaving: true,
        );

        // Assert
        state.mapOrNull(
          loaded: (s) => expect(s.isSaving, isTrue),
        );
      });

      test('should store file correctly', () {
        // Arrange & Act
        final state = EditorState.loaded(file: testFile);

        // Assert
        state.mapOrNull(
          loaded: (s) {
            expect(s.file, equals(testFile));
            expect(s.file.id, equals('test-file-id'));
            expect(s.file.name, equals('test.dart'));
            expect(s.file.content, equals('void main() {}'));
          },
        );
      });

      group('canSave property', () {
        test('should be true when file is dirty and not saving', () {
          // Arrange & Act
          final state = EditorState.loaded(
            file: testFile,
            isDirty: true,
            isSaving: false,
          );

          // Assert
          expect(state.canSave, isTrue);
        });

        test('should be false when file is not dirty', () {
          // Arrange & Act
          final state = EditorState.loaded(
            file: testFile,
            isDirty: false,
            isSaving: false,
          );

          // Assert
          expect(state.canSave, isFalse);
        });

        test('should be false when file is saving', () {
          // Arrange & Act
          final state = EditorState.loaded(
            file: testFile,
            isDirty: true,
            isSaving: true,
          );

          // Assert
          expect(state.canSave, isFalse);
        });

        test('should be false when file is not dirty and saving', () {
          // Arrange & Act
          final state = EditorState.loaded(
            file: testFile,
            isDirty: false,
            isSaving: true,
          );

          // Assert
          expect(state.canSave, isFalse);
        });
      });

      test('should have correct fileName', () {
        // Arrange & Act
        final state = EditorState.loaded(file: testFile);

        // Assert
        expect(state.fileName, equals('test.dart'));
      });

      test('should have correct fileId', () {
        // Arrange & Act
        final state = EditorState.loaded(file: testFile);

        // Assert
        expect(state.fileId, equals('test-file-id'));
      });

      group('copyWith', () {
        test('should copy with updated file', () {
          // Arrange
          final state = EditorState.loaded(file: testFile);
          final updatedFile = testFile.updateContent('// New content');

          // Act
          final newState = state.mapOrNull(
            loaded: (s) => s.copyWith(file: updatedFile),
          );

          // Assert
          expect(newState, isNotNull);
          newState?.mapOrNull(
            loaded: (s) {
              expect(s.file.content, equals('// New content'));
              expect(s.isDirty, isFalse); // Should maintain default
            },
          );
        });

        test('should copy with updated isDirty', () {
          // Arrange
          final state = EditorState.loaded(file: testFile, isDirty: false);

          // Act
          final newState = state.mapOrNull(
            loaded: (s) => s.copyWith(isDirty: true),
          );

          // Assert
          newState?.mapOrNull(
            loaded: (s) => expect(s.isDirty, isTrue),
          );
        });

        test('should copy with updated isSaving', () {
          // Arrange
          final state = EditorState.loaded(file: testFile, isSaving: false);

          // Act
          final newState = state.mapOrNull(
            loaded: (s) => s.copyWith(isSaving: true),
          );

          // Assert
          newState?.mapOrNull(
            loaded: (s) => expect(s.isSaving, isTrue),
          );
        });

        test('should copy with multiple updated properties', () {
          // Arrange
          final state = EditorState.loaded(file: testFile);
          final updatedFile = testFile.updateContent('// Updated');

          // Act
          final newState = state.mapOrNull(
            loaded: (s) => s.copyWith(
              file: updatedFile,
              isDirty: true,
              isSaving: true,
            ),
          );

          // Assert
          newState?.mapOrNull(
            loaded: (s) {
              expect(s.file.content, equals('// Updated'));
              expect(s.isDirty, isTrue);
              expect(s.isSaving, isTrue);
            },
          );
        });
      });
    });

    group('Error State', () {
      test('should create error state with message', () {
        // Arrange & Act
        const state = EditorState.error(message: 'Something went wrong');

        // Assert
        expect(state.isError, isTrue);
        expect(state.isInitial, isFalse);
        expect(state.isLoading, isFalse);
        expect(state.isLoaded, isFalse);
      });

      test('should store error message correctly', () {
        // Arrange & Act
        const errorMessage = 'File not found';
        const state = EditorState.error(message: errorMessage);

        // Assert
        state.mapOrNull(
          error: (s) => expect(s.message, equals(errorMessage)),
        );
      });

      test('should have canSave as false in error state', () {
        // Arrange & Act
        const state = EditorState.error(message: 'Error occurred');

        // Assert
        expect(state.canSave, isFalse);
      });

      test('should have null fileName in error state', () {
        // Arrange & Act
        const state = EditorState.error(message: 'Error occurred');

        // Assert
        expect(state.fileName, isNull);
      });

      test('should have null fileId in error state', () {
        // Arrange & Act
        const state = EditorState.error(message: 'Error occurred');

        // Assert
        expect(state.fileId, isNull);
      });
    });

    group('State Transitions', () {
      test('should transition from initial to loading', () {
        // Arrange
        const initialState = EditorState.initial();

        // Act
        const loadingState = EditorState.loading();

        // Assert
        expect(initialState.isInitial, isTrue);
        expect(loadingState.isLoading, isTrue);
      });

      test('should transition from loading to loaded', () {
        // Arrange
        const loadingState = EditorState.loading();

        // Act
        final loadedState = EditorState.loaded(file: testFile);

        // Assert
        expect(loadingState.isLoading, isTrue);
        expect(loadedState.isLoaded, isTrue);
      });

      test('should transition from loading to error', () {
        // Arrange
        const loadingState = EditorState.loading();

        // Act
        const errorState = EditorState.error(message: 'Load failed');

        // Assert
        expect(loadingState.isLoading, isTrue);
        expect(errorState.isError, isTrue);
      });

      test('should transition from loaded to error', () {
        // Arrange
        final loadedState = EditorState.loaded(file: testFile);

        // Act
        const errorState = EditorState.error(message: 'Save failed');

        // Assert
        expect(loadedState.isLoaded, isTrue);
        expect(errorState.isError, isTrue);
      });

      test('should transition from loaded to initial on close', () {
        // Arrange
        final loadedState = EditorState.loaded(file: testFile);

        // Act
        const initialState = EditorState.initial();

        // Assert
        expect(loadedState.isLoaded, isTrue);
        expect(initialState.isInitial, isTrue);
      });
    });

    group('Pattern Matching', () {
      test('should match on initial state', () {
        // Arrange
        const state = EditorState.initial();

        // Act
        final result = state.map(
          initial: (_) => 'initial',
          loading: (_) => 'loading',
          loaded: (_) => 'loaded',
          error: (_) => 'error',
        );

        // Assert
        expect(result, equals('initial'));
      });

      test('should match on loading state', () {
        // Arrange
        const state = EditorState.loading();

        // Act
        final result = state.map(
          initial: (_) => 'initial',
          loading: (_) => 'loading',
          loaded: (_) => 'loaded',
          error: (_) => 'error',
        );

        // Assert
        expect(result, equals('loading'));
      });

      test('should match on loaded state', () {
        // Arrange
        final state = EditorState.loaded(file: testFile);

        // Act
        final result = state.map(
          initial: (_) => 'initial',
          loading: (_) => 'loading',
          loaded: (_) => 'loaded',
          error: (_) => 'error',
        );

        // Assert
        expect(result, equals('loaded'));
      });

      test('should match on error state', () {
        // Arrange
        const state = EditorState.error(message: 'Error');

        // Act
        final result = state.map(
          initial: (_) => 'initial',
          loading: (_) => 'loading',
          loaded: (_) => 'loaded',
          error: (_) => 'error',
        );

        // Assert
        expect(result, equals('error'));
      });

      test('should use maybeMap with orElse', () {
        // Arrange
        const state = EditorState.initial();

        // Act
        final result = state.maybeMap(
          loaded: (s) => 'loaded',
          orElse: () => 'other',
        );

        // Assert
        expect(result, equals('other'));
      });

      test('should use mapOrNull', () {
        // Arrange
        const state = EditorState.loading();

        // Act
        final result = state.mapOrNull(
          loaded: (s) => 'loaded',
        );

        // Assert
        expect(result, isNull);
      });
    });

    group('Equality', () {
      test('should be equal for same initial states', () {
        // Arrange
        const state1 = EditorState.initial();
        const state2 = EditorState.initial();

        // Assert
        expect(state1, equals(state2));
      });

      test('should be equal for same loading states', () {
        // Arrange
        const state1 = EditorState.loading();
        const state2 = EditorState.loading();

        // Assert
        expect(state1, equals(state2));
      });

      test('should be equal for same loaded states', () {
        // Arrange
        final state1 = EditorState.loaded(file: testFile);
        final state2 = EditorState.loaded(file: testFile);

        // Assert
        expect(state1, equals(state2));
      });

      test('should be equal for same error states', () {
        // Arrange
        const state1 = EditorState.error(message: 'Error');
        const state2 = EditorState.error(message: 'Error');

        // Assert
        expect(state1, equals(state2));
      });

      test('should not be equal for different state types', () {
        // Arrange
        const initial = EditorState.initial();
        const loading = EditorState.loading();

        // Assert
        expect(initial, isNot(equals(loading)));
      });

      test('should not be equal for loaded states with different isDirty', () {
        // Arrange
        final state1 = EditorState.loaded(file: testFile, isDirty: true);
        final state2 = EditorState.loaded(file: testFile, isDirty: false);

        // Assert
        expect(state1, isNot(equals(state2)));
      });

      test('should not be equal for error states with different messages', () {
        // Arrange
        const state1 = EditorState.error(message: 'Error 1');
        const state2 = EditorState.error(message: 'Error 2');

        // Assert
        expect(state1, isNot(equals(state2)));
      });
    });

    group('Use Cases', () {
      group('UC1: File loading workflow', () {
        test('should progress through states correctly', () {
          // Arrange & Act
          const initial = EditorState.initial();
          const loading = EditorState.loading();
          final loaded = EditorState.loaded(file: testFile);

          // Assert
          expect(initial.isInitial, isTrue);
          expect(loading.isLoading, isTrue);
          expect(loaded.isLoaded, isTrue);
          expect(loaded.canSave, isFalse);
        });
      });

      group('UC2: Edit and save workflow', () {
        test('should handle edit and save state changes', () {
          // Arrange
          final loaded = EditorState.loaded(file: testFile);

          // Act - Edit
          final dirty = loaded.mapOrNull(
            loaded: (s) => s.copyWith(isDirty: true),
          );

          // Act - Save
          final saving = dirty?.mapOrNull(
            loaded: (s) => s.copyWith(isSaving: true),
          );

          // Act - Save complete
          final saved = saving?.mapOrNull(
            loaded: (s) => s.copyWith(isDirty: false, isSaving: false),
          );

          // Assert
          expect(loaded.canSave, isFalse);

          dirty?.mapOrNull(
            loaded: (s) => expect(s.isDirty, isTrue),
          );
          expect(dirty?.canSave, isTrue);

          saving?.mapOrNull(
            loaded: (s) => expect(s.isSaving, isTrue),
          );
          expect(saving?.canSave, isFalse);

          saved?.mapOrNull(
            loaded: (s) {
              expect(s.isDirty, isFalse);
              expect(s.isSaving, isFalse);
            },
          );
          expect(saved?.canSave, isFalse);
        });
      });

      group('UC3: Error handling workflow', () {
        test('should handle load error', () {
          // Arrange
          const initial = EditorState.initial();
          const loading = EditorState.loading();

          // Act
          const error = EditorState.error(message: 'File not found');

          // Assert
          expect(initial.isInitial, isTrue);
          expect(loading.isLoading, isTrue);
          expect(error.isError, isTrue);
          expect(error.canSave, isFalse);
        });

        test('should handle save error', () {
          // Arrange
          final loaded = EditorState.loaded(file: testFile, isDirty: true);

          // Act
          const error = EditorState.error(message: 'Save failed');

          // Assert
          expect(loaded.canSave, isTrue);
          expect(error.isError, isTrue);
          expect(error.canSave, isFalse);
        });
      });
    });
  });
}
