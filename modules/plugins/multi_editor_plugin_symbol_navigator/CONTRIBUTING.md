# Contributing to Symbol Navigator Plugin

Thank you for your interest in contributing! This guide will help you get started.

## 🎯 Code of Conduct

- Be respectful and inclusive
- Follow the project's architectural principles
- Write clean, maintainable code
- Add tests for new features
- Document your changes

## 🚀 Quick Start

### Prerequisites

- **Dart/Flutter**: Flutter SDK 3.0+
- **Go**: Go 1.21+
- **Tools** (optional):
  - `golangci-lint` for Go linting
  - `wasm-opt` (binaryen) for WASM optimization
  - `wasm-validate` (wabt) for WASM validation

### Setup

```bash
# 1. Clone repository
git clone https://github.com/777genius/multi_editor_flutter.git
cd multi_editor_flutter

# 2. Setup Dart plugin
cd modules/plugins/multi_editor_plugin_symbol_navigator
./dev.sh deps  # Get dependencies
./dev.sh gen   # Generate freezed files

# 3. Setup Go WASM plugin
cd ../../../packages/wasm_plugins/symbol_navigator_wasm
./dev.sh deps  # Download Go dependencies

# 4. Run tests
./dev.sh test  # Go tests
cd ../../../modules/plugins/multi_editor_plugin_symbol_navigator
./dev.sh test  # Dart tests
```

## 🏗️ Architecture Principles

### Clean Architecture

```text
Presentation → Domain ← Infrastructure
```

- **Domain Layer**: Pure business logic, no dependencies
- **Infrastructure Layer**: External implementations (WASM, parsers)
- **Presentation Layer**: UI and user interaction

### DDD (Domain-Driven Design)

- **Entities**: CodeSymbol, SymbolTree (have identity)
- **Value Objects**: SymbolKind, SymbolLocation (immutable, no identity)
- **Aggregates**: SymbolTree is root aggregate

### SOLID Principles

- **Single Responsibility**: Each class does one thing
- **Open/Closed**: Open for extension (new languages), closed for modification
- **Liskov Substitution**: Parser implementations are substitutable
- **Interface Segregation**: Small, focused interfaces
- **Dependency Inversion**: Depend on abstractions

## 📝 Development Workflow

### 1. Create Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Make Changes

**Dart Changes:**
```bash
cd modules/plugins/multi_editor_plugin_symbol_navigator
./dev.sh fmt      # Format code
./dev.sh analyze  # Run analyzer
./dev.sh gen      # Regenerate if needed
./dev.sh test     # Run tests
```

**Go Changes:**
```bash
cd packages/wasm_plugins/symbol_navigator_wasm
./dev.sh fmt      # Format code
./dev.sh lint     # Run linter
./dev.sh test     # Run tests
./dev.sh build    # Build WASM
```

### 3. Pre-commit Checks

```bash
# Run all checks
./dev.sh all  # Both Dart and Go
```

### 4. Commit

Follow conventional commits:
```text
feat: add JavaScript parser support
fix: correct symbol location for nested classes
docs: update README with new examples
test: add tests for enum parsing
refactor: simplify parser dispatch logic
```

### 5. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Create PR on GitHub with:
- Clear description
- Screenshots/GIFs if UI changes
- Test coverage report
- Performance impact (if applicable)

## 🧪 Testing Guidelines

### Unit Tests

**Test each component in isolation:**

```dart
// Dart example
test('finds symbol by name', () {
  final tree = SymbolTree(...);
  final found = tree.findSymbolByName('MyClass');
  expect(found?.name, 'MyClass');
});
```

```go
// Go example
func TestParseDartClass(t *testing.T) {
  symbols, err := parseDart("class Test {}")
  assert.NoError(t, err)
  assert.Equal(t, "Test", symbols[0].Name)
}
```

### Integration Tests

```dart
test('parses real Dart file', () {
  final plugin = SymbolNavigatorPlugin();
  await plugin.onInitialize(mockContext);

  plugin.onFileOpen(mockDartFile);

  expect(plugin.currentSymbolTree?.totalCount, greaterThan(0));
});
```

### Test Coverage

Aim for:
- **Domain Models**: 100% coverage
- **Parsers**: 90%+ coverage
- **Plugin Logic**: 80%+ coverage

Run coverage:
```bash
# Dart
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Go
go test -cover ./...
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

## 🎨 Code Style

### Dart

Follow [Effective Dart](https://dart.dev/guides/language/effective-dart):

```dart
// ✅ Good
class CodeSymbol {
  final String name;
  final SymbolKind kind;

  const CodeSymbol({required this.name, required this.kind});
}

// ❌ Bad
class code_symbol {
  String Name;
  var Kind;
}
```

### Go

Follow [Effective Go](https://go.dev/doc/effective_go):

```go
// ✅ Good
type Symbol struct {
    Name     string
    Kind     string
    Location Location
}

func ParseSymbols(content string) ([]Symbol, error) {
    // ...
}

// ❌ Bad
type symbol struct {
    name string  // unexported in API
}

func parse_symbols(content string) []Symbol {
    // no error handling
}
```

## 📚 Documentation

### Code Comments

```dart
/// Finds a symbol by its fully qualified name.
///
/// Returns `null` if no symbol matches.
///
/// Example:
/// ```dart
/// final symbol = tree.findSymbolByName('MyClass.myMethod');
/// ```
CodeSymbol? findSymbolByName(String name) {
  // ...
}
```

### README Updates

When adding features:
1. Update README.md with feature description
2. Add usage example
3. Update CHANGELOG.md
4. Update ARCHITECTURE.md if needed

## 🐛 Bug Reports

Good bug report includes:

```markdown
**Description**
Clear description of the bug

**Steps to Reproduce**
1. Open file X
2. Click Y
3. See error

**Expected Behavior**
What should happen

**Actual Behavior**
What actually happens

**Environment**
- OS: macOS 14.0
- Dart: 3.2.0
- Go: 1.21

**Stack Trace**
```
Error: ...
at ...
```

**Code Sample**
Minimal code to reproduce
```

## ✨ Feature Requests

Good feature request includes:

```markdown
**Feature Description**
What feature do you want?

**Use Case**
Why is this needed?

**Proposed Solution**
How would you implement it?

**Alternatives Considered**
Other approaches you thought about

**Additional Context**
Screenshots, mockups, examples
```

## 🌟 Adding New Language Support

### 1. Add Parser (Go)

Create `packages/wasm_plugins/symbol_navigator_wasm/parser/javascript_parser.go`:

```go
package parser

func parseJavaScript(content string) ([]Symbol, error) {
    // TODO: Implement JavaScript parsing
    parser := &JavaScriptParser{content: content}
    return parser.Parse()
}

type JavaScriptParser struct {
    content string
    lines   []string
}

func (p *JavaScriptParser) Parse() ([]Symbol, error) {
    // Parse classes
    symbols := p.parseClasses()
    // Parse functions
    symbols = append(symbols, p.parseFunctions()...)
    return symbols, nil
}
```

### 2. Add Tests

```go
func TestParseJavaScriptClass(t *testing.T) {
    content := "class MyClass { method() {} }"
    symbols, err := parseJavaScript(content)

    assert.NoError(t, err)
    assert.Equal(t, 1, len(symbols))
    assert.Equal(t, "MyClass", symbols[0].Name)
}
```

### 3. Register in Dispatcher

```go
// parser/parser.go
case LangJavaScript:
    symbols, err = parseJavaScript(content)
```

### 4. Add Language Detection (Dart)

```dart
// symbol_navigator_plugin.dart
String _detectLanguage(String filename) {
  switch (ext) {
    case 'js': return 'javascript';
    // ...
  }
}
```

### 5. Update Documentation

- README.md: Add to supported languages
- CHANGELOG.md: Note new feature
- Tests: Ensure all tests pass

## 🚀 Performance Guidelines

### Dart

- Use `const` constructors where possible
- Avoid unnecessary rebuilds
- Profile with DevTools
- Benchmark critical paths

```dart
// ✅ Good
const SymbolKind.classDeclaration()

// ❌ Bad
SymbolKind.classDeclaration()  // Creates new instance every time
```

### Go

- Minimize allocations
- Reuse buffers
- Benchmark hot paths
- Profile with pprof

```go
// ✅ Good
var buffer bytes.Buffer
for _, item := range items {
    buffer.WriteString(item)
}

// ❌ Bad
result := ""
for _, item := range items {
    result += item  // Creates new string each iteration
}
```

### Benchmarks

```go
func BenchmarkParseSymbols(b *testing.B) {
    content := loadTestFile()

    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        ParseSymbols(content, "dart")
    }
}
```

Target:
- Parse 1K lines: < 10ms (current: 5-10ms)
- Parse 10K lines: < 100ms (current: 50-100ms)

## 📊 Code Review Checklist

Before submitting PR:

- [ ] Code follows style guide
- [ ] Tests added for new features
- [ ] All tests pass
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] No performance regressions
- [ ] Error handling added
- [ ] Edge cases considered
- [ ] Memory leaks checked
- [ ] Security implications reviewed

## 🔍 Review Process

1. **Automated Checks**: CI runs tests, linters
2. **Code Review**: Maintainer reviews code
3. **Feedback**: Address review comments
4. **Approval**: Maintainer approves
5. **Merge**: Squash and merge to main

## 🎓 Learning Resources

### Architecture
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Domain-Driven Design](https://martinfowler.com/bliki/DomainDrivenDesign.html)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)

### Languages
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Effective Go](https://go.dev/doc/effective_go)
- [WASM Concepts](https://webassembly.org/docs/concepts/)

### Parsing
- [Tree-sitter](https://tree-sitter.github.io/tree-sitter/)
- [AST Explorer](https://astexplorer.net/)
- [Crafting Interpreters](https://craftinginterpreters.com/)

## 💬 Communication

- **Issues**: Use GitHub issues for bugs and features
- **Discussions**: Use GitHub discussions for questions
- **PRs**: Keep focused, one feature per PR
- **Discord**: Join community Discord (if available)

## 🙏 Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Credited in significant features

## 📜 License

By contributing, you agree that your contributions will be licensed under the same license as the project.

## 🎉 Thank You!

Your contributions make this project better for everyone. Happy coding! 🚀
