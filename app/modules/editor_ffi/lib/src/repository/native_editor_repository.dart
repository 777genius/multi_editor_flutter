import 'dart:async';
import 'dart:ffi' as ffi;
import 'package:dartz/dartz.dart';
import 'package:editor_core/editor_core.dart';
import 'package:ffi/ffi.dart';
import '../ffi/native_bindings.dart';

/// Native Rust editor implementation of ICodeEditorRepository.
///
/// This adapter wraps the Rust FFI and implements the domain interface,
/// allowing the editor to be completely replaced without changing application code.
class NativeEditorRepository implements ICodeEditorRepository {
  final NativeEditorBindings _bindings;
  ffi.Pointer<ffi.Void>? _editorHandle;

  EditorDocument? _currentDocument;

  // Event controllers
  final _contentChangedController = StreamController<String>.broadcast();
  final _cursorPositionChangedController = StreamController<CursorPosition>.broadcast();
  final _selectionChangedController = StreamController<TextSelection>.broadcast();
  final _focusChangedController = StreamController<bool>.broadcast();

  NativeEditorRepository() : _bindings = NativeEditorBindings();

  // ================================================================
  // Lifecycle
  // ================================================================

  @override
  Future<Either<EditorFailure, Unit>> initialize() async {
    if (_editorHandle != null) {
      return right(unit);
    }

    try {
      _editorHandle = _bindings.editorNew();

      if (_editorHandle == null || _editorHandle == ffi.nullptr) {
        return left(const EditorFailure.notInitialized(
          message: 'Failed to create native editor',
        ));
      }

      return right(unit);
    } catch (e) {
      return left(EditorFailure.unexpected(
        message: 'Failed to initialize editor',
        error: e,
      ));
    }
  }

  @override
  bool get isReady => _editorHandle != null && _editorHandle != ffi.nullptr;

  @override
  Future<void> dispose() async {
    if (_editorHandle != null && _editorHandle != ffi.nullptr) {
      _bindings.editorFree(_editorHandle!);
      _editorHandle = null;
    }

    await _contentChangedController.close();
    await _cursorPositionChangedController.close();
    await _selectionChangedController.close();
    await _focusChangedController.close();
  }

  // ================================================================
  // Document Management
  // ================================================================

  @override
  Future<Either<EditorFailure, Unit>> openDocument(EditorDocument document) async {
    if (!isReady) {
      return left(const EditorFailure.notInitialized());
    }

    try {
      final contentPtr = document.content.toNativeUtf8();
      final languagePtr = document.languageId.value.toNativeUtf8();

      final result = _bindings.editorSetContent(_editorHandle!, contentPtr.cast());
      final langResult = _bindings.editorSetLanguage(_editorHandle!, languagePtr.cast());

      malloc.free(contentPtr);
      malloc.free(languagePtr);

      final resultCode = NativeResultCode.fromCode(result);
      final langResultCode = NativeResultCode.fromCode(langResult);

      if (!resultCode.isSuccess || !langResultCode.isSuccess) {
        return left(const EditorFailure.operationFailed(
          operation: 'openDocument',
          reason: 'Failed to set content or language',
        ));
      }

      _currentDocument = document;
      return right(unit);
    } catch (e) {
      return left(EditorFailure.operationFailed(
        operation: 'openDocument',
        reason: e.toString(),
      ));
    }
  }

  @override
  Future<Either<EditorFailure, String>> getContent() async {
    if (!isReady) {
      return left(const EditorFailure.notInitialized());
    }

    try {
      final contentPtr = _bindings.editorGetContent(_editorHandle!);

      if (contentPtr == ffi.nullptr) {
        return left(const EditorFailure.operationFailed(
          operation: 'getContent',
          reason: 'Received null pointer from native',
        ));
      }

      final content = contentPtr.cast<Utf8>().toDartString();
      _bindings.editorFreeString(contentPtr.cast());

      return right(content);
    } catch (e) {
      return left(EditorFailure.operationFailed(
        operation: 'getContent',
        reason: e.toString(),
      ));
    }
  }

  @override
  Future<Either<EditorFailure, Unit>> setContent(String content) async {
    if (!isReady) {
      return left(const EditorFailure.notInitialized());
    }

    try {
      final contentPtr = content.toNativeUtf8();
      final result = _bindings.editorSetContent(_editorHandle!, contentPtr.cast());
      malloc.free(contentPtr);

      final resultCode = NativeResultCode.fromCode(result);

      if (!resultCode.isSuccess) {
        return left(const EditorFailure.operationFailed(
          operation: 'setContent',
        ));
      }

      // Update current document if exists
      if (_currentDocument != null) {
        _currentDocument = _currentDocument!.updateContent(content);
      }

      // Emit content changed event
      _contentChangedController.add(content);

      return right(unit);
    } catch (e) {
      return left(EditorFailure.operationFailed(
        operation: 'setContent',
        reason: e.toString(),
      ));
    }
  }

  @override
  Future<Either<EditorFailure, EditorDocument>> getCurrentDocument() async {
    if (_currentDocument == null) {
      return left(const EditorFailure.documentNotFound());
    }
    return right(_currentDocument!);
  }

  @override
  Future<Either<EditorFailure, Unit>> closeDocument() async {
    _currentDocument = null;
    return right(unit);
  }

  // ================================================================
  // Language & Syntax
  // ================================================================

  @override
  Future<Either<EditorFailure, Unit>> setLanguage(LanguageId languageId) async {
    if (!isReady) {
      return left(const EditorFailure.notInitialized());
    }

    try {
      final languagePtr = languageId.value.toNativeUtf8();
      final result = _bindings.editorSetLanguage(_editorHandle!, languagePtr.cast());
      malloc.free(languagePtr);

      final resultCode = NativeResultCode.fromCode(result);

      if (!resultCode.isSuccess) {
        return left(const EditorFailure.operationFailed(
          operation: 'setLanguage',
        ));
      }

      return right(unit);
    } catch (e) {
      return left(EditorFailure.operationFailed(
        operation: 'setLanguage',
        reason: e.toString(),
      ));
    }
  }

  @override
  Future<Either<EditorFailure, LanguageId>> getLanguage() async {
    if (_currentDocument == null) {
      return left(const EditorFailure.documentNotFound());
    }
    return right(_currentDocument!.languageId);
  }

  // ================================================================
  // Theme & Appearance
  // ================================================================

  @override
  Future<Either<EditorFailure, Unit>> setTheme(EditorTheme theme) async {
    // Theme handling will be implemented with renderer
    return right(unit);
  }

  @override
  Future<Either<EditorFailure, EditorTheme>> getTheme() async {
    return left(const EditorFailure.unsupportedOperation(
      operation: 'getTheme',
    ));
  }

  // ================================================================
  // Cursor & Selection
  // ================================================================

  @override
  Future<Either<EditorFailure, CursorPosition>> getCursorPosition() async {
    if (!isReady) {
      return left(const EditorFailure.notInitialized());
    }

    try {
      final linePtr = malloc<ffi.Size>();
      final columnPtr = malloc<ffi.Size>();

      final result = _bindings.editorGetCursor(_editorHandle!, linePtr, columnPtr);

      final line = linePtr.value;
      final column = columnPtr.value;

      malloc.free(linePtr);
      malloc.free(columnPtr);

      final resultCode = NativeResultCode.fromCode(result);

      if (!resultCode.isSuccess) {
        return left(const EditorFailure.operationFailed(
          operation: 'getCursorPosition',
        ));
      }

      return right(CursorPosition.create(line: line, column: column));
    } catch (e) {
      return left(EditorFailure.operationFailed(
        operation: 'getCursorPosition',
        reason: e.toString(),
      ));
    }
  }

  @override
  Future<Either<EditorFailure, Unit>> setCursorPosition(CursorPosition position) async {
    if (!isReady) {
      return left(const EditorFailure.notInitialized());
    }

    try {
      final result = _bindings.editorMoveCursor(_editorHandle!, position.line, position.column);
      final resultCode = NativeResultCode.fromCode(result);

      if (!resultCode.isSuccess) {
        return left(const EditorFailure.operationFailed(
          operation: 'setCursorPosition',
        ));
      }

      _cursorPositionChangedController.add(position);

      return right(unit);
    } catch (e) {
      return left(EditorFailure.operationFailed(
        operation: 'setCursorPosition',
        reason: e.toString(),
      ));
    }
  }

  @override
  Future<Either<EditorFailure, TextSelection>> getSelection() async {
    // TODO: Implement when needed
    return left(const EditorFailure.unsupportedOperation(
      operation: 'getSelection',
    ));
  }

  @override
  Future<Either<EditorFailure, Unit>> setSelection(TextSelection selection) async {
    if (!isReady) {
      return left(const EditorFailure.notInitialized());
    }

    try {
      final result = _bindings.editorSetSelection(
        _editorHandle!,
        selection.start.line,
        selection.start.column,
        selection.end.line,
        selection.end.column,
      );

      final resultCode = NativeResultCode.fromCode(result);

      if (!resultCode.isSuccess) {
        return left(const EditorFailure.operationFailed(
          operation: 'setSelection',
        ));
      }

      _selectionChangedController.add(selection);

      return right(unit);
    } catch (e) {
      return left(EditorFailure.operationFailed(
        operation: 'setSelection',
        reason: e.toString(),
      ));
    }
  }

  // ================================================================
  // Text Operations
  // ================================================================

  @override
  Future<Either<EditorFailure, Unit>> insertText(String text) async {
    if (!isReady) {
      return left(const EditorFailure.notInitialized());
    }

    try {
      final textPtr = text.toNativeUtf8();
      final result = _bindings.editorInsertText(_editorHandle!, textPtr.cast());
      malloc.free(textPtr);

      final resultCode = NativeResultCode.fromCode(result);

      if (!resultCode.isSuccess) {
        return left(const EditorFailure.operationFailed(
          operation: 'insertText',
        ));
      }

      // Get updated content and emit event
      final contentResult = await getContent();
      contentResult.fold(
        (_) {},
        (content) => _contentChangedController.add(content),
      );

      return right(unit);
    } catch (e) {
      return left(EditorFailure.operationFailed(
        operation: 'insertText',
        reason: e.toString(),
      ));
    }
  }

  @override
  Future<Either<EditorFailure, Unit>> replaceText({
    required CursorPosition start,
    required CursorPosition end,
    required String text,
  }) async {
    // Set selection, delete, insert
    await setSelection(TextSelection(start: start, end: end));

    final deleteResult = _bindings.editorDelete(_editorHandle!);
    if (!NativeResultCode.fromCode(deleteResult).isSuccess) {
      return left(const EditorFailure.operationFailed(operation: 'delete'));
    }

    return insertText(text);
  }

  @override
  Future<Either<EditorFailure, Unit>> formatDocument() async {
    // Formatting will be done via LSP
    return left(const EditorFailure.unsupportedOperation(
      operation: 'formatDocument - use LSP',
    ));
  }

  // ================================================================
  // Editor Actions
  // ================================================================

  @override
  Future<Either<EditorFailure, Unit>> undo() async {
    if (!isReady) {
      return left(const EditorFailure.notInitialized());
    }

    final result = _bindings.editorUndo(_editorHandle!);

    if (result == 1) {
      // Undo successful, emit content changed
      final contentResult = await getContent();
      contentResult.fold(
        (_) {},
        (content) => _contentChangedController.add(content),
      );
      return right(unit);
    } else if (result == 0) {
      return left(const EditorFailure.operationFailed(
        operation: 'undo',
        reason: 'Nothing to undo',
      ));
    } else {
      return left(const EditorFailure.operationFailed(operation: 'undo'));
    }
  }

  @override
  Future<Either<EditorFailure, Unit>> redo() async {
    if (!isReady) {
      return left(const EditorFailure.notInitialized());
    }

    final result = _bindings.editorRedo(_editorHandle!);

    if (result == 1) {
      final contentResult = await getContent();
      contentResult.fold(
        (_) {},
        (content) => _contentChangedController.add(content),
      );
      return right(unit);
    } else if (result == 0) {
      return left(const EditorFailure.operationFailed(
        operation: 'redo',
        reason: 'Nothing to redo',
      ));
    } else {
      return left(const EditorFailure.operationFailed(operation: 'redo'));
    }
  }

  @override
  Future<Either<EditorFailure, Unit>> find(String searchText) async {
    return left(const EditorFailure.unsupportedOperation(operation: 'find'));
  }

  @override
  Future<Either<EditorFailure, Unit>> replace({
    required String searchText,
    required String replaceText,
  }) async {
    return left(const EditorFailure.unsupportedOperation(operation: 'replace'));
  }

  // ================================================================
  // Navigation
  // ================================================================

  @override
  Future<Either<EditorFailure, Unit>> scrollToLine(int lineNumber) async {
    // Will be implemented with renderer
    return right(unit);
  }

  @override
  Future<Either<EditorFailure, Unit>> revealLine(int lineNumber) async {
    return scrollToLine(lineNumber);
  }

  @override
  Future<Either<EditorFailure, Unit>> focus() async {
    _focusChangedController.add(true);
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
}
