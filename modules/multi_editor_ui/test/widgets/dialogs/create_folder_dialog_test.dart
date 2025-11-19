import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_ui/src/widgets/dialogs/create_folder_dialog.dart';

void main() {
  group('CreateFolderDialog', () {
    testWidgets('should render with title and form', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreateFolderDialog(),
          ),
        ),
      );

      // Assert
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Create New Folder'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('should have folder name input field', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreateFolderDialog(),
          ),
        ),
      );

      // Assert
      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.decoration?.labelText, equals('Folder name'));
      expect(textField.decoration?.hintText, equals('my-folder'));
      expect(textField.autofocus, isTrue);
    });

    testWidgets('should have Cancel and Create buttons', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreateFolderDialog(),
          ),
        ),
      );

      // Assert
      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Create'), findsOneWidget);
    });

    testWidgets('should return null when Cancel is pressed', (tester) async {
      // Arrange
      Map<String, dynamic>? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => const CreateFolderDialog(),
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

    testWidgets('should validate empty folder name', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreateFolderDialog(),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Folder name cannot be empty'), findsOneWidget);
    });

    testWidgets('should validate folder name with slashes', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreateFolderDialog(),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextFormField), 'parent/child');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Folder name cannot contain slashes'), findsOneWidget);
    });

    testWidgets('should validate folder name with backslashes',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreateFolderDialog(),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextFormField), 'parent\\child');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Folder name cannot contain slashes'), findsOneWidget);
    });

    testWidgets('should validate folder name length', (tester) async {
      // Arrange
      final longName = 'a' * 256;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreateFolderDialog(),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextFormField), longName);
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('Folder name too long (max 255 characters)'),
        findsOneWidget,
      );
    });

    testWidgets('should submit valid folder name with no parent',
        (tester) async {
      // Arrange
      Map<String, dynamic>? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => const CreateFolderDialog(),
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
      await tester.enterText(find.byType(TextFormField), 'src');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Assert
      expect(dialogResult, isNotNull);
      expect(dialogResult!['name'], equals('src'));
      expect(dialogResult['parentId'], isNull);
    });

    testWidgets('should submit with custom parent folder', (tester) async {
      // Arrange
      Map<String, dynamic>? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => const CreateFolderDialog(
                      initialParentFolderId: 'folder-456',
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
      await tester.enterText(find.byType(TextFormField), 'components');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Assert
      expect(dialogResult, isNotNull);
      expect(dialogResult!['name'], equals('components'));
      expect(dialogResult['parentId'], equals('folder-456'));
    });

    testWidgets('should trim whitespace from folder name', (tester) async {
      // Arrange
      Map<String, dynamic>? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => const CreateFolderDialog(),
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
      await tester.enterText(find.byType(TextFormField), '  lib  ');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Assert
      expect(dialogResult!['name'], equals('lib'));
    });

    testWidgets('should submit on Enter key press', (tester) async {
      // Arrange
      Map<String, dynamic>? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => const CreateFolderDialog(),
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
      await tester.enterText(find.byType(TextFormField), 'test');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Assert
      expect(dialogResult, isNotNull);
      expect(dialogResult!['name'], equals('test'));
    });

    testWidgets('should accept various folder naming conventions',
        (tester) async {
      // Arrange
      final folderNames = [
        'src',
        'lib',
        'test',
        'components',
        'my-folder',
        'my_folder',
        'MyFolder',
        'folder123',
        '.hidden',
      ];

      for (final folderName in folderNames) {
        Map<String, dynamic>? dialogResult;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    dialogResult = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (context) => const CreateFolderDialog(),
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
        await tester.enterText(find.byType(TextFormField), folderName);
        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        // Assert
        expect(dialogResult!['name'], equals(folderName),
            reason: 'Should accept $folderName');
      }
    });

    testWidgets('should dispose controller on widget disposal', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreateFolderDialog(),
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
            body: CreateFolderDialog(),
          ),
        ),
      );

      // Assert
      expect(find.text('Create New Folder'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle maximum valid folder name length',
        (tester) async {
      // Arrange
      final validLongName = 'a' * 255;
      Map<String, dynamic>? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => const CreateFolderDialog(),
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
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Assert
      expect(dialogResult, isNotNull);
      expect(dialogResult!['name'], equals(validLongName));
    });
  });
}
