# Markdown Renderer WASM Plugin

**Production-grade Markdown to HTML renderer using pulldown-cmark**

Demonstrates **Clean Architecture + DDD + SOLID + DRY** principles in Rust WASM plugin.

## 📊 Project Statistics

- **Lines of Code**: ~1,500+ Rust
- **Architecture**: 4 layers (Domain → Application → Infrastructure → Presentation)
- **Design Patterns**: Adapter, Repository, Strategy, Factory
- **SOLID Principles**: All 5 implemented
- **DDD Concepts**: Entities, Value Objects, Aggregates, Services, Use Cases
- **Test Coverage**: Unit tests included

## 🎯 Features

### Markdown Rendering
- ✅ **pulldown-cmark** - Industry-standard Rust markdown parser
- ✅ **GitHub Flavored Markdown** - Tables, strikethrough, task lists
- ✅ **Pure Rust** - No C dependencies, perfect for WASM
- ✅ **Fast & Lightweight** - 150KB binary (unoptimized)
- ✅ **Extensible** - Easy to add custom markdown extensions

### Architecture Quality
- ✅ **Clean Architecture** - Clear separation of concerns
- ✅ **DDD** - Rich domain model with entities and value objects
- ✅ **SOLID** - All 5 principles rigorously applied
- ✅ **DRY** - No code duplication
- ✅ **Testable** - Mocked dependencies, unit tests

## 🏗️ Architecture

### Layer Structure

```text
┌─────────────────────────────────────────────────────┐
│        Presentation Layer (lib.rs)                   │
│  - WASM Exports (plugin_* functions)                │
│  - Serialization (MessagePack)                      │
│  - Event handling                                   │
└────────────────────┬────────────────────────────────┘
                     │ calls
┌────────────────────▼────────────────────────────────┐
│        Application Layer (application/)              │
│  - Use Cases (RenderMarkdownUseCase)               │
│  - DTOs (RenderRequest, RenderResponse)            │
│  - Orchestration logic                              │
└────────────────────┬────────────────────────────────┘
                     │ uses
┌────────────────────▼────────────────────────────────┐
│        Domain Layer (domain/)                        │
│  - Entities: MarkdownDocument, HtmlElement         │
│  - Value Objects: MarkdownOptions, HtmlOutput      │
│  - Services (traits): Renderer                     │
│  - Pure business logic                              │
└────────────────────▲────────────────────────────────┘
                     │ implements
┌────────────────────┴────────────────────────────────┐
│        Infrastructure Layer (infrastructure/)        │
│  - PulldownRenderer (implements Renderer)          │
│  - Memory management (alloc/dealloc)               │
└─────────────────────────────────────────────────────┘
```

**Dependency Rule**: Dependencies point inward. Outer layers depend on inner layers, never the reverse.

### Domain Layer

**Entities** (have identity):
- `MarkdownDocument` - Source document (Aggregate Root)
- `HtmlElement` - Rendered HTML element with metadata
- `HtmlElementCollection` - Collection of elements

**Value Objects** (immutable, no identity):
- `MarkdownOptions` - Rendering configuration
- `HtmlOutput` - Rendered HTML with metadata
- `DocumentStatistics` - Document metrics

**Services** (traits/interfaces):
- `Renderer` - Convert markdown → HTML

### Application Layer

**Use Cases**:
- `RenderMarkdownUseCase` - Main orchestration logic
  1. Validate request
  2. Convert DTO to domain model
  3. Render markdown
  4. Collect statistics
  5. Return response

**DTOs**:
- `RenderRequest` - Input for rendering
- `RenderResponse` - Output with HTML
- `RenderOptionsDto` - Serializable options

### Infrastructure Layer

**Adapters**:
- `PulldownRenderer` - Adapts pulldown-cmark to `Renderer` trait

**pulldown-cmark Integration**:
- CommonMark specification
- GitHub Flavored Markdown extensions
- Tables, strikethrough, footnotes
- Task lists support
- Pure Rust implementation

### Presentation Layer

**WASM Exports**:
- `plugin_get_manifest()` - Plugin metadata
- `plugin_initialize()` - Setup
- `plugin_handle_event()` - Process events
- `plugin_dispose()` - Cleanup

## 🔧 SOLID Principles

### 1. Single Responsibility Principle (SRP)

Each class has **one reason to change**:

- `MarkdownDocument` - Represents source document
- `HtmlOutput` - Represents rendered output
- `PulldownRenderer` - Renders markdown
- `RenderMarkdownUseCase` - Orchestrates rendering

### 2. Open/Closed Principle (OCP)

**Open for extension, closed for modification**:

```rust
// Trait (abstraction) - closed for modification
pub trait Renderer {
    fn render(&self, document: &MarkdownDocument) -> Result<HtmlOutput, String>;
}

// Implementations - open for extension
pub struct PulldownRenderer { /* ... */ }
pub struct CustomRenderer { /* ... */ }
```

### 3. Liskov Substitution Principle (LSP)

**Subtypes must be substitutable for their base types**:

```rust
fn render_doc<R: Renderer>(renderer: R, doc: &MarkdownDocument) {
    let output = renderer.render(doc).unwrap();
    // ...
}

// Works with any renderer
render_doc(PulldownRenderer::new(), &doc);
render_doc(CustomRenderer::new(), &doc);
```

### 4. Interface Segregation Principle (ISP)

**Clients shouldn't depend on interfaces they don't use**:

```rust
pub trait Renderer {
    fn render(&self, document: &MarkdownDocument) -> Result<HtmlOutput, String>;
    fn supports_github_flavored_markdown(&self) -> bool { true }
}
// Minimal interface - only what's needed
```

### 5. Dependency Inversion Principle (DIP)

**Depend on abstractions, not concretions**:

```rust
// Use Case depends on abstraction (trait)
pub struct RenderMarkdownUseCase<R: Renderer> {
    renderer: R,  // ← abstraction
}

// Concrete implementation provided at runtime
let use_case = RenderMarkdownUseCase::new(
    PulldownRenderer::new(),  // ← concrete
);
```

## 🚀 Building

### Prerequisites

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Add WASM target
rustup target add wasm32-unknown-unknown

# Optional: wasm-opt for optimization
cargo install wasm-opt
```

### Build

```bash
./build.sh
```

Output: `build/markdown_renderer_wasm.wasm` (~150KB, ~50KB optimized)

### Project Structure

```
markdown_renderer_wasm/
├── Cargo.toml                          # Dependencies
├── build.sh                            # Build script
├── src/
│   ├── lib.rs                         # Presentation Layer
│   ├── domain/                        # Domain Layer
│   │   ├── mod.rs
│   │   ├── entities/
│   │   │   ├── markdown_document.rs  # MarkdownDocument entity
│   │   │   └── html_element.rs       # HtmlElement entity
│   │   ├── value_objects/
│   │   │   ├── markdown_options.rs   # Options config
│   │   │   └── html_output.rs        # HTML output
│   │   └── services/
│   │       └── renderer.rs            # Renderer trait
│   ├── application/                   # Application Layer
│   │   ├── mod.rs
│   │   ├── use_cases/
│   │   │   └── render_markdown.rs    # RenderMarkdownUseCase
│   │   └── dto/
│   │       ├── render_request.rs     # Input DTO
│   │       └── render_response.rs    # Output DTO
│   └── infrastructure/                # Infrastructure Layer
│       ├── mod.rs
│       ├── pulldown_cmark/
│       │   └── pulldown_renderer.rs  # PulldownRenderer
│       └── memory/
│           └── allocator.rs          # WASM memory
└── README.md                          # This file
```

## 💻 Usage from Dart

### Load Plugin

```dart
import 'package:flutter_plugin_system_host/flutter_plugin_system_host.dart';
import 'package:flutter_plugin_system_wasm_run/flutter_plugin_system_wasm_run.dart';

// Create WASM runtime
final wasmRuntime = WasmRunRuntime(
  config: WasmRuntimeConfig(
    maxMemoryPages: 256,  // 16MB
    maxExecutionTime: Duration(seconds: 5),
  ),
);

// Create plugin runtime
final pluginRuntime = WasmPluginRuntime(
  wasmRuntime: wasmRuntime,
  serializer: MessagePackPluginSerializer(),
);

// Load plugin
final plugin = await pluginManager.loadPlugin(
  pluginId: 'plugin.markdown-renderer-wasm',
  source: PluginSource.file(
    path: 'plugins/markdown_renderer_wasm.wasm',
  ),
  runtime: pluginRuntime,
);
```

### Render Markdown

```dart
// Initialize plugin
await plugin.initialize(pluginContext);

// Render markdown
final response = await plugin.handleEvent(
  PluginEvent(
    type: 'render_markdown',
    data: {
      'request_id': 'req-1',
      'markdown': '''
# Hello World

This is **bold** and this is *italic*.

## Code Example

\`\`\`rust
fn main() {
    println!("Hello, world!");
}
\`\`\`

## Table

| Name | Age |
|------|-----|
| Alice | 30 |
| Bob   | 25 |
      ''',
      'options': {
        'enable_gfm': true,
        'enable_tables': true,
        'enable_strikethrough': true,
      },
    },
  ),
);

if (response.handled) {
  final html = response.data['html'] as String;
  final stats = response.data['statistics'];

  print('Rendered HTML: $html');
  print('Render time: ${stats['render_time_ms']}ms');
  print('Elements: ${stats['element_count']}');
}
```

## 🧪 Testing

### Unit Tests

```bash
cargo test
```

Tests included for:
- Value Objects (MarkdownOptions, HtmlOutput)
- Entities (MarkdownDocument, HtmlElement)
- Infrastructure (PulldownRenderer)
- Application (RenderMarkdownUseCase)

### Example Test

```rust
#[test]
fn test_render_markdown() {
    let renderer = PulldownRenderer::new();
    let document = MarkdownDocument::new(
        "doc-1".to_string(),
        "# Hello\n\n**Bold text**".to_string(),
        MarkdownOptions::default(),
    );

    let result = renderer.render(&document);
    assert!(result.is_ok());

    let html = result.unwrap();
    assert!(html.html().contains("<h1>"));
    assert!(html.html().contains("<strong>"));
}
```

## 📈 Performance

| Metric | Value |
|--------|-------|
| Binary size | ~150KB (unoptimized) |
| Binary size (optimized) | ~50KB (with wasm-opt) |
| Load time | <10ms |
| Render time | ~1-5ms (small doc) |
| Memory usage | <1MB |
| Supported features | GFM, tables, footnotes, strikethrough, task lists |

## 🌟 Use Cases

### Code Editor
- Markdown preview panel
- README rendering
- Documentation preview

### Note-taking App
- Real-time markdown rendering
- Export to HTML

### Blog Platform
- Convert markdown posts to HTML
- Static site generation

### Documentation Tool
- Render technical documentation
- API documentation

## 🔗 Related

- [Plugin System Architecture](../../../docs/PLUGIN_SYSTEM_ARCHITECTURE.md)
- [flutter_plugin_system_core](../../../packages/flutter_plugin_system_core/)
- [flutter_plugin_system_wasm](../../../packages/flutter_plugin_system_wasm/)
- [flutter_plugin_system_wasm_run](../../../packages/flutter_plugin_system_wasm_run/)
- [syntax_highlighter_wasm example](../syntax_highlighter_wasm/) - Companion plugin
- [file_icons_wasm example](../file_icons_wasm/) - Simpler example

## 📚 Learning Resources

### Clean Architecture
- Robert C. Martin - "Clean Architecture"
- [Clean Architecture Blog](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

### Domain-Driven Design
- Eric Evans - "Domain-Driven Design"
- Vaughn Vernon - "Implementing Domain-Driven Design"

### SOLID Principles
- Robert C. Martin - "Agile Software Development: Principles, Patterns, and Practices"

### pulldown-cmark
- [pulldown-cmark Documentation](https://docs.rs/pulldown-cmark/)
- [CommonMark Specification](https://commonmark.org/)
- [GitHub Flavored Markdown](https://github.github.com/gfm/)

## 📝 License

MIT License - see [LICENSE](../../../LICENSE)

---

**Built with ❤️ following Clean Architecture, DDD, and SOLID principles**
