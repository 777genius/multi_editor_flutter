// Example of using SymbolNavigatorPlugin

import 'package:multi_editor_plugin_symbol_navigator/multi_editor_plugin_symbol_navigator.dart';

void main() {
  // Example 1: Creating symbol manually
  print('=== Example 1: Creating Symbols ===');

  final methodSymbol = CodeSymbol(
    name: 'build',
    kind: const SymbolKind.method(),
    location: SymbolLocation(
      startLine: 10,
      startColumn: 2,
      endLine: 15,
      endColumn: 3,
      startOffset: 200,
      endOffset: 350,
    ),
    parentName: 'MyWidget',
  );

  print('Method: ${methodSymbol.name}');
  print('Kind: ${methodSymbol.kind.displayName}');
  print('Qualified: ${methodSymbol.qualifiedName}');
  print('Location: Line ${methodSymbol.location.startLine}');

  // Example 2: Building a class with children
  print('\n=== Example 2: Class with Children ===');

  final field = CodeSymbol(
    name: 'counter',
    kind: const SymbolKind.field(),
    location: SymbolLocation(
      startLine: 7,
      startColumn: 2,
      endLine: 7,
      endColumn: 15,
      startOffset: 120,
      endOffset: 135,
    ),
    parentName: 'MyWidget',
  );

  final constructor = CodeSymbol(
    name: 'MyWidget',
    kind: const SymbolKind.constructor(),
    location: SymbolLocation(
      startLine: 9,
      startColumn: 2,
      endLine: 9,
      endColumn: 25,
      startOffset: 150,
      endOffset: 175,
    ),
    parentName: 'MyWidget',
  );

  final classSymbol = CodeSymbol(
    name: 'MyWidget',
    kind: const SymbolKind.classDeclaration(),
    location: SymbolLocation(
      startLine: 5,
      startColumn: 0,
      endLine: 20,
      endColumn: 1,
      startOffset: 100,
      endOffset: 500,
    ),
    children: [field, constructor, methodSymbol],
  );

  print('Class: ${classSymbol.name}');
  print('Children: ${classSymbol.children.length}');
  print('Is container: ${classSymbol.isContainer}');

  for (final child in classSymbol.children) {
    print('  - ${child.kind.displayName}: ${child.name}');
  }

  // Example 3: Symbol tree
  print('\n=== Example 3: Symbol Tree ===');

  final tree = SymbolTree(
    filePath: 'lib/widgets/my_widget.dart',
    language: 'dart',
    timestamp: DateTime.now(),
    symbols: [classSymbol],
    parseDurationMs: 5,
  );

  print('File: ${tree.filePath}');
  print('Language: ${tree.language}');
  print('Total symbols: ${tree.totalCount}');
  print('Parse time: ${tree.parseDurationMs}ms');

  print('\nStatistics:');
  tree.statistics.forEach((kind, count) {
    print('  $kind: $count');
  });

  // Example 4: Finding symbols
  print('\n=== Example 4: Finding Symbols ===');

  final foundByName = tree.findSymbolByName('build');
  if (foundByName != null) {
    print('Found by name: ${foundByName.qualifiedName}');
  }

  final foundAtLine = tree.findSymbolAtLine(10);
  if (foundAtLine != null) {
    print('Symbol at line 10: ${foundAtLine.name} (${foundAtLine.kind.displayName})');
  }

  // Example 5: Location queries
  print('\n=== Example 5: Location Queries ===');

  final location = methodSymbol.location;
  print('Lines spanned: ${location.lineCount}');
  print('Contains line 12: ${location.containsLine(12)}');
  print('Contains offset 250: ${location.containsOffset(250)}');

  // Example 6: Symbol kind priorities (for sorting)
  print('\n=== Example 6: Symbol Priorities ===');

  final kinds = [
    const SymbolKind.field(),
    const SymbolKind.classDeclaration(),
    const SymbolKind.method(),
    const SymbolKind.constructor(),
  ];

  final sorted = kinds.toList()..sort((a, b) => a.priority.compareTo(b.priority));

  print('Sorted by priority:');
  for (final kind in sorted) {
    print('  ${kind.priority}. ${kind.displayName}');
  }

  // Example 7: Creating from tree-sitter data
  print('\n=== Example 7: From Tree-Sitter Data ===');

  final tsLocation = SymbolLocation.fromTreeSitter(
    startRow: 5,
    startCol: 10,
    endRow: 8,
    endCol: 20,
    startByte: 150,
    endByte: 250,
  );

  print('Tree-sitter location:');
  print('  Lines: ${tsLocation.startLine}-${tsLocation.endLine}');
  print('  Columns: ${tsLocation.startColumn}-${tsLocation.endColumn}');
  print('  Bytes: ${tsLocation.startOffset}-${tsLocation.endOffset}');

  // Example 8: Nested symbol navigation
  print('\n=== Example 8: Nested Navigation ===');

  final allDescendants = classSymbol.getAllDescendants();
  print('All descendants of ${classSymbol.name}:');
  for (final desc in allDescendants) {
    print('  - ${desc.qualifiedName}');
  }

  // Example 9: Symbol metadata
  print('\n=== Example 9: Symbol Metadata ===');

  final symbolWithMeta = CodeSymbol(
    name: 'asyncMethod',
    kind: const SymbolKind.method(),
    location: tsLocation,
    metadata: {
      'async': true,
      'visibility': 'public',
      'returnType': 'Future<void>',
      'parameters': ['String name', 'int age'],
    },
  );

  print('Method: ${symbolWithMeta.name}');
  print('Metadata:');
  symbolWithMeta.metadata.forEach((key, value) {
    print('  $key: $value');
  });

  print('\n=== All Examples Complete ===');
}

/*
Expected output:

=== Example 1: Creating Symbols ===
Method: build
Kind: Method
Qualified: MyWidget.build
Location: Line 10

=== Example 2: Class with Children ===
Class: MyWidget
Children: 3
Is container: true
  - Field: counter
  - Constructor: MyWidget
  - Method: build

=== Example 3: Symbol Tree ===
File: lib/widgets/my_widget.dart
Language: dart
Total symbols: 4
Parse time: 5ms

Statistics:
  Class: 1
  Field: 1
  Constructor: 1
  Method: 1

=== Example 4: Finding Symbols ===
Found by name: MyWidget.build
Symbol at line 10: build (Method)

=== Example 5: Location Queries ===
Lines spanned: 6
Contains line 12: true
Contains offset 250: true

=== Example 6: Symbol Priorities ===
Sorted by priority:
  1. Class
  6. Constructor
  7. Method
  11. Field

=== Example 7: From Tree-Sitter Data ===
Tree-sitter location:
  Lines: 5-8
  Columns: 10-20
  Bytes: 150-250

=== Example 8: Nested Navigation ===
All descendants of MyWidget:
  - MyWidget.counter
  - MyWidget.MyWidget
  - MyWidget.build

=== Example 9: Symbol Metadata ===
Method: asyncMethod
Metadata:
  async: true
  visibility: public
  returnType: Future<void>
  parameters: [String name, int age]

=== All Examples Complete ===
*/
