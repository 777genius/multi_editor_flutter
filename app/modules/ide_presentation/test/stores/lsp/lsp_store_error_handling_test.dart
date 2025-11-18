import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mobx/mobx.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:lsp_application/lsp_application.dart';
import 'package:ide_presentation/ide_presentation.dart';

// Mock use cases
class MockInitializeLspSessionUseCase extends Mock implements InitializeLspSessionUseCase {}
class MockShutdownLspSessionUseCase extends Mock implements ShutdownLspSessionUseCase {}
class MockGetCompletionsUseCase extends Mock implements GetCompletionsUseCase {}
class MockGetHoverInfoUseCase extends Mock implements GetHoverInfoUseCase {}
class MockGetDiagnosticsUseCase extends Mock implements GetDiagnosticsUseCase {}
class MockGoToDefinitionUseCase extends Mock implements GoToDefinitionUseCase {}
class MockFindReferencesUseCase extends Mock implements FindReferencesUseCase {}

void main() {
  late LspStore store;
  late MockInitializeLspSessionUseCase mockInitializeUseCase;
  late MockShutdownLspSessionUseCase mockShutdownUseCase;
  late MockGetCompletionsUseCase mockGetCompletionsUseCase;
  late MockGetHoverInfoUseCase mockGetHoverInfoUseCase;
  late MockGetDiagnosticsUseCase mockGetDiagnosticsUseCase;
  late MockGoToDefinitionUseCase mockGoToDefinitionUseCase;
  late MockFindReferencesUseCase mockFindReferencesUseCase;

  setUp(() {
    mockInitializeUseCase = MockInitializeLspSessionUseCase();
    mockShutdownUseCase = MockShutdownLspSessionUseCase();
    mockGetCompletionsUseCase = MockGetCompletionsUseCase();
    mockGetHoverInfoUseCase = MockGetHoverInfoUseCase();
    mockGetDiagnosticsUseCase = MockGetDiagnosticsUseCase();
    mockGoToDefinitionUseCase = MockGoToDefinitionUseCase();
    mockFindReferencesUseCase = MockFindReferencesUseCase();

    store = LspStore(
      initializeSessionUseCase: mockInitializeUseCase,
      shutdownSessionUseCase: mockShutdownUseCase,
      getCompletionsUseCase: mockGetCompletionsUseCase,
      getHoverInfoUseCase: mockGetHoverInfoUseCase,
      getDiagnosticsUseCase: mockGetDiagnosticsUseCase,
      goToDefinitionUseCase: mockGoToDefinitionUseCase,
      findReferencesUseCase: mockFindReferencesUseCase,
    );
  });

  group('LspStore - Error Handling', () {
    group('Error State', () {
      test('should set error message when operation fails', () {
        // Arrange
        expect(store.errorMessage, isNull);

        // Act
        runInAction(() {
          store.errorMessage = 'Connection failed';
          store.errorFailure = const LspFailure.connectionFailed(
            reason: 'Connection failed',
          );
        });

        // Assert
        expect(store.errorMessage, equals('Connection failed'));
        expect(store.errorFailure, isNotNull);
      });

      test('should indicate hasError when errorMessage is set', () {
        // Arrange
        expect(store.hasError, isFalse);

        // Act
        runInAction(() {
          store.errorMessage = 'Test error';
        });

        // Assert
        expect(store.hasError, isTrue);
      });

      test('should affect isReady when error is set', () {
        // Arrange
        runInAction(() {
          store.session = LspSession(
            id: SessionId.fromString('test-session'),
            languageId: LanguageId.dart,
            state: SessionState.initialized,
            rootUri: DocumentUri.fromFilePath('/test'),
            createdAt: DateTime.now(),
            initializedAt: DateTime.now(),
          );
        });
        expect(store.isReady, isTrue);

        // Act
        runInAction(() {
          store.errorMessage = 'Test error';
        });

        // Assert
        expect(store.isReady, isFalse);
      });
    });

    group('Error Types', () {
      test('should handle connection failed error', () {
        // Act
        runInAction(() {
          store.errorMessage = 'Connection failed';
          store.errorFailure = const LspFailure.connectionFailed(
            reason: 'Failed to connect to LSP server',
          );
        });

        // Assert
        expect(store.hasError, isTrue);
        expect(store.errorFailure, isA<LspFailure>());
      });

      test('should handle initialization failed error', () {
        // Act
        runInAction(() {
          store.errorMessage = 'Failed to initialize';
          store.errorFailure = const LspFailure.initializationFailed(
            reason: 'Invalid configuration',
          );
        });

        // Assert
        expect(store.hasError, isTrue);
        expect(store.errorFailure, isA<LspFailure>());
      });

      test('should handle session not found error', () {
        // Act
        runInAction(() {
          store.errorMessage = 'Session not found';
          store.errorFailure = const LspFailure.sessionNotFound(
            message: 'No session for this language',
          );
        });

        // Assert
        expect(store.hasError, isTrue);
      });

      test('should handle request failed error', () {
        // Act
        runInAction(() {
          store.errorMessage = 'Request failed';
          store.errorFailure = const LspFailure.requestFailed(
            method: 'textDocument/completion',
            reason: 'Timeout',
          );
        });

        // Assert
        expect(store.hasError, isTrue);
      });

      test('should handle server not responding error', () {
        // Act
        runInAction(() {
          store.errorMessage = 'Server not responding';
          store.errorFailure = const LspFailure.serverNotResponding(
            message: 'LSP server is not responding',
          );
        });

        // Assert
        expect(store.hasError, isTrue);
      });

      test('should handle unexpected error', () {
        // Act
        runInAction(() {
          store.errorMessage = 'Unexpected error';
          store.errorFailure = const LspFailure.unexpected(
            message: 'An unexpected error occurred',
          );
        });

        // Assert
        expect(store.hasError, isTrue);
      });
    });

    group('Error Recovery', () {
      test('should clear error state', () {
        // Arrange
        runInAction(() {
          store.errorMessage = 'Test error';
          store.errorFailure = const LspFailure.connectionFailed(
            reason: 'Connection failed',
          );
        });
        expect(store.hasError, isTrue);

        // Act
        store.clearError();

        // Assert
        expect(store.hasError, isFalse);
        expect(store.errorMessage, isNull);
        expect(store.errorFailure, isNull);
      });

      test('should allow state recovery after error', () {
        // Arrange
        runInAction(() {
          store.errorMessage = 'Test error';
        });
        expect(store.isReady, isFalse);

        // Act
        runInAction(() {
          store.clearError();
          store.session = LspSession(
            id: SessionId.fromString('test-session'),
            languageId: LanguageId.dart,
            state: SessionState.initialized,
            rootUri: DocumentUri.fromFilePath('/test'),
            createdAt: DateTime.now(),
            initializedAt: DateTime.now(),
          );
        });

        // Assert
        expect(store.isReady, isTrue);
        expect(store.hasError, isFalse);
      });
    });

    group('Silent Failures', () {
      test('should silently fail completions without setting error', () {
        // Arrange
        runInAction(() {
          store.session = LspSession(
            id: SessionId.fromString('test-session'),
            languageId: LanguageId.dart,
            state: SessionState.initialized,
            rootUri: DocumentUri.fromFilePath('/test'),
            createdAt: DateTime.now(),
            initializedAt: DateTime.now(),
          );
          store.completions = CompletionList(items: [
            CompletionItem(label: 'test', kind: CompletionItemKind.method),
          ]);
        });

        // Act - simulate silent completion failure
        runInAction(() {
          store.completions = null;
          store.completionsPosition = null;
        });

        // Assert
        expect(store.completions, isNull);
        expect(store.hasError, isFalse); // Should not set global error
      });

      test('should silently fail hover without setting error', () {
        // Arrange
        runInAction(() {
          store.session = LspSession(
            id: SessionId.fromString('test-session'),
            languageId: LanguageId.dart,
            state: SessionState.initialized,
            rootUri: DocumentUri.fromFilePath('/test'),
            createdAt: DateTime.now(),
            initializedAt: DateTime.now(),
          );
          store.hoverInfo = HoverInfo(contents: [
            MarkupContent(kind: MarkupKind.plaintext, value: 'Test'),
          ]);
        });

        // Act - simulate silent hover failure
        runInAction(() {
          store.hoverInfo = null;
          store.hoverPosition = null;
        });

        // Assert
        expect(store.hoverInfo, isNull);
        expect(store.hasError, isFalse); // Should not set global error
      });
    });

    group('Status Text During Errors', () {
      test('should show "LSP Error" in statusText when hasError', () {
        // Arrange
        runInAction(() {
          store.errorMessage = 'Connection failed';
        });

        // Assert
        expect(store.statusText, equals('LSP Error'));
      });

      test('should prioritize error over other states in statusText', () {
        // Arrange
        runInAction(() {
          store.isInitializing = true;
          store.isLoading = true;
          store.currentOperation = 'Finding...';
          store.errorMessage = 'Test error';
        });

        // Assert - error should take priority
        expect(store.statusText, equals('LSP Error'));
      });

      test('should show normal status after clearing error', () {
        // Arrange
        runInAction(() {
          store.errorMessage = 'Test error';
          store.session = LspSession(
            id: SessionId.fromString('test-session'),
            languageId: LanguageId.dart,
            state: SessionState.initialized,
            rootUri: DocumentUri.fromFilePath('/test'),
            createdAt: DateTime.now(),
            initializedAt: DateTime.now(),
          );
        });
        expect(store.statusText, equals('LSP Error'));

        // Act
        store.clearError();

        // Assert
        expect(store.statusText, equals('LSP Ready'));
      });
    });

    group('Error State Isolation', () {
      test('should not affect completions state when error is set', () {
        // Arrange
        runInAction(() {
          store.completions = CompletionList(items: [
            CompletionItem(label: 'test', kind: CompletionItemKind.method),
          ]);
        });

        // Act
        runInAction(() {
          store.errorMessage = 'Test error';
        });

        // Assert
        expect(store.completions, isNotNull); // Should remain
      });

      test('should not affect diagnostics state when error is set', () {
        // Arrange
        runInAction(() {
          store.diagnostics = ObservableList<Diagnostic>.of([
            Diagnostic(
              range: TextSelection(
                start: const CursorPosition(line: 0, column: 0),
                end: const CursorPosition(line: 0, column: 10),
              ),
              severity: DiagnosticSeverity.error,
              message: 'Test diagnostic',
            ),
          ]);
        });

        // Act
        runInAction(() {
          store.errorMessage = 'LSP error';
        });

        // Assert
        expect(store.diagnostics, isNotNull); // Should remain
      });

      test('should preserve session when error is set', () {
        // Arrange
        final session = LspSession(
          id: SessionId.fromString('test-session'),
          languageId: LanguageId.dart,
          state: SessionState.initialized,
          rootUri: DocumentUri.fromFilePath('/test'),
          createdAt: DateTime.now(),
          initializedAt: DateTime.now(),
        );
        runInAction(() {
          store.session = session;
        });

        // Act
        runInAction(() {
          store.errorMessage = 'Test error';
        });

        // Assert
        expect(store.session, equals(session)); // Should remain
      });
    });
  });
}
