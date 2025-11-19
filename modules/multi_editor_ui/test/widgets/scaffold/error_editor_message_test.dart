import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_ui/src/widgets/scaffold/widgets/error_editor_message.dart';

void main() {
  group('ErrorEditorMessage Widget Tests', () {
    Widget createWidget({
      required String message,
      VoidCallback? onClose,
      ThemeData? theme,
    }) {
      return MaterialApp(
        theme: theme,
        home: Scaffold(
          body: ErrorEditorMessage(
            message: message,
            onClose: onClose ?? () {},
          ),
        ),
      );
    }

    group('Rendering', () {
      testWidgets('should display error message', (tester) async {
        // Arrange
        const errorMsg = 'Failed to load file';

        // Act
        await tester.pumpWidget(createWidget(message: errorMsg));

        // Assert
        expect(find.text(errorMsg), findsOneWidget);
      });

      testWidgets('should display error title', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(message: 'Test error'));

        // Assert
        expect(find.text('Error'), findsOneWidget);
      });

      testWidgets('should display error icon', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(message: 'Test error'));

        // Assert
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('should display go back button', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(message: 'Test error'));

        // Assert
        expect(find.text('Go back'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      });

      testWidgets('should use FilledButton.icon for go back button',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(message: 'Test error'));

        // Assert
        expect(find.byType(FilledButton), findsOneWidget);
      });

      testWidgets('should center all content', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(message: 'Test error'));

        // Assert
        expect(find.byType(Center), findsOneWidget);
      });

      testWidgets('should arrange elements in column', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(message: 'Test error'));

        // Assert
        expect(find.byType(Column), findsOneWidget);
        final column = tester.widget<Column>(find.byType(Column));
        expect(column.mainAxisAlignment, equals(MainAxisAlignment.center));
      });
    });

    group('Interactions', () {
      testWidgets('should call onClose when go back pressed', (tester) async {
        // Arrange
        var closeCalled = false;
        await tester.pumpWidget(
          createWidget(
            message: 'Test error',
            onClose: () => closeCalled = true,
          ),
        );

        // Act
        await tester.tap(find.text('Go back'));
        await tester.pumpAndSettle();

        // Assert
        expect(closeCalled, isTrue);
      });

      testWidgets('should call onClose only once per tap', (tester) async {
        // Arrange
        var closeCallCount = 0;
        await tester.pumpWidget(
          createWidget(
            message: 'Test error',
            onClose: () => closeCallCount++,
          ),
        );

        // Act
        await tester.tap(find.text('Go back'));
        await tester.pumpAndSettle();

        // Assert
        expect(closeCallCount, equals(1));
      });

      testWidgets('should handle rapid taps correctly', (tester) async {
        // Arrange
        var closeCallCount = 0;
        await tester.pumpWidget(
          createWidget(
            message: 'Test error',
            onClose: () => closeCallCount++,
          ),
        );

        // Act - Multiple rapid taps
        await tester.tap(find.text('Go back'));
        await tester.pump(const Duration(milliseconds: 10));
        await tester.tap(find.text('Go back'));
        await tester.pump(const Duration(milliseconds: 10));
        await tester.tap(find.text('Go back'));
        await tester.pumpAndSettle();

        // Assert
        expect(closeCallCount, equals(3));
      });
    });

    group('Theme Integration', () {
      testWidgets('should use theme error color for icon', (tester) async {
        // Arrange
        final customTheme = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.purple,
            error: Colors.red,
          ),
        );

        // Act
        await tester.pumpWidget(
          createWidget(message: 'Test', theme: customTheme),
        );
        final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));

        // Assert
        expect(icon.color, equals(customTheme.colorScheme.error));
      });

      testWidgets('should use theme error color for title text',
          (tester) async {
        // Arrange
        final customTheme = ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            error: Colors.orange,
          ),
        );

        // Act
        await tester.pumpWidget(
          createWidget(message: 'Test', theme: customTheme),
        );
        final text = tester.widget<Text>(find.text('Error'));

        // Assert
        expect(text.style?.color, equals(customTheme.colorScheme.error));
      });

      testWidgets('should use theme text styles for message', (tester) async {
        // Arrange
        final customTheme = ThemeData(
          textTheme: const TextTheme(
            bodySmall: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        );

        // Act
        await tester.pumpWidget(
          createWidget(message: 'Test error', theme: customTheme),
        );

        // Assert - Message should be displayed
        expect(find.text('Test error'), findsOneWidget);
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
        await tester.pumpWidget(
          createWidget(message: 'Test error', theme: darkTheme),
        );

        // Assert
        expect(tester.takeException(), isNull);
        expect(find.text('Error'), findsOneWidget);
      });

      testWidgets('should use theme for filled button', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(message: 'Test'));

        // Assert
        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNotNull);
      });
    });

    group('Visual Design', () {
      testWidgets('should have large error icon', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(message: 'Test'));

        // Assert
        final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
        expect(icon.size, equals(64));
      });

      testWidgets('should center content', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(message: 'Test'));

        // Assert
        expect(find.byType(Center), findsOneWidget);
      });

      testWidgets('should have proper padding', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(message: 'Test'));

        // Assert
        final padding = tester.widget<Padding>(find.byType(Padding).first);
        expect(padding.padding, equals(const EdgeInsets.all(24.0)));
      });

      testWidgets('should have proper spacing between elements',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(message: 'Test'));

        // Assert
        final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
        expect(
          sizedBoxes.any((box) => box.height == 16),
          isTrue,
          reason: 'Should have 16px spacing',
        );
        expect(
          sizedBoxes.any((box) => box.height == 8),
          isTrue,
          reason: 'Should have 8px spacing',
        );
      });

      testWidgets('should center align message text', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(message: 'Test error message'));

        // Assert
        final text = tester.widget<Text>(find.text('Test error message'));
        expect(text.textAlign, equals(TextAlign.center));
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle empty error message', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(message: ''));

        // Assert - Should render without error
        expect(tester.takeException(), isNull);
        expect(find.text('Error'), findsOneWidget);
        expect(find.text('Go back'), findsOneWidget);
      });

      testWidgets('should handle very long error messages', (tester) async {
        // Arrange
        const longMessage = 'This is a very long error message that might '
            'span multiple lines and needs to be displayed properly without '
            'causing layout issues or overflow problems in the UI. It should '
            'wrap correctly and remain readable.';

        // Act
        await tester.pumpWidget(createWidget(message: longMessage));

        // Assert
        expect(tester.takeException(), isNull);
        expect(find.text(longMessage), findsOneWidget);
      });

      testWidgets('should handle multiline error messages', (tester) async {
        // Arrange
        const multilineMessage = 'Error line 1\nError line 2\nError line 3';

        // Act
        await tester.pumpWidget(createWidget(message: multilineMessage));

        // Assert
        expect(find.text(multilineMessage), findsOneWidget);
      });

      testWidgets('should handle special characters in message',
          (tester) async {
        // Arrange
        const specialMessage = 'Error: file@path/特殊字符/emojis-😀.txt not found!';

        // Act
        await tester.pumpWidget(createWidget(message: specialMessage));

        // Assert
        expect(find.text(specialMessage), findsOneWidget);
      });

      testWidgets('should render in narrow viewports', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(300, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget(message: 'File not found'));

        // Assert
        expect(tester.takeException(), isNull);
        expect(find.text('Error'), findsOneWidget);
      });

      testWidgets('should render in wide viewports', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(2000, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget(message: 'File not found'));

        // Assert
        expect(find.byType(Center), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have meaningful error text', (tester) async {
        // Arrange
        const errorMsg = 'Failed to load file: permission denied';

        // Act
        await tester.pumpWidget(createWidget(message: errorMsg));

        // Assert
        expect(find.text(errorMsg), findsOneWidget);
        expect(find.text('Error'), findsOneWidget);
      });

      testWidgets('should have accessible back button', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(message: 'Test'));

        // Assert
        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNotNull);
        expect(find.text('Go back'), findsOneWidget);
      });

      testWidgets('should have semantic icon', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(message: 'Test'));

        // Assert
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });
    });

    group('Layout & Responsiveness', () {
      testWidgets('should maintain layout on small screens', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(320, 480);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(
          createWidget(message: 'File not found'),
        );

        // Assert
        expect(find.text('Error'), findsOneWidget);
        expect(find.text('File not found'), findsOneWidget);
        expect(find.text('Go back'), findsOneWidget);
      });

      testWidgets('should maintain layout on large screens', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget(message: 'Error occurred'));

        // Assert
        expect(find.byType(Center), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle different aspect ratios', (tester) async {
        // Arrange
        final aspectRatios = [
          const Size(400, 800), // Portrait
          const Size(800, 400), // Landscape
          const Size(600, 600), // Square
        ];

        for (final size in aspectRatios) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          // Act
          await tester.pumpWidget(createWidget(message: 'Error'));

          // Assert
          expect(find.byType(Center), findsOneWidget);
          expect(tester.takeException(), isNull);
        }

        addTearDown(tester.view.reset);
      });
    });

    group('Use Cases', () {
      testWidgets('UC1: File loading error displayed', (tester) async {
        // Arrange
        const error = 'File not found';

        // Act
        await tester.pumpWidget(createWidget(message: error));

        // Assert
        expect(find.text('Error'), findsOneWidget);
        expect(find.text(error), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Go back'), findsOneWidget);
      });

      testWidgets('UC2: User navigates back from error', (tester) async {
        // Arrange
        var navigatedBack = false;
        await tester.pumpWidget(
          createWidget(
            message: 'Error',
            onClose: () => navigatedBack = true,
          ),
        );

        // Act
        await tester.tap(find.text('Go back'));
        await tester.pumpAndSettle();

        // Assert
        expect(navigatedBack, isTrue);
      });

      testWidgets('UC3: Permission denied error displayed', (tester) async {
        // Arrange
        const error = 'Permission denied: Cannot read file';

        // Act
        await tester.pumpWidget(createWidget(message: error));

        // Assert
        expect(find.text(error), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('UC4: Network error displayed', (tester) async {
        // Arrange
        const error = 'Network error: Unable to fetch remote file';

        // Act
        await tester.pumpWidget(createWidget(message: error));

        // Assert
        expect(find.text(error), findsOneWidget);
        expect(find.text('Error'), findsOneWidget);
      });

      testWidgets('UC5: Parse error with technical details', (tester) async {
        // Arrange
        const error = 'Parse error at line 42: Unexpected token }';

        // Act
        await tester.pumpWidget(createWidget(message: error));

        // Assert
        expect(find.text(error), findsOneWidget);
        expect(find.byType(FilledButton), findsOneWidget);
      });

      testWidgets('UC6: User sees error on mobile device', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(
          createWidget(message: 'Mobile error occurred'),
        );

        // Assert
        expect(find.text('Mobile error occurred'), findsOneWidget);
        expect(find.text('Go back'), findsOneWidget);
        final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
        expect(icon.size, equals(64));
      });
    });

    group('State Consistency', () {
      testWidgets('should maintain consistent appearance across rebuilds',
          (tester) async {
        // Arrange
        const message = 'Consistent error';

        // Act - Multiple rebuilds
        await tester.pumpWidget(createWidget(message: message));
        await tester.pumpWidget(createWidget(message: message));
        await tester.pumpWidget(createWidget(message: message));

        // Assert
        expect(find.text('Error'), findsOneWidget);
        expect(find.text(message), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle message changes', (tester) async {
        // Arrange - Initial message
        await tester.pumpWidget(createWidget(message: 'Error 1'));
        expect(find.text('Error 1'), findsOneWidget);

        // Act - Change message
        await tester.pumpWidget(createWidget(message: 'Error 2'));

        // Assert
        expect(find.text('Error 1'), findsNothing);
        expect(find.text('Error 2'), findsOneWidget);
      });
    });

    group('Error Message Types', () {
      testWidgets('should display file not found error', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(message: 'File not found: example.dart'),
        );

        // Assert
        expect(find.text('File not found: example.dart'), findsOneWidget);
      });

      testWidgets('should display permission error', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(message: 'Permission denied'),
        );

        // Assert
        expect(find.text('Permission denied'), findsOneWidget);
      });

      testWidgets('should display generic error', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(message: 'An unexpected error occurred'),
        );

        // Assert
        expect(find.text('An unexpected error occurred'), findsOneWidget);
      });

      testWidgets('should display validation error', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(message: 'Invalid file format'),
        );

        // Assert
        expect(find.text('Invalid file format'), findsOneWidget);
      });
    });
  });
}
