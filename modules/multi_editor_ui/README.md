# multi_editor_ui

UI layer for MultiEditor - Flutter widgets, controllers, and state management.

## Features

- **File Tree View**: Interactive file tree with drag-and-drop
- **Code Editor**: Monaco editor integration for web
- **Editor Scaffold**: Complete editor layout and structure
- **File Icon Support**: Plugin-based file icon system
- **Theme Support**: Light and dark themes

## Installation

\`\`\`yaml
dependencies:
  multi_editor_ui: ^0.1.0
  multi_editor_core: ^0.1.0
  multi_editor_plugins: ^0.1.0
\`\`\`

## Usage

\`\`\`dart
import 'package:multi_editor_ui/editor_ui.dart';

EditorScaffold(
  fileTreeController: fileTreeController,
  editorController: editorController,
  pluginManager: pluginManager,
)
\`\`\`

## License

MIT License - see [LICENSE](LICENSE) file for details.
