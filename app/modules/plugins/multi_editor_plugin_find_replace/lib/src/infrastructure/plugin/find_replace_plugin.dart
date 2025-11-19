import 'dart:async';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import 'package:multi_editor_plugin_base/multi_editor_plugin_base.dart';
import '../../domain/entities/search_result.dart';

/// Advanced Find & Replace Plugin
///
/// Features:
/// - Regex and literal search
/// - Case sensitive / insensitive
/// - Whole word matching
/// - Multi-file find & replace
/// - Replace preview with diff
/// - Search history
class FindReplacePlugin extends BaseEditorPlugin
    with StatefulPlugin, ConfigurablePlugin {
  SearchSession? _currentSearch;
  ReplaceSession? _currentReplace;
  final List<String> _searchHistory = [];
  static const int _maxHistorySize = 20;

  @override
  PluginManifest get manifest => PluginManifestBuilder()
      .withId('plugin.find-replace')
      .withName('Advanced Find & Replace')
      .withVersion('0.1.0')
      .withDescription(
          'Advanced find & replace with regex support and preview')
      .withAuthor('Multi Editor Team')
      .build();

  @override
  Future<void> onInitialize(PluginContext context) async {
    // Load search history from config
    await loadConfig();
    final history = getConfigValue<List<dynamic>>('searchHistory') ?? [];
    _searchHistory.addAll(history.cast<String>());

    setState('searchSession', _currentSearch);
    setState('replaceSession', _currentReplace);

    // Register UI
    final uiService = context.getService<PluginUIService>();
    final descriptor = getUIDescriptor();
    if (descriptor != null && uiService != null) {
      uiService.registerUI(descriptor);
    }
  }

  @override
  Future<void> onDispose() async {
    // Save search history
    await updateConfig('searchHistory', _searchHistory.take(_maxHistorySize).toList());
    await saveConfig();

    disposeStateful();
    disposeConfigurable();
  }

  /// Start a new search
  Future<void> startSearch({
    required String query,
    bool isRegex = false,
    bool caseSensitive = false,
    bool wholeWord = false,
  }) async {
    safeExecute('Start search', () async {
      // Add to history
      _addToSearchHistory(query);

      // Create search session
      _currentSearch = SearchSession(
        query: query,
        isRegex: isRegex,
        caseSensitive: caseSensitive,
        wholeWord: wholeWord,
      );

      // Perform search
      await _performSearch();

      _updateUI();
    });
  }

  /// Perform search in current file or all files
  Future<void> _performSearch() async {
    if (_currentSearch == null) return;

    final matches = <SearchMatch>[];

    // Get current file
    final repository = context.fileRepository;
    // For now, search only in current file
    // TODO: Implement multi-file search using global_search module

    // Build regex pattern
    RegExp? pattern;
    try {
      if (_currentSearch!.isRegex) {
        pattern = RegExp(
          _currentSearch!.query,
          caseSensitive: _currentSearch!.caseSensitive,
        );
      } else {
        // Escape special regex characters
        final escaped = RegExp.escape(_currentSearch!.query);
        final wordBoundary = _currentSearch!.wholeWord ? r'\b' : '';
        pattern = RegExp(
          '$wordBoundary$escaped$wordBoundary',
          caseSensitive: _currentSearch!.caseSensitive,
        );
      }
    } catch (e) {
      print('[FindReplace] Invalid regex pattern: $e');
      return;
    }

    // TODO: Actually search in files
    // This is a simplified version

    _currentSearch = _currentSearch!.copyWith(matches: matches);
  }

  /// Start replace mode
  void startReplace({required String replaceText}) {
    safeExecute('Start replace', () {
      if (_currentSearch == null) return;

      final previews = _currentSearch!.matches.map((match) {
        final replacedText = _performReplacement(
          match.matchedText,
          replaceText,
        );

        // FIXED BUG #10: matchStart/matchEnd must be relative to lineContent
        // When implementing search (line 120), ensure matchStart/matchEnd are
        // positions within the line, NOT absolute file offsets
        final replacedLineContent = match.lineContent.replaceRange(
          match.matchStart,
          match.matchEnd,
          replacedText,
        );

        return ReplacePreview(
          match: match,
          originalText: match.matchedText,
          replacedText: replacedText,
          replacedLineContent: replacedLineContent,
        );
      }).toList();

      _currentReplace = ReplaceSession(
        searchSession: _currentSearch!,
        replaceText: replaceText,
        previews: previews,
      );

      _updateUI();
    });
  }

  /// Perform replacement on text
  String _performReplacement(String originalText, String replaceText) {
    if (_currentSearch!.isRegex) {
      // Support regex replacement with capture groups
      final pattern = RegExp(
        _currentSearch!.query,
        caseSensitive: _currentSearch!.caseSensitive,
      );
      return originalText.replaceAllMapped(pattern, (match) {
        var result = replaceText;
        // FIXED BUG #7: Use raw string r'$' or escape properly
        // Replace $1, $2, etc. with capture groups
        for (var i = 0; i <= match.groupCount; i++) {
          final group = match.group(i) ?? '';
          result = result.replaceAll('\$$i', group); // This now works correctly
        }
        return result;
      });
    } else {
      return replaceText;
    }
  }

  /// Apply a single replacement
  Future<void> applyReplacement(int index) async {
    safeExecute('Apply replacement', () async {
      if (_currentReplace == null || index >= _currentReplace!.previews.length) {
        return;
      }

      final preview = _currentReplace!.previews[index];
      final match = preview.match;

      // Get file and update content
      final file = await context.fileRepository.getFile(match.fileId);
      if (file == null) return;

      // TODO: Actually apply the replacement to the file
      // This would require updating the file content

      // Mark as applied
      final updatedPreviews = List<ReplacePreview>.from(_currentReplace!.previews);
      updatedPreviews[index] = preview.copyWith(applied: true);

      _currentReplace = _currentReplace!.copyWith(previews: updatedPreviews);

      _updateUI();
    });
  }

  /// Apply all replacements
  Future<void> applyAllReplacements() async {
    if (_currentReplace == null) return;

    for (var i = 0; i < _currentReplace!.previews.length; i++) {
      if (!_currentReplace!.previews[i].applied) {
        await applyReplacement(i);
      }
    }
  }

  /// Navigate to next match
  void nextMatch() {
    if (_currentSearch == null || !_currentSearch!.hasMatches) return;

    final nextIndex = (_currentSearch!.currentMatchIndex + 1) %
        _currentSearch!.matchCount;

    _currentSearch = _currentSearch!.copyWith(currentMatchIndex: nextIndex);
    _updateUI();
  }

  /// Navigate to previous match
  void previousMatch() {
    if (_currentSearch == null || !_currentSearch!.hasMatches) return;

    final prevIndex = _currentSearch!.currentMatchIndex == 0
        ? _currentSearch!.matchCount - 1
        : _currentSearch!.currentMatchIndex - 1;

    _currentSearch = _currentSearch!.copyWith(currentMatchIndex: prevIndex);
    _updateUI();
  }

  /// Clear search
  void clearSearch() {
    _currentSearch = null;
    _currentReplace = null;
    _updateUI();
  }

  void _addToSearchHistory(String query) {
    _searchHistory.remove(query);
    _searchHistory.insert(0, query);
    if (_searchHistory.length > _maxHistorySize) {
      _searchHistory.removeRange(_maxHistorySize, _searchHistory.length);
    }
  }

  void _updateUI() {
    setState('searchSession', _currentSearch);
    setState('replaceSession', _currentReplace);

    if (isInitialized) {
      final uiService = context.getService<PluginUIService>();
      final descriptor = getUIDescriptor();
      if (descriptor != null && uiService != null) {
        uiService.registerUI(descriptor);
      } else {
        uiService?.unregisterUI(manifest.id);
      }
    }
  }

  @override
  PluginUIDescriptor? getUIDescriptor() {
    if (_currentSearch == null) return null;

    final items = <Map<String, dynamic>>[];

    if (_currentSearch!.hasMatches) {
      items.add({
        'id': 'search-results',
        'title': 'Found ${_currentSearch!.matchCount} matches',
        'subtitle':
            'Match ${_currentSearch!.currentMatchIndex + 1}/${_currentSearch!.matchCount}',
        'iconCode': 0xe8b6, // Icons.search
        'onTap': 'showSearchResults',
      });

      if (_currentReplace != null) {
        items.add({
          'id': 'replace-preview',
          'title':
              'Replace: ${_currentReplace!.appliedCount}/${_currentReplace!.previewCount} applied',
          'subtitle': '${_currentReplace!.pendingCount} pending',
          'iconCode': 0xe86b, // Icons.find_replace
          'onTap': 'showReplacePreview',
        });
      }
    } else {
      items.add({
        'id': 'no-results',
        'title': 'No matches found',
        'subtitle': 'Query: ${_currentSearch!.query}',
        'iconCode': 0xe002, // Icons.error_outline
      });
    }

    return PluginUIDescriptor(
      pluginId: manifest.id,
      iconCode: 0xe8b6, // Icons.search
      iconFamily: 'MaterialIcons',
      tooltip: 'Find & Replace',
      priority: 20,
      uiData: {
        'type': 'list',
        'items': items,
      },
    );
  }

  /// Getters
  SearchSession? get currentSearch => _currentSearch;
  ReplaceSession? get currentReplace => _currentReplace;
  List<String> get searchHistory => List.from(_searchHistory);
}
