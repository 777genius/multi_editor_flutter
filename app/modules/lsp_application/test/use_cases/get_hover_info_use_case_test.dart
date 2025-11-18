import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_application/lsp_application.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockLspClientRepository extends Mock implements ILspClientRepository {}

void main() {
  group('GetHoverInfoUseCase', () {
    late MockLspClientRepository mockRepository;
    late GetHoverInfoUseCase useCase;
    late LspSession session;

    setUp(() {
      mockRepository = MockLspClientRepository();
      useCase = GetHoverInfoUseCase(mockRepository);

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

    test('should get hover info successfully', () async {
      // Arrange
      final documentUri = DocumentUri.fromFilePath('/test/file.dart');
      final position = const CursorPosition(line: 5, column: 10);

      const hoverInfo = HoverInfo(
        contents: 'String toString()\n\nReturns a string representation',
        range: Range(
          start: Position(line: 5, character: 10),
          end: Position(line: 5, character: 18),
        ),
      );

      when(() => mockRepository.getSession(any()))
          .thenAnswer((_) async => right(session));

      when(() => mockRepository.getHoverInfo(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            position: any(named: 'position'),
          )).thenAnswer((_) async => right(hoverInfo));

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
        (info) {
          expect(info.contents, contains('toString'));
          expect(info.range, isNotNull);
        },
      );

      verify(() => mockRepository.getHoverInfo(
            sessionId: session.id,
            documentUri: documentUri,
            position: position,
          )).called(1);
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

    test('should handle empty hover info', () async {
      // Arrange
      const emptyHoverInfo = HoverInfo(
        contents: '',
        range: null,
      );

      when(() => mockRepository.getSession(any()))
          .thenAnswer((_) async => right(session));

      when(() => mockRepository.getHoverInfo(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            position: any(named: 'position'),
          )).thenAnswer((_) async => right(emptyHoverInfo));

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
        (info) => expect(info.isEmpty, isTrue),
      );
    });

    test('should handle markdown content', () async {
      // Arrange
      const hoverInfo = HoverInfo(
        contents: '```dart\nvoid main() {}\n```\n\nThe main entry point',
        range: Range(
          start: Position(line: 0, character: 0),
          end: Position(line: 0, character: 4),
        ),
      );

      when(() => mockRepository.getSession(any()))
          .thenAnswer((_) async => right(session));

      when(() => mockRepository.getHoverInfo(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            position: any(named: 'position'),
          )).thenAnswer((_) async => right(hoverInfo));

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
        (info) {
          expect(info.contents, contains('```dart'));
          expect(info.isNotEmpty, isTrue);
        },
      );
    });
  });
}
