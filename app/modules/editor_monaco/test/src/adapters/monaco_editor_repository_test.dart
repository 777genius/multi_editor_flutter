import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_monaco_crossplatform/flutter_monaco_crossplatform.dart';
import 'package:editor_core/editor_core.dart';
import 'package:editor_monaco/src/adapters/monaco_editor_repository.dart';

class MockMonacoController extends Mock implements MonacoController {}

void main() {
  setUpAll(() {
    registerFallbackValue(MonacoLanguage.dart);
    registerFallbackValue(MonacoTheme.vs);
    registerFallbackValue(EditorDocument(
      id: 'fallback',
      path: '/fallback',
      name: 'fallback',
      content: '',
      languageId: LanguageId.plaintext,
    ));
  });

  group('MonacoEditorRepository', () {
    late MonacoEditorRepository repository;
    late MockMonacoController mockController;
    late StreamController<void> contentChangedController;
    late StreamController<void> selectionChangedController;
    late StreamController<void> focusController;
    late StreamController<void> blurController;

    setUp(() {
      repository = MonacoEditorRepository();
      mockController = MockMonacoController();

      // Setup stream controllers
      contentChangedController = StreamController<void>.broadcast();
      selectionChangedController = StreamController<void>.broadcast();
      focusController = StreamController<void>.broadcast();
      blurController = StreamController<void>.broadcast();

      // Setup default mock behaviors
      when(() => mockController.onReady).thenAnswer((_) => Future.value());
      when(() => mockController.onContentChanged)
          .thenAnswer((_) => contentChangedController.stream);
      when(() => mockController.onSelectionChanged)
          .thenAnswer((_) => selectionChangedController.stream);
      when(() => mockController.onFocus)
          .thenAnswer((_) => focusController.stream);
      when(() => mockController.onBlur)
          .thenAnswer((_) => blurController.stream);
      when(() => mockController.getValue())
          .thenAnswer((_) => Future.value('test content'));
      when(() => mockController.dispose()).thenReturn(null);
    });

    tearDown(() async {
      await contentChangedController.close();
      await selectionChangedController.close();
      await focusController.close();
      await blurController.close();
      await repository.dispose();
    });

    group('lifecycle', () {
      test('should not be ready before controller is set', () {
        // Assert
        expect(repository.isReady, false);
      });

      test('should be ready after controller is set', () {
        // Act
        repository.setController(mockController);

        // Assert
        expect(repository.isReady, true);
      });

      test('should initialize successfully when controller is ready', () async {
        // Arrange
        repository.setController(mockController);

        // Act
        final result = await repository.initialize();

        // Assert
        expect(result.isRight(), true);
        verify(() => mockController.onReady).called(1);
      });

      test('should fail to initialize when controller is not set', () async {
        // Act
        final result = await repository.initialize();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<EditorFailure>()),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should handle initialization error', () async {
        // Arrange
        repository.setController(mockController);
        when(() => mockController.onReady)
            .thenAnswer((_) => Future.error(Exception('Init failed')));

        // Act
        final result = await repository.initialize();

        // Assert
        expect(result.isLeft(), true);
      });

      test('should dispose all resources', () async {
        // Arrange
        repository.setController(mockController);

        // Act
        await repository.dispose();

        // Assert
        verify(() => mockController.dispose()).called(1);
        expect(repository.isReady, false);
      });
    });

    group('document management', () {
      late EditorDocument testDocument;

      setUp(() {
        testDocument = EditorDocument(
          id: 'test-123',
          path: '/test/file.dart',
          name: 'file.dart',
          content: 'void main() {}',
          languageId: LanguageId.dart,
        );

        repository.setController(mockController);
        when(() => mockController.setValue(any()))
            .thenAnswer((_) => Future.value());
        when(() => mockController.setLanguage(any()))
            .thenAnswer((_) => Future.value());
      });

      test('should successfully open document', () async {
        // Act
        final result = await repository.openDocument(testDocument);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockController.setValue(testDocument.content)).called(1);
        verify(() => mockController.setLanguage(MonacoLanguage.dart)).called(1);
      });

      test('should fail to open document when controller not set', () async {
        // Arrange
        final repo = MonacoEditorRepository();

        // Act
        final result = await repo.openDocument(testDocument);

        // Assert
        expect(result.isLeft(), true);

        await repo.dispose();
      });

      test('should handle error when opening document', () async {
        // Arrange
        when(() => mockController.setValue(any()))
            .thenThrow(Exception('Failed to set value'));

        // Act
        final result = await repository.openDocument(testDocument);

        // Assert
        expect(result.isLeft(), true);
      });

      test('should get content successfully', () async {
        // Arrange
        when(() => mockController.getValue())
            .thenAnswer((_) => Future.value('current content'));

        // Act
        final result = await repository.getContent();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (content) => expect(content, 'current content'),
        );
      });

      test('should fail to get content when controller not set', () async {
        // Arrange
        final repo = MonacoEditorRepository();

        // Act
        final result = await repo.getContent();

        // Assert
        expect(result.isLeft(), true);

        await repo.dispose();
      });

      test('should set content successfully', () async {
        // Arrange
        const newContent = 'new content';

        // Act
        final result = await repository.setContent(newContent);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockController.setValue(newContent)).called(1);
      });

      test('should update current document when setting content', () async {
        // Arrange
        await repository.openDocument(testDocument);
        const newContent = 'updated content';

        // Act
        await repository.setContent(newContent);
        final docResult = await repository.getCurrentDocument();

        // Assert
        expect(docResult.isRight(), true);
        docResult.fold(
          (_) => fail('Expected Right but got Left'),
          (doc) => expect(doc.content, newContent),
        );
      });

      test('should get current document', () async {
        // Arrange
        await repository.openDocument(testDocument);

        // Act
        final result = await repository.getCurrentDocument();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (doc) => expect(doc.id, testDocument.id),
        );
      });

      test('should fail to get current document when none is open', () async {
        // Act
        final result = await repository.getCurrentDocument();

        // Assert
        expect(result.isLeft(), true);
      });

      test('should close document successfully', () async {
        // Arrange
        await repository.openDocument(testDocument);

        // Act
        final result = await repository.closeDocument();

        // Assert
        expect(result.isRight(), true);

        // Verify document is no longer accessible
        final docResult = await repository.getCurrentDocument();
        expect(docResult.isLeft(), true);
      });
    });

    group('language and syntax', () {
      setUp(() {
        repository.setController(mockController);
        when(() => mockController.setLanguage(any()))
            .thenAnswer((_) => Future.value());
      });

      test('should set language successfully', () async {
        // Act
        final result = await repository.setLanguage(LanguageId.dart);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockController.setLanguage(MonacoLanguage.dart)).called(1);
      });

      test('should handle JavaScript language', () async {
        // Act
        final result = await repository.setLanguage(LanguageId.javascript);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockController.setLanguage(MonacoLanguage.javascript))
            .called(1);
      });

      test('should get language from current document', () async {
        // Arrange
        final document = EditorDocument(
          id: 'test',
          path: '/test.ts',
          name: 'test.ts',
          content: '',
          languageId: LanguageId.typescript,
        );
        await repository.openDocument(document);

        // Act
        final result = await repository.getLanguage();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right but got Left'),
          (lang) => expect(lang, LanguageId.typescript),
        );
      });

      test('should fail to get language when no document is open', () async {
        // Act
        final result = await repository.getLanguage();

        // Assert
        expect(result.isLeft(), true);
      });

      test('should fail to set language when controller not set', () async {
        // Arrange
        final repo = MonacoEditorRepository();

        // Act
        final result = await repo.setLanguage(LanguageId.dart);

        // Assert
        expect(result.isLeft(), true);

        await repo.dispose();
      });
    });

    group('theme and appearance', () {
      setUp(() {
        repository.setController(mockController);
        when(() => mockController.setTheme(any()))
            .thenAnswer((_) => Future.value());
      });

      test('should set theme successfully', () async {
        // Act
        final result = await repository.setTheme(EditorTheme.dark);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockController.setTheme(MonacoTheme.vsDark)).called(1);
      });

      test('should set light theme', () async {
        // Act
        final result = await repository.setTheme(EditorTheme.light);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockController.setTheme(MonacoTheme.vs)).called(1);
      });

      test('should fail to get theme (unsupported operation)', () async {
        // Act
        final result = await repository.getTheme();

        // Assert
        expect(result.isLeft(), true);
      });
    });

    group('cursor and selection', () {
      setUp(() {
        repository.setController(mockController);
        when(() => mockController.revealLine(any()))
            .thenAnswer((_) => Future.value());
      });

      test('should set cursor position successfully', () async {
        // Arrange
        final position = CursorPosition.create(line: 5, column: 10);

        // Act
        final result = await repository.setCursorPosition(position);

        // Assert
        expect(result.isRight(), true);
        // Monaco uses 1-indexed, so line 5 becomes 6
        verify(() => mockController.revealLine(6)).called(1);
      });

      test('should get cursor position returns unsupported', () async {
        // Act
        final result = await repository.getCursorPosition();

        // Assert
        expect(result.isLeft(), true);
      });

      test('should get selection returns unsupported', () async {
        // Act
        final result = await repository.getSelection();

        // Assert
        expect(result.isLeft(), true);
      });

      test('should set selection returns unsupported', () async {
        // Arrange
        final selection = TextSelection(
          start: CursorPosition.create(line: 0, column: 0),
          end: CursorPosition.create(line: 1, column: 0),
        );

        // Act
        final result = await repository.setSelection(selection);

        // Assert
        expect(result.isLeft(), true);
      });
    });

    group('text operations', () {
      setUp(() {
        repository.setController(mockController);
        when(() => mockController.format()).thenAnswer((_) => Future.value());
      });

      test('should format document successfully', () async {
        // Act
        final result = await repository.formatDocument();

        // Assert
        expect(result.isRight(), true);
        verify(() => mockController.format()).called(1);
      });

      test('should fail to format when controller not set', () async {
        // Arrange
        final repo = MonacoEditorRepository();

        // Act
        final result = await repo.formatDocument();

        // Assert
        expect(result.isLeft(), true);

        await repo.dispose();
      });

      test('should return unsupported for insertText', () async {
        // Act
        final result = await repository.insertText('test');

        // Assert
        expect(result.isLeft(), true);
      });

      test('should return unsupported for replaceText', () async {
        // Act
        final result = await repository.replaceText(
          start: CursorPosition.create(line: 0, column: 0),
          end: CursorPosition.create(line: 1, column: 0),
          text: 'replacement',
        );

        // Assert
        expect(result.isLeft(), true);
      });
    });

    group('editor actions', () {
      setUp(() {
        repository.setController(mockController);
        when(() => mockController.undo()).thenAnswer((_) => Future.value());
        when(() => mockController.redo()).thenAnswer((_) => Future.value());
        when(() => mockController.find(any()))
            .thenAnswer((_) => Future.value());
        when(() => mockController.replace(any(), any()))
            .thenAnswer((_) => Future.value());
      });

      test('should undo successfully', () async {
        // Act
        final result = await repository.undo();

        // Assert
        expect(result.isRight(), true);
        verify(() => mockController.undo()).called(1);
      });

      test('should redo successfully', () async {
        // Act
        final result = await repository.redo();

        // Assert
        expect(result.isRight(), true);
        verify(() => mockController.redo()).called(1);
      });

      test('should find text successfully', () async {
        // Act
        final result = await repository.find('searchTerm');

        // Assert
        expect(result.isRight(), true);
        verify(() => mockController.find('searchTerm')).called(1);
      });

      test('should replace text successfully', () async {
        // Act
        final result = await repository.replace(
          searchText: 'old',
          replaceText: 'new',
        );

        // Assert
        expect(result.isRight(), true);
        verify(() => mockController.replace('old', 'new')).called(1);
      });

      test('should handle undo error', () async {
        // Arrange
        when(() => mockController.undo())
            .thenThrow(Exception('Undo failed'));

        // Act
        final result = await repository.undo();

        // Assert
        expect(result.isLeft(), true);
      });

      test('should handle redo error', () async {
        // Arrange
        when(() => mockController.redo())
            .thenThrow(Exception('Redo failed'));

        // Act
        final result = await repository.redo();

        // Assert
        expect(result.isLeft(), true);
      });
    });

    group('navigation', () {
      setUp(() {
        repository.setController(mockController);
        when(() => mockController.revealLine(any()))
            .thenAnswer((_) => Future.value());
        when(() => mockController.focus()).thenAnswer((_) => Future.value());
      });

      test('should scroll to line successfully', () async {
        // Act
        final result = await repository.scrollToLine(10);

        // Assert
        expect(result.isRight(), true);
        // Monaco uses 1-indexed, so line 10 becomes 11
        verify(() => mockController.revealLine(11)).called(1);
      });

      test('should reveal line successfully', () async {
        // Act
        final result = await repository.revealLine(5);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockController.revealLine(6)).called(1);
      });

      test('should focus editor successfully', () async {
        // Act
        final result = await repository.focus();

        // Assert
        expect(result.isRight(), true);
        verify(() => mockController.focus()).called(1);
      });

      test('should handle scroll error', () async {
        // Arrange
        when(() => mockController.revealLine(any()))
            .thenThrow(Exception('Scroll failed'));

        // Act
        final result = await repository.scrollToLine(10);

        // Assert
        expect(result.isLeft(), true);
      });
    });

    group('events', () {
      setUp(() {
        repository.setController(mockController);
      });

      test('should emit content changed events', () async {
        // Arrange
        when(() => mockController.getValue())
            .thenAnswer((_) => Future.value('new content'));

        final events = <String>[];
        repository.onContentChanged.listen(events.add);

        // Act
        contentChangedController.add(null);
        await Future.delayed(const Duration(milliseconds: 350));

        // Assert
        expect(events, isNotEmpty);
        expect(events.last, 'new content');
      });

      test('should debounce content changed events', () async {
        // Arrange
        when(() => mockController.getValue())
            .thenAnswer((_) => Future.value('content'));

        final events = <String>[];
        repository.onContentChanged.listen(events.add);

        // Act - Fire multiple events quickly
        contentChangedController.add(null);
        contentChangedController.add(null);
        contentChangedController.add(null);
        await Future.delayed(const Duration(milliseconds: 350));

        // Assert - Should only get one event due to debouncing
        expect(events.length, 1);
      });

      test('should emit focus changed events', () async {
        // Arrange
        final events = <bool>[];
        repository.onFocusChanged.listen(events.add);

        // Act
        focusController.add(null);
        await Future.delayed(Duration.zero);

        blurController.add(null);
        await Future.delayed(Duration.zero);

        // Assert
        expect(events, [true, false]);
      });

      test('should update current document content on content change',
          () async {
        // Arrange
        final document = EditorDocument(
          id: 'test',
          path: '/test.dart',
          name: 'test.dart',
          content: 'original',
          languageId: LanguageId.dart,
        );
        await repository.openDocument(document);

        when(() => mockController.getValue())
            .thenAnswer((_) => Future.value('updated'));

        // Act
        contentChangedController.add(null);
        await Future.delayed(const Duration(milliseconds: 350));

        // Assert
        final docResult = await repository.getCurrentDocument();
        docResult.fold(
          (_) => fail('Expected Right but got Left'),
          (doc) => expect(doc.content, 'updated'),
        );
      });
    });

    group('error handling', () {
      setUp(() {
        repository.setController(mockController);
      });

      test('should handle setValue error', () async {
        // Arrange
        when(() => mockController.setValue(any()))
            .thenThrow(Exception('setValue failed'));

        // Act
        final result = await repository.setContent('test');

        // Assert
        expect(result.isLeft(), true);
      });

      test('should handle setLanguage error', () async {
        // Arrange
        when(() => mockController.setLanguage(any()))
            .thenThrow(Exception('setLanguage failed'));

        // Act
        final result = await repository.setLanguage(LanguageId.dart);

        // Assert
        expect(result.isLeft(), true);
      });

      test('should handle setTheme error', () async {
        // Arrange
        when(() => mockController.setTheme(any()))
            .thenThrow(Exception('setTheme failed'));

        // Act
        final result = await repository.setTheme(EditorTheme.dark);

        // Assert
        expect(result.isLeft(), true);
      });

      test('should handle format error', () async {
        // Arrange
        when(() => mockController.format())
            .thenThrow(Exception('format failed'));

        // Act
        final result = await repository.formatDocument();

        // Assert
        expect(result.isLeft(), true);
      });

      test('should handle focus error', () async {
        // Arrange
        when(() => mockController.focus())
            .thenThrow(Exception('focus failed'));

        // Act
        final result = await repository.focus();

        // Assert
        expect(result.isLeft(), true);
      });
    });

    group('integration scenarios', () {
      late EditorDocument document;

      setUp(() {
        repository.setController(mockController);
        document = EditorDocument(
          id: 'integration-test',
          path: '/test/integration.dart',
          name: 'integration.dart',
          content: 'void main() {\n  print("Hello");\n}',
          languageId: LanguageId.dart,
        );

        when(() => mockController.setValue(any()))
            .thenAnswer((_) => Future.value());
        when(() => mockController.setLanguage(any()))
            .thenAnswer((_) => Future.value());
        when(() => mockController.setTheme(any()))
            .thenAnswer((_) => Future.value());
        when(() => mockController.format()).thenAnswer((_) => Future.value());
        when(() => mockController.undo()).thenAnswer((_) => Future.value());
        when(() => mockController.redo()).thenAnswer((_) => Future.value());
      });

      test('should handle complete editing workflow', () async {
        // Open document
        var result = await repository.openDocument(document);
        expect(result.isRight(), true);

        // Set theme
        result = await repository.setTheme(EditorTheme.dark);
        expect(result.isRight(), true);

        // Format document
        result = await repository.formatDocument();
        expect(result.isRight(), true);

        // Undo
        result = await repository.undo();
        expect(result.isRight(), true);

        // Redo
        result = await repository.redo();
        expect(result.isRight(), true);

        // Close document
        result = await repository.closeDocument();
        expect(result.isRight(), true);
      });

      test('should handle document switching', () async {
        // Arrange
        final document2 = EditorDocument(
          id: 'doc-2',
          path: '/test/doc2.ts',
          name: 'doc2.ts',
          content: 'console.log("test");',
          languageId: LanguageId.typescript,
        );

        // Act - Open first document
        await repository.openDocument(document);
        var docResult = await repository.getCurrentDocument();
        expect(docResult.isRight(), true);
        docResult.fold(
          (_) => fail('Expected Right'),
          (doc) => expect(doc.id, 'integration-test'),
        );

        // Act - Open second document
        await repository.openDocument(document2);
        docResult = await repository.getCurrentDocument();
        expect(docResult.isRight(), true);
        docResult.fold(
          (_) => fail('Expected Right'),
          (doc) => expect(doc.id, 'doc-2'),
        );
      });
    });

    group('edge cases', () {
      setUp(() {
        repository.setController(mockController);
      });

      test('should handle empty content', () async {
        // Arrange
        when(() => mockController.setValue(any()))
            .thenAnswer((_) => Future.value());

        // Act
        final result = await repository.setContent('');

        // Assert
        expect(result.isRight(), true);
      });

      test('should handle very long content', () async {
        // Arrange
        final longContent = 'a' * 100000;
        when(() => mockController.setValue(any()))
            .thenAnswer((_) => Future.value());

        // Act
        final result = await repository.setContent(longContent);

        // Assert
        expect(result.isRight(), true);
      });

      test('should handle line 0 for cursor position', () async {
        // Arrange
        when(() => mockController.revealLine(any()))
            .thenAnswer((_) => Future.value());
        final position = CursorPosition.create(line: 0, column: 0);

        // Act
        final result = await repository.setCursorPosition(position);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockController.revealLine(1)).called(1);
      });

      test('should handle multiple dispose calls', () async {
        // Act
        await repository.dispose();
        await repository.dispose();

        // Assert - Should not throw
        expect(repository.isReady, false);
      });
    });
  });
}
