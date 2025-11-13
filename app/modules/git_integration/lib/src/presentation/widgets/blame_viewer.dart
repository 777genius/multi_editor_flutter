import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/blame_line.dart';
import '../providers/blame_state_provider.dart';

/// Blame viewer widget
///
/// Shows git blame information with:
/// - Line-by-line authorship
/// - Heat map visualization (age-based coloring)
/// - Author tooltips with commit details
/// - Author contribution chart
class BlameViewer extends ConsumerStatefulWidget {
  final String filePath;
  final String fileContent;

  const BlameViewer({
    super.key,
    required this.filePath,
    required this.fileContent,
  });

  @override
  ConsumerState<BlameViewer> createState() => _BlameViewerState();
}

class _BlameViewerState extends ConsumerState<BlameViewer> {
  final _scrollController = ScrollController();
  bool _showHeatMap = true;
  bool _showAuthorChart = false;

  @override
  void initState() {
    super.initState();
    _loadBlame();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadBlame() {
    ref.read(blameNotifierProvider.notifier).loadBlame(
          filePath: widget.filePath,
        );
  }

  @override
  Widget build(BuildContext context) {
    final blameState = ref.watch(blameNotifierProvider);

    if (blameState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (blameState.hasError) {
      return _buildErrorState(blameState.error!);
    }

    if (!blameState.hasBlame) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildToolbar(context, blameState),
        const Divider(height: 1),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildBlameContent(context, blameState),
              ),
              if (_showAuthorChart && blameState.authorContribution != null)
                Container(
                  width: 250,
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                  child: _buildAuthorChart(
                      context, blameState.authorContribution!),
                ),
            ],
          ),
        ),
        if (blameState.hasTooltip) _buildTooltip(context, blameState.tooltip!),
      ],
    );
  }

  Widget _buildErrorState(error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load blame',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.userMessage,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadBlame,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Blame Information',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, BlameState blameState) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(
            Icons.history,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.filePath,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          FilterChip(
            label: const Text('Heat Map'),
            selected: _showHeatMap,
            onSelected: (value) {
              setState(() {
                _showHeatMap = value;
              });
            },
            avatar: Icon(
              _showHeatMap ? Icons.thermostat : Icons.thermostat_outlined,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Contributors'),
            selected: _showAuthorChart,
            onSelected: (value) {
              setState(() {
                _showAuthorChart = value;
              });
            },
            avatar: Icon(
              _showAuthorChart ? Icons.people : Icons.people_outline,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: _loadBlame,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildBlameContent(BuildContext context, BlameState blameState) {
    final blameLines = blameState.blameLines;
    final fileLines = widget.fileContent.split('\n');

    return ListView.builder(
      controller: _scrollController,
      itemCount: blameLines.length,
      itemBuilder: (context, index) {
        final blameLine = blameLines[index];
        final content =
            index < fileLines.length ? fileLines[index] : '';

        return _buildBlameLine(
          context,
          blameLine: blameLine,
          content: content,
          isSelected: blameState.selectedLineNumber == blameLine.lineNumber,
        );
      },
    );
  }

  Widget _buildBlameLine(
    BuildContext context, {
    required BlameLine blameLine,
    required String content,
    required bool isSelected,
  }) {
    final commit = blameLine.commit;
    final author = commit.author;
    final age = DateTime.now().difference(commit.authorDate).inDays;

    // Get heat map color
    Color? backgroundColor;
    if (_showHeatMap) {
      backgroundColor = _getHeatMapColor(age)?.withOpacity(0.1);
    }

    if (isSelected) {
      backgroundColor = Theme.of(context).colorScheme.primary.withOpacity(0.1);
    }

    return InkWell(
      onTap: () {
        ref
            .read(blameNotifierProvider.notifier)
            .selectLine(blameLine.lineNumber);
      },
      child: Container(
        color: backgroundColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heat map indicator
            if (_showHeatMap)
              Container(
                width: 4,
                height: 20,
                color: _getHeatMapColor(age),
              ),
            // Line number
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(
                '${blameLine.lineNumber}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: Theme.of(context).colorScheme.outline,
                    ),
                textAlign: TextAlign.right,
              ),
            ),
            // Author info
            Container(
              width: 200,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 8,
                    backgroundColor: _getAuthorColor(author.name),
                    child: Text(
                      author.initials,
                      style: const TextStyle(fontSize: 8, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      author.name,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Commit info
            Container(
              width: 150,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(
                '${commit.hash.short} • ${commit.ageDisplay}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Text(
                  content,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltip(BuildContext context, tooltip) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _getAuthorColor(tooltip.author),
                child: Text(
                  tooltip.author.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tooltip.author,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      tooltip.formattedDate,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  ref.read(blameNotifierProvider.notifier).clearSelection();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.commit,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tooltip.commitHash,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  tooltip.commitMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorChart(
    BuildContext context,
    Map<String, int> authorContribution,
  ) {
    final sortedAuthors = authorContribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Contributors',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: sortedAuthors.length,
            itemBuilder: (context, index) {
              final entry = sortedAuthors[index];
              final author = entry.key;
              final percentage = entry.value;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: _getAuthorColor(author),
                          child: Text(
                            author.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            author,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainer,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getAuthorColor(author),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color? _getHeatMapColor(int age) {
    if (age <= 7) {
      return Colors.green;
    } else if (age <= 30) {
      return Colors.yellow[700];
    } else if (age <= 90) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Color _getAuthorColor(String author) {
    // Generate consistent color based on author name
    final hash = author.hashCode;
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor();
  }
}

/// Blame legend widget
class BlameLegend extends StatelessWidget {
  const BlameLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLegendItem(
            context,
            color: Colors.green,
            label: '< 1 week',
          ),
          const SizedBox(width: 16),
          _buildLegendItem(
            context,
            color: Colors.yellow[700]!,
            label: '< 1 month',
          ),
          const SizedBox(width: 16),
          _buildLegendItem(
            context,
            color: Colors.orange,
            label: '< 3 months',
          ),
          const SizedBox(width: 16),
          _buildLegendItem(
            context,
            color: Colors.red,
            label: '> 3 months',
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context, {
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
