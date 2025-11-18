import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';

void main() {
  group('DocumentSymbol', () {
    late TextSelection range;
    late TextSelection selectionRange;

    setUp(() {
      range = const TextSelection(
        start: CursorPosition(line: 10, column: 0),
        end: CursorPosition(line: 20, column: 0),
      );
      selectionRange = const TextSelection(
        start: CursorPosition(line: 10, column: 6),
        end: CursorPosition(line: 10, column: 16),
      );
    });

    group('creation', () {
      test('should create document symbol with required fields', () {
        // Act
        final symbol = DocumentSymbol(
          name: 'MyClass',
          kind: SymbolKind.class_,
          range: range,
          selectionRange: selectionRange,
        );

        // Assert
        expect(symbol.name, equals('MyClass'));
        expect(symbol.kind, equals(SymbolKind.class_));
        expect(symbol.range, equals(range));
        expect(symbol.selectionRange, equals(selectionRange));
        expect(symbol.detail, isNull);
        expect(symbol.children, isNull);
      });

      test('should create document symbol with detail', () {
        // Act
        final symbol = DocumentSymbol(
          name: 'myMethod',
          detail: 'void myMethod(String arg)',
          kind: SymbolKind.method,
          range: range,
          selectionRange: selectionRange,
        );

        // Assert
        expect(symbol.detail, equals('void myMethod(String arg)'));
      });

      test('should create document symbol with children', () {
        // Arrange
        final child1 = DocumentSymbol(
          name: 'field1',
          kind: SymbolKind.field,
          range: range,
          selectionRange: selectionRange,
        );

        final child2 = DocumentSymbol(
          name: 'method1',
          kind: SymbolKind.method,
          range: range,
          selectionRange: selectionRange,
        );

        // Act
        final parent = DocumentSymbol(
          name: 'MyClass',
          kind: SymbolKind.class_,
          range: range,
          selectionRange: selectionRange,
          children: [child1, child2],
        );

        // Assert
        expect(parent.children, isNotNull);
        expect(parent.children!.length, equals(2));
        expect(parent.children![0].name, equals('field1'));
        expect(parent.children![1].name, equals('method1'));
      });
    });

    group('SymbolKind', () {
      test('should have class kind', () {
        expect(SymbolKind.values, contains(SymbolKind.class_));
      });

      test('should have method kind', () {
        expect(SymbolKind.values, contains(SymbolKind.method));
      });

      test('should have function kind', () {
        expect(SymbolKind.values, contains(SymbolKind.function));
      });

      test('should have field kind', () {
        expect(SymbolKind.values, contains(SymbolKind.field));
      });

      test('should have variable kind', () {
        expect(SymbolKind.values, contains(SymbolKind.variable));
      });

      test('should have constructor kind', () {
        expect(SymbolKind.values, contains(SymbolKind.constructor));
      });
    });

    group('hierarchical symbols', () {
      test('should represent class with methods', () {
        // Arrange
        final method1 = DocumentSymbol(
          name: 'toString',
          kind: SymbolKind.method,
          range: const TextSelection(
            start: CursorPosition(line: 11, column: 2),
            end: CursorPosition(line: 13, column: 3),
          ),
          selectionRange: const TextSelection(
            start: CursorPosition(line: 11, column: 10),
            end: CursorPosition(line: 11, column: 18),
          ),
        );

        final method2 = DocumentSymbol(
          name: 'equals',
          kind: SymbolKind.method,
          range: const TextSelection(
            start: CursorPosition(line: 15, column: 2),
            end: CursorPosition(line: 17, column: 3),
          ),
          selectionRange: const TextSelection(
            start: CursorPosition(line: 15, column: 10),
            end: CursorPosition(line: 15, column: 16),
          ),
        );

        // Act
        final classSymbol = DocumentSymbol(
          name: 'Person',
          kind: SymbolKind.class_,
          range: range,
          selectionRange: selectionRange,
          children: [method1, method2],
        );

        // Assert
        expect(classSymbol.name, equals('Person'));
        expect(classSymbol.children!.length, equals(2));
        expect(classSymbol.children!.every((child) =>
          child.kind == SymbolKind.method), isTrue);
      });

      test('should represent nested classes', () {
        // Arrange
        final innerClass = DocumentSymbol(
          name: 'InnerClass',
          kind: SymbolKind.class_,
          range: const TextSelection(
            start: CursorPosition(line: 12, column: 2),
            end: CursorPosition(line: 15, column: 3),
          ),
          selectionRange: const TextSelection(
            start: CursorPosition(line: 12, column: 8),
            end: CursorPosition(line: 12, column: 18),
          ),
        );

        // Act
        final outerClass = DocumentSymbol(
          name: 'OuterClass',
          kind: SymbolKind.class_,
          range: range,
          selectionRange: selectionRange,
          children: [innerClass],
        );

        // Assert
        expect(outerClass.children![0].name, equals('InnerClass'));
        expect(outerClass.children![0].kind, equals(SymbolKind.class_));
      });

      test('should represent deeply nested symbols', () {
        // Arrange - Method inside class inside module
        final method = DocumentSymbol(
          name: 'innerMethod',
          kind: SymbolKind.method,
          range: range,
          selectionRange: selectionRange,
        );

        final innerClass = DocumentSymbol(
          name: 'InnerClass',
          kind: SymbolKind.class_,
          range: range,
          selectionRange: selectionRange,
          children: [method],
        );

        final module = DocumentSymbol(
          name: 'MyModule',
          kind: SymbolKind.module,
          range: range,
          selectionRange: selectionRange,
          children: [innerClass],
        );

        // Assert
        expect(module.children![0].children![0].name, equals('innerMethod'));
      });
    });

    group('equality', () {
      test('should be equal with same data', () {
        final symbol1 = DocumentSymbol(
          name: 'Test',
          kind: SymbolKind.function,
          range: range,
          selectionRange: selectionRange,
        );

        final symbol2 = DocumentSymbol(
          name: 'Test',
          kind: SymbolKind.function,
          range: range,
          selectionRange: selectionRange,
        );

        expect(symbol1, equals(symbol2));
      });

      test('should not be equal with different name', () {
        final symbol1 = DocumentSymbol(
          name: 'Test1',
          kind: SymbolKind.function,
          range: range,
          selectionRange: selectionRange,
        );

        final symbol2 = DocumentSymbol(
          name: 'Test2',
          kind: SymbolKind.function,
          range: range,
          selectionRange: selectionRange,
        );

        expect(symbol1, isNot(equals(symbol2)));
      });
    });
  });

  group('WorkspaceSymbol', () {
    group('creation', () {
      test('should create workspace symbol with required fields', () {
        // Act
        const symbol = WorkspaceSymbol(
          name: 'MyClass',
          kind: SymbolKind.class_,
          location: DocumentUri('file:///test.dart'),
        );

        // Assert
        expect(symbol.name, equals('MyClass'));
        expect(symbol.kind, equals(SymbolKind.class_));
        expect(symbol.location, equals(const DocumentUri('file:///test.dart')));
        expect(symbol.containerName, isNull);
      });

      test('should create workspace symbol with container name', () {
        // Act
        const symbol = WorkspaceSymbol(
          name: 'myMethod',
          kind: SymbolKind.method,
          location: DocumentUri('file:///test.dart'),
          containerName: 'MyClass',
        );

        // Assert
        expect(symbol.containerName, equals('MyClass'));
      });
    });

    group('equality', () {
      test('should be equal with same data', () {
        const symbol1 = WorkspaceSymbol(
          name: 'Test',
          kind: SymbolKind.function,
          location: DocumentUri('file:///test.dart'),
        );

        const symbol2 = WorkspaceSymbol(
          name: 'Test',
          kind: SymbolKind.function,
          location: DocumentUri('file:///test.dart'),
        );

        expect(symbol1, equals(symbol2));
      });

      test('should not be equal with different location', () {
        const symbol1 = WorkspaceSymbol(
          name: 'Test',
          kind: SymbolKind.function,
          location: DocumentUri('file:///test1.dart'),
        );

        const symbol2 = WorkspaceSymbol(
          name: 'Test',
          kind: SymbolKind.function,
          location: DocumentUri('file:///test2.dart'),
        );

        expect(symbol1, isNot(equals(symbol2)));
      });
    });

    group('search results', () {
      test('should represent search result with container', () {
        const symbol = WorkspaceSymbol(
          name: 'build',
          kind: SymbolKind.method,
          location: DocumentUri('file:///lib/widget.dart'),
          containerName: 'MyWidget',
        );

        expect(symbol.name, equals('build'));
        expect(symbol.containerName, equals('MyWidget'));
      });

      test('should represent top-level function', () {
        const symbol = WorkspaceSymbol(
          name: 'main',
          kind: SymbolKind.function,
          location: DocumentUri('file:///lib/main.dart'),
        );

        expect(symbol.name, equals('main'));
        expect(symbol.containerName, isNull);
      });
    });
  });
}
