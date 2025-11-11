import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lsp_domain/lsp_domain.dart';

/// CompletionPopup
///
/// Popup widget that displays code completion suggestions from LSP.
///
/// Architecture (Clean Architecture + MobX):
/// ```
/// CompletionPopup (UI Widget)
///     ↓ receives
/// CompletionList (Domain Entity from LSP)
///     ↓ selected by user
/// onSelected callback (triggers insertText action)
/// ```
///
/// Responsibilities:
/// - Displays completion items
/// - Handles keyboard navigation (up/down arrows)
/// - Handles selection (Enter key or click)
/// - Filters completions by typing
///
/// Example:
/// ```dart
/// CompletionPopup(
///   completions: completionList,
///   onSelected: (item) {
///     editorStore.insertText(item.insertText);
///   },
///   onDismissed: () {
///     // Close popup
///   },
/// )
/// ```
class CompletionPopup extends StatefulWidget {
  final CompletionList completions;
  final void Function(CompletionItem) onSelected;
  final VoidCallback? onDismissed;
  final Offset? position;

  const CompletionPopup({
    super.key,
    required this.completions,
    required this.onSelected,
    this.onDismissed,
    this.position,
  });

  @override
  State<CompletionPopup> createState() => _CompletionPopupState();
}

class _CompletionPopupState extends State<CompletionPopup> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus to capture keyboard events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      _moveSelection(1);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _moveSelection(-1);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.tab) {
      _selectCurrent();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.escape) {
      widget.onDismissed?.call();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _moveSelection(int delta) {
    setState(() {
      _selectedIndex = (_selectedIndex + delta).clamp(
        0,
        widget.completions.items.length - 1,
      );
    });

    // Scroll to selected item
    _scrollToSelected();
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;
    if (widget.completions.items.isEmpty) return;

    final itemHeight = 40.0;
    final selectedPosition = _selectedIndex * itemHeight;
    final visibleHeight = _scrollController.position.viewportDimension;

    if (selectedPosition < _scrollController.offset) {
      // Scroll up - ensure not negative
      _scrollController.animateTo(
        selectedPosition.clamp(0.0, double.infinity),
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    } else if (selectedPosition + itemHeight >
        _scrollController.offset + visibleHeight) {
      // Scroll down - ensure target is not negative
      final targetScroll = selectedPosition + itemHeight - visibleHeight;
      _scrollController.animateTo(
        targetScroll.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  void _selectCurrent() {
    if (_selectedIndex >= 0 &&
        _selectedIndex < widget.completions.items.length) {
      widget.onSelected(widget.completions.items[_selectedIndex]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            color: const Color(0xFF252526), // VS Code dark
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF3E3E42),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(),

              // Completion items
              Flexible(
                child: ListView.builder(
                  controller: _scrollController,
                  shrinkWrap: true,
                  itemCount: widget.completions.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.completions.items[index];
                    final isSelected = index == _selectedIndex;

                    return _buildCompletionItem(item, isSelected, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D30),
        border: Border(
          bottom: BorderSide(color: Color(0xFF3E3E42), width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: Color(0xFF4EC9B0),
          ),
          const SizedBox(width: 8),
          Text(
            'Suggestions (${widget.completions.items.length})',
            style: const TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            'Tab to accept',
            style: TextStyle(
              color: const Color(0xFFCCCCCC).withOpacity(0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionItem(
    CompletionItem item,
    bool isSelected,
    int index,
  ) {
    return InkWell(
      onTap: () => widget.onSelected(item),
      onHover: (hovering) {
        if (hovering) {
          setState(() => _selectedIndex = index);
        }
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: isSelected
            ? const Color(0xFF094771) // VS Code selected item
            : Colors.transparent,
        child: Row(
          children: [
            // Icon based on completion kind
            _buildCompletionIcon(item.kind),
            const SizedBox(width: 12),

            // Label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.detail != null && item.detail!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.detail!,
                      style: TextStyle(
                        color: const Color(0xFFCCCCCC).withOpacity(0.6),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Sort text (if different from label)
            if (item.sortText != null && item.sortText != item.label)
              Text(
                item.sortText!,
                style: TextStyle(
                  color: const Color(0xFFCCCCCC).withOpacity(0.4),
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionIcon(CompletionItemKind? kind) {
    IconData icon;
    Color color;

    switch (kind) {
      case CompletionItemKind.method:
      case CompletionItemKind.function:
      case CompletionItemKind.constructor:
        icon = Icons.functions;
        color = const Color(0xFFDCDCAA); // Yellow
        break;
      case CompletionItemKind.variable:
      case CompletionItemKind.field:
      case CompletionItemKind.property:
        icon = Icons.adjust;
        color = const Color(0xFF4FC1FF); // Blue
        break;
      case CompletionItemKind.class_:
      case CompletionItemKind.interface:
      case CompletionItemKind.struct:
        icon = Icons.class_;
        color = const Color(0xFF4EC9B0); // Teal
        break;
      case CompletionItemKind.keyword:
        icon = Icons.key;
        color = const Color(0xFFC586C0); // Purple
        break;
      case CompletionItemKind.snippet:
        icon = Icons.code;
        color = const Color(0xFFCE9178); // Orange
        break;
      default:
        icon = Icons.text_fields;
        color = const Color(0xFFCCCCCC); // Gray
    }

    return Icon(icon, size: 16, color: color);
  }
}
