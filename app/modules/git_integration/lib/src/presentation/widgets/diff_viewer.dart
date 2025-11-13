import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/github-dark.dart';
import '../../domain/entities/diff_hunk.dart';
import '../providers/diff_state_provider.dart';

/// Diff viewer widget
///
/// Shows diff with two view modes:
/// - Side-by-side: old and new versions side by side
/// - Unified: classic unified diff view
class DiffViewer extends ConsumerStatefulWidget {
  final String? filePath;
  final List<DiffHunk>? hunks;

  const DiffViewer({
    super.key,
    this.filePath,
    this.hunks,
  });

  @override
  ConsumerState<DiffViewer> createState() => _DiffViewerState();
}

class _DiffViewerState extends ConsumerState<DiffViewer> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diffState = ref.watch(diffNotifierProvider);
    final hunks = widget.hunks ?? diffState.selectedDiff ?? [];

    if (hunks.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildToolbar(context, diffState),
        const Divider(height: 1),
        Expanded(
          child: _buildDiffView(context, hunks, diffState.viewMode),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.difference,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Diff Available',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Select a file to view its changes',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, DiffState diffState) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          if (widget.filePath != null) ...[
            Icon(
              Icons.insert_drive_file,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.filePath!,
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 16),
          ],
          _buildViewModeToggle(diffState.viewMode),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: _copyDiff,
            tooltip: 'Copy Diff',
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeToggle(DiffViewMode mode) {
    return SegmentedButton<DiffViewMode>(
      segments: const [
        ButtonSegment(
          value: DiffViewMode.sideBySide,
          icon: Icon(Icons.view_column, size: 18),
          label: Text('Side by Side'),
        ),
        ButtonSegment(
          value: DiffViewMode.unified,
          icon: Icon(Icons.view_agenda, size: 18),
          label: Text('Unified'),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (Set<DiffViewMode> selection) {
        ref
            .read(diffNotifierProvider.notifier)
            .setViewMode(selection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildDiffView(
    BuildContext context,
    List<DiffHunk> hunks,
    DiffViewMode mode,
  ) {
    return mode == DiffViewMode.sideBySide
        ? _buildSideBySideView(context, hunks)
        : _buildUnifiedView(context, hunks);
  }

  Widget _buildSideBySideView(BuildContext context, List<DiffHunk> hunks) {
    return Row(
      children: [
        Expanded(child: _buildOldVersion(context, hunks)),
        const VerticalDivider(width: 1),
        Expanded(child: _buildNewVersion(context, hunks)),
      ],
    );
  }

  Widget _buildOldVersion(BuildContext context, List<DiffHunk> hunks) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: hunks.length,
      itemBuilder: (context, index) {
        final hunk = hunks[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHunkHeader(context, hunk),
            ...hunk.lines.where((line) =>
                line.type == DiffLineType.removed ||
                line.type == DiffLineType.context
            ).map((line) => _buildDiffLine(
                  context,
                  line: line,
                  isOldVersion: true,
                )),
          ],
        );
      },
    );
  }

  Widget _buildNewVersion(BuildContext context, List<DiffHunk> hunks) {
    return ListView.builder(
      itemCount: hunks.length,
      itemBuilder: (context, index) {
        final hunk = hunks[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHunkHeader(context, hunk),
            ...hunk.lines.where((line) =>
                line.type == DiffLineType.added ||
                line.type == DiffLineType.context
            ).map((line) => _buildDiffLine(
                  context,
                  line: line,
                  isOldVersion: false,
                )),
          ],
        );
      },
    );
  }

  Widget _buildUnifiedView(BuildContext context, List<DiffHunk> hunks) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: hunks.length,
      itemBuilder: (context, index) {
        final hunk = hunks[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHunkHeader(context, hunk),
            ...hunk.lines.map((line) => _buildDiffLine(
                  context,
                  line: line,
                  isUnified: true,
                )),
          ],
        );
      },
    );
  }

  Widget _buildHunkHeader(BuildContext context, DiffHunk hunk) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Text(
        hunk.header,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildDiffLine(
    BuildContext context, {
    required DiffLine line,
    bool isOldVersion = false,
    bool isUnified = false,
  }) {
    Color? backgroundColor;
    Color? textColor;
    String lineNumberText = '';

    if (line.type == DiffLineType.added) {
      backgroundColor = Colors.green.withOpacity(0.2);
      textColor = Colors.green[900];
      if (isUnified) {
        lineNumberText =
            '    ${line.newLineNumber.toNullable() ?? ""}';
      } else {
        lineNumberText = '${line.newLineNumber.toNullable() ?? ""}';
      }
    } else if (line.type == DiffLineType.removed) {
      backgroundColor = Colors.red.withOpacity(0.2);
      textColor = Colors.red[900];
      if (isUnified) {
        lineNumberText =
            '${line.oldLineNumber.toNullable() ?? ""}    ';
      } else {
        lineNumberText = '${line.oldLineNumber.toNullable() ?? ""}';
      }
    } else {
      // Context line
      if (isUnified) {
        lineNumberText =
            '${line.oldLineNumber.toNullable() ?? ""} ${line.newLineNumber.toNullable() ?? ""}';
      } else if (isOldVersion) {
        lineNumberText = '${line.oldLineNumber.toNullable() ?? ""}';
      } else {
        lineNumberText = '${line.newLineNumber.toNullable() ?? ""}';
      }
    }

    return Container(
      color: backgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line number gutter
          Container(
            width: isUnified ? 80 : 50,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(
              lineNumberText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          // Diff marker (+/-)
          if (isUnified)
            Container(
              width: 20,
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                line.prefix,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: _buildHighlightedContent(
                context,
                content: line.content,
                textColor: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedContent(
    BuildContext context, {
    required String content,
    Color? textColor,
  }) {
    // Try to detect language from file extension
    final extension = widget.filePath?.split('.').last ?? 'txt';
    final language = _getLanguageFromExtension(extension);

    if (language != null) {
      return HighlightView(
        content,
        language: language,
        theme: Theme.of(context).brightness == Brightness.dark
            ? githubDarkTheme
            : githubTheme,
        padding: EdgeInsets.zero,
        textStyle: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: textColor,
        ),
      );
    }

    return Text(
      content,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        color: textColor,
      ),
    );
  }

  String? _getLanguageFromExtension(String extension) {
    const languageMap = {
      'dart': 'dart',
      'js': 'javascript',
      'ts': 'typescript',
      'jsx': 'javascript',
      'tsx': 'typescript',
      'py': 'python',
      'java': 'java',
      'kt': 'kotlin',
      'swift': 'swift',
      'rs': 'rust',
      'go': 'go',
      'cpp': 'cpp',
      'c': 'c',
      'cs': 'csharp',
      'rb': 'ruby',
      'php': 'php',
      'html': 'xml',
      'xml': 'xml',
      'json': 'json',
      'yaml': 'yaml',
      'yml': 'yaml',
      'md': 'markdown',
      'sh': 'bash',
      'sql': 'sql',
      'css': 'css',
      'scss': 'scss',
    };

    return languageMap[extension.toLowerCase()];
  }

  void _copyDiff() {
    // TODO: Implement copy diff to clipboard
  }
}

/// Diff statistics widget
class DiffStatistics extends ConsumerWidget {
  const DiffStatistics({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(diffStatisticsProvider);

    if (stats == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStat(
            context,
            icon: Icons.add,
            count: stats.additions,
            color: Colors.green,
          ),
          const SizedBox(width: 16),
          _buildStat(
            context,
            icon: Icons.remove,
            count: stats.deletions,
            color: Colors.red,
          ),
          const SizedBox(width: 16),
          _buildStat(
            context,
            icon: Icons.timeline,
            count: stats.changes,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    BuildContext context, {
    required IconData icon,
    required int count,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
