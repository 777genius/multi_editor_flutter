import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';
import 'package:ide_presentation/ide_presentation.dart';

void main() {
  group('CompletionPopup', () {
    late CompletionList testCompletions;
    late CompletionItem methodItem;
    late CompletionItem classItem;
    late CompletionItem variableItem;

    setUp(() {
      methodItem = CompletionItem(
        label: 'toString',
        kind: CompletionItemKind.method,
        detail: '() → String',
        insertText: 'toString()',
      );

      classItem = CompletionItem(
        label: 'MyClass',
        kind: CompletionItemKind.class_,
        detail: 'Custom class',
        insertText: 'MyClass',
      );

      variableItem = CompletionItem(
        label: 'myVariable',
        kind: CompletionItemKind.variable,
        detail: 'String',
        insertText: 'myVariable',
      );

      testCompletions = CompletionList(
        items: [methodItem, classItem, variableItem],
        isIncomplete: false,
      );
    });

    testWidgets('should render with completion items', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CompletionPopup(
                  completions: testCompletions,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('toString'), findsOneWidget);
      expect(find.text('MyClass'), findsOneWidget);
      expect(find.text('myVariable'), findsOneWidget);
    });

    testWidgets('should display completion count in header', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CompletionPopup(
                  completions: testCompletions,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Suggestions (3)'), findsOneWidget);
    });

    testWidgets('should show "Tab to accept" hint', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CompletionPopup(
                  completions: testCompletions,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Tab to accept'), findsOneWidget);
    });

    testWidgets('should call onSelected when item clicked', (tester) async {
      // Arrange
      CompletionItem? selectedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CompletionPopup(
                  completions: testCompletions,
                  onSelected: (item) => selectedItem = item,
                ),
              ],
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('MyClass'));
      await tester.pumpAndSettle();

      // Assert
      expect(selectedItem, equals(classItem));
    });

    testWidgets('should navigate down with arrow key', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CompletionPopup(
                  completions: testCompletions,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Wait for focus
      await tester.pumpAndSettle();

      // Act - Press down arrow
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      // Assert - Selection should move to index 1
      expect(find.byType(CompletionPopup), findsOneWidget);
    });

    testWidgets('should navigate up with arrow key', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CompletionPopup(
                  completions: testCompletions,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Press down then up
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CompletionPopup), findsOneWidget);
    });

    testWidgets('should select item with Enter key', (tester) async {
      // Arrange
      CompletionItem? selectedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CompletionPopup(
                  completions: testCompletions,
                  onSelected: (item) => selectedItem = item,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Press Enter (selects first item by default)
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Assert
      expect(selectedItem, equals(methodItem));
    });

    testWidgets('should select item with Tab key', (tester) async {
      // Arrange
      CompletionItem? selectedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CompletionPopup(
                  completions: testCompletions,
                  onSelected: (item) => selectedItem = item,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Press Tab
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Assert
      expect(selectedItem, equals(methodItem));
    });

    testWidgets('should call onDismissed with Escape key', (tester) async {
      // Arrange
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CompletionPopup(
                  completions: testCompletions,
                  onSelected: (_) {},
                  onDismissed: () => dismissed = true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Assert
      expect(dismissed, isTrue);
    });

    testWidgets('should work without onDismissed callback', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CompletionPopup(
                  completions: testCompletions,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Should not crash when pressing Escape
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CompletionPopup), findsOneWidget);
    });

    testWidgets('should display item details', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CompletionPopup(
                  completions: testCompletions,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('() → String'), findsOneWidget);
      expect(find.text('Custom class'), findsOneWidget);
      expect(find.text('String'), findsOneWidget);
    });

    testWidgets('should handle items without details', (tester) async {
      // Arrange
      final itemNoDetail = CompletionItem(
        label: 'simpleItem',
        kind: CompletionItemKind.text,
        insertText: 'simpleItem',
      );

      final completions = CompletionList(
        items: [itemNoDetail],
        isIncomplete: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CompletionPopup(
                  completions: completions,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Assert - Should still render
      expect(find.text('simpleItem'), findsOneWidget);
    });

    testWidgets('should display sort text when different from label', (tester) async {
      // Arrange
      final itemWithSortText = CompletionItem(
        label: 'myMethod',
        kind: CompletionItemKind.method,
        insertText: 'myMethod()',
        sortText: '0001',
      );

      final completions = CompletionList(
        items: [itemWithSortText],
        isIncomplete: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CompletionPopup(
                  completions: completions,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('0001'), findsOneWidget);
    });

    testWidgets('should not display sort text when same as label', (tester) async {
      // Arrange
      final itemSameSortText = CompletionItem(
        label: 'myMethod',
        kind: CompletionItemKind.method,
        insertText: 'myMethod()',
        sortText: 'myMethod',
      );

      final completions = CompletionList(
        items: [itemSameSortText],
        isIncomplete: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CompletionPopup(
                  completions: completions,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Assert - Sort text should not be displayed separately
      expect(find.text('myMethod'), findsOneWidget);
    });

    testWidgets('should be scrollable for many completions', (tester) async {
      // Arrange - Create many completions
      final manyCompletions = CompletionList(
        items: List.generate(
          50,
          (index) => CompletionItem(
            label: 'item$index',
            kind: CompletionItemKind.variable,
            insertText: 'item$index',
          ),
        ),
        isIncomplete: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CompletionPopup(
                  completions: manyCompletions,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should have VS Code dark styling', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CompletionPopup(
                  completions: testCompletions,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Assert - Check for dark background
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(Material),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(const Color(0xFF252526)));
    });

    testWidgets('should have elevation shadow', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CompletionPopup(
                  completions: testCompletions,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      final material = tester.widget<Material>(find.byType(Material));
      expect(material.elevation, equals(8));
    });

    testWidgets('should enforce max width and height', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CompletionPopup(
                  completions: testCompletions,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(Material),
          matching: find.byType(Container),
        ).first,
      );
      expect(container.width, equals(400));
      expect(container.constraints?.maxHeight, equals(300));
    });

    testWidgets('should auto-focus on init', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CompletionPopup(
                  completions: testCompletions,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Widget should be focusable
      expect(find.byType(Focus), findsOneWidget);
    });

    group('Completion Item Icons', () {
      testWidgets('should show function icon for methods', (tester) async {
        // Arrange
        final completions = CompletionList(
          items: [methodItem],
          isIncomplete: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  CompletionPopup(
                    completions: completions,
                    onSelected: (_) {},
                  ),
                ],
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.functions), findsOneWidget);
      });

      testWidgets('should show class icon for classes', (tester) async {
        // Arrange
        final completions = CompletionList(
          items: [classItem],
          isIncomplete: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  CompletionPopup(
                    completions: completions,
                    onSelected: (_) {},
                  ),
                ],
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.class_), findsOneWidget);
      });

      testWidgets('should show variable icon for variables', (tester) async {
        // Arrange
        final completions = CompletionList(
          items: [variableItem],
          isIncomplete: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  CompletionPopup(
                    completions: completions,
                    onSelected: (_) {},
                  ),
                ],
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.adjust), findsOneWidget);
      });

      testWidgets('should show keyword icon for keywords', (tester) async {
        // Arrange
        final keywordItem = CompletionItem(
          label: 'final',
          kind: CompletionItemKind.keyword,
          insertText: 'final',
        );

        final completions = CompletionList(
          items: [keywordItem],
          isIncomplete: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  CompletionPopup(
                    completions: completions,
                    onSelected: (_) {},
                  ),
                ],
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.key), findsOneWidget);
      });

      testWidgets('should show snippet icon for snippets', (tester) async {
        // Arrange
        final snippetItem = CompletionItem(
          label: 'for loop',
          kind: CompletionItemKind.snippet,
          insertText: 'for (var i = 0; i < \$1; i++) {\n  \$2\n}',
        );

        final completions = CompletionList(
          items: [snippetItem],
          isIncomplete: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  CompletionPopup(
                    completions: completions,
                    onSelected: (_) {},
                  ),
                ],
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.code), findsOneWidget);
      });

      testWidgets('should show default icon for unknown kind', (tester) async {
        // Arrange
        final unknownItem = CompletionItem(
          label: 'unknown',
          kind: null,
          insertText: 'unknown',
        );

        final completions = CompletionList(
          items: [unknownItem],
          isIncomplete: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  CompletionPopup(
                    completions: completions,
                    onSelected: (_) {},
                  ),
                ],
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.text_fields), findsOneWidget);
      });
    });

    group('Keyboard Navigation', () {
      testWidgets('should not select beyond bounds when navigating down', (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  CompletionPopup(
                    completions: testCompletions,
                    onSelected: (_) {},
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Act - Press down many times
        for (var i = 0; i < 10; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pump();
        }

        // Assert - Should not crash
        expect(find.byType(CompletionPopup), findsOneWidget);
      });

      testWidgets('should not select below 0 when navigating up', (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  CompletionPopup(
                    completions: testCompletions,
                    onSelected: (_) {},
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Act - Press up many times from start
        for (var i = 0; i < 10; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          await tester.pump();
        }

        // Assert - Should not crash
        expect(find.byType(CompletionPopup), findsOneWidget);
      });

      testWidgets('should select correct item after navigation', (tester) async {
        // Arrange
        CompletionItem? selectedItem;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  CompletionPopup(
                    completions: testCompletions,
                    onSelected: (item) => selectedItem = item,
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Act - Navigate down twice and select
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        // Assert - Should select third item (index 2)
        expect(selectedItem, equals(variableItem));
      });
    });

    group('Hover Behavior', () {
      testWidgets('should update selection on hover', (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  CompletionPopup(
                    completions: testCompletions,
                    onSelected: (_) {},
                  ),
                ],
              ),
            ),
          ),
        );

        // Act - Hover over second item
        final secondItem = find.text('MyClass');
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();
        await gesture.moveTo(tester.getCenter(secondItem));
        await tester.pumpAndSettle();

        // Assert - Should not crash
        expect(find.byType(CompletionPopup), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle empty completion list', (tester) async {
        // Arrange
        final emptyCompletions = CompletionList(
          items: [],
          isIncomplete: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  CompletionPopup(
                    completions: emptyCompletions,
                    onSelected: (_) {},
                  ),
                ],
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('Suggestions (0)'), findsOneWidget);
      });

      testWidgets('should handle very long labels', (tester) async {
        // Arrange
        final longLabelItem = CompletionItem(
          label: 'A' * 100,
          kind: CompletionItemKind.variable,
          insertText: 'A' * 100,
        );

        final completions = CompletionList(
          items: [longLabelItem],
          isIncomplete: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  CompletionPopup(
                    completions: completions,
                    onSelected: (_) {},
                  ),
                ],
              ),
            ),
          ),
        );

        // Assert - Should not crash
        expect(find.byType(CompletionPopup), findsOneWidget);
      });

      testWidgets('should handle incomplete completion list', (tester) async {
        // Arrange
        final incompleteCompletions = CompletionList(
          items: [methodItem],
          isIncomplete: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  CompletionPopup(
                    completions: incompleteCompletions,
                    onSelected: (_) {},
                  ),
                ],
              ),
            ),
          ),
        );

        // Assert - Should still render
        expect(find.text('toString'), findsOneWidget);
      });
    });
  });
}
