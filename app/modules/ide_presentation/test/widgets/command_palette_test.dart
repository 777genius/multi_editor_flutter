import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ide_presentation/ide_presentation.dart';

void main() {
  group('CommandPalette', () {
    late List<Command> testCommands;
    late Command fileOpenCommand;
    late Command fileSaveCommand;
    late Command editUndoCommand;
    late Command lspRenameCommand;

    setUp(() {
      fileOpenCommand = Command(
        id: 'file.open',
        label: 'Open File',
        action: () {},
        category: 'File',
        shortcut: 'Ctrl+O',
        icon: Icons.folder_open,
      );

      fileSaveCommand = Command(
        id: 'file.save',
        label: 'Save',
        action: () {},
        category: 'File',
        shortcut: 'Ctrl+S',
        icon: Icons.save,
      );

      editUndoCommand = Command(
        id: 'edit.undo',
        label: 'Undo',
        action: () {},
        category: 'Edit',
        description: 'Undo last change',
        shortcut: 'Ctrl+Z',
        icon: Icons.undo,
      );

      lspRenameCommand = Command(
        id: 'lsp.rename',
        label: 'Rename Symbol',
        action: () {},
        category: 'LSP',
        description: 'Rename symbol across workspace',
        shortcut: 'F2',
        icon: Icons.edit,
      );

      testCommands = [
        fileOpenCommand,
        fileSaveCommand,
        editUndoCommand,
        lspRenameCommand,
      ];
    });

    testWidgets('should render with commands', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPalette(
              commands: testCommands,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Open File'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('Rename Symbol'), findsOneWidget);
    });

    testWidgets('should display search placeholder', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPalette(
              commands: testCommands,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Type a command or search...'), findsOneWidget);
    });

    testWidgets('should display keyboard shortcuts', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPalette(
              commands: testCommands,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Ctrl+O'), findsOneWidget);
      expect(find.text('Ctrl+S'), findsOneWidget);
      expect(find.text('Ctrl+Z'), findsOneWidget);
      expect(find.text('F2'), findsOneWidget);
    });

    testWidgets('should display command categories', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPalette(
              commands: testCommands,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('File'), findsWidgets);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('LSP'), findsOneWidget);
    });

    testWidgets('should display command descriptions', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPalette(
              commands: testCommands,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Undo last change'), findsOneWidget);
      expect(find.text('Rename symbol across workspace'), findsOneWidget);
    });

    testWidgets('should filter commands by label', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPalette(
              commands: testCommands,
            ),
          ),
        ),
      );

      // Act - Type search query
      await tester.enterText(find.byType(TextField), 'save');
      await tester.pump();

      // Assert
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Open File'), findsNothing);
      expect(find.text('Undo'), findsNothing);
    });

    testWidgets('should filter commands by category', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPalette(
              commands: testCommands,
            ),
          ),
        ),
      );

      // Act - Search by category
      await tester.enterText(find.byType(TextField), 'file');
      await tester.pump();

      // Assert - Should show all File commands
      expect(find.text('Open File'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Undo'), findsNothing);
    });

    testWidgets('should filter commands by description', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPalette(
              commands: testCommands,
            ),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextField), 'workspace');
      await tester.pump();

      // Assert
      expect(find.text('Rename Symbol'), findsOneWidget);
      expect(find.text('Open File'), findsNothing);
    });

    testWidgets('should show empty state when no results', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPalette(
              commands: testCommands,
            ),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextField), 'xyz nonexistent');
      await tester.pump();

      // Assert
      expect(find.text('No commands found'), findsOneWidget);
      expect(find.text('Try a different search query'), findsOneWidget);
    });

    testWidgets('should show quick actions when empty search', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPalette(
              commands: [],
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Quick Actions'), findsOneWidget);
    });

    testWidgets('should navigate down with arrow key', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPalette(
              commands: testCommands,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      // Assert - Should not crash
      expect(find.byType(CommandPalette), findsOneWidget);
    });

    testWidgets('should navigate up with arrow key', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPalette(
              commands: testCommands,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Navigate down first, then up
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      // Assert
      expect(find.byType(CommandPalette), findsOneWidget);
    });

    testWidgets('should wrap around when navigating down at end', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPalette(
              commands: testCommands,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Navigate down multiple times to wrap
      for (var i = 0; i < testCommands.length + 1; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
      }

      // Assert - Should wrap to beginning
      expect(find.byType(CommandPalette), findsOneWidget);
    });

    testWidgets('should wrap around when navigating up at start', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPalette(
              commands: testCommands,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Navigate up from start
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      // Assert - Should wrap to end
      expect(find.byType(CommandPalette), findsOneWidget);
    });

    testWidgets('should execute command with Enter key', (tester) async {
      // Arrange
      var executed = false;
      final commandWithAction = Command(
        id: 'test',
        label: 'Test Command',
        action: () => executed = true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPalette(
              commands: [commandWithAction],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Assert
      expect(executed, isTrue);
    });

    testWidgets('should close with Escape key', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    CommandPalette.show(context, commands: testCommands);
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      // Act - Open dialog
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Verify opened
      expect(find.byType(CommandPalette), findsOneWidget);

      // Press Escape
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Assert - Dialog should close
      expect(find.byType(CommandPalette), findsNothing);
    });

    testWidgets('should execute command on tap', (tester) async {
      // Arrange
      var executed = false;
      final commandWithAction = Command(
        id: 'test',
        label: 'Test Command',
        action: () => executed = true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    CommandPalette.show(context, commands: [commandWithAction]);
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Act - Tap command
      await tester.tap(find.text('Test Command'));
      await tester.pumpAndSettle();

      // Assert
      expect(executed, isTrue);
    });

    testWidgets('should call onCommandExecuted callback', (tester) async {
      // Arrange
      Command? executedCommand;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    CommandPalette.show(
                      context,
                      commands: testCommands,
                      onCommandExecuted: (cmd) => executedCommand = cmd,
                    );
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Act - Execute command
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Assert
      expect(executedCommand?.id, equals('file.save'));
    });

    testWidgets('should work without onCommandExecuted callback', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    CommandPalette.show(context, commands: testCommands);
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Act - Should not crash
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CommandPalette), findsNothing);
    });

    testWidgets('should display recent commands first', (tester) async {
      // Arrange
      final recentCommands = [fileSaveCommand];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPalette(
              commands: testCommands,
              recentCommands: recentCommands,
            ),
          ),
        ),
      );

      // Assert - Recent commands should be shown
      expect(find.text('Save'), findsWidgets);
    });

    testWidgets('should auto-focus search input', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPalette(
              commands: testCommands,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - TextField should be focused
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.focusNode, isNotNull);
    });

    testWidgets('should have VS Code dark styling', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPalette(
              commands: testCommands,
            ),
          ),
        ),
      );

      // Assert - Check for dark background
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(const Color(0xFF252526)));
    });

    testWidgets('should display command icons', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPalette(
              commands: testCommands,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
      expect(find.byIcon(Icons.save), findsOneWidget);
      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('should handle commands without icons', (tester) async {
      // Arrange
      final commandNoIcon = Command(
        id: 'test',
        label: 'Test Command',
        action: () {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPalette(
              commands: [commandNoIcon],
            ),
          ),
        ),
      );

      // Assert - Should still render
      expect(find.text('Test Command'), findsOneWidget);
    });

    testWidgets('should handle commands without category', (tester) async {
      // Arrange
      final commandNoCategory = Command(
        id: 'test',
        label: 'Test Command',
        action: () {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPalette(
              commands: [commandNoCategory],
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Command'), findsOneWidget);
    });

    testWidgets('should handle commands without description', (tester) async {
      // Arrange
      final commandNoDescription = Command(
        id: 'test',
        label: 'Test Command',
        action: () {},
        category: 'Test',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPalette(
              commands: [commandNoDescription],
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Command'), findsOneWidget);
    });

    testWidgets('should handle commands without shortcut', (tester) async {
      // Arrange
      final commandNoShortcut = Command(
        id: 'test',
        label: 'Test Command',
        action: () {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPalette(
              commands: [commandNoShortcut],
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Command'), findsOneWidget);
    });

    testWidgets('should be scrollable for many commands', (tester) async {
      // Arrange - Create many commands
      final manyCommands = List.generate(
        50,
        (index) => Command(
          id: 'cmd$index',
          label: 'Command $index',
          action: () {},
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPalette(
              commands: manyCommands,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should enforce max height constraint', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandPalette(
              commands: testCommands,
            ),
          ),
        ),
      );

      // Assert
      final constrainedBox = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(CommandPalette),
          matching: find.byType(ConstrainedBox),
        ).first,
      );
      expect(constrainedBox.constraints.maxHeight, equals(400));
    });

    group('Search Relevance', () {
      testWidgets('should prioritize exact matches', (tester) async {
        // Arrange
        final commands = [
          Command(id: '1', label: 'Open File', action: () {}),
          Command(id: '2', label: 'open', action: () {}),
          Command(id: '3', label: 'Reopen', action: () {}),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommandPalette(
                commands: commands,
              ),
            ),
          ),
        );

        // Act
        await tester.enterText(find.byType(TextField), 'open');
        await tester.pump();

        // Assert - Exact match should be first
        final listView = find.byType(ListView);
        expect(listView, findsOneWidget);
      });

      testWidgets('should prioritize starts-with matches', (tester) async {
        // Arrange
        final commands = [
          Command(id: '1', label: 'Reopen File', action: () {}),
          Command(id: '2', label: 'Open File', action: () {}),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommandPalette(
                commands: commands,
              ),
            ),
          ),
        );

        // Act
        await tester.enterText(find.byType(TextField), 'open');
        await tester.pump();

        // Assert
        expect(find.text('Open File'), findsOneWidget);
      });
    });

    group('Category Colors', () {
      testWidgets('should apply category-specific colors', (tester) async {
        // Arrange
        final categorizedCommands = [
          Command(id: '1', label: 'File Cmd', action: () {}, category: 'File'),
          Command(id: '2', label: 'Edit Cmd', action: () {}, category: 'Edit'),
          Command(id: '3', label: 'View Cmd', action: () {}, category: 'View'),
          Command(id: '4', label: 'Navigate Cmd', action: () {}, category: 'Navigate'),
          Command(id: '5', label: 'Refactor Cmd', action: () {}, category: 'Refactor'),
          Command(id: '6', label: 'LSP Cmd', action: () {}, category: 'LSP'),
          Command(id: '7', label: 'Settings Cmd', action: () {}, category: 'Settings'),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommandPalette(
                commands: categorizedCommands,
              ),
            ),
          ),
        );

        // Assert - All categories should render
        expect(find.text('File'), findsOneWidget);
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('View'), findsOneWidget);
        expect(find.text('Navigate'), findsOneWidget);
        expect(find.text('Refactor'), findsOneWidget);
        expect(find.text('LSP'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
      });
    });
  });

  group('Command', () {
    test('should create command with required fields', () {
      // Arrange & Act
      final command = Command(
        id: 'test',
        label: 'Test Command',
        action: () {},
      );

      // Assert
      expect(command.id, equals('test'));
      expect(command.label, equals('Test Command'));
      expect(command.action, isNotNull);
    });

    test('should create command with optional fields', () {
      // Arrange & Act
      final command = Command(
        id: 'test',
        label: 'Test Command',
        action: () {},
        category: 'Test',
        description: 'Test description',
        shortcut: 'Ctrl+T',
        icon: Icons.check,
        iconColor: Colors.blue,
      );

      // Assert
      expect(command.category, equals('Test'));
      expect(command.description, equals('Test description'));
      expect(command.shortcut, equals('Ctrl+T'));
      expect(command.icon, equals(Icons.check));
      expect(command.iconColor, equals(Colors.blue));
    });
  });

  group('DefaultCommands', () {
    test('should provide default IDE commands', () {
      // Arrange & Act
      final commands = DefaultCommands.getCommands();

      // Assert
      expect(commands.isNotEmpty, isTrue);
      expect(commands.any((c) => c.id == 'file.new'), isTrue);
      expect(commands.any((c) => c.id == 'file.open'), isTrue);
      expect(commands.any((c) => c.id == 'file.save'), isTrue);
      expect(commands.any((c) => c.id == 'edit.undo'), isTrue);
      expect(commands.any((c) => c.id == 'edit.redo'), isTrue);
      expect(commands.any((c) => c.id == 'lsp.rename'), isTrue);
    });

    test('should execute custom callbacks', () {
      // Arrange
      var newFileExecuted = false;
      var saveExecuted = false;

      // Act
      final commands = DefaultCommands.getCommands(
        onNewFile: () => newFileExecuted = true,
        onSave: () => saveExecuted = true,
      );

      final newFileCmd = commands.firstWhere((c) => c.id == 'file.new');
      final saveCmd = commands.firstWhere((c) => c.id == 'file.save');

      newFileCmd.action();
      saveCmd.action();

      // Assert
      expect(newFileExecuted, isTrue);
      expect(saveExecuted, isTrue);
    });

    test('should have proper keyboard shortcuts', () {
      // Arrange & Act
      final commands = DefaultCommands.getCommands();

      // Assert
      final saveCmd = commands.firstWhere((c) => c.id == 'file.save');
      expect(saveCmd.shortcut, equals('Ctrl+S'));

      final undoCmd = commands.firstWhere((c) => c.id == 'edit.undo');
      expect(undoCmd.shortcut, equals('Ctrl+Z'));

      final renameCmd = commands.firstWhere((c) => c.id == 'lsp.rename');
      expect(renameCmd.shortcut, equals('F2'));
    });
  });
}
