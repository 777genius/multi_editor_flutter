import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lsp_domain/lsp_domain.dart';

/// DiagnosticsPanel
///
/// Bottom panel that displays LSP diagnostics (errors, warnings, info).
///
/// Architecture (Clean Architecture + MobX):
/// ```
/// DiagnosticsPanel (UI Widget)
///     ↓ observes
/// LspStore.diagnostics (Observable<List<Diagnostic>>)
///     ↓ from
/// LSP Server via WebSocket
/// ```
///
/// Responsibilities:
/// - Displays list of diagnostics
/// - Groups by severity (errors, warnings, info)
/// - Allows clicking to jump to diagnostic location
/// - Shows diagnostic details (message, source)
///
/// Example:
/// ```dart
/// DiagnosticsPanel(
///   diagnostics: lspStore.diagnostics,
///   onDiagnosticTap: (diagnostic) {
///     editorStore.setCursorPosition(diagnostic.range.start);
///   },
/// )
/// ```
class DiagnosticsPanel extends StatefulWidget {
  final List<Diagnostic> diagnostics;
  final void Function(Diagnostic)? onDiagnosticTap;
  final VoidCallback? onClose;

  const DiagnosticsPanel({
    super.key,
    required this.diagnostics,
    this.onDiagnosticTap,
    this.onClose,
  });

  @override
  State<DiagnosticsPanel> createState() => _DiagnosticsPanelState();
}

class _DiagnosticsPanelState extends State<DiagnosticsPanel> {
  bool _showErrors = true;
  bool _showWarnings = true;
  bool _showInfos = true;

  @override
  Widget build(BuildContext context) {
    final errors = widget.diagnostics
        .where((d) => d.severity == DiagnosticSeverity.error)
        .toList();
    final warnings = widget.diagnostics
        .where((d) => d.severity == DiagnosticSeverity.warning)
        .toList();
    final infos = widget.diagnostics
        .where((d) =>
            d.severity == DiagnosticSeverity.information ||
            d.severity == DiagnosticSeverity.hint)
        .toList();

    // Apply filters
    final filteredDiagnostics = widget.diagnostics.where((d) {
      if (d.severity == DiagnosticSeverity.error && !_showErrors) return false;
      if (d.severity == DiagnosticSeverity.warning && !_showWarnings) return false;
      if ((d.severity == DiagnosticSeverity.information ||
              d.severity == DiagnosticSeverity.hint) &&
          !_showInfos) return false;
      return true;
    }).toList();

    final screenHeight = MediaQuery.of(context).size.height;
    final panelHeight = (screenHeight * 0.3).clamp(150.0, 400.0);

    return Container(
      height: panelHeight,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E), // VS Code dark
        border: Border(
          top: BorderSide(color: Color(0xFF3E3E42), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(errors.length, warnings.length, infos.length),

          // Diagnostic list
          Expanded(
            child: filteredDiagnostics.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: filteredDiagnostics.length,
                    itemBuilder: (context, index) {
                      return _buildDiagnosticItem(filteredDiagnostics[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int errorCount, int warningCount, int infoCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D30),
        border: Border(
          bottom: BorderSide(color: Color(0xFF3E3E42), width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_outlined,
            size: 16,
            color: Color(0xFFCCCCCC),
          ),
          const SizedBox(width: 8),
          const Text(
            'PROBLEMS',
            style: TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 24),

          // Error filter toggle
          if (errorCount > 0) ...[
            FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error, size: 14, color: Color(0xFFF48771)),
                  const SizedBox(width: 4),
                  Text('$errorCount', style: const TextStyle(fontSize: 12)),
                ],
              ),
              selected: _showErrors,
              onSelected: (value) => setState(() => _showErrors = value),
              backgroundColor: const Color(0xFF3E3E42),
              selectedColor: const Color(0xFF5A1F1F),
              checkmarkColor: const Color(0xFFF48771),
              side: BorderSide.none,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
          ],

          // Warning filter toggle
          if (warningCount > 0) ...[
            FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning, size: 14, color: Color(0xFFCCA700)),
                  const SizedBox(width: 4),
                  Text('$warningCount', style: const TextStyle(fontSize: 12)),
                ],
              ),
              selected: _showWarnings,
              onSelected: (value) => setState(() => _showWarnings = value),
              backgroundColor: const Color(0xFF3E3E42),
              selectedColor: const Color(0xFF4A3C1F),
              checkmarkColor: const Color(0xFFCCA700),
              side: BorderSide.none,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
          ],

          // Info filter toggle
          if (infoCount > 0) ...[
            FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info, size: 14, color: Color(0xFF75BEFF)),
                  const SizedBox(width: 4),
                  Text('$infoCount', style: const TextStyle(fontSize: 12)),
                ],
              ),
              selected: _showInfos,
              onSelected: (value) => setState(() => _showInfos = value),
              backgroundColor: const Color(0xFF3E3E42),
              selectedColor: const Color(0xFF1F3A4A),
              checkmarkColor: const Color(0xFF75BEFF),
              side: BorderSide.none,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],

          const Spacer(),

          // Close button
          if (widget.onClose != null)
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              color: const Color(0xFFCCCCCC),
              onPressed: widget.onClose,
              tooltip: 'Close Problems Panel',
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: Color(0xFF89D185), // Green
          ),
          SizedBox(height: 16),
          Text(
            'No problems found',
            style: TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticItem(Diagnostic diagnostic) {
    final icon = _getDiagnosticIcon(diagnostic.severity);
    final color = _getDiagnosticColor(diagnostic.severity);

    return InkWell(
      onTap: () => widget.onDiagnosticTap?.call(diagnostic),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFF3E3E42), width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message
                  Text(
                    diagnostic.message,
                    style: const TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Location and source
                  Row(
                    children: [
                      // Line number
                      Text(
                        'Ln ${diagnostic.range.start.line + 1}, Col ${diagnostic.range.start.column + 1}',
                        style: TextStyle(
                          color: const Color(0xFFCCCCCC).withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),

                      // Source
                      if (diagnostic.source != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3E3E42),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            diagnostic.source!,
                            style: const TextStyle(
                              color: Color(0xFFCCCCCC),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],

                      // Code
                      if (diagnostic.code != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '[${diagnostic.code}]',
                          style: TextStyle(
                            color: const Color(0xFFCCCCCC).withOpacity(0.5),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Severity badge
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: color, width: 0.5),
              ),
              child: Text(
                _getSeverityLabel(diagnostic.severity),
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDiagnosticIcon(DiagnosticSeverity severity) {
    switch (severity) {
      case DiagnosticSeverity.error:
        return Icons.error;
      case DiagnosticSeverity.warning:
        return Icons.warning;
      case DiagnosticSeverity.information:
        return Icons.info;
      case DiagnosticSeverity.hint:
        return Icons.lightbulb_outline;
    }
  }

  Color _getDiagnosticColor(DiagnosticSeverity severity) {
    switch (severity) {
      case DiagnosticSeverity.error:
        return const Color(0xFFF48771); // Red
      case DiagnosticSeverity.warning:
        return const Color(0xFFCCA700); // Yellow
      case DiagnosticSeverity.information:
        return const Color(0xFF75BEFF); // Blue
      case DiagnosticSeverity.hint:
        return const Color(0xFF89D185); // Green
    }
  }

  String _getSeverityLabel(DiagnosticSeverity severity) {
    switch (severity) {
      case DiagnosticSeverity.error:
        return 'ERROR';
      case DiagnosticSeverity.warning:
        return 'WARN';
      case DiagnosticSeverity.information:
        return 'INFO';
      case DiagnosticSeverity.hint:
        return 'HINT';
    }
  }
}
