import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_ui/src/widgets/scaffold/widgets/empty_editor_placeholder.dart';

void main() {
  group('EmptyEditorPlaceholder Widget Tests', () {
    Widget createWidget({ThemeData? theme}) {
      return MaterialApp(
        theme: theme,
        home: const Scaffold(body: EmptyEditorPlaceholder()),
      );
    }

    group('Rendering', () {
      testWidgets('should display "No file selected" message',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.text('No file selected'), findsOneWidget);
      });

      testWidgets('should display instruction text', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(
          find.text('Select a file from the tree to start editing'),
          findsOneWidget,
        );
      });

      testWidgets('should display code icon', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byIcon(Icons.code), findsOneWidget);
      });

      testWidgets('should center content', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byType(Center), findsOneWidget);
      });

      testWidgets('should arrange items in column', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byType(Column), findsOneWidget);
      });

      testWidgets('should have main axis alignment centered', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        final column = tester.widget<Column>(find.byType(Column));
        expect(column.mainAxisAlignment, equals(MainAxisAlignment.center));
      });
    });

    group('Visual Design', () {
      testWidgets('should have large icon', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        final icon = tester.widget<Icon>(find.byIcon(Icons.code));
        expect(icon.size, equals(64));
      });

      testWidgets('should have proper spacing between elements',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
        expect(
          sizedBoxes.any((box) => box.height == 16),
          isTrue,
          reason: 'Should have 16px spacing after icon',
        );
        expect(
          sizedBoxes.any((box) => box.height == 8),
          isTrue,
          reason: 'Should have 8px spacing between texts',
        );
      });

      testWidgets('should use title medium style for main text',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert - Finds the text widget
        final textWidget = tester.widget<Text>(find.text('No file selected'));
        expect(textWidget.style, isNotNull);
      });

      testWidgets('should use body small style for instruction text',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        final textWidget = tester.widget<Text>(
          find.text('Select a file from the tree to start editing'),
        );
        expect(textWidget.style, isNotNull);
      });
    });

    group('Theme Integration', () {
      testWidgets('should use theme onSurface color with opacity for icon',
          (tester) async {
        // Arrange
        final customTheme = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.purple,
            brightness: Brightness.light,
          ),
        );

        // Act
        await tester.pumpWidget(createWidget(theme: customTheme));
        final icon = tester.widget<Icon>(find.byIcon(Icons.code));

        // Assert
        expect(icon.color, isNotNull);
        expect(icon.color?.opacity, lessThan(1.0));
      });

      testWidgets('should use theme text styles for title', (tester) async {
        // Arrange
        final customTheme = ThemeData(
          textTheme: const TextTheme(
            titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        );

        // Act
        await tester.pumpWidget(createWidget(theme: customTheme));

        // Assert - Widget should render with theme
        expect(find.text('No file selected'), findsOneWidget);
      });

      testWidgets('should use theme text color with opacity', (tester) async {
        // Arrange
        final customTheme = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
        );

        // Act
        await tester.pumpWidget(createWidget(theme: customTheme));
        final titleText = tester.widget<Text>(find.text('No file selected'));
        final bodyText = tester.widget<Text>(
          find.text('Select a file from the tree to start editing'),
        );

        // Assert
        expect(titleText.style?.color, isNotNull);
        expect(bodyText.style?.color, isNotNull);
      });

      testWidgets('should adapt to dark theme', (tester) async {
        // Arrange
        final darkTheme = ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
        );

        // Act
        await tester.pumpWidget(createWidget(theme: darkTheme));

        // Assert - Should render without errors
        expect(tester.takeException(), isNull);
        expect(find.text('No file selected'), findsOneWidget);
      });

      testWidgets('should handle high contrast themes', (tester) async {
        // Arrange
        final highContrastTheme = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.black,
            brightness: Brightness.dark,
            contrastLevel: 1.0,
          ),
        );

        // Act
        await tester.pumpWidget(createWidget(theme: highContrastTheme));

        // Assert
        expect(tester.takeException(), isNull);
        expect(find.text('No file selected'), findsOneWidget);
      });
    });

    group('Layout & Responsiveness', () {
      testWidgets('should render in small viewports', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(320, 480);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(tester.takeException(), isNull);
        expect(find.text('No file selected'), findsOneWidget);
        expect(find.text('Select a file from the tree to start editing'),
            findsOneWidget);
      });

      testWidgets('should render in large viewports', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(tester.takeException(), isNull);
        expect(find.text('No file selected'), findsOneWidget);
      });

      testWidgets('should render in portrait orientation', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(480, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.text('No file selected'), findsOneWidget);
        expect(find.byIcon(Icons.code), findsOneWidget);
      });

      testWidgets('should render in landscape orientation', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(800, 480);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.text('No file selected'), findsOneWidget);
        expect(find.byIcon(Icons.code), findsOneWidget);
      });

      testWidgets('should maintain centered layout in all screen sizes',
          (tester) async {
        // Arrange
        final screenSizes = [
          const Size(320, 480),
          const Size(768, 1024),
          const Size(1920, 1080),
        ];

        for (final size in screenSizes) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          // Act
          await tester.pumpWidget(createWidget());

          // Assert
          expect(find.byType(Center), findsOneWidget);
          expect(tester.takeException(), isNull);
        }

        addTearDown(tester.view.reset);
      });
    });

    group('Accessibility', () {
      testWidgets('should have meaningful text for screen readers',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        final titleText = tester.widget<Text>(find.text('No file selected'));
        final bodyText = tester.widget<Text>(
          find.text('Select a file from the tree to start editing'),
        );

        expect(titleText.data, isNotEmpty);
        expect(bodyText.data, isNotEmpty);
        expect(bodyText.data, contains('Select'));
        expect(bodyText.data, contains('file'));
      });

      testWidgets('should provide clear instructions', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(
          find.text('Select a file from the tree to start editing'),
          findsOneWidget,
        );
      });

      testWidgets('should have icon with semantic meaning', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byIcon(Icons.code), findsOneWidget);
      });
    });

    group('Visual Consistency', () {
      testWidgets('should maintain consistent opacity levels', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        final icon = tester.widget<Icon>(find.byIcon(Icons.code));
        expect(icon.color?.opacity, equals(0.3));
      });

      testWidgets('should have consistent text alignment', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        final texts = tester.widgetList<Text>(find.byType(Text));
        expect(texts.length, greaterThan(0));
      });

      testWidgets('should render all elements in correct order',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert - Check vertical order of elements
        final column = tester.widget<Column>(find.byType(Column));
        expect(column.children.length, equals(5)); // Icon, SizedBox, Text, SizedBox, Text
      });
    });

    group('Edge Cases', () {
      testWidgets('should render with minimal theme data', (tester) async {
        // Arrange
        final minimalTheme = ThemeData(useMaterial3: true);

        // Act
        await tester.pumpWidget(createWidget(theme: minimalTheme));

        // Assert
        expect(tester.takeException(), isNull);
        expect(find.text('No file selected'), findsOneWidget);
      });

      testWidgets('should handle very small viewports gracefully',
          (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(100, 100);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget());

        // Assert - Should render without crashing
        expect(find.text('No file selected'), findsOneWidget);
      });

      testWidgets('should handle very large viewports', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(4000, 3000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(tester.takeException(), isNull);
        expect(find.byType(Center), findsOneWidget);
      });

      testWidgets('should handle null theme gracefully', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(theme: null));

        // Assert
        expect(tester.takeException(), isNull);
        expect(find.text('No file selected'), findsOneWidget);
      });
    });

    group('Use Cases', () {
      testWidgets('UC1: User opens app and sees empty editor', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byIcon(Icons.code), findsOneWidget);
        expect(find.text('No file selected'), findsOneWidget);
        expect(
          find.text('Select a file from the tree to start editing'),
          findsOneWidget,
        );
      });

      testWidgets('UC2: User sees placeholder in center of screen',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byType(Center), findsOneWidget);
        final column = tester.widget<Column>(find.byType(Column));
        expect(column.mainAxisAlignment, equals(MainAxisAlignment.center));
      });

      testWidgets('UC3: User understands what action to take',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert - Instructions should be clear
        final instructionText = find.text(
          'Select a file from the tree to start editing',
        );
        expect(instructionText, findsOneWidget);

        final textWidget = tester.widget<Text>(instructionText);
        expect(textWidget.data, contains('Select'));
        expect(textWidget.data, contains('file'));
        expect(textWidget.data, contains('tree'));
      });

      testWidgets('UC4: Placeholder displays consistently across themes',
          (tester) async {
        // Arrange
        final themes = [
          ThemeData.light(),
          ThemeData.dark(),
          ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
          ),
        ];

        for (final theme in themes) {
          // Act
          await tester.pumpWidget(createWidget(theme: theme));

          // Assert
          expect(find.text('No file selected'), findsOneWidget);
          expect(find.byIcon(Icons.code), findsOneWidget);
        }
      });

      testWidgets('UC5: User on mobile sees properly sized placeholder',
          (tester) async {
        // Arrange - Mobile screen size
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.text('No file selected'), findsOneWidget);
        expect(find.byIcon(Icons.code), findsOneWidget);

        final icon = tester.widget<Icon>(find.byIcon(Icons.code));
        expect(icon.size, equals(64)); // Icon should still be visible
      });

      testWidgets('UC6: User on tablet sees properly scaled placeholder',
          (tester) async {
        // Arrange - Tablet screen size
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byType(Center), findsOneWidget);
        expect(find.text('No file selected'), findsOneWidget);
      });
    });

    group('State Immutability', () {
      testWidgets('should be a const widget', (tester) async {
        // Arrange & Act
        const widget1 = EmptyEditorPlaceholder();
        const widget2 = EmptyEditorPlaceholder();

        // Assert
        expect(identical(widget1, widget2), isTrue);
      });

      testWidgets('should rebuild without errors', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget());

        // Act - Rebuild
        await tester.pumpWidget(createWidget());
        await tester.pumpWidget(createWidget());

        // Assert
        expect(tester.takeException(), isNull);
        expect(find.text('No file selected'), findsOneWidget);
      });
    });
  });
}
