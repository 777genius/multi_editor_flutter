import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';
import 'package:editor_core/editor_core.dart';
import 'package:ide_presentation/src/stores/editor/editor_store.dart';

import 'editor_store_test.mocks.dart';

@GenerateMocks([ICodeEditorRepository])
void main() {
  late EditorStore store;
  late MockICodeEditorRepository mockRepository;

  setUp(() {
    mockRepository = MockICodeEditorRepository();
    store = EditorStore(editorRepository: mockRepository);
  });

  tearDown(() {
    store.dispose();
  });

  group('EditorStore', () {
    group('openDocument', () {
      test('should open document successfully', () async {
        // Arrange
        final doc = EditorDocument(
          uri: DocumentUri.fromFilePath('/test/file.dart'),
          content: 'void main() {}',
          languageId: LanguageId.dart,
          lastModified: DateTime.now(),
        );

        when(mockRepository.openDocument(any))
            .thenAnswer((_) async => right(unit));

        // Act
        await store.openDocument(
          uri: doc.uri,
          language: doc.languageId,
          initialContent: doc.content,
        );

        // Assert
        expect(store.hasDocument, true);
        expect(store.documentUri, doc.uri);
        expect(store.languageId, doc.languageId);
        expect(store.content, doc.content);
        expect(store.isLoading, false);
        expect(store.hasUnsavedChanges, false);
      });

      test('should handle open document failure', () async {
        // Arrange
        when(mockRepository.openDocument(any)).thenAnswer(
          (_) async => left(
            const EditorFailure.operationFailed(
              operation: 'open',
              reason: 'Test failure',
            ),
          ),
        );

        // Act
        await store.openDocument(
          uri: DocumentUri.fromFilePath('/test/file.dart'),
          language: LanguageId.dart,
          initialContent: 'test',
        );

        // Assert
        expect(store.hasError, true);
        expect(store.errorMessage, isNotNull);
      });
    });

    group('insertText', () {
      test('should insert text and mark as unsaved', () async {
        // Arrange
        await _setupOpenDocument(store, mockRepository);

        when(mockRepository.insertText(any))
            .thenAnswer((_) async => right(unit));
        when(mockRepository.getContent())
            .thenAnswer((_) async => right('Hello'));
        when(mockRepository.getCursorPosition()).thenAnswer(
          (_) async => right(CursorPosition.create(line: 0, column: 5)),
        );

        // Act
        await store.insertText('Hello');

        // Assert
        expect(store.hasUnsavedChanges, true);
        expect(store.canUndo, true);
      });
    });

    group('undo/redo', () {
      test('should perform undo successfully', () async {
        // Arrange
        await _setupOpenDocument(store, mockRepository);
        store.canUndo = true;

        when(mockRepository.undo()).thenAnswer((_) async => right(unit));
        when(mockRepository.getContent())
            .thenAnswer((_) async => right('Original'));
        when(mockRepository.getCursorPosition()).thenAnswer(
          (_) async => right(CursorPosition.create(line: 0, column: 0)),
        );

        // Act
        await store.undo();

        // Assert
        expect(store.canRedo, true);
        verify(mockRepository.undo()).called(1);
      });

      test('should not undo when canUndo is false', () async {
        // Arrange
        await _setupOpenDocument(store, mockRepository);
        store.canUndo = false;

        // Act
        await store.undo();

        // Assert
        verifyNever(mockRepository.undo());
      });
    });

    group('updateContentFromUI', () {
      test('should debounce content sync', () async {
        // Arrange
        await _setupOpenDocument(store, mockRepository);

        // Act
        store.updateContentFromUI('Line 1');
        store.updateContentFromUI('Line 1\nLine 2');
        store.updateContentFromUI('Line 1\nLine 2\nLine 3');

        // Assert - Should mark as unsaved immediately
        expect(store.hasUnsavedChanges, true);
        expect(store.content, 'Line 1\nLine 2\nLine 3');

        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 350));

        // Repository should be called once after debounce
        verify(mockRepository.setContent(any)).called(greaterThanOrEqualTo(1));
      });
    });

    group('computed properties', () {
      test('isReady should be true when document is loaded', () async {
        // Arrange
        await _setupOpenDocument(store, mockRepository);

        // Assert
        expect(store.isReady, true);
      });

      test('lineCount should count lines correctly', () async {
        // Arrange
        await _setupOpenDocument(store, mockRepository);
        store.content = 'Line 1\nLine 2\nLine 3';

        // Assert
        expect(store.lineCount, 3);
      });

      test('currentLine should return line at cursor', () async {
        // Arrange
        await _setupOpenDocument(store, mockRepository);
        store.content = 'Line 1\nLine 2\nLine 3';
        store.cursorPosition = CursorPosition.create(line: 1, column: 0);

        // Assert
        expect(store.currentLine, 'Line 2');
      });
    });

    group('closeDocument', () {
      test('should reset all state when closing', () async {
        // Arrange
        await _setupOpenDocument(store, mockRepository);
        store.hasUnsavedChanges = true;
        store.canUndo = true;

        // Act
        store.closeDocument();

        // Assert
        expect(store.hasDocument, false);
        expect(store.content, '');
        expect(store.hasUnsavedChanges, false);
        expect(store.canUndo, false);
        expect(store.canRedo, false);
        expect(store.errorMessage, null);
      });
    });

    group('error handling', () {
      test('should set error on insertText failure', () async {
        // Arrange
        await _setupOpenDocument(store, mockRepository);

        when(mockRepository.insertText(any)).thenAnswer(
          (_) async => left(
            const EditorFailure.operationFailed(
              operation: 'insert',
              reason: 'Test error',
            ),
          ),
        );

        // Act
        await store.insertText('test');

        // Assert
        expect(store.hasError, true);
        expect(store.errorMessage, contains('Failed to insert text'));
      });

      test('should clear error', () async {
        // Arrange
        await _setupOpenDocument(store, mockRepository);
        store.errorMessage = 'Test error';
        store.errorFailure = const EditorFailure.unexpected(
          message: 'Test',
        );

        // Act
        store.clearError();

        // Assert
        expect(store.errorMessage, null);
        expect(store.errorFailure, null);
      });
    });
  });
}

/// Helper to setup open document
Future<void> _setupOpenDocument(
  EditorStore store,
  MockICodeEditorRepository mockRepository,
) async {
  when(mockRepository.openDocument(any))
      .thenAnswer((_) async => right(unit));

  await store.openDocument(
    uri: DocumentUri.fromFilePath('/test/file.dart'),
    language: LanguageId.dart,
    initialContent: 'test content',
  );
}
