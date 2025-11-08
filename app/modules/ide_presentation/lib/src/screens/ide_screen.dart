import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';
import '../stores/editor/editor_store.dart';
import '../stores/lsp/lsp_store.dart';
import '../widgets/editor_view.dart';
import '../widgets/diagnostics_panel.dart';
import '../widgets/settings_dialog.dart';
import '../infrastructure/file_service.dart';
import '../infrastructure/file_picker_service.dart';

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
/// - GetIt: Dependency injection for stores and services
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
/// │ Diagnostics Panel (if problems)     │
/// ├─────────────────────────────────────┤
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
  late final FileService _fileService;
  late final FilePickerService _filePickerService;

  bool _showDiagnosticsPanel = false;
  String? _currentFilePath;

  @override
  void initState() {
    super.initState();
    _editorStore = GetIt.I<EditorStore>();
    _lspStore = GetIt.I<LspStore>();
    _fileService = GetIt.I<FileService>();
    _filePickerService = GetIt.I<FilePickerService>();

    // Initialize editor repository
    _initializeEditor();
  }

  Future<void> _initializeEditor() async {
    try {
      // Initialize the native editor
      final repo = GetIt.I<ICodeEditorRepository>();
      await repo.initialize();
    } catch (e) {
      // Log error but don't crash - editor might work in degraded mode
      debugPrint('Failed to initialize editor: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Editor initialization failed: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Dispose Repository which holds Rust FFI handle
    // This is important to prevent memory leaks
    try {
      final repo = GetIt.I<ICodeEditorRepository>();
      repo.dispose();
    } catch (e) {
      debugPrint('Error disposing editor repository: $e');
    }
    super.dispose();
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
          final fileName = _currentFilePath?.split('/').last ?? 'Untitled';

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

        // Toggle diagnostics panel
        Observer(
          builder: (_) {
            final hasDiagnostics = _lspStore.hasDiagnostics;

            return IconButton(
              icon: Badge(
                isLabelVisible: hasDiagnostics,
                label: Text('${_lspStore.errorCount + _lspStore.warningCount}'),
                child: Icon(
                  _showDiagnosticsPanel
                      ? Icons.keyboard_arrow_down
                      : Icons.warning_outlined,
                ),
              ),
              tooltip: 'Problems',
              onPressed: hasDiagnostics
                  ? () => setState(() => _showDiagnosticsPanel = !_showDiagnosticsPanel)
                  : null,
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
    return Column(
      children: [
        // Main editor area
        Expanded(
          child: Row(
            children: [
              // File Explorer Sidebar (left)
              _buildSidebar(),

              // Main Editor Area (center)
              const Expanded(
                child: EditorView(),
              ),
            ],
          ),
        ),

        // Diagnostics panel (bottom, collapsible)
        if (_showDiagnosticsPanel)
          Observer(
            builder: (_) {
              if (!_lspStore.hasDiagnostics) return const SizedBox.shrink();

              return DiagnosticsPanel(
                diagnostics: _lspStore.diagnostics?.toList() ?? [],
                onDiagnosticTap: _handleDiagnosticTap,
                onClose: () => setState(() => _showDiagnosticsPanel = false),
              );
            },
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

          // Quick actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.add, color: Colors.white, size: 16),
                  title: const Text(
                    'New File',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  onTap: _handleNewFile,
                  dense: true,
                ),
                ListTile(
                  leading: const Icon(Icons.folder_open, color: Colors.white, size: 16),
                  title: const Text(
                    'Open File',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  onTap: _handleOpenFile,
                  dense: true,
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF3E3E42)),

          // File tree (placeholder)
          Expanded(
            child: Observer(
              builder: (_) {
                if (_currentFilePath == null) {
                  return const Center(
                    child: Text(
                      'No file opened',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  );
                }

                return ListView(
                  children: [
                    _buildFileTreeItem(
                      icon: Icons.insert_drive_file,
                      name: _currentFilePath!.split('/').last,
                      isSelected: true,
                      onTap: () {},
                    ),
                  ],
                );
              },
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
    bool isSelected = false,
    int indent = 0,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(
          left: 16.0 + (indent * 16.0),
          top: 8,
          bottom: 8,
          right: 16,
        ),
        color: isSelected ? const Color(0xFF094771) : null,
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

  /// Handles opening a file with file picker
  Future<void> _handleOpenFile() async {
    // Show file picker
    final filePath = await _filePickerService.pickFile(
      allowedExtensions: FilePickerService.allTextExtensions,
      dialogTitle: 'Open File',
    );

    if (filePath == null) return;

    // Load file using FileService
    final result = await _fileService.readFile(filePath);

    result.fold(
      (failure) {
        // Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to open file: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (document) async {
        // Open document in editor
        if (mounted) {
          setState(() {
            _currentFilePath = filePath;
          });
        }

        // Open document with initial content (fixes race condition)
        await _editorStore.openDocument(
          uri: document.uri,
          language: document.languageId,
          initialContent: document.content,
        );

        // Show success
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opened: ${document.uri.path}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }

  /// Handles creating a new file
  void _handleNewFile() {
    setState(() {
      _currentFilePath = null;
    });

    _editorStore.closeDocument();
    _editorStore.loadContent('');
  }

  /// Handles saving the current file
  Future<void> _handleSave() async {
    if (_currentFilePath == null) {
      // Save As - pick location
      final directory = await _filePickerService.pickDirectory(
        dialogTitle: 'Save File',
      );

      if (directory == null) return;

      // For now, save as "untitled.txt"
      // In real implementation, show dialog to enter filename
      _currentFilePath = '$directory/untitled.txt';
    }

    // Save file using FileService
    final result = await _fileService.writeFile(
      filePath: _currentFilePath!,
      content: _editorStore.content,
    );

    result.fold(
      (failure) {
        // Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save file: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (_) async {
        // Mark as saved
        await _editorStore.markDocumentSaved();

        // Show success
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved: $_currentFilePath'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }

  /// Handles opening settings dialog
  void _handleSettings() {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(
        initialSettings: {
          'fontSize': 14.0,
          'showLineNumbers': true,
          'wordWrap': false,
          'theme': 'dark',
          'lspBridgeUrl': 'ws://localhost:9999',
          'connectionTimeout': 10,
          'requestTimeout': 30,
        },
        onSave: (settings) {
          // Apply settings
          debugPrint('Settings saved: $settings');
          // TODO: Persist settings and apply them
        },
      ),
    );
  }

  /// Handles clicking on a diagnostic
  Future<void> _handleDiagnosticTap(Diagnostic diagnostic) async {
    // Jump to diagnostic location
    await _editorStore.moveCursor(diagnostic.range.start);
  }
}
