import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_application/lsp_application.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockLspClientRepository extends Mock implements ILspClientRepository {}
class MockCodeEditorRepository extends Mock implements ICodeEditorRepository {}

void main() {
  group('FindReferencesUseCase', () {
    late MockLspClientRepository mockLspRepository;
    late MockCodeEditorRepository mockEditorRepository;
    late FindReferencesUseCase useCase;
    late LspSession session;

    setUp(() {
      mockLspRepository = MockLspClientRepository();
      mockEditorRepository = MockCodeEditorRepository();
      useCase = FindReferencesUseCase(mockLspRepository, mockEditorRepository);

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

    test('should find references successfully', () async {
      // Arrange
      final documentUri = DocumentUri.fromFilePath('/current/file.dart');
      final position = const CursorPosition(line: 10, column: 5);
      const content = 'class Test { }';

      final references = [
        Location(
          uri: DocumentUri.fromFilePath('/file1.dart'),
          range: const Range(
            start: Position(line: 5, character: 0),
            end: Position(line: 5, character: 10),
          ),
        ),
        Location(
          uri: DocumentUri.fromFilePath('/file2.dart'),
          range: const Range(
            start: Position(line: 15, character: 5),
            end: Position(line: 15, character: 15),
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

      when(() => mockLspRepository.findReferences(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            position: any(named: 'position'),
            includeDeclaration: any(named: 'includeDeclaration'),
          )).thenAnswer((_) async => right(references));

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
        (refs) {
          expect(refs.length, equals(2));
          expect(refs[0].uri.path, contains('file1.dart'));
          expect(refs[1].uri.path, contains('file2.dart'));
        },
      );
    });

    test('should include declaration when requested', () async {
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

      when(() => mockLspRepository.findReferences(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            position: any(named: 'position'),
            includeDeclaration: true,
          )).thenAnswer((_) async => right([]));

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
        position: const CursorPosition(line: 0, column: 0),
        includeDeclaration: true,
      );

      // Assert
      expect(result.isRight(), isTrue);
      verify(() => mockLspRepository.findReferences(
            sessionId: session.id,
            documentUri: any(named: 'documentUri'),
            position: any(named: 'position'),
            includeDeclaration: true,
          )).called(1);
    });

    test('should handle empty references list', () async {
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

      when(() => mockLspRepository.findReferences(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            position: any(named: 'position'),
            includeDeclaration: any(named: 'includeDeclaration'),
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
        (refs) => expect(refs, isEmpty),
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
      result.fold(
        (failure) {
          expect(failure, isA<_ServerNotResponding>());
        },
        (_) => fail('Should not succeed'),
      );
    });
  });
}
