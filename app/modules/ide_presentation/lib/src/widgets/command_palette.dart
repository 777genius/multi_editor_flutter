import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// CommandPalette
///
/// VS Code-style command palette for quick actions:
/// - File operations (open, save, new)
/// - Editor commands (format, refactor)
/// - Navigation (go to symbol, go to line)
/// - LSP actions (rename, find references)
/// - Settings and preferences
/// - Custom commands
///
/// Features:
/// - Fuzzy search
/// - Keyboard shortcuts display
/// - Recent commands
/// - Command categories
/// - Custom command registration
///
/// Architecture:
/// - Command registry pattern
/// - Action-based architecture
/// - Keyboard-first design
///
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (_) => CommandPalette(
///     commands: [
///       Command(
///         id: 'file.open',
///         label: 'File: Open',
///         action: () => openFile(),
///         shortcut: 'Ctrl+O',
///       ),
///     ],
///   ),
/// )
/// ```
class CommandPalette extends StatefulWidget {
  final List<Command> commands;
  final List<Command>? recentCommands;
  final void Function(Command command)? onCommandExecuted;

  const CommandPalette({
    super.key,
    required this.commands,
    this.recentCommands,
    this.onCommandExecuted,
  });

  @override
  State<CommandPalette> createState() => _CommandPaletteState();

  /// Shows the command palette as a dialog
  static Future<void> show(
    BuildContext context, {
    required List<Command> commands,
    List<Command>? recentCommands,
    void Function(Command command)? onCommandExecuted,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => CommandPalette(
        commands: commands,
        recentCommands: recentCommands,
        onCommandExecuted: onCommandExecuted,
      ),
    );
  }
}

class _CommandPaletteState extends State<CommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode();
  late List<Command> _filteredCommands;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _filteredCommands = [
      ...(widget.recentCommands ?? []),
      ...widget.commands,
    ];
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _filterCommands(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCommands = [
          ...(widget.recentCommands ?? []),
          ...widget.commands,
        ];
      } else {
        final lowerQuery = query.toLowerCase();

        // Fuzzy search
        _filteredCommands = widget.commands.where((cmd) {
          final labelLower = cmd.label.toLowerCase();
          final categoryLower = cmd.category?.toLowerCase() ?? '';
          final descriptionLower = cmd.description?.toLowerCase() ?? '';

          return labelLower.contains(lowerQuery) ||
                 categoryLower.contains(lowerQuery) ||
                 descriptionLower.contains(lowerQuery);
        }).toList();

        // Sort by relevance
        _filteredCommands.sort((a, b) {
          final aLabel = a.label.toLowerCase();
          final bLabel = b.label.toLowerCase();

          // Exact match
          if (aLabel == lowerQuery) return -1;
          if (bLabel == lowerQuery) return 1;

          // Starts with query
          final aStarts = aLabel.startsWith(lowerQuery);
          final bStarts = bLabel.startsWith(lowerQuery);
          if (aStarts && !bStarts) return -1;
          if (!aStarts && bStarts) return 1;

          // Alphabetical
          return aLabel.compareTo(bLabel);
        });
      }

      _selectedIndex = 0;
    });
  }

  void _executeCommand(Command command) {
    Navigator.of(context).pop();
    command.action();
    widget.onCommandExecuted?.call(command);
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _filteredCommands.length;
        });
        break;

      case LogicalKeyboardKey.arrowUp:
        setState(() {
          _selectedIndex = (_selectedIndex - 1 + _filteredCommands.length) %
                          _filteredCommands.length;
        });
        break;

      case LogicalKeyboardKey.enter:
        if (_filteredCommands.isNotEmpty) {
          _executeCommand(_filteredCommands[_selectedIndex]);
        }
        break;

      case LogicalKeyboardKey.escape:
        Navigator.of(context).pop();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 100),
      child: RawKeyboardListener(
        focusNode: _keyboardFocusNode,
        onKey: _handleKeyEvent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            color: const Color(0xFF252526),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search input
              _buildSearchInput(),

              // Command list
              if (_filteredCommands.isNotEmpty)
                _buildCommandList()
              else
                _buildEmptyState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF3E3E42)),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            color: Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              decoration: const InputDecoration(
                hintText: 'Type a command or search...',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: _filterCommands,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF3E3E42),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Esc',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandList() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _filteredCommands.length,
        itemBuilder: (context, index) {
          final command = _filteredCommands[index];
          final isSelected = index == _selectedIndex;

          return _buildCommandItem(command, isSelected);
        },
      ),
    );
  }

  Widget _buildCommandItem(Command command, bool isSelected) {
    return InkWell(
      onTap: () => _executeCommand(command),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? const Color(0xFF094771) : null,
        child: Row(
          children: [
            // Command icon
            if (command.icon != null) ...[
              Icon(
                command.icon,
                size: 18,
                color: command.iconColor ?? Colors.grey,
              ),
              const SizedBox(width: 12),
            ],

            // Command label and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Category badge
                      if (command.category != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(command.category!),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            command.category!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Label
                      Flexible(
                        child: Text(
                          command.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Description
                  if (command.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      command.description!,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Keyboard shortcut
            if (command.shortcut != null) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3E3E42),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFF555555),
                  ),
                ),
                child: Text(
                  command.shortcut!,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No commands found',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search query',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'file':
        return Colors.blue[700]!;
      case 'edit':
        return Colors.green[700]!;
      case 'view':
        return Colors.purple[700]!;
      case 'navigate':
        return Colors.orange[700]!;
      case 'refactor':
        return Colors.cyan[700]!;
      case 'lsp':
        return Colors.indigo[700]!;
      case 'settings':
        return Colors.grey[700]!;
      default:
        return Colors.grey[700]!;
    }
  }
}

/// Command model
class Command {
  final String id;
  final String label;
  final VoidCallback action;
  final String? category;
  final String? description;
  final String? shortcut;
  final IconData? icon;
  final Color? iconColor;

  const Command({
    required this.id,
    required this.label,
    required this.action,
    this.category,
    this.description,
    this.shortcut,
    this.icon,
    this.iconColor,
  });
}

/// Default IDE commands
class DefaultCommands {
  static List<Command> getCommands({
    VoidCallback? onNewFile,
    VoidCallback? onOpenFile,
    VoidCallback? onSave,
    VoidCallback? onSaveAs,
    VoidCallback? onUndo,
    VoidCallback? onRedo,
    VoidCallback? onFormat,
    VoidCallback? onGoToLine,
    VoidCallback? onFindReferences,
    VoidCallback? onRename,
    VoidCallback? onSettings,
  }) {
    return [
      // File commands
      Command(
        id: 'file.new',
        label: 'New File',
        action: onNewFile ?? () {},
        category: 'File',
        shortcut: 'Ctrl+N',
        icon: Icons.insert_drive_file,
        iconColor: Colors.blue,
      ),
      Command(
        id: 'file.open',
        label: 'Open File',
        action: onOpenFile ?? () {},
        category: 'File',
        shortcut: 'Ctrl+O',
        icon: Icons.folder_open,
        iconColor: Colors.blue,
      ),
      Command(
        id: 'file.save',
        label: 'Save',
        action: onSave ?? () {},
        category: 'File',
        shortcut: 'Ctrl+S',
        icon: Icons.save,
        iconColor: Colors.blue,
      ),
      Command(
        id: 'file.saveAs',
        label: 'Save As...',
        action: onSaveAs ?? () {},
        category: 'File',
        shortcut: 'Ctrl+Shift+S',
        icon: Icons.save_as,
        iconColor: Colors.blue,
      ),

      // Edit commands
      Command(
        id: 'edit.undo',
        label: 'Undo',
        action: onUndo ?? () {},
        category: 'Edit',
        shortcut: 'Ctrl+Z',
        icon: Icons.undo,
        iconColor: Colors.green,
      ),
      Command(
        id: 'edit.redo',
        label: 'Redo',
        action: onRedo ?? () {},
        category: 'Edit',
        shortcut: 'Ctrl+Y',
        icon: Icons.redo,
        iconColor: Colors.green,
      ),
      Command(
        id: 'edit.format',
        label: 'Format Document',
        action: onFormat ?? () {},
        category: 'Edit',
        description: 'Format the entire document',
        shortcut: 'Shift+Alt+F',
        icon: Icons.format_align_left,
        iconColor: Colors.green,
      ),

      // Navigate commands
      Command(
        id: 'navigate.goToLine',
        label: 'Go to Line',
        action: onGoToLine ?? () {},
        category: 'Navigate',
        shortcut: 'Ctrl+G',
        icon: Icons.arrow_forward,
        iconColor: Colors.orange,
      ),

      // LSP commands
      Command(
        id: 'lsp.findReferences',
        label: 'Find All References',
        action: onFindReferences ?? () {},
        category: 'LSP',
        description: 'Find all references to symbol',
        shortcut: 'Shift+F12',
        icon: Icons.search,
        iconColor: Colors.indigo,
      ),
      Command(
        id: 'lsp.rename',
        label: 'Rename Symbol',
        action: onRename ?? () {},
        category: 'LSP',
        description: 'Rename symbol across workspace',
        shortcut: 'F2',
        icon: Icons.edit,
        iconColor: Colors.indigo,
      ),

      // Settings
      Command(
        id: 'settings.open',
        label: 'Open Settings',
        action: onSettings ?? () {},
        category: 'Settings',
        shortcut: 'Ctrl+,',
        icon: Icons.settings,
        iconColor: Colors.grey,
      ),
    ];
  }
}
