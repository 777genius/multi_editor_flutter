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

  group('LspStore - Computed Properties', () {
    group('isReady', () {
      test('should be false when session is null', () {
        // Assert
        expect(store.isReady, isFalse);
      });

      test('should be false when initializing', () {
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
          store.isInitializing = true;
        });

        // Assert
        expect(store.isReady, isFalse);
      });

      test('should be false when has error', () {
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
          store.errorMessage = 'Test error';
        });

        // Assert
        expect(store.isReady, isFalse);
      });

      test('should be true when session exists and no error', () {
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
          store.isInitializing = false;
          store.errorMessage = null;
        });

        // Assert
        expect(store.isReady, isTrue);
      });
    });

    group('hasError', () {
      test('should be false when errorMessage is null', () {
        // Assert
        expect(store.hasError, isFalse);
      });

      test('should be true when errorMessage is set', () {
        // Arrange
        runInAction(() {
          store.errorMessage = 'Test error';
        });

        // Assert
        expect(store.hasError, isTrue);
      });
    });

    group('hasCompletions', () {
      test('should be false when completions is null', () {
        // Assert
        expect(store.hasCompletions, isFalse);
      });

      test('should be false when completions list is empty', () {
        // Arrange
        runInAction(() {
          store.completions = CompletionList(items: []);
        });

        // Assert
        expect(store.hasCompletions, isFalse);
      });

      test('should be true when completions has items', () {
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
        });

        // Assert
        expect(store.hasCompletions, isTrue);
      });
    });

    group('hasHoverInfo', () {
      test('should be false when hoverInfo is null', () {
        // Assert
        expect(store.hasHoverInfo, isFalse);
      });

      test('should be false when hoverInfo contents is empty', () {
        // Arrange
        runInAction(() {
          store.hoverInfo = HoverInfo(contents: []);
        });

        // Assert
        expect(store.hasHoverInfo, isFalse);
      });

      test('should be true when hoverInfo has contents', () {
        // Arrange
        runInAction(() {
          store.hoverInfo = HoverInfo(
            contents: [
              MarkupContent(
                kind: MarkupKind.plaintext,
                value: 'Test hover info',
              ),
            ],
          );
        });

        // Assert
        expect(store.hasHoverInfo, isTrue);
      });
    });

    group('hasDiagnostics', () {
      test('should be false when diagnostics is null', () {
        // Assert
        expect(store.hasDiagnostics, isFalse);
      });

      test('should be false when diagnostics is empty', () {
        // Arrange
        runInAction(() {
          store.diagnostics = ObservableList<Diagnostic>();
        });

        // Assert
        expect(store.hasDiagnostics, isFalse);
      });

      test('should be true when diagnostics has items', () {
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
        });

        // Assert
        expect(store.hasDiagnostics, isTrue);
      });
    });

    group('errorCount', () {
      test('should be 0 when diagnostics is null', () {
        // Assert
        expect(store.errorCount, equals(0));
      });

      test('should be 0 when no error diagnostics', () {
        // Arrange
        runInAction(() {
          store.diagnostics = ObservableList<Diagnostic>.of([
            Diagnostic(
              range: TextSelection(
                start: const CursorPosition(line: 0, column: 0),
                end: const CursorPosition(line: 0, column: 10),
              ),
              severity: DiagnosticSeverity.warning,
              message: 'Test warning',
            ),
          ]);
        });

        // Assert
        expect(store.errorCount, equals(0));
      });

      test('should count only error diagnostics', () {
        // Arrange
        runInAction(() {
          store.diagnostics = ObservableList<Diagnostic>.of([
            Diagnostic(
              range: TextSelection(
                start: const CursorPosition(line: 0, column: 0),
                end: const CursorPosition(line: 0, column: 10),
              ),
              severity: DiagnosticSeverity.error,
              message: 'Error 1',
            ),
            Diagnostic(
              range: TextSelection(
                start: const CursorPosition(line: 1, column: 0),
                end: const CursorPosition(line: 1, column: 10),
              ),
              severity: DiagnosticSeverity.warning,
              message: 'Warning 1',
            ),
            Diagnostic(
              range: TextSelection(
                start: const CursorPosition(line: 2, column: 0),
                end: const CursorPosition(line: 2, column: 10),
              ),
              severity: DiagnosticSeverity.error,
              message: 'Error 2',
            ),
          ]);
        });

        // Assert
        expect(store.errorCount, equals(2));
      });
    });

    group('warningCount', () {
      test('should be 0 when diagnostics is null', () {
        // Assert
        expect(store.warningCount, equals(0));
      });

      test('should count only warning diagnostics', () {
        // Arrange
        runInAction(() {
          store.diagnostics = ObservableList<Diagnostic>.of([
            Diagnostic(
              range: TextSelection(
                start: const CursorPosition(line: 0, column: 0),
                end: const CursorPosition(line: 0, column: 10),
              ),
              severity: DiagnosticSeverity.error,
              message: 'Error 1',
            ),
            Diagnostic(
              range: TextSelection(
                start: const CursorPosition(line: 1, column: 0),
                end: const CursorPosition(line: 1, column: 10),
              ),
              severity: DiagnosticSeverity.warning,
              message: 'Warning 1',
            ),
            Diagnostic(
              range: TextSelection(
                start: const CursorPosition(line: 2, column: 0),
                end: const CursorPosition(line: 2, column: 10),
              ),
              severity: DiagnosticSeverity.warning,
              message: 'Warning 2',
            ),
          ]);
        });

        // Assert
        expect(store.warningCount, equals(2));
      });
    });

    group('errors getter', () {
      test('should return empty list when diagnostics is null', () {
        // Assert
        expect(store.errors, isEmpty);
      });

      test('should return only error diagnostics', () {
        // Arrange
        final error1 = Diagnostic(
          range: TextSelection(
            start: const CursorPosition(line: 0, column: 0),
            end: const CursorPosition(line: 0, column: 10),
          ),
          severity: DiagnosticSeverity.error,
          message: 'Error 1',
        );

        final error2 = Diagnostic(
          range: TextSelection(
            start: const CursorPosition(line: 2, column: 0),
            end: const CursorPosition(line: 2, column: 10),
          ),
          severity: DiagnosticSeverity.error,
          message: 'Error 2',
        );

        runInAction(() {
          store.diagnostics = ObservableList<Diagnostic>.of([
            error1,
            Diagnostic(
              range: TextSelection(
                start: const CursorPosition(line: 1, column: 0),
                end: const CursorPosition(line: 1, column: 10),
              ),
              severity: DiagnosticSeverity.warning,
              message: 'Warning 1',
            ),
            error2,
          ]);
        });

        // Assert
        expect(store.errors, hasLength(2));
        expect(store.errors, contains(error1));
        expect(store.errors, contains(error2));
      });
    });

    group('warnings getter', () {
      test('should return empty list when diagnostics is null', () {
        // Assert
        expect(store.warnings, isEmpty);
      });

      test('should return only warning diagnostics', () {
        // Arrange
        final warning1 = Diagnostic(
          range: TextSelection(
            start: const CursorPosition(line: 1, column: 0),
            end: const CursorPosition(line: 1, column: 10),
          ),
          severity: DiagnosticSeverity.warning,
          message: 'Warning 1',
        );

        final warning2 = Diagnostic(
          range: TextSelection(
            start: const CursorPosition(line: 3, column: 0),
            end: const CursorPosition(line: 3, column: 10),
          ),
          severity: DiagnosticSeverity.warning,
          message: 'Warning 2',
        );

        runInAction(() {
          store.diagnostics = ObservableList<Diagnostic>.of([
            Diagnostic(
              range: TextSelection(
                start: const CursorPosition(line: 0, column: 0),
                end: const CursorPosition(line: 0, column: 10),
              ),
              severity: DiagnosticSeverity.error,
              message: 'Error 1',
            ),
            warning1,
            warning2,
          ]);
        });

        // Assert
        expect(store.warnings, hasLength(2));
        expect(store.warnings, contains(warning1));
        expect(store.warnings, contains(warning2));
      });
    });

    group('statusText', () {
      test('should return "LSP Error" when hasError', () {
        // Arrange
        runInAction(() {
          store.errorMessage = 'Test error';
        });

        // Assert
        expect(store.statusText, equals('LSP Error'));
      });

      test('should return "Initializing..." when initializing', () {
        // Arrange
        runInAction(() {
          store.isInitializing = true;
        });

        // Assert
        expect(store.statusText, equals('Initializing...'));
      });

      test('should return current operation when loading', () {
        // Arrange
        runInAction(() {
          store.isLoading = true;
          store.currentOperation = 'Finding definition...';
        });

        // Assert
        expect(store.statusText, equals('Finding definition...'));
      });

      test('should return "LSP Ready" when ready', () {
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
          store.isInitializing = false;
          store.errorMessage = null;
        });

        // Assert
        expect(store.statusText, equals('LSP Ready'));
      });

      test('should return "No LSP Session" by default', () {
        // Assert
        expect(store.statusText, equals('No LSP Session'));
      });
    });
  });
}
