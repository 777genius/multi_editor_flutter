import 'package:flutter/material.dart';
import '../models/search_models.dart';

/// Widget to display global search results
///
/// Shows results grouped by file with syntax highlighting of matches.
class SearchResultsWidget extends StatefulWidget {
  /// Search results to display
  final SearchResults results;

  /// Callback when a match is clicked
  final void Function(SearchMatch match)? onMatchTap;

  /// Whether to show context lines
  final bool showContext;

  const SearchResultsWidget({
    super.key,
    required this.results,
    this.onMatchTap,
    this.showContext = true,
  });

  @override
  State<SearchResultsWidget> createState() => _SearchResultsWidgetState();
}

class _SearchResultsWidgetState extends State<SearchResultsWidget> {
  late Map<String, List<SearchMatch>> _groupedMatches;
  final Set<String> _expandedFiles = {};

  @override
  void initState() {
    super.initState();
    _updateGroupedMatches();
  }

  @override
  void didUpdateWidget(SearchResultsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.results != widget.results) {
      _updateGroupedMatches();
    }
  }

  void _updateGroupedMatches() {
    _groupedMatches = widget.results.groupByFile();
    // Auto-expand first file
    if (_groupedMatches.isNotEmpty) {
      _expandedFiles.add(_groupedMatches.keys.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.results.matches.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildSummary(),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: _groupedMatches.length,
            itemBuilder: (context, index) {
              final filePath = _groupedMatches.keys.elementAt(index);
              final matches = _groupedMatches[filePath]!;
              return _buildFileGroup(filePath, matches);
            },
          ),
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
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '${widget.results.totalMatches} matches in ${widget.results.filesWithMatches} files',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            '${widget.results.durationMs}ms',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileGroup(String filePath, List<SearchMatch> matches) {
    final isExpanded = _expandedFiles.contains(filePath);
    final fileName = filePath.split('/').last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedFiles.remove(filePath);
              } else {
                _expandedFiles.add(filePath);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.description,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        filePath,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${matches.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          ...matches.map((match) => _buildMatchItem(match)),
      ],
    );
  }

  Widget _buildMatchItem(SearchMatch match) {
    return InkWell(
      onTap: () => widget.onMatchTap?.call(match),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line number and match
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '${match.lineNumber}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  child: _buildHighlightedLine(match),
                ),
              ],
            ),
            // Context lines (if enabled)
            if (widget.showContext) ...[
              if (match.contextBefore.isNotEmpty)
                _buildContextLines(match.contextBefore, match.lineNumber - match.contextBefore.length),
              if (match.contextAfter.isNotEmpty)
                _buildContextLines(match.contextAfter, match.lineNumber + 1),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedLine(SearchMatch match) {
    final before = match.lineContent.substring(0, match.column);
    final matched = match.lineContent.substring(
      match.column,
      (match.column + match.matchLength).clamp(0, match.lineContent.length),
    );
    final after = match.lineContent.substring(
      (match.column + match.matchLength).clamp(0, match.lineContent.length),
    );

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: Colors.black87,
        ),
        children: [
          TextSpan(text: before),
          TextSpan(
            text: matched,
            style: TextStyle(
              backgroundColor: Colors.yellow.withOpacity(0.3),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }

  Widget _buildContextLines(List<String> lines, int startLineNumber) {
    return Padding(
      padding: const EdgeInsets.only(left: 50, top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.asMap().entries.map((entry) {
          final idx = entry.key;
          final line = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(
              line,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Search input widget with options
class SearchInputWidget extends StatefulWidget {
  /// Callback when search is triggered
  final void Function(SearchConfig config) onSearch;

  /// Initial pattern
  final String? initialPattern;

  const SearchInputWidget({
    super.key,
    required this.onSearch,
    this.initialPattern,
  });

  @override
  State<SearchInputWidget> createState() => _SearchInputWidgetState();
}

class _SearchInputWidgetState extends State<SearchInputWidget> {
  late TextEditingController _controller;
  bool _useRegex = false;
  bool _caseSensitive = false;
  bool _showOptions = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPattern);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _performSearch() {
    if (_controller.text.isEmpty) return;

    final config = SearchConfig(
      pattern: _controller.text,
      useRegex: _useRegex,
      caseInsensitive: !_caseSensitive,
    );

    widget.onSearch(config);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Search in files...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.settings,
                            color: _showOptions ? Theme.of(context).colorScheme.primary : null,
                          ),
                          onPressed: () {
                            setState(() => _showOptions = !_showOptions);
                          },
                          tooltip: 'Search options',
                        ),
                      ],
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _performSearch,
                icon: const Icon(Icons.search),
                label: const Text('Search'),
              ),
            ],
          ),
        ),
        if (_showOptions)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            child: Row(
              children: [
                Checkbox(
                  value: _useRegex,
                  onChanged: (value) {
                    setState(() => _useRegex = value ?? false);
                  },
                ),
                const Text('Use Regex'),
                const SizedBox(width: 16),
                Checkbox(
                  value: _caseSensitive,
                  onChanged: (value) {
                    setState(() => _caseSensitive = value ?? false);
                  },
                ),
                const Text('Case Sensitive'),
              ],
            ),
          ),
      ],
    );
  }
}
