import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:lsp_application/lsp_application.dart';

class MockLspClientRepository extends Mock implements ILspClientRepository {}
class MockCodeEditorRepository extends Mock implements ICodeEditorRepository {}

/// Integration tests for complete LSP workflows.
///
/// These tests verify that multiple components work together correctly
/// in realistic editor scenarios.
void main() {
  late MockLspClientRepository mockLspRepo;
  late MockCodeEditorRepository mockEditorRepo;
  late LspSessionService sessionService;
  late DiagnosticService diagnosticService;
  late EditorSyncService syncService;
  late CodeLensService codeLensService;

  setUp(() {
    mockLspRepo = MockLspClientRepository();
    mockEditorRepo = MockCodeEditorRepository();

    sessionService = LspSessionService(mockLspRepo);
    diagnosticService = DiagnosticService(mockLspRepo);
    syncService = EditorSyncService(
      editorRepository: mockEditorRepo,
      lspRepository: mockLspRepo,
      sessionService: sessionService,
    );
    codeLensService = CodeLensService(mockLspRepo);
  });

  setUpAll(() {
    registerFallbackValue(LanguageId.dart);
    registerFallbackValue(DocumentUri.fromFilePath('/test.dart'));
    registerFallbackValue(SessionId.fromString('test-session'));
    registerFallbackValue(CursorPosition.create(line: 0, column: 0));
  });

  group('Complete Editor Workflow', () {
    test('should complete full initialization and editing workflow', () async {
      // Arrange
      final session = LspSession(
        id: SessionId.fromString('test-session'),
        languageId: LanguageId.dart,
        state: SessionState.initialized,
        rootUri: DocumentUri.fromFilePath('/project'),
        createdAt: DateTime.now(),
        initializedAt: DateTime.now(),
      );

      // Setup mocks for initialization
      when(() => mockLspRepo.initializeSession(
            languageId: any(named: 'languageId'),
            rootUri: any(named: 'rootUri'),
            capabilities: any(named: 'capabilities'),
          )).thenAnswer((_) async => right(session));

      when(() => mockLspRepo.getSession(any()))
          .thenAnswer((_) async => right(session));

      // Step 1: Initialize LSP session
      final initUseCase = InitializeLspSessionUseCase(mockLspRepo);
      final initResult = await initUseCase(
        languageId: LanguageId.dart,
        rootUri: DocumentUri.fromFilePath('/project'),
      );

      expect(initResult.isRight(), true);

      // Step 2: Open document and sync
      when(() => mockEditorRepo.getContent())
          .thenAnswer((_) async => right('void main() {}'));

      when(() => mockLspRepo.notifyDocumentOpened(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            content: any(named: 'content'),
          )).thenAnswer((_) async => right(unit));

      final syncResult = await syncService.syncDocument(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
      );

      expect(syncResult.isRight(), true);

      // Step 3: Get diagnostics
      final diagnostics = [
        Diagnostic(
          range: TextSelection(
            start: CursorPosition.create(line: 0, column: 0),
            end: CursorPosition.create(line: 0, column: 4),
          ),
          severity: DiagnosticSeverity.warning,
          message: 'Unused function',
        ),
      ];

      when(() => mockLspRepo.getDiagnostics(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
          )).thenAnswer((_) async => right(diagnostics));

      final diagResult = await diagnosticService.getDiagnostics(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
      );

      expect(diagResult.isRight(), true);
      diagResult.fold(
        (_) => fail('Expected Right'),
        (diags) => expect(diags.length, 1),
      );

      // Step 4: Get code lenses
      final codeLenses = [
        CodeLens(
          range: TextSelection(
            start: CursorPosition.create(line: 0, column: 0),
            end: CursorPosition.create(line: 0, column: 4),
          ),
          command: Command(
            title: 'Run',
            command: 'dart.run',
            arguments: [],
          ),
        ),
      ];

      when(() => mockLspRepo.getCodeLenses(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
          )).thenAnswer((_) async => right(codeLenses));

      final codeLensResult = await codeLensService.getCodeLenses(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
      );

      expect(codeLensResult.isRight(), true);

      // Verify complete workflow executed
      verify(() => mockLspRepo.initializeSession(
            languageId: any(named: 'languageId'),
            rootUri: any(named: 'rootUri'),
            capabilities: any(named: 'capabilities'),
          )).called(1);
      verify(() => mockLspRepo.notifyDocumentOpened(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            content: any(named: 'content'),
          )).called(1);
    });

    test('should handle edit -> diagnostics -> code actions workflow', () async {
      // Arrange
      final session = LspSession(
        id: SessionId.fromString('test-session'),
        languageId: LanguageId.dart,
        state: SessionState.initialized,
        rootUri: DocumentUri.fromFilePath('/project'),
        createdAt: DateTime.now(),
        initializedAt: DateTime.now(),
      );

      when(() => mockLspRepo.getSession(any()))
          .thenAnswer((_) async => right(session));

      // Step 1: User makes an edit
      when(() => mockEditorRepo.getContent())
          .thenAnswer((_) async => right('void main() { int x }'));

      when(() => mockLspRepo.notifyDocumentChanged(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            content: any(named: 'content'),
          )).thenAnswer((_) async => right(unit));

      await syncService.syncDocument(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
      );

      // Step 2: LSP returns diagnostics for the error
      final diagnostics = [
        Diagnostic(
          range: TextSelection(
            start: CursorPosition.create(line: 0, column: 19),
            end: CursorPosition.create(line: 0, column: 20),
          ),
          severity: DiagnosticSeverity.error,
          message: 'Expected ; after variable declaration',
        ),
      ];

      when(() => mockLspRepo.getDiagnostics(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
          )).thenAnswer((_) async => right(diagnostics));

      final diagResult = await diagnosticService.getDiagnostics(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
      );

      // Step 3: User requests code actions for the error
      final codeActions = [
        CodeAction(
          title: 'Add semicolon',
          kind: CodeActionKind.quickFix,
          edit: WorkspaceEdit(
            changes: {
              DocumentUri.fromFilePath('/test.dart'): [
                TextEdit(
                  range: TextSelection(
                    start: CursorPosition.create(line: 0, column: 20),
                    end: CursorPosition.create(line: 0, column: 20),
                  ),
                  newText: ';',
                ),
              ],
            },
          ),
        ),
      ];

      when(() => mockLspRepo.getCodeActions(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            range: any(named: 'range'),
            diagnostics: any(named: 'diagnostics'),
          )).thenAnswer((_) async => right(codeActions));

      final getCodeActionsUseCase = GetCodeActionsUseCase(mockLspRepo);
      final actionsResult = await getCodeActionsUseCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
        range: diagnostics.first.range,
        diagnostics: diagnostics,
      );

      // Assert
      expect(diagResult.isRight(), true);
      expect(actionsResult.isRight(), true);
      actionsResult.fold(
        (_) => fail('Expected Right'),
        (actions) {
          expect(actions.length, 1);
          expect(actions.first.title, 'Add semicolon');
        },
      );
    });

    test('should handle completion -> signature help workflow', () async {
      // Arrange
      final session = LspSession(
        id: SessionId.fromString('test-session'),
        languageId: LanguageId.dart,
        state: SessionState.initialized,
        rootUri: DocumentUri.fromFilePath('/project'),
        createdAt: DateTime.now(),
        initializedAt: DateTime.now(),
      );

      when(() => mockLspRepo.getSession(any()))
          .thenAnswer((_) async => right(session));

      // Step 1: User types "pri" and requests completion
      final completions = [
        CompletionItem(
          label: 'print',
          kind: CompletionItemKind.function,
          detail: 'void print(Object? object)',
          insertText: 'print',
        ),
      ];

      when(() => mockEditorRepo.getContent())
          .thenAnswer((_) async => right('void main() { pri'));

      when(() => mockLspRepo.notifyDocumentChanged(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            content: any(named: 'content'),
          )).thenAnswer((_) async => right(unit));

      when(() => mockLspRepo.getCompletions(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            position: any(named: 'position'),
            triggerCharacter: any(named: 'triggerCharacter'),
          )).thenAnswer((_) async => right(completions));

      final getCompletionsUseCase = GetCompletionsUseCase(
        mockLspRepo,
        mockEditorRepo,
      );

      final completionResult = await getCompletionsUseCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
        position: CursorPosition.create(line: 0, column: 17),
      );

      expect(completionResult.isRight(), true);

      // Step 2: User accepts completion and types "(" - triggers signature help
      when(() => mockEditorRepo.getContent())
          .thenAnswer((_) async => right('void main() { print('));

      final signatureHelp = SignatureHelp(
        signatures: [
          SignatureInformation(
            label: 'void print(Object? object)',
            documentation: 'Prints an object to the console',
            parameters: [
              ParameterInformation(
                label: 'object',
                documentation: 'The object to print',
              ),
            ],
          ),
        ],
        activeSignature: 0,
        activeParameter: 0,
      );

      when(() => mockLspRepo.getSignatureHelp(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            position: any(named: 'position'),
            triggerCharacter: any(named: 'triggerCharacter'),
          )).thenAnswer((_) async => right(signatureHelp));

      final getSignatureHelpUseCase = GetSignatureHelpUseCase(mockLspRepo);
      final signatureResult = await getSignatureHelpUseCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
        position: CursorPosition.create(line: 0, column: 20),
        triggerCharacter: '(',
      );

      // Assert
      expect(signatureResult.isRight(), true);
      signatureResult.fold(
        (_) => fail('Expected Right'),
        (help) {
          expect(help.signatures.length, 1);
          expect(help.signatures.first.label, 'void print(Object? object)');
          expect(help.activeParameter, 0);
        },
      );
    });

    test('should handle format -> diagnostics refresh workflow', () async {
      // Arrange
      final session = LspSession(
        id: SessionId.fromString('test-session'),
        languageId: LanguageId.dart,
        state: SessionState.initialized,
        rootUri: DocumentUri.fromFilePath('/project'),
        createdAt: DateTime.now(),
        initializedAt: DateTime.now(),
      );

      when(() => mockLspRepo.getSession(any()))
          .thenAnswer((_) async => right(session));

      // Step 1: Format document
      when(() => mockEditorRepo.getContent())
          .thenAnswer((_) async => right('void main(){print("hello");}'));

      when(() => mockLspRepo.notifyDocumentChanged(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            content: any(named: 'content'),
          )).thenAnswer((_) async => right(unit));

      final textEdits = [
        TextEdit(
          range: TextSelection(
            start: CursorPosition.create(line: 0, column: 0),
            end: CursorPosition.create(line: 0, column: 28),
          ),
          newText: 'void main() {\n  print("hello");\n}',
        ),
      ];

      when(() => mockLspRepo.formatDocument(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => right(textEdits));

      when(() => mockEditorRepo.replaceText(
            start: any(named: 'start'),
            end: any(named: 'end'),
            text: any(named: 'text'),
          )).thenAnswer((_) async => right(unit));

      final formatUseCase = FormatDocumentUseCase(mockLspRepo, mockEditorRepo);
      final formatResult = await formatUseCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
      );

      expect(formatResult.isRight(), true);

      // Step 2: Refresh diagnostics after formatting
      when(() => mockLspRepo.getDiagnostics(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
          )).thenAnswer((_) async => right([]));

      await diagnosticService.refreshDiagnostics(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
      );

      // Verify formatting was applied and diagnostics refreshed
      verify(() => mockLspRepo.formatDocument(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            options: any(named: 'options'),
          )).called(1);
      verify(() => mockEditorRepo.replaceText(
            start: any(named: 'start'),
            end: any(named: 'end'),
            text: any(named: 'text'),
          )).called(1);
    });
  });

  group('Error Recovery Workflows', () {
    test('should recover from LSP session crash and reinitialize', () async {
      // Arrange
      final session = LspSession(
        id: SessionId.fromString('test-session'),
        languageId: LanguageId.dart,
        state: SessionState.initialized,
        rootUri: DocumentUri.fromFilePath('/project'),
        createdAt: DateTime.now(),
        initializedAt: DateTime.now(),
      );

      // Step 1: Initial successful operation
      when(() => mockLspRepo.getSession(any()))
          .thenAnswer((_) async => right(session));

      when(() => mockLspRepo.getDiagnostics(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
          )).thenAnswer((_) async => right([]));

      var diagResult = await diagnosticService.getDiagnostics(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
      );

      expect(diagResult.isRight(), true);

      // Step 2: LSP server crashes - session not found
      when(() => mockLspRepo.getSession(any()))
          .thenAnswer((_) async => left(LspFailure.sessionNotFound(
                message: 'Session crashed',
              )));

      diagResult = await diagnosticService.getDiagnostics(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
      );

      expect(diagResult.isLeft(), true);

      // Step 3: Reinitialize session
      when(() => mockLspRepo.initializeSession(
            languageId: any(named: 'languageId'),
            rootUri: any(named: 'rootUri'),
            capabilities: any(named: 'capabilities'),
          )).thenAnswer((_) async => right(session));

      final initUseCase = InitializeLspSessionUseCase(mockLspRepo);
      final initResult = await initUseCase(
        languageId: LanguageId.dart,
        rootUri: DocumentUri.fromFilePath('/project'),
      );

      expect(initResult.isRight(), true);

      // Step 4: Operations work again
      when(() => mockLspRepo.getSession(any()))
          .thenAnswer((_) async => right(session));

      diagResult = await diagnosticService.getDiagnostics(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
      );

      expect(diagResult.isRight(), true);
    });
  });

  tearDown(() async {
    await syncService.dispose();
    await diagnosticService.dispose();
    await codeLensService.dispose();
  });
}
