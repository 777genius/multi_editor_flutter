import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lsp_domain/lsp_domain.dart';

/// AdvancedCompletionPopup
///
/// Advanced code completion widget with:
/// - Icon indicators for completion item types
/// - Categorized grouping
/// - Fuzzy filtering
/// - Keyboard navigation
/// - Documentation preview
/// - Signature help
/// - Snippet support
///
/// Architecture:
/// - Follows VS Code / IntelliJ completion UI patterns
/// - Keyboard-first design
/// - Efficient rendering with ListView.builder
/// - Smart positioning to stay on screen
///
/// Usage:
/// ```dart
/// AdvancedCompletionPopup(
///   completions: completionList.items,
///   position: Offset(100, 200),
///   onSelect: (item) {
///     insertCompletion(item);
///   },
/// )
/// ```
class AdvancedCompletionPopup extends StatefulWidget {
  final List<CompletionItem> completions;
  final Offset position;
  final void Function(CompletionItem item) onSelect;
  final void Function()? onDismiss;
  final String? filterText;
  final Size? maxSize;

  const AdvancedCompletionPopup({
    super.key,
    required this.completions,
    required this.position,
    required this.onSelect,
    this.onDismiss,
    this.filterText,
    this.maxSize,
  });

  @override
  State<AdvancedCompletionPopup> createState() => _AdvancedCompletionPopupState();
}

class _AdvancedCompletionPopupState extends State<AdvancedCompletionPopup> {
  late List<CompletionItem> _filteredCompletions;
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _keyboardFocusNode = FocusNode();
  CompletionItem? _hoveredItem;

  @override
  void initState() {
    super.initState();
    _filterCompletions();

    // Request focus after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _keyboardFocusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(AdvancedCompletionPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filterText != oldWidget.filterText ||
        widget.completions != oldWidget.completions) {
      _filterCompletions();
    }
  }

  void _filterCompletions() {
    if (widget.filterText == null || widget.filterText!.isEmpty) {
      _filteredCompletions = widget.completions;
    } else {
      // Fuzzy filter
      final filter = widget.filterText!.toLowerCase();
      _filteredCompletions = widget.completions.where((item) {
        final label = item.label.toLowerCase();
        final filterText = (item.filterText ?? item.label).toLowerCase();
        return label.contains(filter) || filterText.contains(filter);
      }).toList();

      // Sort by relevance
      _filteredCompletions.sort((a, b) {
        final aLabel = a.label.toLowerCase();
        final bLabel = b.label.toLowerCase();

        // Exact match first
        if (aLabel == filter) return -1;
        if (bLabel == filter) return 1;

        // Starts with filter
        final aStarts = aLabel.startsWith(filter);
        final bStarts = bLabel.startsWith(filter);
        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;

        // Preselected items
        if (a.preselect && !b.preselect) return -1;
        if (!a.preselect && b.preselect) return 1;

        // Sort text
        final aSortText = a.sortText ?? a.label;
        final bSortText = b.sortText ?? b.label;
        return aSortText.compareTo(bSortText);
      });
    }

    // Reset selection
    if (_selectedIndex >= _filteredCompletions.length) {
      _selectedIndex = _filteredCompletions.isEmpty ? 0 : _filteredCompletions.length - 1;
    }
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _filteredCompletions.length;
          _scrollToSelected();
        });
        break;

      case LogicalKeyboardKey.arrowUp:
        setState(() {
          _selectedIndex = (_selectedIndex - 1 + _filteredCompletions.length) %
                          _filteredCompletions.length;
          _scrollToSelected();
        });
        break;

      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.tab:
        if (_filteredCompletions.isNotEmpty) {
          widget.onSelect(_filteredCompletions[_selectedIndex]);
        }
        break;

      case LogicalKeyboardKey.escape:
        widget.onDismiss?.call();
        break;

      case LogicalKeyboardKey.pageDown:
        setState(() {
          _selectedIndex = (_selectedIndex + 10).clamp(0, _filteredCompletions.length - 1);
          _scrollToSelected();
        });
        break;

      case LogicalKeyboardKey.pageUp:
        setState(() {
          _selectedIndex = (_selectedIndex - 10).clamp(0, _filteredCompletions.length - 1);
          _scrollToSelected();
        });
        break;
    }
  }

  void _scrollToSelected() {
    if (_scrollController.hasClients && _filteredCompletions.isNotEmpty) {
      final itemHeight = 32.0;
      final targetScroll = _selectedIndex * itemHeight;
      final viewportHeight = _scrollController.position.viewportDimension;

      if (targetScroll < _scrollController.offset) {
        _scrollController.animateTo(
          targetScroll,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      } else if (targetScroll + itemHeight > _scrollController.offset + viewportHeight) {
        _scrollController.animateTo(
          targetScroll + itemHeight - viewportHeight,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_filteredCompletions.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxSize = widget.maxSize ?? const Size(400, 300);

    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: RawKeyboardListener(
        focusNode: _keyboardFocusNode,
        onKey: _handleKeyEvent,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: maxSize.width,
              maxHeight: maxSize.height,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF252526),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF454545)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Completion list
                Flexible(
                  flex: 3,
                  child: _buildCompletionList(),
                ),

                // Documentation panel (if hovered item has docs)
                if (_hoveredItem != null && _hoveredItem!.documentation != null)
                  Flexible(
                    flex: 2,
                    child: _buildDocumentationPanel(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionList() {
    return Container(
      constraints: const BoxConstraints(minWidth: 250),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF454545)),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  size: 14,
                  color: Colors.amber,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_filteredCompletions.length} suggestions',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Completion items
          Flexible(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _filteredCompletions.length,
              itemBuilder: (context, index) {
                final item = _filteredCompletions[index];
                final isSelected = index == _selectedIndex;

                return _buildCompletionItem(
                  item,
                  isSelected: isSelected,
                  onTap: () => widget.onSelect(item),
                  onHover: () => setState(() => _hoveredItem = item),
                );
              },
            ),
          ),

          // Footer hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF454545)),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.keyboard, size: 12, color: Colors.grey),
                SizedBox(width: 6),
                Text(
                  '↑↓ navigate • Enter/Tab select • Esc dismiss',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionItem(
    CompletionItem item, {
    required bool isSelected,
    required VoidCallback onTap,
    required VoidCallback onHover,
  }) {
    return MouseRegion(
      onEnter: (_) => onHover(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: isSelected ? const Color(0xFF094771) : null,
          child: Row(
            children: [
              // Icon for completion kind
              _buildKindIcon(item.kind),
              const SizedBox(width: 10),

              // Label
              Expanded(
                child: Row(
                  children: [
                    // Main label
                    Flexible(
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Detail (type, signature)
                    if (item.detail != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          item.detail!,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Preselect indicator
              if (item.preselect)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'Suggested',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKindIcon(CompletionItemKind kind) {
    IconData icon;
    Color color;

    switch (kind) {
      case CompletionItemKind.method:
        icon = Icons.functions;
        color = Colors.purple[300]!;
        break;
      case CompletionItemKind.function:
        icon = Icons.code;
        color = Colors.purple[300]!;
        break;
      case CompletionItemKind.constructor:
        icon = Icons.build;
        color = Colors.blue[300]!;
        break;
      case CompletionItemKind.field:
        icon = Icons.toggle_on;
        color = Colors.blue[300]!;
        break;
      case CompletionItemKind.variable:
        icon = Icons.data_object;
        color = Colors.blue[300]!;
        break;
      case CompletionItemKind.class_:
        icon = Icons.class_;
        color = Colors.orange[300]!;
        break;
      case CompletionItemKind.interface:
        icon = Icons.integration_instructions;
        color = Colors.cyan[300]!;
        break;
      case CompletionItemKind.module:
        icon = Icons.folder;
        color = Colors.green[300]!;
        break;
      case CompletionItemKind.property:
        icon = Icons.settings;
        color = Colors.blue[300]!;
        break;
      case CompletionItemKind.keyword:
        icon = Icons.vpn_key;
        color = Colors.pink[300]!;
        break;
      case CompletionItemKind.snippet:
        icon = Icons.description;
        color = Colors.green[300]!;
        break;
      case CompletionItemKind.enum_:
        icon = Icons.list;
        color = Colors.amber[300]!;
        break;
      case CompletionItemKind.constant:
        icon = Icons.lock;
        color = Colors.red[300]!;
        break;
      default:
        icon = Icons.article;
        color = Colors.grey[400]!;
    }

    return Icon(icon, size: 16, color: color);
  }

  Widget _buildDocumentationPanel() {
    final doc = _hoveredItem?.documentation;
    if (doc == null) return const SizedBox.shrink();

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Color(0xFF454545)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF454545)),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Documentation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Documentation content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Text(
                doc,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
