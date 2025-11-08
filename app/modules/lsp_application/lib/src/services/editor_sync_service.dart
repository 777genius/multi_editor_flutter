import 'dart:async';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:rxdart/rxdart.dart';

/// Application Service: Synchronizes editor state with LSP server.
///
/// This service is responsible for:
/// - Listening to editor content changes
/// - Notifying LSP server about document updates
/// - Debouncing rapid changes to avoid flooding LSP
/// - Managing document open/close/save notifications
///
/// This is an application service that coordinates between
/// the editor and LSP server, keeping them in sync.
///
/// Follows SRP: One responsibility - keep editor and LSP in sync.
///
/// Example:
/// ```dart
/// final service = EditorSyncService(
///   editorRepository: editorRepo,
///   lspRepository: lspRepo,
///   sessionService: sessionService,
/// );
///
/// // Start syncing
/// await service.startSyncing(
///   languageId: LanguageId.dart,
///   documentUri: DocumentUri.fromFilePath('/file.dart'),
/// );
///
/// // Editor changes are automatically synced to LSP
///
/// // Stop syncing
/// await service.stopSyncing();
/// ```
class EditorSyncService {
  final ICodeEditorRepository _editorRepository;
  final ILspClientRepository _lspRepository;
  final LspSessionService _sessionService;

  /// Debounce duration for content changes
  /// Prevents flooding LSP server with every keystroke
  final Duration _debounceDuration;

  StreamSubscription? _contentSubscription;
  StreamSubscription? _cursorSubscription;
  StreamSubscription? _focusSubscription;

  LspSession? _currentSession;
  DocumentUri? _currentDocumentUri;

  EditorSyncService({
    required ICodeEditorRepository editorRepository,
    required ILspClientRepository lspRepository,
    required LspSessionService sessionService,
    Duration debounceDuration = const Duration(milliseconds: 300),
  })  : _editorRepository = editorRepository,
        _lspRepository = lspRepository,
        _sessionService = sessionService,
        _debounceDuration = debounceDuration;

  /// Starts synchronizing editor with LSP server.
  ///
  /// This method:
  /// 1. Gets or creates LSP session for the language
  /// 2. Notifies LSP about document open
  /// 3. Starts listening to editor changes
  /// 4. Syncs changes with LSP server (debounced)
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [documentUri]: Document URI
  /// - [rootUri]: Project root URI
  ///
  /// Returns: true if sync started successfully
  Future<bool> startSyncing({
    required LanguageId languageId,
    required DocumentUri documentUri,
    required DocumentUri rootUri,
  }) async {
    // Stop existing sync if any
    await stopSyncing();

    // Get or create LSP session
    final sessionResult = await _sessionService.getOrCreateSession(
      languageId: languageId,
      rootUri: rootUri,
    );

    final session = sessionResult.fold(
      (_) => null,
      (s) => s,
    );

    if (session == null || !session.canHandleRequests) {
      return false;
    }

    _currentSession = session;
    _currentDocumentUri = documentUri;

    // Get initial content and notify LSP about document open
    final contentResult = await _editorRepository.getContent();

    await contentResult.fold(
      (_) async {},
      (content) async {
        await _lspRepository.notifyDocumentOpened(
          sessionId: session.id,
          documentUri: documentUri,
          languageId: languageId,
          content: content,
        );
      },
    );

    // Start listening to editor changes
    _setupContentListener();
    _setupCursorListener();
    _setupFocusListener();

    return true;
  }

  /// Stops synchronizing.
  ///
  /// Notifies LSP server that document is closed and
  /// stops listening to editor changes.
  Future<void> stopSyncing() async {
    // Cancel subscriptions
    await _contentSubscription?.cancel();
    await _cursorSubscription?.cancel();
    await _focusSubscription?.cancel();

    _contentSubscription = null;
    _cursorSubscription = null;
    _focusSubscription = null;

    // Notify LSP about document close
    if (_currentSession != null && _currentDocumentUri != null) {
      await _lspRepository.notifyDocumentClosed(
        sessionId: _currentSession!.id,
        documentUri: _currentDocumentUri!,
      );
    }

    _currentSession = null;
    _currentDocumentUri = null;
  }

  /// Sets up content change listener with debouncing.
  ///
  /// This prevents flooding LSP server with every keystroke.
  /// Instead, changes are batched and sent after user stops typing.
  void _setupContentListener() {
    _contentSubscription = _editorRepository.onContentChanged
        .debounceTime(_debounceDuration)
        .listen((content) {
      _handleContentChange(content);
    });
  }

  /// Handles content change event.
  ///
  /// Notifies LSP server about the new content.
  Future<void> _handleContentChange(String content) async {
    if (_currentSession == null || _currentDocumentUri == null) {
      return;
    }

    await _lspRepository.notifyDocumentChanged(
      sessionId: _currentSession!.id,
      documentUri: _currentDocumentUri!,
      content: content,
    );
  }

  /// Sets up cursor position listener.
  ///
  /// Some LSP servers use cursor position for context-aware features.
  void _setupCursorListener() {
    _cursorSubscription = _editorRepository.onCursorPositionChanged
        .debounceTime(const Duration(milliseconds: 100))
        .listen((position) {
      // TODO: Implement cursor position tracking for LSP features
      // Cursor position can be used for:
      // - Context-aware completions (send position to completion provider)
      // - Hover info (update hover based on cursor position)
      // - Signature help (show function signatures at cursor)
      // Future implementation: Send cursor position updates to active LSP session
    });
  }

  /// Sets up focus listener.
  ///
  /// Some IDEs notify LSP when editor gains/loses focus.
  void _setupFocusListener() {
    _focusSubscription = _editorRepository.onFocusChanged.listen((hasFocus) {
      // TODO: Implement focus-based LSP optimization
      // Can be used to:
      // - Pause/resume LSP updates when not focused (battery saving)
      // - Trigger re-validation when gaining focus (catch external changes)
      // - Debounce diagnostics updates when unfocused
      // Future implementation: Notify LSP session about focus changes
    });
  }

  /// Notifies LSP that document was saved.
  ///
  /// Should be called when user saves the file.
  Future<void> notifyDocumentSaved() async {
    if (_currentSession == null || _currentDocumentUri == null) {
      return;
    }

    await _lspRepository.notifyDocumentSaved(
      sessionId: _currentSession!.id,
      documentUri: _currentDocumentUri!,
    );
  }

  /// Checks if currently syncing.
  ///
  /// Returns: true if sync is active
  bool get isSyncing =>
      _currentSession != null &&
      _currentDocumentUri != null &&
      _contentSubscription != null;

  /// Gets current document URI.
  ///
  /// Returns: Current document URI or null
  DocumentUri? get currentDocumentUri => _currentDocumentUri;

  /// Gets current session.
  ///
  /// Returns: Current LSP session or null
  LspSession? get currentSession => _currentSession;

  /// Disposes the service.
  ///
  /// Stops all subscriptions and cleans up.
  Future<void> dispose() async {
    await stopSyncing();
  }
}
