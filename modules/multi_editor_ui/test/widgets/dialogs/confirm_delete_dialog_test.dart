import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_ui/src/widgets/dialogs/confirm_delete_dialog.dart';

void main() {
  group('ConfirmDeleteDialog', () {
    testWidgets('should render with required properties', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmDeleteDialog(
              itemName: 'test.dart',
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Delete item?'), findsOneWidget);
      expect(find.text('test.dart'), findsOneWidget);
      expect(find.text('This action cannot be undone.'), findsOneWidget);
    });

    testWidgets('should render with custom item type', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmDeleteDialog(
              itemName: 'my-folder',
              itemType: 'folder',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Delete folder?'), findsOneWidget);
      expect(find.text('my-folder'), findsOneWidget);
    });

    testWidgets('should display warning message when provided',
        (tester) async {
      // Arrange
      const warningText = 'This folder contains 5 files';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmDeleteDialog(
              itemName: 'folder-with-files',
              itemType: 'folder',
              warningMessage: warningText,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(warningText), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('should not display warning container when message is null',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmDeleteDialog(
              itemName: 'test.dart',
              warningMessage: null,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('should have Cancel and Delete buttons', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmDeleteDialog(
              itemName: 'test.dart',
            ),
          ),
        ),
      );

      // Assert
      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Delete'), findsOneWidget);
    });

    testWidgets('should return false when Cancel is pressed', (tester) async {
      // Arrange
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<bool>(
                    context: context,
                    builder: (context) => const ConfirmDeleteDialog(
                      itemName: 'test.dart',
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Assert
      expect(dialogResult, equals(false));
    });

    testWidgets('should return true when Delete is pressed', (tester) async {
      // Arrange
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<bool>(
                    context: context,
                    builder: (context) => const ConfirmDeleteDialog(
                      itemName: 'test.dart',
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Assert
      expect(dialogResult, equals(true));
    });

    testWidgets('should display formatted message with item name',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmDeleteDialog(
              itemName: 'important-file.txt',
              itemType: 'file',
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(RichText), findsWidgets);
      expect(find.text('important-file.txt'), findsOneWidget);
    });

    testWidgets('should apply error color scheme to Delete button',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
          ),
          home: const Scaffold(
            body: ConfirmDeleteDialog(
              itemName: 'test.dart',
            ),
          ),
        ),
      );

      // Assert
      final deleteButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Delete'),
      );
      expect(deleteButton.style, isNotNull);
    });

    testWidgets('should display all content sections in correct order',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmDeleteDialog(
              itemName: 'test-folder',
              itemType: 'folder',
              warningMessage: 'Warning: This folder is not empty',
            ),
          ),
        ),
      );

      // Assert - All sections present
      expect(find.text('Delete folder?'), findsOneWidget);
      expect(find.text('test-folder'), findsOneWidget);
      expect(find.text('Warning: This folder is not empty'), findsOneWidget);
      expect(find.text('This action cannot be undone.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('should render with minimum required properties',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmDeleteDialog(
              itemName: 'x',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('x'), findsOneWidget);
      expect(find.text('Delete item?'), findsOneWidget);
    });

    testWidgets('should handle long item names gracefully', (tester) async {
      // Arrange
      const longName =
          'very_long_file_name_that_might_cause_layout_issues_if_not_handled_properly.dart';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmDeleteDialog(
              itemName: longName,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(longName), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle long warning messages', (tester) async {
      // Arrange
      const longWarning =
          'This is a very long warning message that explains in detail why this deletion might be problematic and what consequences it might have on the system and user data.';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmDeleteDialog(
              itemName: 'test.dart',
              warningMessage: longWarning,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(longWarning), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should work with dark theme', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: ConfirmDeleteDialog(
              itemName: 'test.dart',
              warningMessage: 'Dark mode warning',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('test.dart'), findsOneWidget);
      expect(find.text('Dark mode warning'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
