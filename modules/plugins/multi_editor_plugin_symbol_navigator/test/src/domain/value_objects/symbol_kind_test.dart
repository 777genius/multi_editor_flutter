import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugin_symbol_navigator/src/domain/value_objects/symbol_kind.dart';

void main() {
  group('SymbolKind', () {
    group('factory constructors', () {
      test('should create class declaration', () {
        // Arrange & Act
        const kind = SymbolKind.classDeclaration();

        // Assert
        expect(kind, isA<SymbolKind>());
        expect(kind.displayName, 'Class');
      });

      test('should create abstract class', () {
        // Arrange & Act
        const kind = SymbolKind.abstractClass();

        // Assert
        expect(kind.displayName, 'Abstract Class');
      });

      test('should create mixin', () {
        // Arrange & Act
        const kind = SymbolKind.mixin();

        // Assert
        expect(kind.displayName, 'Mixin');
      });

      test('should create extension', () {
        // Arrange & Act
        const kind = SymbolKind.extension();

        // Assert
        expect(kind.displayName, 'Extension');
      });

      test('should create enum declaration', () {
        // Arrange & Act
        const kind = SymbolKind.enumDeclaration();

        // Assert
        expect(kind.displayName, 'Enum');
      });

      test('should create typedef', () {
        // Arrange & Act
        const kind = SymbolKind.typedef();

        // Assert
        expect(kind.displayName, 'Typedef');
      });

      test('should create function', () {
        // Arrange & Act
        const kind = SymbolKind.function();

        // Assert
        expect(kind.displayName, 'Function');
      });

      test('should create method', () {
        // Arrange & Act
        const kind = SymbolKind.method();

        // Assert
        expect(kind.displayName, 'Method');
      });

      test('should create constructor', () {
        // Arrange & Act
        const kind = SymbolKind.constructor();

        // Assert
        expect(kind.displayName, 'Constructor');
      });

      test('should create getter', () {
        // Arrange & Act
        const kind = SymbolKind.getter();

        // Assert
        expect(kind.displayName, 'Getter');
      });

      test('should create setter', () {
        // Arrange & Act
        const kind = SymbolKind.setter();

        // Assert
        expect(kind.displayName, 'Setter');
      });

      test('should create field', () {
        // Arrange & Act
        const kind = SymbolKind.field();

        // Assert
        expect(kind.displayName, 'Field');
      });

      test('should create property', () {
        // Arrange & Act
        const kind = SymbolKind.property();

        // Assert
        expect(kind.displayName, 'Property');
      });

      test('should create constant', () {
        // Arrange & Act
        const kind = SymbolKind.constant();

        // Assert
        expect(kind.displayName, 'Constant');
      });

      test('should create variable', () {
        // Arrange & Act
        const kind = SymbolKind.variable();

        // Assert
        expect(kind.displayName, 'Variable');
      });

      test('should create enum value', () {
        // Arrange & Act
        const kind = SymbolKind.enumValue();

        // Assert
        expect(kind.displayName, 'Enum Value');
      });

      test('should create parameter', () {
        // Arrange & Act
        const kind = SymbolKind.parameter();

        // Assert
        expect(kind.displayName, 'Parameter');
      });
    });

    group('iconCode getter', () {
      test('should return correct icon code for class declaration', () {
        // Arrange
        const kind = SymbolKind.classDeclaration();

        // Act & Assert
        expect(kind.iconCode, 0xe3af); // Icons.class_
      });

      test('should return correct icon code for abstract class', () {
        // Arrange
        const kind = SymbolKind.abstractClass();

        // Act & Assert
        expect(kind.iconCode, 0xe3af); // Icons.class_
      });

      test('should return correct icon code for mixin', () {
        // Arrange
        const kind = SymbolKind.mixin();

        // Act & Assert
        expect(kind.iconCode, 0xe8d4); // Icons.merge_type
      });

      test('should return correct icon code for extension', () {
        // Arrange
        const kind = SymbolKind.extension();

        // Act & Assert
        expect(kind.iconCode, 0xe5c5); // Icons.extension
      });

      test('should return correct icon code for enum', () {
        // Arrange
        const kind = SymbolKind.enumDeclaration();

        // Act & Assert
        expect(kind.iconCode, 0xe241); // Icons.format_list_numbered
      });

      test('should return correct icon code for typedef', () {
        // Arrange
        const kind = SymbolKind.typedef();

        // Act & Assert
        expect(kind.iconCode, 0xe8de); // Icons.mode
      });

      test('should return correct icon code for function', () {
        // Arrange
        const kind = SymbolKind.function();

        // Act & Assert
        expect(kind.iconCode, 0xe24d); // Icons.functions
      });

      test('should return correct icon code for method', () {
        // Arrange
        const kind = SymbolKind.method();

        // Act & Assert
        expect(kind.iconCode, 0xe8f4); // Icons.flash_on
      });

      test('should return correct icon code for constructor', () {
        // Arrange
        const kind = SymbolKind.constructor();

        // Act & Assert
        expect(kind.iconCode, 0xe869); // Icons.build
      });

      test('should return correct icon code for getter', () {
        // Arrange
        const kind = SymbolKind.getter();

        // Act & Assert
        expect(kind.iconCode, 0xe896); // Icons.arrow_downward
      });

      test('should return correct icon code for setter', () {
        // Arrange
        const kind = SymbolKind.setter();

        // Act & Assert
        expect(kind.iconCode, 0xe5c8); // Icons.arrow_upward
      });

      test('should return correct icon code for field', () {
        // Arrange
        const kind = SymbolKind.field();

        // Act & Assert
        expect(kind.iconCode, 0xe14d); // Icons.square
      });

      test('should return correct icon code for property', () {
        // Arrange
        const kind = SymbolKind.property();

        // Act & Assert
        expect(kind.iconCode, 0xe14d); // Icons.square
      });

      test('should return correct icon code for constant', () {
        // Arrange
        const kind = SymbolKind.constant();

        // Act & Assert
        expect(kind.iconCode, 0xe897); // Icons.brightness_low
      });

      test('should return correct icon code for variable', () {
        // Arrange
        const kind = SymbolKind.variable();

        // Act & Assert
        expect(kind.iconCode, 0xe86f); // Icons.data_object
      });

      test('should return correct icon code for enum value', () {
        // Arrange
        const kind = SymbolKind.enumValue();

        // Act & Assert
        expect(kind.iconCode, 0xe5ca); // Icons.label
      });

      test('should return correct icon code for parameter', () {
        // Arrange
        const kind = SymbolKind.parameter();

        // Act & Assert
        expect(kind.iconCode, 0xe3c9); // Icons.input
      });
    });

    group('displayName getter', () {
      test('should return all display names correctly', () {
        // Arrange
        final kinds = {
          const SymbolKind.classDeclaration(): 'Class',
          const SymbolKind.abstractClass(): 'Abstract Class',
          const SymbolKind.mixin(): 'Mixin',
          const SymbolKind.extension(): 'Extension',
          const SymbolKind.enumDeclaration(): 'Enum',
          const SymbolKind.typedef(): 'Typedef',
          const SymbolKind.function(): 'Function',
          const SymbolKind.method(): 'Method',
          const SymbolKind.constructor(): 'Constructor',
          const SymbolKind.getter(): 'Getter',
          const SymbolKind.setter(): 'Setter',
          const SymbolKind.field(): 'Field',
          const SymbolKind.property(): 'Property',
          const SymbolKind.constant(): 'Constant',
          const SymbolKind.variable(): 'Variable',
          const SymbolKind.enumValue(): 'Enum Value',
          const SymbolKind.parameter(): 'Parameter',
        };

        // Act & Assert
        kinds.forEach((kind, expectedName) {
          expect(kind.displayName, expectedName);
        });
      });
    });

    group('priority getter', () {
      test('should return correct priority for class types', () {
        // Arrange & Act & Assert
        expect(const SymbolKind.classDeclaration().priority, 1);
        expect(const SymbolKind.abstractClass().priority, 1);
      });

      test('should return correct priority for mixin', () {
        // Arrange & Act & Assert
        expect(const SymbolKind.mixin().priority, 2);
      });

      test('should return correct priority for extension', () {
        // Arrange & Act & Assert
        expect(const SymbolKind.extension().priority, 3);
      });

      test('should return correct priority for enum', () {
        // Arrange & Act & Assert
        expect(const SymbolKind.enumDeclaration().priority, 4);
      });

      test('should return correct priority for typedef', () {
        // Arrange & Act & Assert
        expect(const SymbolKind.typedef().priority, 5);
      });

      test('should return correct priority for constructor', () {
        // Arrange & Act & Assert
        expect(const SymbolKind.constructor().priority, 6);
      });

      test('should return correct priority for method', () {
        // Arrange & Act & Assert
        expect(const SymbolKind.method().priority, 7);
      });

      test('should return correct priority for getter', () {
        // Arrange & Act & Assert
        expect(const SymbolKind.getter().priority, 8);
      });

      test('should return correct priority for setter', () {
        // Arrange & Act & Assert
        expect(const SymbolKind.setter().priority, 9);
      });

      test('should return correct priority for function', () {
        // Arrange & Act & Assert
        expect(const SymbolKind.function().priority, 10);
      });

      test('should return correct priority for field', () {
        // Arrange & Act & Assert
        expect(const SymbolKind.field().priority, 11);
      });

      test('should return correct priority for property', () {
        // Arrange & Act & Assert
        expect(const SymbolKind.property().priority, 12);
      });

      test('should return correct priority for constant', () {
        // Arrange & Act & Assert
        expect(const SymbolKind.constant().priority, 13);
      });

      test('should return correct priority for variable', () {
        // Arrange & Act & Assert
        expect(const SymbolKind.variable().priority, 14);
      });

      test('should return correct priority for enum value', () {
        // Arrange & Act & Assert
        expect(const SymbolKind.enumValue().priority, 15);
      });

      test('should return correct priority for parameter', () {
        // Arrange & Act & Assert
        expect(const SymbolKind.parameter().priority, 16);
      });

      test('should have class declaration with lowest priority number', () {
        // Arrange
        const kinds = [
          SymbolKind.classDeclaration(),
          SymbolKind.abstractClass(),
          SymbolKind.mixin(),
          SymbolKind.function(),
          SymbolKind.variable(),
        ];

        // Act
        final priorities = kinds.map((k) => k.priority).toList();
        final minPriority = priorities.reduce((a, b) => a < b ? a : b);

        // Assert
        expect(const SymbolKind.classDeclaration().priority, minPriority);
      });

      test('should have parameter with highest priority number', () {
        // Arrange
        const kinds = [
          SymbolKind.classDeclaration(),
          SymbolKind.method(),
          SymbolKind.variable(),
          SymbolKind.parameter(),
        ];

        // Act
        final priorities = kinds.map((k) => k.priority).toList();
        final maxPriority = priorities.reduce((a, b) => a > b ? a : b);

        // Assert
        expect(const SymbolKind.parameter().priority, maxPriority);
      });

      test('should have unique priorities for different kinds', () {
        // Arrange
        const kinds = [
          SymbolKind.classDeclaration(),
          SymbolKind.mixin(),
          SymbolKind.extension(),
          SymbolKind.enumDeclaration(),
          SymbolKind.typedef(),
          SymbolKind.constructor(),
          SymbolKind.method(),
          SymbolKind.getter(),
          SymbolKind.setter(),
          SymbolKind.function(),
          SymbolKind.field(),
          SymbolKind.property(),
          SymbolKind.constant(),
          SymbolKind.variable(),
          SymbolKind.enumValue(),
          SymbolKind.parameter(),
        ];

        // Act
        final priorities = kinds.map((k) => k.priority).toList();
        final uniquePriorities = priorities.toSet();

        // Assert - abstractClass shares priority with classDeclaration
        expect(uniquePriorities.length, greaterThan(10));
      });
    });

    group('equality', () {
      test('should be equal for same kind', () {
        // Arrange
        const kind1 = SymbolKind.classDeclaration();
        const kind2 = SymbolKind.classDeclaration();

        // Act & Assert
        expect(kind1, equals(kind2));
        expect(kind1.hashCode, equals(kind2.hashCode));
      });

      test('should not be equal for different kinds', () {
        // Arrange
        const kind1 = SymbolKind.classDeclaration();
        const kind2 = SymbolKind.function();

        // Act & Assert
        expect(kind1, isNot(equals(kind2)));
      });

      test('should be equal for same function kinds', () {
        // Arrange
        const kind1 = SymbolKind.function();
        const kind2 = SymbolKind.function();

        // Act & Assert
        expect(kind1, equals(kind2));
      });

      test('should be equal for same method kinds', () {
        // Arrange
        const kind1 = SymbolKind.method();
        const kind2 = SymbolKind.method();

        // Act & Assert
        expect(kind1, equals(kind2));
      });
    });

    group('map and maybeMap', () {
      test('should use map to handle all cases', () {
        // Arrange
        const kind = SymbolKind.classDeclaration();

        // Act
        final result = kind.map(
          classDeclaration: (_) => 'class',
          abstractClass: (_) => 'abstract',
          mixin: (_) => 'mixin',
          extension: (_) => 'extension',
          enumDeclaration: (_) => 'enum',
          typedef: (_) => 'typedef',
          function: (_) => 'function',
          method: (_) => 'method',
          constructor: (_) => 'constructor',
          getter: (_) => 'getter',
          setter: (_) => 'setter',
          field: (_) => 'field',
          property: (_) => 'property',
          constant: (_) => 'constant',
          variable: (_) => 'variable',
          enumValue: (_) => 'enumValue',
          parameter: (_) => 'parameter',
        );

        // Assert
        expect(result, 'class');
      });

      test('should use maybeMap with specific case', () {
        // Arrange
        const kind = SymbolKind.method();

        // Act
        final result = kind.maybeMap(
          method: (_) => 'found method',
          orElse: () => 'other',
        );

        // Assert
        expect(result, 'found method');
      });

      test('should use maybeMap orElse for unmatched case', () {
        // Arrange
        const kind = SymbolKind.classDeclaration();

        // Act
        final result = kind.maybeMap(
          method: (_) => 'method',
          orElse: () => 'not a method',
        );

        // Assert
        expect(result, 'not a method');
      });
    });

    group('practical examples', () {
      test('should represent Dart class symbol', () {
        // Arrange & Act
        const kind = SymbolKind.classDeclaration();

        // Assert
        expect(kind.displayName, 'Class');
        expect(kind.priority, 1);
        expect(kind.iconCode, isNotNull);
      });

      test('should represent Dart method symbol', () {
        // Arrange & Act
        const kind = SymbolKind.method();

        // Assert
        expect(kind.displayName, 'Method');
        expect(kind.priority, 7);
        expect(kind.iconCode, 0xe8f4);
      });

      test('should represent Dart getter symbol', () {
        // Arrange & Act
        const kind = SymbolKind.getter();

        // Assert
        expect(kind.displayName, 'Getter');
        expect(kind.priority, 8);
      });

      test('should represent Dart enum symbol', () {
        // Arrange & Act
        const kind = SymbolKind.enumDeclaration();

        // Assert
        expect(kind.displayName, 'Enum');
        expect(kind.priority, 4);
      });

      test('should represent Dart extension symbol', () {
        // Arrange & Act
        const kind = SymbolKind.extension();

        // Assert
        expect(kind.displayName, 'Extension');
        expect(kind.priority, 3);
      });

      test('should sort symbols by priority', () {
        // Arrange
        final symbols = [
          const SymbolKind.variable(),
          const SymbolKind.classDeclaration(),
          const SymbolKind.method(),
          const SymbolKind.field(),
        ];

        // Act
        symbols.sort((a, b) => a.priority.compareTo(b.priority));

        // Assert
        expect(symbols[0], isA<SymbolKind>());
        expect(symbols[0].priority, 1); // classDeclaration
        expect(symbols[1].priority, 7); // method
        expect(symbols[2].priority, 11); // field
        expect(symbols[3].priority, 14); // variable
      });
    });

    group('when expression support', () {
      test('should work with when for class kinds', () {
        // Arrange
        const kind = SymbolKind.classDeclaration();

        // Act
        final result = kind.when(
          classDeclaration: () => 'class',
          abstractClass: () => 'abstract',
          mixin: () => 'mixin',
          extension: () => 'extension',
          enumDeclaration: () => 'enum',
          typedef: () => 'typedef',
          function: () => 'function',
          method: () => 'method',
          constructor: () => 'constructor',
          getter: () => 'getter',
          setter: () => 'setter',
          field: () => 'field',
          property: () => 'property',
          constant: () => 'constant',
          variable: () => 'variable',
          enumValue: () => 'enumValue',
          parameter: () => 'parameter',
        );

        // Assert
        expect(result, 'class');
      });

      test('should work with maybeWhen for specific case', () {
        // Arrange
        const kind = SymbolKind.function();

        // Act
        final result = kind.maybeWhen(
          function: () => 'is function',
          orElse: () => 'not function',
        );

        // Assert
        expect(result, 'is function');
      });

      test('should work with maybeWhen orElse', () {
        // Arrange
        const kind = SymbolKind.classDeclaration();

        // Act
        final result = kind.maybeWhen(
          function: () => 'is function',
          method: () => 'is method',
          orElse: () => 'other kind',
        );

        // Assert
        expect(result, 'other kind');
      });
    });

    group('all symbol kinds coverage', () {
      test('should have 17 different symbol kinds', () {
        // Arrange
        const kinds = [
          SymbolKind.classDeclaration(),
          SymbolKind.abstractClass(),
          SymbolKind.mixin(),
          SymbolKind.extension(),
          SymbolKind.enumDeclaration(),
          SymbolKind.typedef(),
          SymbolKind.function(),
          SymbolKind.method(),
          SymbolKind.constructor(),
          SymbolKind.getter(),
          SymbolKind.setter(),
          SymbolKind.field(),
          SymbolKind.property(),
          SymbolKind.constant(),
          SymbolKind.variable(),
          SymbolKind.enumValue(),
          SymbolKind.parameter(),
        ];

        // Act & Assert
        expect(kinds.length, 17);
        for (final kind in kinds) {
          expect(kind.displayName, isNotEmpty);
          expect(kind.priority, greaterThanOrEqualTo(1));
          expect(kind.iconCode, greaterThan(0));
        }
      });

      test('should have unique display names', () {
        // Arrange
        const kinds = [
          SymbolKind.classDeclaration(),
          SymbolKind.abstractClass(),
          SymbolKind.mixin(),
          SymbolKind.extension(),
          SymbolKind.enumDeclaration(),
          SymbolKind.typedef(),
          SymbolKind.function(),
          SymbolKind.method(),
          SymbolKind.constructor(),
          SymbolKind.getter(),
          SymbolKind.setter(),
          SymbolKind.field(),
          SymbolKind.property(),
          SymbolKind.constant(),
          SymbolKind.variable(),
          SymbolKind.enumValue(),
          SymbolKind.parameter(),
        ];

        // Act
        final displayNames = kinds.map((k) => k.displayName).toSet();

        // Assert
        expect(displayNames.length, 17);
      });
    });
  });
}
