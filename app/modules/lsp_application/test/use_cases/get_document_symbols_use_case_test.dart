import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_application/lsp_application.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockLspClientRepository extends Mock implements ILspClientRepository {}

void main() {
  group('GetDocumentSymbolsUseCase', () {
    late MockLspClientRepository mockRepository;
    late GetDocumentSymbolsUseCase useCase;
    late LspSession session;

    setUp(() {
      mockRepository = MockLspClientRepository();
      useCase = GetDocumentSymbolsUseCase(mockRepository);

      session = LspSession(
        id: SessionId.generate(),
        languageId: LanguageId.dart,
        state: SessionState.ready,
        createdAt: DateTime.now(),
      );

      registerFallbackValue(SessionId.generate());
      registerFallbackValue(DocumentUri.fromFilePath('/test.dart'));
      registerFallbackValue(LanguageId.dart);
    });

    test('should get document symbols successfully', () async {
      // Arrange
      final documentUri = DocumentUri.fromFilePath('/test/file.dart');

      final symbols = [
        const DocumentSymbol(
          name: 'MyClass',
          kind: SymbolKind.classSymbol,
          range: Range(
            start: Position(line: 0, character: 0),
            end: Position(line: 10, character: 0),
          ),
          selectionRange: Range(
            start: Position(line: 0, character: 6),
            end: Position(line: 0, character: 13),
          ),
          children: [],
        ),
        const DocumentSymbol(
          name: 'myFunction',
          kind: SymbolKind.function,
          range: Range(
            start: Position(line: 12, character: 0),
            end: Position(line: 15, character: 0),
          ),
          selectionRange: Range(
            start: Position(line: 12, character: 5),
            end: Position(line: 12, character: 15),
          ),
          children: [],
        ),
      ];

      when(() => mockRepository.getSession(any()))
          .thenAnswer((_) async => right(session));

      when(() => mockRepository.getDocumentSymbols(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
          )).thenAnswer((_) async => right(symbols));

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        documentUri: documentUri,
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should not fail'),
        (syms) {
          expect(syms.length, equals(2));
          expect(syms[0].name, equals('MyClass'));
          expect(syms[0].kind, equals(SymbolKind.classSymbol));
          expect(syms[1].name, equals('myFunction'));
          expect(syms[1].kind, equals(SymbolKind.function));
        },
      );

      verify(() => mockRepository.getDocumentSymbols(
            sessionId: session.id,
            documentUri: documentUri,
          )).called(1);
    });

    test('should handle hierarchical symbols', () async {
      // Arrange
      final documentUri = DocumentUri.fromFilePath('/test/file.dart');

      final symbols = [
        const DocumentSymbol(
          name: 'MyClass',
          kind: SymbolKind.classSymbol,
          range: Range(
            start: Position(line: 0, character: 0),
            end: Position(line: 10, character: 0),
          ),
          selectionRange: Range(
            start: Position(line: 0, character: 6),
            end: Position(line: 0, character: 13),
          ),
          children: [
            DocumentSymbol(
              name: 'method1',
              kind: SymbolKind.method,
              range: Range(
                start: Position(line: 2, character: 2),
                end: Position(line: 4, character: 2),
              ),
              selectionRange: Range(
                start: Position(line: 2, character: 7),
                end: Position(line: 2, character: 14),
              ),
              children: [],
            ),
          ],
        ),
      ];

      when(() => mockRepository.getSession(any()))
          .thenAnswer((_) async => right(session));

      when(() => mockRepository.getDocumentSymbols(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
          )).thenAnswer((_) async => right(symbols));

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        documentUri: documentUri,
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should not fail'),
        (syms) {
          expect(syms.length, equals(1));
          expect(syms[0].children.length, equals(1));
          expect(syms[0].children[0].name, equals('method1'));
        },
      );
    });

    test('should handle empty symbol list', () async {
      // Arrange
      when(() => mockRepository.getSession(any()))
          .thenAnswer((_) async => right(session));

      when(() => mockRepository.getDocumentSymbols(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
          )).thenAnswer((_) async => right([]));

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should not fail'),
        (syms) => expect(syms, isEmpty),
      );
    });

    test('should fail when session not ready', () async {
      // Arrange
      final notReadySession = session.copyWith(state: SessionState.initializing);

      when(() => mockRepository.getSession(any()))
          .thenAnswer((_) async => right(notReadySession));

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
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
