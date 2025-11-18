import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_application/lsp_application.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockLspClientRepository extends Mock implements ILspClientRepository {}

void main() {
  group('GetWorkspaceSymbolsUseCase', () {
    late MockLspClientRepository mockLspRepository;
    late GetWorkspaceSymbolsUseCase useCase;
    late LspSession session;

    setUp(() {
      mockLspRepository = MockLspClientRepository();
      useCase = GetWorkspaceSymbolsUseCase(mockLspRepository);

      session = LspSession(
        id: SessionId.generate(),
        languageId: LanguageId.dart,
        state: SessionState.ready,
        createdAt: DateTime.now(),
      );

      registerFallbackValue(SessionId.generate());
      registerFallbackValue(LanguageId.dart);
    });

    group('call', () {
      test('should return empty list when query is empty', () async {
        // Arrange
        const query = '';

        // Act
        final result = await useCase(
          languageId: LanguageId.dart,
          query: query,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (symbols) => expect(symbols, isEmpty),
        );

        verifyNever(() => mockLspRepository.getSession(any()));
      });

      test('should get workspace symbols successfully', () async {
        // Arrange
        const query = 'UserRepo';
        final symbols = [
          WorkspaceSymbol(
            name: 'UserRepository',
            kind: SymbolKind.class_,
            location: Location(
              uri: DocumentUri.fromFilePath('/lib/user_repository.dart'),
              range: const Range(
                start: Position(line: 5, character: 0),
                end: Position(line: 20, character: 0),
              ),
            ),
          ),
          WorkspaceSymbol(
            name: 'IUserRepository',
            kind: SymbolKind.interface,
            location: Location(
              uri: DocumentUri.fromFilePath('/lib/i_user_repository.dart'),
              range: const Range(
                start: Position(line: 3, character: 0),
                end: Position(line: 10, character: 0),
              ),
            ),
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getWorkspaceSymbols(
              sessionId: any(named: 'sessionId'),
              query: any(named: 'query'),
            )).thenAnswer((_) async => right(symbols));

        // Act
        final result = await useCase(
          languageId: LanguageId.dart,
          query: query,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (resultSymbols) {
            expect(resultSymbols.length, equals(2));
            expect(resultSymbols[0].name, equals('IUserRepository'));
            expect(resultSymbols[1].name, equals('UserRepository'));
          },
        );

        verify(() => mockLspRepository.getWorkspaceSymbols(
              sessionId: session.id,
              query: query,
            )).called(1);
      });

      test('should sort symbols with exact matches first', () async {
        // Arrange
        const query = 'User';
        final symbols = [
          WorkspaceSymbol(
            name: 'UserService',
            kind: SymbolKind.class_,
            location: Location(
              uri: DocumentUri.fromFilePath('/lib/user_service.dart'),
              range: const Range(
                start: Position(line: 5, character: 0),
                end: Position(line: 20, character: 0),
              ),
            ),
          ),
          WorkspaceSymbol(
            name: 'User',
            kind: SymbolKind.class_,
            location: Location(
              uri: DocumentUri.fromFilePath('/lib/user.dart'),
              range: const Range(
                start: Position(line: 3, character: 0),
                end: Position(line: 15, character: 0),
              ),
            ),
          ),
          WorkspaceSymbol(
            name: 'AdminUser',
            kind: SymbolKind.class_,
            location: Location(
              uri: DocumentUri.fromFilePath('/lib/admin_user.dart'),
              range: const Range(
                start: Position(line: 2, character: 0),
                end: Position(line: 12, character: 0),
              ),
            ),
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getWorkspaceSymbols(
              sessionId: any(named: 'sessionId'),
              query: any(named: 'query'),
            )).thenAnswer((_) async => right(symbols));

        // Act
        final result = await useCase(
          languageId: LanguageId.dart,
          query: query,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (resultSymbols) {
            expect(resultSymbols.length, equals(3));
            // Exact match should be first
            expect(resultSymbols[0].name, equals('User'));
            // Then sorted alphabetically
            expect(resultSymbols[1].name, equals('AdminUser'));
            expect(resultSymbols[2].name, equals('UserService'));
          },
        );
      });

      test('should handle case-insensitive exact matching', () async {
        // Arrange
        const query = 'user';
        final symbols = [
          WorkspaceSymbol(
            name: 'UserModel',
            kind: SymbolKind.class_,
            location: Location(
              uri: DocumentUri.fromFilePath('/lib/user_model.dart'),
              range: const Range(
                start: Position(line: 1, character: 0),
                end: Position(line: 10, character: 0),
              ),
            ),
          ),
          WorkspaceSymbol(
            name: 'User',
            kind: SymbolKind.class_,
            location: Location(
              uri: DocumentUri.fromFilePath('/lib/user.dart'),
              range: const Range(
                start: Position(line: 1, character: 0),
                end: Position(line: 10, character: 0),
              ),
            ),
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getWorkspaceSymbols(
              sessionId: any(named: 'sessionId'),
              query: any(named: 'query'),
            )).thenAnswer((_) async => right(symbols));

        // Act
        final result = await useCase(
          languageId: LanguageId.dart,
          query: query,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (resultSymbols) {
            expect(resultSymbols.length, equals(2));
            // 'User' is exact match (case-insensitive)
            expect(resultSymbols[0].name, equals('User'));
            expect(resultSymbols[1].name, equals('UserModel'));
          },
        );
      });

      test('should fail when session not found', () async {
        // Arrange
        const query = 'Test';

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => left(const LspFailure.sessionNotFound()));

        // Act
        final result = await useCase(
          languageId: LanguageId.dart,
          query: query,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<LspFailure>()),
          (_) => fail('Should not succeed'),
        );
      });

      test('should fail when LSP request fails', () async {
        // Arrange
        const query = 'Test';

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getWorkspaceSymbols(
              sessionId: any(named: 'sessionId'),
              query: any(named: 'query'),
            )).thenAnswer((_) async => left(const LspFailure.serverError(
              message: 'LSP server error',
            )));

        // Act
        final result = await useCase(
          languageId: LanguageId.dart,
          query: query,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<LspFailure>()),
          (_) => fail('Should not succeed'),
        );
      });

      test('should handle empty symbol list from LSP', () async {
        // Arrange
        const query = 'NonExistent';

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getWorkspaceSymbols(
              sessionId: any(named: 'sessionId'),
              query: any(named: 'query'),
            )).thenAnswer((_) async => right([]));

        // Act
        final result = await useCase(
          languageId: LanguageId.dart,
          query: query,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (symbols) => expect(symbols, isEmpty),
        );
      });

      test('should handle multiple symbols with same name', () async {
        // Arrange
        const query = 'getData';
        final symbols = [
          WorkspaceSymbol(
            name: 'getData',
            kind: SymbolKind.function,
            location: Location(
              uri: DocumentUri.fromFilePath('/lib/service_a.dart'),
              range: const Range(
                start: Position(line: 10, character: 0),
                end: Position(line: 15, character: 0),
              ),
            ),
          ),
          WorkspaceSymbol(
            name: 'getData',
            kind: SymbolKind.function,
            location: Location(
              uri: DocumentUri.fromFilePath('/lib/service_b.dart'),
              range: const Range(
                start: Position(line: 20, character: 0),
                end: Position(line: 25, character: 0),
              ),
            ),
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getWorkspaceSymbols(
              sessionId: any(named: 'sessionId'),
              query: any(named: 'query'),
            )).thenAnswer((_) async => right(symbols));

        // Act
        final result = await useCase(
          languageId: LanguageId.dart,
          query: query,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (resultSymbols) {
            expect(resultSymbols.length, equals(2));
            expect(resultSymbols.every((s) => s.name == 'getData'), isTrue);
          },
        );
      });
    });
  });
}
