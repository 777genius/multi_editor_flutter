import 'dart:async';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import 'package:multi_editor_plugin_base/multi_editor_plugin_base.dart';
import 'package:git_integration/git_integration.dart';

/// Git Blame Inline Viewer Plugin
///
/// Shows git blame information for the current line in the editor.
/// Displays:
/// - Commit hash
/// - Author
/// - Relative time
/// - Commit message
class GitBlamePlugin extends BaseEditorPlugin with StatefulPlugin {
  BlameService? _blameService;
  String? _currentFileId;
  int? _currentLine;
  BlameLine? _currentBlameLine;
  Timer? _blameDebounce;

  @override
  PluginManifest get manifest => PluginManifestBuilder()
      .withId('plugin.git-blame')
      .withName('Git Blame Viewer')
      .withVersion('0.1.0')
      .withDescription('Shows git blame information for current line')
      .withAuthor('Multi Editor Team')
      .addActivationEvent('onFileOpen')
      .addActivationEvent('onCursorPositionChange')
      .build();

  @override
  Future<void> onInitialize(PluginContext context) async {
    // Try to get BlameService from context
    _blameService = context.getService<BlameService>();

    if (_blameService == null) {
      print('[GitBlame] BlameService not available');
    }

    setState('blameLine', _currentBlameLine);

    // Register UI
    final uiService = context.getService<PluginUIService>();
    final descriptor = getUIDescriptor();
    if (descriptor != null && uiService != null) {
      uiService.registerUI(descriptor);
    }
  }

  @override
  Future<void> onDispose() async {
    _blameDebounce?.cancel();
    disposeStateful();
  }

  @override
  void onFileOpen(FileDocument file) {
    safeExecute('Update current file', () {
      _currentFileId = file.id;
      _currentBlameLine = null;
      _updateUI();
    });
  }

  @override
  void onFileClose(String fileId) {
    safeExecute('Clear blame on file close', () {
      if (_currentFileId == fileId) {
        _currentFileId = null;
        _currentLine = null;
        _currentBlameLine = null;
        _updateUI();
      }
    });
  }

  /// Handle cursor position change
  /// Note: This event is not in the current plugin API, but would be added
  void onCursorPositionChange(int line, int column) {
    safeExecute('Update blame for cursor line', () {
      if (_currentLine != line) {
        _currentLine = line;
        _scheduleBlameUpdate();
      }
    });
  }

  void _scheduleBlameUpdate() {
    _blameDebounce?.cancel();
    _blameDebounce = Timer(const Duration(milliseconds: 200), () {
      _fetchBlameForCurrentLine();
    });
  }

  Future<void> _fetchBlameForCurrentLine() async {
    if (_blameService == null || _currentFileId == null || _currentLine == null) {
      return;
    }

    try {
      // Get repository path from current file
      final repository = context.fileRepository;
      final file = await repository.getFile(_currentFileId!);

      if (file == null) return;

      // Get blame for file
      final blameResult = await _blameService!.getBlame(
        RepositoryPath(file.name), // Simplified, should get actual repo path
        file.name,
      );

      blameResult.fold(
        (failure) {
          print('[GitBlame] Failed to get blame: $failure');
          _currentBlameLine = null;
        },
        (blameLines) {
          // Find blame for current line
          if (_currentLine! < blameLines.length) {
            _currentBlameLine = blameLines[_currentLine!];
          } else {
            _currentBlameLine = null;
          }
        },
      );

      _updateUI();
    } catch (e) {
      print('[GitBlame] Error fetching blame: $e');
    }
  }

  void _updateUI() {
    setState('blameLine', _currentBlameLine);

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
    if (_currentBlameLine == null) return null;

    final blame = _currentBlameLine!;

    return PluginUIDescriptor(
      pluginId: manifest.id,
      iconCode: 0xe889, // Icons.history
      iconFamily: 'MaterialIcons',
      tooltip: 'Git Blame',
      priority: 25,
      uiData: {
        'type': 'inline',
        'items': [
          {
            'id': 'blame-info',
            'title': '${blame.shortHash} • ${blame.author.name}',
            'subtitle': '${blame.relativeTime} • ${blame.commitMessage}',
            'iconCode': 0xe889, // Icons.history
            'onTap': 'showCommitDetails',
            'metadata': {
              'commitHash': blame.commitHash.value,
              'author': blame.author.name,
              'email': blame.author.email,
              'timestamp': blame.timestamp.toIso8601String(),
              'message': blame.commitMessage,
            },
          },
        ],
      },
    );
  }

  /// Get current blame line
  BlameLine? get currentBlameLine => _currentBlameLine;
}
