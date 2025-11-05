import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'editor_config.dart';

class MonacoCodeEditor extends StatefulWidget {
  final String code;
  final String language;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final MonacoTheme? theme;
  final EditorConfig config;

  const MonacoCodeEditor({
    super.key,
    required this.code,
    required this.language,
    this.onChanged,
    this.readOnly = false,
    this.theme,
    this.config = const EditorConfig(),
  });

  @override
  State<MonacoCodeEditor> createState() => _MonacoCodeEditorState();
}

class _MonacoCodeEditorState extends State<MonacoCodeEditor> {
  MonacoController? _controller;
  bool _isInitialized = false;
  String? _lastCode;
  String? _lastLanguage;
  Brightness? _lastBrightness;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _lastCode = widget.code;
    _lastLanguage = widget.language;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null && !_isInitialized) {
      _initializeEditor();
    }
  }

  Future<void> _initializeEditor() async {
    setState(() {
      _isInitialized = true;
    });

    try {
      debugPrint('[MonacoEditor] Initializing editor with code length: ${widget.code.length}, language: ${widget.language}');

      final brightness = Theme.of(context).brightness;
      _lastBrightness = brightness;
      final theme =
          widget.theme ??
          (brightness == Brightness.dark ? MonacoTheme.vsDark : MonacoTheme.vs);

      _controller = await MonacoController.create(
        options: EditorOptions(
          language: _getMonacoLanguage(widget.language),
          theme: theme,
          readOnly: widget.readOnly,
          fontSize: widget.config.fontSize,
          fontFamily: widget.config.fontFamily,
          minimap: widget.config.showMinimap,
          wordWrap: widget.config.wordWrap,
          tabSize: widget.config.tabSize,
          lineNumbers: widget.config.showLineNumbers,
          bracketPairColorization: widget.config.bracketPairColorization,
        ),
      );

      debugPrint('[MonacoEditor] Controller created, waiting for onReady...');
      await _controller!.onReady;

      debugPrint('[MonacoEditor] Ready! Setting value with length: ${widget.code.length}');
      await _controller!.setValue(widget.code);
      _lastCode = widget.code;
      debugPrint('[MonacoEditor] Initialization complete!');

      _controller!.onContentChanged.listen((isFlush) {
        if (widget.onChanged != null && !isFlush) {
          _controller!.getValue().then((value) {
            if (value != _lastCode) {
              _lastCode = value;
              widget.onChanged!(value);
            }
          });
        }
      });

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Failed to initialize Monaco Editor: $e');
    }
  }

  @override
  void didUpdateWidget(MonacoCodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_controller == null || !_isInitialized) return;
    if (_isUpdating) return;

    final currentBrightness = Theme.of(context).brightness;
    if (widget.theme == null && currentBrightness != _lastBrightness) {
      _updateTheme(currentBrightness);
    }

    if (widget.language != oldWidget.language) {
      _updateLanguage();
    }

    if (widget.code != oldWidget.code && widget.code != _lastCode) {
      _updateContent();
    }
  }

  Future<void> _updateLanguage() async {
    if (_controller == null || _isUpdating) return;

    _isUpdating = true;
    try {
      final newLanguage = _getMonacoLanguage(widget.language);
      debugPrint('[MonacoEditor] Updating language to: ${widget.language}');

      await _controller!.setLanguage(newLanguage);
      _lastLanguage = widget.language;

      debugPrint('[MonacoEditor] Language updated successfully');
    } catch (e) {
      debugPrint('[MonacoEditor] Failed to update language: $e');
    } finally {
      _isUpdating = false;
    }
  }

  Future<void> _updateContent() async {
    if (_controller == null || _isUpdating) return;

    _isUpdating = true;
    try {
      debugPrint('[MonacoEditor] Updating content, length: ${widget.code.length}');

      await _controller!.setValue(widget.code);
      _lastCode = widget.code;

      debugPrint('[MonacoEditor] Content updated successfully');
    } catch (e) {
      debugPrint('[MonacoEditor] Failed to update content: $e');
    } finally {
      _isUpdating = false;
    }
  }

  Future<void> _updateTheme(Brightness brightness) async {
    if (_controller == null || _isUpdating) return;

    _isUpdating = true;
    try {
      final newTheme = brightness == Brightness.dark
          ? MonacoTheme.vsDark
          : MonacoTheme.vs;

      debugPrint('[MonacoEditor] Updating theme to: ${newTheme.id} (brightness: $brightness)');

      await _controller!.setTheme(newTheme);
      _lastBrightness = brightness;

      debugPrint('[MonacoEditor] Theme updated successfully');
    } catch (e) {
      debugPrint('[MonacoEditor] Failed to update theme: $e');
    } finally {
      _isUpdating = false;
    }
  }

  MonacoLanguage _getMonacoLanguage(String language) {
    return switch (language.toLowerCase()) {
      'dart' => MonacoLanguage.dart,
      'javascript' || 'js' => MonacoLanguage.javascript,
      'typescript' || 'ts' => MonacoLanguage.typescript,
      'json' => MonacoLanguage.json,
      'html' => MonacoLanguage.html,
      'css' => MonacoLanguage.css,
      'scss' || 'sass' => MonacoLanguage.scss,
      'python' || 'py' => MonacoLanguage.python,
      'rust' || 'rs' => MonacoLanguage.rust,
      'go' => MonacoLanguage.go,
      'java' => MonacoLanguage.java,
      'cpp' || 'c++' || 'cxx' => MonacoLanguage.cpp,
      'csharp' || 'cs' => MonacoLanguage.csharp,
      'markdown' || 'md' => MonacoLanguage.markdown,
      'yaml' || 'yml' => MonacoLanguage.yaml,
      'xml' => MonacoLanguage.xml,
      'sql' => MonacoLanguage.sql,
      'shell' || 'bash' || 'sh' => MonacoLanguage.shell,
      _ => MonacoLanguage.plaintext,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: MonacoEditor(
            controller: _controller!,
            showStatusBar: widget.config.showStatusBar,
          ),
        ),
        MonacoFocusGuard(controller: _controller!),
      ],
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
