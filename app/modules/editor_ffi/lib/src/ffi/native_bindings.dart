import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

/// Opaque pointer to native Editor
typedef EditorHandle = ffi.Pointer<ffi.Void>;

/// Result codes from native operations
enum NativeResultCode {
  success(0),
  errorNull(-1),
  errorInvalidUtf8(-2),
  errorOutOfBounds(-3),
  errorUnknown(-4);

  final int code;
  const NativeResultCode(this.code);

  factory NativeResultCode.fromCode(int code) {
    return values.firstWhere(
      (e) => e.code == code,
      orElse: () => NativeResultCode.errorUnknown,
    );
  }

  bool get isSuccess => this == NativeResultCode.success;
}

/// Native FFI bindings to Rust editor
class NativeEditorBindings {
  final ffi.DynamicLibrary _lib;

  NativeEditorBindings() : _lib = _loadLibrary();

  /// Loads the native library
  static ffi.DynamicLibrary _loadLibrary() {
    if (Platform.isMacOS) {
      return ffi.DynamicLibrary.open('libeditor_native.dylib');
    } else if (Platform.isLinux) {
      return ffi.DynamicLibrary.open('libeditor_native.so');
    } else if (Platform.isWindows) {
      return ffi.DynamicLibrary.open('editor_native.dll');
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }

  // ================================================================
  // Lifecycle
  // ================================================================

  late final editorNew = _lib
      .lookup<ffi.NativeFunction<EditorHandle Function()>>('editor_new')
      .asFunction<EditorHandle Function()>();

  late final editorWithContent = _lib
      .lookup<
          ffi.NativeFunction<
              EditorHandle Function(
                  ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>)>>('editor_with_content')
      .asFunction<EditorHandle Function(ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>)>();

  late final editorFree = _lib
      .lookup<ffi.NativeFunction<ffi.Void Function(EditorHandle)>>('editor_free')
      .asFunction<void Function(EditorHandle)>();

  // ================================================================
  // Content Operations
  // ================================================================

  late final editorGetContent = _lib
      .lookup<
          ffi.NativeFunction<
              ffi.Pointer<ffi.Char> Function(EditorHandle)>>('editor_get_content')
      .asFunction<ffi.Pointer<ffi.Char> Function(EditorHandle)>();

  late final editorSetContent = _lib
      .lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(EditorHandle,
                  ffi.Pointer<ffi.Char>)>>('editor_set_content')
      .asFunction<int Function(EditorHandle, ffi.Pointer<ffi.Char>)>();

  late final editorInsertText = _lib
      .lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(EditorHandle,
                  ffi.Pointer<ffi.Char>)>>('editor_insert_text')
      .asFunction<int Function(EditorHandle, ffi.Pointer<ffi.Char>)>();

  late final editorDelete = _lib
      .lookup<ffi.NativeFunction<ffi.Int32 Function(EditorHandle)>>('editor_delete')
      .asFunction<int Function(EditorHandle)>();

  // ================================================================
  // Cursor & Selection
  // ================================================================

  late final editorGetCursor = _lib
      .lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(EditorHandle, ffi.Pointer<ffi.Size>,
                  ffi.Pointer<ffi.Size>)>>('editor_get_cursor')
      .asFunction<
          int Function(
              EditorHandle, ffi.Pointer<ffi.Size>, ffi.Pointer<ffi.Size>)>();

  late final editorMoveCursor = _lib
      .lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(
                  EditorHandle, ffi.Size, ffi.Size)>>('editor_move_cursor')
      .asFunction<int Function(EditorHandle, int, int)>();

  late final editorSetSelection = _lib
      .lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(EditorHandle, ffi.Size, ffi.Size, ffi.Size,
                  ffi.Size)>>('editor_set_selection')
      .asFunction<int Function(EditorHandle, int, int, int, int)>();

  late final editorClearSelection = _lib
      .lookup<ffi.NativeFunction<ffi.Int32 Function(EditorHandle)>>(
          'editor_clear_selection')
      .asFunction<int Function(EditorHandle)>();

  // ================================================================
  // Undo/Redo
  // ================================================================

  late final editorUndo = _lib
      .lookup<ffi.NativeFunction<ffi.Int32 Function(EditorHandle)>>('editor_undo')
      .asFunction<int Function(EditorHandle)>();

  late final editorRedo = _lib
      .lookup<ffi.NativeFunction<ffi.Int32 Function(EditorHandle)>>('editor_redo')
      .asFunction<int Function(EditorHandle)>();

  // ================================================================
  // Language
  // ================================================================

  late final editorSetLanguage = _lib
      .lookup<
          ffi.NativeFunction<
              ffi.Int32 Function(EditorHandle,
                  ffi.Pointer<ffi.Char>)>>('editor_set_language')
      .asFunction<int Function(EditorHandle, ffi.Pointer<ffi.Char>)>();

  // ================================================================
  // Metadata
  // ================================================================

  late final editorLineCount = _lib
      .lookup<ffi.NativeFunction<ffi.Size Function(EditorHandle)>>('editor_line_count')
      .asFunction<int Function(EditorHandle)>();

  late final editorGetLine = _lib
      .lookup<
          ffi.NativeFunction<
              ffi.Pointer<ffi.Char> Function(
                  EditorHandle, ffi.Size)>>('editor_get_line')
      .asFunction<ffi.Pointer<ffi.Char> Function(EditorHandle, int)>();

  late final editorIsDirty = _lib
      .lookup<ffi.NativeFunction<ffi.Int32 Function(EditorHandle)>>('editor_is_dirty')
      .asFunction<int Function(EditorHandle)>();

  late final editorMarkSaved = _lib
      .lookup<ffi.NativeFunction<ffi.Int32 Function(EditorHandle)>>(
          'editor_mark_saved')
      .asFunction<int Function(EditorHandle)>();

  // ================================================================
  // Memory Management
  // ================================================================

  late final editorFreeString = _lib
      .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Char>)>>(
          'editor_free_string')
      .asFunction<void Function(ffi.Pointer<ffi.Char>)>();
}
