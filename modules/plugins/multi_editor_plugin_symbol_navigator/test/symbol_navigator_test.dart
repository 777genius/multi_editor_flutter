import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugin_symbol_navigator/multi_editor_plugin_symbol_navigator.dart';

void main() {
  group('SymbolKind', () {
    test('has correct icon codes', () {
      expect(const SymbolKind.classDeclaration().iconCode, 0xe3af);
      expect(const SymbolKind.method().iconCode, 0xe8f4);
      expect(const SymbolKind.function().iconCode, 0xe24d);
    });

    test('has correct display names', () {
      expect(const SymbolKind.classDeclaration().displayName, 'Class');
      expect(const SymbolKind.method().displayName, 'Method');
      expect(const SymbolKind.function().displayName, 'Function');
    });

    test('has correct priority', () {
      expect(const SymbolKind.classDeclaration().priority, 1);
      expect(const SymbolKind.method().priority, 7);
      expect(const SymbolKind.field().priority, 11);
    });
  });

  group('SymbolLocation', () {
    test('calculates line count correctly', () {
      const location = SymbolLocation(
        startLine: 5,
        startColumn: 0,
        endLine: 10,
        endColumn: 0,
        startOffset: 100,
        endOffset: 200,
      );

      expect(location.lineCount, 6); // Lines 5-10 inclusive
    });

    test('checks if contains line', () {
      const location = SymbolLocation(
        startLine: 5,
        startColumn: 0,
        endLine: 10,
        endColumn: 0,
        startOffset: 100,
        endOffset: 200,
      );

      expect(location.containsLine(5), true);
      expect(location.containsLine(7), true);
      expect(location.containsLine(10), true);
      expect(location.containsLine(4), false);
      expect(location.containsLine(11), false);
    });

    test('checks if contains offset', () {
      const location = SymbolLocation(
        startLine: 5,
        startColumn: 0,
        endLine: 10,
        endColumn: 0,
        startOffset: 100,
        endOffset: 200,
      );

      expect(location.containsOffset(100), true);
      expect(location.containsOffset(150), true);
      expect(location.containsOffset(200), true);
      expect(location.containsOffset(99), false);
      expect(location.containsOffset(201), false);
    });

    test('creates from tree-sitter data', () {
      final location = SymbolLocation.fromTreeSitter(
        startRow: 5,
        startCol: 10,
        endRow: 8,
        endCol: 20,
        startByte: 150,
        endByte: 250,
      );

      expect(location.startLine, 5);
      expect(location.startColumn, 10);
      expect(location.endLine, 8);
      expect(location.endColumn, 20);
      expect(location.startOffset, 150);
      expect(location.endOffset, 250);
    });
  });

  group('CodeSymbol', () {
    test('calculates qualified name correctly', () {
      const symbol = CodeSymbol(
        name: 'myMethod',
        kind: SymbolKind.method(),
        location: SymbolLocation(
          startLine: 5,
          startColumn: 0,
          endLine: 10,
          endColumn: 0,
          startOffset: 100,
          endOffset: 200,
        ),
        parentName: 'MyClass',
      );

      expect(symbol.qualifiedName, 'MyClass.myMethod');
    });

    test('identifies container symbols', () {
      const classSymbol = CodeSymbol(
        name: 'MyClass',
        kind: SymbolKind.classDeclaration(),
        location: SymbolLocation(
          startLine: 0,
          startColumn: 0,
          endLine: 10,
          endColumn: 0,
          startOffset: 0,
          endOffset: 100,
        ),
      );

      const methodSymbol = CodeSymbol(
        name: 'myMethod',
        kind: SymbolKind.method(),
        location: SymbolLocation(
          startLine: 5,
          startColumn: 0,
          endLine: 7,
          endColumn: 0,
          startOffset: 50,
          endOffset: 70,
        ),
      );

      expect(classSymbol.isContainer, true);
      expect(methodSymbol.isContainer, false);
    });

    test('adds children correctly', () {
      const parent = CodeSymbol(
        name: 'MyClass',
        kind: SymbolKind.classDeclaration(),
        location: SymbolLocation(
          startLine: 0,
          startColumn: 0,
          endLine: 10,
          endColumn: 0,
          startOffset: 0,
          endOffset: 100,
        ),
      );

      const child = CodeSymbol(
        name: 'myMethod',
        kind: SymbolKind.method(),
        location: SymbolLocation(
          startLine: 5,
          startColumn: 0,
          endLine: 7,
          endColumn: 0,
          startOffset: 50,
          endOffset: 70,
        ),
        parentName: 'MyClass',
      );

      final updated = parent.addChild(child);
      expect(updated.children.length, 1);
      expect(updated.children.first.name, 'myMethod');
    });

    test('finds symbol at line', () {
      const method = CodeSymbol(
        name: 'myMethod',
        kind: SymbolKind.method(),
        location: SymbolLocation(
          startLine: 5,
          startColumn: 0,
          endLine: 7,
          endColumn: 0,
          startOffset: 50,
          endOffset: 70,
        ),
        parentName: 'MyClass',
      );

      const classSymbol = CodeSymbol(
        name: 'MyClass',
        kind: SymbolKind.classDeclaration(),
        location: SymbolLocation(
          startLine: 0,
          startColumn: 0,
          endLine: 10,
          endColumn: 0,
          startOffset: 0,
          endOffset: 100,
        ),
        children: [method],
      );

      final foundMethod = classSymbol.findSymbolAtLine(6);
      expect(foundMethod?.name, 'myMethod');

      final foundClass = classSymbol.findSymbolAtLine(1);
      expect(foundClass?.name, 'MyClass');

      final notFound = classSymbol.findSymbolAtLine(20);
      expect(notFound, null);
    });
  });

  group('SymbolTree', () {
    test('counts all symbols correctly', () {
      const method = CodeSymbol(
        name: 'myMethod',
        kind: SymbolKind.method(),
        location: SymbolLocation(
          startLine: 5,
          startColumn: 0,
          endLine: 7,
          endColumn: 0,
          startOffset: 50,
          endOffset: 70,
        ),
      );

      const classSymbol = CodeSymbol(
        name: 'MyClass',
        kind: SymbolKind.classDeclaration(),
        location: SymbolLocation(
          startLine: 0,
          startColumn: 0,
          endLine: 10,
          endColumn: 0,
          startOffset: 0,
          endOffset: 100,
        ),
        children: [method],
      );

      final tree = SymbolTree(
        filePath: 'test.dart',
        language: 'dart',
        timestamp: DateTime.now(),
        symbols: [classSymbol],
      );

      expect(tree.totalCount, 2); // 1 class + 1 method
    });

    test('finds symbol by name', () {
      const method = CodeSymbol(
        name: 'myMethod',
        kind: SymbolKind.method(),
        location: SymbolLocation(
          startLine: 5,
          startColumn: 0,
          endLine: 7,
          endColumn: 0,
          startOffset: 50,
          endOffset: 70,
        ),
        parentName: 'MyClass',
      );

      const classSymbol = CodeSymbol(
        name: 'MyClass',
        kind: SymbolKind.classDeclaration(),
        location: SymbolLocation(
          startLine: 0,
          startColumn: 0,
          endLine: 10,
          endColumn: 0,
          startOffset: 0,
          endOffset: 100,
        ),
        children: [method],
      );

      final tree = SymbolTree(
        filePath: 'test.dart',
        language: 'dart',
        timestamp: DateTime.now(),
        symbols: [classSymbol],
      );

      expect(tree.findSymbolByName('MyClass')?.name, 'MyClass');
      expect(tree.findSymbolByName('myMethod')?.name, 'myMethod');
      expect(tree.findSymbolByName('MyClass.myMethod')?.name, 'myMethod');
      expect(tree.findSymbolByName('NotFound'), null);
    });

    test('calculates statistics correctly', () {
      const method1 = CodeSymbol(
        name: 'method1',
        kind: SymbolKind.method(),
        location: SymbolLocation(
          startLine: 5,
          startColumn: 0,
          endLine: 7,
          endColumn: 0,
          startOffset: 50,
          endOffset: 70,
        ),
      );

      const method2 = CodeSymbol(
        name: 'method2',
        kind: SymbolKind.method(),
        location: SymbolLocation(
          startLine: 8,
          startColumn: 0,
          endLine: 10,
          endColumn: 0,
          startOffset: 80,
          endOffset: 90,
        ),
      );

      const field = CodeSymbol(
        name: 'myField',
        kind: SymbolKind.field(),
        location: SymbolLocation(
          startLine: 2,
          startColumn: 0,
          endLine: 2,
          endColumn: 10,
          startOffset: 20,
          endOffset: 30,
        ),
      );

      const classSymbol = CodeSymbol(
        name: 'MyClass',
        kind: SymbolKind.classDeclaration(),
        location: SymbolLocation(
          startLine: 0,
          startColumn: 0,
          endLine: 10,
          endColumn: 0,
          startOffset: 0,
          endOffset: 100,
        ),
        children: [method1, method2, field],
      );

      final tree = SymbolTree(
        filePath: 'test.dart',
        language: 'dart',
        timestamp: DateTime.now(),
        symbols: [classSymbol],
      );

      final stats = tree.statistics;
      expect(stats['Class'], 1);
      expect(stats['Method'], 2);
      expect(stats['Field'], 1);
    });
  });
}
