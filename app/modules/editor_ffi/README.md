# Editor FFI Bridge

Dart FFI bridge for the native Rust editor.

## Purpose

This module wraps the Rust editor's C FFI in a clean Dart API that implements `ICodeEditorRepository` from `editor_core`.

## Architecture

```
Domain (editor_core)
    ↓ implements
FFI Bridge (editor_ffi)
    ├── NativeEditorRepository (Dart wrapper)
    ├── NativeEditorBindings (FFI bindings)
    └── FFI layer
        ↓
Rust Editor (editor_native)
```

## Usage

```dart
import 'package:editor_ffi/editor_ffi.dart';
import 'package:editor_core/editor_core.dart';

// Create repository
final repository = NativeEditorRepository();

// Initialize
await repository.initialize();

// Open document
final document = EditorDocument(
  uri: DocumentUri.fromFilePath('/path/to/file.dart'),
  content: 'void main() {}',
  languageId: LanguageId.dart,
  lastModified: DateTime.now(),
);

await repository.openDocument(document);

// Insert text (fast!)
await repository.insertText('print("Hello, Rust!");');

// Get content
final result = await repository.getContent();
result.fold(
  (failure) => print('Error: $failure'),
  (content) => print('Content: $content'),
);

// Undo
await repository.undo();

// Dispose
await repository.dispose();
```

## Platform Support

| Platform | Library | Status |
|----------|---------|--------|
| **macOS** | libeditor_native.dylib | ✅ Supported |
| **Linux** | libeditor_native.so | ✅ Supported |
| **Windows** | editor_native.dll | ✅ Supported |
| **Web** | WASM | ⏳ Future |

## Deployment

1. **Build Rust library:**
   ```bash
   cd ../editor_native
   cargo build --release
   ```

2. **Copy to assets:**
   ```bash
   # macOS
   cp target/release/libeditor_native.dylib lib/native/macos/

   # Linux
   cp target/release/libeditor_native.so lib/native/linux/

   # Windows
   cp target/release/editor_native.dll lib/native/windows/
   ```

3. **Bundle with Flutter app:**
   The native library will be included in the app bundle automatically.

## Testing

```dart
test('NativeEditorRepository inserts text correctly', () async {
  final repository = NativeEditorRepository();
  await repository.initialize();

  await repository.setContent('Hello');
  await repository.insertText(', Rust!');

  final content = await repository.getContent();
  expect(content.getOrElse(() => ''), equals('Hello, Rust!'));

  await repository.dispose();
});
```

## Error Handling

All operations return `Either<EditorFailure, T>` for type-safe error handling:

```dart
final result = await repository.insertText('test');

result.fold(
  (failure) => failure.map(
    notInitialized: (_) => print('Editor not initialized'),
    operationFailed: (f) => print('Operation failed: ${f.reason}'),
    // ... other failure cases
  ),
  (_) => print('Success!'),
);
```

## Performance

FFI overhead is minimal (~50-200μs per call), which is negligible compared to editor operations.

---

**Bridges Dart ↔ Rust** 🌉
