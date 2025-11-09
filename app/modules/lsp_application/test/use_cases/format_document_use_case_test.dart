import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:lsp_application/lsp_application.dart';

class MockLspClientRepository extends Mock implements ILspClientRepository {}
class MockCodeEditorRepository extends Mock implements ICodeEditorRepository {}

void main() {
  late MockLspClientRepository mockLspRepo;
  late MockCodeEditorRepository mockEditorRepo;
  late FormatDocumentUseCase useCase;

  setUp(() {
    mockLspRepo = MockLspClientRepository();
    mockEditorRepo = MockCodeEditorRepository();
    useCase = FormatDocumentUseCase(mockLspRepo, mockEditorRepo);
  });

  setUpAll(() {
    registerFallbackValue(LanguageId.dart);
    registerFallbackValue(DocumentUri.fromFilePath('/test.dart'));
    registerFallbackValue(SessionId.fromString('test-session'));
    registerFallbackValue(CursorPosition.create(line: 0, column: 0));
    registerFallbackValue(FormattingOptions.defaults());
  });

  group('FormatDocumentUseCase', () {
    test('should return formatted content when successful', () async {
      // Arrange
      final session = LspSession(
        id: SessionId.fromString('test-session'),
        languageId: LanguageId.dart,
        state: SessionState.initialized,
        rootUri: DocumentUri.fromFilePath('/project'),
        createdAt: DateTime.now(),
        initializedAt: DateTime.now(),
      );

      final textEdits = [
        TextEdit(
          range: TextSelection(
            start: CursorPosition.create(line: 0, column: 0),
            end: CursorPosition.create(line: 0, column: 10),
          ),
          newText: 'formatted',
        ),
      ];

      when(() => mockLspRepo.getSession(any()))
          .thenAnswer((_) async => right(session));

      when(() => mockEditorRepo.getContent())
          .thenAnswer((_) async => right('unformatted'));

      when(() => mockLspRepo.notifyDocumentChanged(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            content: any(named: 'content'),
          )).thenAnswer((_) async => right(unit));

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

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
      );

      // Assert
      expect(result.isRight(), true);
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
      );

      // Assert
      expect(result.isLeft(), true);
      verifyNever(() => mockLspRepo.formatDocument(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            options: any(named: 'options'),
          ));
    });

    test('should return failure when editor content unavailable', () async {
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

      when(() => mockEditorRepo.getContent())
          .thenAnswer((_) async => left(EditorFailure.notInitialized()));

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
      );

      // Assert
      expect(result.isLeft(), true);
    });

    test('should handle empty text edits', () async {
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

      when(() => mockEditorRepo.getContent())
          .thenAnswer((_) async => right('already formatted'));

      when(() => mockLspRepo.notifyDocumentChanged(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            content: any(named: 'content'),
          )).thenAnswer((_) async => right(unit));

      when(() => mockLspRepo.formatDocument(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => right([])); // No edits needed

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
      );

      // Assert
      expect(result.isRight(), true);
      verifyNever(() => mockEditorRepo.replaceText(
            start: any(named: 'start'),
            end: any(named: 'end'),
            text: any(named: 'text'),
          ));
    });
  });
}
