import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_application/lsp_application.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockLspClientRepository extends Mock implements ILspClientRepository {}
class MockCodeEditorRepository extends Mock implements ICodeEditorRepository {}

void main() {
  group('GoToDefinitionUseCase', () {
    late MockLspClientRepository mockLspRepository;
    late MockCodeEditorRepository mockEditorRepository;
    late GoToDefinitionUseCase useCase;
    late LspSession session;

    setUp(() {
      mockLspRepository = MockLspClientRepository();
      mockEditorRepository = MockCodeEditorRepository();
      useCase = GoToDefinitionUseCase(mockLspRepository, mockEditorRepository);

      session = LspSession(
        id: SessionId.generate(),
        languageId: LanguageId.dart,
        state: SessionState.ready,
        createdAt: DateTime.now(),
      );

      registerFallbackValue(SessionId.generate());
      registerFallbackValue(DocumentUri.fromFilePath('/test.dart'));
      registerFallbackValue(const CursorPosition(line: 0, column: 0));
      registerFallbackValue(LanguageId.dart);
    });

    test('should get definition location successfully', () async {
      // Arrange
      final documentUri = DocumentUri.fromFilePath('/current/file.dart');
      final position = const CursorPosition(line: 10, column: 5);
      const content = 'class Test { }';

      final locations = [
        Location(
          uri: DocumentUri.fromFilePath('/other/file.dart'),
          range: const Range(
            start: Position(line: 5, character: 0),
            end: Position(line: 5, character: 10),
          ),
        ),
      ];

      when(() => mockLspRepository.getSession(any()))
          .thenAnswer((_) async => right(session));

      when(() => mockEditorRepository.getContent())
          .thenAnswer((_) async => right(content));

      when(() => mockLspRepository.notifyDocumentChanged(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            content: any(named: 'content'),
          )).thenAnswer((_) async => right(unit));

      when(() => mockLspRepository.getDefinition(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            position: any(named: 'position'),
          )).thenAnswer((_) async => right(locations));

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        documentUri: documentUri,
        position: position,
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should not fail'),
        (locs) {
          expect(locs.length, equals(1));
          expect(locs[0].uri.path, contains('other/file.dart'));
        },
      );
    });

    test('should fail when session not ready', () async {
      // Arrange
      final notReadySession = session.copyWith(state: SessionState.initializing);

      when(() => mockLspRepository.getSession(any()))
          .thenAnswer((_) async => right(notReadySession));

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
        position: const CursorPosition(line: 0, column: 0),
      );

      // Assert
      expect(result.isLeft(), isTrue);
    });

    test('should handle empty definition list', () async {
      // Arrange
      const content = 'class Test { }';

      when(() => mockLspRepository.getSession(any()))
          .thenAnswer((_) async => right(session));

      when(() => mockEditorRepository.getContent())
          .thenAnswer((_) async => right(content));

      when(() => mockLspRepository.notifyDocumentChanged(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            content: any(named: 'content'),
          )).thenAnswer((_) async => right(unit));

      when(() => mockLspRepository.getDefinition(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            position: any(named: 'position'),
          )).thenAnswer((_) async => right([]));

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
        position: const CursorPosition(line: 0, column: 0),
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should not fail'),
        (locs) => expect(locs, isEmpty),
      );
    });
  });
}
