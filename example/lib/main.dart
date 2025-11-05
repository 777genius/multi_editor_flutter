import 'package:flutter/material.dart';
import 'package:editor_ui/editor_ui.dart';
import 'di/service_locator.dart';
import 'widgets/app_header.dart';
import 'widgets/setting_row.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies
  await ServiceLocator.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi-File Code Editor',
      debugShowCheckedModeBanner: false,
      theme: AppThemeData.light(),
      darkTheme: AppThemeData.dark(),
      themeMode: _themeMode,
      home: EditorPage(
        themeMode: _themeMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class EditorPage extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  const EditorPage({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final _fileTreeController = ServiceLocator.instance.fileTreeController;
  final _editorController = ServiceLocator.instance.editorController;
  final _pluginManager = ServiceLocator.instance.pluginManager;
  final _editorConfig = const EditorConfig(
    fontSize: 14.0,
    fontFamily: 'Consolas, Monaco, monospace',
    showMinimap: true,
    wordWrap: true,
    tabSize: 2,
    showLineNumbers: true,
    bracketPairColorization: true,
    showStatusBar: true,
    autoSave: true,
    autoSaveDelay: 2,
  );

  @override
  Widget build(BuildContext context) {
    return EditorScaffold(
      fileTreeController: _fileTreeController,
      editorController: _editorController,
      pluginManager: _pluginManager,
      editorConfig: _editorConfig,
      customHeader: AppHeader(
        themeMode: widget.themeMode,
        onToggleTheme: widget.onToggleTheme,
        onShowSettings: () => _showSettingsDialog(context),
        onShowAbout: () => _showAboutDialog(context),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Editor Settings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Configuration:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 16),
                  SettingRow(
                      label: 'Font Size',
                      value: '${_editorConfig.fontSize}px'),
                  SettingRow(
                      label: 'Font Family',
                      value: _editorConfig.fontFamily),
                  SettingRow(
                    label: 'Tab Size',
                    value: '${_editorConfig.tabSize} spaces',
                  ),
                  SettingRow(
                    label: 'Line Numbers',
                    value:
                        _editorConfig.showLineNumbers ? 'Enabled' : 'Disabled',
                  ),
                  SettingRow(
                    label: 'Minimap',
                    value: _editorConfig.showMinimap ? 'Enabled' : 'Disabled',
                  ),
                  SettingRow(
                    label: 'Word Wrap',
                    value: _editorConfig.wordWrap ? 'Enabled' : 'Disabled',
                  ),
                  SettingRow(
                    label: 'Bracket Colorization',
                    value: _editorConfig.bracketPairColorization
                        ? 'Enabled'
                        : 'Disabled',
                  ),
                  SettingRow(
                    label: 'Auto Save',
                    value: _editorConfig.autoSave
                        ? 'Enabled (${_editorConfig.autoSaveDelay}s delay)'
                        : 'Disabled',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('About'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.code,
                      color: Theme.of(context).colorScheme.primary,
                      size: 48,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Multi-File Code Editor',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Version 1.0.0',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Features:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                const Text('• File tree with unlimited nesting'),
                const Text('• Monaco code editor with syntax highlighting'),
                const Text('• Drag & Drop support'),
                const Text('• Auto-save functionality'),
                const Text('• File watching'),
                const Text('• Multiple language support'),
                const SizedBox(height: 16),
                Text(
                  'Architecture:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                const Text('• Clean Architecture'),
                const Text('• Domain-Driven Design'),
                const Text('• SOLID Principles'),
                const Text('• ValueNotifier State Management'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    // Controllers are managed by ServiceLocator
    super.dispose();
  }
}
