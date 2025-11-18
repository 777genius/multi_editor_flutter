import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_application/lsp_application.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockLspClientRepository extends Mock implements ILspClientRepository {}
class MockCodeEditorRepository extends Mock implements ICodeEditorRepository {}
class MockLspSessionService extends Mock implements LspSessionService {}
class MockDiagnosticService extends Mock implements DiagnosticService {}
class MockCodeLensService extends Mock implements CodeLensService {}
class MockDocumentLinksService extends Mock implements DocumentLinksService {}
class MockInlayHintsService extends Mock implements InlayHintsService {}
class MockFoldingService extends Mock implements FoldingService {}
class MockSemanticTokensService extends Mock implements SemanticTokensService {}

void main() {
  group('EditorSyncService', () {
    late MockLspClientRepository mockLspRepository;
    late MockCodeEditorRepository mockEditorRepository;
    late MockLspSessionService mockSessionService;
    late MockDiagnosticService mockDiagnosticService;
    late MockCodeLensService mockCodeLensService;
    late MockDocumentLinksService mockDocumentLinksService;
    late MockInlayHintsService mockInlayHintsService;
    late MockFoldingService mockFoldingService;
    late MockSemanticTokensService mockSemanticTokensService;
    late EditorSyncService service;
    late LspSession session;
    late DocumentUri documentUri;
    late DocumentUri rootUri;

    setUp(() {
      mockLspRepository = MockLspClientRepository();
      mockEditorRepository = MockCodeEditorRepository();
      mockSessionService = MockLspSessionService();
      mockDiagnosticService = MockDiagnosticService();
      mockCodeLensService = MockCodeLensService();
      mockDocumentLinksService = MockDocumentLinksService();
      mockInlayHintsService = MockInlayHintsService();
      mockFoldingService = MockFoldingService();
      mockSemanticTokensService = MockSemanticTokensService();

      service = EditorSyncService(
        editorRepository: mockEditorRepository,
        lspRepository: mockLspRepository,
        sessionService: mockSessionService,
        diagnosticService: mockDiagnosticService,
        codeLensService: mockCodeLensService,
        documentLinksService: mockDocumentLinksService,
        inlayHintsService: mockInlayHintsService,
        foldingService: mockFoldingService,
        semanticTokensService: mockSemanticTokensService,
        debounceDuration: const Duration(milliseconds: 50), // Short for testing
      );

      session = LspSession(
        id: SessionId.generate(),
        languageId: LanguageId.dart,
        state: SessionState.ready,
        createdAt: DateTime.now(),
      );

      documentUri = DocumentUri.fromFilePath('/lib/test.dart');
      rootUri = DocumentUri.fromFilePath('/project');

      registerFallbackValue(SessionId.generate());
      registerFallbackValue(LanguageId.dart);
      registerFallbackValue(documentUri);
      registerFallbackValue(rootUri);
    });

    tearDown(() async {
      await service.dispose();
    });

    group('startSyncing', () {
      test('should start syncing successfully', () async {
        // Arrange
        const content = 'class Test { }';

        when(() => mockSessionService.getOrCreateSession(
              languageId: any(named: 'languageId'),
              rootUri: any(named: 'rootUri'),
            )).thenAnswer((_) async => right(session));

        when(() => mockEditorRepository.getContent())
            .thenAnswer((_) async => right(content));

        when(() => mockLspRepository.notifyDocumentOpened(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              languageId: any(named: 'languageId'),
              content: any(named: 'content'),
            )).thenAnswer((_) async => right(unit));

        when(() => mockEditorRepository.onContentChanged)
            .thenAnswer((_) => const Stream.empty());

        when(() => mockEditorRepository.onCursorPositionChanged)
            .thenAnswer((_) => const Stream.empty());

        when(() => mockEditorRepository.onFocusChanged)
            .thenAnswer((_) => const Stream.empty());

        // Act
        final result = await service.startSyncing(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          rootUri: rootUri,
        );

        // Assert
        expect(result, isTrue);
        expect(service.isSyncing, isTrue);
        expect(service.currentDocumentUri, equals(documentUri));

        verify(() => mockLspRepository.notifyDocumentOpened(
              sessionId: session.id,
              documentUri: documentUri,
              languageId: LanguageId.dart,
              content: content,
            )).called(1);
      });

      test('should fail when session not ready', () async {
        // Arrange
        final notReadySession = LspSession(
          id: SessionId.generate(),
          languageId: LanguageId.dart,
          state: SessionState.initializing,
          createdAt: DateTime.now(),
        );

        when(() => mockSessionService.getOrCreateSession(
              languageId: any(named: 'languageId'),
              rootUri: any(named: 'rootUri'),
            )).thenAnswer((_) async => right(notReadySession));

        // Act
        final result = await service.startSyncing(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          rootUri: rootUri,
        );

        // Assert
        expect(result, isFalse);
        expect(service.isSyncing, isFalse);
      });

      test('should fail when cannot get session', () async {
        // Arrange
        when(() => mockSessionService.getOrCreateSession(
              languageId: any(named: 'languageId'),
              rootUri: any(named: 'rootUri'),
            )).thenAnswer((_) async => left(const LspFailure.sessionNotFound()));

        // Act
        final result = await service.startSyncing(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          rootUri: rootUri,
        );

        // Assert
        expect(result, isFalse);
        expect(service.isSyncing, isFalse);
      });

      test('should stop existing sync before starting new one', () async {
        // Arrange
        const content = 'class Test { }';

        when(() => mockSessionService.getOrCreateSession(
              languageId: any(named: 'languageId'),
              rootUri: any(named: 'rootUri'),
            )).thenAnswer((_) async => right(session));

        when(() => mockEditorRepository.getContent())
            .thenAnswer((_) async => right(content));

        when(() => mockLspRepository.notifyDocumentOpened(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              languageId: any(named: 'languageId'),
              content: any(named: 'content'),
            )).thenAnswer((_) async => right(unit));

        when(() => mockLspRepository.notifyDocumentClosed(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(unit));

        when(() => mockEditorRepository.onContentChanged)
            .thenAnswer((_) => const Stream.empty());

        when(() => mockEditorRepository.onCursorPositionChanged)
            .thenAnswer((_) => const Stream.empty());

        when(() => mockEditorRepository.onFocusChanged)
            .thenAnswer((_) => const Stream.empty());

        // Act - start sync twice
        await service.startSyncing(languageId: LanguageId.dart, documentUri: documentUri, rootUri: rootUri);
        await service.startSyncing(languageId: LanguageId.dart, documentUri: documentUri, rootUri: rootUri);

        // Assert - should have closed old document and opened new one
        verify(() => mockLspRepository.notifyDocumentClosed(
              sessionId: session.id,
              documentUri: documentUri,
            )).called(1);

        verify(() => mockLspRepository.notifyDocumentOpened(
              sessionId: session.id,
              documentUri: documentUri,
              languageId: LanguageId.dart,
              content: content,
            )).called(2);
      });
    });

    group('stopSyncing', () {
      test('should stop syncing and notify LSP', () async {
        // Arrange
        const content = 'class Test { }';

        when(() => mockSessionService.getOrCreateSession(
              languageId: any(named: 'languageId'),
              rootUri: any(named: 'rootUri'),
            )).thenAnswer((_) async => right(session));

        when(() => mockEditorRepository.getContent())
            .thenAnswer((_) async => right(content));

        when(() => mockLspRepository.notifyDocumentOpened(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              languageId: any(named: 'languageId'),
              content: any(named: 'content'),
            )).thenAnswer((_) async => right(unit));

        when(() => mockLspRepository.notifyDocumentClosed(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(unit));

        when(() => mockEditorRepository.onContentChanged)
            .thenAnswer((_) => const Stream.empty());

        when(() => mockEditorRepository.onCursorPositionChanged)
            .thenAnswer((_) => const Stream.empty());

        when(() => mockEditorRepository.onFocusChanged)
            .thenAnswer((_) => const Stream.empty());

        await service.startSyncing(languageId: LanguageId.dart, documentUri: documentUri, rootUri: rootUri);

        // Act
        await service.stopSyncing();

        // Assert
        expect(service.isSyncing, isFalse);
        expect(service.currentDocumentUri, isNull);

        verify(() => mockLspRepository.notifyDocumentClosed(
              sessionId: session.id,
              documentUri: documentUri,
            )).called(1);
      });

      test('should not fail when called without active sync', () async {
        // Act & Assert - should not throw
        await service.stopSyncing();
        expect(service.isSyncing, isFalse);
      });
    });

    group('content change handling', () {
      test('should notify LSP and clear caches on content change', () async {
        // Arrange
        const content = 'class Test { }';
        const updatedContent = 'class Test { void method() { } }';

        final contentController = StreamController<String>();

        when(() => mockSessionService.getOrCreateSession(
              languageId: any(named: 'languageId'),
              rootUri: any(named: 'rootUri'),
            )).thenAnswer((_) async => right(session));

        when(() => mockEditorRepository.getContent())
            .thenAnswer((_) async => right(content));

        when(() => mockLspRepository.notifyDocumentOpened(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              languageId: any(named: 'languageId'),
              content: any(named: 'content'),
            )).thenAnswer((_) async => right(unit));

        when(() => mockLspRepository.notifyDocumentChanged(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              content: any(named: 'content'),
            )).thenAnswer((_) async => right(unit));

        when(() => mockEditorRepository.onContentChanged)
            .thenAnswer((_) => contentController.stream);

        when(() => mockEditorRepository.onCursorPositionChanged)
            .thenAnswer((_) => const Stream.empty());

        when(() => mockEditorRepository.onFocusChanged)
            .thenAnswer((_) => const Stream.empty());

        when(() => mockDiagnosticService.clearDiagnostics(documentUri: any(named: 'documentUri')))
            .thenReturn(null);

        when(() => mockCodeLensService.clearCodeLenses(documentUri: any(named: 'documentUri')))
            .thenReturn(null);

        when(() => mockDocumentLinksService.clearDocumentLinks(documentUri: any(named: 'documentUri')))
            .thenReturn(null);

        when(() => mockInlayHintsService.clearInlayHints(documentUri: any(named: 'documentUri')))
            .thenReturn(null);

        when(() => mockFoldingService.clearFoldingRanges(documentUri: any(named: 'documentUri')))
            .thenReturn(null);

        when(() => mockSemanticTokensService.clearSemanticTokens(documentUri: any(named: 'documentUri')))
            .thenReturn(null);

        await service.startSyncing(languageId: LanguageId.dart, documentUri: documentUri, rootUri: rootUri);

        // Act - simulate content change
        contentController.add(updatedContent);

        // Wait for debounce + processing
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(() => mockLspRepository.notifyDocumentChanged(
              sessionId: session.id,
              documentUri: documentUri,
              content: updatedContent,
            )).called(1);

        verify(() => mockDiagnosticService.clearDiagnostics(documentUri: documentUri)).called(1);
        verify(() => mockCodeLensService.clearCodeLenses(documentUri: documentUri)).called(1);
        verify(() => mockDocumentLinksService.clearDocumentLinks(documentUri: documentUri)).called(1);
        verify(() => mockInlayHintsService.clearInlayHints(documentUri: documentUri)).called(1);
        verify(() => mockFoldingService.clearFoldingRanges(documentUri: documentUri)).called(1);
        verify(() => mockSemanticTokensService.clearSemanticTokens(documentUri: documentUri)).called(1);

        await contentController.close();
      });

      test('should debounce rapid content changes', () async {
        // Arrange
        const content = 'class Test { }';

        final contentController = StreamController<String>();

        when(() => mockSessionService.getOrCreateSession(
              languageId: any(named: 'languageId'),
              rootUri: any(named: 'rootUri'),
            )).thenAnswer((_) async => right(session));

        when(() => mockEditorRepository.getContent())
            .thenAnswer((_) async => right(content));

        when(() => mockLspRepository.notifyDocumentOpened(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              languageId: any(named: 'languageId'),
              content: any(named: 'content'),
            )).thenAnswer((_) async => right(unit));

        when(() => mockLspRepository.notifyDocumentChanged(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              content: any(named: 'content'),
            )).thenAnswer((_) async => right(unit));

        when(() => mockEditorRepository.onContentChanged)
            .thenAnswer((_) => contentController.stream);

        when(() => mockEditorRepository.onCursorPositionChanged)
            .thenAnswer((_) => const Stream.empty());

        when(() => mockEditorRepository.onFocusChanged)
            .thenAnswer((_) => const Stream.empty());

        when(() => mockDiagnosticService.clearDiagnostics(documentUri: any(named: 'documentUri')))
            .thenReturn(null);

        when(() => mockCodeLensService.clearCodeLenses(documentUri: any(named: 'documentUri')))
            .thenReturn(null);

        when(() => mockDocumentLinksService.clearDocumentLinks(documentUri: any(named: 'documentUri')))
            .thenReturn(null);

        when(() => mockInlayHintsService.clearInlayHints(documentUri: any(named: 'documentUri')))
            .thenReturn(null);

        when(() => mockFoldingService.clearFoldingRanges(documentUri: any(named: 'documentUri')))
            .thenReturn(null);

        when(() => mockSemanticTokensService.clearSemanticTokens(documentUri: any(named: 'documentUri')))
            .thenReturn(null);

        await service.startSyncing(languageId: LanguageId.dart, documentUri: documentUri, rootUri: rootUri);

        // Act - simulate rapid content changes
        contentController.add('change 1');
        contentController.add('change 2');
        contentController.add('change 3');
        contentController.add('final change');

        // Wait for debounce + processing
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - should only process the last change due to debouncing
        verify(() => mockLspRepository.notifyDocumentChanged(
              sessionId: session.id,
              documentUri: documentUri,
              content: 'final change',
            )).called(1);

        await contentController.close();
      });
    });

    group('notifyDocumentSaved', () {
      test('should notify LSP when document is saved', () async {
        // Arrange
        const content = 'class Test { }';

        when(() => mockSessionService.getOrCreateSession(
              languageId: any(named: 'languageId'),
              rootUri: any(named: 'rootUri'),
            )).thenAnswer((_) async => right(session));

        when(() => mockEditorRepository.getContent())
            .thenAnswer((_) async => right(content));

        when(() => mockLspRepository.notifyDocumentOpened(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              languageId: any(named: 'languageId'),
              content: any(named: 'content'),
            )).thenAnswer((_) async => right(unit));

        when(() => mockLspRepository.notifyDocumentSaved(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(unit));

        when(() => mockEditorRepository.onContentChanged)
            .thenAnswer((_) => const Stream.empty());

        when(() => mockEditorRepository.onCursorPositionChanged)
            .thenAnswer((_) => const Stream.empty());

        when(() => mockEditorRepository.onFocusChanged)
            .thenAnswer((_) => const Stream.empty());

        await service.startSyncing(languageId: LanguageId.dart, documentUri: documentUri, rootUri: rootUri);

        // Act
        await service.notifyDocumentSaved();

        // Assert
        verify(() => mockLspRepository.notifyDocumentSaved(
              sessionId: session.id,
              documentUri: documentUri,
            )).called(1);
      });

      test('should not notify when not syncing', () async {
        // Act
        await service.notifyDocumentSaved();

        // Assert
        verifyNever(() => mockLspRepository.notifyDocumentSaved(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            ));
      });
    });

    group('isSyncing', () {
      test('should return false when not syncing', () {
        expect(service.isSyncing, isFalse);
      });

      test('should return true when syncing', () async {
        // Arrange
        const content = 'class Test { }';

        when(() => mockSessionService.getOrCreateSession(
              languageId: any(named: 'languageId'),
              rootUri: any(named: 'rootUri'),
            )).thenAnswer((_) async => right(session));

        when(() => mockEditorRepository.getContent())
            .thenAnswer((_) async => right(content));

        when(() => mockLspRepository.notifyDocumentOpened(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              languageId: any(named: 'languageId'),
              content: any(named: 'content'),
            )).thenAnswer((_) async => right(unit));

        when(() => mockEditorRepository.onContentChanged)
            .thenAnswer((_) => const Stream.empty());

        when(() => mockEditorRepository.onCursorPositionChanged)
            .thenAnswer((_) => const Stream.empty());

        when(() => mockEditorRepository.onFocusChanged)
            .thenAnswer((_) => const Stream.empty());

        // Act
        await service.startSyncing(languageId: LanguageId.dart, documentUri: documentUri, rootUri: rootUri);

        // Assert
        expect(service.isSyncing, isTrue);
      });
    });

    group('currentSession and currentDocumentUri', () {
      test('should return current session and document when syncing', () async {
        // Arrange
        const content = 'class Test { }';

        when(() => mockSessionService.getOrCreateSession(
              languageId: any(named: 'languageId'),
              rootUri: any(named: 'rootUri'),
            )).thenAnswer((_) async => right(session));

        when(() => mockEditorRepository.getContent())
            .thenAnswer((_) async => right(content));

        when(() => mockLspRepository.notifyDocumentOpened(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              languageId: any(named: 'languageId'),
              content: any(named: 'content'),
            )).thenAnswer((_) async => right(unit));

        when(() => mockEditorRepository.onContentChanged)
            .thenAnswer((_) => const Stream.empty());

        when(() => mockEditorRepository.onCursorPositionChanged)
            .thenAnswer((_) => const Stream.empty());

        when(() => mockEditorRepository.onFocusChanged)
            .thenAnswer((_) => const Stream.empty());

        // Act
        await service.startSyncing(languageId: LanguageId.dart, documentUri: documentUri, rootUri: rootUri);

        // Assert
        expect(service.currentSession, equals(session));
        expect(service.currentDocumentUri, equals(documentUri));
      });
    });
  });
}
