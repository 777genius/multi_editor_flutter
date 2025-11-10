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
  late RenameSymbolUseCase useCase;

  setUp(() {
    mockLspRepo = MockLspClientRepository();
    mockEditorRepo = MockCodeEditorRepository();
    useCase = RenameSymbolUseCase(mockLspRepo, mockEditorRepo);
  });

  setUpAll(() {
    registerFallbackValue(LanguageId.dart);
    registerFallbackValue(DocumentUri.fromFilePath('/test.dart'));
    registerFallbackValue(SessionId.fromString('test-session'));
    registerFallbackValue(CursorPosition.create(line: 0, column: 0));
  });

  group('RenameSymbolUseCase', () {
    test('should return RenameResult when successful', () async {
      // Arrange
      final session = LspSession(
        id: SessionId.fromString('test-session'),
        languageId: LanguageId.dart,
        state: SessionState.initialized,
        rootUri: DocumentUri.fromFilePath('/project'),
        createdAt: DateTime.now(),
        initializedAt: DateTime.now(),
      );

      final workspaceEdit = WorkspaceEdit(
        changes: {
          DocumentUri.fromFilePath('/test.dart'): [
            TextEdit(
              range: TextSelection(
                start: CursorPosition.create(line: 0, column: 0),
                end: CursorPosition.create(line: 0, column: 7),
              ),
              newText: 'newName',
            ),
          ],
          DocumentUri.fromFilePath('/test2.dart'): [
            TextEdit(
              range: TextSelection(
                start: CursorPosition.create(line: 5, column: 10),
                end: CursorPosition.create(line: 5, column: 17),
              ),
              newText: 'newName',
            ),
          ],
        },
      );

      when(() => mockLspRepo.getSession(any()))
          .thenAnswer((_) async => right(session));

      when(() => mockEditorRepo.getContent())
          .thenAnswer((_) async => right('oldName'));

      when(() => mockLspRepo.notifyDocumentChanged(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            content: any(named: 'content'),
          )).thenAnswer((_) async => right(unit));

      when(() => mockLspRepo.rename(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            position: any(named: 'position'),
            newName: any(named: 'newName'),
          )).thenAnswer((_) async => right(workspaceEdit));

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
        position: CursorPosition.create(line: 0, column: 0),
        newName: 'newName',
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (renameResult) {
          expect(renameResult.changedFiles, 2);
          expect(renameResult.totalEdits, 2);
        },
      );
    });

    test('should return failure for invalid identifier', () async {
      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
        position: CursorPosition.create(line: 0, column: 0),
        newName: '123invalid', // Invalid: starts with number
      );

      // Assert
      expect(result.isLeft(), true);
      verifyNever(() => mockLspRepo.rename(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            position: any(named: 'position'),
            newName: any(named: 'newName'),
          ));
    });

    test('should return failure for empty name', () async {
      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
        position: CursorPosition.create(line: 0, column: 0),
        newName: '',
      );

      // Assert
      expect(result.isLeft(), true);
    });

    test('should handle session not found', () async {
      // Arrange
      when(() => mockLspRepo.getSession(any()))
          .thenAnswer((_) async => left(LspFailure.sessionNotFound(
                message: 'Session not found',
              )));

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
        position: CursorPosition.create(line: 0, column: 0),
        newName: 'validName',
      );

      // Assert
      expect(result.isLeft(), true);
    });
  });
}
