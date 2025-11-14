import 'package:flutter/material.dart';
import '../models/minimap_data.dart';

/// Visual minimap widget that displays code overview
///
/// Shows a simplified view of the entire file with:
/// - Color-coded lines (code, comments, empty)
/// - Indentation visualization
/// - Current viewport indicator
/// - Click to navigate
class MinimapWidget extends StatefulWidget {
  /// Minimap data to display
  final MinimapData data;

  /// Width of the minimap
  final double width;

  /// Height of the minimap (if null, uses available height)
  final double? height;

  /// Current scroll position (0.0 to 1.0)
  final double scrollPosition;

  /// Viewport height as fraction of total (0.0 to 1.0)
  final double viewportFraction;

  /// Callback when user clicks on minimap
  final ValueChanged<double>? onNavigate;

  /// Color theme for minimap
  final MinimapTheme? theme;

  const MinimapWidget({
    super.key,
    required this.data,
    this.width = 100,
    this.height,
    this.scrollPosition = 0.0,
    this.viewportFraction = 0.1,
    this.onNavigate,
    this.theme,
  });

  @override
  State<MinimapWidget> createState() => _MinimapWidgetState();
}

class _MinimapWidgetState extends State<MinimapWidget> {
  MinimapTheme get _theme => widget.theme ?? MinimapTheme.defaultTheme();

  @override
  Widget build(BuildContext context) {
    if (widget.data.lines.isEmpty) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: _theme.backgroundColor,
        child: Center(
          child: Text(
            'No data',
            style: TextStyle(color: _theme.emptyLineColor, fontSize: 10),
          ),
        ),
      );
    }

    return GestureDetector(
      onTapDown: (details) => _handleTap(details.localPosition),
      onPanUpdate: (details) => _handlePan(details.localPosition),
      child: Container(
        width: widget.width,
        height: widget.height,
        color: _theme.backgroundColor,
        child: CustomPaint(
          painter: _MinimapPainter(
            data: widget.data,
            scrollPosition: widget.scrollPosition,
            viewportFraction: widget.viewportFraction,
            theme: _theme,
          ),
        ),
      ),
    );
  }

  void _handleTap(Offset position) {
    if (widget.onNavigate == null) return;

    final height = widget.height ?? 0;
    if (height == 0) return;

    // Convert tap position to scroll position (0.0 to 1.0)
    final scrollPos = (position.dy / height).clamp(0.0, 1.0);
    widget.onNavigate!(scrollPos);
  }

  void _handlePan(Offset position) {
    _handleTap(position);
  }
}

/// Painter for minimap visualization
class _MinimapPainter extends CustomPainter {
  final MinimapData data;
  final double scrollPosition;
  final double viewportFraction;
  final MinimapTheme theme;

  _MinimapPainter({
    required this.data,
    required this.scrollPosition,
    required this.viewportFraction,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // CRITICAL: Check for empty data AND zero totalLines to prevent division by zero
    if (data.lines.isEmpty || data.totalLines == 0) return;

    final lineHeight = size.height / data.totalLines;
    final maxWidth = size.width - 4; // Leave margin

    // Draw each line
    for (var i = 0; i < data.lines.length; i++) {
      final line = data.lines[i];
      // CRITICAL: data.lines.length already checked as non-empty, safe to divide
      final y = i * lineHeight * (data.totalLines / data.lines.length);

      if (y >= size.height) break;

      _drawLine(canvas, line, y, lineHeight, maxWidth);
    }

    // Draw viewport indicator
    _drawViewport(canvas, size);
  }

  void _drawLine(
    Canvas canvas,
    MinimapLine line,
    double y,
    double lineHeight,
    double maxWidth,
  ) {
    if (line.isEmpty) {
      // Empty lines - subtle background
      final paint = Paint()
        ..color = theme.emptyLineColor
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(0, y, maxWidth, lineHeight),
        paint,
      );
      return;
    }

    // CRITICAL: Prevent division by zero if maxLength is 0
    // If maxLength is 0, all lines have zero length, so draw nothing
    if (data.maxLength == 0) return;

    // Calculate visual width based on line length and indent
    final indentWidth = (line.indent / data.maxLength) * maxWidth;
    final contentWidth = (line.length / data.maxLength) * maxWidth;

    // Draw indent (if any)
    if (line.indent > 0) {
      final indentPaint = Paint()
        ..color = theme.indentColor
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(0, y, indentWidth, lineHeight),
        indentPaint,
      );
    }

    // Draw content
    final contentPaint = Paint()
      ..color = line.isComment ? theme.commentColor : theme.codeColor
      ..style = PaintingStyle.fill;

    // Opacity based on density
    final opacity = (line.density / 100.0).clamp(0.3, 1.0);
    contentPaint.color = contentPaint.color.withOpacity(opacity);

    canvas.drawRect(
      Rect.fromLTWH(indentWidth, y, contentWidth, lineHeight),
      contentPaint,
    );
  }

  void _drawViewport(Canvas canvas, Size size) {
    final viewportY = scrollPosition * size.height;
    final viewportHeight = viewportFraction * size.height;

    // Draw viewport rectangle
    final viewportPaint = Paint()
      ..color = theme.viewportColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(
      Rect.fromLTWH(0, viewportY, size.width, viewportHeight),
      viewportPaint,
    );

    // Draw semi-transparent overlay
    final overlayPaint = Paint()
      ..color = theme.viewportColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, viewportY, size.width, viewportHeight),
      overlayPaint,
    );
  }

  @override
  bool shouldRepaint(_MinimapPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.scrollPosition != scrollPosition ||
        oldDelegate.viewportFraction != viewportFraction;
  }
}

/// Color theme for minimap
class MinimapTheme {
  final Color backgroundColor;
  final Color codeColor;
  final Color commentColor;
  final Color emptyLineColor;
  final Color indentColor;
  final Color viewportColor;

  const MinimapTheme({
    required this.backgroundColor,
    required this.codeColor,
    required this.commentColor,
    required this.emptyLineColor,
    required this.indentColor,
    required this.viewportColor,
  });

  factory MinimapTheme.defaultTheme() {
    return const MinimapTheme(
      backgroundColor: Color(0xFF1E1E1E), // Dark background
      codeColor: Color(0xFFD4D4D4),      // Light gray for code
      commentColor: Color(0xFF6A9955),   // Green for comments
      emptyLineColor: Color(0xFF252526), // Subtle dark for empty
      indentColor: Color(0xFF2D2D2D),    // Darker for indent
      viewportColor: Color(0xFF007ACC),  // Blue for viewport
    );
  }

  factory MinimapTheme.light() {
    return const MinimapTheme(
      backgroundColor: Color(0xFFFFFFFF),
      codeColor: Color(0xFF000000),
      commentColor: Color(0xFF008000),
      emptyLineColor: Color(0xFFF5F5F5),
      indentColor: Color(0xFFEEEEEE),
      viewportColor: Color(0xFF0066CC),
    );
  }
}
