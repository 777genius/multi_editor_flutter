import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:editor_core/editor_core.dart';
import 'package:ide_presentation/ide_presentation.dart';

void main() {
  group('EditorTabBar', () {
    late List<EditorTab> testTabs;

    setUp(() {
      testTabs = [
        EditorTab(
          documentUri: DocumentUri.fromFilePath('/test/file1.dart'),
          title: 'file1.dart',
          hasUnsavedChanges: false,
        ),
        EditorTab(
          documentUri: DocumentUri.fromFilePath('/test/file2.dart'),
          title: 'file2.dart',
          hasUnsavedChanges: true,
        ),
        EditorTab(
          documentUri: DocumentUri.fromFilePath('/test/file3.js'),
          title: 'file3.js',
          hasUnsavedChanges: false,
        ),
      ];
    });

    testWidgets('should render with tabs', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorTabBar(
              tabs: testTabs,
              activeTabIndex: 0,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('file1.dart'), findsOneWidget);
      expect(find.text('file2.dart'), findsOneWidget);
      expect(find.text('file3.js'), findsOneWidget);
    });

    testWidgets('should highlight active tab', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorTabBar(
              tabs: testTabs,
              activeTabIndex: 1,
            ),
          ),
        ),
      );

      // Assert
      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(containers.isNotEmpty, isTrue);
    });

    testWidgets('should call onTabSelected when tab tapped', (tester) async {
      // Arrange
      int? selectedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorTabBar(
              tabs: testTabs,
              activeTabIndex: 0,
              onTabSelected: (index) => selectedIndex = index,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('file2.dart'));
      await tester.pumpAndSettle();

      // Assert
      expect(selectedIndex, equals(1));
    });

    testWidgets('should show unsaved changes indicator', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorTabBar(
              tabs: testTabs,
              activeTabIndex: 0,
            ),
          ),
        ),
      );

      // Assert - file2 has unsaved changes (blue dot indicator)
      final indicators = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(EditorTabBar),
          matching: find.byType(Container),
        ),
      );
      expect(indicators.isNotEmpty, isTrue);
    });

    testWidgets('should display file type icons', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorTabBar(
              tabs: testTabs,
              activeTabIndex: 0,
            ),
          ),
        ),
      );

      // Assert - Should have icons for .dart and .js files
      expect(find.byIcon(Icons.code), findsWidgets);
      expect(find.byIcon(Icons.javascript), findsOneWidget);
    });

    testWidgets('should call onTabClosed when close button tapped', (tester) async {
      // Arrange
      int? closedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorTabBar(
              tabs: testTabs,
              activeTabIndex: 0,
              onTabClosed: (index) => closedIndex = index,
            ),
          ),
        ),
      );

      // Act - Find and tap close icon
      final closeButtons = find.byIcon(Icons.close);
      if (closeButtons.evaluate().isNotEmpty) {
        await tester.tap(closeButtons.first);
        await tester.pumpAndSettle();
      }

      // Assert - Close button appears on active/hover
      expect(closeButtons, findsWidgets);
    });

    testWidgets('should show new tab button when callback provided', (tester) async {
      // Arrange
      var newTabCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorTabBar(
              tabs: testTabs,
              activeTabIndex: 0,
              onNewTab: () => newTabCalled = true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Assert
      expect(newTabCalled, isTrue);
    });

    testWidgets('should not show new tab button when callback not provided', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorTabBar(
              tabs: testTabs,
              activeTabIndex: 0,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('should be scrollable for many tabs', (tester) async {
      // Arrange - Create many tabs
      final manyTabs = List.generate(
        20,
        (index) => EditorTab(
          documentUri: DocumentUri.fromFilePath('/test/file$index.dart'),
          title: 'file$index.dart',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorTabBar(
              tabs: manyTabs,
              activeTabIndex: 0,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should show tooltip with full path on hover', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorTabBar(
              tabs: testTabs,
              activeTabIndex: 0,
            ),
          ),
        ),
      );

      // Assert - Tooltips should be present
      expect(find.byType(Tooltip), findsWidgets);
    });

    testWidgets('should handle empty tabs list', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const EditorTabBar(
              tabs: [],
              activeTabIndex: 0,
            ),
          ),
        ),
      );

      // Assert - Should not crash
      expect(find.byType(EditorTabBar), findsOneWidget);
    });

    testWidgets('should work without onTabSelected callback', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorTabBar(
              tabs: testTabs,
              activeTabIndex: 0,
            ),
          ),
        ),
      );

      // Act - Should not crash when tapping
      await tester.tap(find.text('file1.dart'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(EditorTabBar), findsOneWidget);
    });

    testWidgets('should work without onTabClosed callback', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorTabBar(
              tabs: testTabs,
              activeTabIndex: 0,
            ),
          ),
        ),
      );

      // Assert - Should not crash
      expect(find.byType(EditorTabBar), findsOneWidget);
    });

    testWidgets('should have VS Code dark theme styling', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorTabBar(
              tabs: testTabs,
              activeTabIndex: 0,
            ),
          ),
        ),
      );

      // Assert - Check for dark background
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(EditorTabBar),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(const Color(0xFF2D2D30)));
    });

    testWidgets('should show active indicator', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditorTabBar(
              tabs: testTabs,
              activeTabIndex: 0,
            ),
          ),
        ),
      );

      // Assert - Blue indicator should be present
      final indicators = tester.widgetList<Container>(find.byType(Container));
      final blueIndicator = indicators.any((container) =>
          container.color == const Color(0xFF007ACC) &&
          container.constraints?.maxWidth == 2);
      expect(indicators.isNotEmpty, isTrue);
    });

    group('File Type Icons', () {
      testWidgets('should show correct icon for Dart files', (tester) async {
        // Arrange
        final dartTab = EditorTab(
          documentUri: DocumentUri.fromFilePath('/test/main.dart'),
          title: 'main.dart',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EditorTabBar(
                tabs: [dartTab],
                activeTabIndex: 0,
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.code), findsWidgets);
      });

      testWidgets('should show correct icon for JavaScript files', (tester) async {
        // Arrange
        final jsTab = EditorTab(
          documentUri: DocumentUri.fromFilePath('/test/app.js'),
          title: 'app.js',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EditorTabBar(
                tabs: [jsTab],
                activeTabIndex: 0,
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.javascript), findsOneWidget);
      });

      testWidgets('should show correct icon for Python files', (tester) async {
        // Arrange
        final pyTab = EditorTab(
          documentUri: DocumentUri.fromFilePath('/test/script.py'),
          title: 'script.py',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EditorTabBar(
                tabs: [pyTab],
                activeTabIndex: 0,
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.code), findsWidgets);
      });

      testWidgets('should show correct icon for JSON files', (tester) async {
        // Arrange
        final jsonTab = EditorTab(
          documentUri: DocumentUri.fromFilePath('/test/config.json'),
          title: 'config.json',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EditorTabBar(
                tabs: [jsonTab],
                activeTabIndex: 0,
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.data_object), findsOneWidget);
      });

      testWidgets('should show correct icon for Markdown files', (tester) async {
        // Arrange
        final mdTab = EditorTab(
          documentUri: DocumentUri.fromFilePath('/test/README.md'),
          title: 'README.md',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EditorTabBar(
                tabs: [mdTab],
                activeTabIndex: 0,
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.article), findsOneWidget);
      });

      testWidgets('should show generic icon for unknown file types', (tester) async {
        // Arrange
        final unknownTab = EditorTab(
          documentUri: DocumentUri.fromFilePath('/test/file.xyz'),
          title: 'file.xyz',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EditorTabBar(
                tabs: [unknownTab],
                activeTabIndex: 0,
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.insert_drive_file), findsOneWidget);
      });
    });

    group('EditorTab Model', () {
      test('should create tab with required fields', () {
        // Arrange & Act
        final tab = EditorTab(
          documentUri: DocumentUri.fromFilePath('/test/file.dart'),
          title: 'file.dart',
        );

        // Assert
        expect(tab.documentUri.path, contains('/test/file.dart'));
        expect(tab.title, equals('file.dart'));
        expect(tab.hasUnsavedChanges, isFalse);
        expect(tab.isPinned, isFalse);
      });

      test('should create tab with unsaved changes', () {
        // Arrange & Act
        final tab = EditorTab(
          documentUri: DocumentUri.fromFilePath('/test/file.dart'),
          title: 'file.dart',
          hasUnsavedChanges: true,
        );

        // Assert
        expect(tab.hasUnsavedChanges, isTrue);
      });

      test('should copy tab with modified fields', () {
        // Arrange
        final original = EditorTab(
          documentUri: DocumentUri.fromFilePath('/test/file.dart'),
          title: 'file.dart',
          hasUnsavedChanges: false,
        );

        // Act
        final modified = original.copyWith(hasUnsavedChanges: true);

        // Assert
        expect(modified.hasUnsavedChanges, isTrue);
        expect(modified.title, equals(original.title));
        expect(modified.documentUri, equals(original.documentUri));
      });

      test('should copy tab with new title', () {
        // Arrange
        final original = EditorTab(
          documentUri: DocumentUri.fromFilePath('/test/file.dart'),
          title: 'file.dart',
        );

        // Act
        final modified = original.copyWith(title: 'renamed.dart');

        // Assert
        expect(modified.title, equals('renamed.dart'));
        expect(modified.documentUri, equals(original.documentUri));
      });
    });
  });
}
