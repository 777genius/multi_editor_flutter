# Plugin System Documentation Index

This directory contains comprehensive documentation about the multi-file code editor's plugin system.

## Documents

### 1. **PLUGIN_GUIDE.md** (Main Comprehensive Guide)
   - Complete overview of the plugin system
   - Architecture layers and core components
   - Plugin System Architecture (EditorPlugin, PluginContext, PluginManifest)
   - BaseEditorPlugin class and lifecycle
   - ConfigurablePlugin and StatefulPlugin mixins
   - PluginManager functionality
   - **Detailed sections for each built-in plugin:**
     - AutoSavePlugin
     - RecentFilesPlugin
     - FileStatsPlugin
   - Plugin registration process
   - Plugin lifecycle (creation, registration, activation, runtime, unregistration, cleanup)
   - Event system and available events
   - UI integration points (toolbar, context menu, sidebar)
   - Custom plugin creation guide
   - Configuration and persistence
   - Best practices and troubleshooting

   **Best for**: Understanding the full plugin architecture and how everything works together

### 2. **PLUGIN_QUICK_REFERENCE.md** (Quick Lookup Guide)
   - Plugin locations in the codebase
   - Core interfaces location
   - Registration location
   - Plugin creation checklist
   - Event handlers quick list
   - UI building methods reference
   - State management quick reference
   - Plugin access patterns
   - Summary of the three built-in plugins
   - Error handling patterns
   - Plugin dependencies
   - Storage options
   - Best practices summary
   - Common patterns
   - Testing guide
   - Debugging tips
   - Performance tips
   - Version compatibility

   **Best for**: Quick lookups and references while coding

### 3. **PLUGIN_ARCHITECTURE.md** (Architecture & Code Examples)
   - System architecture diagrams (ASCII art)
   - Plugin inheritance hierarchy
   - Event flow diagram
   - State lifecycle diagram
   - Data flow diagrams
   - **Five detailed code examples:**
     1. Timer Plugin (simple example)
     2. Configuration Plugin (ConfigurablePlugin example)
     3. File Analysis Plugin (StatefulPlugin example)
     4. Event-Listening Plugin (comprehensive example)
     5. Service Locator integration
   - UI integration example
   - Unit testing example
   - Performance considerations
   - Security best practices

   **Best for**: Understanding architecture visually and learning through examples

## Quick Start

### For New Developers
1. Start with **PLUGIN_GUIDE.md** - Introduction and Overview section
2. Read about the **BaseEditorPlugin** class
3. Look at **PLUGIN_QUICK_REFERENCE.md** - Plugin Creation Checklist
4. Study one code example in **PLUGIN_ARCHITECTURE.md**

### For API Reference
1. Use **PLUGIN_QUICK_REFERENCE.md** for quick lookups
2. Check **PLUGIN_GUIDE.md** sections for detailed information
3. See **PLUGIN_ARCHITECTURE.md** for code examples

### For Troubleshooting
1. Check **PLUGIN_GUIDE.md** - Troubleshooting section
2. Look at **PLUGIN_QUICK_REFERENCE.md** - Error Handling section
3. Review **PLUGIN_ARCHITECTURE.md** - Testing example

## File Locations

### Plugin Implementation Files
- Base classes: `/modules/plugins/plugin_base/lib/src/`
- AutoSavePlugin: `/modules/plugins/plugin_auto_save/lib/src/`
- RecentFilesPlugin: `/modules/plugins/plugin_recent_files/lib/src/`
- FileStatsPlugin: `/modules/plugins/plugin_file_stats/lib/src/`

### Core Plugin System
- Plugin API: `/modules/editor_plugins/lib/src/plugin_api/`
- Plugin Manager: `/modules/editor_plugins/lib/src/plugin_manager/`

### Example App
- Service Locator: `/example/lib/di/service_locator.dart`
- App Plugin Context: `/example/lib/plugins/app_plugin_context.dart`
- Main App: `/example/lib/main.dart`

## Key Concepts

### Plugin Manifest
```
id, name, version, description, author, 
dependencies, capabilities, activationEvents, metadata
```

### Plugin Lifecycle
```
Creation → Registration → Initialization → Ready → Events → Disposal
```

### State Management
- **Stateful**: Session-only state (no persistence)
- **Configurable**: Persistent configuration (saved to storage)

### Event System
File/Folder events automatically subscribed during plugin initialization

### UI Integration
Three methods available (not yet rendered in UI):
- buildToolbarAction()
- buildContextMenuItem()
- buildSidebarPanel()

## The Three Built-In Plugins

| Plugin | ID | Purpose | UI |
|--------|----|---------|----|
| AutoSavePlugin | `plugin.auto_save` | Auto-saves files every 5s | None |
| RecentFilesPlugin | `plugin.recent_files` | Tracks recent files | Sidebar panel |
| FileStatsPlugin | `plugin.file_stats` | Shows file stats | Toolbar chip |

## Architecture Pattern

The plugin system follows:
- **Clean Architecture**: Separated concerns (domain, application, infrastructure)
- **Domain-Driven Design**: Explicit domain concepts
- **SOLID Principles**: Especially Open/Closed principle for extensibility
- **Event-Driven**: Asynchronous event subscriptions
- **Dependency Injection**: Via PluginContext

## Mixins Available

- **ConfigurablePlugin**: Configuration persistence
- **StatefulPlugin**: Session state management

Can be combined:
```dart
class MyPlugin extends BaseEditorPlugin with ConfigurablePlugin, StatefulPlugin
```

## Important Notes

⚠️ **UI Integration Status**
The plugin methods `buildToolbarAction()`, `buildContextMenuItem()`, and `buildSidebarPanel()` are defined but not yet integrated into the EditorScaffold UI component. This is a future enhancement.

## Documentation Structure

Each document is self-contained but complements the others:

- **PLUGIN_GUIDE.md**: Complete, detailed, reference-style
- **PLUGIN_QUICK_REFERENCE.md**: Condensed checklists and lookups
- **PLUGIN_ARCHITECTURE.md**: Visual diagrams and code examples

## How to Use These Docs

### Read a specific topic
1. Use PLUGIN_QUICK_REFERENCE.md to find the section
2. Go to PLUGIN_GUIDE.md for detailed explanation
3. Check PLUGIN_ARCHITECTURE.md for examples

### Learn by example
1. Start with PLUGIN_ARCHITECTURE.md
2. Pick a code example
3. Reference PLUGIN_GUIDE.md for explanations

### Debug a problem
1. Check PLUGIN_QUICK_REFERENCE.md - Troubleshooting
2. Read PLUGIN_GUIDE.md - Troubleshooting section
3. Review PLUGIN_ARCHITECTURE.md - Testing example

## Contributing New Plugins

When creating a new plugin:

1. Follow the checklist in PLUGIN_QUICK_REFERENCE.md
2. Implement the interface as shown in PLUGIN_GUIDE.md
3. Use patterns from PLUGIN_ARCHITECTURE.md examples
4. Register in service_locator.dart
5. Add tests based on testing example
6. Update your manifest with accurate metadata

## Version Information

- Dart: ^3.7.0
- Flutter: Latest stable
- Plugin Base: 0.1.0
- Freezed: ^3.1.0

## Additional Resources

- Source code in `/modules/plugins/` directories
- Example app in `/example/` directory
- Editor core in `/modules/editor_core/`
- Editor UI in `/modules/editor_ui/`

---

**Last Updated**: 2024
**Status**: Complete Documentation
**Total Pages**: 3 comprehensive markdown files
