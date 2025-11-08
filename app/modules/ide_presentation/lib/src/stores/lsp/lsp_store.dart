import 'package:mobx/mobx.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:lsp_application/lsp_application.dart';
import 'package:injectable/injectable.dart';

part 'lsp_store.g.dart';

/// LspStore
///
/// MobX Store для управления LSP взаимодействиями и языковыми функциями.
///
/// Architecture (Clean Architecture + MobX):
/// ```
/// UI Widget
///     ↓ observes (@observable)
/// LspStore
///     ↓ calls (@action)
/// LSP Use Cases (Application Layer)
///     ↓ uses
/// ILspClientRepository (Domain Interface)
///     ↑ implemented by
/// LSP Infrastructure Adapters
/// ```
///
/// MobX Best Practices:
/// - @observable: Reactive state (session, completions, hover, diagnostics)
/// - @action: State mutations (initialize, getCompletions, getHover)
/// - @computed: Derived state (isReady, hasCompletions, errorCount)
/// - Single Responsibility: Manages only LSP state
/// - Dependency Injection: Use Cases injected via constructor
/// - Clean Architecture: Depends only on application use cases
///
/// Responsibilities:
/// - Manages LSP session lifecycle
/// - Coordinates completion requests
/// - Coordinates hover information requests
/// - Coordinates diagnostics requests
/// - Coordinates navigation (go-to-definition, find-references)
/// - Exposes reactive state for UI
///
/// Example:
/// ```dart
/// // In UI widget
/// @override
/// Widget build(BuildContext context) {
///   final store = getIt<LspStore>();
///
///   return Observer(
///     builder: (_) {
///       if (store.hasCompletions) {
///         return CompletionPopup(
///           completions: store.completions!.items,
///         );
///       }
///       return SizedBox.shrink();
///     },
///   );
/// }
///
/// // Trigger action
/// await store.getCompletions(
///   languageId: LanguageId.dart,
///   documentUri: DocumentUri.fromFilePath('/file.dart'),
///   position: CursorPosition.create(line: 10, column: 5),
/// );
/// ```
@injectable
class LspStore = _LspStore with _$LspStore;

abstract class _LspStore with Store {
  final InitializeLspSessionUseCase _initializeSessionUseCase;
  final ShutdownLspSessionUseCase _shutdownSessionUseCase;
  final GetCompletionsUseCase _getCompletionsUseCase;
  final GetHoverInfoUseCase _getHoverInfoUseCase;
  final GetDiagnosticsUseCase _getDiagnosticsUseCase;
  final GoToDefinitionUseCase _goToDefinitionUseCase;
  final FindReferencesUseCase _findReferencesUseCase;

  _LspStore({
    required InitializeLspSessionUseCase initializeSessionUseCase,
    required ShutdownLspSessionUseCase shutdownSessionUseCase,
    required GetCompletionsUseCase getCompletionsUseCase,
    required GetHoverInfoUseCase getHoverInfoUseCase,
    required GetDiagnosticsUseCase getDiagnosticsUseCase,
    required GoToDefinitionUseCase goToDefinitionUseCase,
    required FindReferencesUseCase findReferencesUseCase,
  })  : _initializeSessionUseCase = initializeSessionUseCase,
        _shutdownSessionUseCase = shutdownSessionUseCase,
        _getCompletionsUseCase = getCompletionsUseCase,
        _getHoverInfoUseCase = getHoverInfoUseCase,
        _getDiagnosticsUseCase = getDiagnosticsUseCase,
        _goToDefinitionUseCase = goToDefinitionUseCase,
        _findReferencesUseCase = findReferencesUseCase;

  // ================================================================
  // Observable State (Reactive)
  // ================================================================

  /// Current LSP session (null if not initialized)
  @observable
  LspSession? session;

  /// Current language ID (null if no session)
  @observable
  LanguageId? languageId;

  /// Code completions (null if not loaded)
  @observable
  CompletionList? completions;

  /// Completion request position (null if no completions)
  @observable
  CursorPosition? completionsPosition;

  /// Hover information (null if not loaded)
  @observable
  HoverInfo? hoverInfo;

  /// Hover request position (null if no hover)
  @observable
  CursorPosition? hoverPosition;

  /// Diagnostics list (null if not loaded)
  @observable
  ObservableList<Diagnostic>? diagnostics;

  /// Document URI for diagnostics (null if not loaded)
  @observable
  DocumentUri? diagnosticsDocumentUri;

  /// Definition locations (null if not loaded)
  @observable
  ObservableList<Location>? definitionLocations;

  /// Reference locations (null if not loaded)
  @observable
  ObservableList<Location>? referenceLocations;

  /// Whether session is initializing
  @observable
  bool isInitializing = false;

  /// Whether an operation is in progress
  @observable
  bool isLoading = false;

  /// Current operation name (null if not loading)
  @observable
  String? currentOperation;

  /// Error message (null if no error)
  @observable
  String? errorMessage;

  /// Error failure object (null if no error)
  @observable
  LspFailure? errorFailure;

  // ================================================================
  // Computed Properties (Derived State)
  // ================================================================

  /// Whether LSP session is ready
  @computed
  bool get isReady => session != null && !isInitializing && !hasError;

  /// Whether LSP is in error state
  @computed
  bool get hasError => errorMessage != null;

  /// Whether completions are available
  @computed
  bool get hasCompletions => completions != null && completions!.items.isNotEmpty;

  /// Whether hover info is available
  @computed
  bool get hasHoverInfo => hoverInfo != null && hoverInfo!.contents.isNotEmpty;

  /// Whether diagnostics are available
  @computed
  bool get hasDiagnostics => diagnostics != null && diagnostics!.isNotEmpty;

  /// Number of errors in diagnostics
  @computed
  int get errorCount {
    if (diagnostics == null) return 0;
    return diagnostics!
        .where((d) => d.severity == DiagnosticSeverity.error)
        .length;
  }

  /// Number of warnings in diagnostics
  @computed
  int get warningCount {
    if (diagnostics == null) return 0;
    return diagnostics!
        .where((d) => d.severity == DiagnosticSeverity.warning)
        .length;
  }

  /// Only error diagnostics
  @computed
  List<Diagnostic> get errors {
    if (diagnostics == null) return [];
    return diagnostics!
        .where((d) => d.severity == DiagnosticSeverity.error)
        .toList();
  }

  /// Only warning diagnostics
  @computed
  List<Diagnostic> get warnings {
    if (diagnostics == null) return [];
    return diagnostics!
        .where((d) => d.severity == DiagnosticSeverity.warning)
        .toList();
  }

  /// LSP status for display
  @computed
  String get statusText {
    if (hasError) return 'LSP Error';
    if (isInitializing) return 'Initializing...';
    if (isLoading && currentOperation != null) return currentOperation!;
    if (isReady) return 'LSP Ready';
    return 'No LSP Session';
  }

  // ================================================================
  // Actions (State Mutations)
  // ================================================================

  /// Initializes LSP session for a language
  @action
  Future<void> initializeSession({
    required LanguageId language,
    required DocumentUri rootUri,
  }) async {
    isInitializing = true;
    errorMessage = null;
    errorFailure = null;
    languageId = language;

    final result = await _initializeSessionUseCase(
      languageId: language,
      rootUri: rootUri,
    );

    result.fold(
      (failure) {
        _handleError('Failed to initialize LSP session', failure);
        isInitializing = false;
      },
      (newSession) {
        session = newSession;
        isInitializing = false;
      },
    );
  }

  /// Shuts down LSP session
  @action
  Future<void> shutdownSession() async {
    if (languageId == null) return;

    final result = await _shutdownSessionUseCase(languageId: languageId!);

    result.fold(
      (failure) => _handleError('Failed to shutdown LSP session', failure),
      (_) {
        session = null;
        languageId = null;
        _clearAllData();
      },
    );
  }

  /// Requests code completions at cursor position
  @action
  Future<void> getCompletions({
    required LanguageId language,
    required DocumentUri documentUri,
    required CursorPosition position,
    String? filterPrefix,
  }) async {
    if (!isReady) return;

    // Don't set loading state for completions (would flicker)
    final result = await _getCompletionsUseCase(
      languageId: language,
      documentUri: documentUri,
      position: position,
      filterPrefix: filterPrefix,
    );

    result.fold(
      (failure) {
        // Silently fail completions - don't disrupt editing
        // Could log this for debugging
        completions = null;
        completionsPosition = null;
      },
      (newCompletions) {
        completions = newCompletions;
        completionsPosition = position;
      },
    );
  }

  /// Requests hover information at cursor position
  @action
  Future<void> getHoverInfo({
    required LanguageId language,
    required DocumentUri documentUri,
    required CursorPosition position,
  }) async {
    if (!isReady) return;

    final result = await _getHoverInfoUseCase(
      languageId: language,
      documentUri: documentUri,
      position: position,
    );

    result.fold(
      (failure) {
        // Silently fail hover - don't disrupt editing
        hoverInfo = null;
        hoverPosition = null;
      },
      (newHoverInfo) {
        hoverInfo = newHoverInfo;
        hoverPosition = position;
      },
    );
  }

  /// Requests diagnostics for a document
  @action
  Future<void> getDiagnostics({
    required LanguageId language,
    required DocumentUri documentUri,
  }) async {
    if (!isReady) return;

    final result = await _getDiagnosticsUseCase(
      languageId: language,
      documentUri: documentUri,
    );

    result.fold(
      (failure) => _handleError('Failed to get diagnostics', failure),
      (newDiagnostics) {
        diagnostics = ObservableList.of(newDiagnostics);
        diagnosticsDocumentUri = documentUri;
      },
    );
  }

  /// Requests go to definition
  @action
  Future<void> goToDefinition({
    required LanguageId language,
    required DocumentUri documentUri,
    required CursorPosition position,
  }) async {
    if (!isReady) return;

    isLoading = true;
    currentOperation = 'Finding definition...';
    errorMessage = null;
    errorFailure = null;

    final result = await _goToDefinitionUseCase(
      languageId: language,
      documentUri: documentUri,
      position: position,
    );

    result.fold(
      (failure) {
        _handleError('Failed to find definition', failure);
        isLoading = false;
        currentOperation = null;
      },
      (locations) {
        definitionLocations = ObservableList.of(locations);
        isLoading = false;
        currentOperation = null;
      },
    );
  }

  /// Requests find references
  @action
  Future<void> findReferences({
    required LanguageId language,
    required DocumentUri documentUri,
    required CursorPosition position,
  }) async {
    if (!isReady) return;

    isLoading = true;
    currentOperation = 'Finding references...';
    errorMessage = null;
    errorFailure = null;

    final result = await _findReferencesUseCase(
      languageId: language,
      documentUri: documentUri,
      position: position,
    );

    result.fold(
      (failure) {
        _handleError('Failed to find references', failure);
        isLoading = false;
        currentOperation = null;
      },
      (locations) {
        referenceLocations = ObservableList.of(locations);
        isLoading = false;
        currentOperation = null;
      },
    );
  }

  /// Clears completions popup
  @action
  void clearCompletions() {
    completions = null;
    completionsPosition = null;
  }

  /// Clears hover popup
  @action
  void clearHover() {
    hoverInfo = null;
    hoverPosition = null;
  }

  /// Clears diagnostics
  @action
  void clearDiagnostics() {
    diagnostics = null;
    diagnosticsDocumentUri = null;
  }

  /// Clears error state
  @action
  void clearError() {
    errorMessage = null;
    errorFailure = null;
  }

  // ================================================================
  // Private Methods
  // ================================================================

  /// Clears all LSP data
  @action
  void _clearAllData() {
    completions = null;
    completionsPosition = null;
    hoverInfo = null;
    hoverPosition = null;
    diagnostics = null;
    diagnosticsDocumentUri = null;
    definitionLocations = null;
    referenceLocations = null;
    errorMessage = null;
    errorFailure = null;
    isLoading = false;
    currentOperation = null;
  }

  /// Handles error by setting error state
  @action
  void _handleError(String message, LspFailure failure) {
    errorMessage = message;
    errorFailure = failure;
  }

  /// Disposes store resources
  void dispose() {
    // Cleanup if needed
  }
}
