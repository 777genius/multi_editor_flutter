/// FFI bridge between Dart and Rust native editor.
///
/// This package wraps the Rust FFI in a clean Dart API that implements
/// the ICodeEditorRepository interface from editor_core.
library editor_ffi;

export 'src/repository/native_editor_repository.dart';
export 'src/ffi/native_bindings.dart';
