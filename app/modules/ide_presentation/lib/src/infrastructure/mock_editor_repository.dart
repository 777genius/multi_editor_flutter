import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:editor_core/editor_core.dart';

/// Mock implementation of ICodeEditorRepository for MVP/Testing.
///
/// This is a temporary in-memory implementation that allows the app to run
/// without the Rust native editor being compiled.
///
/// Architecture:
/// - Implements ICodeEditorRepository (domain interface)
/// - Pure Dart implementation (no FFI required)
/// - Event streams for reactive updates
/// - Proper error handling with Either
///
/// Usage:
/// ```dart
/// // In DI:
/// getIt.registerLazySingleton<ICodeEditorRepository>(
///   () => MockEditorRepository(),
/// );
/// ```
///
/// Note: Replace with NativeEditorRepository when Rust is compiled.
class MockEditorRepository implements ICodeEditorRepository {
  // In-memory state
  String _content = '';
  CursorPosition _cursorPosition = CursorPosition.create(line: 0, column: 0);
  TextSelection? _selection;
  EditorDocument? _currentDocument;
  LanguageId _languageId = LanguageId.plainText;
  EditorTheme _theme = EditorTheme.dark();
  bool _isReady = false;
  bool _isFocused = false;

  // Undo/Redo stacks
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  int _maxHistorySize = 100;

  // Event controllers
  final _contentChangedController = StreamController<String>.broadcast();
  final _cursorPositionChangedController =
      StreamController<CursorPosition>.broadcast();
  final _selectionChangedController =
      StreamController<TextSelection>.broadcast();
  final _focusChangedController = StreamController<bool>.broadcast();

  MockEditorRepository();

  // ================================================================
  // Lifecycle
  // ================================================================

  @override
  Future<Either<EditorFailure, Unit>> initialize() async {
    _isReady = true;
    return right(unit);
  }

  @override
  bool get isReady => _isReady;

  @override
  Future<void> dispose() async {
    await _contentChangedController.close();
    await _cursorPositionChangedController.close();
    await _selectionChangedController.close();
    await _focusChangedController.close();
  }

  // ================================================================
  // Document Management
  // ================================================================

  @override
  Future<Either<EditorFailure, Unit>> openDocument(
      EditorDocument document) async {
    if (!isReady) {
      return left(const EditorFailure.notInitialized());
    }

    _currentDocument = document;
    _content = document.content;
    _languageId = document.languageId;
    _cursorPosition = CursorPosition.create(line: 0, column: 0);
    _selection = null;
    _undoStack.clear();
    _redoStack.clear();

    _contentChangedController.add(_content);
    _cursorPositionChangedController.add(_cursorPosition);

    return right(unit);
  }

  @override
  Future<Either<EditorFailure, String>> getContent() async {
    if (!isReady) {
      return left(const EditorFailure.notInitialized());
    }
    return right(_content);
  }

  @override
  Future<Either<EditorFailure, Unit>> setContent(String content) async {
    if (!isReady) {
      return left(const EditorFailure.notInitialized());
    }

    _pushToUndoStack();
    _content = content;
    _contentChangedController.add(_content);

    return right(unit);
  }

  @override
  Future<Either<EditorFailure, EditorDocument>> getCurrentDocument() async {
    if (!isReady) {
      return left(const EditorFailure.notInitialized());
    }

    if (_currentDocument == null) {
      return left(const EditorFailure.documentNotFound(
        message: 'No document currently opened',
      ));
    }

    return right(_currentDocument!);
  }

  @override
  Future<Either<EditorFailure, Unit>> closeDocument() async {
    _currentDocument = null;
    _content = '';
    _cursorPosition = CursorPosition.create(line: 0, column: 0);
    _selection = null;
    _undoStack.clear();
    _redoStack.clear();

    return right(unit);
  }

  // ================================================================
  // Language & Syntax
  // ================================================================

  @override
  Future<Either<EditorFailure, Unit>> setLanguage(LanguageId languageId) async {
    _languageId = languageId;
    return right(unit);
  }

  @override
  Future<Either<EditorFailure, LanguageId>> getLanguage() async {
    return right(_languageId);
  }

  // ================================================================
  // Theme & Appearance
  // ================================================================

  @override
  Future<Either<EditorFailure, Unit>> setTheme(EditorTheme theme) async {
    _theme = theme;
    return right(unit);
  }

  @override
  Future<Either<EditorFailure, EditorTheme>> getTheme() async {
    return right(_theme);
  }

  // ================================================================
  // Cursor & Selection
  // ================================================================

  @override
  Future<Either<EditorFailure, CursorPosition>> getCursorPosition() async {
    if (!isReady) {
      return left(const EditorFailure.notInitialized());
    }
    return right(_cursorPosition);
  }

  @override
  Future<Either<EditorFailure, Unit>> setCursorPosition(
      CursorPosition position) async {
    if (!isReady) {
      return left(const EditorFailure.notInitialized());
    }

    _cursorPosition = position;
    _cursorPositionChangedController.add(_cursorPosition);

    return right(unit);
  }

  @override
  Future<Either<EditorFailure, TextSelection>> getSelection() async {
    if (!isReady) {
      return left(const EditorFailure.notInitialized());
    }

    if (_selection == null) {
      return left(const EditorFailure.operationFailed(
        operation: 'getSelection',
        reason: 'No text selected',
      ));
    }

    return right(_selection!);
  }

  @override
  Future<Either<EditorFailure, Unit>> setSelection(
      TextSelection selection) async {
    if (!isReady) {
      return left(const EditorFailure.notInitialized());
    }

    _selection = selection;
    _selectionChangedController.add(_selection!);

    return right(unit);
  }

  // ================================================================
  // Text Operations
  // ================================================================

  @override
  Future<Either<EditorFailure, Unit>> insertText(String text) async {
    if (!isReady) {
      return left(const EditorFailure.notInitialized());
    }

    _pushToUndoStack();

    // Simple insertion at cursor (for MVP)
    final lines = _content.split('\n');
    if (_cursorPosition.line < lines.length) {
      final line = lines[_cursorPosition.line];
      final before = line.substring(0, _cursorPosition.column);
      final after = line.substring(_cursorPosition.column);
      lines[_cursorPosition.line] = before + text + after;

      _content = lines.join('\n');
      _cursorPosition = CursorPosition.create(
        line: _cursorPosition.line,
        column: _cursorPosition.column + text.length,
      );

      _contentChangedController.add(_content);
      _cursorPositionChangedController.add(_cursorPosition);
    }

    return right(unit);
  }

  @override
  Future<Either<EditorFailure, Unit>> replaceText({
    required CursorPosition start,
    required CursorPosition end,
    required String text,
  }) async {
    if (!isReady) {
      return left(const EditorFailure.notInitialized());
    }

    _pushToUndoStack();

    // Simple replace (for MVP, single line only)
    final lines = _content.split('\n');
    if (start.line < lines.length && end.line < lines.length) {
      if (start.line == end.line) {
        // Same line
        final line = lines[start.line];
        final before = line.substring(0, start.column);
        final after = line.substring(end.column);
        lines[start.line] = before + text + after;

        _content = lines.join('\n');
        _cursorPosition = CursorPosition.create(
          line: start.line,
          column: start.column + text.length,
        );

        _contentChangedController.add(_content);
        _cursorPositionChangedController.add(_cursorPosition);
      }
    }

    return right(unit);
  }

  @override
  Future<Either<EditorFailure, Unit>> formatDocument() async {
    // No-op for mock
    return right(unit);
  }

  // ================================================================
  // Editor Actions
  // ================================================================

  @override
  Future<Either<EditorFailure, Unit>> undo() async {
    if (!isReady) {
      return left(const EditorFailure.notInitialized());
    }

    if (_undoStack.isEmpty) {
      return left(const EditorFailure.operationFailed(
        operation: 'undo',
        reason: 'Nothing to undo',
      ));
    }

    _redoStack.add(_content);
    _content = _undoStack.removeLast();
    _contentChangedController.add(_content);

    return right(unit);
  }

  @override
  Future<Either<EditorFailure, Unit>> redo() async {
    if (!isReady) {
      return left(const EditorFailure.notInitialized());
    }

    if (_redoStack.isEmpty) {
      return left(const EditorFailure.operationFailed(
        operation: 'redo',
        reason: 'Nothing to redo',
      ));
    }

    _undoStack.add(_content);
    _content = _redoStack.removeLast();
    _contentChangedController.add(_content);

    return right(unit);
  }

  @override
  Future<Either<EditorFailure, Unit>> find(String searchText) async {
    // No-op for mock
    return right(unit);
  }

  @override
  Future<Either<EditorFailure, Unit>> replace({
    required String searchText,
    required String replaceText,
  }) async {
    // No-op for mock
    return right(unit);
  }

  // ================================================================
  // Navigation
  // ================================================================

  @override
  Future<Either<EditorFailure, Unit>> scrollToLine(int lineNumber) async {
    // No-op for mock
    return right(unit);
  }

  @override
  Future<Either<EditorFailure, Unit>> revealLine(int lineNumber) async {
    // No-op for mock
    return right(unit);
  }

  @override
  Future<Either<EditorFailure, Unit>> focus() async {
    _isFocused = true;
    _focusChangedController.add(_isFocused);
    return right(unit);
  }

  // ================================================================
  // Events
  // ================================================================

  @override
  Stream<String> get onContentChanged => _contentChangedController.stream;

  @override
  Stream<CursorPosition> get onCursorPositionChanged =>
      _cursorPositionChangedController.stream;

  @override
  Stream<TextSelection> get onSelectionChanged =>
      _selectionChangedController.stream;

  @override
  Stream<bool> get onFocusChanged => _focusChangedController.stream;

  // ================================================================
  // Private Helpers
  // ================================================================

  void _pushToUndoStack() {
    _undoStack.add(_content);
    if (_undoStack.length > _maxHistorySize) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear(); // Clear redo stack on new change
  }
}
