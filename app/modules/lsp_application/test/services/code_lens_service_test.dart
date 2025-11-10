import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:lsp_application/lsp_application.dart';

class MockLspClientRepository extends Mock implements ILspClientRepository {}

void main() {
  late MockLspClientRepository mockLspRepo;
  late CodeLensService service;

  setUp(() {
    mockLspRepo = MockLspClientRepository();
    service = CodeLensService(mockLspRepo);
  });

  setUpAll(() {
    registerFallbackValue(LanguageId.dart);
    registerFallbackValue(DocumentUri.fromFilePath('/test.dart'));
    registerFallbackValue(SessionId.fromString('test-session'));
  });

  group('CodeLensService', () {
    test('should get code lenses successfully', () async {
      // Arrange
      final session = LspSession(
        id: SessionId.fromString('test-session'),
        languageId: LanguageId.dart,
        state: SessionState.initialized,
        rootUri: DocumentUri.fromFilePath('/project'),
        createdAt: DateTime.now(),
        initializedAt: DateTime.now(),
      );

      final codeLenses = [
        CodeLens(
          range: TextSelection(
            start: CursorPosition.create(line: 0, column: 0),
            end: CursorPosition.create(line: 0, column: 10),
          ),
          command: Command(
            title: '5 references',
            command: 'editor.action.showReferences',
            arguments: [],
          ),
        ),
      ];

      when(() => mockLspRepo.getSession(any()))
          .thenAnswer((_) async => right(session));

      when(() => mockLspRepo.getCodeLenses(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
          )).thenAnswer((_) async => right(codeLenses));

      // Act
      final result = await service.getCodeLenses(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (lenses) {
          expect(lenses.length, 1);
          expect(lenses.first.command?.title, '5 references');
        },
      );
    });

    test('should cache code lenses', () async {
      // Arrange
      final session = LspSession(
        id: SessionId.fromString('test-session'),
        languageId: LanguageId.dart,
        state: SessionState.initialized,
        rootUri: DocumentUri.fromFilePath('/project'),
        createdAt: DateTime.now(),
        initializedAt: DateTime.now(),
      );

      final codeLenses = [
        CodeLens(
          range: TextSelection(
            start: CursorPosition.create(line: 0, column: 0),
            end: CursorPosition.create(line: 0, column: 10),
          ),
        ),
      ];

      when(() => mockLspRepo.getSession(any()))
          .thenAnswer((_) async => right(session));

      when(() => mockLspRepo.getCodeLenses(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
          )).thenAnswer((_) async => right(codeLenses));

      // Act
      await service.getCodeLenses(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
      );

      // Second call should use cache
      final result = await service.getCodeLenses(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
        forceRefresh: false,
      );

      // Assert
      expect(result.isRight(), true);
      // Should only call LSP once (cached second time)
      verify(() => mockLspRepo.getCodeLenses(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
          )).called(1);
    });

    test('should return empty when disabled', () async {
      // Arrange
      service.setEnabled(false);

      // Act
      final result = await service.getCodeLenses(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (lenses) => expect(lenses.isEmpty, true),
      );

      verifyNever(() => mockLspRepo.getCodeLenses(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
          ));
    });

    test('should clear code lenses', () async {
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

      when(() => mockLspRepo.getCodeLenses(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
          )).thenAnswer((_) async => right([]));

      await service.getCodeLenses(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
      );

      // Act
      service.clearCodeLenses(
        documentUri: DocumentUri.fromFilePath('/test.dart'),
      );

      // Assert
      expect(service.getCodeLensCount(
        documentUri: DocumentUri.fromFilePath('/test.dart'),
      ), 0);
    });

    test('should emit update events', () async {
      // Arrange
      final session = LspSession(
        id: SessionId.fromString('test-session'),
        languageId: LanguageId.dart,
        state: SessionState.initialized,
        rootUri: DocumentUri.fromFilePath('/project'),
        createdAt: DateTime.now(),
        initializedAt: DateTime.now(),
      );

      final codeLenses = [
        CodeLens(
          range: TextSelection(
            start: CursorPosition.create(line: 0, column: 0),
            end: CursorPosition.create(line: 0, column: 10),
          ),
        ),
      ];

      when(() => mockLspRepo.getSession(any()))
          .thenAnswer((_) async => right(session));

      when(() => mockLspRepo.getCodeLenses(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
          )).thenAnswer((_) async => right(codeLenses));

      // Act
      final updates = <CodeLensUpdate>[];
      final subscription = service.onCodeLensChanged.listen(updates.add);

      await service.getCodeLenses(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
      );

      await Future.delayed(Duration(milliseconds: 10));

      // Assert
      expect(updates.length, 1);
      expect(updates.first.codeLenses.length, 1);

      await subscription.cancel();
    });
  });
}
