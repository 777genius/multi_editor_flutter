import 'package:flutter_test/flutter_test.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';

void main() {
  group('CallHierarchyItem', () {
    group('Construction', () {
      test('should create with all required parameters', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 10, column: 0),
          end: const CursorPosition(line: 15, column: 20),
        );
        final selectionRange = TextSelection(
          start: const CursorPosition(line: 10, column: 5),
          end: const CursorPosition(line: 10, column: 15),
        );

        // Act
        final item = CallHierarchyItem(
          name: 'calculateTotal',
          kind: SymbolKind.function,
          uri: DocumentUri.fromFilePath('/src/calculator.dart'),
          range: range,
          selectionRange: selectionRange,
        );

        // Assert
        expect(item.name, equals('calculateTotal'));
        expect(item.kind, equals(SymbolKind.function));
        expect(item.detail, isNull);
      });

      test('should create with detail', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 5, column: 0),
          end: const CursorPosition(line: 10, column: 0),
        );
        final selectionRange = TextSelection(
          start: const CursorPosition(line: 5, column: 6),
          end: const CursorPosition(line: 5, column: 15),
        );

        // Act
        final item = CallHierarchyItem(
          name: 'processData',
          kind: SymbolKind.method,
          detail: 'async processData(List<String> data)',
          uri: DocumentUri.fromFilePath('/lib/processor.dart'),
          range: range,
          selectionRange: selectionRange,
        );

        // Assert
        expect(item.detail, contains('async'));
        expect(item.detail, contains('List<String>'));
      });
    });

    group('Symbol Kinds', () {
      test('should support function kind', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 5, column: 0),
        );

        // Act
        final item = CallHierarchyItem(
          name: 'main',
          kind: SymbolKind.function,
          uri: DocumentUri.fromFilePath('/main.dart'),
          range: range,
          selectionRange: range,
        );

        // Assert
        expect(item.kind, equals(SymbolKind.function));
      });

      test('should support method kind', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 10, column: 2),
          end: const CursorPosition(line: 15, column: 3),
        );

        // Act
        final item = CallHierarchyItem(
          name: 'build',
          kind: SymbolKind.method,
          uri: DocumentUri.fromFilePath('/widget.dart'),
          range: range,
          selectionRange: range,
        );

        // Assert
        expect(item.kind, equals(SymbolKind.method));
      });

      test('should support constructor kind', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 5, column: 2),
          end: const CursorPosition(line: 8, column: 3),
        );

        // Act
        final item = CallHierarchyItem(
          name: 'MyClass',
          kind: SymbolKind.constructor,
          uri: DocumentUri.fromFilePath('/my_class.dart'),
          range: range,
          selectionRange: range,
        );

        // Assert
        expect(item.kind, equals(SymbolKind.constructor));
      });
    });

    group('Range Differences', () {
      test('should distinguish between range and selectionRange', () {
        // Arrange - range includes whole function, selectionRange is just the name
        final range = TextSelection(
          start: const CursorPosition(line: 10, column: 0),
          end: const CursorPosition(line: 20, column: 1),
        );
        final selectionRange = TextSelection(
          start: const CursorPosition(line: 10, column: 5),
          end: const CursorPosition(line: 10, column: 15),
        );

        // Act
        final item = CallHierarchyItem(
          name: 'calculate',
          kind: SymbolKind.function,
          uri: DocumentUri.fromFilePath('/test.dart'),
          range: range,
          selectionRange: selectionRange,
        );

        // Assert
        expect(item.range.start.line, lessThan(item.selectionRange.start.line) ||
               (item.range.start.line == item.selectionRange.start.line &&
                item.range.start.column <= item.selectionRange.start.column));
        expect(item.selectionRange.end.line, lessThanOrEqualTo(item.range.end.line));
      });

      test('should support same range and selectionRange', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 5, column: 0),
          end: const CursorPosition(line: 5, column: 10),
        );

        // Act
        final item = CallHierarchyItem(
          name: 'getter',
          kind: SymbolKind.method,
          uri: DocumentUri.fromFilePath('/test.dart'),
          range: range,
          selectionRange: range,
        );

        // Assert
        expect(item.range, equals(item.selectionRange));
      });
    });

    group('Equality', () {
      test('should be equal with same values', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 5, column: 0),
        );
        final item1 = CallHierarchyItem(
          name: 'test',
          kind: SymbolKind.function,
          uri: DocumentUri.fromFilePath('/test.dart'),
          range: range,
          selectionRange: range,
        );
        final item2 = CallHierarchyItem(
          name: 'test',
          kind: SymbolKind.function,
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
          end: const CursorPosition(line: 5, column: 0),
        );
        final item1 = CallHierarchyItem(
          name: 'test1',
          kind: SymbolKind.function,
          uri: DocumentUri.fromFilePath('/test.dart'),
          range: range,
          selectionRange: range,
        );
        final item2 = CallHierarchyItem(
          name: 'test2',
          kind: SymbolKind.function,
          uri: DocumentUri.fromFilePath('/test.dart'),
          range: range,
          selectionRange: range,
        );

        // Assert
        expect(item1, isNot(equals(item2)));
      });
    });
  });

  group('CallHierarchyIncomingCall', () {
    group('Construction', () {
      test('should create with caller and call sites', () {
        // Arrange
        final callerRange = TextSelection(
          start: const CursorPosition(line: 5, column: 0),
          end: const CursorPosition(line: 10, column: 0),
        );
        final caller = CallHierarchyItem(
          name: 'caller',
          kind: SymbolKind.function,
          uri: DocumentUri.fromFilePath('/caller.dart'),
          range: callerRange,
          selectionRange: callerRange,
        );
        final callSites = [
          TextSelection(
            start: const CursorPosition(line: 7, column: 5),
            end: const CursorPosition(line: 7, column: 15),
          ),
        ];

        // Act
        final incoming = CallHierarchyIncomingCall(
          from: caller,
          fromRanges: callSites,
        );

        // Assert
        expect(incoming.from.name, equals('caller'));
        expect(incoming.fromRanges.length, equals(1));
      });

      test('should support multiple call sites', () {
        // Arrange
        final callerRange = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 20, column: 0),
        );
        final caller = CallHierarchyItem(
          name: 'process',
          kind: SymbolKind.function,
          uri: DocumentUri.fromFilePath('/test.dart'),
          range: callerRange,
          selectionRange: callerRange,
        );
        final callSites = [
          TextSelection(
            start: const CursorPosition(line: 5, column: 5),
            end: const CursorPosition(line: 5, column: 15),
          ),
          TextSelection(
            start: const CursorPosition(line: 10, column: 5),
            end: const CursorPosition(line: 10, column: 15),
          ),
          TextSelection(
            start: const CursorPosition(line: 15, column: 5),
            end: const CursorPosition(line: 15, column: 15),
          ),
        ];

        // Act
        final incoming = CallHierarchyIncomingCall(
          from: caller,
          fromRanges: callSites,
        );

        // Assert
        expect(incoming.fromRanges.length, equals(3));
      });

      test('should support empty call sites list', () {
        // Arrange
        final callerRange = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 5, column: 0),
        );
        final caller = CallHierarchyItem(
          name: 'caller',
          kind: SymbolKind.function,
          uri: DocumentUri.fromFilePath('/test.dart'),
          range: callerRange,
          selectionRange: callerRange,
        );

        // Act
        final incoming = CallHierarchyIncomingCall(
          from: caller,
          fromRanges: [],
        );

        // Assert
        expect(incoming.fromRanges, isEmpty);
      });
    });

    group('Use Cases', () {
      test('should represent function called from main', () {
        // Arrange
        final mainRange = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 10, column: 0),
        );
        final main = CallHierarchyItem(
          name: 'main',
          kind: SymbolKind.function,
          uri: DocumentUri.fromFilePath('/main.dart'),
          range: mainRange,
          selectionRange: mainRange,
        );
        final callSite = [
          TextSelection(
            start: const CursorPosition(line: 5, column: 2),
            end: const CursorPosition(line: 5, column: 15),
          ),
        ];

        // Act
        final incoming = CallHierarchyIncomingCall(
          from: main,
          fromRanges: callSite,
        );

        // Assert
        expect(incoming.from.name, equals('main'));
      });

      test('should represent method called from multiple locations', () {
        // Arrange
        final callerRange = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 50, column: 0),
        );
        final caller = CallHierarchyItem(
          name: 'ComplexClass.method',
          kind: SymbolKind.method,
          uri: DocumentUri.fromFilePath('/complex.dart'),
          range: callerRange,
          selectionRange: callerRange,
        );

        // Multiple calls within same caller
        final callSites = List.generate(
          5,
          (i) => TextSelection(
            start: CursorPosition(line: i * 10, column: 4),
            end: CursorPosition(line: i * 10, column: 14),
          ),
        );

        // Act
        final incoming = CallHierarchyIncomingCall(
          from: caller,
          fromRanges: callSites,
        );

        // Assert
        expect(incoming.fromRanges.length, equals(5));
      });
    });
  });

  group('CallHierarchyOutgoingCall', () {
    group('Construction', () {
      test('should create with callee and call sites', () {
        // Arrange
        final calleeRange = TextSelection(
          start: const CursorPosition(line: 20, column: 0),
          end: const CursorPosition(line: 25, column: 0),
        );
        final callee = CallHierarchyItem(
          name: 'callee',
          kind: SymbolKind.function,
          uri: DocumentUri.fromFilePath('/callee.dart'),
          range: calleeRange,
          selectionRange: calleeRange,
        );
        final callSites = [
          TextSelection(
            start: const CursorPosition(line: 10, column: 5),
            end: const CursorPosition(line: 10, column: 15),
          ),
        ];

        // Act
        final outgoing = CallHierarchyOutgoingCall(
          to: callee,
          fromRanges: callSites,
        );

        // Assert
        expect(outgoing.to.name, equals('callee'));
        expect(outgoing.fromRanges.length, equals(1));
      });

      test('should represent function calling multiple helpers', () {
        // Arrange - One function calls multiple other functions
        final helperRange = TextSelection(
          start: const CursorPosition(line: 50, column: 0),
          end: const CursorPosition(line: 55, column: 0),
        );
        final helper = CallHierarchyItem(
          name: 'helper',
          kind: SymbolKind.function,
          uri: DocumentUri.fromFilePath('/helpers.dart'),
          range: helperRange,
          selectionRange: helperRange,
        );
        final callSites = [
          TextSelection(
            start: const CursorPosition(line: 10, column: 2),
            end: const CursorPosition(line: 10, column: 12),
          ),
          TextSelection(
            start: const CursorPosition(line: 15, column: 2),
            end: const CursorPosition(line: 15, column: 12),
          ),
        ];

        // Act
        final outgoing = CallHierarchyOutgoingCall(
          to: helper,
          fromRanges: callSites,
        );

        // Assert
        expect(outgoing.fromRanges.length, equals(2));
      });
    });

    group('Use Cases', () {
      test('should represent recursive call', () {
        // Arrange
        final functionRange = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 10, column: 0),
        );
        final function = CallHierarchyItem(
          name: 'fibonacci',
          kind: SymbolKind.function,
          uri: DocumentUri.fromFilePath('/math.dart'),
          range: functionRange,
          selectionRange: functionRange,
        );
        final recursiveCallSites = [
          TextSelection(
            start: const CursorPosition(line: 5, column: 10),
            end: const CursorPosition(line: 5, column: 19),
          ),
          TextSelection(
            start: const CursorPosition(line: 6, column: 10),
            end: const CursorPosition(line: 6, column: 19),
          ),
        ];

        // Act - Outgoing call to itself
        final outgoing = CallHierarchyOutgoingCall(
          to: function,
          fromRanges: recursiveCallSites,
        );

        // Assert
        expect(outgoing.to.name, equals('fibonacci'));
        expect(outgoing.fromRanges.length, equals(2));
      });
    });
  });

  group('CallHierarchyResult', () {
    group('Construction', () {
      test('should create with item only', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 5, column: 0),
        );
        final item = CallHierarchyItem(
          name: 'test',
          kind: SymbolKind.function,
          uri: DocumentUri.fromFilePath('/test.dart'),
          range: range,
          selectionRange: range,
        );

        // Act
        final result = CallHierarchyResult(item: item);

        // Assert
        expect(result.item.name, equals('test'));
        expect(result.incomingCalls, isNull);
        expect(result.outgoingCalls, isNull);
      });

      test('should create with incoming calls', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 5, column: 0),
        );
        final item = CallHierarchyItem(
          name: 'target',
          kind: SymbolKind.function,
          uri: DocumentUri.fromFilePath('/test.dart'),
          range: range,
          selectionRange: range,
        );
        final incoming = [
          CallHierarchyIncomingCall(
            from: item,
            fromRanges: [],
          ),
        ];

        // Act
        final result = CallHierarchyResult(
          item: item,
          incomingCalls: incoming,
        );

        // Assert
        expect(result.incomingCalls, isNotNull);
        expect(result.incomingCalls!.length, equals(1));
      });

      test('should create with outgoing calls', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 5, column: 0),
        );
        final item = CallHierarchyItem(
          name: 'caller',
          kind: SymbolKind.function,
          uri: DocumentUri.fromFilePath('/test.dart'),
          range: range,
          selectionRange: range,
        );
        final outgoing = [
          CallHierarchyOutgoingCall(
            to: item,
            fromRanges: [],
          ),
        ];

        // Act
        final result = CallHierarchyResult(
          item: item,
          outgoingCalls: outgoing,
        );

        // Assert
        expect(result.outgoingCalls, isNotNull);
        expect(result.outgoingCalls!.length, equals(1));
      });

      test('should create with both incoming and outgoing calls', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 5, column: 0),
        );
        final item = CallHierarchyItem(
          name: 'middleFunction',
          kind: SymbolKind.function,
          uri: DocumentUri.fromFilePath('/test.dart'),
          range: range,
          selectionRange: range,
        );

        // Act
        final result = CallHierarchyResult(
          item: item,
          incomingCalls: [
            CallHierarchyIncomingCall(from: item, fromRanges: []),
          ],
          outgoingCalls: [
            CallHierarchyOutgoingCall(to: item, fromRanges: []),
          ],
        );

        // Assert
        expect(result.incomingCalls, isNotNull);
        expect(result.outgoingCalls, isNotNull);
      });
    });
  });
}
