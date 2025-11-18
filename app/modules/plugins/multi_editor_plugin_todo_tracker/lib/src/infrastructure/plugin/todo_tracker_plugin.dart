import 'dart:async';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import 'package:multi_editor_plugin_base/multi_editor_plugin_base.dart';
import '../../domain/entities/todo_item.dart';

/// TODO/FIXME Tracker Plugin
///
/// Hybrid approach:
/// - Uses simple Dart regex for small files (< 5000 lines)
/// - Uses WASM backend for large files (>= 5000 lines) for better performance
class TodoTrackerPlugin extends BaseEditorPlugin with StatefulPlugin {
  static const int _wasmThreshold = 5000; // Lines threshold for WASM usage

  final Map<String, TodoCollection> _todosByFile = {};
  Timer? _scanDebounce;
  String? _currentFileId;

  @override
  PluginManifest get manifest => PluginManifestBuilder()
      .withId('plugin.todo-tracker')
      .withName('TODO Tracker')
      .withVersion('0.1.0')
      .withDescription(
          'Track TODO/FIXME/HACK comments with fast WASM backend for large files')
      .withAuthor('Multi Editor Team')
      .addActivationEvent('onFileOpen')
      .addActivationEvent('onFileContentChange')
      .build();

  @override
  Future<void> onInitialize(PluginContext context) async {
    setState('todos', _todosByFile);

    // Register UI
    final uiService = context.getService<PluginUIService>();
    final descriptor = getUIDescriptor();
    if (descriptor != null && uiService != null) {
      uiService.registerUI(descriptor);
    }
  }

  @override
  Future<void> onDispose() async {
    _scanDebounce?.cancel();
    disposeStateful();
  }

  @override
  void onFileOpen(FileDocument file) {
    safeExecute('Scan TODOs on file open', () {
      _currentFileId = file.id;
      _scheduleScan(file.id, file.content);
    });
  }

  @override
  void onFileContentChange(String fileId, String content) {
    safeExecute('Scan TODOs on content change', () {
      _scheduleScan(fileId, content);
    });
  }

  @override
  void onFileClose(String fileId) {
    safeExecute('Clear TODOs on file close', () {
      if (_currentFileId == fileId) {
        _currentFileId = null;
      }
      _todosByFile.remove(fileId);
      _updateUI();
    });
  }

  void _scheduleScan(String fileId, String content) {
    _scanDebounce?.cancel();
    _scanDebounce = Timer(const Duration(milliseconds: 300), () {
      _scanTodos(fileId, content);
    });
  }

  Future<void> _scanTodos(String fileId, String content) async {
    final lineCount = '\n'.allMatches(content).length + 1;

    TodoCollection collection;

    if (lineCount >= _wasmThreshold) {
      // Use WASM for large files
      collection = await _scanWithWasm(content);
    } else {
      // Use Dart for small files
      collection = _scanWithDart(content);
    }

    _todosByFile[fileId] = collection;
    _updateUI();
  }

  /// Scan using simple Dart regex (for small files)
  TodoCollection _scanWithDart(String content) {
    final stopwatch = Stopwatch()..start();
    final items = <TodoItem>[];

    // FIXED BUG #5: Changed .+ to [^\n]+ to prevent catastrophic backtracking
    final patterns = {
      TodoType.todo: RegExp(r'(?://|#|/\*+)\s*TODO(?:\([^)]+\))?:?\s*([^\n]+)',
          multiLine: true, caseSensitive: false),
      TodoType.fixme: RegExp(r'(?://|#|/\*+)\s*FIXME(?:\([^)]+\))?:?\s*([^\n]+)',
          multiLine: true, caseSensitive: false),
      TodoType.hack: RegExp(r'(?://|#|/\*+)\s*HACK(?:\([^)]+\))?:?\s*([^\n]+)',
          multiLine: true, caseSensitive: false),
      TodoType.note: RegExp(r'(?://|#|/\*+)\s*NOTE(?:\([^)]+\))?:?\s*([^\n]+)',
          multiLine: true, caseSensitive: false),
      TodoType.xxx: RegExp(r'(?://|#|/\*+)\s*XXX(?:\([^)]+\))?:?\s*([^\n]+)',
          multiLine: true),
      TodoType.bug: RegExp(r'(?://|#|/\*+)\s*BUG(?:\([^)]+\))?:?\s*([^\n]+)',
          multiLine: true, caseSensitive: false),
      TodoType.optimize:
          RegExp(r'(?://|#|/\*+)\s*OPTIMIZE(?:\([^)]+\))?:?\s*([^\n]+)',
              multiLine: true, caseSensitive: false),
      TodoType.review: RegExp(r'(?://|#|/\*+)\s*REVIEW(?:\([^)]+\))?:?\s*([^\n]+)',
          multiLine: true, caseSensitive: false),
    };

    final lines = content.split('\n');
    for (var lineIdx = 0; lineIdx < lines.length; lineIdx++) {
      final line = lines[lineIdx];

      for (final entry in patterns.entries) {
        final match = entry.value.firstMatch(line);
        if (match != null) {
          final text = match.group(1)?.trim() ?? '';
          if (text.isEmpty) continue;

          final priority = _detectPriority(entry.key, text);
          final author = _extractAuthor(line);
          final tags = _extractTags(text);

          // FIXED BUG #6: Find actual TODO marker position, not match start
          final todoMarkerPos = line.indexOf(entry.key.name.toUpperCase(), match.start);
          final column = todoMarkerPos != -1 ? todoMarkerPos : match.start;

          items.add(TodoItem(
            todoType: entry.key,
            priority: priority,
            text: text,
            line: lineIdx,
            column: column,
            position: Position(line: lineIdx, column: column),
            author: author,
            tags: tags,
          ));
          break;
        }
      }
    }

    return TodoCollection(
      items: items,
      countsByType: _calculateTypeCounts(items),
      countsByPriority: _calculatePriorityCounts(items),
      scanDurationMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Scan using WASM backend (for large files)
  Future<TodoCollection> _scanWithWasm(String content) async {
    // TODO: Implement WASM integration when WASM runtime is ready
    // For now, fall back to Dart
    return _scanWithDart(content);
  }

  TodoPriority _detectPriority(TodoType type, String text) {
    if (text.contains('!!!')) return TodoPriority.high;
    if (text.contains('!!')) return TodoPriority.high;
    if (text.contains('!')) return TodoPriority.medium;

    switch (type) {
      case TodoType.fixme:
      case TodoType.bug:
        return TodoPriority.high;
      case TodoType.todo:
      case TodoType.hack:
      case TodoType.optimize:
      case TodoType.review:
        return TodoPriority.medium;
      case TodoType.note:
      case TodoType.xxx:
        return TodoPriority.low;
    }
  }

  String? _extractAuthor(String line) {
    final authorRegex = RegExp(r'\((@?[\w\-]+)\)');
    final match = authorRegex.firstMatch(line);
    return match?.group(1);
  }

  List<String> _extractTags(String text) {
    final tagRegex = RegExp(r'#([\w\-]+)');
    return tagRegex
        .allMatches(text)
        .map((m) => m.group(1)!)
        .toList();
  }

  TodoTypeCounts _calculateTypeCounts(List<TodoItem> items) {
    var counts = const TodoTypeCounts();
    for (final item in items) {
      counts = switch (item.todoType) {
        TodoType.todo => counts.copyWith(todo: counts.todo + 1),
        TodoType.fixme => counts.copyWith(fixme: counts.fixme + 1),
        TodoType.hack => counts.copyWith(hack: counts.hack + 1),
        TodoType.note => counts.copyWith(note: counts.note + 1),
        TodoType.xxx => counts.copyWith(xxx: counts.xxx + 1),
        TodoType.bug => counts.copyWith(bug: counts.bug + 1),
        TodoType.optimize => counts.copyWith(optimize: counts.optimize + 1),
        TodoType.review => counts.copyWith(review: counts.review + 1),
      };
    }
    return counts;
  }

  PriorityCounts _calculatePriorityCounts(List<TodoItem> items) {
    var counts = const PriorityCounts();
    for (final item in items) {
      counts = switch (item.priority) {
        TodoPriority.high => counts.copyWith(high: counts.high + 1),
        TodoPriority.medium => counts.copyWith(medium: counts.medium + 1),
        TodoPriority.low => counts.copyWith(low: counts.low + 1),
      };
    }
    return counts;
  }

  void _updateUI() {
    setState('todos', _todosByFile);

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

    final collection = _todosByFile[_currentFileId];
    if (collection == null || collection.items.isEmpty) return null;

    return PluginUIDescriptor(
      pluginId: manifest.id,
      iconCode: 0xe873, // Icons.checklist
      iconFamily: 'MaterialIcons',
      tooltip: 'TODOs (${collection.items.length})',
      priority: 15,
      uiData: {
        'type': 'list',
        'items': collection.items.map((item) {
          return {
            'id': '${item.line}:${item.column}',
            'title': '${_todoTypeIcon(item.todoType)} ${item.text}',
            'subtitle':
                'Line ${item.line + 1}${item.author != null ? ' • ${item.author}' : ''}',
            'iconCode': _priorityIconCode(item.priority),
            'onTap': 'jumpToLine',
            'metadata': {'line': item.line},
          };
        }).toList(),
      },
    );
  }

  String _todoTypeIcon(TodoType type) {
    return switch (type) {
      TodoType.todo => '📝',
      TodoType.fixme => '🔧',
      TodoType.hack => '⚠️',
      TodoType.note => '📌',
      TodoType.xxx => '❗',
      TodoType.bug => '🐛',
      TodoType.optimize => '⚡',
      TodoType.review => '👀',
    };
  }

  int _priorityIconCode(TodoPriority priority) {
    return switch (priority) {
      TodoPriority.high => 0xe002, // Icons.priority_high
      TodoPriority.medium => 0xe811, // Icons.warning
      TodoPriority.low => 0xe88e, // Icons.info
    };
  }

  /// Get todos for current file
  TodoCollection? get currentTodos =>
      _currentFileId != null ? _todosByFile[_currentFileId] : null;

  /// Get all todos across all files
  Map<String, TodoCollection> get allTodos => Map.from(_todosByFile);
}
