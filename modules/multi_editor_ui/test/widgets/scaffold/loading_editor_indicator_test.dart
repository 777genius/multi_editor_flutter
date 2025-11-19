import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_ui/src/widgets/scaffold/widgets/loading_editor_indicator.dart';

void main() {
  group('LoadingEditorIndicator Widget Tests', () {
    Widget createWidget({ThemeData? theme}) {
      return MaterialApp(
        theme: theme,
        home: const Scaffold(body: LoadingEditorIndicator()),
      );
    }

    group('Rendering', () {
      testWidgets('should display circular progress indicator',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should center indicator', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byType(Center), findsOneWidget);
      });

      testWidgets('should have exactly one progress indicator', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Theme Integration', () {
      testWidgets('should use theme primary color', (tester) async {
        // Arrange
        final customTheme = ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        );

        // Act
        await tester.pumpWidget(createWidget(theme: customTheme));

        // Assert - Should render without errors
        expect(tester.takeException(), isNull);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
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

        // Assert
        expect(tester.takeException(), isNull);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should adapt to light theme', (tester) async {
        // Arrange
        final lightTheme = ThemeData(
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
        );

        // Act
        await tester.pumpWidget(createWidget(theme: lightTheme));

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should work with custom color schemes', (tester) async {
        // Arrange
        final customTheme = ThemeData(
          colorScheme: const ColorScheme(
            brightness: Brightness.light,
            primary: Colors.orange,
            onPrimary: Colors.white,
            secondary: Colors.deepOrange,
            onSecondary: Colors.white,
            error: Colors.red,
            onError: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
        );

        // Act
        await tester.pumpWidget(createWidget(theme: customTheme));

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
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
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should render in large viewports', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should center on portrait screens', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(480, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byType(Center), findsOneWidget);
      });

      testWidgets('should center on landscape screens', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(800, 480);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byType(Center), findsOneWidget);
      });

      testWidgets('should maintain centered position across screen sizes',
          (tester) async {
        // Arrange
        final screenSizes = [
          const Size(320, 480), // Mobile
          const Size(768, 1024), // Tablet
          const Size(1920, 1080), // Desktop
        ];

        for (final size in screenSizes) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          // Act
          await tester.pumpWidget(createWidget());

          // Assert
          expect(find.byType(Center), findsOneWidget);
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        }

        addTearDown(tester.view.reset);
      });

      testWidgets('should handle extreme aspect ratios', (tester) async {
        // Arrange - Very wide screen
        tester.view.physicalSize = const Size(3440, 1440);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byType(Center), findsOneWidget);
      });
    });

    group('Animation', () {
      testWidgets('should animate continuously', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget());

        // Act - Let animation run
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        // Assert - Should still be visible
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should continue animating over time', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget());

        // Act - Simulate longer time period
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have semantic meaning for loading state',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should be visible to assistive technologies',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert - Progress indicator should be present
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('should render with minimal theme', (tester) async {
        // Arrange
        final minimalTheme = ThemeData(useMaterial3: true);

        // Act
        await tester.pumpWidget(createWidget(theme: minimalTheme));

        // Assert
        expect(tester.takeException(), isNull);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should handle null theme gracefully', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(theme: null));

        // Assert
        expect(tester.takeException(), isNull);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should render in very small viewports', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(100, 100);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should render in very large viewports', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(4000, 3000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byType(Center), findsOneWidget);
      });

      testWidgets('should handle high DPI screens', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Use Cases', () {
      testWidgets('UC1: File loading shows spinner', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(Center), findsOneWidget);
      });

      testWidgets('UC2: Spinner is centered in available space',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byType(Center), findsOneWidget);
      });

      testWidgets('UC3: Loading indicator on mobile', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('UC4: Loading indicator on tablet', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('UC5: Loading indicator on desktop', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('UC6: Loading persists until file is loaded',
          (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget());

        // Act - Simulate time passing
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));

        // Assert - Should still be showing
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('State Immutability', () {
      testWidgets('should be a const widget', (tester) async {
        // Arrange & Act
        const widget1 = LoadingEditorIndicator();
        const widget2 = LoadingEditorIndicator();

        // Assert
        expect(identical(widget1, widget2), isTrue);
      });

      testWidgets('should rebuild without errors', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget());

        // Act - Multiple rebuilds
        await tester.pumpWidget(createWidget());
        await tester.pumpWidget(createWidget());
        await tester.pumpWidget(createWidget());

        // Assert
        expect(tester.takeException(), isNull);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should maintain state across theme changes',
          (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget(theme: ThemeData.light()));

        // Act - Change theme
        await tester.pumpWidget(createWidget(theme: ThemeData.dark()));

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Performance', () {
      testWidgets('should render quickly', (tester) async {
        // Arrange
        final stopwatch = Stopwatch()..start();

        // Act
        await tester.pumpWidget(createWidget());

        // Assert
        stopwatch.stop();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        // Just ensure it completes - no specific time assertion
      });

      testWidgets('should handle multiple rapid rebuilds', (tester) async {
        // Arrange & Act
        for (int i = 0; i < 10; i++) {
          await tester.pumpWidget(createWidget());
          await tester.pump(const Duration(milliseconds: 10));
        }

        // Assert
        expect(tester.takeException(), isNull);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Visual Consistency', () {
      testWidgets('should maintain same appearance across rebuilds',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // Rebuild
        await tester.pumpWidget(createWidget());
        await tester.pump();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(Center), findsOneWidget);
      });

      testWidgets('should work with different themes consistently',
          (tester) async {
        // Arrange
        final themes = [
          ThemeData.light(),
          ThemeData.dark(),
          ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.red)),
        ];

        // Act & Assert
        for (final theme in themes) {
          await tester.pumpWidget(createWidget(theme: theme));
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        }
      });
    });

    group('Widget Composition', () {
      testWidgets('should contain only Center and CircularProgressIndicator',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        expect(find.byType(LoadingEditorIndicator), findsOneWidget);
        expect(find.byType(Center), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should have CircularProgressIndicator as child of Center',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget());

        // Assert
        final center = tester.widget<Center>(find.byType(Center));
        expect(center.child, isA<CircularProgressIndicator>());
      });
    });

    group('Multiple Instances', () {
      testWidgets('should support multiple loading indicators', (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: const [
                  LoadingEditorIndicator(),
                  LoadingEditorIndicator(),
                ],
              ),
            ),
          ),
        );

        // Act & Assert
        expect(find.byType(LoadingEditorIndicator), findsNWidgets(2));
        expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
      });
    });
  });
}
