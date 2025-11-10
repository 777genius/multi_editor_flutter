# Syntax Highlighter WASM Plugin

**Production-grade syntax highlighter using Syntect (TextMate grammars)**

Demonstrates **Clean Architecture + DDD + SOLID + DRY** principles in Rust WASM plugin.

## 📊 Project Statistics

- **Lines of Code**: ~2,000+ Rust
- **Architecture**: 4 layers (Domain → Application → Infrastructure → Presentation)
- **Design Patterns**: 10+ (Repository, Factory, Builder, Adapter, Facade, Strategy, etc.)
- **SOLID Principles**: All 5 implemented
- **DDD Concepts**: Entities, Value Objects, Aggregates, Services, Use Cases
- **Test Coverage**: Unit tests included

## 🎯 Features

### Syntax Highlighting
- ✅ **Syntect Integration** - Production-ready TextMate grammar engine
- ✅ **Multiple Languages** - 100+ languages supported out of the box
- ✅ **TextMate Grammars** - Industry-standard grammar format (used by VS Code, Sublime, Atom)
- ✅ **Built-in Themes** - 20+ default themes (base16, Solarized, etc.)
- ✅ **Fast & Accurate** - Proven highlighting engine from Sublime Text

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
│  - Use Cases (HighlightCodeUseCase)                │
│  - DTOs (ParseRequest, HighlightResponse)          │
│  - Orchestration logic                              │
└────────────────────┬────────────────────────────────┘
                     │ uses
┌────────────────────▼────────────────────────────────┐
│        Domain Layer (domain/)                        │
│  - Entities: SyntaxTree, HighlightRange            │
│  - Value Objects: Language, Position, Theme         │
│  - Services (traits): Parser, Highlighter          │
│  - Pure business logic                              │
└────────────────────▲────────────────────────────────┘
                     │ implements
┌────────────────────┴────────────────────────────────┐
│        Infrastructure Layer (infrastructure/)        │
│  - SyntectParser (implements Parser)               │
│  - SyntectHighlighter (implements Highlighter)     │
│  - Memory management (alloc/dealloc)               │
└─────────────────────────────────────────────────────┘
```

**Dependency Rule**: Dependencies point inward. Outer layers depend on inner layers, never the reverse.

### Domain Layer

**Entities** (have identity):
- `SyntaxTree` - Parsed code structure (Aggregate Root)
- `HighlightRange` - Highlighted region with style
- `HighlightCollection` - Collection of ranges (Aggregate)

**Value Objects** (immutable, no identity):
- `Language` - Programming language enum
- `Position` - Line/column in text
- `Range` - Start/end positions
- `Theme` - Color scheme
- `Color` - RGB color
- `HighlightStyle` - Token style

**Services** (traits/interfaces):
- `Parser` - Parse source code → `SyntaxTree`
- `Highlighter` - Generate highlights from tree

### Application Layer

**Use Cases**:
- `HighlightCodeUseCase` - Main orchestration logic
  1. Validate request
  2. Parse language
  3. Parse source code
  4. Generate highlights
  5. Sort and convert to DTOs
  6. Return response

**DTOs**:
- `ParseRequest` - Input for use case
- `HighlightResponse` - Output from use case
- `HighlightRangeDto` - Serializable highlight

### Infrastructure Layer

**Adapters**:
- `SyntectParser` - Adapts Syntect to `Parser` trait
- `SyntectHighlighter` - Adapts Syntect highlighting to `Highlighter` trait

**Syntect Integration**:
- TextMate grammar parsing (`.tmLanguage` / `.sublime-syntax`)
- Built-in support for 100+ languages
- 20+ default themes (base16, Solarized, Monokai, etc.)
- Regex-based pattern matching (pure Rust, WASM-compatible)

### Presentation Layer

**WASM Exports**:
- `plugin_get_manifest()` - Plugin metadata
- `plugin_initialize()` - Setup
- `plugin_handle_event()` - Process events
- `plugin_dispose()` - Cleanup

## 🔧 SOLID Principles

### 1. Single Responsibility Principle (SRP)

Each class has **one reason to change**:

- `SyntaxTree` - Represents parsed code structure
- `HighlightRange` - Represents single highlighted region
- `SyntectParser` - Parses source code
- `SyntectHighlighter` - Generates highlights
- `HighlightCodeUseCase` - Orchestrates highlighting process

### 2. Open/Closed Principle (OCP)

**Open for extension, closed for modification**:

```rust
// Trait (abstraction) - closed for modification
pub trait Parser {
    fn parse(&self, language: Language, source: &str) -> Result<SyntaxTree, String>;
}

// Implementations - open for extension
pub struct SyntectParser { /* ... */ }
pub struct LspParser { /* ... */ }
pub struct CustomParser { /* ... */ }
```

### 3. Liskov Substitution Principle (LSP)

**Subtypes must be substitutable for their base types**:

```rust
// Any Parser implementation can be used
fn highlight_code<P: Parser>(parser: P, source: &str) {
    let tree = parser.parse(Language::Rust, source).unwrap();
    // ...
}

// Works with any parser
highlight_code(SyntectParser::new(), "fn main() {}");
highlight_code(CustomParser::new(), "fn main() {}");
```

### 4. Interface Segregation Principle (ISP)

**Clients shouldn't depend on interfaces they don't use**:

```rust
// Minimal interfaces
pub trait Parser {
    fn parse(&self, language: Language, source: &str) -> Result<SyntaxTree, String>;
    fn supports_language(&self, language: Language) -> bool;
}

pub trait Highlighter {
    fn highlight(&self, tree: &SyntaxTree, theme: &Theme) -> Result<HighlightCollection, String>;
}

// NOT: pub trait ParserAndHighlighter { /* both */ }
```

### 5. Dependency Inversion Principle (DIP)

**Depend on abstractions, not concretions**:

```rust
// Use Case depends on abstractions (traits)
pub struct HighlightCodeUseCase<P, H>
where
    P: Parser,        // ← abstraction
    H: Highlighter,   // ← abstraction
{
    parser: P,
    highlighter: H,
}

// Concrete implementations provided at runtime (DI)
let use_case = HighlightCodeUseCase::new(
    SyntectParser::new(),      // ← concrete
    SyntectHighlighter::new(), // ← concrete
);
```

## 📐 DDD Concepts

### Bounded Contexts

- **Syntax Highlighting Context** - Parsing and highlighting
- **Theme Context** - Color schemes and styles
- **Plugin Context** - WASM runtime and lifecycle

### Aggregates

**SyntaxTree** (Aggregate Root):
- Consistency boundary
- Controls access to internal nodes
- Provides statistics and validation

**HighlightCollection** (Aggregate):
- Collection of `HighlightRange` entities
- Sorting, filtering operations
- Overlap detection

### Value Objects

All value objects are:
- **Immutable** - Cannot change after creation
- **Self-validating** - Constructor validates input
- **Equality by value** - Not identity

Example:
```rust
let pos1 = Position::new(5, 10);
let pos2 = Position::new(5, 10);
assert_eq!(pos1, pos2); // Equal by value
```

### Domain Services

Expressed as traits (interfaces):
- `Parser` - Complex operation on entities
- `Highlighter` - Transformation service

## 🚀 Building

### Prerequisites

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Add WASM target with WASI support (required for Syntect)
rustup target add wasm32-wasip1

# Optional: wasm-opt for optimization
cargo install wasm-opt
```

### Build

```bash
./build.sh
```

Output: `build/syntax_highlighter_wasm.wasm` (~1.6MB, includes 100+ language grammars)

### Project Structure

```
syntax_highlighter_wasm/
├── Cargo.toml                          # Dependencies
├── build.sh                            # Build script
├── src/
│   ├── lib.rs                         # Presentation Layer
│   ├── domain/                        # Domain Layer
│   │   ├── mod.rs
│   │   ├── entities/
│   │   │   ├── syntax_tree.rs        # SyntaxTree entity
│   │   │   └── highlight_range.rs    # HighlightRange entity
│   │   ├── value_objects/
│   │   │   ├── language.rs           # Language enum
│   │   │   ├── position.rs           # Position/Range
│   │   │   └── theme.rs              # Theme/Color/Style
│   │   └── services/
│   │       ├── parser.rs             # Parser trait
│   │       └── highlighter.rs        # Highlighter trait
│   ├── application/                   # Application Layer
│   │   ├── mod.rs
│   │   ├── use_cases/
│   │   │   └── highlight_code.rs     # HighlightCodeUseCase
│   │   └── dto/
│   │       ├── parse_request.rs      # Input DTO
│   │       └── highlight_response.rs # Output DTO
│   └── infrastructure/                # Infrastructure Layer
│       ├── mod.rs
│       ├── syntect/
│       │   ├── syntect_parser.rs     # SyntectParser
│       │   └── syntect_highlighter.rs # SyntectHighlighter
│       └── memory/
│           └── allocator.rs          # WASM memory
└── README.md                          # This file
```

## 💻 Usage from Dart

### Load Plugin

```dart
import 'package:flutter_plugin_system_host/flutter_plugin_system_host.dart';
import 'package:flutter_plugin_system_wasm_run/flutter_plugin_system_wasm_run.dart';

// Create WASM runtime with WASI support (required for Syntect)
final wasmRuntime = WasmRunRuntime(
  config: WasmRuntimeConfig(
    maxMemoryPages: 256,  // 16MB
    maxExecutionTime: Duration(seconds: 5),
    enableWasi: true,     // IMPORTANT: Enable WASI for Syntect
  ),
);

// Create plugin runtime
final pluginRuntime = WasmPluginRuntime(
  wasmRuntime: wasmRuntime,
  serializer: MessagePackPluginSerializer(),
);

// Load plugin
final plugin = await pluginManager.loadPlugin(
  pluginId: 'plugin.syntax-highlighter-wasm',
  source: PluginSource.file(
    path: 'plugins/syntax_highlighter_wasm.wasm',
  ),
  runtime: pluginRuntime,
);
```

### Highlight Code

```dart
// Initialize plugin
await plugin.initialize(pluginContext);

// Highlight Rust code
final response = await plugin.handleEvent(
  PluginEvent(
    type: 'highlight_code',
    data: {
      'language': 'rust',
      'source_code': '''
        fn main() {
            let x = 42;
            println!("Answer: {}", x);
        }
      ''',
    },
  ),
);

if (response.handled) {
  final ranges = response.data['ranges'] as List;
  print('Highlighted ${ranges.length} ranges');

  for (final range in ranges) {
    print('${range['token_type']}: ${range['text']}');
  }
  // Output:
  // keyword: fn
  // function: main
  // keyword: let
  // variable: x
  // operator: =
  // number: 42
  // ...
}
```

## 🧪 Testing

### Unit Tests

```bash
cargo test
```

Tests included for:
- Value Objects (Language, Position, Range, Theme, Color)
- Entities (SyntaxTree, HighlightRange, HighlightCollection)
- Infrastructure (SyntectParser, SyntectHighlighter)
- Application (HighlightCodeUseCase)

### Integration Test

```dart
test('syntax highlighter WASM plugin', () async {
  final plugin = await loadPlugin('syntax_highlighter_wasm.wasm');

  final response = await plugin.handleEvent(
    PluginEvent(type: 'highlight_code', data: {
      'language': 'rust',
      'source_code': 'fn main() {}',
    }),
  );

  expect(response.handled, true);
  expect(response.data['ranges'], isNotEmpty);
  expect(response.data['has_errors'], false);
});
```

## 📈 Performance

| Metric | Value |
|--------|-------|
| Binary size | ~1.6MB (includes 100+ grammars) |
| Load time | ~50ms |
| Parse time | ~5-10ms (small file) |
| Highlight time | ~10-20ms (small file) |
| Memory usage | ~3-5MB |
| Supported languages | 100+ (Rust, JS, TS, Python, Go, Java, C++, etc.) |

## 🔗 Related

- [Plugin System Architecture](../../../docs/PLUGIN_SYSTEM_ARCHITECTURE.md)
- [flutter_plugin_system_core](../../../packages/flutter_plugin_system_core/)
- [flutter_plugin_system_wasm](../../../packages/flutter_plugin_system_wasm/)
- [flutter_plugin_system_wasm_run](../../../packages/flutter_plugin_system_wasm_run/)
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

### Syntect
- [Syntect Documentation](https://docs.rs/syntect/)
- [TextMate Grammars](https://macromates.com/manual/en/language_grammars)
- [Sublime Syntax](https://www.sublimetext.com/docs/syntax.html)

## 📝 License

MIT License - see [LICENSE](../../../LICENSE)

---

**Built with ❤️ following Clean Architecture, DDD, and SOLID principles**
