import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:lsp_application/lsp_application.dart';

class MockLspClientRepository extends Mock implements ILspClientRepository {}

void main() {
  late MockLspClientRepository mockLspRepo;
  late GetCodeActionsUseCase useCase;

  setUp(() {
    mockLspRepo = MockLspClientRepository();
    useCase = GetCodeActionsUseCase(mockLspRepo);
  });

  setUpAll(() {
    registerFallbackValue(LanguageId.dart);
    registerFallbackValue(DocumentUri.fromFilePath('/test.dart'));
    registerFallbackValue(SessionId.fromString('test-session'));
    registerFallbackValue(TextSelection(
      start: CursorPosition.create(line: 0, column: 0),
      end: CursorPosition.create(line: 0, column: 10),
    ));
  });

  group('GetCodeActionsUseCase', () {
    test('should return code actions sorted by priority', () async {
      // Arrange
      final session = LspSession(
        id: SessionId.fromString('test-session'),
        languageId: LanguageId.dart,
        state: SessionState.initialized,
        rootUri: DocumentUri.fromFilePath('/project'),
        createdAt: DateTime.now(),
        initializedAt: DateTime.now(),
      );

      final codeActions = [
        CodeAction(
          title: 'Organize imports',
          kind: CodeActionKind.source,
        ),
        CodeAction(
          title: 'Fix missing return',
          kind: CodeActionKind.quickFix,
        ),
        CodeAction(
          title: 'Extract method',
          kind: CodeActionKind.refactor,
        ),
      ];

      when(() => mockLspRepo.getSession(any()))
          .thenAnswer((_) async => right(session));

      when(() => mockLspRepo.getCodeActions(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            range: any(named: 'range'),
            diagnostics: any(named: 'diagnostics'),
          )).thenAnswer((_) async => right(codeActions));

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
        range: TextSelection(
          start: CursorPosition.create(line: 0, column: 0),
          end: CursorPosition.create(line: 0, column: 10),
        ),
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (actions) {
          expect(actions.length, 3);
          // Quick fixes should be first (priority 0)
          expect(actions[0].kind, CodeActionKind.quickFix);
          expect(actions[0].title, 'Fix missing return');
          // Refactorings second (priority 1)
          expect(actions[1].kind, CodeActionKind.refactor);
          expect(actions[1].title, 'Extract method');
          // Source actions last (priority 2)
          expect(actions[2].kind, CodeActionKind.source);
          expect(actions[2].title, 'Organize imports');
        },
      );
    });

    test('should pass diagnostics when provided', () async {
      // Arrange
      final session = LspSession(
        id: SessionId.fromString('test-session'),
        languageId: LanguageId.dart,
        state: SessionState.initialized,
        rootUri: DocumentUri.fromFilePath('/project'),
        createdAt: DateTime.now(),
        initializedAt: DateTime.now(),
      );

      final diagnostics = [
        Diagnostic(
          range: TextSelection(
            start: CursorPosition.create(line: 0, column: 0),
            end: CursorPosition.create(line: 0, column: 10),
          ),
          severity: DiagnosticSeverity.error,
          message: 'Missing return statement',
        ),
      ];

      final codeActions = [
        CodeAction(
          title: 'Add return statement',
          kind: CodeActionKind.quickFix,
        ),
      ];

      when(() => mockLspRepo.getSession(any()))
          .thenAnswer((_) async => right(session));

      when(() => mockLspRepo.getCodeActions(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            range: any(named: 'range'),
            diagnostics: any(named: 'diagnostics'),
          )).thenAnswer((_) async => right(codeActions));

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
        range: TextSelection(
          start: CursorPosition.create(line: 0, column: 0),
          end: CursorPosition.create(line: 0, column: 10),
        ),
        diagnostics: diagnostics,
      );

      // Assert
      expect(result.isRight(), true);
      verify(() => mockLspRepo.getCodeActions(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            range: any(named: 'range'),
            diagnostics: diagnostics,
          )).called(1);
    });

    test('should return empty list when no code actions available', () async {
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

      when(() => mockLspRepo.getCodeActions(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            range: any(named: 'range'),
            diagnostics: any(named: 'diagnostics'),
          )).thenAnswer((_) async => right([]));

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
        range: TextSelection(
          start: CursorPosition.create(line: 0, column: 0),
          end: CursorPosition.create(line: 0, column: 10),
        ),
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (actions) => expect(actions.isEmpty, true),
      );
    });

    test('should return failure when session not found', () async {
      // Arrange
      when(() => mockLspRepo.getSession(any()))
          .thenAnswer((_) async => left(LspFailure.sessionNotFound(
                message: 'Session not found',
              )));

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
        range: TextSelection(
          start: CursorPosition.create(line: 0, column: 0),
          end: CursorPosition.create(line: 0, column: 10),
        ),
      );

      // Assert
      expect(result.isLeft(), true);
      verifyNever(() => mockLspRepo.getCodeActions(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            range: any(named: 'range'),
            diagnostics: any(named: 'diagnostics'),
          ));
    });

    test('should handle LSP server error', () async {
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

      when(() => mockLspRepo.getCodeActions(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            range: any(named: 'range'),
            diagnostics: any(named: 'diagnostics'),
          )).thenAnswer((_) async => left(const LspFailure.serverError(
                message: 'LSP server error',
              )));

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
        range: TextSelection(
          start: CursorPosition.create(line: 0, column: 0),
          end: CursorPosition.create(line: 0, column: 10),
        ),
      );

      // Assert
      expect(result.isLeft(), true);
    });
  });
}
