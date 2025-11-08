import 'dart:async';
import 'package:mobx/mobx.dart';
import 'package:editor_core/editor_core.dart';
import 'package:injectable/injectable.dart';

part 'editor_store.g.dart';

/// EditorStore
///
/// MobX Store для управления состоянием редактора.
///
/// Architecture (Clean Architecture + MobX):
/// ```
/// UI Widget
///     ↓ observes (@observable)
/// EditorStore
///     ↓ calls (@action)
/// Use Cases (Application Layer)
///     ↓ uses
/// Repositories (Domain Interfaces)
///     ↑ implemented by
/// Infrastructure Adapters
/// ```
///
/// MobX Best Practices:
/// - @observable: Reactive state (content, cursor, selection)
/// - @action: State mutations (insertText, moveCursor, undo/redo)
/// - @computed: Derived state (hasUnsavedChanges, canUndo, canRedo)
/// - Single Responsibility: Manages only editor state
/// - Dependency Injection: Repository injected via constructor
/// - Clean Architecture: Depends only on domain interfaces
///
/// Responsibilities:
/// - Manages editor content and cursor state
/// - Handles text editing operations
/// - Coordinates undo/redo operations
/// - Tracks document changes and save state
/// - Exposes reactive state for UI
///
/// Example:
/// ```dart
/// // In UI widget
/// @override
/// Widget build(BuildContext context) {
///   final store = getIt<EditorStore>();
///
///   return Observer(
///     builder: (_) => Text(store.content),
///   );
/// }
///
/// // Trigger action
/// store.insertText('Hello', 0);
/// ```
@injectable
class EditorStore = _EditorStore with _$EditorStore;

abstract class _EditorStore with Store {
  final ICodeEditorRepository _editorRepository;

  // Debounce timer for syncing content to Repository
  Timer? _contentSyncTimer;

  _EditorStore({
    required ICodeEditorRepository editorRepository,
  }) : _editorRepository = editorRepository;

  // ================================================================
  // Observable State (Reactive)
  // ================================================================

  /// Current editor content
  @observable
  String content = '';

  /// Current cursor position
  @observable
  CursorPosition cursorPosition = CursorPosition.create(line: 0, column: 0);

  /// Current text selection (null if no selection)
  @observable
  TextSelection? selection;

  /// Current document URI (null if no document opened)
  @observable
  DocumentUri? documentUri;

  /// Current language ID (null if no language set)
  @observable
  LanguageId? languageId;

  /// Whether document has unsaved changes
  @observable
  bool hasUnsavedChanges = false;

  /// Whether undo operation is available
  @observable
  bool canUndo = false;

  /// Whether redo operation is available
  @observable
  bool canRedo = false;

  /// Whether editor is loading
  @observable
  bool isLoading = false;

  /// Error message (null if no error)
  @observable
  String? errorMessage;

  /// Error failure object (null if no error)
  @observable
  EditorFailure? errorFailure;

  // ================================================================
  // Computed Properties (Derived State)
  // ================================================================

  /// Whether a document is currently opened
  @computed
  bool get hasDocument => documentUri != null;

  /// Whether editor is in error state
  @computed
  bool get hasError => errorMessage != null;

  /// Whether editor is ready for editing
  @computed
  bool get isReady => hasDocument && !isLoading && !hasError;

  /// Total number of lines in document
  @computed
  int get lineCount => content.split('\n').length;

  /// Current line content
  @computed
  String get currentLine {
    if (content.isEmpty) return '';
    final lines = content.split('\n');
    if (cursorPosition.line >= lines.length) return '';
    return lines[cursorPosition.line];
  }

  // ================================================================
  // Actions (State Mutations)
  // ================================================================

  /// Inserts text at current cursor position
  @action
  Future<void> insertText(String text) async {
    if (!isReady) return;

    final result = await _editorRepository.insertText(text);

    result.fold(
      (failure) => _handleError('Failed to insert text', failure),
      (_) async {
        await _refreshEditorState();
        hasUnsavedChanges = true;
        canUndo = true;
      },
    );
  }

  /// Deletes text between two positions
  @action
  Future<void> deleteText({
    required CursorPosition start,
    required CursorPosition end,
  }) async {
    if (!isReady) return;

    // Use replaceText with empty string to delete
    final result = await _editorRepository.replaceText(
      start: start,
      end: end,
      text: '',
    );

    result.fold(
      (failure) => _handleError('Failed to delete text', failure),
      (_) async {
        await _refreshEditorState();
        hasUnsavedChanges = true;
        canUndo = true;
      },
    );
  }

  /// Moves cursor to position
  @action
  Future<void> moveCursor(CursorPosition position) async {
    if (!isReady) return;

    final result = await _editorRepository.setCursorPosition(position);

    result.fold(
      (failure) => _handleError('Failed to move cursor', failure),
      (_) {
        cursorPosition = position;
        selection = null; // Clear selection on cursor move
      },
    );
  }

  /// Sets text selection
  @action
  void setSelection(TextSelection newSelection) {
    selection = newSelection;
  }

  /// Clears text selection
  @action
  void clearSelection() {
    selection = null;
  }

  /// Performs undo operation
  @action
  Future<void> undo() async {
    if (!canUndo) return;

    final result = await _editorRepository.undo();

    result.fold(
      (failure) => _handleError('Failed to undo', failure),
      (_) async {
        await _refreshEditorState();
        canRedo = true;
      },
    );
  }

  /// Performs redo operation
  @action
  Future<void> redo() async {
    if (!canRedo) return;

    final result = await _editorRepository.redo();

    result.fold(
      (failure) => _handleError('Failed to redo', failure),
      (_) async {
        await _refreshEditorState();
        canUndo = true;
      },
    );
  }

  /// Opens a document with content
  @action
  Future<void> openDocument({
    required DocumentUri uri,
    required LanguageId language,
    required String initialContent,
  }) async {
    isLoading = true;
    errorMessage = null;
    errorFailure = null;

    try {
      // Set document metadata
      documentUri = uri;
      languageId = language;
      content = initialContent;
      cursorPosition = CursorPosition.create(line: 0, column: 0);
      selection = null;
      hasUnsavedChanges = false;
      canUndo = false;
      canRedo = false;

      // Open in repository
      final document = EditorDocument(
        uri: uri,
        content: initialContent,
        languageId: language,
        lastModified: DateTime.now(),
      );

      final result = await _editorRepository.openDocument(document);
      result.fold(
        (failure) => _handleError('Failed to open document', failure),
        (_) => {}, // Success
      );
    } finally {
      isLoading = false;
    }
  }

  /// Closes current document
  @action
  void closeDocument() {
    content = '';
    cursorPosition = CursorPosition.create(line: 0, column: 0);
    selection = null;
    documentUri = null;
    languageId = null;
    hasUnsavedChanges = false;
    canUndo = false;
    canRedo = false;
    errorMessage = null;
    errorFailure = null;
  }

  /// Saves current document (marks as saved - actual file write happens externally via FileService)
  @action
  Future<void> markDocumentSaved() async {
    if (!hasDocument) return;
    hasUnsavedChanges = false;
  }

  /// Loads content into editor
  @action
  void loadContent(String newContent, {DocumentUri? uri}) {
    content = newContent;
    cursorPosition = CursorPosition.create(line: 0, column: 0);
    selection = null;
    if (uri != null) {
      documentUri = uri;
    }
    hasUnsavedChanges = false;
    errorMessage = null;
    errorFailure = null;
  }

  /// Updates content from UI (TextField changes)
  ///
  /// This is called when user types in TextField.
  /// Uses debouncing to avoid excessive Repository updates.
  /// After 300ms of inactivity, syncs with Repository for Undo/Redo support.
  @action
  void updateContentFromUI(String newContent) {
    if (content != newContent) {
      content = newContent;
      hasUnsavedChanges = true;
      errorMessage = null;
      errorFailure = null;

      // Cancel previous timer
      _contentSyncTimer?.cancel();

      // Schedule Repository sync after 300ms of inactivity (debouncing)
      _contentSyncTimer = Timer(const Duration(milliseconds: 300), () {
        _syncContentToRepository(newContent);
      });
    }
  }

  /// Syncs content to Repository for Undo/Redo support
  Future<void> _syncContentToRepository(String content) async {
    if (!hasDocument) return;

    // Set content in Repository so Undo/Redo stack is updated
    final result = await _editorRepository.setContent(content);

    result.fold(
      (failure) {
        // Don't show error to user for background sync, just log
        // Presentation layer will continue working with local content
      },
      (_) {
        // Successfully synced - update undo/redo state
        canUndo = true;
      },
    );
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

  /// Refreshes editor state from repository
  @action
  Future<void> _refreshEditorState() async {
    final contentResult = await _editorRepository.getContent();
    final cursorResult = await _editorRepository.getCursorPosition();

    contentResult.fold(
      (failure) => _handleError('Failed to get content', failure),
      (newContent) {
        content = newContent;
      },
    );

    cursorResult.fold(
      (failure) => _handleError('Failed to get cursor', failure),
      (newCursor) {
        cursorPosition = newCursor;
      },
    );
  }

  /// Handles error by setting error state
  @action
  void _handleError(String message, EditorFailure failure) {
    errorMessage = message;
    errorFailure = failure;
  }

  /// Disposes store resources
  void dispose() {
    _contentSyncTimer?.cancel();
  }
}
