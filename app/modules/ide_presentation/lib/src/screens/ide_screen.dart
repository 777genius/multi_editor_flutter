import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import '../stores/editor/editor_store.dart';
import '../stores/lsp/lsp_store.dart';
import '../widgets/editor_view.dart';

/// IdeScreen
///
/// Main IDE screen that brings together all IDE components.
///
/// Architecture (Clean Architecture + MobX):
/// ```
/// IdeScreen (UI)
///     ↓ observes
/// EditorStore + LspStore (MobX Stores)
///     ↓ calls actions
/// Use Cases (Application Layer)
///     ↓ uses
/// Repositories (Domain Interfaces)
/// ```
///
/// MobX Best Practices:
/// - Observer: Reactively rebuilds on store changes
/// - GetIt: Dependency injection for stores
/// - Composition: Multiple stores for different concerns
/// - Separation: UI logic in widgets, business logic in stores
///
/// Layout:
/// ```
/// ┌─────────────────────────────────────┐
/// │ AppBar (Title, Actions)             │
/// ├─────────┬───────────────────────────┤
/// │ File    │                           │
/// │ Explorer│   Editor View             │
/// │         │   (Code Editor)           │
/// │         │                           │
/// ├─────────┴───────────────────────────┤
/// │ Status Bar (Language, Diagnostics)  │
/// └─────────────────────────────────────┘
/// ```
///
/// Example:
/// ```dart
/// MaterialApp(
///   home: IdeScreen(),
/// );
/// ```
class IdeScreen extends StatefulWidget {
  const IdeScreen({super.key});

  @override
  State<IdeScreen> createState() => _IdeScreenState();
}

class _IdeScreenState extends State<IdeScreen> {
  late final EditorStore _editorStore;
  late final LspStore _lspStore;

  @override
  void initState() {
    super.initState();
    _editorStore = GetIt.I<EditorStore>();
    _lspStore = GetIt.I<LspStore>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildStatusBar(),
    );
  }

  /// Builds the app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Observer(
        builder: (_) {
          final hasUnsaved = _editorStore.hasUnsavedChanges;
          final fileName = _editorStore.documentUri?.path.split('/').last ?? 'Untitled';

          return Row(
            children: [
              const Text('Flutter IDE'),
              const SizedBox(width: 8),
              const Text('•', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                hasUnsaved ? '$fileName *' : fileName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: hasUnsaved ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        },
      ),
      backgroundColor: const Color(0xFF2D2D30), // VS Code dark theme
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        // File menu
        IconButton(
          icon: const Icon(Icons.folder_open),
          tooltip: 'Open File',
          onPressed: _handleOpenFile,
        ),

        // Save button
        Observer(
          builder: (_) {
            final canSave = _editorStore.hasUnsavedChanges;

            return IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save',
              onPressed: canSave ? _handleSave : null,
            );
          },
        ),

        // Undo button
        Observer(
          builder: (_) {
            final canUndo = _editorStore.canUndo;

            return IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo',
              onPressed: canUndo ? () => _editorStore.undo() : null,
            );
          },
        ),

        // Redo button
        Observer(
          builder: (_) {
            final canRedo = _editorStore.canRedo;

            return IconButton(
              icon: const Icon(Icons.redo),
              tooltip: 'Redo',
              onPressed: canRedo ? () => _editorStore.redo() : null,
            );
          },
        ),

        // Settings
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: _handleSettings,
        ),
      ],
    );
  }

  /// Builds the main body
  Widget _buildBody() {
    return Row(
      children: [
        // File Explorer Sidebar (left)
        _buildSidebar(),

        // Main Editor Area (center)
        const Expanded(
          child: EditorView(),
        ),
      ],
    );
  }

  /// Builds the left sidebar (file explorer)
  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: const Color(0xFF252526),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar header
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'EXPLORER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),

          // File tree
          Expanded(
            child: ListView(
              children: [
                _buildFileTreeItem(
                  icon: Icons.folder,
                  name: 'app',
                  isDirectory: true,
                ),
                _buildFileTreeItem(
                  icon: Icons.folder,
                  name: 'modules',
                  isDirectory: true,
                  indent: 1,
                ),
                _buildFileTreeItem(
                  icon: Icons.insert_drive_file,
                  name: 'main.dart',
                  indent: 1,
                ),
                _buildFileTreeItem(
                  icon: Icons.insert_drive_file,
                  name: 'README.md',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a file tree item
  Widget _buildFileTreeItem({
    required IconData icon,
    required String name,
    bool isDirectory = false,
    int indent = 0,
  }) {
    return InkWell(
      onTap: () {
        // TODO: Open file
        if (!isDirectory) {
          _handleOpenFileByName(name);
        }
      },
      child: Container(
        padding: EdgeInsets.only(
          left: 16.0 + (indent * 16.0),
          top: 8,
          bottom: 8,
          right: 16,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isDirectory ? Colors.amber : Colors.blue,
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the status bar
  Widget _buildStatusBar() {
    return Observer(
      builder: (_) {
        return Container(
          height: 24,
          color: const Color(0xFF007ACC), // VS Code blue
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Language indicator
              if (_editorStore.languageId != null) ...[
                const Icon(
                  Icons.code,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  _editorStore.languageId!.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
              ],

              // Cursor position
              if (_editorStore.hasDocument) ...[
                Text(
                  'Ln ${_editorStore.cursorPosition.line + 1}, '
                  'Col ${_editorStore.cursorPosition.column + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
              ],

              // Line count
              if (_editorStore.hasDocument) ...[
                Text(
                  '${_editorStore.lineCount} lines',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
              ],

              const Spacer(),

              // Diagnostics count
              if (_lspStore.hasDiagnostics) ...[
                if (_lspStore.errorCount > 0) ...[
                  const Icon(Icons.error, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    '${_lspStore.errorCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                ],
                if (_lspStore.warningCount > 0) ...[
                  const Icon(Icons.warning, size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    '${_lspStore.warningCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                ],
              ],

              // LSP status
              _buildLspStatus(),
            ],
          ),
        );
      },
    );
  }

  /// Builds LSP status indicator
  Widget _buildLspStatus() {
    return Observer(
      builder: (_) {
        if (_lspStore.isReady) {
          return const Row(
            children: [
              Icon(Icons.check_circle, size: 14, color: Colors.green),
              SizedBox(width: 4),
              Text(
                'LSP Ready',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          );
        }

        if (_lspStore.isInitializing) {
          return const Row(
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 4),
              Text(
                'Initializing...',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          );
        }

        if (_lspStore.hasError) {
          return const Row(
            children: [
              Icon(Icons.error, size: 14, color: Colors.red),
              SizedBox(width: 4),
              Text(
                'LSP Error',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  // ================================================================
  // Event Handlers
  // ================================================================

  void _handleOpenFile() {
    // TODO: Implement file picker
    debugPrint('Open file clicked');
  }

  void _handleOpenFileByName(String name) {
    // TODO: Load actual file content
    _editorStore.loadContent(
      '// File: $name\n\nvoid main() {\n  print("Hello World");\n}\n',
    );
  }

  void _handleSave() {
    _editorStore.saveDocument();
  }

  void _handleSettings() {
    // TODO: Implement settings dialog
    debugPrint('Settings clicked');
  }
}
