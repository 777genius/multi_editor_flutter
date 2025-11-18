import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_infrastructure/lsp_infrastructure.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';

void main() {
  group('WebSocketLspClientRepository', () {
    late WebSocketLspClientRepository repository;

    setUp(() {
      repository = WebSocketLspClientRepository(
        bridgeUrl: 'ws://localhost:9999',
        connectionTimeout: const Duration(seconds: 5),
        requestTimeout: const Duration(seconds: 10),
      );
    });

    tearDown(() async {
      await repository.dispose();
    });

    group('initialization', () {
      test('should initialize with disconnected state', () {
        // Assert
        expect(repository.isConnected, isFalse);
      });

      test('should initialize with custom bridge URL', () {
        // Arrange & Act
        final customRepository = WebSocketLspClientRepository(
          bridgeUrl: 'ws://custom-host:8888',
        );

        // Assert
        expect(customRepository.isConnected, isFalse);

        customRepository.dispose();
      });

      test('should initialize with custom timeouts', () {
        // Arrange & Act
        final customRepository = WebSocketLspClientRepository(
          bridgeUrl: 'ws://localhost:9999',
          connectionTimeout: const Duration(seconds: 3),
          requestTimeout: const Duration(seconds: 15),
        );

        // Assert
        expect(customRepository.isConnected, isFalse);

        customRepository.dispose();
      });
    });

    group('connection state', () {
      test('should report disconnected state before connection attempt', () {
        // Assert
        expect(repository.isConnected, isFalse);
      });

      test('should emit status events', () async {
        // Arrange
        final statusEvents = <LspServerStatus>[];
        final subscription = repository.onStatusChanged.listen((status) {
          statusEvents.add(status);
        });

        // Act
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(statusEvents, isEmpty); // No events before connection

        await subscription.cancel();
      });

      test('should emit diagnostic events', () async {
        // Arrange
        final diagnosticEvents = <DiagnosticUpdate>[];
        final subscription = repository.onDiagnostics.listen((update) {
          diagnosticEvents.add(update);
        });

        // Act
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(diagnosticEvents, isEmpty); // No events before connection

        await subscription.cancel();
      });
    });

    group('session management (without connection)', () {
      test('should return error when getting session without connection', () async {
        // Act
        final result = await repository.getSession(LanguageId.dart);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<LspFailure>()),
          (_) => fail('Should not succeed'),
        );
      });

      test('should return false when checking session without connection', () async {
        // Act
        final hasSession = await repository.hasSession(LanguageId.dart);

        // Assert
        expect(hasSession, isFalse);
      });

      test('should return error when initializing without connection', () async {
        // Act
        final result = await repository.initialize(
          languageId: LanguageId.dart,
          rootUri: DocumentUri.fromFilePath('/test/project'),
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(
            failure.maybeWhen(
              connectionFailed: (_) => true,
              orElse: () => false,
            ),
            isTrue,
          ),
          (_) => fail('Should not succeed'),
        );
      });

      test('should return error when shutting down without connection', () async {
        // Arrange
        final sessionId = SessionId.fromString('test-session-123');

        // Act
        final result = await repository.shutdown(sessionId);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(
            failure.maybeWhen(
              connectionFailed: (_) => true,
              orElse: () => false,
            ),
            isTrue,
          ),
          (_) => fail('Should not succeed'),
        );
      });
    });

    group('language features (without connection)', () {
      test('should return error when getting completions without connection', () async {
        // Arrange
        final sessionId = SessionId.fromString('test-session');
        final documentUri = DocumentUri.fromFilePath('/test/file.dart');
        const position = CursorPosition(line: 10, column: 5);

        // Act
        final result = await repository.getCompletions(
          sessionId: sessionId,
          documentUri: documentUri,
          position: position,
        );

        // Assert
        expect(result.isLeft(), isTrue);
      });

      test('should return error when getting hover info without connection', () async {
        // Arrange
        final sessionId = SessionId.fromString('test-session');
        final documentUri = DocumentUri.fromFilePath('/test/file.dart');
        const position = CursorPosition(line: 5, column: 10);

        // Act
        final result = await repository.getHoverInfo(
          sessionId: sessionId,
          documentUri: documentUri,
          position: position,
        );

        // Assert
        expect(result.isLeft(), isTrue);
      });

      test('should return error when getting diagnostics without connection', () async {
        // Arrange
        final sessionId = SessionId.fromString('test-session');
        final documentUri = DocumentUri.fromFilePath('/test/file.dart');

        // Act
        final result = await repository.getDiagnostics(
          sessionId: sessionId,
          documentUri: documentUri,
        );

        // Assert
        expect(result.isLeft(), isTrue);
      });

      test('should return error when getting definition without connection', () async {
        // Arrange
        final sessionId = SessionId.fromString('test-session');
        final documentUri = DocumentUri.fromFilePath('/test/file.dart');
        const position = CursorPosition(line: 20, column: 15);

        // Act
        final result = await repository.getDefinition(
          sessionId: sessionId,
          documentUri: documentUri,
          position: position,
        );

        // Assert
        expect(result.isLeft(), isTrue);
      });

      test('should return error when getting references without connection', () async {
        // Arrange
        final sessionId = SessionId.fromString('test-session');
        final documentUri = DocumentUri.fromFilePath('/test/file.dart');
        const position = CursorPosition(line: 15, column: 8);

        // Act
        final result = await repository.getReferences(
          sessionId: sessionId,
          documentUri: documentUri,
          position: position,
        );

        // Assert
        expect(result.isLeft(), isTrue);
      });
    });

    group('text document synchronization (without connection)', () {
      test('should return error when notifying document opened without connection', () async {
        // Arrange
        final sessionId = SessionId.fromString('test-session');
        final documentUri = DocumentUri.fromFilePath('/test/file.dart');
        const content = 'void main() {}';

        // Act
        final result = await repository.notifyDocumentOpened(
          sessionId: sessionId,
          documentUri: documentUri,
          languageId: LanguageId.dart,
          content: content,
        );

        // Assert
        expect(result.isLeft(), isTrue);
      });

      test('should return error when notifying document changed without connection', () async {
        // Arrange
        final sessionId = SessionId.fromString('test-session');
        final documentUri = DocumentUri.fromFilePath('/test/file.dart');
        const content = 'void main() { print("hello"); }';

        // Act
        final result = await repository.notifyDocumentChanged(
          sessionId: sessionId,
          documentUri: documentUri,
          content: content,
        );

        // Assert
        expect(result.isLeft(), isTrue);
      });

      test('should return error when notifying document closed without connection', () async {
        // Arrange
        final sessionId = SessionId.fromString('test-session');
        final documentUri = DocumentUri.fromFilePath('/test/file.dart');

        // Act
        final result = await repository.notifyDocumentClosed(
          sessionId: sessionId,
          documentUri: documentUri,
        );

        // Assert
        expect(result.isLeft(), isTrue);
      });

      test('should return error when notifying document saved without connection', () async {
        // Arrange
        final sessionId = SessionId.fromString('test-session');
        final documentUri = DocumentUri.fromFilePath('/test/file.dart');

        // Act
        final result = await repository.notifyDocumentSaved(
          sessionId: sessionId,
          documentUri: documentUri,
        );

        // Assert
        expect(result.isLeft(), isTrue);
      });
    });

    group('additional language features (without connection)', () {
      test('should return error when getting code actions without connection', () async {
        // Arrange
        final sessionId = SessionId.fromString('test-session');
        final documentUri = DocumentUri.fromFilePath('/test/file.dart');
        final range = TextSelection(
          start: const CursorPosition(line: 5, column: 0),
          end: const CursorPosition(line: 5, column: 10),
        );

        // Act
        final result = await repository.getCodeActions(
          sessionId: sessionId,
          documentUri: documentUri,
          range: range,
          diagnostics: [],
        );

        // Assert
        expect(result.isLeft(), isTrue);
      });

      test('should return error when getting document symbols without connection', () async {
        // Arrange
        final sessionId = SessionId.fromString('test-session');
        final documentUri = DocumentUri.fromFilePath('/test/file.dart');

        // Act
        final result = await repository.getDocumentSymbols(
          sessionId: sessionId,
          documentUri: documentUri,
        );

        // Assert
        expect(result.isLeft(), isTrue);
      });

      test('should return error when formatting document without connection', () async {
        // Arrange
        final sessionId = SessionId.fromString('test-session');
        final documentUri = DocumentUri.fromFilePath('/test/file.dart');
        const options = FormattingOptions(
          tabSize: 2,
          insertSpaces: true,
        );

        // Act
        final result = await repository.formatDocument(
          sessionId: sessionId,
          documentUri: documentUri,
          options: options,
        );

        // Assert
        expect(result.isLeft(), isTrue);
      });

      test('should return error when renaming symbol without connection', () async {
        // Arrange
        final sessionId = SessionId.fromString('test-session');
        final documentUri = DocumentUri.fromFilePath('/test/file.dart');
        const position = CursorPosition(line: 10, column: 5);

        // Act
        final result = await repository.rename(
          sessionId: sessionId,
          documentUri: documentUri,
          position: position,
          newName: 'newSymbolName',
        );

        // Assert
        expect(result.isLeft(), isTrue);
      });
    });

    group('dispose', () {
      test('should disconnect and clean up resources', () async {
        // Act
        await repository.dispose();

        // Assert
        expect(repository.isConnected, isFalse);
      });

      test('should be safe to call dispose multiple times', () async {
        // Act & Assert
        await repository.dispose();
        await repository.dispose(); // Should not throw
      });

      test('should cancel pending subscriptions on dispose', () async {
        // Arrange
        final statusEvents = <LspServerStatus>[];
        final subscription = repository.onStatusChanged.listen((status) {
          statusEvents.add(status);
        });

        // Act
        await repository.dispose();
        await subscription.cancel();

        // Assert - no crash
        expect(true, isTrue);
      });
    });

    group('edge cases', () {
      test('should handle multiple hasSession checks for different languages', () async {
        // Act
        final hasDart = await repository.hasSession(LanguageId.dart);
        final hasJs = await repository.hasSession(LanguageId.javascript);
        final hasTs = await repository.hasSession(LanguageId.typescript);

        // Assert
        expect(hasDart, isFalse);
        expect(hasJs, isFalse);
        expect(hasTs, isFalse);
      });

      test('should handle concurrent operation attempts without connection', () async {
        // Arrange
        final sessionId = SessionId.fromString('test-session');
        final documentUri = DocumentUri.fromFilePath('/test/file.dart');
        const position = CursorPosition(line: 0, column: 0);

        // Act - fire multiple operations concurrently
        final futures = await Future.wait([
          repository.getCompletions(
            sessionId: sessionId,
            documentUri: documentUri,
            position: position,
          ),
          repository.getHoverInfo(
            sessionId: sessionId,
            documentUri: documentUri,
            position: position,
          ),
          repository.getDiagnostics(
            sessionId: sessionId,
            documentUri: documentUri,
          ),
        ]);

        // Assert - all should fail gracefully
        expect(futures.every((result) => result.isLeft()), isTrue);
      });
    });
  });
}
