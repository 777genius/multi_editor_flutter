import 'package:flutter_test/flutter_test.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';

void main() {
  group('TypeHierarchyItem', () {
    group('Construction', () {
      test('should create class type hierarchy item', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 5, column: 0),
          end: const CursorPosition(line: 20, column: 1),
        );
        final selectionRange = TextSelection(
          start: const CursorPosition(line: 5, column: 6),
          end: const CursorPosition(line: 5, column: 15),
        );

        // Act
        final item = TypeHierarchyItem(
          name: 'MyWidget',
          kind: SymbolKind.class_,
          uri: DocumentUri.fromFilePath('/lib/widgets/my_widget.dart'),
          range: range,
          selectionRange: selectionRange,
        );

        // Assert
        expect(item.name, equals('MyWidget'));
        expect(item.kind, equals(SymbolKind.class_));
        expect(item.detail, isNull);
      });

      test('should create with detail', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 10, column: 0),
          end: const CursorPosition(line: 25, column: 1),
        );
        final selectionRange = TextSelection(
          start: const CursorPosition(line: 10, column: 6),
          end: const CursorPosition(line: 10, column: 20),
        );

        // Act
        final item = TypeHierarchyItem(
          name: 'StatefulWidget',
          kind: SymbolKind.class_,
          detail: 'abstract class StatefulWidget extends Widget',
          uri: DocumentUri.fromFilePath('/flutter/widgets.dart'),
          range: range,
          selectionRange: selectionRange,
        );

        // Assert
        expect(item.detail, contains('abstract'));
        expect(item.detail, contains('extends Widget'));
      });
    });

    group('Symbol Kinds', () {
      test('should support class kind', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 10, column: 0),
        );

        // Act
        final item = TypeHierarchyItem(
          name: 'MyClass',
          kind: SymbolKind.class_,
          uri: DocumentUri.fromFilePath('/test.dart'),
          range: range,
          selectionRange: range,
        );

        // Assert
        expect(item.kind, equals(SymbolKind.class_));
      });

      test('should support interface kind', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 5, column: 0),
          end: const CursorPosition(line: 15, column: 0),
        );

        // Act
        final item = TypeHierarchyItem(
          name: 'IComparable',
          kind: SymbolKind.interface,
          uri: DocumentUri.fromFilePath('/interfaces.dart'),
          range: range,
          selectionRange: range,
        );

        // Assert
        expect(item.kind, equals(SymbolKind.interface));
      });

      test('should support struct kind', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 3, column: 0),
          end: const CursorPosition(line: 8, column: 0),
        );

        // Act
        final item = TypeHierarchyItem(
          name: 'Point',
          kind: SymbolKind.struct,
          uri: DocumentUri.fromFilePath('/geometry.rs'),
          range: range,
          selectionRange: range,
        );

        // Assert
        expect(item.kind, equals(SymbolKind.struct));
      });

      test('should support enum kind', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 5, column: 0),
        );

        // Act
        final item = TypeHierarchyItem(
          name: 'Color',
          kind: SymbolKind.enum_,
          uri: DocumentUri.fromFilePath('/colors.dart'),
          range: range,
          selectionRange: range,
        );

        // Assert
        expect(item.kind, equals(SymbolKind.enum_));
      });
    });

    group('Use Cases', () {
      test('should represent base class', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 20, column: 0),
        );

        // Act
        final item = TypeHierarchyItem(
          name: 'Widget',
          kind: SymbolKind.class_,
          detail: 'abstract class Widget',
          uri: DocumentUri.fromFilePath('/flutter/widgets/framework.dart'),
          range: range,
          selectionRange: range,
        );

        // Assert
        expect(item.name, equals('Widget'));
        expect(item.detail, contains('abstract'));
      });

      test('should represent derived class', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 50, column: 0),
          end: const CursorPosition(line: 100, column: 0),
        );

        // Act
        final item = TypeHierarchyItem(
          name: 'StatefulWidget',
          kind: SymbolKind.class_,
          detail: 'class StatefulWidget extends Widget',
          uri: DocumentUri.fromFilePath('/flutter/widgets/framework.dart'),
          range: range,
          selectionRange: range,
        );

        // Assert
        expect(item.detail, contains('extends Widget'));
      });

      test('should represent interface implementation', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 10, column: 0),
          end: const CursorPosition(line: 30, column: 0),
        );

        // Act
        final item = TypeHierarchyItem(
          name: 'MyComparable',
          kind: SymbolKind.class_,
          detail: 'class MyComparable implements Comparable<MyComparable>',
          uri: DocumentUri.fromFilePath('/my_class.dart'),
          range: range,
          selectionRange: range,
        );

        // Assert
        expect(item.detail, contains('implements Comparable'));
      });
    });

    group('Equality', () {
      test('should be equal with same values', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 10, column: 0),
        );
        final item1 = TypeHierarchyItem(
          name: 'TestClass',
          kind: SymbolKind.class_,
          uri: DocumentUri.fromFilePath('/test.dart'),
          range: range,
          selectionRange: range,
        );
        final item2 = TypeHierarchyItem(
          name: 'TestClass',
          kind: SymbolKind.class_,
          uri: DocumentUri.fromFilePath('/test.dart'),
          range: range,
          selectionRange: range,
        );

        // Assert
        expect(item1, equals(item2));
      });

      test('should not be equal with different names', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 10, column: 0),
        );
        final item1 = TypeHierarchyItem(
          name: 'ClassA',
          kind: SymbolKind.class_,
          uri: DocumentUri.fromFilePath('/test.dart'),
          range: range,
          selectionRange: range,
        );
        final item2 = TypeHierarchyItem(
          name: 'ClassB',
          kind: SymbolKind.class_,
          uri: DocumentUri.fromFilePath('/test.dart'),
          range: range,
          selectionRange: range,
        );

        // Assert
        expect(item1, isNot(equals(item2)));
      });

      test('should not be equal with different kinds', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 10, column: 0),
        );
        final item1 = TypeHierarchyItem(
          name: 'Test',
          kind: SymbolKind.class_,
          uri: DocumentUri.fromFilePath('/test.dart'),
          range: range,
          selectionRange: range,
        );
        final item2 = TypeHierarchyItem(
          name: 'Test',
          kind: SymbolKind.interface,
          uri: DocumentUri.fromFilePath('/test.dart'),
          range: range,
          selectionRange: range,
        );

        // Assert
        expect(item1, isNot(equals(item2)));
      });
    });
  });

  group('TypeHierarchyResult', () {
    group('Construction', () {
      test('should create with item only', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 10, column: 0),
        );
        final item = TypeHierarchyItem(
          name: 'MyClass',
          kind: SymbolKind.class_,
          uri: DocumentUri.fromFilePath('/test.dart'),
          range: range,
          selectionRange: range,
        );

        // Act
        final result = TypeHierarchyResult(item: item);

        // Assert
        expect(result.item.name, equals('MyClass'));
        expect(result.supertypes, isNull);
        expect(result.subtypes, isNull);
      });

      test('should create with supertypes', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 10, column: 0),
          end: const CursorPosition(line: 20, column: 0),
        );
        final item = TypeHierarchyItem(
          name: 'DerivedClass',
          kind: SymbolKind.class_,
          uri: DocumentUri.fromFilePath('/derived.dart'),
          range: range,
          selectionRange: range,
        );
        final baseClass = TypeHierarchyItem(
          name: 'BaseClass',
          kind: SymbolKind.class_,
          uri: DocumentUri.fromFilePath('/base.dart'),
          range: range,
          selectionRange: range,
        );

        // Act
        final result = TypeHierarchyResult(
          item: item,
          supertypes: [baseClass],
        );

        // Assert
        expect(result.supertypes, isNotNull);
        expect(result.supertypes!.length, equals(1));
        expect(result.supertypes!.first.name, equals('BaseClass'));
      });

      test('should create with subtypes', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 10, column: 0),
        );
        final item = TypeHierarchyItem(
          name: 'BaseClass',
          kind: SymbolKind.class_,
          uri: DocumentUri.fromFilePath('/base.dart'),
          range: range,
          selectionRange: range,
        );
        final derived1 = TypeHierarchyItem(
          name: 'DerivedClass1',
          kind: SymbolKind.class_,
          uri: DocumentUri.fromFilePath('/derived1.dart'),
          range: range,
          selectionRange: range,
        );
        final derived2 = TypeHierarchyItem(
          name: 'DerivedClass2',
          kind: SymbolKind.class_,
          uri: DocumentUri.fromFilePath('/derived2.dart'),
          range: range,
          selectionRange: range,
        );

        // Act
        final result = TypeHierarchyResult(
          item: item,
          subtypes: [derived1, derived2],
        );

        // Assert
        expect(result.subtypes, isNotNull);
        expect(result.subtypes!.length, equals(2));
      });

      test('should create with both supertypes and subtypes', () {
        // Arrange - Middle class in hierarchy
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 10, column: 0),
        );
        final item = TypeHierarchyItem(
          name: 'MiddleClass',
          kind: SymbolKind.class_,
          uri: DocumentUri.fromFilePath('/middle.dart'),
          range: range,
          selectionRange: range,
        );
        final supertype = TypeHierarchyItem(
          name: 'BaseClass',
          kind: SymbolKind.class_,
          uri: DocumentUri.fromFilePath('/base.dart'),
          range: range,
          selectionRange: range,
        );
        final subtype = TypeHierarchyItem(
          name: 'DerivedClass',
          kind: SymbolKind.class_,
          uri: DocumentUri.fromFilePath('/derived.dart'),
          range: range,
          selectionRange: range,
        );

        // Act
        final result = TypeHierarchyResult(
          item: item,
          supertypes: [supertype],
          subtypes: [subtype],
        );

        // Assert
        expect(result.supertypes, isNotNull);
        expect(result.subtypes, isNotNull);
      });
    });

    group('Inheritance Scenarios', () {
      test('should represent single inheritance', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 10, column: 0),
        );
        final derived = TypeHierarchyItem(
          name: 'MyWidget',
          kind: SymbolKind.class_,
          uri: DocumentUri.fromFilePath('/my_widget.dart'),
          range: range,
          selectionRange: range,
        );
        final base = TypeHierarchyItem(
          name: 'StatelessWidget',
          kind: SymbolKind.class_,
          uri: DocumentUri.fromFilePath('/flutter/widgets.dart'),
          range: range,
          selectionRange: range,
        );

        // Act
        final result = TypeHierarchyResult(
          item: derived,
          supertypes: [base],
        );

        // Assert
        expect(result.supertypes!.length, equals(1));
      });

      test('should represent multiple inheritance chain', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 10, column: 0),
        );
        final derived = TypeHierarchyItem(
          name: 'MyWidget',
          kind: SymbolKind.class_,
          uri: DocumentUri.fromFilePath('/test.dart'),
          range: range,
          selectionRange: range,
        );
        final parent = TypeHierarchyItem(
          name: 'StatelessWidget',
          kind: SymbolKind.class_,
          uri: DocumentUri.fromFilePath('/flutter.dart'),
          range: range,
          selectionRange: range,
        );
        final grandparent = TypeHierarchyItem(
          name: 'Widget',
          kind: SymbolKind.class_,
          uri: DocumentUri.fromFilePath('/flutter.dart'),
          range: range,
          selectionRange: range,
        );

        // Act
        final result = TypeHierarchyResult(
          item: derived,
          supertypes: [parent, grandparent],
        );

        // Assert
        expect(result.supertypes!.length, equals(2));
        expect(result.supertypes!.map((t) => t.name), containsAll(['StatelessWidget', 'Widget']));
      });

      test('should represent interface implementations', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 10, column: 0),
        );
        final implementation = TypeHierarchyItem(
          name: 'MyComparable',
          kind: SymbolKind.class_,
          uri: DocumentUri.fromFilePath('/test.dart'),
          range: range,
          selectionRange: range,
        );
        final interface1 = TypeHierarchyItem(
          name: 'Comparable',
          kind: SymbolKind.interface,
          uri: DocumentUri.fromFilePath('/core.dart'),
          range: range,
          selectionRange: range,
        );
        final interface2 = TypeHierarchyItem(
          name: 'Serializable',
          kind: SymbolKind.interface,
          uri: DocumentUri.fromFilePath('/core.dart'),
          range: range,
          selectionRange: range,
        );

        // Act
        final result = TypeHierarchyResult(
          item: implementation,
          supertypes: [interface1, interface2],
        );

        // Assert
        expect(result.supertypes!.length, equals(2));
      });

      test('should represent multiple subtypes', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 10, column: 0),
        );
        final base = TypeHierarchyItem(
          name: 'Widget',
          kind: SymbolKind.class_,
          uri: DocumentUri.fromFilePath('/flutter/widgets.dart'),
          range: range,
          selectionRange: range,
        );
        final subtypes = [
          'StatelessWidget',
          'StatefulWidget',
          'ProxyWidget',
          'RenderObjectWidget',
        ].map((name) => TypeHierarchyItem(
          name: name,
          kind: SymbolKind.class_,
          uri: DocumentUri.fromFilePath('/flutter/widgets.dart'),
          range: range,
          selectionRange: range,
        )).toList();

        // Act
        final result = TypeHierarchyResult(
          item: base,
          subtypes: subtypes,
        );

        // Assert
        expect(result.subtypes!.length, equals(4));
      });
    });

    group('Empty Hierarchies', () {
      test('should support root class with no supertypes', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 10, column: 0),
        );
        final item = TypeHierarchyItem(
          name: 'Object',
          kind: SymbolKind.class_,
          uri: DocumentUri.fromFilePath('/dart/core.dart'),
          range: range,
          selectionRange: range,
        );

        // Act
        final result = TypeHierarchyResult(item: item);

        // Assert
        expect(result.supertypes, isNull);
      });

      test('should support leaf class with no subtypes', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 10, column: 0),
        );
        final item = TypeHierarchyItem(
          name: 'FinalClass',
          kind: SymbolKind.class_,
          detail: 'final class FinalClass',
          uri: DocumentUri.fromFilePath('/test.dart'),
          range: range,
          selectionRange: range,
        );

        // Act
        final result = TypeHierarchyResult(item: item);

        // Assert
        expect(result.subtypes, isNull);
      });
    });
  });
}
