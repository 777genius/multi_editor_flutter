# TODO/FIXME Tracker Plugin

Tracks TODO, FIXME, HACK, NOTE, XXX, BUG, OPTIMIZE, and REVIEW comments in your source code.

## Features

- **Hybrid Performance**: Uses Dart for small files (< 5000 lines) and Rust WASM for large files
- **Multiple Markers**: Supports TODO, FIXME, HACK, NOTE, XXX, BUG, OPTIMIZE, REVIEW
- **Author Extraction**: Detects authors in format `TODO(john): ...`
- **Tag Extraction**: Extracts tags like `TODO #bug #critical: ...`
- **Priority Detection**: Auto-detects priority from `!!!`, `!!`, `!` markers
- **Real-time Scanning**: Updates as you type (debounced)
- **UI Integration**: Shows TODOs in sidebar panel

## Supported Formats

```dart
// TODO: simple todo
// TODO(john): todo with author
// TODO #bug #critical: todo with tags
// TODO !!! urgent: high priority todo
// FIXME: needs fixing
// HACK: temporary solution
// NOTE: important note
// XXX: warning
// BUG: known bug
// OPTIMIZE: needs optimization
// REVIEW: needs code review
```

## Priority Levels

- **High**: FIXME, BUG, or any TODO with `!!!` or `!!`
- **Medium**: TODO, HACK, OPTIMIZE, REVIEW, or TODOs with `!`
- **Low**: NOTE, XXX

## Architecture

- **Domain**: `TodoItem`, `TodoCollection` entities
- **Infrastructure**: Hybrid scanner (Dart + WASM backend)
- **WASM Backend**: `/packages/wasm_plugins/todo_scanner_wasm/`

## Performance

- **Small files (< 5000 lines)**: ~1-5ms (Dart regex)
- **Large files (>= 5000 lines)**: ~5-20ms (Rust WASM)

## Usage

```dart
final plugin = TodoTrackerPlugin();
await pluginManager.registerPlugin(plugin);

// Access current file's TODOs
final todos = plugin.currentTodos;
print('Found ${todos?.items.length} TODOs');
```
