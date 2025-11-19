import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_ui/src/widgets/dialogs/create_file_dialog.dart';

void main() {
  group('CreateFileDialog', () {
    testWidgets('should render with title and form', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreateFileDialog(),
          ),
        ),
      );

      // Assert
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Create New File'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('should have file name input field', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreateFileDialog(),
          ),
        ),
      );

      // Assert
      expect(find.widgetWithText(TextFormField, 'example.dart'), findsOneWidget);
      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.decoration?.labelText, equals('File name'));
      expect(textField.autofocus, isTrue);
    });

    testWidgets('should have Cancel and Create buttons', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreateFileDialog(),
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
                    builder: (context) => const CreateFileDialog(),
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

    testWidgets('should validate empty file name', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreateFileDialog(),
          ),
        ),
      );

      // Act - Try to submit with empty name
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('File name cannot be empty'), findsOneWidget);
    });

    testWidgets('should validate file name with slashes', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreateFileDialog(),
          ),
        ),
      );

      // Act - Enter name with forward slash
      await tester.enterText(find.byType(TextFormField), 'folder/file.dart');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('File name cannot contain slashes'), findsOneWidget);
    });

    testWidgets('should validate file name with backslashes', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreateFileDialog(),
          ),
        ),
      );

      // Act - Enter name with backslash
      await tester.enterText(find.byType(TextFormField), 'folder\\file.dart');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('File name cannot contain slashes'), findsOneWidget);
    });

    testWidgets('should validate file name length', (tester) async {
      // Arrange
      final longName = 'a' * 256;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreateFileDialog(),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextFormField), longName);
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('File name too long (max 255 characters)'),
        findsOneWidget,
      );
    });

    testWidgets('should submit valid file name with default folder',
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
                    builder: (context) => const CreateFileDialog(),
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
      await tester.enterText(find.byType(TextFormField), 'main.dart');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Assert
      expect(dialogResult, isNotNull);
      expect(dialogResult!['name'], equals('main.dart'));
      expect(dialogResult['folderId'], equals('root'));
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
                    builder: (context) => const CreateFileDialog(
                      initialParentFolderId: 'folder-123',
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
      await tester.enterText(find.byType(TextFormField), 'config.json');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Assert
      expect(dialogResult, isNotNull);
      expect(dialogResult!['name'], equals('config.json'));
      expect(dialogResult['folderId'], equals('folder-123'));
    });

    testWidgets('should trim whitespace from file name', (tester) async {
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
                    builder: (context) => const CreateFileDialog(),
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
      await tester.enterText(find.byType(TextFormField), '  test.dart  ');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Assert
      expect(dialogResult!['name'], equals('test.dart'));
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
                    builder: (context) => const CreateFileDialog(),
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
      await tester.enterText(find.byType(TextFormField), 'readme.md');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Assert
      expect(dialogResult, isNotNull);
      expect(dialogResult!['name'], equals('readme.md'));
    });

    testWidgets('should accept various file extensions', (tester) async {
      // Arrange
      final fileNames = [
        'main.dart',
        'styles.css',
        'index.html',
        'package.json',
        'README.md',
        '.gitignore',
        'Dockerfile',
      ];

      for (final fileName in fileNames) {
        Map<String, dynamic>? dialogResult;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    dialogResult = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (context) => const CreateFileDialog(),
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
        await tester.enterText(find.byType(TextFormField), fileName);
        await tester.tap(find.text('Create'));
        await tester.pumpAndSettle();

        // Assert
        expect(dialogResult!['name'], equals(fileName),
            reason: 'Should accept $fileName');
      }
    });

    testWidgets('should dispose controller on widget disposal', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreateFileDialog(),
          ),
        ),
      );

      // Act - Pump new widget to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      // Assert - No exceptions thrown
      expect(tester.takeException(), isNull);
    });

    testWidgets('should work with dark theme', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: CreateFileDialog(),
          ),
        ),
      );

      // Assert
      expect(find.text('Create New File'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
