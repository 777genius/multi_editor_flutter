import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_application/lsp_application.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockLspClientRepository extends Mock implements ILspClientRepository {}
class MockCodeEditorRepository extends Mock implements ICodeEditorRepository {}

void main() {
  group('GetCompletionsUseCase', () {
    late MockLspClientRepository mockLspRepository;
    late MockCodeEditorRepository mockEditorRepository;
    late GetCompletionsUseCase useCase;
    late LspSession session;
    late DocumentUri documentUri;
    late CursorPosition position;

    setUp(() {
      mockLspRepository = MockLspClientRepository();
      mockEditorRepository = MockCodeEditorRepository();
      useCase = GetCompletionsUseCase(mockLspRepository, mockEditorRepository);

      session = LspSession(
        id: SessionId.generate(),
        languageId: LanguageId.dart,
        state: SessionState.ready,
        createdAt: DateTime.now(),
      );
      documentUri = DocumentUri.fromFilePath('/test/file.dart');
      position = const CursorPosition(line: 10, column: 5);

      registerFallbackValue(SessionId.generate());
      registerFallbackValue(documentUri);
      registerFallbackValue(LanguageId.dart);
      registerFallbackValue(position);
    });

    group('call', () {
      test('should get completions successfully', () async {
        // Arrange
        const content = 'class Test { }';
        final completions = CompletionList(
          isIncomplete: false,
          items: const [
            CompletionItem(
              label: 'print',
              kind: CompletionItemKind.function,
            ),
            CompletionItem(
              label: 'toString',
              kind: CompletionItemKind.method,
            ),
          ],
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockEditorRepository.getContent())
            .thenAnswer((_) async => right(content));

        when(() => mockLspRepository.notifyDocumentChanged(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              content: any(named: 'content'),
            )).thenAnswer((_) async => right(unit));

        when(() => mockLspRepository.getCompletions(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              position: any(named: 'position'),
            )).thenAnswer((_) async => right(completions));

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
          (list) {
            expect(list.items.length, equals(2));
            expect(list.items[0].label, equals('print'));
          },
        );

        verify(() => mockLspRepository.notifyDocumentChanged(
              sessionId: session.id,
              documentUri: documentUri,
              content: content,
            )).called(1);
      });

      test('should filter completions by prefix', () async {
        // Arrange
        const content = 'class Test { }';
        final completions = CompletionList(
          isIncomplete: false,
          items: const [
            CompletionItem(
              label: 'print',
              kind: CompletionItemKind.function,
            ),
            CompletionItem(
              label: 'toString',
              kind: CompletionItemKind.method,
            ),
            CompletionItem(
              label: 'private',
              kind: CompletionItemKind.keyword,
            ),
          ],
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockEditorRepository.getContent())
            .thenAnswer((_) async => right(content));

        when(() => mockLspRepository.notifyDocumentChanged(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              content: any(named: 'content'),
            )).thenAnswer((_) async => right(unit));

        when(() => mockLspRepository.getCompletions(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              position: any(named: 'position'),
            )).thenAnswer((_) async => right(completions));

        // Act
        final result = await useCase(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          position: position,
          filterPrefix: 'pri',
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (list) {
            expect(list.items.length, equals(2));
            expect(list.items.every((item) =>
              item.label.toLowerCase().startsWith('pri')), isTrue);
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
          documentUri: documentUri,
          position: position,
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

      test('should fail when cannot get editor content', () async {
        // Arrange
        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockEditorRepository.getContent())
            .thenAnswer((_) async => left(const EditorFailure.notInitialized()));

        // Act
        final result = await useCase(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          position: position,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<_Unexpected>());
          },
          (_) => fail('Should not succeed'),
        );
      });

      test('should sort completions by relevance', () async {
        // Arrange
        const content = 'class Test { }';
        final completions = CompletionList(
          isIncomplete: false,
          items: const [
            CompletionItem(
              label: 'zzzLast',
              kind: CompletionItemKind.function,
              sortText: 'zzz',
            ),
            CompletionItem(
              label: 'aaaFirst',
              kind: CompletionItemKind.method,
              sortText: 'aaa',
            ),
          ],
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockEditorRepository.getContent())
            .thenAnswer((_) async => right(content));

        when(() => mockLspRepository.notifyDocumentChanged(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              content: any(named: 'content'),
            )).thenAnswer((_) async => right(unit));

        when(() => mockLspRepository.getCompletions(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              position: any(named: 'position'),
            )).thenAnswer((_) async => right(completions));

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
          (list) {
            expect(list.items[0].label, equals('aaaFirst'));
            expect(list.items[1].label, equals('zzzLast'));
          },
        );
      });
    });
  });
}
