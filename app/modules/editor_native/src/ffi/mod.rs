use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::ptr;
use crate::editor::{Editor, Position, Selection, LanguageId};

/// Opaque pointer to Editor (for FFI safety)
type EditorHandle = *mut Editor;

/// FFI Result codes
#[repr(C)]
pub enum ResultCode {
    Success = 0,
    ErrorNull = -1,
    ErrorInvalidUtf8 = -2,
    ErrorOutOfBounds = -3,
    ErrorUnknown = -4,
}

// ==================================================================
// Lifecycle Management
// ==================================================================

/// Creates a new editor instance
///
/// # Safety
/// Returns an opaque pointer that must be freed with `editor_free()`
#[no_mangle]
pub unsafe extern "C" fn editor_new() -> EditorHandle {
    Box::into_raw(Box::new(Editor::new()))
}

/// Creates an editor with initial content
///
/// # Safety
/// - `content` must be a valid C string
/// - `language_id` must be a valid C string
/// - Returns an opaque pointer that must be freed with `editor_free()`
#[no_mangle]
pub unsafe extern "C" fn editor_with_content(
    content: *const c_char,
    language_id: *const c_char,
) -> EditorHandle {
    if content.is_null() || language_id.is_null() {
        return ptr::null_mut();
    }

    let content_str = match CStr::from_ptr(content).to_str() {
        Ok(s) => s,
        Err(_) => return ptr::null_mut(),
    };

    let language_str = match CStr::from_ptr(language_id).to_str() {
        Ok(s) => s,
        Err(_) => return ptr::null_mut(),
    };

    let language = LanguageId::parse(language_str);

    match Editor::with_content(content_str, language) {
        Ok(editor) => Box::into_raw(Box::new(editor)),
        Err(_) => ptr::null_mut(),
    }
}

/// Frees an editor instance
///
/// # Safety
/// - `handle` must be a valid pointer returned by `editor_new()`
/// - Must not be used after calling this function
#[no_mangle]
pub unsafe extern "C" fn editor_free(handle: EditorHandle) {
    if !handle.is_null() {
        drop(Box::from_raw(handle));
    }
}

// ==================================================================
// Content Operations
// ==================================================================

/// Gets the editor content
///
/// # Safety
/// - `handle` must be a valid editor pointer
/// - Caller must free the returned string with `editor_free_string()`
#[no_mangle]
pub unsafe extern "C" fn editor_get_content(handle: EditorHandle) -> *mut c_char {
    if handle.is_null() {
        return ptr::null_mut();
    }

    let editor = &*handle;
    let content = editor.content();

    match CString::new(content) {
        Ok(c_str) => c_str.into_raw(),
        Err(_) => ptr::null_mut(),
    }
}

/// Sets the editor content
///
/// # Safety
/// - `handle` must be a valid editor pointer
/// - `content` must be a valid C string
#[no_mangle]
pub unsafe extern "C" fn editor_set_content(
    handle: EditorHandle,
    content: *const c_char,
) -> ResultCode {
    if handle.is_null() || content.is_null() {
        return ResultCode::ErrorNull;
    }

    let editor = &mut *handle;

    let content_str = match CStr::from_ptr(content).to_str() {
        Ok(s) => s,
        Err(_) => return ResultCode::ErrorInvalidUtf8,
    };

    match editor.set_content(content_str) {
        Ok(_) => ResultCode::Success,
        Err(_) => ResultCode::ErrorUnknown,
    }
}

/// Inserts text at the current cursor position
///
/// # Safety
/// - `handle` must be a valid editor pointer
/// - `text` must be a valid C string
#[no_mangle]
pub unsafe extern "C" fn editor_insert_text(
    handle: EditorHandle,
    text: *const c_char,
) -> ResultCode {
    if handle.is_null() || text.is_null() {
        return ResultCode::ErrorNull;
    }

    let editor = &mut *handle;

    let text_str = match CStr::from_ptr(text).to_str() {
        Ok(s) => s,
        Err(_) => return ResultCode::ErrorInvalidUtf8,
    };

    match editor.insert_text(text_str) {
        Ok(_) => ResultCode::Success,
        Err(_) => ResultCode::ErrorUnknown,
    }
}

/// Deletes the current selection or character at cursor
///
/// # Safety
/// - `handle` must be a valid editor pointer
#[no_mangle]
pub unsafe extern "C" fn editor_delete(handle: EditorHandle) -> ResultCode {
    if handle.is_null() {
        return ResultCode::ErrorNull;
    }

    let editor = &mut *handle;

    match editor.delete() {
        Ok(_) => ResultCode::Success,
        Err(_) => ResultCode::ErrorUnknown,
    }
}

// ==================================================================
// Cursor & Selection
// ==================================================================

/// Gets the current cursor position
///
/// # Safety
/// - `handle` must be a valid editor pointer
/// - `out_line` and `out_column` must be valid pointers
#[no_mangle]
pub unsafe extern "C" fn editor_get_cursor(
    handle: EditorHandle,
    out_line: *mut usize,
    out_column: *mut usize,
) -> ResultCode {
    if handle.is_null() || out_line.is_null() || out_column.is_null() {
        return ResultCode::ErrorNull;
    }

    let editor = &*handle;
    let cursor = editor.cursor();

    *out_line = cursor.line;
    *out_column = cursor.column;

    ResultCode::Success
}

/// Moves the cursor to a position
///
/// # Safety
/// - `handle` must be a valid editor pointer
#[no_mangle]
pub unsafe extern "C" fn editor_move_cursor(
    handle: EditorHandle,
    line: usize,
    column: usize,
) -> ResultCode {
    if handle.is_null() {
        return ResultCode::ErrorNull;
    }

    let editor = &mut *handle;
    editor.move_cursor(Position::new(line, column));

    ResultCode::Success
}

/// Sets the selection range
///
/// # Safety
/// - `handle` must be a valid editor pointer
#[no_mangle]
pub unsafe extern "C" fn editor_set_selection(
    handle: EditorHandle,
    start_line: usize,
    start_column: usize,
    end_line: usize,
    end_column: usize,
) -> ResultCode {
    if handle.is_null() {
        return ResultCode::ErrorNull;
    }

    let editor = &mut *handle;
    let selection = Selection::new(
        Position::new(start_line, start_column),
        Position::new(end_line, end_column),
    );

    editor.set_selection(selection);
    ResultCode::Success
}

/// Clears the current selection
///
/// # Safety
/// - `handle` must be a valid editor pointer
#[no_mangle]
pub unsafe extern "C" fn editor_clear_selection(handle: EditorHandle) -> ResultCode {
    if handle.is_null() {
        return ResultCode::ErrorNull;
    }

    let editor = &mut *handle;
    editor.clear_selection();

    ResultCode::Success
}

// ==================================================================
// Undo/Redo
// ==================================================================

/// Undoes the last edit
///
/// # Safety
/// - `handle` must be a valid editor pointer
/// Returns 1 if undo was performed, 0 if undo stack is empty
#[no_mangle]
pub unsafe extern "C" fn editor_undo(handle: EditorHandle) -> i32 {
    if handle.is_null() {
        return -1;
    }

    let editor = &mut *handle;

    match editor.undo() {
        Ok(true) => 1,
        Ok(false) => 0,
        Err(_) => -1,
    }
}

/// Redoes the last undone edit
///
/// # Safety
/// - `handle` must be a valid editor pointer
/// Returns 1 if redo was performed, 0 if redo stack is empty
#[no_mangle]
pub unsafe extern "C" fn editor_redo(handle: EditorHandle) -> i32 {
    if handle.is_null() {
        return -1;
    }

    let editor = &mut *handle;

    match editor.redo() {
        Ok(true) => 1,
        Ok(false) => 0,
        Err(_) => -1,
    }
}

// ==================================================================
// Language
// ==================================================================

/// Sets the programming language for syntax highlighting
///
/// # Safety
/// - `handle` must be a valid editor pointer
/// - `language_id` must be a valid C string
#[no_mangle]
pub unsafe extern "C" fn editor_set_language(
    handle: EditorHandle,
    language_id: *const c_char,
) -> ResultCode {
    if handle.is_null() || language_id.is_null() {
        return ResultCode::ErrorNull;
    }

    let editor = &mut *handle;

    let language_str = match CStr::from_ptr(language_id).to_str() {
        Ok(s) => s,
        Err(_) => return ResultCode::ErrorInvalidUtf8,
    };

    let language = LanguageId::parse(language_str);

    match editor.set_language(language) {
        Ok(_) => ResultCode::Success,
        Err(_) => ResultCode::ErrorUnknown,
    }
}

// ==================================================================
// Metadata
// ==================================================================

/// Gets the number of lines in the editor
///
/// # Safety
/// - `handle` must be a valid editor pointer
#[no_mangle]
pub unsafe extern "C" fn editor_line_count(handle: EditorHandle) -> usize {
    if handle.is_null() {
        return 0;
    }

    let editor = &*handle;
    editor.line_count()
}

/// Gets a specific line content
///
/// # Safety
/// - `handle` must be a valid editor pointer
/// - Caller must free the returned string with `editor_free_string()`
#[no_mangle]
pub unsafe extern "C" fn editor_get_line(
    handle: EditorHandle,
    line_index: usize,
) -> *mut c_char {
    if handle.is_null() {
        return ptr::null_mut();
    }

    let editor = &*handle;

    match editor.line(line_index) {
        Some(line) => match CString::new(line) {
            Ok(c_str) => c_str.into_raw(),
            Err(_) => ptr::null_mut(),
        },
        None => ptr::null_mut(),
    }
}

/// Checks if the editor has unsaved changes
///
/// # Safety
/// - `handle` must be a valid editor pointer
/// Returns 1 if dirty, 0 if not
#[no_mangle]
pub unsafe extern "C" fn editor_is_dirty(handle: EditorHandle) -> i32 {
    if handle.is_null() {
        return 0;
    }

    let editor = &*handle;
    if editor.is_dirty() {
        1
    } else {
        0
    }
}

/// Marks the editor as saved
///
/// # Safety
/// - `handle` must be a valid editor pointer
#[no_mangle]
pub unsafe extern "C" fn editor_mark_saved(handle: EditorHandle) -> ResultCode {
    if handle.is_null() {
        return ResultCode::ErrorNull;
    }

    let editor = &mut *handle;
    editor.mark_saved();

    ResultCode::Success
}

// ==================================================================
// Memory Management
// ==================================================================

/// Frees a C string returned by the editor
///
/// # Safety
/// - `ptr` must be a string returned by an editor function
/// - Must not be used after calling this function
#[no_mangle]
pub unsafe extern "C" fn editor_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        drop(CString::from_raw(ptr));
    }
}

#[cfg(test)]
mod tests;
