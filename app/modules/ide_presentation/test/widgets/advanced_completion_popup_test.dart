import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:ide_presentation/ide_presentation.dart';

void main() {
  group('AdvancedCompletionPopup', () {
    late CompletionList testCompletions;

    setUp(() {
      testCompletions = CompletionList(
        items: [
          CompletionItem(
            label: 'toString',
            kind: CompletionItemKind.method,
            detail: '() → String',
            documentation: 'Returns a string representation',
            insertText: 'toString()',
          ),
          CompletionItem(
            label: 'MyClass',
            kind: CompletionItemKind.class_,
            detail: 'Custom class',
            documentation: 'A custom class for testing',
            insertText: 'MyClass',
          ),
        ],
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
                AdvancedCompletionPopup(
                  completions: testCompletions,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Assert - Widget should render
      expect(find.byType(AdvancedCompletionPopup), findsOneWidget);
    });

    testWidgets('should work without onDismissed callback', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AdvancedCompletionPopup(
                  completions: testCompletions,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Assert - Should not crash
      expect(find.byType(AdvancedCompletionPopup), findsOneWidget);
    });

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
                AdvancedCompletionPopup(
                  completions: emptyCompletions,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(AdvancedCompletionPopup), findsOneWidget);
    });
  });
}
