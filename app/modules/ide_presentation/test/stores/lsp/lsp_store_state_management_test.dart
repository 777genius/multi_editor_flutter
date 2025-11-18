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

  group('LspStore - State Management', () {
    group('Initial State', () {
      test('should have null session initially', () {
        // Assert
        expect(store.session, isNull);
      });

      test('should have null languageId initially', () {
        // Assert
        expect(store.languageId, isNull);
      });

      test('should have null completions initially', () {
        // Assert
        expect(store.completions, isNull);
        expect(store.completionsPosition, isNull);
      });

      test('should have null hoverInfo initially', () {
        // Assert
        expect(store.hoverInfo, isNull);
        expect(store.hoverPosition, isNull);
      });

      test('should have null diagnostics initially', () {
        // Assert
        expect(store.diagnostics, isNull);
        expect(store.diagnosticsDocumentUri, isNull);
      });

      test('should have null definition locations initially', () {
        // Assert
        expect(store.definitionLocations, isNull);
      });

      test('should have null reference locations initially', () {
        // Assert
        expect(store.referenceLocations, isNull);
      });

      test('should not be initializing initially', () {
        // Assert
        expect(store.isInitializing, isFalse);
      });

      test('should not be loading initially', () {
        // Assert
        expect(store.isLoading, isFalse);
        expect(store.currentOperation, isNull);
      });

      test('should have no error initially', () {
        // Assert
        expect(store.errorMessage, isNull);
        expect(store.errorFailure, isNull);
      });
    });

    group('clearCompletions', () {
      test('should clear completions data', () {
        // Arrange
        runInAction(() {
          store.completions = CompletionList(
            items: [
              CompletionItem(
                label: 'test',
                kind: CompletionItemKind.method,
              ),
            ],
          );
          store.completionsPosition = const CursorPosition(line: 10, column: 5);
        });

        // Act
        store.clearCompletions();

        // Assert
        expect(store.completions, isNull);
        expect(store.completionsPosition, isNull);
      });

      test('should be safe to call when completions is null', () {
        // Act & Assert - should not throw
        store.clearCompletions();
        expect(store.completions, isNull);
      });

      test('should not affect other state', () {
        // Arrange
        runInAction(() {
          store.completions = CompletionList(items: []);
          store.hoverInfo = HoverInfo(contents: []);
          store.diagnostics = ObservableList<Diagnostic>();
        });

        // Act
        store.clearCompletions();

        // Assert
        expect(store.hoverInfo, isNotNull);
        expect(store.diagnostics, isNotNull);
      });
    });

    group('clearHover', () {
      test('should clear hover data', () {
        // Arrange
        runInAction(() {
          store.hoverInfo = HoverInfo(
            contents: [
              MarkupContent(
                kind: MarkupKind.plaintext,
                value: 'Test hover',
              ),
            ],
          );
          store.hoverPosition = const CursorPosition(line: 5, column: 10);
        });

        // Act
        store.clearHover();

        // Assert
        expect(store.hoverInfo, isNull);
        expect(store.hoverPosition, isNull);
      });

      test('should be safe to call when hover is null', () {
        // Act & Assert - should not throw
        store.clearHover();
        expect(store.hoverInfo, isNull);
      });

      test('should not affect other state', () {
        // Arrange
        runInAction(() {
          store.hoverInfo = HoverInfo(contents: []);
          store.completions = CompletionList(items: []);
          store.diagnostics = ObservableList<Diagnostic>();
        });

        // Act
        store.clearHover();

        // Assert
        expect(store.completions, isNotNull);
        expect(store.diagnostics, isNotNull);
      });
    });

    group('clearDiagnostics', () {
      test('should clear diagnostics data', () {
        // Arrange
        runInAction(() {
          store.diagnostics = ObservableList<Diagnostic>.of([
            Diagnostic(
              range: TextSelection(
                start: const CursorPosition(line: 0, column: 0),
                end: const CursorPosition(line: 0, column: 10),
              ),
              severity: DiagnosticSeverity.error,
              message: 'Test error',
            ),
          ]);
          store.diagnosticsDocumentUri = DocumentUri.fromFilePath('/test.dart');
        });

        // Act
        store.clearDiagnostics();

        // Assert
        expect(store.diagnostics, isNull);
        expect(store.diagnosticsDocumentUri, isNull);
      });

      test('should be safe to call when diagnostics is null', () {
        // Act & Assert - should not throw
        store.clearDiagnostics();
        expect(store.diagnostics, isNull);
      });
    });

    group('clearError', () {
      test('should clear error state', () {
        // Arrange
        runInAction(() {
          store.errorMessage = 'Test error';
          store.errorFailure = const LspFailure.connectionFailed(
            reason: 'Test failure',
          );
        });

        // Act
        store.clearError();

        // Assert
        expect(store.errorMessage, isNull);
        expect(store.errorFailure, isNull);
      });

      test('should be safe to call when no error', () {
        // Act & Assert - should not throw
        store.clearError();
        expect(store.errorMessage, isNull);
        expect(store.errorFailure, isNull);
      });

      test('should not affect other state', () {
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
          store.completions = CompletionList(items: []);
        });

        // Act
        store.clearError();

        // Assert
        expect(store.session, isNotNull);
        expect(store.completions, isNotNull);
      });
    });

    group('Observable Reactivity', () {
      test('should observe session changes', () {
        // Arrange
        var callCount = 0;
        autorun((_) {
          // Access observable
          store.session;
          callCount++;
        });

        // Act
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

        // Assert - autorun runs once initially, then once on change
        expect(callCount, greaterThan(1));
      });

      test('should observe completions changes', () {
        // Arrange
        var callCount = 0;
        autorun((_) {
          store.completions;
          callCount++;
        });

        // Act
        runInAction(() {
          store.completions = CompletionList(
            items: [
              CompletionItem(
                label: 'test',
                kind: CompletionItemKind.method,
              ),
            ],
          );
        });

        // Assert
        expect(callCount, greaterThan(1));
      });

      test('should observe error changes', () {
        // Arrange
        var callCount = 0;
        autorun((_) {
          store.errorMessage;
          callCount++;
        });

        // Act
        runInAction(() {
          store.errorMessage = 'Test error';
        });

        // Assert
        expect(callCount, greaterThan(1));
      });
    });

    group('State Transitions', () {
      test('should transition from uninitialized to initialized', () {
        // Assert initial state
        expect(store.session, isNull);
        expect(store.isReady, isFalse);

        // Act
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

        // Assert
        expect(store.session, isNotNull);
        expect(store.isReady, isTrue);
      });

      test('should transition from ready to error', () {
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
          store.errorMessage = 'Connection lost';
        });

        // Assert
        expect(store.isReady, isFalse);
        expect(store.hasError, isTrue);
      });

      test('should transition from error to ready', () {
        // Arrange
        runInAction(() {
          store.errorMessage = 'Test error';
        });
        expect(store.hasError, isTrue);

        // Act
        store.clearError();

        // Assert
        expect(store.hasError, isFalse);
      });
    });

    group('dispose', () {
      test('should have dispose method', () {
        // Act & Assert - should not throw
        store.dispose();
      });

      test('should be safe to call multiple times', () {
        // Act & Assert - should not throw
        store.dispose();
        store.dispose();
        store.dispose();
      });
    });
  });
}
