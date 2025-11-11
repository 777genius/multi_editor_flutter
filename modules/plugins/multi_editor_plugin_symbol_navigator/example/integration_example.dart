// Integration example: How to use SymbolNavigatorPlugin in your application

/*
This example shows how to integrate the Symbol Navigator Plugin
into a Flutter application with the multi_editor plugin system.
*/

import 'package:flutter/material.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import 'package:multi_editor_plugin_symbol_navigator/multi_editor_plugin_symbol_navigator.dart';

/// Example: Registering the Symbol Navigator Plugin
Future<void> registerSymbolNavigatorPlugin(PluginManager pluginManager) async {
  // Create plugin instance
  final symbolNavigator = SymbolNavigatorPlugin();

  // Register with plugin manager
  await pluginManager.registerPlugin(symbolNavigator);

  print('Symbol Navigator Plugin registered');
}

/// Example: Accessing symbol data from the plugin
class SymbolNavigatorWidget extends StatelessWidget {
  final SymbolNavigatorPlugin plugin;

  const SymbolNavigatorWidget({
    Key? key,
    required this.plugin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Access current symbol tree
    final symbolTree = plugin.currentSymbolTree;

    if (symbolTree == null) {
      return const Center(
        child: Text('No symbols available\nOpen a file to see symbols'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with statistics
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '${symbolTree.filePath} (${symbolTree.totalCount} symbols)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),

        // Symbol tree
        Expanded(
          child: ListView.builder(
            itemCount: symbolTree.symbols.length,
            itemBuilder: (context, index) {
              final symbol = symbolTree.symbols[index];
              return SymbolTile(
                symbol: symbol,
                onTap: () => _onSymbolTap(context, symbol),
              );
            },
          ),
        ),

        // Statistics footer
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Statistics:'),
              ...symbolTree.statistics.entries.map(
                (e) => Text('  ${e.key}: ${e.value}'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onSymbolTap(BuildContext context, CodeSymbol symbol) {
    // Handle symbol click - jump to definition
    plugin.onSymbolClick(symbol.name, symbol.location.startLine);

    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Jump to ${symbol.qualifiedName}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

/// Example: Symbol tile widget
class SymbolTile extends StatelessWidget {
  final CodeSymbol symbol;
  final VoidCallback onTap;
  final int indent;

  const SymbolTile({
    Key? key,
    required this.symbol,
    required this.onTap,
    this.indent = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16.0 + (indent * 16.0),
              top: 4.0,
              bottom: 4.0,
              right: 8.0,
            ),
            child: Row(
              children: [
                // Icon
                Icon(
                  IconData(symbol.kind.iconCode, fontFamily: 'MaterialIcons'),
                  size: 16,
                  color: _getIconColor(),
                ),
                const SizedBox(width: 8),

                // Name
                Expanded(
                  child: Text(
                    symbol.name,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),

                // Line number
                Text(
                  'L${symbol.location.startLine + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Children
        ...symbol.children.map(
          (child) => SymbolTile(
            symbol: child,
            onTap: () => onTap(),
            indent: indent + 1,
          ),
        ),
      ],
    );
  }

  Color _getIconColor() {
    return symbol.kind.map(
      classDeclaration: (_) => Colors.blue,
      abstractClass: (_) => Colors.purple,
      mixin: (_) => Colors.orange,
      extension: (_) => Colors.teal,
      enumDeclaration: (_) => Colors.green,
      typedef: (_) => Colors.indigo,
      function: (_) => Colors.amber,
      method: (_) => Colors.lightBlue,
      constructor: (_) => Colors.brown,
      getter: (_) => Colors.lightGreen,
      setter: (_) => Colors.lime,
      field: (_) => Colors.grey,
      property: (_) => Colors.blueGrey,
      constant: (_) => Colors.deepOrange,
      variable: (_) => Colors.cyan,
      enumValue: (_) => Colors.lightGreen,
      parameter: (_) => Colors.grey,
    );
  }
}

/// Example: Full integration in app
class ExampleApp extends StatefulWidget {
  const ExampleApp({Key? key}) : super(key: key);

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  late PluginManager _pluginManager;
  late SymbolNavigatorPlugin _symbolNavigator;

  @override
  void initState() {
    super.initState();
    _initializePlugins();
  }

  Future<void> _initializePlugins() async {
    // Create plugin manager
    _pluginManager = PluginManager();

    // Create and register Symbol Navigator
    _symbolNavigator = SymbolNavigatorPlugin();
    await _pluginManager.registerPlugin(_symbolNavigator);

    // Initialize plugin
    // (This would normally be done by the plugin system)
    // await _symbolNavigator.onInitialize(context);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Symbol Navigator Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Symbol Navigator Example'),
        ),
        body: Row(
          children: [
            // Main editor area (placeholder)
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.grey[100],
                child: const Center(
                  child: Text('Editor Area'),
                ),
              ),
            ),

            // Symbol navigator sidebar
            SizedBox(
              width: 300,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: SymbolNavigatorWidget(
                  plugin: _symbolNavigator,
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _simulateFileOpen,
          child: const Icon(Icons.file_open),
          tooltip: 'Simulate file open',
        ),
      ),
    );
  }

  void _simulateFileOpen() {
    // Simulate opening a Dart file
    final mockFile = FileDocument(
      id: 'mock-file-1',
      name: 'my_widget.dart',
      content: '''
class MyWidget extends StatelessWidget {
  final String title;

  const MyWidget({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(title);
  }
}

mixin Logger {
  void log(String message) {
    print(message);
  }
}

enum Status { pending, active, completed }
''',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Trigger file open event
    _symbolNavigator.onFileOpen(mockFile);

    setState(() {});
  }

  @override
  void dispose() {
    _symbolNavigator.onDispose();
    super.dispose();
  }
}

/// Example: Running the app
void main() {
  runApp(const ExampleApp());
}

/*
Expected UI Layout:

┌─────────────────────────────────────────────────────────────┐
│ Symbol Navigator Example                                    │
├─────────────────────────────────────────────────────────────┤
│                           │  my_widget.dart (5 symbols)     │
│                           ├──────────────────────────────────┤
│                           │  🏛️ MyWidget             L1      │
│      Editor Area          │    📦 title              L2      │
│                           │    🔨 MyWidget           L4      │
│    (Code display)         │    ⚡ build              L7      │
│                           │  🔀 Logger               L12     │
│                           │    ⚡ log                L13     │
│                           │  📋 Status               L18     │
│                           │                                  │
│                           │  Statistics:                     │
│                           │    Class: 1                      │
│                           │    Mixin: 1                      │
│                           │    Enum: 1                       │
│                           │    Field: 1                      │
│                           │    Constructor: 1                │
│                           │    Method: 2                     │
└─────────────────────────────────────────────────────────────┘

Features demonstrated:
- Plugin registration
- Symbol tree display
- Hierarchical structure (children indented)
- Click-to-navigate (with snackbar feedback)
- Statistics display
- Icon-based symbol type visualization
- Line number display
- Real-time updates (on file open/change)

Next steps:
1. Connect to real editor controller
2. Integrate jump-to-line functionality
3. Add search/filter capabilities
4. Implement symbol outline breadcrumbs
*/
