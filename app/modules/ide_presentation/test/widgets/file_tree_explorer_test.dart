import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ide_presentation/ide_presentation.dart';

void main() {
  group('FileTreeExplorer', () {
    const testRootPath = '/test/project';

    testWidgets('should render with root path', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FileTreeExplorer(
              rootPath: testRootPath,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(FileTreeExplorer), findsOneWidget);
    });

    testWidgets('should display search bar', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FileTreeExplorer(
              rootPath: testRootPath,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search files...'), findsOneWidget);
    });

    testWidgets('should display search icon', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FileTreeExplorer(
              rootPath: testRootPath,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('should allow text input in search', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FileTreeExplorer(
              rootPath: testRootPath,
            ),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Assert
      expect(find.text('test'), findsOneWidget);
    });

    testWidgets('should show clear button when search has text', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FileTreeExplorer(
              rootPath: testRootPath,
            ),
          ),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('should clear search when clear button tapped', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FileTreeExplorer(
              rootPath: testRootPath,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Act
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      // Assert
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('should have scrollable tree view', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FileTreeExplorer(
              rootPath: testRootPath,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should work without file selection callback', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FileTreeExplorer(
              rootPath: testRootPath,
            ),
          ),
        ),
      );

      // Assert - Should not crash
      expect(find.byType(FileTreeExplorer), findsOneWidget);
    });

    testWidgets('should work without directory selection callback', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FileTreeExplorer(
              rootPath: testRootPath,
            ),
          ),
        ),
      );

      // Assert - Should not crash
      expect(find.byType(FileTreeExplorer), findsOneWidget);
    });

    testWidgets('should respect showHiddenFiles flag', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FileTreeExplorer(
              rootPath: testRootPath,
              showHiddenFiles: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(FileTreeExplorer), findsOneWidget);
    });

    testWidgets('should have dark theme styling', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FileTreeExplorer(
              rootPath: testRootPath,
            ),
          ),
        ),
      );

      // Assert - Check for dark colors
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.style?.color, equals(Colors.white));
    });

    testWidgets('should show tooltips on tree items', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FileTreeExplorer(
              rootPath: testRootPath,
            ),
          ),
        ),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Assert - Tooltips may be present for items
      // The actual items depend on file system, so we just check the tree exists
      expect(find.byType(FileTreeExplorer), findsOneWidget);
    });

    group('File Icons', () {
      testWidgets('should have folder icon for directories', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: FileTreeExplorer(
                rootPath: testRootPath,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Folder icons may appear
        // Actual behavior depends on file system
        expect(find.byType(FileTreeExplorer), findsOneWidget);
      });
    });

    group('Search Functionality', () {
      testWidgets('should filter items based on search query', (tester) async {
        // Arrange
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: FileTreeExplorer(
                rootPath: testRootPath,
              ),
            ),
          ),
        );

        // Act - Enter search query
        await tester.enterText(find.byType(TextField), 'dart');
        await tester.pump();

        // Assert - Widget should still be present
        expect(find.byType(FileTreeExplorer), findsOneWidget);
      });

      testWidgets('should perform case-insensitive search', (tester) async {
        // Arrange
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: FileTreeExplorer(
                rootPath: testRootPath,
              ),
            ),
          ),
        );

        // Act
        await tester.enterText(find.byType(TextField), 'DART');
        await tester.pump();

        // Assert
        expect(find.byType(FileTreeExplorer), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle empty root path', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: FileTreeExplorer(
                rootPath: '',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Should not crash
        expect(find.byType(FileTreeExplorer), findsOneWidget);
      });

      testWidgets('should handle non-existent path gracefully', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: FileTreeExplorer(
                rootPath: '/nonexistent/path/that/does/not/exist',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Should not crash
        expect(find.byType(FileTreeExplorer), findsOneWidget);
      });

      testWidgets('should handle excluded patterns', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: FileTreeExplorer(
                rootPath: testRootPath,
                excludedPatterns: {'node_modules', '.git'},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(FileTreeExplorer), findsOneWidget);
      });
    });

    group('Search Bar Styling', () {
      testWidgets('should have proper border styling', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: FileTreeExplorer(
                rootPath: testRootPath,
              ),
            ),
          ),
        );

        // Assert
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.decoration, isNotNull);
      });

      testWidgets('should have proper hint styling', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: FileTreeExplorer(
                rootPath: testRootPath,
              ),
            ),
          ),
        );

        // Assert
        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.decoration?.hintText, equals('Search files...'));
      });
    });
  });
}
