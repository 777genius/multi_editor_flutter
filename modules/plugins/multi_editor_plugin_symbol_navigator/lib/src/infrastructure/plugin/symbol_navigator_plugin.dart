import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import 'package:multi_editor_plugin_base/multi_editor_plugin_base.dart';
import 'package:flutter_plugin_system_core/flutter_plugin_system_core.dart';
import 'package:flutter_plugin_system_wasm/flutter_plugin_system_wasm.dart';
import '../../domain/entities/code_symbol.dart';

/// Symbol Navigator plugin powered by tree-sitter WASM parser
///
/// Features:
/// - Parses source code to extract symbols (classes, functions, methods, fields)
/// - Displays hierarchical symbol tree in UI
/// - Supports multiple languages (Dart, JavaScript, TypeScript, Python, Go)
/// - Click-to-navigate to symbol definition
/// - Real-time updates on file changes
class SymbolNavigatorPlugin extends BaseEditorPlugin with StatefulPlugin {
  SymbolTree? _currentSymbolTree;
  String? _currentFileId;
  Timer? _parseDebounce;
  bool _disposed = false;

  /// WASM plugin ID for symbol parser
  static const String _wasmPluginId = 'wasm.symbol-navigator';

  /// Debounce delay for parsing
  static const _parseDelay = Duration(milliseconds: 500);

  @override
  PluginManifest get manifest => PluginManifestBuilder()
      .withId('plugin.symbol-navigator')
      .withName('Symbol Navigator')
      .withVersion('0.1.0')
      .withDescription(
        'Navigate code structure with tree-sitter powered symbol parsing',
      )
      .withAuthor('Editor Team')
      .withCapability('parse.symbols', 'Parse and display code symbols')
      .withCapability('navigate.symbols', 'Jump to symbol definitions')
      .addActivationEvent('onFileOpen')
      .addActivationEvent('onFileContentChange')
      .build();

  @override
  Future<void> onInitialize(PluginContext context) async {
    // Initialize state
    setState('symbolTree', null);
    setState('loading', false);
    setState('error', null);

    // Register UI with PluginUIService
    final uiService = context.getService<PluginUIService>();
    final descriptor = getUIDescriptor();
    if (descriptor != null && uiService != null) {
      uiService.registerUI(descriptor);
    }

    if (kDebugMode) {
      print('[SymbolNavigator] Initialized');
    }
  }

  @override
  Future<void> onDispose() async {
    _disposed = true;
    _parseDebounce?.cancel();
    _parseDebounce = null;
    _currentSymbolTree = null;
    _currentFileId = null;
    disposeStateful();

    if (kDebugMode) {
      print('[SymbolNavigator] Disposed');
    }
  }

  @override
  void onFileOpen(FileDocument file) {
    safeExecute('Parse symbols on file open', () {
      _scheduleParseFile(file);
    });
  }

  @override
  void onFileContentChange(String fileId, String content) {
    safeExecute('Parse symbols on content change', () {
      // Only parse if this is the currently open file
      if (_currentFileId == fileId) {
        context.fileRepository.getFile(fileId).fold(
          (failure) {
            if (kDebugMode) {
              print('[SymbolNavigator] Failed to get file: ${failure.displayMessage}');
            }
          },
          (file) => _scheduleParseFile(file),
        );
      }
    });
  }

  @override
  void onFileClose(String fileId) {
    safeExecute('Clear symbols on file close', () {
      if (_currentFileId == fileId) {
        _currentSymbolTree = null;
        _currentFileId = null;
        setState('symbolTree', null);
        _updateUI();
      }
    });
  }

  /// Schedule parsing with debouncing
  void _scheduleParseFile(FileDocument file) {
    _parseDebounce?.cancel();
    _parseDebounce = Timer(_parseDelay, () {
      if (_disposed) return;
      _parseFile(file);
    });
  }

  /// Parse file to extract symbols
  Future<void> _parseFile(FileDocument file) async {
    if (_disposed) return;

    _currentFileId = file.id;
    setState('loading', true);
    setState('error', null);

    try {
      final language = _detectLanguage(file.name);

      if (kDebugMode) {
        print('[SymbolNavigator] Parsing ${file.name} (language: $language)');
      }

      // TODO: Call WASM plugin to parse symbols
      // For now, create empty symbol tree
      final symbolTree = SymbolTree(
        filePath: file.name,
        language: language,
        timestamp: DateTime.now(),
        symbols: _parseMockSymbols(file.content),
      );

      if (_disposed) return;

      _currentSymbolTree = symbolTree;
      setState('symbolTree', symbolTree);
      setState('loading', false);

      if (kDebugMode) {
        print('[SymbolNavigator] Parsed ${symbolTree.totalCount} symbols');
      }

      _updateUI();
    } catch (e, st) {
      if (kDebugMode) {
        print('[SymbolNavigator] Parse error: $e');
        debugPrintStack(stackTrace: st);
      }

      if (!_disposed) {
        setState('error', e.toString());
        setState('loading', false);
        _updateUI();
      }
    }
  }

  /// Detect language from file extension
  String _detectLanguage(String filename) {
    // Handle edge cases
    if (filename.isEmpty) return 'unknown';

    // Handle dotfiles without extension (e.g., .bashrc, .gitignore)
    if (filename.startsWith('.') && !filename.substring(1).contains('.')) {
      return 'unknown';
    }

    // Extract extension, handling files without extensions
    final parts = filename.split('.');
    if (parts.length < 2) {
      // No extension (e.g., "Makefile", "README")
      return 'unknown';
    }

    final ext = parts.last.toLowerCase();

    // Return unknown for empty extensions
    if (ext.isEmpty) return 'unknown';

    switch (ext) {
      case 'dart':
        return 'dart';
      case 'js':
      case 'jsx':
        return 'javascript';
      case 'ts':
      case 'tsx':
        return 'typescript';
      case 'py':
        return 'python';
      case 'go':
        return 'go';
      case 'rs':
        return 'rust';
      default:
        return 'unknown';
    }
  }

  /// Temporary mock parser (will be replaced with WASM tree-sitter)
  List<CodeSymbol> _parseMockSymbols(String content) {
    // Simple regex-based mock parser for Dart
    final symbols = <CodeSymbol>[];
    final lines = content.split('\n');

    // Parse classes
    final classRegex = RegExp(r'class\s+(\w+)');
    final matches = classRegex.allMatches(content);

    for (final match in matches) {
      final name = match.group(1)!;

      // Calculate line number
      final textBeforeMatch = content.substring(0, match.start);
      final lineNumber = textBeforeMatch.split('\n').length - 1;

      // Calculate column position within the line
      final lineStart = textBeforeMatch.lastIndexOf('\n') + 1;
      final startColumn = match.start - lineStart;
      final endColumn = match.end - lineStart;

      symbols.add(CodeSymbol(
        name: name,
        kind: const SymbolKind.classDeclaration(),
        location: SymbolLocation(
          startLine: lineNumber,
          startColumn: startColumn,
          endLine: lineNumber,
          endColumn: endColumn,
          startOffset: match.start,
          endOffset: match.end,
        ),
      ));
    }

    return symbols;
  }

  /// Update UI descriptor
  void _updateUI() {
    if (!isInitialized || _disposed) return;

    final uiService = context.getService<PluginUIService>();
    final descriptor = getUIDescriptor();
    if (descriptor != null && uiService != null) {
      uiService.registerUI(descriptor);
    }
  }

  @override
  PluginUIDescriptor? getUIDescriptor() {
    final symbolTree = _currentSymbolTree;
    final loading = getState<bool>('loading') ?? false;
    final error = getState<String?>('error');

    if (loading) {
      return PluginUIDescriptor(
        pluginId: manifest.id,
        iconCode: 0xe8b2, // Icons.account_tree
        iconFamily: 'MaterialIcons',
        tooltip: 'Symbol Navigator (Loading...)',
        priority: 20,
        uiData: {
          'type': 'list',
          'items': [
            {
              'id': 'loading',
              'title': 'Parsing symbols...',
              'iconCode': 0xe627, // Icons.hourglass_empty
            }
          ],
        },
      );
    }

    if (error != null) {
      return PluginUIDescriptor(
        pluginId: manifest.id,
        iconCode: 0xe8b2, // Icons.account_tree
        iconFamily: 'MaterialIcons',
        tooltip: 'Symbol Navigator (Error)',
        priority: 20,
        uiData: {
          'type': 'list',
          'items': [
            {
              'id': 'error',
              'title': 'Parse error',
              'subtitle': error,
              'iconCode': 0xe000, // Icons.error
            }
          ],
        },
      );
    }

    if (symbolTree == null || symbolTree.symbols.isEmpty) {
      return PluginUIDescriptor(
        pluginId: manifest.id,
        iconCode: 0xe8b2, // Icons.account_tree
        iconFamily: 'MaterialIcons',
        tooltip: 'Symbol Navigator',
        priority: 20,
        uiData: {
          'type': 'list',
          'items': [
            {
              'id': 'empty',
              'title': 'No symbols',
              'subtitle': 'Open a file to see symbols',
              'iconCode': 0xe88f, // Icons.info_outline
            }
          ],
        },
      );
    }

    // Build symbol tree UI
    final items = <Map<String, dynamic>>[];
    for (final symbol in symbolTree.symbols) {
      items.add(_buildSymbolItem(symbol, level: 0));
      items.addAll(_buildChildSymbolItems(symbol, level: 1));
    }

    return PluginUIDescriptor(
      pluginId: manifest.id,
      iconCode: 0xe8b2, // Icons.account_tree
      iconFamily: 'MaterialIcons',
      tooltip: 'Symbol Navigator (${symbolTree.totalCount} symbols)',
      priority: 20,
      uiData: {
        'type': 'tree',
        'items': items,
        'stats': symbolTree.statistics,
      },
    );
  }

  Map<String, dynamic> _buildSymbolItem(CodeSymbol symbol, {required int level}) {
    return {
      'id': symbol.qualifiedName,
      'title': symbol.name,
      'subtitle': symbol.kind.displayName,
      'iconCode': symbol.kind.iconCode,
      'line': symbol.location.startLine,
      'level': level,
      'hasChildren': symbol.children.isNotEmpty,
      'onTap': 'jumpToSymbol',
    };
  }

  List<Map<String, dynamic>> _buildChildSymbolItems(
    CodeSymbol symbol, {
    required int level,
  }) {
    final items = <Map<String, dynamic>>[];
    for (final child in symbol.children) {
      items.add(_buildSymbolItem(child, level: level));
      items.addAll(_buildChildSymbolItems(child, level: level + 1));
    }
    return items;
  }

  /// Handle symbol navigation action
  void onSymbolClick(String symbolName, int line) {
    safeExecute('Navigate to symbol', () {
      if (kDebugMode) {
        print('[SymbolNavigator] Navigate to $symbolName at line $line');
      }
      // TODO: Trigger navigation in editor
      // This would be handled by the UI layer
    });
  }

  /// Get current symbol tree
  SymbolTree? get currentSymbolTree => _currentSymbolTree;

  /// Get symbol at line
  CodeSymbol? getSymbolAtLine(int line) {
    return _currentSymbolTree?.findSymbolAtLine(line);
  }
}
