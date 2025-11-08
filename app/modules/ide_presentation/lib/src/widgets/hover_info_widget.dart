import 'package:flutter/material.dart';
import 'package:lsp_domain/lsp_domain.dart';

/// HoverInfoWidget
///
/// Tooltip-style widget that displays hover information from LSP.
///
/// Architecture (Clean Architecture):
/// ```
/// HoverInfoWidget (UI Widget)
///     ↓ receives
/// HoverInfo (Domain Entity from LSP)
///     ↓ from
/// GetHoverInfoUseCase
/// ```
///
/// Responsibilities:
/// - Displays hover information (type, documentation)
/// - Positioned near cursor
/// - Dismissible on click outside or Escape
///
/// Example:
/// ```dart
/// HoverInfoWidget(
///   hoverInfo: lspStore.hoverInfo,
///   position: Offset(100, 200),
///   onDismiss: () {
///     // Close hover
///   },
/// )
/// ```
class HoverInfoWidget extends StatelessWidget {
  final HoverInfo hoverInfo;
  final Offset position;
  final VoidCallback? onDismiss;

  const HoverInfoWidget({
    super.key,
    required this.hoverInfo,
    required this.position,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onTap: onDismiss,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 500,
              maxHeight: 300,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E), // VS Code dark
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: const Color(0xFF3E3E42),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: _buildContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent() {
    return [_buildText(hoverInfo.contents)];
  }

  Widget _buildText(String text) {
    // Check if content looks like code (contains backticks or brackets)
    final isCode = text.contains('```') ||
                   text.contains('`') ||
                   (text.contains('{') && text.contains('}'));

    if (isCode) {
      // Display as code block
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF252526),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF3E3E42)),
        ),
        child: SelectableText(
          text.replaceAll('```', '').trim(),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Color(0xFFD4D4D4),
          ),
        ),
      );
    } else {
      // Display as plain text
      return SelectableText(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFFCCCCCC),
        ),
      );
    }
  }
}
