import 'dart:async';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import 'package:multi_editor_plugin_base/multi_editor_plugin_base.dart';
import '../../domain/entities/bracket_match.dart';

/// Bracket Pair Colorizer Plugin
///
/// Rainbow bracket colorizer with WASM backend for performance.
/// Features:
/// - Rainbow colors for different nesting levels
/// - Supports (), {}, [], <>
/// - Error detection (unmatched, mismatched)
/// - String and comment awareness
/// - Language-specific handling
class BracketColorizerPlugin extends BaseEditorPlugin
    with StatefulPlugin, ConfigurablePlugin {
  final Map<String, BracketCollection> _bracketsByFile = {};
  Timer? _analysisDebounce;
  String? _currentFileId;
  ColorScheme _colorScheme = ColorScheme.rainbow();

  @override
  PluginManifest get manifest => PluginManifestBuilder()
      .withId('plugin.bracket-colorizer')
      .withName('Bracket Pair Colorizer')
      .withVersion('0.1.0')
      .withDescription(
          'Rainbow bracket colorizer with nesting depth analysis and error detection')
      .withAuthor('Multi Editor Team')
      .addActivationEvent('onFileOpen')
      .addActivationEvent('onFileContentChange')
      .build();

  @override
  Future<void> onInitialize(PluginContext context) async {
    // Load color scheme from config
    await loadConfig();
    final colorsData = getConfigValue<Map<String, dynamic>>('colorScheme');
    if (colorsData != null) {
      try {
        _colorScheme = ColorScheme.fromJson(colorsData);
      } catch (e) {
        print('[BracketColorizer] Failed to load color scheme: $e');
      }
    }

    setState('brackets', _bracketsByFile);
    setState('colorScheme', _colorScheme);

    // Register UI
    final uiService = context.getService<PluginUIService>();
    final descriptor = getUIDescriptor();
    if (descriptor != null && uiService != null) {
      uiService.registerUI(descriptor);
    }
  }

  @override
  Future<void> onDispose() async {
    _analysisDebounce?.cancel();

    // Save color scheme
    await updateConfig('colorScheme', _colorScheme.toJson());
    await saveConfig();

    disposeStateful();
    disposeConfigurable();
  }

  @override
  void onFileOpen(FileDocument file) {
    safeExecute('Analyze brackets on file open', () {
      _currentFileId = file.id;
      _scheduleAnalysis(file.id, file.content);
    });
  }

  @override
  void onFileContentChange(String fileId, String content) {
    safeExecute('Analyze brackets on content change', () {
      _scheduleAnalysis(fileId, content);
    });
  }

  @override
  void onFileClose(String fileId) {
    safeExecute('Clear brackets on file close', () {
      if (_currentFileId == fileId) {
        _currentFileId = null;
      }
      _bracketsByFile.remove(fileId);
      _updateUI();
    });
  }

  void _scheduleAnalysis(String fileId, String content) {
    _analysisDebounce?.cancel();
    _analysisDebounce = Timer(const Duration(milliseconds: 200), () {
      _analyzeBrackets(fileId, content);
    });
  }

  Future<void> _analyzeBrackets(String fileId, String content) async {
    // For now, use simple Dart-based analysis
    // TODO: Integrate WASM backend when WASM runtime is ready
    final collection = _analyzeBracketsWithDart(content);

    _bracketsByFile[fileId] = collection;
    _updateUI();
  }

  /// Simple Dart-based bracket analysis
  /// This is a fallback; production version should use WASM backend
  BracketCollection _analyzeBracketsWithDart(String content) {
    final stopwatch = Stopwatch()..start();

    final pairs = <BracketPair>[];
    final unmatched = <UnmatchedBracket>[];
    final stack = <Bracket>[];
    var maxDepth = 0;

    // Track strings and comments
    var inString = false;
    var inSingleQuoteString = false;
    var inComment = false;
    var inMultilineComment = false;
    var escapeNext = false;

    var line = 0;
    var column = 0;
    var offset = 0;

    // FIXED BUG #3: split('') breaks on Unicode! Use runes instead
    final chars = content.runes.map((r) => String.fromCharCode(r)).toList();
    for (var i = 0; i < chars.length; i++) {
      final ch = chars[i];

      // Handle escape sequences
      // FIXED BUG #8: When escaping a newline, still update line counter
      if (escapeNext) {
        escapeNext = false;
        if (ch == '\n') {
          line++;
          column = 0;
        } else {
          column++;
        }
        offset++;
        continue;
      }

      if (ch == '\\' && (inString || inSingleQuoteString)) {
        escapeNext = true;
        offset++;
        column++;
        continue;
      }

      // Handle newlines
      if (ch == '\n') {
        line++;
        column = 0;
        offset++;
        inComment = false;
        continue;
      }

      // Handle strings
      if (ch == '"' && !inSingleQuoteString && !inComment && !inMultilineComment) {
        inString = !inString;
      } else if (ch == "'" && !inString && !inComment && !inMultilineComment) {
        inSingleQuoteString = !inSingleQuoteString;
      }

      // Handle comments
      if (!inString && !inSingleQuoteString) {
        if (i + 1 < chars.length && ch == '/' && chars[i + 1] == '/') {
          inComment = true;
        }
        if (i + 1 < chars.length && ch == '/' && chars[i + 1] == '*') {
          inMultilineComment = true;
        }
        // FIXED BUG #4: Don't double increment! Loop adds 1 automatically
        if (i + 1 < chars.length && ch == '*' && chars[i + 1] == '/') {
          inMultilineComment = false;
          offset += 2;
          column += 2;
          i++; // This is OK - we manually increment to skip '/'
          continue;
        }
      }

      // Process brackets
      if (!inString && !inSingleQuoteString && !inComment && !inMultilineComment) {
        final bracketInfo = _detectBracket(ch);
        if (bracketInfo != null) {
          final (type, side) = bracketInfo;
          final position = BracketPosition(line: line, column: column, offset: offset);
          final depth = stack.length;
          final colorLevel = depth % _colorScheme.colors.length;

          final bracket = Bracket(
            bracketType: type,
            side: side,
            position: position,
            depth: depth,
            colorLevel: colorLevel,
            character: ch,
          );

          if (side == BracketSide.opening) {
            stack.add(bracket);
            if (depth > maxDepth) maxDepth = depth;
          } else {
            if (stack.isNotEmpty) {
              final opening = stack.removeLast();
              if (opening.bracketType == type) {
                pairs.add(BracketPair(
                  opening: opening,
                  closing: bracket,
                  depth: opening.depth,
                  isMatched: true,
                ));
              } else {
                unmatched.add(UnmatchedBracket(
                  bracket: bracket,
                  reason: 'TypeMismatch',
                ));
                unmatched.add(UnmatchedBracket(
                  bracket: opening,
                  reason: 'TypeMismatch',
                ));
              }
            } else {
              unmatched.add(UnmatchedBracket(
                bracket: bracket,
                reason: 'MissingOpening',
              ));
            }
          }
        }
      }

      offset++;
      column++;
    }

    // Remaining opening brackets are unmatched
    for (final opening in stack) {
      unmatched.add(UnmatchedBracket(
        bracket: opening,
        reason: 'MissingClosing',
      ));
    }

    final duration = stopwatch.elapsedMilliseconds;

    // Calculate statistics
    final stats = BracketStatistics(
      roundPairs: pairs.where((p) => p.bracketType == BracketType.round).length,
      curlyPairs: pairs.where((p) => p.bracketType == BracketType.curly).length,
      squarePairs: pairs.where((p) => p.bracketType == BracketType.square).length,
      anglePairs: pairs.where((p) => p.bracketType == BracketType.angle).length,
      unmatchedCount: unmatched.length,
      mismatchedCount: unmatched.where((u) => u.reason == 'TypeMismatch').length,
    );

    return BracketCollection(
      pairs: pairs,
      unmatched: unmatched,
      maxDepth: maxDepth,
      totalBrackets: pairs.length * 2 + unmatched.length,
      analysisDurationMs: duration,
      statistics: stats,
    );
  }

  (BracketType, BracketSide)? _detectBracket(String ch) {
    return switch (ch) {
      '(' => (BracketType.round, BracketSide.opening),
      ')' => (BracketType.round, BracketSide.closing),
      '{' => (BracketType.curly, BracketSide.opening),
      '}' => (BracketType.curly, BracketSide.closing),
      '[' => (BracketType.square, BracketSide.opening),
      ']' => (BracketType.square, BracketSide.closing),
      '<' => (BracketType.angle, BracketSide.opening),
      '>' => (BracketType.angle, BracketSide.closing),
      _ => null,
    };
  }

  void _updateUI() {
    setState('brackets', _bracketsByFile);

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
    if (_currentFileId == null) return null;

    final collection = _bracketsByFile[_currentFileId];
    if (collection == null) return null;

    final items = <Map<String, dynamic>>[];

    // Summary
    items.add({
      'id': 'summary',
      'title': 'Brackets: ${collection.statistics.totalPairs} pairs',
      'subtitle':
          'Max depth: ${collection.maxDepth} • ${collection.hasErrors ? "⚠️ ${collection.unmatched.length} errors" : "✓ All matched"}',
      'iconCode': 0xe86a, // Icons.code
    });

    // Statistics
    if (collection.statistics.roundPairs > 0) {
      items.add({
        'id': 'round',
        'title': '() Round: ${collection.statistics.roundPairs}',
        'iconCode': 0xe86a,
      });
    }
    if (collection.statistics.curlyPairs > 0) {
      items.add({
        'id': 'curly',
        'title': '{} Curly: ${collection.statistics.curlyPairs}',
        'iconCode': 0xe86a,
      });
    }
    if (collection.statistics.squarePairs > 0) {
      items.add({
        'id': 'square',
        'title': '[] Square: ${collection.statistics.squarePairs}',
        'iconCode': 0xe86a,
      });
    }
    if (collection.statistics.anglePairs > 0) {
      items.add({
        'id': 'angle',
        'title': '<> Angle: ${collection.statistics.anglePairs}',
        'iconCode': 0xe86a,
      });
    }

    // Errors
    if (collection.hasErrors) {
      items.add({
        'id': 'errors',
        'title': '⚠️ Errors: ${collection.unmatched.length}',
        'subtitle': 'Mismatched: ${collection.statistics.mismatchedCount}',
        'iconCode': 0xe000, // Icons.error
        'onTap': 'showErrors',
      });
    }

    return PluginUIDescriptor(
      pluginId: manifest.id,
      iconCode: 0xe86a, // Icons.code
      iconFamily: 'MaterialIcons',
      tooltip: 'Bracket Colorizer',
      priority: 30,
      uiData: {
        'type': 'list',
        'items': items,
      },
    );
  }

  /// Update color scheme
  Future<void> setColorScheme(ColorScheme scheme) async {
    _colorScheme = scheme;
    setState('colorScheme', _colorScheme);

    // Re-analyze current file with new colors
    if (_currentFileId != null) {
      final file = await context.fileRepository.getFile(_currentFileId!);
      if (file != null) {
        await _analyzeBrackets(file.id, file.content);
      }
    }

    _updateUI();
  }

  /// Get current bracket collection
  BracketCollection? get currentBrackets =>
      _currentFileId != null ? _bracketsByFile[_currentFileId] : null;

  /// Get all brackets
  Map<String, BracketCollection> get allBrackets => Map.from(_bracketsByFile);

  /// Get current color scheme
  ColorScheme get colorScheme => _colorScheme;
}
