import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugin_symbol_navigator/src/domain/entities/code_symbol.dart';
import 'package:multi_editor_plugin_symbol_navigator/src/domain/value_objects/symbol_kind.dart';
import 'package:multi_editor_plugin_symbol_navigator/src/domain/value_objects/symbol_location.dart';

void main() {
  group('CodeSymbol', () {
    group('constructor', () {
      test('should create instance with required fields', () {
        // Arrange
        const location = SymbolLocation(
          startLine: 10,
          startColumn: 0,
          endLine: 20,
          endColumn: 1,
          startOffset: 100,
          endOffset: 200,
        );

        // Act
        const symbol = CodeSymbol(
          name: 'MyClass',
          kind: SymbolKind.classDeclaration(),
          location: location,
        );

        // Assert
        expect(symbol.name, 'MyClass');
        expect(symbol.kind, const SymbolKind.classDeclaration());
        expect(symbol.location, location);
        expect(symbol.parentName, isNull);
        expect(symbol.children, isEmpty);
        expect(symbol.metadata, isEmpty);
      });

      test('should create instance with all fields', () {
        // Arrange
        const location = SymbolLocation(
          startLine: 10,
          startColumn: 0,
          endLine: 20,
          endColumn: 1,
          startOffset: 100,
          endOffset: 200,
        );
        const child = CodeSymbol(
          name: 'build',
          kind: SymbolKind.method(),
          location: SymbolLocation(
            startLine: 15,
            startColumn: 2,
            endLine: 18,
            endColumn: 3,
            startOffset: 150,
            endOffset: 180,
          ),
        );

        // Act
        final symbol = CodeSymbol(
          name: 'MyWidget',
          kind: const SymbolKind.classDeclaration(),
          location: location,
          parentName: 'ParentClass',
          children: const [child],
          metadata: const {'abstract': false, 'sealed': false},
        );

        // Assert
        expect(symbol.name, 'MyWidget');
        expect(symbol.parentName, 'ParentClass');
        expect(symbol.children.length, 1);
        expect(symbol.children.first.name, 'build');
        expect(symbol.metadata, {'abstract': false, 'sealed': false});
      });

      test('should create instance with multiple children', () {
        // Arrange
        const location = SymbolLocation(
          startLine: 0,
          startColumn: 0,
          endLine: 100,
          endColumn: 1,
          startOffset: 0,
          endOffset: 1000,
        );
        const children = [
          CodeSymbol(
            name: 'method1',
            kind: SymbolKind.method(),
            location: SymbolLocation(
              startLine: 10,
              startColumn: 2,
              endLine: 15,
              endColumn: 3,
              startOffset: 100,
              endOffset: 150,
            ),
          ),
          CodeSymbol(
            name: 'method2',
            kind: SymbolKind.method(),
            location: SymbolLocation(
              startLine: 20,
              startColumn: 2,
              endLine: 25,
              endColumn: 3,
              startOffset: 200,
              endOffset: 250,
            ),
          ),
        ];

        // Act
        const symbol = CodeSymbol(
          name: 'MyClass',
          kind: SymbolKind.classDeclaration(),
          location: location,
          children: children,
        );

        // Assert
        expect(symbol.children.length, 2);
        expect(symbol.children[0].name, 'method1');
        expect(symbol.children[1].name, 'method2');
      });
    });

    group('isContainer getter', () {
      test('should return true for class declaration', () {
        // Arrange
        const symbol = CodeSymbol(
          name: 'MyClass',
          kind: SymbolKind.classDeclaration(),
          location: SymbolLocation(
            startLine: 0,
            startColumn: 0,
            endLine: 10,
            endColumn: 1,
            startOffset: 0,
            endOffset: 100,
          ),
        );

        // Act & Assert
        expect(symbol.isContainer, true);
      });

      test('should return true for abstract class', () {
        // Arrange
        const symbol = CodeSymbol(
          name: 'MyAbstractClass',
          kind: SymbolKind.abstractClass(),
          location: SymbolLocation(
            startLine: 0,
            startColumn: 0,
            endLine: 10,
            endColumn: 1,
            startOffset: 0,
            endOffset: 100,
          ),
        );

        // Act & Assert
        expect(symbol.isContainer, true);
      });

      test('should return true for mixin', () {
        // Arrange
        const symbol = CodeSymbol(
          name: 'MyMixin',
          kind: SymbolKind.mixin(),
          location: SymbolLocation(
            startLine: 0,
            startColumn: 0,
            endLine: 10,
            endColumn: 1,
            startOffset: 0,
            endOffset: 100,
          ),
        );

        // Act & Assert
        expect(symbol.isContainer, true);
      });

      test('should return true for extension', () {
        // Arrange
        const symbol = CodeSymbol(
          name: 'MyExtension',
          kind: SymbolKind.extension(),
          location: SymbolLocation(
            startLine: 0,
            startColumn: 0,
            endLine: 10,
            endColumn: 1,
            startOffset: 0,
            endOffset: 100,
          ),
        );

        // Act & Assert
        expect(symbol.isContainer, true);
      });

      test('should return true for enum declaration', () {
        // Arrange
        const symbol = CodeSymbol(
          name: 'MyEnum',
          kind: SymbolKind.enumDeclaration(),
          location: SymbolLocation(
            startLine: 0,
            startColumn: 0,
            endLine: 10,
            endColumn: 1,
            startOffset: 0,
            endOffset: 100,
          ),
        );

        // Act & Assert
        expect(symbol.isContainer, true);
      });

      test('should return false for function', () {
        // Arrange
        const symbol = CodeSymbol(
          name: 'myFunction',
          kind: SymbolKind.function(),
          location: SymbolLocation(
            startLine: 0,
            startColumn: 0,
            endLine: 5,
            endColumn: 1,
            startOffset: 0,
            endOffset: 50,
          ),
        );

        // Act & Assert
        expect(symbol.isContainer, false);
      });

      test('should return false for method', () {
        // Arrange
        const symbol = CodeSymbol(
          name: 'myMethod',
          kind: SymbolKind.method(),
          location: SymbolLocation(
            startLine: 0,
            startColumn: 0,
            endLine: 5,
            endColumn: 1,
            startOffset: 0,
            endOffset: 50,
          ),
        );

        // Act & Assert
        expect(symbol.isContainer, false);
      });

      test('should return false for variable', () {
        // Arrange
        const symbol = CodeSymbol(
          name: 'myVar',
          kind: SymbolKind.variable(),
          location: SymbolLocation(
            startLine: 0,
            startColumn: 0,
            endLine: 0,
            endColumn: 10,
            startOffset: 0,
            endOffset: 10,
          ),
        );

        // Act & Assert
        expect(symbol.isContainer, false);
      });
    });

    group('qualifiedName getter', () {
      test('should return name when no parent', () {
        // Arrange
        const symbol = CodeSymbol(
          name: 'MyClass',
          kind: SymbolKind.classDeclaration(),
          location: SymbolLocation(
            startLine: 0,
            startColumn: 0,
            endLine: 10,
            endColumn: 1,
            startOffset: 0,
            endOffset: 100,
          ),
        );

        // Act & Assert
        expect(symbol.qualifiedName, 'MyClass');
      });

      test('should return qualified name with parent', () {
        // Arrange
        const symbol = CodeSymbol(
          name: 'build',
          kind: SymbolKind.method(),
          location: SymbolLocation(
            startLine: 5,
            startColumn: 2,
            endLine: 8,
            endColumn: 3,
            startOffset: 50,
            endOffset: 80,
          ),
          parentName: 'MyWidget',
        );

        // Act & Assert
        expect(symbol.qualifiedName, 'MyWidget.build');
      });

      test('should handle nested qualified names', () {
        // Arrange
        const symbol = CodeSymbol(
          name: 'innerMethod',
          kind: SymbolKind.method(),
          location: SymbolLocation(
            startLine: 10,
            startColumn: 4,
            endLine: 12,
            endColumn: 5,
            startOffset: 100,
            endOffset: 120,
          ),
          parentName: 'OuterClass.InnerClass',
        );

        // Act & Assert
        expect(symbol.qualifiedName, 'OuterClass.InnerClass.innerMethod');
      });
    });

    group('summary getter', () {
      test('should return summary for class', () {
        // Arrange
        const symbol = CodeSymbol(
          name: 'MyClass',
          kind: SymbolKind.classDeclaration(),
          location: SymbolLocation(
            startLine: 0,
            startColumn: 0,
            endLine: 10,
            endColumn: 1,
            startOffset: 0,
            endOffset: 100,
          ),
        );

        // Act & Assert
        expect(symbol.summary, 'class MyClass');
      });

      test('should return summary for method with parent', () {
        // Arrange
        const symbol = CodeSymbol(
          name: 'build',
          kind: SymbolKind.method(),
          location: SymbolLocation(
            startLine: 5,
            startColumn: 2,
            endLine: 8,
            endColumn: 3,
            startOffset: 50,
            endOffset: 80,
          ),
          parentName: 'MyWidget',
        );

        // Act & Assert
        expect(symbol.summary, 'method MyWidget.build');
      });

      test('should return summary for function', () {
        // Arrange
        const symbol = CodeSymbol(
          name: 'main',
          kind: SymbolKind.function(),
          location: SymbolLocation(
            startLine: 0,
            startColumn: 0,
            endLine: 3,
            endColumn: 1,
            startOffset: 0,
            endOffset: 30,
          ),
        );

        // Act & Assert
        expect(symbol.summary, 'function main');
      });
    });

    group('addChild', () {
      test('should add child to symbol', () {
        // Arrange
        const parent = CodeSymbol(
          name: 'MyClass',
          kind: SymbolKind.classDeclaration(),
          location: SymbolLocation(
            startLine: 0,
            startColumn: 0,
            endLine: 20,
            endColumn: 1,
            startOffset: 0,
            endOffset: 200,
          ),
        );
        const child = CodeSymbol(
          name: 'build',
          kind: SymbolKind.method(),
          location: SymbolLocation(
            startLine: 10,
            startColumn: 2,
            endLine: 15,
            endColumn: 3,
            startOffset: 100,
            endOffset: 150,
          ),
        );

        // Act
        final result = parent.addChild(child);

        // Assert
        expect(result.children.length, 1);
        expect(result.children.first, child);
        expect(parent.children.isEmpty, true); // Original unchanged
      });

      test('should add multiple children', () {
        // Arrange
        const parent = CodeSymbol(
          name: 'MyClass',
          kind: SymbolKind.classDeclaration(),
          location: SymbolLocation(
            startLine: 0,
            startColumn: 0,
            endLine: 30,
            endColumn: 1,
            startOffset: 0,
            endOffset: 300,
          ),
        );
        const child1 = CodeSymbol(
          name: 'method1',
          kind: SymbolKind.method(),
          location: SymbolLocation(
            startLine: 10,
            startColumn: 2,
            endLine: 15,
            endColumn: 3,
            startOffset: 100,
            endOffset: 150,
          ),
        );
        const child2 = CodeSymbol(
          name: 'method2',
          kind: SymbolKind.method(),
          location: SymbolLocation(
            startLine: 20,
            startColumn: 2,
            endLine: 25,
            endColumn: 3,
            startOffset: 200,
            endOffset: 250,
          ),
        );

        // Act
        final result = parent.addChild(child1).addChild(child2);

        // Assert
        expect(result.children.length, 2);
        expect(result.children[0], child1);
        expect(result.children[1], child2);
      });
    });

    group('sortChildren', () {
      test('should sort children by line number', () {
        // Arrange
        const parent = CodeSymbol(
          name: 'MyClass',
          kind: SymbolKind.classDeclaration(),
          location: SymbolLocation(
            startLine: 0,
            startColumn: 0,
            endLine: 50,
            endColumn: 1,
            startOffset: 0,
            endOffset: 500,
          ),
          children: [
            CodeSymbol(
              name: 'method2',
              kind: SymbolKind.method(),
              location: SymbolLocation(
                startLine: 30,
                startColumn: 2,
                endLine: 35,
                endColumn: 3,
                startOffset: 300,
                endOffset: 350,
              ),
            ),
            CodeSymbol(
              name: 'method1',
              kind: SymbolKind.method(),
              location: SymbolLocation(
                startLine: 10,
                startColumn: 2,
                endLine: 15,
                endColumn: 3,
                startOffset: 100,
                endOffset: 150,
              ),
            ),
            CodeSymbol(
              name: 'method3',
              kind: SymbolKind.method(),
              location: SymbolLocation(
                startLine: 40,
                startColumn: 2,
                endLine: 45,
                endColumn: 3,
                startOffset: 400,
                endOffset: 450,
              ),
            ),
          ],
        );

        // Act
        final sorted = parent.sortChildren();

        // Assert
        expect(sorted.children[0].name, 'method1');
        expect(sorted.children[1].name, 'method2');
        expect(sorted.children[2].name, 'method3');
        expect(sorted.children[0].location.startLine, 10);
        expect(sorted.children[1].location.startLine, 30);
        expect(sorted.children[2].location.startLine, 40);
      });

      test('should return same order if already sorted', () {
        // Arrange
        const parent = CodeSymbol(
          name: 'MyClass',
          kind: SymbolKind.classDeclaration(),
          location: SymbolLocation(
            startLine: 0,
            startColumn: 0,
            endLine: 30,
            endColumn: 1,
            startOffset: 0,
            endOffset: 300,
          ),
          children: [
            CodeSymbol(
              name: 'method1',
              kind: SymbolKind.method(),
              location: SymbolLocation(
                startLine: 10,
                startColumn: 2,
                endLine: 15,
                endColumn: 3,
                startOffset: 100,
                endOffset: 150,
              ),
            ),
            CodeSymbol(
              name: 'method2',
              kind: SymbolKind.method(),
              location: SymbolLocation(
                startLine: 20,
                startColumn: 2,
                endLine: 25,
                endColumn: 3,
                startOffset: 200,
                endOffset: 250,
              ),
            ),
          ],
        );

        // Act
        final sorted = parent.sortChildren();

        // Assert
        expect(sorted.children[0].name, 'method1');
        expect(sorted.children[1].name, 'method2');
      });

      test('should not modify original', () {
        // Arrange
        const parent = CodeSymbol(
          name: 'MyClass',
          kind: SymbolKind.classDeclaration(),
          location: SymbolLocation(
            startLine: 0,
            startColumn: 0,
            endLine: 30,
            endColumn: 1,
            startOffset: 0,
            endOffset: 300,
          ),
          children: [
            CodeSymbol(
              name: 'method2',
              kind: SymbolKind.method(),
              location: SymbolLocation(
                startLine: 20,
                startColumn: 2,
                endLine: 25,
                endColumn: 3,
                startOffset: 200,
                endOffset: 250,
              ),
            ),
            CodeSymbol(
              name: 'method1',
              kind: SymbolKind.method(),
              location: SymbolLocation(
                startLine: 10,
                startColumn: 2,
                endLine: 15,
                endColumn: 3,
                startOffset: 100,
                endOffset: 150,
              ),
            ),
          ],
        );

        // Act
        final sorted = parent.sortChildren();

        // Assert
        expect(parent.children[0].name, 'method2'); // Original unchanged
        expect(sorted.children[0].name, 'method1'); // Sorted version
      });
    });

    group('getAllDescendants', () {
      test('should return empty list for symbol with no children', () {
        // Arrange
        const symbol = CodeSymbol(
          name: 'MyFunction',
          kind: SymbolKind.function(),
          location: SymbolLocation(
            startLine: 0,
            startColumn: 0,
            endLine: 5,
            endColumn: 1,
            startOffset: 0,
            endOffset: 50,
          ),
        );

        // Act
        final descendants = symbol.getAllDescendants();

        // Assert
        expect(descendants, isEmpty);
      });

      test('should return direct children', () {
        // Arrange
        const parent = CodeSymbol(
          name: 'MyClass',
          kind: SymbolKind.classDeclaration(),
          location: SymbolLocation(
            startLine: 0,
            startColumn: 0,
            endLine: 20,
            endColumn: 1,
            startOffset: 0,
            endOffset: 200,
          ),
          children: [
            CodeSymbol(
              name: 'method1',
              kind: SymbolKind.method(),
              location: SymbolLocation(
                startLine: 10,
                startColumn: 2,
                endLine: 15,
                endColumn: 3,
                startOffset: 100,
                endOffset: 150,
              ),
            ),
          ],
        );

        // Act
        final descendants = parent.getAllDescendants();

        // Assert
        expect(descendants.length, 1);
        expect(descendants[0].name, 'method1');
      });

      test('should return nested descendants recursively', () {
        // Arrange
        const grandchild = CodeSymbol(
          name: 'innerMethod',
          kind: SymbolKind.method(),
          location: SymbolLocation(
            startLine: 25,
            startColumn: 4,
            endLine: 28,
            endColumn: 5,
            startOffset: 250,
            endOffset: 280,
          ),
        );
        const child = CodeSymbol(
          name: 'InnerClass',
          kind: SymbolKind.classDeclaration(),
          location: SymbolLocation(
            startLine: 20,
            startColumn: 2,
            endLine: 30,
            endColumn: 3,
            startOffset: 200,
            endOffset: 300,
          ),
          children: [grandchild],
        );
        const parent = CodeSymbol(
          name: 'OuterClass',
          kind: SymbolKind.classDeclaration(),
          location: SymbolLocation(
            startLine: 0,
            startColumn: 0,
            endLine: 35,
            endColumn: 1,
            startOffset: 0,
            endOffset: 350,
          ),
          children: [child],
        );

        // Act
        final descendants = parent.getAllDescendants();

        // Assert
        expect(descendants.length, 2);
        expect(descendants[0].name, 'InnerClass');
        expect(descendants[1].name, 'innerMethod');
      });

      test('should return all descendants in depth-first order', () {
        // Arrange
        const grandchild1 = CodeSymbol(
          name: 'grandchild1',
          kind: SymbolKind.method(),
          location: SymbolLocation(
            startLine: 25,
            startColumn: 4,
            endLine: 28,
            endColumn: 5,
            startOffset: 250,
            endOffset: 280,
          ),
        );
        const child1 = CodeSymbol(
          name: 'child1',
          kind: SymbolKind.classDeclaration(),
          location: SymbolLocation(
            startLine: 20,
            startColumn: 2,
            endLine: 30,
            endColumn: 3,
            startOffset: 200,
            endOffset: 300,
          ),
          children: [grandchild1],
        );
        const child2 = CodeSymbol(
          name: 'child2',
          kind: SymbolKind.method(),
          location: SymbolLocation(
            startLine: 35,
            startColumn: 2,
            endLine: 40,
            endColumn: 3,
            startOffset: 350,
            endOffset: 400,
          ),
        );
        const parent = CodeSymbol(
          name: 'parent',
          kind: SymbolKind.classDeclaration(),
          location: SymbolLocation(
            startLine: 0,
            startColumn: 0,
            endLine: 45,
            endColumn: 1,
            startOffset: 0,
            endOffset: 450,
          ),
          children: [child1, child2],
        );

        // Act
        final descendants = parent.getAllDescendants();

        // Assert
        expect(descendants.length, 3);
        expect(descendants[0].name, 'child1');
        expect(descendants[1].name, 'grandchild1');
        expect(descendants[2].name, 'child2');
      });
    });

    group('findSymbolAtLine', () {
      test('should find symbol at line', () {
        // Arrange
        const symbol = CodeSymbol(
          name: 'MyClass',
          kind: SymbolKind.classDeclaration(),
          location: SymbolLocation(
            startLine: 10,
            startColumn: 0,
            endLine: 20,
            endColumn: 1,
            startOffset: 100,
            endOffset: 200,
          ),
        );

        // Act
        final found = symbol.findSymbolAtLine(15);

        // Assert
        expect(found, isNotNull);
        expect(found!.name, 'MyClass');
      });

      test('should return null for line outside range', () {
        // Arrange
        const symbol = CodeSymbol(
          name: 'MyClass',
          kind: SymbolKind.classDeclaration(),
          location: SymbolLocation(
            startLine: 10,
            startColumn: 0,
            endLine: 20,
            endColumn: 1,
            startOffset: 100,
            endOffset: 200,
          ),
        );

        // Act
        final found = symbol.findSymbolAtLine(25);

        // Assert
        expect(found, isNull);
      });

      test('should find child symbol when more specific', () {
        // Arrange
        const child = CodeSymbol(
          name: 'build',
          kind: SymbolKind.method(),
          location: SymbolLocation(
            startLine: 15,
            startColumn: 2,
            endLine: 18,
            endColumn: 3,
            startOffset: 150,
            endOffset: 180,
          ),
        );
        const parent = CodeSymbol(
          name: 'MyWidget',
          kind: SymbolKind.classDeclaration(),
          location: SymbolLocation(
            startLine: 10,
            startColumn: 0,
            endLine: 20,
            endColumn: 1,
            startOffset: 100,
            endOffset: 200,
          ),
          children: [child],
        );

        // Act
        final found = parent.findSymbolAtLine(16);

        // Assert
        expect(found, isNotNull);
        expect(found!.name, 'build'); // Child, not parent
      });

      test('should return parent when line not in any child', () {
        // Arrange
        const child = CodeSymbol(
          name: 'build',
          kind: SymbolKind.method(),
          location: SymbolLocation(
            startLine: 15,
            startColumn: 2,
            endLine: 18,
            endColumn: 3,
            startOffset: 150,
            endOffset: 180,
          ),
        );
        const parent = CodeSymbol(
          name: 'MyWidget',
          kind: SymbolKind.classDeclaration(),
          location: SymbolLocation(
            startLine: 10,
            startColumn: 0,
            endLine: 20,
            endColumn: 1,
            startOffset: 100,
            endOffset: 200,
          ),
          children: [child],
        );

        // Act
        final found = parent.findSymbolAtLine(12); // Before child

        // Assert
        expect(found, isNotNull);
        expect(found!.name, 'MyWidget'); // Parent
      });
    });

    group('equality', () {
      test('should be equal when all fields are the same', () {
        // Arrange
        const location = SymbolLocation(
          startLine: 10,
          startColumn: 0,
          endLine: 20,
          endColumn: 1,
          startOffset: 100,
          endOffset: 200,
        );
        const symbol1 = CodeSymbol(
          name: 'MyClass',
          kind: SymbolKind.classDeclaration(),
          location: location,
        );
        const symbol2 = CodeSymbol(
          name: 'MyClass',
          kind: SymbolKind.classDeclaration(),
          location: location,
        );

        // Act & Assert
        expect(symbol1, equals(symbol2));
        expect(symbol1.hashCode, equals(symbol2.hashCode));
      });

      test('should not be equal when names differ', () {
        // Arrange
        const location = SymbolLocation(
          startLine: 10,
          startColumn: 0,
          endLine: 20,
          endColumn: 1,
          startOffset: 100,
          endOffset: 200,
        );
        const symbol1 = CodeSymbol(
          name: 'MyClass1',
          kind: SymbolKind.classDeclaration(),
          location: location,
        );
        const symbol2 = CodeSymbol(
          name: 'MyClass2',
          kind: SymbolKind.classDeclaration(),
          location: location,
        );

        // Act & Assert
        expect(symbol1, isNot(equals(symbol2)));
      });

      test('should not be equal when kinds differ', () {
        // Arrange
        const location = SymbolLocation(
          startLine: 10,
          startColumn: 0,
          endLine: 20,
          endColumn: 1,
          startOffset: 100,
          endOffset: 200,
        );
        const symbol1 = CodeSymbol(
          name: 'MyClass',
          kind: SymbolKind.classDeclaration(),
          location: location,
        );
        const symbol2 = CodeSymbol(
          name: 'MyClass',
          kind: SymbolKind.mixin(),
          location: location,
        );

        // Act & Assert
        expect(symbol1, isNot(equals(symbol2)));
      });
    });

    group('copyWith', () {
      test('should copy with new name', () {
        // Arrange
        const original = CodeSymbol(
          name: 'MyClass',
          kind: SymbolKind.classDeclaration(),
          location: SymbolLocation(
            startLine: 10,
            startColumn: 0,
            endLine: 20,
            endColumn: 1,
            startOffset: 100,
            endOffset: 200,
          ),
        );

        // Act
        final copied = original.copyWith(name: 'YourClass');

        // Assert
        expect(copied.name, 'YourClass');
        expect(original.name, 'MyClass');
      });

      test('should copy with new children', () {
        // Arrange
        const original = CodeSymbol(
          name: 'MyClass',
          kind: SymbolKind.classDeclaration(),
          location: SymbolLocation(
            startLine: 10,
            startColumn: 0,
            endLine: 20,
            endColumn: 1,
            startOffset: 100,
            endOffset: 200,
          ),
        );
        const newChild = CodeSymbol(
          name: 'newMethod',
          kind: SymbolKind.method(),
          location: SymbolLocation(
            startLine: 15,
            startColumn: 2,
            endLine: 18,
            endColumn: 3,
            startOffset: 150,
            endOffset: 180,
          ),
        );

        // Act
        final copied = original.copyWith(children: [newChild]);

        // Assert
        expect(copied.children.length, 1);
        expect(copied.children.first.name, 'newMethod');
        expect(original.children.isEmpty, true);
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON', () {
        // Arrange
        const symbol = CodeSymbol(
          name: 'MyClass',
          kind: SymbolKind.classDeclaration(),
          location: SymbolLocation(
            startLine: 10,
            startColumn: 0,
            endLine: 20,
            endColumn: 1,
            startOffset: 100,
            endOffset: 200,
          ),
        );

        // Act
        final json = symbol.toJson();

        // Assert
        expect(json['name'], 'MyClass');
        expect(json['children'], isEmpty);
        expect(json['metadata'], isEmpty);
      });

      test('should deserialize from JSON', () {
        // Arrange
        final json = {
          'name': 'MyClass',
          'kind': {'runtimeType': 'classDeclaration'},
          'location': {
            'startLine': 10,
            'startColumn': 0,
            'endLine': 20,
            'endColumn': 1,
            'startOffset': 100,
            'endOffset': 200,
          },
          'children': <Map<String, dynamic>>[],
          'metadata': <String, dynamic>{},
        };

        // Act
        final symbol = CodeSymbol.fromJson(json);

        // Assert
        expect(symbol.name, 'MyClass');
        expect(symbol.location.startLine, 10);
      });
    });
  });

  group('SymbolTree', () {
    group('constructor', () {
      test('should create instance with required fields', () {
        // Arrange
        final timestamp = DateTime(2024, 1, 1);

        // Act
        final tree = SymbolTree(
          filePath: '/path/to/file.dart',
          language: 'dart',
          timestamp: timestamp,
        );

        // Assert
        expect(tree.filePath, '/path/to/file.dart');
        expect(tree.symbols, isEmpty);
        expect(tree.language, 'dart');
        expect(tree.timestamp, timestamp);
        expect(tree.parseDurationMs, isNull);
      });

      test('should create instance with symbols', () {
        // Arrange
        const symbols = [
          CodeSymbol(
            name: 'MyClass',
            kind: SymbolKind.classDeclaration(),
            location: SymbolLocation(
              startLine: 0,
              startColumn: 0,
              endLine: 10,
              endColumn: 1,
              startOffset: 0,
              endOffset: 100,
            ),
          ),
        ];
        final timestamp = DateTime(2024, 1, 1);

        // Act
        final tree = SymbolTree(
          filePath: '/path/to/file.dart',
          symbols: symbols,
          language: 'dart',
          timestamp: timestamp,
          parseDurationMs: 150,
        );

        // Assert
        expect(tree.symbols.length, 1);
        expect(tree.symbols.first.name, 'MyClass');
        expect(tree.parseDurationMs, 150);
      });
    });

    group('getAllSymbols', () {
      test('should return empty list for tree with no symbols', () {
        // Arrange
        final tree = SymbolTree(
          filePath: '/path/to/file.dart',
          language: 'dart',
          timestamp: DateTime.now(),
        );

        // Act
        final allSymbols = tree.getAllSymbols();

        // Assert
        expect(allSymbols, isEmpty);
      });

      test('should return all root symbols', () {
        // Arrange
        const symbols = [
          CodeSymbol(
            name: 'Class1',
            kind: SymbolKind.classDeclaration(),
            location: SymbolLocation(
              startLine: 0,
              startColumn: 0,
              endLine: 10,
              endColumn: 1,
              startOffset: 0,
              endOffset: 100,
            ),
          ),
          CodeSymbol(
            name: 'Class2',
            kind: SymbolKind.classDeclaration(),
            location: SymbolLocation(
              startLine: 15,
              startColumn: 0,
              endLine: 25,
              endColumn: 1,
              startOffset: 150,
              endOffset: 250,
            ),
          ),
        ];
        final tree = SymbolTree(
          filePath: '/path/to/file.dart',
          symbols: symbols,
          language: 'dart',
          timestamp: DateTime.now(),
        );

        // Act
        final allSymbols = tree.getAllSymbols();

        // Assert
        expect(allSymbols.length, 2);
      });

      test('should return all symbols including nested ones', () {
        // Arrange
        const child = CodeSymbol(
          name: 'method',
          kind: SymbolKind.method(),
          location: SymbolLocation(
            startLine: 5,
            startColumn: 2,
            endLine: 8,
            endColumn: 3,
            startOffset: 50,
            endOffset: 80,
          ),
        );
        const parent = CodeSymbol(
          name: 'MyClass',
          kind: SymbolKind.classDeclaration(),
          location: SymbolLocation(
            startLine: 0,
            startColumn: 0,
            endLine: 10,
            endColumn: 1,
            startOffset: 0,
            endOffset: 100,
          ),
          children: [child],
        );
        final tree = SymbolTree(
          filePath: '/path/to/file.dart',
          symbols: const [parent],
          language: 'dart',
          timestamp: DateTime.now(),
        );

        // Act
        final allSymbols = tree.getAllSymbols();

        // Assert
        expect(allSymbols.length, 2);
        expect(allSymbols[0].name, 'MyClass');
        expect(allSymbols[1].name, 'method');
      });
    });

    group('findSymbolByName', () {
      test('should find symbol by name', () {
        // Arrange
        const symbols = [
          CodeSymbol(
            name: 'MyClass',
            kind: SymbolKind.classDeclaration(),
            location: SymbolLocation(
              startLine: 0,
              startColumn: 0,
              endLine: 10,
              endColumn: 1,
              startOffset: 0,
              endOffset: 100,
            ),
          ),
        ];
        final tree = SymbolTree(
          filePath: '/path/to/file.dart',
          symbols: symbols,
          language: 'dart',
          timestamp: DateTime.now(),
        );

        // Act
        final found = tree.findSymbolByName('MyClass');

        // Assert
        expect(found, isNotNull);
        expect(found!.name, 'MyClass');
      });

      test('should find nested symbol by name', () {
        // Arrange
        const child = CodeSymbol(
          name: 'build',
          kind: SymbolKind.method(),
          location: SymbolLocation(
            startLine: 5,
            startColumn: 2,
            endLine: 8,
            endColumn: 3,
            startOffset: 50,
            endOffset: 80,
          ),
          parentName: 'MyWidget',
        );
        const parent = CodeSymbol(
          name: 'MyWidget',
          kind: SymbolKind.classDeclaration(),
          location: SymbolLocation(
            startLine: 0,
            startColumn: 0,
            endLine: 10,
            endColumn: 1,
            startOffset: 0,
            endOffset: 100,
          ),
          children: [child],
        );
        final tree = SymbolTree(
          filePath: '/path/to/file.dart',
          symbols: const [parent],
          language: 'dart',
          timestamp: DateTime.now(),
        );

        // Act
        final found = tree.findSymbolByName('build');

        // Assert
        expect(found, isNotNull);
        expect(found!.name, 'build');
      });

      test('should find symbol by qualified name', () {
        // Arrange
        const child = CodeSymbol(
          name: 'build',
          kind: SymbolKind.method(),
          location: SymbolLocation(
            startLine: 5,
            startColumn: 2,
            endLine: 8,
            endColumn: 3,
            startOffset: 50,
            endOffset: 80,
          ),
          parentName: 'MyWidget',
        );
        const parent = CodeSymbol(
          name: 'MyWidget',
          kind: SymbolKind.classDeclaration(),
          location: SymbolLocation(
            startLine: 0,
            startColumn: 0,
            endLine: 10,
            endColumn: 1,
            startOffset: 0,
            endOffset: 100,
          ),
          children: [child],
        );
        final tree = SymbolTree(
          filePath: '/path/to/file.dart',
          symbols: const [parent],
          language: 'dart',
          timestamp: DateTime.now(),
        );

        // Act
        final found = tree.findSymbolByName('MyWidget.build');

        // Assert
        expect(found, isNotNull);
        expect(found!.qualifiedName, 'MyWidget.build');
      });

      test('should return null for non-existent symbol', () {
        // Arrange
        final tree = SymbolTree(
          filePath: '/path/to/file.dart',
          language: 'dart',
          timestamp: DateTime.now(),
        );

        // Act
        final found = tree.findSymbolByName('NonExistent');

        // Assert
        expect(found, isNull);
      });
    });

    group('findSymbolAtLine', () {
      test('should find symbol at line', () {
        // Arrange
        const symbols = [
          CodeSymbol(
            name: 'MyClass',
            kind: SymbolKind.classDeclaration(),
            location: SymbolLocation(
              startLine: 10,
              startColumn: 0,
              endLine: 20,
              endColumn: 1,
              startOffset: 100,
              endOffset: 200,
            ),
          ),
        ];
        final tree = SymbolTree(
          filePath: '/path/to/file.dart',
          symbols: symbols,
          language: 'dart',
          timestamp: DateTime.now(),
        );

        // Act
        final found = tree.findSymbolAtLine(15);

        // Assert
        expect(found, isNotNull);
        expect(found!.name, 'MyClass');
      });

      test('should return null for line with no symbol', () {
        // Arrange
        const symbols = [
          CodeSymbol(
            name: 'MyClass',
            kind: SymbolKind.classDeclaration(),
            location: SymbolLocation(
              startLine: 10,
              startColumn: 0,
              endLine: 20,
              endColumn: 1,
              startOffset: 100,
              endOffset: 200,
            ),
          ),
        ];
        final tree = SymbolTree(
          filePath: '/path/to/file.dart',
          symbols: symbols,
          language: 'dart',
          timestamp: DateTime.now(),
        );

        // Act
        final found = tree.findSymbolAtLine(5);

        // Assert
        expect(found, isNull);
      });
    });

    group('statistics getter', () {
      test('should return empty stats for empty tree', () {
        // Arrange
        final tree = SymbolTree(
          filePath: '/path/to/file.dart',
          language: 'dart',
          timestamp: DateTime.now(),
        );

        // Act
        final stats = tree.statistics;

        // Assert
        expect(stats, isEmpty);
      });

      test('should count symbols by kind', () {
        // Arrange
        const symbols = [
          CodeSymbol(
            name: 'Class1',
            kind: SymbolKind.classDeclaration(),
            location: SymbolLocation(
              startLine: 0,
              startColumn: 0,
              endLine: 10,
              endColumn: 1,
              startOffset: 0,
              endOffset: 100,
            ),
            children: [
              CodeSymbol(
                name: 'method1',
                kind: SymbolKind.method(),
                location: SymbolLocation(
                  startLine: 5,
                  startColumn: 2,
                  endLine: 8,
                  endColumn: 3,
                  startOffset: 50,
                  endOffset: 80,
                ),
              ),
            ],
          ),
          CodeSymbol(
            name: 'function1',
            kind: SymbolKind.function(),
            location: SymbolLocation(
              startLine: 15,
              startColumn: 0,
              endLine: 20,
              endColumn: 1,
              startOffset: 150,
              endOffset: 200,
            ),
          ),
        ];
        final tree = SymbolTree(
          filePath: '/path/to/file.dart',
          symbols: symbols,
          language: 'dart',
          timestamp: DateTime.now(),
        );

        // Act
        final stats = tree.statistics;

        // Assert
        expect(stats['Class'], 1);
        expect(stats['Method'], 1);
        expect(stats['Function'], 1);
      });
    });

    group('totalCount getter', () {
      test('should return 0 for empty tree', () {
        // Arrange
        final tree = SymbolTree(
          filePath: '/path/to/file.dart',
          language: 'dart',
          timestamp: DateTime.now(),
        );

        // Act
        final count = tree.totalCount;

        // Assert
        expect(count, 0);
      });

      test('should count all symbols including nested', () {
        // Arrange
        const symbols = [
          CodeSymbol(
            name: 'MyClass',
            kind: SymbolKind.classDeclaration(),
            location: SymbolLocation(
              startLine: 0,
              startColumn: 0,
              endLine: 10,
              endColumn: 1,
              startOffset: 0,
              endOffset: 100,
            ),
            children: [
              CodeSymbol(
                name: 'method1',
                kind: SymbolKind.method(),
                location: SymbolLocation(
                  startLine: 5,
                  startColumn: 2,
                  endLine: 8,
                  endColumn: 3,
                  startOffset: 50,
                  endOffset: 80,
                ),
              ),
            ],
          ),
        ];
        final tree = SymbolTree(
          filePath: '/path/to/file.dart',
          symbols: symbols,
          language: 'dart',
          timestamp: DateTime.now(),
        );

        // Act
        final count = tree.totalCount;

        // Assert
        expect(count, 2);
      });
    });
  });
}
