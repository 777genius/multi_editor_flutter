import '../models/snippet_data.dart';

/// Collection of Dart code snippets for autocomplete.
///
/// Includes common Dart language constructs and Flutter widgets.
class DartSnippets {
  DartSnippets._();

  // ============================================================================
  // BASIC DART LANGUAGE CONSTRUCTS
  // ============================================================================

  static const main = SnippetData(
    prefix: 'main',
    label: 'main function',
    body: 'void main() {\n  \${1:// code}\n}',
    description: 'Main entry point',
  );

  static const mainAsync = SnippetData(
    prefix: 'maina',
    label: 'async main function',
    body: 'Future<void> main() async {\n  \${1:// code}\n}',
    description: 'Async main entry point',
  );

  static const classSnippet = SnippetData(
    prefix: 'class',
    label: 'class',
    body: 'class \${1:ClassName} {\n  \${2:// fields and methods}\n}',
    description: 'Class declaration',
  );

  static const abstractClass = SnippetData(
    prefix: 'absclass',
    label: 'abstract class',
    body:
        'abstract class \${1:ClassName} {\n  \${2:// abstract methods}\n}',
    description: 'Abstract class declaration',
  );

  static const enumSnippet = SnippetData(
    prefix: 'enum',
    label: 'enum',
    body: 'enum \${1:EnumName} {\n  \${2:value1},\n  \${3:value2},\n}',
    description: 'Enum declaration',
  );

  static const ifStatement = SnippetData(
    prefix: 'if',
    label: 'if statement',
    body: 'if (\${1:condition}) {\n  \${2:// code}\n}',
    description: 'If statement',
  );

  static const ifElseStatement = SnippetData(
    prefix: 'ifelse',
    label: 'if-else statement',
    body:
        'if (\${1:condition}) {\n  \${2:// code}\n} else {\n  \${3:// code}\n}',
    description: 'If-else statement',
  );

  static const forLoop = SnippetData(
    prefix: 'for',
    label: 'for loop',
    body: 'for (var \${1:i} = 0; \${1:i} < \${2:length}; \${1:i}++) {\n  \${3:// code}\n}',
    description: 'For loop',
  );

  static const forInLoop = SnippetData(
    prefix: 'forin',
    label: 'for-in loop',
    body: 'for (var \${1:item} in \${2:collection}) {\n  \${3:// code}\n}',
    description: 'For-in loop',
  );

  static const whileLoop = SnippetData(
    prefix: 'while',
    label: 'while loop',
    body: 'while (\${1:condition}) {\n  \${2:// code}\n}',
    description: 'While loop',
  );

  static const tryCatch = SnippetData(
    prefix: 'try',
    label: 'try-catch',
    body:
        'try {\n  \${1:// code}\n} catch (\${2:e}) {\n  \${3:// error handling}\n}',
    description: 'Try-catch block',
  );

  static const tryCatchFinally = SnippetData(
    prefix: 'tryf',
    label: 'try-catch-finally',
    body:
        'try {\n  \${1:// code}\n} catch (\${2:e}) {\n  \${3:// error handling}\n} finally {\n  \${4:// cleanup}\n}',
    description: 'Try-catch-finally block',
  );

  static const asyncFunction = SnippetData(
    prefix: 'funa',
    label: 'async function',
    body:
        'Future<\${1:void}> \${2:functionName}() async {\n  \${3:// code}\n}',
    description: 'Async function',
  );

  static const function = SnippetData(
    prefix: 'fun',
    label: 'function',
    body: '\${1:void} \${2:functionName}() {\n  \${3:// code}\n}',
    description: 'Function declaration',
  );

  // ============================================================================
  // FLUTTER WIDGETS
  // ============================================================================

  static const statelessWidget = SnippetData(
    prefix: 'stless',
    label: 'StatelessWidget',
    body: '''class \${1:WidgetName} extends StatelessWidget {
  const \${1:WidgetName}({super.key});

  @override
  Widget build(BuildContext context) {
    return \${2:Container()};
  }
}''',
    description: 'StatelessWidget boilerplate',
  );

  static const statefulWidget = SnippetData(
    prefix: 'stful',
    label: 'StatefulWidget',
    body: '''class \${1:WidgetName} extends StatefulWidget {
  const \${1:WidgetName}({super.key});

  @override
  State<\${1:WidgetName}> createState() => _\${1:WidgetName}State();
}

class _\${1:WidgetName}State extends State<\${1:WidgetName}> {
  @override
  Widget build(BuildContext context) {
    return \${2:Container()};
  }
}''',
    description: 'StatefulWidget boilerplate',
  );

  static const buildMethod = SnippetData(
    prefix: 'build',
    label: 'build method',
    body:
        '@override\nWidget build(BuildContext context) {\n  return \${1:Container()};\n}',
    description: 'Widget build method',
  );

  static const initState = SnippetData(
    prefix: 'initState',
    label: 'initState',
    body: '@override\nvoid initState() {\n  super.initState();\n  \${1:// code}\n}',
    description: 'initState lifecycle method',
  );

  static const dispose = SnippetData(
    prefix: 'dispose',
    label: 'dispose',
    body: '@override\nvoid dispose() {\n  \${1:// cleanup}\n  super.dispose();\n}',
    description: 'dispose lifecycle method',
  );

  static const scaffold = SnippetData(
    prefix: 'scaffold',
    label: 'Scaffold',
    body: '''Scaffold(
  appBar: AppBar(
    title: const Text('\${1:Title}'),
  ),
  body: \${2:Container()},
)''',
    description: 'Scaffold widget',
  );

  static const container = SnippetData(
    prefix: 'container',
    label: 'Container',
    body: 'Container(\n  \${1:child: }\n)',
    description: 'Container widget',
  );

  static const column = SnippetData(
    prefix: 'column',
    label: 'Column',
    body: 'Column(\n  children: [\n    \${1:// widgets}\n  ],\n)',
    description: 'Column widget',
  );

  static const row = SnippetData(
    prefix: 'row',
    label: 'Row',
    body: 'Row(\n  children: [\n    \${1:// widgets}\n  ],\n)',
    description: 'Row widget',
  );

  static const listView = SnippetData(
    prefix: 'listview',
    label: 'ListView',
    body: 'ListView(\n  children: [\n    \${1:// widgets}\n  ],\n)',
    description: 'ListView widget',
  );

  static const listViewBuilder = SnippetData(
    prefix: 'listviewbuilder',
    label: 'ListView.builder',
    body: '''ListView.builder(
  itemCount: \${1:items.length},
  itemBuilder: (context, index) {
    return \${2:ListTile()};
  },
)''',
    description: 'ListView.builder widget',
  );

  static const futureBuilder = SnippetData(
    prefix: 'futurebuilder',
    label: 'FutureBuilder',
    body: '''FutureBuilder<\${1:Type}>(
  future: \${2:futureFunction()},
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return \${3:Text(snapshot.data.toString())};
    } else if (snapshot.hasError) {
      return Text('Error: \${snapshot.error}');
    }
    return const CircularProgressIndicator();
  },
)''',
    description: 'FutureBuilder widget',
  );

  static const streamBuilder = SnippetData(
    prefix: 'streambuilder',
    label: 'StreamBuilder',
    body: '''StreamBuilder<\${1:Type}>(
  stream: \${2:stream},
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return \${3:Text(snapshot.data.toString())};
    } else if (snapshot.hasError) {
      return Text('Error: \${snapshot.error}');
    }
    return const CircularProgressIndicator();
  },
)''',
    description: 'StreamBuilder widget',
  );

  // ============================================================================
  // COMPLETE SNIPPET LIST
  // ============================================================================

  /// All available Dart snippets.
  static const List<SnippetData> all = [
    // Basic Dart
    main,
    mainAsync,
    classSnippet,
    abstractClass,
    enumSnippet,
    ifStatement,
    ifElseStatement,
    forLoop,
    forInLoop,
    whileLoop,
    tryCatch,
    tryCatchFinally,
    asyncFunction,
    function,

    // Flutter Widgets
    statelessWidget,
    statefulWidget,
    buildMethod,
    initState,
    dispose,
    scaffold,
    container,
    column,
    row,
    listView,
    listViewBuilder,
    futureBuilder,
    streamBuilder,
  ];
}
