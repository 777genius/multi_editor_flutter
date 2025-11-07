# multi_editor_plugins

Plugin system for MultiEditor - extensibility framework with lifecycle management, event dispatching, messaging, and error tracking.

## Features

- **Plugin Lifecycle**: Initialize, activate, deactivate, dispose
- **Event Dispatching**: Subscribe to file and folder events
- **Message Bus**: Inter-plugin communication
- **Error Tracking**: Plugin error monitoring and handling
- **UI Extension Points**: Add custom UI to editor
- **File Icon System**: Custom file icon providers

## Installation

\`\`\`yaml
dependencies:
  multi_editor_plugins: ^0.1.0
  multi_editor_core: ^0.1.0
\`\`\`

## Usage

\`\`\`dart
import 'package:multi_editor_plugins/editor_plugins.dart';

class MyPlugin extends EditorPlugin {
  @override
  PluginManifest get manifest => PluginManifest(
    id: 'my-plugin',
    name: 'My Plugin',
    version: '1.0.0',
  );

  @override
  Future<void> onInitialize(PluginContext context) async {
    // Initialize plugin
  }
}
\`\`\`

## License

MIT License - see [LICENSE](LICENSE) file for details.
