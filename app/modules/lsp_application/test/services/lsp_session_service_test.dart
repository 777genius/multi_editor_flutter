import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_application/lsp_application.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockLspClientRepository extends Mock implements ILspClientRepository {}

void main() {
  group('LspSessionService', () {
    late MockLspClientRepository mockLspRepository;
    late LspSessionService service;
    late DocumentUri rootUri;

    setUp(() {
      mockLspRepository = MockLspClientRepository();
      service = LspSessionService(mockLspRepository);
      rootUri = DocumentUri.fromFilePath('/project');

      registerFallbackValue(SessionId.generate());
      registerFallbackValue(LanguageId.dart);
      registerFallbackValue(rootUri);
    });

    group('getOrCreateSession', () {
      test('should create new session when none exists', () async {
        // Arrange
        final session = LspSession(
          id: SessionId.generate(),
          languageId: LanguageId.dart,
          state: SessionState.ready,
          createdAt: DateTime.now(),
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => left(const LspFailure.sessionNotFound()));

        when(() => mockLspRepository.initialize(
              languageId: any(named: 'languageId'),
              rootUri: any(named: 'rootUri'),
            )).thenAnswer((_) async => right(session));

        // Act
        final result = await service.getOrCreateSession(
          languageId: LanguageId.dart,
          rootUri: rootUri,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (resultSession) => expect(resultSession.id, equals(session.id)),
        );

        verify(() => mockLspRepository.initialize(
              languageId: LanguageId.dart,
              rootUri: rootUri,
            )).called(1);
      });

      test('should return existing active session', () async {
        // Arrange
        final session = LspSession(
          id: SessionId.generate(),
          languageId: LanguageId.dart,
          state: SessionState.ready,
          createdAt: DateTime.now(),
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        // Act
        final result = await service.getOrCreateSession(
          languageId: LanguageId.dart,
          rootUri: rootUri,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (resultSession) => expect(resultSession.id, equals(session.id)),
        );

        verifyNever(() => mockLspRepository.initialize(
              languageId: any(named: 'languageId'),
              rootUri: any(named: 'rootUri'),
            ));
      });

      test('should return cached session on second call', () async {
        // Arrange
        final session = LspSession(
          id: SessionId.generate(),
          languageId: LanguageId.dart,
          state: SessionState.ready,
          createdAt: DateTime.now(),
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => left(const LspFailure.sessionNotFound()));

        when(() => mockLspRepository.initialize(
              languageId: any(named: 'languageId'),
              rootUri: any(named: 'rootUri'),
            )).thenAnswer((_) async => right(session));

        // Act
        await service.getOrCreateSession(languageId: LanguageId.dart, rootUri: rootUri);
        final result = await service.getOrCreateSession(languageId: LanguageId.dart, rootUri: rootUri);

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockLspRepository.initialize(
              languageId: LanguageId.dart,
              rootUri: rootUri,
            )).called(1);
      });

      test('should create new session when cached session is inactive', () async {
        // Arrange
        final inactiveSession = LspSession(
          id: SessionId.generate(),
          languageId: LanguageId.dart,
          state: SessionState.stopped,
          createdAt: DateTime.now(),
        );

        final newSession = LspSession(
          id: SessionId.generate(),
          languageId: LanguageId.dart,
          state: SessionState.ready,
          createdAt: DateTime.now(),
        );

        var callCount = 0;
        when(() => mockLspRepository.getSession(any())).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return right(inactiveSession);
          return left(const LspFailure.sessionNotFound());
        });

        when(() => mockLspRepository.initialize(
              languageId: any(named: 'languageId'),
              rootUri: any(named: 'rootUri'),
            )).thenAnswer((_) async => right(newSession));

        // Act - first call caches inactive session
        await service.getOrCreateSession(languageId: LanguageId.dart, rootUri: rootUri);

        // Second call should create new session
        final result = await service.getOrCreateSession(languageId: LanguageId.dart, rootUri: rootUri);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (resultSession) => expect(resultSession.id, equals(newSession.id)),
        );

        verify(() => mockLspRepository.initialize(
              languageId: LanguageId.dart,
              rootUri: rootUri,
            )).called(1);
      });

      test('should fail when initialization fails', () async {
        // Arrange
        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => left(const LspFailure.sessionNotFound()));

        when(() => mockLspRepository.initialize(
              languageId: any(named: 'languageId'),
              rootUri: any(named: 'rootUri'),
            )).thenAnswer((_) async => left(const LspFailure.serverError(
              message: 'Failed to start server',
            )));

        // Act
        final result = await service.getOrCreateSession(
          languageId: LanguageId.dart,
          rootUri: rootUri,
        );

        // Assert
        expect(result.isLeft(), isTrue);
      });
    });

    group('getSession', () {
      test('should get existing session', () async {
        // Arrange
        final session = LspSession(
          id: SessionId.generate(),
          languageId: LanguageId.dart,
          state: SessionState.ready,
          createdAt: DateTime.now(),
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        // Act
        final result = await service.getSession(languageId: LanguageId.dart);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (resultSession) => expect(resultSession.id, equals(session.id)),
        );
      });

      test('should fail when session not found', () async {
        // Arrange
        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => left(const LspFailure.sessionNotFound()));

        // Act
        final result = await service.getSession(languageId: LanguageId.dart);

        // Assert
        expect(result.isLeft(), isTrue);
      });

      test('should remove inactive session from cache', () async {
        // Arrange
        final inactiveSession = LspSession(
          id: SessionId.generate(),
          languageId: LanguageId.dart,
          state: SessionState.stopped,
          createdAt: DateTime.now(),
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(inactiveSession));

        // First call caches the inactive session
        await service.getSession(languageId: LanguageId.dart);

        // Act - second call should not use cache
        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => left(const LspFailure.sessionNotFound()));

        final result = await service.getSession(languageId: LanguageId.dart);

        // Assert
        expect(result.isLeft(), isTrue);
      });

      test('should cache active session', () async {
        // Arrange
        final session = LspSession(
          id: SessionId.generate(),
          languageId: LanguageId.dart,
          state: SessionState.ready,
          createdAt: DateTime.now(),
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        // Act
        await service.getSession(languageId: LanguageId.dart);
        await service.getSession(languageId: LanguageId.dart);

        // Assert - should only call repository once
        verify(() => mockLspRepository.getSession(LanguageId.dart)).called(1);
      });
    });

    group('hasSession', () {
      test('should return true when session exists', () async {
        // Arrange
        final session = LspSession(
          id: SessionId.generate(),
          languageId: LanguageId.dart,
          state: SessionState.ready,
          createdAt: DateTime.now(),
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        // Act
        final result = await service.hasSession(languageId: LanguageId.dart);

        // Assert
        expect(result, isTrue);
      });

      test('should return false when session not found', () async {
        // Arrange
        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => left(const LspFailure.sessionNotFound()));

        // Act
        final result = await service.hasSession(languageId: LanguageId.dart);

        // Assert
        expect(result, isFalse);
      });
    });

    group('shutdownSession', () {
      test('should shutdown session successfully', () async {
        // Arrange
        final session = LspSession(
          id: SessionId.generate(),
          languageId: LanguageId.dart,
          state: SessionState.ready,
          createdAt: DateTime.now(),
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.shutdown(any()))
            .thenAnswer((_) async => right(unit));

        // Act
        final result = await service.shutdownSession(languageId: LanguageId.dart);

        // Assert
        expect(result.isRight(), isTrue);
        verify(() => mockLspRepository.shutdown(session.id)).called(1);
      });

      test('should remove session from cache after shutdown', () async {
        // Arrange
        final session = LspSession(
          id: SessionId.generate(),
          languageId: LanguageId.dart,
          state: SessionState.ready,
          createdAt: DateTime.now(),
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.shutdown(any()))
            .thenAnswer((_) async => right(unit));

        // Act
        await service.shutdownSession(languageId: LanguageId.dart);

        // Assert
        expect(service.getActiveSessionCount(), equals(0));
      });

      test('should fail when session not found', () async {
        // Arrange
        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => left(const LspFailure.sessionNotFound()));

        // Act
        final result = await service.shutdownSession(languageId: LanguageId.dart);

        // Assert
        expect(result.isLeft(), isTrue);
      });
    });

    group('shutdownAllSessions', () {
      test('should shutdown all active sessions', () async {
        // Arrange
        final session1 = LspSession(
          id: SessionId.generate(),
          languageId: LanguageId.dart,
          state: SessionState.ready,
          createdAt: DateTime.now(),
        );

        final session2 = LspSession(
          id: SessionId.generate(),
          languageId: LanguageId.typescript,
          state: SessionState.ready,
          createdAt: DateTime.now(),
        );

        when(() => mockLspRepository.getSession(LanguageId.dart))
            .thenAnswer((_) async => left(const LspFailure.sessionNotFound()));

        when(() => mockLspRepository.getSession(LanguageId.typescript))
            .thenAnswer((_) async => left(const LspFailure.sessionNotFound()));

        when(() => mockLspRepository.initialize(
              languageId: LanguageId.dart,
              rootUri: any(named: 'rootUri'),
            )).thenAnswer((_) async => right(session1));

        when(() => mockLspRepository.initialize(
              languageId: LanguageId.typescript,
              rootUri: any(named: 'rootUri'),
            )).thenAnswer((_) async => right(session2));

        when(() => mockLspRepository.shutdown(any()))
            .thenAnswer((_) async => right(unit));

        await service.getOrCreateSession(languageId: LanguageId.dart, rootUri: rootUri);
        await service.getOrCreateSession(languageId: LanguageId.typescript, rootUri: rootUri);

        // Act
        final count = await service.shutdownAllSessions();

        // Assert
        expect(count, equals(2));
        verify(() => mockLspRepository.shutdown(session1.id)).called(1);
        verify(() => mockLspRepository.shutdown(session2.id)).called(1);
        expect(service.getActiveSessionCount(), equals(0));
      });

      test('should continue shutting down even if one fails', () async {
        // Arrange
        final session1 = LspSession(
          id: SessionId.generate(),
          languageId: LanguageId.dart,
          state: SessionState.ready,
          createdAt: DateTime.now(),
        );

        final session2 = LspSession(
          id: SessionId.generate(),
          languageId: LanguageId.typescript,
          state: SessionState.ready,
          createdAt: DateTime.now(),
        );

        when(() => mockLspRepository.getSession(LanguageId.dart))
            .thenAnswer((_) async => left(const LspFailure.sessionNotFound()));

        when(() => mockLspRepository.getSession(LanguageId.typescript))
            .thenAnswer((_) async => left(const LspFailure.sessionNotFound()));

        when(() => mockLspRepository.initialize(
              languageId: LanguageId.dart,
              rootUri: any(named: 'rootUri'),
            )).thenAnswer((_) async => right(session1));

        when(() => mockLspRepository.initialize(
              languageId: LanguageId.typescript,
              rootUri: any(named: 'rootUri'),
            )).thenAnswer((_) async => right(session2));

        var shutdownCallCount = 0;
        when(() => mockLspRepository.shutdown(any())).thenAnswer((_) async {
          shutdownCallCount++;
          if (shutdownCallCount == 1) {
            return left(const LspFailure.serverError(message: 'Failed'));
          }
          return right(unit);
        });

        await service.getOrCreateSession(languageId: LanguageId.dart, rootUri: rootUri);
        await service.getOrCreateSession(languageId: LanguageId.typescript, rootUri: rootUri);

        // Act
        final count = await service.shutdownAllSessions();

        // Assert
        expect(count, equals(1));
        verify(() => mockLspRepository.shutdown(any())).called(2);
      });
    });

    group('getActiveSessions', () {
      test('should return all active sessions', () async {
        // Arrange
        final session1 = LspSession(
          id: SessionId.generate(),
          languageId: LanguageId.dart,
          state: SessionState.ready,
          createdAt: DateTime.now(),
        );

        final session2 = LspSession(
          id: SessionId.generate(),
          languageId: LanguageId.typescript,
          state: SessionState.ready,
          createdAt: DateTime.now(),
        );

        when(() => mockLspRepository.getSession(LanguageId.dart))
            .thenAnswer((_) async => left(const LspFailure.sessionNotFound()));

        when(() => mockLspRepository.getSession(LanguageId.typescript))
            .thenAnswer((_) async => left(const LspFailure.sessionNotFound()));

        when(() => mockLspRepository.initialize(
              languageId: LanguageId.dart,
              rootUri: any(named: 'rootUri'),
            )).thenAnswer((_) async => right(session1));

        when(() => mockLspRepository.initialize(
              languageId: LanguageId.typescript,
              rootUri: any(named: 'rootUri'),
            )).thenAnswer((_) async => right(session2));

        await service.getOrCreateSession(languageId: LanguageId.dart, rootUri: rootUri);
        await service.getOrCreateSession(languageId: LanguageId.typescript, rootUri: rootUri);

        // Act
        final sessions = service.getActiveSessions();

        // Assert
        expect(sessions.length, equals(2));
      });

      test('should filter out inactive sessions', () async {
        // Arrange
        final inactiveSession = LspSession(
          id: SessionId.generate(),
          languageId: LanguageId.dart,
          state: SessionState.stopped,
          createdAt: DateTime.now(),
        );

        when(() => mockLspRepository.getSession(LanguageId.dart))
            .thenAnswer((_) async => right(inactiveSession));

        await service.getOrCreateSession(languageId: LanguageId.dart, rootUri: rootUri);

        // Act
        final sessions = service.getActiveSessions();

        // Assert
        expect(sessions, isEmpty);
        expect(service.getActiveSessionCount(), equals(0));
      });
    });

    group('clearCache', () {
      test('should clear session cache', () async {
        // Arrange
        final session = LspSession(
          id: SessionId.generate(),
          languageId: LanguageId.dart,
          state: SessionState.ready,
          createdAt: DateTime.now(),
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => left(const LspFailure.sessionNotFound()));

        when(() => mockLspRepository.initialize(
              languageId: any(named: 'languageId'),
              rootUri: any(named: 'rootUri'),
            )).thenAnswer((_) async => right(session));

        await service.getOrCreateSession(languageId: LanguageId.dart, rootUri: rootUri);

        // Act
        service.clearCache();

        // Assert
        expect(service.getActiveSessionCount(), equals(0));
      });
    });
  });
}
