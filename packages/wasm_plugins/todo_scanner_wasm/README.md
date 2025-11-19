# TODO Scanner WASM Plugin

Fast TODO/FIXME/HACK comment scanner implemented in Rust and compiled to WebAssembly for high performance.

## Features

- **Fast scanning**: Optimized regex-based scanning for large files (10MB+)
- **Multiple markers**: Supports TODO, FIXME, HACK, NOTE, XXX, BUG, OPTIMIZE, REVIEW
- **Author extraction**: Extracts author from comments like `TODO(john): ...`
- **Tag extraction**: Extracts tags from comments like `TODO #bug #critical: ...`
- **Priority detection**: Detects priority from `!!!`, `!!`, `!` markers
- **Multi-language support**: Works with all common programming languages

## Architecture

Follows **Clean Architecture** principles:

```
Presentation (lib.rs - WASM exports)
    ↓
Application (use_cases.rs - business logic orchestration)
    ↓
Domain (entities.rs, value_objects.rs - core business logic)
    ↑
Infrastructure (scanner.rs - regex implementation)
```

## Building

```bash
# Make build script executable
chmod +x build.sh

# Build the WASM plugin
./build.sh
```

Output: `build/todo_scanner_wasm.wasm`

## Usage

### From Dart

```dart
// Use through the TodoTrackerPlugin (Dart wrapper)
// See: app/modules/plugins/multi_editor_plugin_todo_tracker
```

### Direct WASM API

```javascript
// Initialize
plugin_initialize()

// Scan for TODOs
const request = {
  event_type: "scan_todos",
  data: {
    request_id: "scan-1",
    content: "// TODO: implement this\n// FIXME: fix bug",
    file_extension: "dart"
  }
}

const response = plugin_handle_event(request)

// Response format:
{
  request_id: "scan-1",
  success: true,
  data: {
    items: [
      {
        todo_type: "TODO",
        priority: "medium",
        text: "implement this",
        line: 0,
        column: 3,
        author: null,
        tags: []
      }
    ],
    counts_by_type: { todo: 1, fixme: 1, ... },
    counts_by_priority: { high: 0, medium: 2, low: 0 },
    scan_duration_ms: 5
  }
}
```

## Supported TODO Formats

```dart
// TODO: simple todo
// TODO(john): todo with author
// TODO[john]: alternative author format
// TODO #bug #critical: todo with tags
// TODO !!! urgent: high priority
// FIXME: fix this bug
// HACK: temporary solution
// NOTE: important note
// XXX: warning
// BUG: known bug
// OPTIMIZE: needs optimization
// REVIEW: needs code review
```

## Performance

- **Typical scan time**: 5-20ms for 10,000 lines
- **Max file size**: 10MB
- **Memory efficient**: Regex-based scanning with minimal allocations

## Testing

```bash
cargo test
```
