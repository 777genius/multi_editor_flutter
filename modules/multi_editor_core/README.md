# multi_editor_core

Core domain layer for MultiEditor - a multi-file code editor built with Flutter.

## Features

- **Entities**: Core business entities (`FileDocument`, `FileTreeNode`)
- **Value Objects**: Type-safe value objects for domain logic
- **Repositories**: Repository interfaces following Clean Architecture
- **Domain Services**: Business logic services
- **Event System**: Domain events for file operations

## Architecture

This package follows:
- **Clean Architecture** - separation of concerns, dependency inversion
- **Domain-Driven Design (DDD)** - entities, value objects, aggregates
- **SOLID Principles** - maintainable and testable code

## Installation

\`\`\`yaml
dependencies:
  multi_editor_core: ^0.1.0
\`\`\`

## Usage

\`\`\`dart
import 'package:multi_editor_core/editor_core.dart';

// Create a file document
final file = FileDocument(
  id: 'file1',
  name: 'main.dart',
  content: 'void main() {}',
  language: 'dart',
);

// Create a file tree node
final node = FileTreeNode.file(
  id: 'node1',
  name: 'main.dart',
  language: 'dart',
);
\`\`\`

## Documentation

For complete documentation, visit the [GitHub repository](https://github.com/777genius/multi_editor_flutter).

## License

MIT License - see [LICENSE](LICENSE) file for details.
