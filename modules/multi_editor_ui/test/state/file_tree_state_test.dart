import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_ui/src/state/file_tree_state.dart';

void main() {
  group('FileTreeState', () {
    // Test data
    final rootNode = FileTreeNode.folder(
      id: 'root',
      name: 'root',
      children: [
        FileTreeNode.folder(
          id: 'src',
          name: 'src',
          parentId: 'root',
          children: [
            FileTreeNode.file(
              id: 'file-1',
              name: 'main.dart',
              parentId: 'src',
              language: 'dart',
            ),
          ],
        ),
        FileTreeNode.file(
          id: 'file-2',
          name: 'readme.md',
          parentId: 'root',
          language: 'markdown',
        ),
      ],
    );

    group('Initial State', () {
      test('should create initial state', () {
        // Arrange & Act
        const state = FileTreeState.initial();

        // Assert
        expect(state.isInitial, isTrue);
        expect(state.isLoading, isFalse);
        expect(state.isLoaded, isFalse);
        expect(state.isError, isFalse);
      });

      test('should have null rootNode in initial state', () {
        // Arrange & Act
        const state = FileTreeState.initial();

        // Assert
        expect(state.rootNode, isNull);
      });

      test('should have zero treeDepth in initial state', () {
        // Arrange & Act
        const state = FileTreeState.initial();

        // Assert
        expect(state.treeDepth, equals(0));
      });

      test('should have zero totalFiles in initial state', () {
        // Arrange & Act
        const state = FileTreeState.initial();

        // Assert
        expect(state.totalFiles, equals(0));
      });

      test('should have zero totalFolders in initial state', () {
        // Arrange & Act
        const state = FileTreeState.initial();

        // Assert
        expect(state.totalFolders, equals(0));
      });
    });

    group('Loading State', () {
      test('should create loading state', () {
        // Arrange & Act
        const state = FileTreeState.loading();

        // Assert
        expect(state.isLoading, isTrue);
        expect(state.isInitial, isFalse);
        expect(state.isLoaded, isFalse);
        expect(state.isError, isFalse);
      });

      test('should have null rootNode in loading state', () {
        // Arrange & Act
        const state = FileTreeState.loading();

        // Assert
        expect(state.rootNode, isNull);
      });

      test('should have zero treeDepth in loading state', () {
        // Arrange & Act
        const state = FileTreeState.loading();

        // Assert
        expect(state.treeDepth, equals(0));
      });
    });

    group('Loaded State', () {
      test('should create loaded state with root node', () {
        // Arrange & Act
        final state = FileTreeState.loaded(rootNode: rootNode);

        // Assert
        expect(state.isLoaded, isTrue);
        expect(state.isInitial, isFalse);
        expect(state.isLoading, isFalse);
        expect(state.isError, isFalse);
      });

      test('should store rootNode correctly', () {
        // Arrange & Act
        final state = FileTreeState.loaded(rootNode: rootNode);

        // Assert
        expect(state.rootNode, equals(rootNode));
        expect(state.rootNode?.name, equals('root'));
      });

      test('should have null selectedNodeId by default', () {
        // Arrange & Act
        final state = FileTreeState.loaded(rootNode: rootNode);

        // Assert
        state.mapOrNull(
          loaded: (s) => expect(s.selectedNodeId, isNull),
        );
      });

      test('should have empty expandedFolderIds by default', () {
        // Arrange & Act
        final state = FileTreeState.loaded(rootNode: rootNode);

        // Assert
        state.mapOrNull(
          loaded: (s) => expect(s.expandedFolderIds, isEmpty),
        );
      });

      test('should create loaded state with selectedNodeId', () {
        // Arrange & Act
        final state = FileTreeState.loaded(
          rootNode: rootNode,
          selectedNodeId: 'file-1',
        );

        // Assert
        state.mapOrNull(
          loaded: (s) => expect(s.selectedNodeId, equals('file-1')),
        );
      });

      test('should create loaded state with expandedFolderIds', () {
        // Arrange & Act
        final state = FileTreeState.loaded(
          rootNode: rootNode,
          expandedFolderIds: ['root', 'src'],
        );

        // Assert
        state.mapOrNull(
          loaded: (s) {
            expect(s.expandedFolderIds, contains('root'));
            expect(s.expandedFolderIds, contains('src'));
          },
        );
      });

      test('should calculate treeDepth correctly', () {
        // Arrange & Act
        final state = FileTreeState.loaded(rootNode: rootNode);

        // Assert
        expect(state.treeDepth, equals(2)); // root -> src -> file
      });

      test('should calculate totalFiles correctly', () {
        // Arrange & Act
        final state = FileTreeState.loaded(rootNode: rootNode);

        // Assert
        expect(state.totalFiles, equals(2)); // main.dart and readme.md
      });

      test('should calculate totalFolders correctly', () {
        // Arrange & Act
        final state = FileTreeState.loaded(rootNode: rootNode);

        // Assert
        expect(state.totalFolders, equals(2)); // root and src
      });

      group('copyWith', () {
        test('should copy with updated rootNode', () {
          // Arrange
          final state = FileTreeState.loaded(rootNode: rootNode);
          final newRootNode = FileTreeNode.folder(
            id: 'new-root',
            name: 'new-root',
          );

          // Act
          final newState = state.mapOrNull(
            loaded: (s) => s.copyWith(rootNode: newRootNode),
          );

          // Assert
          expect(newState?.rootNode?.name, equals('new-root'));
        });

        test('should copy with updated selectedNodeId', () {
          // Arrange
          final state = FileTreeState.loaded(rootNode: rootNode);

          // Act
          final newState = state.mapOrNull(
            loaded: (s) => s.copyWith(selectedNodeId: 'file-1'),
          );

          // Assert
          newState?.mapOrNull(
            loaded: (s) => expect(s.selectedNodeId, equals('file-1')),
          );
        });

        test('should copy with updated expandedFolderIds', () {
          // Arrange
          final state = FileTreeState.loaded(rootNode: rootNode);

          // Act
          final newState = state.mapOrNull(
            loaded: (s) => s.copyWith(expandedFolderIds: ['root', 'src']),
          );

          // Assert
          newState?.mapOrNull(
            loaded: (s) {
              expect(s.expandedFolderIds, contains('root'));
              expect(s.expandedFolderIds, contains('src'));
            },
          );
        });

        test('should copy with multiple updated properties', () {
          // Arrange
          final state = FileTreeState.loaded(rootNode: rootNode);

          // Act
          final newState = state.mapOrNull(
            loaded: (s) => s.copyWith(
              selectedNodeId: 'file-2',
              expandedFolderIds: ['root'],
            ),
          );

          // Assert
          newState?.mapOrNull(
            loaded: (s) {
              expect(s.selectedNodeId, equals('file-2'));
              expect(s.expandedFolderIds, equals(['root']));
            },
          );
        });
      });
    });

    group('Error State', () {
      test('should create error state with message', () {
        // Arrange & Act
        const state = FileTreeState.error(message: 'Failed to load tree');

        // Assert
        expect(state.isError, isTrue);
        expect(state.isInitial, isFalse);
        expect(state.isLoading, isFalse);
        expect(state.isLoaded, isFalse);
      });

      test('should store error message correctly', () {
        // Arrange & Act
        const errorMessage = 'Network error';
        const state = FileTreeState.error(message: errorMessage);

        // Assert
        state.mapOrNull(
          error: (s) => expect(s.message, equals(errorMessage)),
        );
      });

      test('should have null rootNode in error state', () {
        // Arrange & Act
        const state = FileTreeState.error(message: 'Error');

        // Assert
        expect(state.rootNode, isNull);
      });

      test('should have zero treeDepth in error state', () {
        // Arrange & Act
        const state = FileTreeState.error(message: 'Error');

        // Assert
        expect(state.treeDepth, equals(0));
      });

      test('should have zero totalFiles in error state', () {
        // Arrange & Act
        const state = FileTreeState.error(message: 'Error');

        // Assert
        expect(state.totalFiles, equals(0));
      });

      test('should have zero totalFolders in error state', () {
        // Arrange & Act
        const state = FileTreeState.error(message: 'Error');

        // Assert
        expect(state.totalFolders, equals(0));
      });
    });

    group('isFolderExpanded', () {
      test('should return true for expanded folder', () {
        // Arrange
        final state = FileTreeState.loaded(
          rootNode: rootNode,
          expandedFolderIds: ['root', 'src'],
        );

        // Act & Assert
        expect(state.isFolderExpanded('root'), isTrue);
        expect(state.isFolderExpanded('src'), isTrue);
      });

      test('should return false for collapsed folder', () {
        // Arrange
        final state = FileTreeState.loaded(
          rootNode: rootNode,
          expandedFolderIds: ['root'],
        );

        // Act & Assert
        expect(state.isFolderExpanded('src'), isFalse);
      });

      test('should return false in non-loaded state', () {
        // Arrange
        const state = FileTreeState.initial();

        // Act & Assert
        expect(state.isFolderExpanded('root'), isFalse);
      });
    });

    group('isNodeSelected', () {
      test('should return true for selected node', () {
        // Arrange
        final state = FileTreeState.loaded(
          rootNode: rootNode,
          selectedNodeId: 'file-1',
        );

        // Act & Assert
        expect(state.isNodeSelected('file-1'), isTrue);
      });

      test('should return false for non-selected node', () {
        // Arrange
        final state = FileTreeState.loaded(
          rootNode: rootNode,
          selectedNodeId: 'file-1',
        );

        // Act & Assert
        expect(state.isNodeSelected('file-2'), isFalse);
      });

      test('should return false when no node is selected', () {
        // Arrange
        final state = FileTreeState.loaded(rootNode: rootNode);

        // Act & Assert
        expect(state.isNodeSelected('file-1'), isFalse);
      });

      test('should return false in non-loaded state', () {
        // Arrange
        const state = FileTreeState.initial();

        // Act & Assert
        expect(state.isNodeSelected('file-1'), isFalse);
      });
    });

    group('isFileSelected', () {
      test('should return true for selected file', () {
        // Arrange
        final state = FileTreeState.loaded(
          rootNode: rootNode,
          selectedNodeId: 'file-1',
        );

        // Act & Assert
        expect(state.isFileSelected('file-1'), isTrue);
      });

      test('should return false for non-selected file', () {
        // Arrange
        final state = FileTreeState.loaded(
          rootNode: rootNode,
          selectedNodeId: 'file-1',
        );

        // Act & Assert
        expect(state.isFileSelected('file-2'), isFalse);
      });
    });

    group('State Transitions', () {
      test('should transition from initial to loading', () {
        // Arrange
        const initialState = FileTreeState.initial();

        // Act
        const loadingState = FileTreeState.loading();

        // Assert
        expect(initialState.isInitial, isTrue);
        expect(loadingState.isLoading, isTrue);
      });

      test('should transition from loading to loaded', () {
        // Arrange
        const loadingState = FileTreeState.loading();

        // Act
        final loadedState = FileTreeState.loaded(rootNode: rootNode);

        // Assert
        expect(loadingState.isLoading, isTrue);
        expect(loadedState.isLoaded, isTrue);
      });

      test('should transition from loading to error', () {
        // Arrange
        const loadingState = FileTreeState.loading();

        // Act
        const errorState = FileTreeState.error(message: 'Load failed');

        // Assert
        expect(loadingState.isLoading, isTrue);
        expect(errorState.isError, isTrue);
      });

      test('should update loaded state with new tree', () {
        // Arrange
        final loadedState = FileTreeState.loaded(rootNode: rootNode);

        // Act
        final newRootNode = FileTreeNode.folder(
          id: 'new-root',
          name: 'new-root',
        );

        final updatedState = loadedState.mapOrNull(
          loaded: (s) => s.copyWith(rootNode: newRootNode),
        );

        // Assert
        expect(loadedState.rootNode?.name, equals('root'));
        expect(updatedState?.rootNode?.name, equals('new-root'));
      });
    });

    group('Pattern Matching', () {
      test('should match on initial state', () {
        // Arrange
        const state = FileTreeState.initial();

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
        const state = FileTreeState.loading();

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
        final state = FileTreeState.loaded(rootNode: rootNode);

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
        const state = FileTreeState.error(message: 'Error');

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
        const state = FileTreeState.initial();

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
        const state = FileTreeState.loading();

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
        const state1 = FileTreeState.initial();
        const state2 = FileTreeState.initial();

        // Assert
        expect(state1, equals(state2));
      });

      test('should be equal for same loading states', () {
        // Arrange
        const state1 = FileTreeState.loading();
        const state2 = FileTreeState.loading();

        // Assert
        expect(state1, equals(state2));
      });

      test('should be equal for same loaded states', () {
        // Arrange
        final state1 = FileTreeState.loaded(rootNode: rootNode);
        final state2 = FileTreeState.loaded(rootNode: rootNode);

        // Assert
        expect(state1, equals(state2));
      });

      test('should be equal for same error states', () {
        // Arrange
        const state1 = FileTreeState.error(message: 'Error');
        const state2 = FileTreeState.error(message: 'Error');

        // Assert
        expect(state1, equals(state2));
      });

      test('should not be equal for different state types', () {
        // Arrange
        const initial = FileTreeState.initial();
        const loading = FileTreeState.loading();

        // Assert
        expect(initial, isNot(equals(loading)));
      });

      test('should not be equal for loaded states with different selectedNodeId', () {
        // Arrange
        final state1 = FileTreeState.loaded(
          rootNode: rootNode,
          selectedNodeId: 'file-1',
        );
        final state2 = FileTreeState.loaded(
          rootNode: rootNode,
          selectedNodeId: 'file-2',
        );

        // Assert
        expect(state1, isNot(equals(state2)));
      });

      test('should not be equal for loaded states with different expandedFolderIds', () {
        // Arrange
        final state1 = FileTreeState.loaded(
          rootNode: rootNode,
          expandedFolderIds: ['root'],
        );
        final state2 = FileTreeState.loaded(
          rootNode: rootNode,
          expandedFolderIds: ['root', 'src'],
        );

        // Assert
        expect(state1, isNot(equals(state2)));
      });

      test('should not be equal for error states with different messages', () {
        // Arrange
        const state1 = FileTreeState.error(message: 'Error 1');
        const state2 = FileTreeState.error(message: 'Error 2');

        // Assert
        expect(state1, isNot(equals(state2)));
      });
    });

    group('Use Cases', () {
      group('UC1: Load and display file tree', () {
        test('should progress through states correctly', () {
          // Arrange & Act
          const initial = FileTreeState.initial();
          const loading = FileTreeState.loading();
          final loaded = FileTreeState.loaded(rootNode: rootNode);

          // Assert
          expect(initial.isInitial, isTrue);
          expect(initial.totalFiles, equals(0));

          expect(loading.isLoading, isTrue);
          expect(loading.totalFiles, equals(0));

          expect(loaded.isLoaded, isTrue);
          expect(loaded.totalFiles, equals(2));
          expect(loaded.totalFolders, equals(2));
        });
      });

      group('UC2: Navigate and expand folders', () {
        test('should handle folder expansion and selection', () {
          // Arrange
          final state = FileTreeState.loaded(rootNode: rootNode);

          // Act - Expand root
          final expandedRoot = state.mapOrNull(
            loaded: (s) => s.copyWith(
              expandedFolderIds: ['root'],
              selectedNodeId: 'root',
            ),
          );

          // Act - Expand src
          final expandedBoth = expandedRoot?.mapOrNull(
            loaded: (s) => s.copyWith(
              expandedFolderIds: ['root', 'src'],
              selectedNodeId: 'src',
            ),
          );

          // Assert
          expect(state.isFolderExpanded('root'), isFalse);

          expandedRoot?.mapOrNull(
            loaded: (s) {
              expect(s.expandedFolderIds, contains('root'));
              expect(s.selectedNodeId, equals('root'));
            },
          );
          expect(expandedRoot?.isFolderExpanded('root'), isTrue);

          expandedBoth?.mapOrNull(
            loaded: (s) {
              expect(s.expandedFolderIds, contains('root'));
              expect(s.expandedFolderIds, contains('src'));
              expect(s.selectedNodeId, equals('src'));
            },
          );
          expect(expandedBoth?.isFolderExpanded('src'), isTrue);
        });
      });

      group('UC3: Select file for editing', () {
        test('should select file and maintain tree state', () {
          // Arrange
          final state = FileTreeState.loaded(
            rootNode: rootNode,
            expandedFolderIds: ['root', 'src'],
          );

          // Act
          final selectedFile = state.mapOrNull(
            loaded: (s) => s.copyWith(selectedNodeId: 'file-1'),
          );

          // Assert
          selectedFile?.mapOrNull(
            loaded: (s) {
              expect(s.selectedNodeId, equals('file-1'));
              expect(s.expandedFolderIds, contains('root'));
              expect(s.expandedFolderIds, contains('src'));
            },
          );

          expect(selectedFile?.isFileSelected('file-1'), isTrue);
          expect(selectedFile?.isFolderExpanded('root'), isTrue);
        });
      });

      group('UC4: Error recovery', () {
        test('should handle load error and allow retry', () {
          // Arrange
          const initial = FileTreeState.initial();
          const loading = FileTreeState.loading();

          // Act
          const error = FileTreeState.error(message: 'Network error');

          // Retry
          const retryLoading = FileTreeState.loading();
          final retryLoaded = FileTreeState.loaded(rootNode: rootNode);

          // Assert
          expect(initial.isInitial, isTrue);
          expect(loading.isLoading, isTrue);
          expect(error.isError, isTrue);
          expect(error.totalFiles, equals(0));

          expect(retryLoading.isLoading, isTrue);
          expect(retryLoaded.isLoaded, isTrue);
          expect(retryLoaded.totalFiles, equals(2));
        });
      });
    });
  });
}
