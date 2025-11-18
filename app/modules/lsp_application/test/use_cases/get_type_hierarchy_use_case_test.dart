import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_application/lsp_application.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockLspClientRepository extends Mock implements ILspClientRepository {}

void main() {
  group('GetTypeHierarchyUseCase', () {
    late MockLspClientRepository mockLspRepository;
    late GetTypeHierarchyUseCase useCase;
    late LspSession session;
    late DocumentUri documentUri;
    late CursorPosition position;
    late TypeHierarchyItem hierarchyItem;

    setUp(() {
      mockLspRepository = MockLspClientRepository();
      useCase = GetTypeHierarchyUseCase(mockLspRepository);

      session = LspSession(
        id: SessionId.generate(),
        languageId: LanguageId.dart,
        state: SessionState.ready,
        createdAt: DateTime.now(),
      );

      documentUri = DocumentUri.fromFilePath('/lib/user.dart');
      position = const CursorPosition(line: 5, column: 6);

      hierarchyItem = TypeHierarchyItem(
        name: 'User',
        kind: SymbolKind.class_,
        uri: documentUri,
        range: const Range(
          start: Position(line: 5, character: 0),
          end: Position(line: 20, character: 0),
        ),
        selectionRange: const Range(
          start: Position(line: 5, character: 6),
          end: Position(line: 5, character: 10),
        ),
      );

      registerFallbackValue(SessionId.generate());
      registerFallbackValue(LanguageId.dart);
      registerFallbackValue(documentUri);
      registerFallbackValue(const CursorPosition(line: 0, column: 0));
      registerFallbackValue(hierarchyItem);
    });

    group('call', () {
      test('should get type hierarchy successfully with both directions', () async {
        // Arrange
        final supertypes = [
          TypeHierarchyItem(
            name: 'Person',
            kind: SymbolKind.class_,
            uri: DocumentUri.fromFilePath('/lib/person.dart'),
            range: const Range(
              start: Position(line: 1, character: 0),
              end: Position(line: 15, character: 0),
            ),
            selectionRange: const Range(
              start: Position(line: 1, character: 6),
              end: Position(line: 1, character: 12),
            ),
          ),
        ];

        final subtypes = [
          TypeHierarchyItem(
            name: 'AdminUser',
            kind: SymbolKind.class_,
            uri: DocumentUri.fromFilePath('/lib/admin_user.dart'),
            range: const Range(
              start: Position(line: 3, character: 0),
              end: Position(line: 25, character: 0),
            ),
            selectionRange: const Range(
              start: Position(line: 3, character: 6),
              end: Position(line: 3, character: 15),
            ),
          ),
          TypeHierarchyItem(
            name: 'GuestUser',
            kind: SymbolKind.class_,
            uri: DocumentUri.fromFilePath('/lib/guest_user.dart'),
            range: const Range(
              start: Position(line: 2, character: 0),
              end: Position(line: 10, character: 0),
            ),
            selectionRange: const Range(
              start: Position(line: 2, character: 6),
              end: Position(line: 2, character: 15),
            ),
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.prepareTypeHierarchy(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              position: any(named: 'position'),
            )).thenAnswer((_) async => right(hierarchyItem));

        when(() => mockLspRepository.getSupertypes(
              sessionId: any(named: 'sessionId'),
              item: any(named: 'item'),
            )).thenAnswer((_) async => right(supertypes));

        when(() => mockLspRepository.getSubtypes(
              sessionId: any(named: 'sessionId'),
              item: any(named: 'item'),
            )).thenAnswer((_) async => right(subtypes));

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
            expect(hierarchyResult.supertypes.length, equals(1));
            expect(hierarchyResult.subtypes.length, equals(2));
            expect(hierarchyResult.supertypes[0].name, equals('Person'));
            expect(hierarchyResult.subtypes[0].name, equals('AdminUser'));
            expect(hierarchyResult.subtypes[1].name, equals('GuestUser'));
          },
        );

        verify(() => mockLspRepository.prepareTypeHierarchy(
              sessionId: session.id,
              documentUri: documentUri,
              position: position,
            )).called(1);
        verify(() => mockLspRepository.getSupertypes(
              sessionId: session.id,
              item: hierarchyItem,
            )).called(1);
        verify(() => mockLspRepository.getSubtypes(
              sessionId: session.id,
              item: hierarchyItem,
            )).called(1);
      });

      test('should get only supertypes when direction is supertypes', () async {
        // Arrange
        final supertypes = [
          TypeHierarchyItem(
            name: 'BaseClass',
            kind: SymbolKind.class_,
            uri: DocumentUri.fromFilePath('/lib/base.dart'),
            range: const Range(
              start: Position(line: 1, character: 0),
              end: Position(line: 10, character: 0),
            ),
            selectionRange: const Range(
              start: Position(line: 1, character: 6),
              end: Position(line: 1, character: 15),
            ),
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.prepareTypeHierarchy(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              position: any(named: 'position'),
            )).thenAnswer((_) async => right(hierarchyItem));

        when(() => mockLspRepository.getSupertypes(
              sessionId: any(named: 'sessionId'),
              item: any(named: 'item'),
            )).thenAnswer((_) async => right(supertypes));

        // Act
        final result = await useCase(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          position: position,
          direction: TypeHierarchyDirection.supertypes,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (hierarchyResult) {
            expect(hierarchyResult.supertypes.length, equals(1));
            expect(hierarchyResult.subtypes, isEmpty);
          },
        );

        verify(() => mockLspRepository.getSupertypes(
              sessionId: session.id,
              item: hierarchyItem,
            )).called(1);
        verifyNever(() => mockLspRepository.getSubtypes(
              sessionId: any(named: 'sessionId'),
              item: any(named: 'item'),
            ));
      });

      test('should get only subtypes when direction is subtypes', () async {
        // Arrange
        final subtypes = [
          TypeHierarchyItem(
            name: 'DerivedClass',
            kind: SymbolKind.class_,
            uri: DocumentUri.fromFilePath('/lib/derived.dart'),
            range: const Range(
              start: Position(line: 1, character: 0),
              end: Position(line: 10, character: 0),
            ),
            selectionRange: const Range(
              start: Position(line: 1, character: 6),
              end: Position(line: 1, character: 18),
            ),
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.prepareTypeHierarchy(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              position: any(named: 'position'),
            )).thenAnswer((_) async => right(hierarchyItem));

        when(() => mockLspRepository.getSubtypes(
              sessionId: any(named: 'sessionId'),
              item: any(named: 'item'),
            )).thenAnswer((_) async => right(subtypes));

        // Act
        final result = await useCase(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          position: position,
          direction: TypeHierarchyDirection.subtypes,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (hierarchyResult) {
            expect(hierarchyResult.supertypes, isEmpty);
            expect(hierarchyResult.subtypes.length, equals(1));
          },
        );

        verifyNever(() => mockLspRepository.getSupertypes(
              sessionId: any(named: 'sessionId'),
              item: any(named: 'item'),
            ));
        verify(() => mockLspRepository.getSubtypes(
              sessionId: session.id,
              item: hierarchyItem,
            )).called(1);
      });

      test('should fail when no hierarchy item found at position', () async {
        // Arrange
        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.prepareTypeHierarchy(
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
            expect(failure.message, contains('No type hierarchy item found'));
          },
          (_) => fail('Should not succeed'),
        );
      });

      test('should handle empty supertypes and subtypes', () async {
        // Arrange
        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.prepareTypeHierarchy(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              position: any(named: 'position'),
            )).thenAnswer((_) async => right(hierarchyItem));

        when(() => mockLspRepository.getSupertypes(
              sessionId: any(named: 'sessionId'),
              item: any(named: 'item'),
            )).thenAnswer((_) async => right([]));

        when(() => mockLspRepository.getSubtypes(
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
            expect(hierarchyResult.supertypes, isEmpty);
            expect(hierarchyResult.subtypes, isEmpty);
          },
        );
      });

      test('should ignore supertype errors when getting both', () async {
        // Arrange
        final subtypes = [
          TypeHierarchyItem(
            name: 'Child',
            kind: SymbolKind.class_,
            uri: DocumentUri.fromFilePath('/lib/child.dart'),
            range: const Range(
              start: Position(line: 1, character: 0),
              end: Position(line: 5, character: 0),
            ),
            selectionRange: const Range(
              start: Position(line: 1, character: 6),
              end: Position(line: 1, character: 11),
            ),
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.prepareTypeHierarchy(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              position: any(named: 'position'),
            )).thenAnswer((_) async => right(hierarchyItem));

        when(() => mockLspRepository.getSupertypes(
              sessionId: any(named: 'sessionId'),
              item: any(named: 'item'),
            )).thenAnswer((_) async => left(const LspFailure.serverError(message: 'Error')));

        when(() => mockLspRepository.getSubtypes(
              sessionId: any(named: 'sessionId'),
              item: any(named: 'item'),
            )).thenAnswer((_) async => right(subtypes));

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
            expect(hierarchyResult.supertypes, isEmpty);
            expect(hierarchyResult.subtypes.length, equals(1));
          },
        );
      });

      test('should ignore subtype errors when getting both', () async {
        // Arrange
        final supertypes = [
          TypeHierarchyItem(
            name: 'Parent',
            kind: SymbolKind.class_,
            uri: DocumentUri.fromFilePath('/lib/parent.dart'),
            range: const Range(
              start: Position(line: 1, character: 0),
              end: Position(line: 5, character: 0),
            ),
            selectionRange: const Range(
              start: Position(line: 1, character: 6),
              end: Position(line: 1, character: 12),
            ),
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.prepareTypeHierarchy(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              position: any(named: 'position'),
            )).thenAnswer((_) async => right(hierarchyItem));

        when(() => mockLspRepository.getSupertypes(
              sessionId: any(named: 'sessionId'),
              item: any(named: 'item'),
            )).thenAnswer((_) async => right(supertypes));

        when(() => mockLspRepository.getSubtypes(
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
            expect(hierarchyResult.supertypes.length, equals(1));
            expect(hierarchyResult.subtypes, isEmpty);
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

      test('should fail when prepare type hierarchy fails', () async {
        // Arrange
        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.prepareTypeHierarchy(
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

      test('should handle interface with multiple implementations', () async {
        // Arrange
        final subtypes = [
          TypeHierarchyItem(
            name: 'Implementation1',
            kind: SymbolKind.class_,
            uri: DocumentUri.fromFilePath('/lib/impl1.dart'),
            range: const Range(start: Position(line: 1, character: 0), end: Position(line: 10, character: 0)),
            selectionRange: const Range(start: Position(line: 1, character: 6), end: Position(line: 1, character: 20)),
          ),
          TypeHierarchyItem(
            name: 'Implementation2',
            kind: SymbolKind.class_,
            uri: DocumentUri.fromFilePath('/lib/impl2.dart'),
            range: const Range(start: Position(line: 1, character: 0), end: Position(line: 10, character: 0)),
            selectionRange: const Range(start: Position(line: 1, character: 6), end: Position(line: 1, character: 20)),
          ),
          TypeHierarchyItem(
            name: 'Implementation3',
            kind: SymbolKind.class_,
            uri: DocumentUri.fromFilePath('/lib/impl3.dart'),
            range: const Range(start: Position(line: 1, character: 0), end: Position(line: 10, character: 0)),
            selectionRange: const Range(start: Position(line: 1, character: 6), end: Position(line: 1, character: 20)),
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.prepareTypeHierarchy(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              position: any(named: 'position'),
            )).thenAnswer((_) async => right(hierarchyItem));

        when(() => mockLspRepository.getSupertypes(
              sessionId: any(named: 'sessionId'),
              item: any(named: 'item'),
            )).thenAnswer((_) async => right([]));

        when(() => mockLspRepository.getSubtypes(
              sessionId: any(named: 'sessionId'),
              item: any(named: 'item'),
            )).thenAnswer((_) async => right(subtypes));

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
            expect(hierarchyResult.subtypes.length, equals(3));
          },
        );
      });
    });
  });
}
