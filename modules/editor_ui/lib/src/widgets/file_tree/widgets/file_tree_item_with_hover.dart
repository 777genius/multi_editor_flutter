import 'package:flutter/material.dart';
import '../../../theme/editor_theme_extension.dart';

class FileTreeItemWithHover extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final void Function(TapDownDetails details)? onSecondaryTap;

  const FileTreeItemWithHover({
    super.key,
    required this.child,
    required this.isSelected,
    this.onSecondaryTap,
  });

  @override
  State<FileTreeItemWithHover> createState() => _FileTreeItemWithHoverState();
}

class _FileTreeItemWithHoverState extends State<FileTreeItemWithHover> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final editorTheme = context.editorTheme;

    Color? backgroundColor;
    if (widget.isSelected) {
      backgroundColor = _isHovered
          ? editorTheme.fileTreeSelectionHoverBackground
          : editorTheme.fileTreeSelectionBackground;
    } else if (_isHovered) {
      backgroundColor = editorTheme.fileTreeHoverBackground;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onSecondaryTapDown: widget.onSecondaryTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          color: backgroundColor,
          child: widget.child,
        ),
      ),
    );
  }
}
