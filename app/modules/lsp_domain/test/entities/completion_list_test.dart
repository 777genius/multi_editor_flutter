import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';

void main() {
  group('CompletionList', () {
    late List<CompletionItem> items;

    setUp(() {
      items = [
        const CompletionItem(
          label: 'print',
          kind: CompletionItemKind.function,
          detail: 'void print(Object? object)',
        ),
        const CompletionItem(
          label: 'println',
          kind: CompletionItemKind.function,
          detail: 'void println(String str)',
        ),
        const CompletionItem(
          label: 'parseInt',
          kind: CompletionItemKind.function,
          detail: 'int parseInt(String source)',
        ),
        const CompletionItem(
          label: 'String',
          kind: CompletionItemKind.class_,
          detail: 'class String',
        ),
      ];
    });

    group('creation', () {
      test('should create completion list with items', () {
        // Act
        final completions = CompletionList(items: items);

        // Assert
        expect(completions.items, equals(items));
        expect(completions.isIncomplete, isFalse);
      });

      test('should create incomplete completion list', () {
        // Act
        final completions = CompletionList(
          items: items,
          isIncomplete: true,
        );

        // Assert
        expect(completions.isIncomplete, isTrue);
      });

      test('should create empty completion list', () {
        // Act
        const completions = CompletionList.empty;

        // Assert
        expect(completions.items, isEmpty);
        expect(completions.isIncomplete, isFalse);
      });
    });

    group('filterByPrefix', () {
      late CompletionList completions;

      setUp(() {
        completions = CompletionList(items: items);
      });

      test('should filter items by prefix (case insensitive)', () {
        // Act
        final filtered = completions.filterByPrefix('prin');

        // Assert
        expect(filtered.items.length, equals(2));
        expect(filtered.items[0].label, equals('print'));
        expect(filtered.items[1].label, equals('println'));
      });

      test('should filter items by uppercase prefix', () {
        // Act
        final filtered = completions.filterByPrefix('PRIN');

        // Assert
        expect(filtered.items.length, equals(2));
        expect(filtered.items.every((item) =>
          item.label.toLowerCase().startsWith('prin')), isTrue);
      });

      test('should return all items when prefix is empty', () {
        // Act
        final filtered = completions.filterByPrefix('');

        // Assert
        expect(filtered.items.length, equals(items.length));
        expect(filtered.items, equals(items));
      });

      test('should return empty list when no matches', () {
        // Act
        final filtered = completions.filterByPrefix('xyz');

        // Assert
        expect(filtered.items, isEmpty);
      });

      test('should filter by single character', () {
        // Act
        final filtered = completions.filterByPrefix('p');

        // Assert
        expect(filtered.items.length, equals(3));
        expect(filtered.items.every((item) =>
          item.label.toLowerCase().startsWith('p')), isTrue);
      });

      test('should preserve isIncomplete flag', () {
        // Arrange
        final incompleteList = CompletionList(
          items: items,
          isIncomplete: true,
        );

        // Act
        final filtered = incompleteList.filterByPrefix('prin');

        // Assert
        expect(filtered.isIncomplete, isTrue);
      });
    });

    group('sortByRelevance', () {
      test('should sort by sortText when available', () {
        // Arrange
        final unsorted = CompletionList(items: [
          const CompletionItem(
            label: 'zebra',
            kind: CompletionItemKind.function,
            sortText: '1',
          ),
          const CompletionItem(
            label: 'apple',
            kind: CompletionItemKind.function,
            sortText: '2',
          ),
          const CompletionItem(
            label: 'banana',
            kind: CompletionItemKind.function,
            sortText: '0',
          ),
        ]);

        // Act
        final sorted = unsorted.sortByRelevance();

        // Assert
        expect(sorted.items[0].label, equals('banana')); // sortText: 0
        expect(sorted.items[1].label, equals('zebra'));  // sortText: 1
        expect(sorted.items[2].label, equals('apple'));  // sortText: 2
      });

      test('should sort by label when sortText is not available', () {
        // Arrange
        final unsorted = CompletionList(items: [
          const CompletionItem(
            label: 'zebra',
            kind: CompletionItemKind.function,
          ),
          const CompletionItem(
            label: 'apple',
            kind: CompletionItemKind.function,
          ),
          const CompletionItem(
            label: 'banana',
            kind: CompletionItemKind.function,
          ),
        ]);

        // Act
        final sorted = unsorted.sortByRelevance();

        // Assert
        expect(sorted.items[0].label, equals('apple'));
        expect(sorted.items[1].label, equals('banana'));
        expect(sorted.items[2].label, equals('zebra'));
      });

      test('should handle mixed sortText and label sorting', () {
        // Arrange
        final unsorted = CompletionList(items: [
          const CompletionItem(
            label: 'withSort2',
            kind: CompletionItemKind.function,
            sortText: 'b',
          ),
          const CompletionItem(
            label: 'noSort1',
            kind: CompletionItemKind.function,
          ),
          const CompletionItem(
            label: 'withSort1',
            kind: CompletionItemKind.function,
            sortText: 'a',
          ),
        ]);

        // Act
        final sorted = unsorted.sortByRelevance();

        // Assert
        expect(sorted.items[0].label, equals('withSort1')); // sortText: a
        expect(sorted.items[1].label, equals('withSort2')); // sortText: b
        expect(sorted.items[2].label, equals('noSort1'));   // label: noSort1
      });

      test('should not modify original list', () {
        // Arrange
        final original = CompletionList(items: items);
        final originalFirst = original.items.first.label;

        // Act
        final sorted = original.sortByRelevance();

        // Assert
        expect(original.items.first.label, equals(originalFirst));
        expect(sorted.items.first.label, isNot(equals(originalFirst)));
      });
    });

    group('equality', () {
      test('should be equal with same items', () {
        final list1 = CompletionList(items: items);
        final list2 = CompletionList(items: items);

        expect(list1, equals(list2));
      });

      test('should not be equal with different isIncomplete', () {
        final list1 = CompletionList(items: items, isIncomplete: false);
        final list2 = CompletionList(items: items, isIncomplete: true);

        expect(list1, isNot(equals(list2)));
      });
    });
  });

  group('CompletionItem', () {
    test('should create with required fields', () {
      // Act
      const item = CompletionItem(
        label: 'print',
        kind: CompletionItemKind.function,
      );

      // Assert
      expect(item.label, equals('print'));
      expect(item.kind, equals(CompletionItemKind.function));
      expect(item.detail, isNull);
      expect(item.documentation, isNull);
      expect(item.preselect, isFalse);
    });

    test('should create with all fields', () {
      // Arrange
      const textEdit = TextEdit(
        range: TextSelection(
          start: CursorPosition(line: 1, column: 0),
          end: CursorPosition(line: 1, column: 5),
        ),
        newText: 'print',
      );

      // Act
      const item = CompletionItem(
        label: 'print',
        kind: CompletionItemKind.function,
        detail: 'void print(Object? object)',
        documentation: 'Prints an object to the console',
        insertText: 'print(\$1)',
        sortText: '1',
        filterText: 'print',
        textEdit: textEdit,
        preselect: true,
      );

      // Assert
      expect(item.detail, equals('void print(Object? object)'));
      expect(item.documentation, equals('Prints an object to the console'));
      expect(item.insertText, equals('print(\$1)'));
      expect(item.sortText, equals('1'));
      expect(item.filterText, equals('print'));
      expect(item.textEdit, equals(textEdit));
      expect(item.preselect, isTrue);
    });

    test('should be equal with same data', () {
      const item1 = CompletionItem(
        label: 'test',
        kind: CompletionItemKind.function,
        detail: 'detail',
      );

      const item2 = CompletionItem(
        label: 'test',
        kind: CompletionItemKind.function,
        detail: 'detail',
      );

      expect(item1, equals(item2));
    });

    test('should not be equal with different label', () {
      const item1 = CompletionItem(
        label: 'test1',
        kind: CompletionItemKind.function,
      );

      const item2 = CompletionItem(
        label: 'test2',
        kind: CompletionItemKind.function,
      );

      expect(item1, isNot(equals(item2)));
    });
  });

  group('CompletionItemKind', () {
    test('should have all standard LSP kinds', () {
      expect(CompletionItemKind.values, contains(CompletionItemKind.text));
      expect(CompletionItemKind.values, contains(CompletionItemKind.method));
      expect(CompletionItemKind.values, contains(CompletionItemKind.function));
      expect(CompletionItemKind.values, contains(CompletionItemKind.constructor));
      expect(CompletionItemKind.values, contains(CompletionItemKind.field));
      expect(CompletionItemKind.values, contains(CompletionItemKind.variable));
      expect(CompletionItemKind.values, contains(CompletionItemKind.class_));
      expect(CompletionItemKind.values, contains(CompletionItemKind.interface));
      expect(CompletionItemKind.values, contains(CompletionItemKind.module));
      expect(CompletionItemKind.values, contains(CompletionItemKind.property));
    });
  });

  group('TextEdit', () {
    test('should create with range and newText', () {
      // Arrange
      const range = TextSelection(
        start: CursorPosition(line: 1, column: 0),
        end: CursorPosition(line: 1, column: 5),
      );

      // Act
      const edit = TextEdit(
        range: range,
        newText: 'replacement',
      );

      // Assert
      expect(edit.range, equals(range));
      expect(edit.newText, equals('replacement'));
    });

    test('should be equal with same data', () {
      const edit1 = TextEdit(
        range: TextSelection(
          start: CursorPosition(line: 1, column: 0),
          end: CursorPosition(line: 1, column: 5),
        ),
        newText: 'text',
      );

      const edit2 = TextEdit(
        range: TextSelection(
          start: CursorPosition(line: 1, column: 0),
          end: CursorPosition(line: 1, column: 5),
        ),
        newText: 'text',
      );

      expect(edit1, equals(edit2));
    });
  });
}
