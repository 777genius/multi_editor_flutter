# Changelog

All notable changes to Symbol Navigator Plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Tree-sitter integration for 10-100x faster parsing
- JavaScript/TypeScript parser support
- Python parser support
- Go parser support (using stdlib go/parser)
- Rust parser support
- Symbol search and filtering
- Symbol outline breadcrumbs
- Jump-to-definition integration
- LSP integration for enhanced accuracy
- Symbol refactoring hints

## [0.1.0] - 2025-01-11

### Added
- Initial release of Symbol Navigator Plugin
- Hybrid Dart + Go WASM architecture
- Domain models: `CodeSymbol`, `SymbolKind`, `SymbolLocation`, `SymbolTree`
- Go WASM parser with MessagePack serialization
- Regex-based Dart parser (proof-of-concept)
- Support for 16 symbol types:
  - Classes: class, abstract class, mixin, extension
  - Functions: function, method, constructor, getter, setter
  - Fields: field, property, constant, variable
  - Types: enum, typedef, enum value, parameter
- Hierarchical symbol tree with parent-child relationships
- Location tracking: line/column/byte offset
- Real-time parsing with 500ms debounce
- Plugin UI integration with tree view
- Symbol statistics and metrics
- Comprehensive test suite (Dart + Go)
- Development scripts for both Dart and Go
- Complete documentation (README, BUILD_INSTRUCTIONS, examples)
- Performance: ~5-10ms for 1000 lines (regex-based)

### Features
- **Multi-language support framework**: Ready for Dart, JS, TS, Python, Go, Rust
- **Memory-efficient**: Packed pointer returns, minimal allocations
- **Type-safe**: Freezed for immutable data classes
- **Well-tested**: Unit tests, integration tests, benchmarks
- **Developer-friendly**: Dev scripts, examples, comprehensive docs

### Technical Details
- Clean Architecture (Domain/Infrastructure layers)
- DDD principles (Entities, Value Objects)
- SOLID principles throughout
- Freezed for code generation
- MessagePack for WASM communication
- WASM memory management (alloc/dealloc)
- Makefile build system for Go

### Documentation
- README with feature overview and architecture
- BUILD_INSTRUCTIONS for setup
- Usage examples with expected output
- Inline code documentation
- WASM plugin documentation

## [0.0.1] - Development

### Initial Prototype
- Basic plugin structure
- Proof-of-concept regex parser
- Domain model design

---

## Version History

- **0.1.0** - Initial public release (2025-01-11)
- **0.0.1** - Internal prototype

## Migration Guides

### Upgrading to 0.1.0

First release, no migration needed.

## Breaking Changes

None yet (initial release).

## Dependencies

### Dart
- `flutter`: SDK
- `multi_editor_core`: Local path
- `multi_editor_plugins`: Local path
- `multi_editor_plugin_base`: Local path
- `flutter_plugin_system_core`: Local path
- `flutter_plugin_system_wasm`: Local path
- `fpdart`: ^1.1.0
- `freezed_annotation`: ^2.4.1
- `json_annotation`: ^4.8.1

### Go
- `github.com/vmihailenco/msgpack/v5`: v5.4.1

## Known Issues

- Freezed files must be generated before use (see BUILD_INSTRUCTIONS.md)
- Regex parser has ~90% accuracy (edge cases with complex syntax)
- No symbol search/filtering yet
- Jump-to-definition not yet integrated with editor

## Future Roadmap

See [README.md](README.md) for detailed roadmap.
