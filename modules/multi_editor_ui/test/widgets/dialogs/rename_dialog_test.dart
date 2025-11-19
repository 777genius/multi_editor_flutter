import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_ui/src/widgets/dialogs/rename_dialog.dart';

void main() {
  group('RenameDialog', () {
    testWidgets('should render with title and form', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RenameDialog(
              currentName: 'old-name.dart',
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Rename item'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('should display custom item type in title', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RenameDialog(
              currentName: 'my-folder',
              itemType: 'folder',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Rename folder'), findsOneWidget);
    });

    testWidgets('should populate input field with current name',
        (tester) async {
      // Arrange
      const currentName = 'existing-file.txt';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RenameDialog(
              currentName: currentName,
            ),
          ),
        ),
      );

      // Assert
      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.controller?.text, equals(currentName));
    });

    testWidgets('should display current name as informational text',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RenameDialog(
              currentName: 'readme.md',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Current name: readme.md'), findsOneWidget);
    });

    testWidgets('should have Cancel and Rename buttons', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RenameDialog(
              currentName: 'test.dart',
            ),
          ),
        ),
      );

      // Assert
      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Rename'), findsOneWidget);
    });

    testWidgets('should return null when Cancel is pressed', (tester) async {
      // Arrange
      String? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<String>(
                    context: context,
                    builder: (context) => const RenameDialog(
                      currentName: 'old.dart',
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
      expect(dialogResult, isNull);
    });

    testWidgets('should validate empty new name', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RenameDialog(
              currentName: 'old.dart',
            ),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextFormField), '');
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Name cannot be empty'), findsOneWidget);
    });

    testWidgets('should validate name with slashes', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RenameDialog(
              currentName: 'old.dart',
            ),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextFormField), 'folder/file.dart');
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Name cannot contain slashes'), findsOneWidget);
    });

    testWidgets('should validate name with backslashes', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RenameDialog(
              currentName: 'old.dart',
            ),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextFormField), 'folder\\file.dart');
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Name cannot contain slashes'), findsOneWidget);
    });

    testWidgets('should validate name length', (tester) async {
      // Arrange
      final longName = 'a' * 256;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RenameDialog(
              currentName: 'old.dart',
            ),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextFormField), longName);
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Name too long (max 255 characters)'), findsOneWidget);
    });

    testWidgets('should return new name when changed', (tester) async {
      // Arrange
      String? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<String>(
                    context: context,
                    builder: (context) => const RenameDialog(
                      currentName: 'old-name.dart',
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextFormField), 'new-name.dart');
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      // Assert
      expect(dialogResult, equals('new-name.dart'));
    });

    testWidgets('should return null when name is unchanged', (tester) async {
      // Arrange
      const currentName = 'unchanged.dart';
      String? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<String>(
                    context: context,
                    builder: (context) => const RenameDialog(
                      currentName: currentName,
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Act - Keep the same name
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      // Assert
      expect(dialogResult, isNull);
    });

    testWidgets('should trim whitespace from new name', (tester) async {
      // Arrange
      String? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<String>(
                    context: context,
                    builder: (context) => const RenameDialog(
                      currentName: 'old.dart',
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextFormField), '  new.dart  ');
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      // Assert
      expect(dialogResult, equals('new.dart'));
    });

    testWidgets('should submit on Enter key press', (tester) async {
      // Arrange
      String? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<String>(
                    context: context,
                    builder: (context) => const RenameDialog(
                      currentName: 'old.md',
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextFormField), 'new.md');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Assert
      expect(dialogResult, equals('new.md'));
    });

    testWidgets('should autofocus on text input field', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RenameDialog(
              currentName: 'test.dart',
            ),
          ),
        ),
      );

      // Assert
      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.autofocus, isTrue);
    });

    testWidgets('should dispose controller on widget disposal', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RenameDialog(
              currentName: 'test.dart',
            ),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      // Assert
      expect(tester.takeException(), isNull);
    });

    testWidgets('should work with dark theme', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: RenameDialog(
              currentName: 'test.dart',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Rename item'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle renaming with various file extensions',
        (tester) async {
      // Arrange
      final testCases = {
        'old.dart': 'new.dart',
        'readme.md': 'README.MD',
        'index.html': 'main.html',
        'app.js': 'index.js',
      };

      for (final entry in testCases.entries) {
        String? dialogResult;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    dialogResult = await showDialog<String>(
                      context: context,
                      builder: (context) => RenameDialog(
                        currentName: entry.key,
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Act
        await tester.enterText(find.byType(TextFormField), entry.value);
        await tester.tap(find.text('Rename'));
        await tester.pumpAndSettle();

        // Assert
        expect(dialogResult, equals(entry.value),
            reason: 'Should rename ${entry.key} to ${entry.value}');
      }
    });

    testWidgets('should handle maximum valid name length', (tester) async {
      // Arrange
      final validLongName = 'a' * 255;
      String? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<String>(
                    context: context,
                    builder: (context) => const RenameDialog(
                      currentName: 'short.txt',
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextFormField), validLongName);
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      // Assert
      expect(dialogResult, equals(validLongName));
    });
  });
}
