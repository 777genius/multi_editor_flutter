import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// SearchAndReplacePanel
///
/// Advanced search and replace functionality:
/// - Find in current file
/// - Find in all files (workspace search)
/// - Replace in current file
/// - Replace all
/// - Case sensitive search
/// - Whole word match
/// - Regular expression support
/// - Search history
/// - Match highlighting
/// - Navigation between matches
///
/// Architecture:
/// - State management for search options
/// - Efficient text searching algorithm
/// - Match caching for performance
///
/// Usage:
/// ```dart
/// SearchAndReplacePanel(
///   content: editorContent,
///   onSearchResult: (results) => highlightMatches(results),
///   onReplace: (from, to) => replaceText(from, to),
/// )
/// ```
class SearchAndReplacePanel extends StatefulWidget {
  final String? initialSearchQuery;
  final void Function(SearchResults results)? onSearchResult;
  final void Function(String from, String to)? onReplace;
  final void Function(String from, String to)? onReplaceAll;
  final VoidCallback? onClose;

  const SearchAndReplacePanel({
    super.key,
    this.initialSearchQuery,
    this.onSearchResult,
    this.onReplace,
    this.onReplaceAll,
    this.onClose,
  });

  @override
  State<SearchAndReplacePanel> createState() => _SearchAndReplacePanelState();
}

class _SearchAndReplacePanelState extends State<SearchAndReplacePanel> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _replaceFocusNode = FocusNode();

  bool _showReplace = false;
  bool _caseSensitive = false;
  bool _wholeWord = false;
  bool _useRegex = false;
  bool _searchInAllFiles = false;

  int _currentMatchIndex = 0;
  int _totalMatches = 0;
  String? _regexError;

  final List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();

    if (widget.initialSearchQuery != null) {
      _searchController.text = widget.initialSearchQuery!;
      _performSearch();
    }

    _searchController.addListener(_performSearch);
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _replaceController.dispose();
    _searchFocusNode.dispose();
    _replaceFocusNode.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text;

    if (query.isEmpty) {
      setState(() {
        _totalMatches = 0;
        _currentMatchIndex = 0;
        _regexError = null;
      });
      widget.onSearchResult?.call(SearchResults.empty());
      return;
    }

    // Validate regex pattern if regex mode is enabled
    if (_useRegex) {
      try {
        RegExp(query, caseSensitive: _caseSensitive);
        setState(() => _regexError = null);
      } catch (e) {
        setState(() {
          _regexError = e.toString().replaceFirst('FormatException: ', '');
          _totalMatches = 0;
          _currentMatchIndex = 0;
        });
        widget.onSearchResult?.call(SearchResults.empty());
        return;
      }
    }

    // Add to history
    if (!_searchHistory.contains(query)) {
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
    }

    // Perform search (this would be implemented by the editor)
    // For now, just notify with mock results
    final results = SearchResults(
      query: query,
      matches: [], // Would be populated by actual search
      currentIndex: _currentMatchIndex,
      caseSensitive: _caseSensitive,
      wholeWord: _wholeWord,
      useRegex: _useRegex,
    );

    widget.onSearchResult?.call(results);
  }

  void _nextMatch() {
    if (_totalMatches > 0) {
      setState(() {
        _currentMatchIndex = (_currentMatchIndex + 1) % _totalMatches;
      });
    }
  }

  void _previousMatch() {
    if (_totalMatches > 0) {
      setState(() {
        _currentMatchIndex =
            (_currentMatchIndex - 1 + _totalMatches) % _totalMatches;
      });
    }
  }

  void _replace() {
    final from = _searchController.text;
    final to = _replaceController.text;

    if (from.isNotEmpty) {
      widget.onReplace?.call(from, to);
      _nextMatch();
    }
  }

  void _replaceAll() {
    final from = _searchController.text;
    final to = _replaceController.text;

    if (from.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace All'),
          content: Text(
            'Replace all $_totalMatches occurrences of "$from" with "$to"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onReplaceAll?.call(from, to);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('REPLACE ALL'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Color(0xFF252526),
        border: Border(
          bottom: BorderSide(color: Color(0xFF3E3E42)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search row
          _buildSearchRow(),

          // Replace row (if visible)
          if (_showReplace) ...[
            const SizedBox(height: 8),
            _buildReplaceRow(),
          ],

          // Options row
          const SizedBox(height: 8),
          _buildOptionsRow(),

          // Keyboard shortcuts hint (if no regex error)
          if (_regexError == null && _searchController.text.isNotEmpty)
            _buildKeyboardHints(),
        ],
      ),
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        // Search icon
        const Icon(
          Icons.search,
          size: 18,
          color: Colors.grey,
        ),
        const SizedBox(width: 8),

        // Search input
        Expanded(
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFF3E3E42)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: _regexError != null
                      ? const Color(0xFFF48771)
                      : const Color(0xFF3E3E42),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: _regexError != null
                      ? const Color(0xFFF48771)
                      : const Color(0xFF007ACC),
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFFF48771)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFFF48771)),
              ),
              errorText: _regexError,
              errorStyle: const TextStyle(
                color: Color(0xFFF48771),
                fontSize: 11,
              ),
              filled: true,
              fillColor: const Color(0xFF3C3C3C),
            ),
            onSubmitted: (_) => _nextMatch(),
          ),
        ),

        const SizedBox(width: 8),

        // Match counter
        if (_searchController.text.isNotEmpty)
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF3C3C3C),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF3E3E42)),
              ),
              child: Text(
                _totalMatches > 0
                    ? '${_currentMatchIndex + 1} of $_totalMatches'
                    : 'No results',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

        const SizedBox(width: 4),

        // Previous match
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_up, size: 20),
          color: Colors.grey,
          onPressed: _totalMatches > 0 ? _previousMatch : null,
          tooltip: 'Previous Match (Shift+Enter)',
        ),

        // Next match
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          color: Colors.grey,
          onPressed: _totalMatches > 0 ? _nextMatch : null,
          tooltip: 'Next Match (Enter)',
        ),

        // Toggle replace
        IconButton(
          icon: Icon(
            _showReplace ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            size: 20,
          ),
          color: Colors.grey,
          onPressed: () => setState(() => _showReplace = !_showReplace),
          tooltip: 'Toggle Replace',
        ),

        // Close
        IconButton(
          icon: const Icon(Icons.close, size: 20),
          color: Colors.grey,
          onPressed: widget.onClose,
          tooltip: 'Close (Esc)',
        ),
      ],
    );
  }

  Widget _buildReplaceRow() {
    return Row(
      children: [
        // Replace icon
        const Icon(
          Icons.find_replace,
          size: 18,
          color: Colors.grey,
        ),
        const SizedBox(width: 8),

        // Replace input
        Expanded(
          child: TextField(
            controller: _replaceController,
            focusNode: _replaceFocusNode,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Replace',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFF3E3E42)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFF3E3E42)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFF007ACC)),
              ),
              filled: true,
              fillColor: const Color(0xFF3C3C3C),
            ),
            onSubmitted: (_) => _replace(),
          ),
        ),

        const SizedBox(width: 8),

        // Replace button
        OutlinedButton.icon(
          onPressed: _searchController.text.isNotEmpty ? _replace : null,
          icon: const Icon(Icons.find_replace, size: 16),
          label: const Text('Replace'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF3E3E42)),
          ),
        ),

        const SizedBox(width: 4),

        // Replace all button
        OutlinedButton.icon(
          onPressed: _searchController.text.isNotEmpty && _totalMatches > 0
              ? _replaceAll
              : null,
          icon: const Icon(Icons.published_with_changes, size: 16),
          label: const Text('Replace All'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF3E3E42)),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsRow() {
    return Row(
      children: [
        const SizedBox(width: 26),

        // Case sensitive
        _buildOptionButton(
          icon: Icons.abc,
          label: 'Aa',
          tooltip: 'Match Case',
          isActive: _caseSensitive,
          onPressed: () => setState(() => _caseSensitive = !_caseSensitive),
        ),

        const SizedBox(width: 4),

        // Whole word
        _buildOptionButton(
          icon: Icons.text_fields,
          label: 'Ab',
          tooltip: 'Match Whole Word',
          isActive: _wholeWord,
          onPressed: () => setState(() => _wholeWord = !_wholeWord),
        ),

        const SizedBox(width: 4),

        // Regex
        _buildOptionButton(
          icon: Icons.code,
          label: '.*',
          tooltip: 'Use Regular Expression',
          isActive: _useRegex,
          onPressed: () {
            setState(() {
              _useRegex = !_useRegex;
              // Clear regex error when toggling off regex mode
              if (!_useRegex) {
                _regexError = null;
              }
            });
            // Re-run search with new mode
            _performSearch();
          },
        ),

        const SizedBox(width: 16),

        // Search in all files
        Row(
          children: [
            Checkbox(
              value: _searchInAllFiles,
              onChanged: (value) =>
                  setState(() => _searchInAllFiles = value ?? false),
              fillColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return const Color(0xFF007ACC);
                }
                return Colors.grey;
              }),
            ),
            const Text(
              'Search in all files',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),

        const Spacer(),

        // Search history
        if (_searchHistory.isNotEmpty)
          PopupMenuButton<String>(
            icon: const Icon(Icons.history, size: 18, color: Colors.grey),
            tooltip: 'Search History',
            itemBuilder: (context) {
              return _searchHistory.map((query) {
                return PopupMenuItem(
                  value: query,
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        query,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
            onSelected: (query) {
              _searchController.text = query;
              _searchFocusNode.requestFocus();
            },
          ),
      ],
    );
  }

  Widget _buildKeyboardHints() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF3E3E42)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.keyboard,
            size: 14,
            color: Color(0xFF007ACC),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _buildShortcutHint('Enter', 'Next match'),
                _buildShortcutHint('Shift+Enter', 'Previous'),
                _buildShortcutHint('Esc', 'Close'),
                if (_showReplace)
                  _buildShortcutHint('Ctrl+H', 'Replace'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutHint(String keys, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF3E3E42),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: const Color(0xFF555555)),
          ),
          child: Text(
            keys,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required IconData? icon,
    required String label,
    required String tooltip,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF094771) : const Color(0xFF3C3C3C),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isActive ? const Color(0xFF007ACC) : const Color(0xFF3E3E42),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Icon(
                  icon,
                  size: 14,
                  color: isActive ? Colors.white : Colors.grey,
                ),
              if (icon != null && label.isNotEmpty) const SizedBox(width: 4),
              if (label.isNotEmpty)
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Search results model
class SearchResults {
  final String query;
  final List<SearchMatch> matches;
  final int currentIndex;
  final bool caseSensitive;
  final bool wholeWord;
  final bool useRegex;

  const SearchResults({
    required this.query,
    required this.matches,
    required this.currentIndex,
    this.caseSensitive = false,
    this.wholeWord = false,
    this.useRegex = false,
  });

  factory SearchResults.empty() {
    return const SearchResults(
      query: '',
      matches: [],
      currentIndex: 0,
    );
  }

  int get totalMatches => matches.length;
  bool get isEmpty => matches.isEmpty;
  bool get isNotEmpty => matches.isNotEmpty;
}

/// Search match model
class SearchMatch {
  final int startOffset;
  final int endOffset;
  final int line;
  final int column;
  final String matchedText;

  const SearchMatch({
    required this.startOffset,
    required this.endOffset,
    required this.line,
    required this.column,
    required this.matchedText,
  });
}
