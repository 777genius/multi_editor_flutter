import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_application/lsp_application.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockLspClientRepository extends Mock implements ILspClientRepository {}

void main() {
  group('InitializeLspSessionUseCase', () {
    late MockLspClientRepository mockRepository;
    late InitializeLspSessionUseCase useCase;
    late DocumentUri rootUri;

    setUp(() {
      mockRepository = MockLspClientRepository();
      useCase = InitializeLspSessionUseCase(mockRepository);
      rootUri = DocumentUri.fromFilePath('/test/project');

      registerFallbackValue(LanguageId.dart);
      registerFallbackValue(rootUri);
    });

    group('call', () {
      test('should initialize new session successfully', () async {
        // Arrange
        final session = LspSession(
          id: SessionId.generate(),
          languageId: LanguageId.dart,
          state: SessionState.ready,
          createdAt: DateTime.now(),
        );

        when(() => mockRepository.getSession(any()))
            .thenAnswer((_) async => left(const LspFailure.sessionNotFound()));

        when(() => mockRepository.initialize(
              languageId: any(named: 'languageId'),
              rootUri: any(named: 'rootUri'),
            )).thenAnswer((_) async => right(session));

        // Act
        final result = await useCase(
          languageId: LanguageId.dart,
          rootUri: rootUri,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (sess) {
            expect(sess.languageId, equals(LanguageId.dart));
            expect(sess.state, equals(SessionState.ready));
          },
        );

        verify(() => mockRepository.initialize(
              languageId: LanguageId.dart,
              rootUri: rootUri,
            )).called(1);
      });

      test('should return existing active session', () async {
        // Arrange
        final existingSession = LspSession(
          id: SessionId.generate(),
          languageId: LanguageId.dart,
          state: SessionState.ready,
          createdAt: DateTime.now(),
        );

        when(() => mockRepository.getSession(any()))
            .thenAnswer((_) async => right(existingSession));

        // Act
        final result = await useCase(
          languageId: LanguageId.dart,
          rootUri: rootUri,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (sess) {
            expect(sess.id, equals(existingSession.id));
          },
        );

        verifyNever(() => mockRepository.initialize(
              languageId: any(named: 'languageId'),
              rootUri: any(named: 'rootUri'),
            ));
      });

      test('should reinitialize when existing session is not active', () async {
        // Arrange
        final inactiveSession = LspSession(
          id: SessionId.generate(),
          languageId: LanguageId.dart,
          state: SessionState.failed,
          createdAt: DateTime.now(),
        );

        final newSession = LspSession(
          id: SessionId.generate(),
          languageId: LanguageId.dart,
          state: SessionState.ready,
          createdAt: DateTime.now(),
        );

        when(() => mockRepository.getSession(any()))
            .thenAnswer((_) async => right(inactiveSession));

        when(() => mockRepository.initialize(
              languageId: any(named: 'languageId'),
              rootUri: any(named: 'rootUri'),
            )).thenAnswer((_) async => right(newSession));

        // Act
        final result = await useCase(
          languageId: LanguageId.dart,
          rootUri: rootUri,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockRepository.initialize(
              languageId: LanguageId.dart,
              rootUri: rootUri,
            )).called(1);
      });

      test('should fail when initialization fails', () async {
        // Arrange
        when(() => mockRepository.getSession(any()))
            .thenAnswer((_) async => left(const LspFailure.sessionNotFound()));

        when(() => mockRepository.initialize(
              languageId: any(named: 'languageId'),
              rootUri: any(named: 'rootUri'),
            )).thenAnswer(
          (_) async => left(const LspFailure.serverNotFound(
            message: 'LSP binary not found',
          )),
        );

        // Act
        final result = await useCase(
          languageId: LanguageId.dart,
          rootUri: rootUri,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<_ServerNotFound>());
          },
          (_) => fail('Should not succeed'),
        );
      });

      test('should handle different language IDs', () async {
        // Arrange
        final session = LspSession(
          id: SessionId.generate(),
          languageId: LanguageId.typescript,
          state: SessionState.ready,
          createdAt: DateTime.now(),
        );

        when(() => mockRepository.getSession(LanguageId.typescript))
            .thenAnswer((_) async => left(const LspFailure.sessionNotFound()));

        when(() => mockRepository.initialize(
              languageId: LanguageId.typescript,
              rootUri: any(named: 'rootUri'),
            )).thenAnswer((_) async => right(session));

        // Act
        final result = await useCase(
          languageId: LanguageId.typescript,
          rootUri: rootUri,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (sess) {
            expect(sess.languageId, equals(LanguageId.typescript));
          },
        );
      });
    });
  });
}
