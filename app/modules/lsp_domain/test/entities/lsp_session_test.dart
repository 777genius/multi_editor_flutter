import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';

void main() {
  group('LspSession', () {
    late SessionId sessionId;
    late LanguageId languageId;
    late DocumentUri rootUri;

    setUp(() {
      sessionId = SessionId.generate();
      languageId = const LanguageId('dart');
      rootUri = const DocumentUri('file:///project');
    });

    group('creation', () {
      test('should create session with valid data', () {
        // Arrange & Act
        final session = LspSession(
          id: sessionId,
          languageId: languageId,
          state: SessionState.created,
          rootUri: rootUri,
          createdAt: DateTime.now(),
        );

        // Assert
        expect(session.id, equals(sessionId));
        expect(session.languageId, equals(languageId));
        expect(session.state, equals(SessionState.created));
        expect(session.rootUri, equals(rootUri));
        expect(session.initializedAt, isNull);
      });

      test('should create session using factory method', () {
        // Act
        final session = LspSession.create(
          languageId: languageId,
          rootUri: rootUri,
        );

        // Assert
        expect(session.languageId, equals(languageId));
        expect(session.rootUri, equals(rootUri));
        expect(session.state, equals(SessionState.created));
        expect(session.id, isNotNull);
        expect(session.createdAt, isNotNull);
      });

      test('should be in created state by default', () {
        final session = LspSession.create(
          languageId: languageId,
          rootUri: rootUri,
        );

        expect(session.state, equals(SessionState.created));
      });
    });

    group('state transitions', () {
      late LspSession session;

      setUp(() {
        session = LspSession.create(
          languageId: languageId,
          rootUri: rootUri,
        );
      });

      test('should transition from created to initializing', () {
        // Act
        final updatedSession = session.markInitializing();

        // Assert
        expect(updatedSession.state, equals(SessionState.initializing));
        expect(session.state, equals(SessionState.created)); // immutability
      });

      test('should transition to initialized with timestamp', () {
        // Arrange
        final initializingSession = session.markInitializing();

        // Act
        final initializedSession = initializingSession.markInitialized();

        // Assert
        expect(initializedSession.state, equals(SessionState.initialized));
        expect(initializedSession.initializedAt, isNotNull);
      });

      test('should transition to failed', () {
        // Act
        final failedSession = session.markFailed();

        // Assert
        expect(failedSession.state, equals(SessionState.failed));
      });

      test('should transition to shutdown', () {
        // Act
        final shutdownSession = session.markShutdown();

        // Assert
        expect(shutdownSession.state, equals(SessionState.shutdown));
      });

      test('should maintain immutability on transitions', () {
        final initialState = session.state;
        session.markInitializing();

        expect(session.state, equals(initialState));
      });
    });

    group('canHandleRequests', () {
      test('should return true when initialized', () {
        final session = LspSession.create(
          languageId: languageId,
          rootUri: rootUri,
        ).markInitializing().markInitialized();

        expect(session.canHandleRequests, isTrue);
      });

      test('should return false when created', () {
        final session = LspSession.create(
          languageId: languageId,
          rootUri: rootUri,
        );

        expect(session.canHandleRequests, isFalse);
      });

      test('should return false when initializing', () {
        final session = LspSession.create(
          languageId: languageId,
          rootUri: rootUri,
        ).markInitializing();

        expect(session.canHandleRequests, isFalse);
      });

      test('should return false when failed', () {
        final session = LspSession.create(
          languageId: languageId,
          rootUri: rootUri,
        ).markFailed();

        expect(session.canHandleRequests, isFalse);
      });

      test('should return false when shutdown', () {
        final session = LspSession.create(
          languageId: languageId,
          rootUri: rootUri,
        ).markShutdown();

        expect(session.canHandleRequests, isFalse);
      });
    });

    group('isActive', () {
      test('should return true when initialized', () {
        final session = LspSession.create(
          languageId: languageId,
          rootUri: rootUri,
        ).markInitializing().markInitialized();

        expect(session.isActive, isTrue);
      });

      test('should return true when initializing', () {
        final session = LspSession.create(
          languageId: languageId,
          rootUri: rootUri,
        ).markInitializing();

        expect(session.isActive, isTrue);
      });

      test('should return false when created', () {
        final session = LspSession.create(
          languageId: languageId,
          rootUri: rootUri,
        );

        expect(session.isActive, isFalse);
      });

      test('should return false when failed', () {
        final session = LspSession.create(
          languageId: languageId,
          rootUri: rootUri,
        ).markFailed();

        expect(session.isActive, isFalse);
      });

      test('should return false when shutdown', () {
        final session = LspSession.create(
          languageId: languageId,
          rootUri: rootUri,
        ).markShutdown();

        expect(session.isActive, isFalse);
      });
    });

    group('equality', () {
      test('should be equal with same data', () {
        final createdAt = DateTime.now();
        final session1 = LspSession(
          id: sessionId,
          languageId: languageId,
          state: SessionState.initialized,
          rootUri: rootUri,
          createdAt: createdAt,
        );

        final session2 = LspSession(
          id: sessionId,
          languageId: languageId,
          state: SessionState.initialized,
          rootUri: rootUri,
          createdAt: createdAt,
        );

        expect(session1, equals(session2));
        expect(session1.hashCode, equals(session2.hashCode));
      });

      test('should not be equal with different session ID', () {
        final session1 = LspSession.create(
          languageId: languageId,
          rootUri: rootUri,
        );

        final session2 = LspSession.create(
          languageId: languageId,
          rootUri: rootUri,
        );

        expect(session1, isNot(equals(session2)));
      });

      test('should not be equal with different state', () {
        final createdAt = DateTime.now();
        final session1 = LspSession(
          id: sessionId,
          languageId: languageId,
          state: SessionState.created,
          rootUri: rootUri,
          createdAt: createdAt,
        );

        final session2 = LspSession(
          id: sessionId,
          languageId: languageId,
          state: SessionState.initialized,
          rootUri: rootUri,
          createdAt: createdAt,
        );

        expect(session1, isNot(equals(session2)));
      });
    });

    group('copyWith', () {
      test('should copy with new state', () {
        final session = LspSession.create(
          languageId: languageId,
          rootUri: rootUri,
        );

        final copied = session.copyWith(state: SessionState.initialized);

        expect(copied.state, equals(SessionState.initialized));
        expect(copied.id, equals(session.id));
        expect(copied.languageId, equals(session.languageId));
      });

      test('should copy with new timestamp', () {
        final session = LspSession.create(
          languageId: languageId,
          rootUri: rootUri,
        );

        final now = DateTime.now();
        final copied = session.copyWith(initializedAt: now);

        expect(copied.initializedAt, equals(now));
        expect(copied.id, equals(session.id));
      });
    });
  });
}
