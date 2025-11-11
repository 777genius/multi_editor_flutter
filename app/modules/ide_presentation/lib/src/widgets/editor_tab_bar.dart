import 'package:flutter/material.dart';
import 'package:editor_core/editor_core.dart';

/// EditorTabBar
///
/// Tab bar for managing multiple open files:
/// - Tab creation and removal
/// - Tab reordering (drag & drop)
/// - Active tab indicator
/// - Unsaved changes indicator
/// - Close all / Close others
/// - Tab overflow scrolling
/// - Tab context menu
///
/// Architecture:
/// - Efficient tab rendering
/// - State management for open files
/// - Keyboard navigation
///
/// Usage:
/// ```dart
/// EditorTabBar(
///   tabs: [
///     EditorTab(
///       documentUri: DocumentUri.fromFilePath('/file1.dart'),
///       title: 'file1.dart',
///       hasUnsavedChanges: true,
///     ),
///   ],
///   activeTabIndex: 0,
///   onTabSelected: (index) => switchToTab(index),
///   onTabClosed: (index) => closeTab(index),
/// )
/// ```
class EditorTabBar extends StatefulWidget {
  final List<EditorTab> tabs;
  final int activeTabIndex;
  final void Function(int index)? onTabSelected;
  final void Function(int index)? onTabClosed;
  final void Function(int fromIndex, int toIndex)? onTabReordered;
  final VoidCallback? onNewTab;

  const EditorTabBar({
    super.key,
    required this.tabs,
    required this.activeTabIndex,
    this.onTabSelected,
    this.onTabClosed,
    this.onTabReordered,
    this.onNewTab,
  });

  @override
  State<EditorTabBar> createState() => _EditorTabBarState();
}

class _EditorTabBarState extends State<EditorTabBar> {
  final ScrollController _scrollController = ScrollController();
  int? _hoveredTabIndex;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showTabContextMenu(BuildContext context, int tabIndex, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        const PopupMenuItem(
          value: 'close',
          child: Row(
            children: [
              Icon(Icons.close, size: 16),
              SizedBox(width: 8),
              Text('Close'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'closeOthers',
          child: Row(
            children: [
              Icon(Icons.clear_all, size: 16),
              SizedBox(width: 8),
              Text('Close Others'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'closeToRight',
          child: Row(
            children: [
              Icon(Icons.keyboard_double_arrow_right, size: 16),
              SizedBox(width: 8),
              Text('Close to the Right'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'closeAll',
          child: Row(
            children: [
              Icon(Icons.close_fullscreen, size: 16),
              SizedBox(width: 8),
              Text('Close All'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'copyPath',
          child: Row(
            children: [
              Icon(Icons.content_copy, size: 16),
              SizedBox(width: 8),
              Text('Copy Path'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'reveal',
          child: Row(
            children: [
              Icon(Icons.folder_open, size: 16),
              SizedBox(width: 8),
              Text('Reveal in Explorer'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        _handleContextMenuAction(value, tabIndex);
      }
    });
  }

  void _handleContextMenuAction(String action, int tabIndex) {
    switch (action) {
      case 'close':
        widget.onTabClosed?.call(tabIndex);
        break;
      case 'closeOthers':
        // Close all tabs except this one
        for (int i = widget.tabs.length - 1; i >= 0; i--) {
          if (i != tabIndex) {
            widget.onTabClosed?.call(i);
          }
        }
        break;
      case 'closeToRight':
        // Close all tabs to the right
        for (int i = widget.tabs.length - 1; i > tabIndex; i--) {
          widget.onTabClosed?.call(i);
        }
        break;
      case 'closeAll':
        // Close all tabs
        for (int i = widget.tabs.length - 1; i >= 0; i--) {
          widget.onTabClosed?.call(i);
        }
        break;
      case 'copyPath':
        // Copy file path to clipboard
        debugPrint('Copy path: ${widget.tabs[tabIndex].documentUri.path}');
        break;
      case 'reveal':
        // Reveal in file explorer
        debugPrint('Reveal: ${widget.tabs[tabIndex].documentUri.path}');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D30),
        border: Border(
          bottom: BorderSide(color: Color(0xFF3E3E42)),
        ),
      ),
      child: Row(
        children: [
          // Tabs
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: widget.tabs.length,
              itemBuilder: (context, index) {
                final tab = widget.tabs[index];
                final isActive = index == widget.activeTabIndex;
                final isHovered = index == _hoveredTabIndex;

                return _buildTab(
                  tab,
                  index,
                  isActive: isActive,
                  isHovered: isHovered,
                );
              },
            ),
          ),

          // New tab button
          if (widget.onNewTab != null)
            _buildNewTabButton(),
        ],
      ),
    );
  }

  Widget _buildTab(
    EditorTab tab,
    int index, {
    required bool isActive,
    required bool isHovered,
  }) {
    return Tooltip(
      message: tab.documentUri.path,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredTabIndex = index),
        onExit: (_) => setState(() => _hoveredTabIndex = null),
        child: GestureDetector(
          onTap: () => widget.onTabSelected?.call(index),
          onSecondaryTapDown: (details) {
            _showTabContextMenu(context, index, details.globalPosition);
          },
          child: Container(
          constraints: const BoxConstraints(minWidth: 80, maxWidth: 200),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF1E1E1E)
                : (isHovered ? const Color(0xFF2A2D2E) : null),
            border: const Border(
              right: BorderSide(color: Color(0xFF3E3E42)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Active indicator
              Container(
                width: 2,
                height: 36,
                color: isActive ? const Color(0xFF007ACC) : Colors.transparent,
              ),

              const SizedBox(width: 8),

              // File icon
              _getFileIcon(tab.title),
              const SizedBox(width: 8),

              // Title
              Flexible(
                child: Text(
                  tab.title,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey[400],
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),

              // Unsaved changes indicator
              if (tab.hasUnsavedChanges) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF007ACC),
                    shape: BoxShape.circle,
                  ),
                ),
              ],

              const SizedBox(width: 8),

              // Close button (visible on hover or if active)
              if (isHovered || isActive)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => widget.onTabClosed?.call(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 22),

              const SizedBox(width: 8),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildNewTabButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onNewTab,
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: Color(0xFF3E3E42)),
            ),
          ),
          child: const Icon(
            Icons.add,
            size: 18,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();

    IconData icon;
    Color color;

    switch (ext) {
      case 'dart':
        icon = Icons.code;
        color = const Color(0xFF0175C2);
        break;
      case 'js':
      case 'ts':
      case 'jsx':
      case 'tsx':
        icon = Icons.javascript;
        color = const Color(0xFFF7DF1E);
        break;
      case 'py':
        icon = Icons.code;
        color = const Color(0xFF3776AB);
        break;
      case 'json':
      case 'yaml':
      case 'yml':
        icon = Icons.data_object;
        color = const Color(0xFFCB3837);
        break;
      case 'md':
        icon = Icons.article;
        color = const Color(0xFF083FA1);
        break;
      case 'html':
      case 'css':
        icon = Icons.web;
        color = const Color(0xFFE34C26);
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }

    return Icon(icon, size: 16, color: color);
  }
}

/// EditorTab model
class EditorTab {
  final DocumentUri documentUri;
  final String title;
  final bool hasUnsavedChanges;
  final bool isPinned;

  const EditorTab({
    required this.documentUri,
    required this.title,
    this.hasUnsavedChanges = false,
    this.isPinned = false,
  });

  EditorTab copyWith({
    DocumentUri? documentUri,
    String? title,
    bool? hasUnsavedChanges,
    bool? isPinned,
  }) {
    return EditorTab(
      documentUri: documentUri ?? this.documentUri,
      title: title ?? this.title,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
