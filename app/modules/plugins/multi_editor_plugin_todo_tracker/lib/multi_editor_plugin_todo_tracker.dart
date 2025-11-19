/// TODO/FIXME Tracker Plugin
///
/// Tracks TODO, FIXME, HACK, NOTE, XXX, BUG, OPTIMIZE, REVIEW comments in source code.
/// Uses hybrid approach:
/// - Dart regex for small files (< 5000 lines)
/// - Rust WASM backend for large files (>= 5000 lines)
library multi_editor_plugin_todo_tracker;

export 'src/domain/entities/todo_item.dart';
export 'src/infrastructure/plugin/todo_tracker_plugin.dart';
