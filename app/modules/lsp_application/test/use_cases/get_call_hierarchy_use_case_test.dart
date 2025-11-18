import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_application/lsp_application.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockLspClientRepository extends Mock implements ILspClientRepository {}

void main() {
  group('GetCallHierarchyUseCase', () {
    late MockLspClientRepository mockLspRepository;
    late GetCallHierarchyUseCase useCase;
    late LspSession session;
    late DocumentUri documentUri;
    late CursorPosition position;
    late CallHierarchyItem hierarchyItem;

    setUp(() {
      mockLspRepository = MockLspClientRepository();
      useCase = GetCallHierarchyUseCase(mockLspRepository);

      session = LspSession(
        id: SessionId.generate(),
        languageId: LanguageId.dart,
        state: SessionState.ready,
        createdAt: DateTime.now(),
      );

      documentUri = DocumentUri.fromFilePath('/lib/service.dart');
      position = const CursorPosition(line: 10, column: 5);

      hierarchyItem = CallHierarchyItem(
        name: 'processData',
        kind: SymbolKind.function,
        uri: documentUri,
        range: const Range(
          start: Position(line: 10, character: 0),
          end: Position(line: 20, character: 0),
        ),
        selectionRange: const Range(
          start: Position(line: 10, character: 5),
          end: Position(line: 10, character: 16),
        ),
      );

      registerFallbackValue(SessionId.generate());
      registerFallbackValue(LanguageId.dart);
      registerFallbackValue(documentUri);
      registerFallbackValue(const CursorPosition(line: 0, column: 0));
      registerFallbackValue(hierarchyItem);
    });

    group('call', () {
      test('should get call hierarchy successfully with both directions', () async {
        // Arrange
        final incomingCalls = [
          CallHierarchyIncomingCall(
            from: CallHierarchyItem(
              name: 'caller1',
              kind: SymbolKind.function,
              uri: DocumentUri.fromFilePath('/lib/caller1.dart'),
              range: const Range(
                start: Position(line: 5, character: 0),
                end: Position(line: 10, character: 0),
              ),
              selectionRange: const Range(
                start: Position(line: 5, character: 0),
                end: Position(line: 5, character: 7),
              ),
            ),
            fromRanges: [
              const Range(
                start: Position(line: 7, character: 2),
                end: Position(line: 7, character: 13),
              ),
            ],
          ),
        ];

        final outgoingCalls = [
          CallHierarchyOutgoingCall(
            to: CallHierarchyItem(
              name: 'helper',
              kind: SymbolKind.function,
              uri: DocumentUri.fromFilePath('/lib/helper.dart'),
              range: const Range(
                start: Position(line: 3, character: 0),
                end: Position(line: 8, character: 0),
              ),
              selectionRange: const Range(
                start: Position(line: 3, character: 0),
                end: Position(line: 3, character: 6),
              ),
            ),
            fromRanges: [
              const Range(
                start: Position(line: 15, character: 2),
                end: Position(line: 15, character: 8),
              ),
            ],
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.prepareCallHierarchy(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              position: any(named: 'position'),
            )).thenAnswer((_) async => right(hierarchyItem));

        when(() => mockLspRepository.getIncomingCalls(
              sessionId: any(named: 'sessionId'),
              item: any(named: 'item'),
            )).thenAnswer((_) async => right(incomingCalls));

        when(() => mockLspRepository.getOutgoingCalls(
              sessionId: any(named: 'sessionId'),
              item: any(named: 'item'),
            )).thenAnswer((_) async => right(outgoingCalls));

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
          (hierarchyResult) {
            expect(hierarchyResult.item, equals(hierarchyItem));
            expect(hierarchyResult.incomingCalls.length, equals(1));
            expect(hierarchyResult.outgoingCalls.length, equals(1));
            expect(hierarchyResult.incomingCalls[0].from.name, equals('caller1'));
            expect(hierarchyResult.outgoingCalls[0].to.name, equals('helper'));
          },
        );

        verify(() => mockLspRepository.prepareCallHierarchy(
              sessionId: session.id,
              documentUri: documentUri,
              position: position,
            )).called(1);
        verify(() => mockLspRepository.getIncomingCalls(
              sessionId: session.id,
              item: hierarchyItem,
            )).called(1);
        verify(() => mockLspRepository.getOutgoingCalls(
              sessionId: session.id,
              item: hierarchyItem,
            )).called(1);
      });

      test('should get only incoming calls when direction is incoming', () async {
        // Arrange
        final incomingCalls = [
          CallHierarchyIncomingCall(
            from: CallHierarchyItem(
              name: 'caller',
              kind: SymbolKind.function,
              uri: DocumentUri.fromFilePath('/lib/caller.dart'),
              range: const Range(
                start: Position(line: 1, character: 0),
                end: Position(line: 5, character: 0),
              ),
              selectionRange: const Range(
                start: Position(line: 1, character: 0),
                end: Position(line: 1, character: 6),
              ),
            ),
            fromRanges: [
              const Range(
                start: Position(line: 3, character: 0),
                end: Position(line: 3, character: 11),
              ),
            ],
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.prepareCallHierarchy(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              position: any(named: 'position'),
            )).thenAnswer((_) async => right(hierarchyItem));

        when(() => mockLspRepository.getIncomingCalls(
              sessionId: any(named: 'sessionId'),
              item: any(named: 'item'),
            )).thenAnswer((_) async => right(incomingCalls));

        // Act
        final result = await useCase(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          position: position,
          direction: CallHierarchyDirection.incoming,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (hierarchyResult) {
            expect(hierarchyResult.incomingCalls.length, equals(1));
            expect(hierarchyResult.outgoingCalls, isEmpty);
          },
        );

        verify(() => mockLspRepository.getIncomingCalls(
              sessionId: session.id,
              item: hierarchyItem,
            )).called(1);
        verifyNever(() => mockLspRepository.getOutgoingCalls(
              sessionId: any(named: 'sessionId'),
              item: any(named: 'item'),
            ));
      });

      test('should get only outgoing calls when direction is outgoing', () async {
        // Arrange
        final outgoingCalls = [
          CallHierarchyOutgoingCall(
            to: CallHierarchyItem(
              name: 'callee',
              kind: SymbolKind.function,
              uri: DocumentUri.fromFilePath('/lib/callee.dart'),
              range: const Range(
                start: Position(line: 1, character: 0),
                end: Position(line: 5, character: 0),
              ),
              selectionRange: const Range(
                start: Position(line: 1, character: 0),
                end: Position(line: 1, character: 6),
              ),
            ),
            fromRanges: [
              const Range(
                start: Position(line: 12, character: 2),
                end: Position(line: 12, character: 8),
              ),
            ],
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.prepareCallHierarchy(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              position: any(named: 'position'),
            )).thenAnswer((_) async => right(hierarchyItem));

        when(() => mockLspRepository.getOutgoingCalls(
              sessionId: any(named: 'sessionId'),
              item: any(named: 'item'),
            )).thenAnswer((_) async => right(outgoingCalls));

        // Act
        final result = await useCase(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          position: position,
          direction: CallHierarchyDirection.outgoing,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (hierarchyResult) {
            expect(hierarchyResult.incomingCalls, isEmpty);
            expect(hierarchyResult.outgoingCalls.length, equals(1));
          },
        );

        verifyNever(() => mockLspRepository.getIncomingCalls(
              sessionId: any(named: 'sessionId'),
              item: any(named: 'item'),
            ));
        verify(() => mockLspRepository.getOutgoingCalls(
              sessionId: session.id,
              item: hierarchyItem,
            )).called(1);
      });

      test('should fail when no hierarchy item found at position', () async {
        // Arrange
        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.prepareCallHierarchy(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              position: any(named: 'position'),
            )).thenAnswer((_) async => right(null));

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
            expect(failure, isA<LspFailure>());
            expect(failure.message, contains('No call hierarchy item found'));
          },
          (_) => fail('Should not succeed'),
        );
      });

      test('should handle empty incoming and outgoing calls', () async {
        // Arrange
        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.prepareCallHierarchy(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              position: any(named: 'position'),
            )).thenAnswer((_) async => right(hierarchyItem));

        when(() => mockLspRepository.getIncomingCalls(
              sessionId: any(named: 'sessionId'),
              item: any(named: 'item'),
            )).thenAnswer((_) async => right([]));

        when(() => mockLspRepository.getOutgoingCalls(
              sessionId: any(named: 'sessionId'),
              item: any(named: 'item'),
            )).thenAnswer((_) async => right([]));

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
          (hierarchyResult) {
            expect(hierarchyResult.item, equals(hierarchyItem));
            expect(hierarchyResult.incomingCalls, isEmpty);
            expect(hierarchyResult.outgoingCalls, isEmpty);
          },
        );
      });

      test('should ignore incoming call errors when getting both', () async {
        // Arrange
        final outgoingCalls = [
          CallHierarchyOutgoingCall(
            to: CallHierarchyItem(
              name: 'helper',
              kind: SymbolKind.function,
              uri: DocumentUri.fromFilePath('/lib/helper.dart'),
              range: const Range(
                start: Position(line: 1, character: 0),
                end: Position(line: 5, character: 0),
              ),
              selectionRange: const Range(
                start: Position(line: 1, character: 0),
                end: Position(line: 1, character: 6),
              ),
            ),
            fromRanges: [const Range(start: Position(line: 3, character: 0), end: Position(line: 3, character: 6))],
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.prepareCallHierarchy(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              position: any(named: 'position'),
            )).thenAnswer((_) async => right(hierarchyItem));

        when(() => mockLspRepository.getIncomingCalls(
              sessionId: any(named: 'sessionId'),
              item: any(named: 'item'),
            )).thenAnswer((_) async => left(const LspFailure.serverError(message: 'Error')));

        when(() => mockLspRepository.getOutgoingCalls(
              sessionId: any(named: 'sessionId'),
              item: any(named: 'item'),
            )).thenAnswer((_) async => right(outgoingCalls));

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
          (hierarchyResult) {
            expect(hierarchyResult.incomingCalls, isEmpty);
            expect(hierarchyResult.outgoingCalls.length, equals(1));
          },
        );
      });

      test('should ignore outgoing call errors when getting both', () async {
        // Arrange
        final incomingCalls = [
          CallHierarchyIncomingCall(
            from: CallHierarchyItem(
              name: 'caller',
              kind: SymbolKind.function,
              uri: DocumentUri.fromFilePath('/lib/caller.dart'),
              range: const Range(
                start: Position(line: 1, character: 0),
                end: Position(line: 5, character: 0),
              ),
              selectionRange: const Range(
                start: Position(line: 1, character: 0),
                end: Position(line: 1, character: 6),
              ),
            ),
            fromRanges: [const Range(start: Position(line: 2, character: 0), end: Position(line: 2, character: 11))],
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.prepareCallHierarchy(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              position: any(named: 'position'),
            )).thenAnswer((_) async => right(hierarchyItem));

        when(() => mockLspRepository.getIncomingCalls(
              sessionId: any(named: 'sessionId'),
              item: any(named: 'item'),
            )).thenAnswer((_) async => right(incomingCalls));

        when(() => mockLspRepository.getOutgoingCalls(
              sessionId: any(named: 'sessionId'),
              item: any(named: 'item'),
            )).thenAnswer((_) async => left(const LspFailure.serverError(message: 'Error')));

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
          (hierarchyResult) {
            expect(hierarchyResult.incomingCalls.length, equals(1));
            expect(hierarchyResult.outgoingCalls, isEmpty);
          },
        );
      });

      test('should fail when session not found', () async {
        // Arrange
        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => left(const LspFailure.sessionNotFound()));

        // Act
        final result = await useCase(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          position: position,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<LspFailure>()),
          (_) => fail('Should not succeed'),
        );
      });

      test('should fail when prepare call hierarchy fails', () async {
        // Arrange
        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.prepareCallHierarchy(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              position: any(named: 'position'),
            )).thenAnswer((_) async => left(const LspFailure.serverError(
              message: 'Failed to prepare hierarchy',
            )));

        // Act
        final result = await useCase(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          position: position,
        );

        // Assert
        expect(result.isLeft(), isTrue);
      });
    });
  });
}
