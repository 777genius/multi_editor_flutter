import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_ui/src/widgets/scaffold/widgets/dirty_changes_indicator.dart';

void main() {
  group('DirtyChangesIndicator Widget Tests', () {
    // Helper to create widget with optional theme
    Widget createWidget({
      VoidCallback? onSave,
      ThemeData? theme,
    }) {
      return MaterialApp(
        theme: theme,
        home: Scaffold(
          body: DirtyChangesIndicator(onSave: onSave ?? () {}),
        ),
      );
    }

    group('Rendering', () {
      testWidgets('should display unsaved changes message', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.text('You have unsaved changes'), findsOneWidget);
      });

      testWidgets('should display save button', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.text('Save'), findsOneWidget);
        expect(find.byType(TextButton), findsOneWidget);
      });

      testWidgets('should display info icon', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
        final icon = tester.widget<Icon>(find.byIcon(Icons.info_outline));
        expect(icon.size, equals(16));
      });

      testWidgets('should use Row layout with proper spacing', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byType(Row), findsOneWidget);
        final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
        expect(
          sizedBoxes.any((box) => box.width == 8),
          isTrue,
          reason: 'Should have 8px spacing between icon and text',
        );
      });

      testWidgets('should have spacer to push button to right',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byType(Spacer), findsOneWidget);
      });
    });

    group('Interactions', () {
      testWidgets('should call onSave when save button pressed',
          (tester) async {
        // Arrange
        var saveCalled = false;
        await tester.pumpWidget(
          createWidget(onSave: () => saveCalled = true),
        );

        // Act
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Assert
        expect(saveCalled, isTrue);
      });

      testWidgets('should call onSave only once per tap', (tester) async {
        // Arrange
        var saveCallCount = 0;
        await tester.pumpWidget(
          createWidget(onSave: () => saveCallCount++),
        );

        // Act
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Assert
        expect(saveCallCount, equals(1));
      });

      testWidgets('should handle rapid taps correctly', (tester) async {
        // Arrange
        var saveCallCount = 0;
        await tester.pumpWidget(
          createWidget(onSave: () => saveCallCount++),
        );

        // Act - Multiple rapid taps
        await tester.tap(find.text('Save'));
        await tester.pump(const Duration(milliseconds: 10));
        await tester.tap(find.text('Save'));
        await tester.pump(const Duration(milliseconds: 10));
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Assert
        expect(saveCallCount, equals(3));
      });
    });

    group('Theme Integration', () {
      testWidgets('should use primaryContainer color from theme',
          (tester) async {
        // Arrange
        final customTheme = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.purple,
            brightness: Brightness.light,
          ),
        );
        await tester.pumpWidget(createWidget(theme: customTheme));

        // Act
        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration as BoxDecoration;

        // Assert
        expect(
          decoration.color,
          equals(customTheme.colorScheme.primaryContainer),
        );
      });

      testWidgets('should use primary color for top border', (tester) async {
        // Arrange
        final customTheme = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.orange,
            brightness: Brightness.light,
          ),
        );
        await tester.pumpWidget(createWidget(theme: customTheme));

        // Act
        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration as BoxDecoration;
        final border = decoration.border as Border;

        // Assert
        expect(border.top.color, equals(customTheme.colorScheme.primary));
        expect(border.top.width, equals(2));
      });

      testWidgets('should use onPrimaryContainer for text and icon',
          (tester) async {
        // Arrange
        final customTheme = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
        );
        await tester.pumpWidget(createWidget(theme: customTheme));

        // Act
        final icon = tester.widget<Icon>(find.byIcon(Icons.info_outline));
        final text = tester.widget<Text>(find.text('You have unsaved changes'));

        // Assert
        expect(icon.color, equals(customTheme.colorScheme.onPrimaryContainer));
        expect(
          text.style?.color,
          equals(customTheme.colorScheme.onPrimaryContainer),
        );
      });

      testWidgets('should adapt to dark theme', (tester) async {
        // Arrange
        final darkTheme = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
        );
        await tester.pumpWidget(createWidget(theme: darkTheme));

        // Act
        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration as BoxDecoration;

        // Assert
        expect(decoration.color, equals(darkTheme.colorScheme.primaryContainer));
        expect(decoration.color, isNot(equals(Colors.white)));
      });
    });

    group('Visual Design & Layout', () {
      testWidgets('should have correct padding', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());
        final container = tester.widget<Container>(find.byType(Container));

        // Assert
        expect(
          container.padding,
          equals(const EdgeInsets.symmetric(horizontal: 16, vertical: 4)),
        );
      });

      testWidgets('should have primary container background', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());
        final container = tester.widget<Container>(find.byType(Container));

        // Assert
        expect(container.decoration, isNotNull);
        expect(container.decoration, isA<BoxDecoration>());
      });

      testWidgets('should have top border with correct width', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());
        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration as BoxDecoration;
        final border = decoration.border as Border;

        // Assert
        expect(border.top.width, equals(2));
      });

      testWidgets('should have correct text size', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());
        final text = tester.widget<Text>(find.text('You have unsaved changes'));

        // Assert
        expect(text.style?.fontSize, equals(12));
      });

      testWidgets('should maintain layout with long screen widths',
          (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(2000, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget());

        // Assert - Should still render without overflow
        expect(tester.takeException(), isNull);
        expect(find.text('You have unsaved changes'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have accessible text for screen readers',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        final text = tester.widget<Text>(find.text('You have unsaved changes'));
        expect(text.data, isNotEmpty);
        expect(text.data, contains('unsaved'));
      });

      testWidgets('should have tappable save button with sufficient size',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());
        final buttonFinder = find.byType(TextButton);
        final button = tester.widget<TextButton>(buttonFinder);

        // Assert - TextButton should be tappable
        expect(button.onPressed, isNotNull);

        // Check minimum tap target size
        final size = tester.getSize(buttonFinder);
        expect(size.height >= 48 || size.width >= 48, isTrue,
            reason: 'Button should meet minimum tap target size guidelines');
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle null onSave gracefully', (tester) async {
        // Arrange - Providing a no-op callback (required parameter)
        await tester.pumpWidget(createWidget(onSave: () {}));

        // Act
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Assert - Should not crash
        expect(tester.takeException(), isNull);
      });

      testWidgets('should render in narrow viewports without overflow',
          (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(300, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(tester.takeException(), isNull);
        expect(find.text('You have unsaved changes'), findsOneWidget);
      });

      testWidgets('should render in very narrow viewports', (tester) async {
        // Arrange - Extreme case
        tester.view.physicalSize = const Size(200, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget());

        // Assert - Should handle gracefully
        expect(find.text('You have unsaved changes'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
      });
    });

    group('Use Cases', () {
      testWidgets('UC1: User sees unsaved changes warning', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.text('You have unsaved changes'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });

      testWidgets('UC2: User clicks save from indicator', (tester) async {
        // Arrange
        var saved = false;
        await tester.pumpWidget(createWidget(onSave: () => saved = true));

        // Act
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // Assert
        expect(saved, isTrue);
      });

      testWidgets('UC3: Indicator persists until save action', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget());

        // Act - Wait for animations
        await tester.pumpAndSettle();

        // Assert - Indicator should still be visible
        expect(find.text('You have unsaved changes'), findsOneWidget);
      });

      testWidgets('UC4: Multiple unsaved indicators can exist', (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  DirtyChangesIndicator(onSave: () {}),
                  DirtyChangesIndicator(onSave: () {}),
                ],
              ),
            ),
          ),
        );

        // Act & Assert
        expect(find.text('You have unsaved changes'), findsNWidgets(2));
        expect(find.text('Save'), findsNWidgets(2));
      });
    });
  });
}
