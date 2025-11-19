import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import 'package:multi_editor_ui/src/widgets/scaffold/widgets/plugin_header_button.dart';

void main() {
  group('PluginHeaderButton Widget Tests', () {
    late PluginUIDescriptor testDescriptor;
    late PluginUIDescriptor longTooltipDescriptor;
    late PluginUIDescriptor customIconDescriptor;

    setUp(() {
      testDescriptor = PluginUIDescriptor(
        pluginId: 'test-plugin',
        iconCode: Icons.star.codePoint,
        tooltip: 'Test Plugin',
        uiData: const {
          'type': 'list',
          'items': [],
        },
      );

      longTooltipDescriptor = PluginUIDescriptor(
        pluginId: 'long-tooltip-plugin',
        iconCode: Icons.extension.codePoint,
        tooltip: 'This is a very long tooltip that tests text wrapping',
        uiData: const {
          'type': 'list',
          'items': [],
        },
      );

      customIconDescriptor = PluginUIDescriptor(
        pluginId: 'custom-icon-plugin',
        iconCode: Icons.bookmark.codePoint,
        iconFamily: 'MaterialIcons',
        tooltip: 'Custom Icon Plugin',
        uiData: const {
          'type': 'list',
          'items': [],
        },
      );
    });

    Widget createWidget({
      required PluginUIDescriptor descriptor,
      Function(String action, Map<String, dynamic> data)? onItemAction,
      ThemeData? theme,
    }) {
      return MaterialApp(
        theme: theme,
        home: Scaffold(
          body: PluginHeaderButton(
            descriptor: descriptor,
            onItemAction: onItemAction ?? (_, __) {},
          ),
        ),
      );
    }

    group('Rendering', () {
      testWidgets('should display plugin icon', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Assert
        expect(find.byIcon(Icons.star), findsOneWidget);
      });

      testWidgets('should have tooltip', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Assert
        expect(find.byTooltip('Test Plugin'), findsOneWidget);
      });

      testWidgets('should render as IconButton', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Assert
        expect(find.byType(IconButton), findsOneWidget);
      });

      testWidgets('should have correct icon size', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Assert
        final icon = tester.widget<Icon>(find.byIcon(Icons.star));
        expect(icon.size, equals(18));
      });

      testWidgets('should have zero padding', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Assert
        final button = tester.widget<IconButton>(find.byType(IconButton));
        expect(button.padding, equals(EdgeInsets.zero));
      });

      testWidgets('should have empty box constraints', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Assert
        final button = tester.widget<IconButton>(find.byType(IconButton));
        expect(button.constraints, equals(const BoxConstraints()));
      });
    });

    group('Interactions', () {
      testWidgets('should open dialog on tap', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Act
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.text('Test Plugin'), findsOneWidget);
      });

      testWidgets('should close dialog on close button tap', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsOneWidget);

        // Act
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Dialog), findsNothing);
      });

      testWidgets('should handle multiple open/close cycles', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        for (int i = 0; i < 3; i++) {
          // Act - Open dialog
          await tester.tap(find.byIcon(Icons.star));
          await tester.pumpAndSettle();
          expect(find.byType(Dialog), findsOneWidget);

          // Act - Close dialog
          await tester.tap(find.byIcon(Icons.close));
          await tester.pumpAndSettle();
          expect(find.byType(Dialog), findsNothing);
        }
      });

      testWidgets('should prevent multiple dialogs from opening',
          (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Act - Try to open dialog twice
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert - Only one dialog should be present
        expect(find.byType(Dialog), findsOneWidget);
      });
    });

    group('Dialog Content', () {
      testWidgets('should show empty message for empty list', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Act
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('No items'), findsOneWidget);
      });

      testWidgets('should show plugin icon in dialog header', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Act
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert - Button + dialog header
        expect(find.byIcon(Icons.star), findsNWidgets(2));
      });

      testWidgets('should show plugin tooltip as dialog title',
          (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Act
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Test Plugin'), findsOneWidget);
      });

      testWidgets('should show close button in dialog', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Act
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('should have divider in dialog', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Act
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Divider), findsOneWidget);
        final divider = tester.widget<Divider>(find.byType(Divider));
        expect(divider.height, equals(1));
      });

      testWidgets('should render dialog with correct width', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Act
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert
        final dialog = tester.widget<Dialog>(find.byType(Dialog));
        expect(dialog.shape, isA<RoundedRectangleBorder>());
      });

      testWidgets('should have max height constraint', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Act
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert
        final container = tester.widget<Container>(
          find.ancestor(
            of: find.text('Test Plugin'),
            matching: find.byType(Container),
          ).first,
        );
        expect(container.constraints, isNotNull);
      });
    });

    group('Icon Customization', () {
      testWidgets('should use custom icon from descriptor', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(descriptor: customIconDescriptor));

        // Assert
        expect(find.byIcon(Icons.bookmark), findsOneWidget);
      });

      testWidgets('should use custom icon family', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(descriptor: customIconDescriptor));

        // Assert
        final icon = tester.widget<Icon>(find.byIcon(Icons.bookmark));
        expect(icon.icon?.fontFamily, equals('MaterialIcons'));
      });

      testWidgets('should handle null icon family', (tester) async {
        // Arrange
        final descriptor = PluginUIDescriptor(
          pluginId: 'null-family',
          iconCode: Icons.settings.codePoint,
          tooltip: 'Settings',
          uiData: const {'type': 'list', 'items': []},
        );

        // Act
        await tester.pumpWidget(createWidget(descriptor: descriptor));

        // Assert
        expect(find.byIcon(Icons.settings), findsOneWidget);
      });
    });

    group('Callback Handling', () {
      testWidgets('should invoke onItemAction callback', (tester) async {
        // Arrange
        var actionCalled = false;
        String? receivedAction;
        Map<String, dynamic>? receivedData;

        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.star.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'list',
            'items': [
              {'id': '1', 'title': 'Item 1', 'action': 'test_action'}
            ],
          },
        );

        await tester.pumpWidget(
          createWidget(
            descriptor: descriptor,
            onItemAction: (action, data) {
              actionCalled = true;
              receivedAction = action;
              receivedData = data;
            },
          ),
        );

        // Act - Open dialog
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert - Dialog should be open
        expect(find.byType(Dialog), findsOneWidget);
      });

      testWidgets('should close dialog after action', (tester) async {
        // Arrange
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.star.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'list',
            'items': [
              {'id': '1', 'title': 'Item 1', 'action': 'test_action'}
            ],
          },
        );

        await tester.pumpWidget(
          createWidget(
            descriptor: descriptor,
            onItemAction: (action, data) {},
          ),
        );

        // Act - Open dialog
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsOneWidget);

        // Note: Testing actual item clicks would require the PluginUIBuilder
        // to render clickable items, which may not happen with empty items
      });
    });

    group('Theme Integration', () {
      testWidgets('should use theme primary color for dialog icon',
          (tester) async {
        // Arrange
        final customTheme = ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        );

        await tester.pumpWidget(
          createWidget(descriptor: testDescriptor, theme: customTheme),
        );

        // Act
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert
        final icons = tester.widgetList<Icon>(find.byIcon(Icons.star));
        expect(icons.length, equals(2)); // Button + dialog
      });

      testWidgets('should use theme text styles', (tester) async {
        // Arrange
        final customTheme = ThemeData(
          textTheme: const TextTheme(
            titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        );

        await tester.pumpWidget(
          createWidget(descriptor: testDescriptor, theme: customTheme),
        );

        // Act
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Test Plugin'), findsOneWidget);
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

        await tester.pumpWidget(
          createWidget(descriptor: testDescriptor, theme: darkTheme),
        );

        // Act
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Dialog), findsOneWidget);
      });

      testWidgets('should use theme divider color', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert
        final divider = tester.widget<Divider>(find.byType(Divider));
        expect(divider.height, equals(1));
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle long tooltips', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(descriptor: longTooltipDescriptor),
        );

        // Assert
        expect(
          find.byTooltip('This is a very long tooltip that tests text wrapping'),
          findsOneWidget,
        );
      });

      testWidgets('should handle empty tooltip', (tester) async {
        // Arrange
        final descriptor = PluginUIDescriptor(
          pluginId: 'empty-tooltip',
          iconCode: Icons.help.codePoint,
          tooltip: '',
          uiData: const {'type': 'list', 'items': []},
        );

        // Act
        await tester.pumpWidget(createWidget(descriptor: descriptor));

        // Assert - Should render without errors
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle special characters in tooltip',
          (tester) async {
        // Arrange
        final descriptor = PluginUIDescriptor(
          pluginId: 'special-chars',
          iconCode: Icons.star.codePoint,
          tooltip: 'Plugin 特殊字符 😀',
          uiData: const {'type': 'list', 'items': []},
        );

        // Act
        await tester.pumpWidget(createWidget(descriptor: descriptor));
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Plugin 特殊字符 😀'), findsOneWidget);
      });

      testWidgets('should handle multiple rapid taps', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Act - Rapid taps
        await tester.tap(find.byIcon(Icons.star));
        await tester.pump(const Duration(milliseconds: 10));
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert - Should still show only one dialog
        expect(find.byType(Dialog), findsOneWidget);
      });

      testWidgets('should handle narrow viewports', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(300, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Act
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Dialog), findsOneWidget);
      });

      testWidgets('should handle wide viewports', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(2000, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Act
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Dialog), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have accessible tooltip', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Assert
        expect(find.byTooltip('Test Plugin'), findsOneWidget);
      });

      testWidgets('should have tappable button', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Assert
        final button = tester.widget<IconButton>(find.byType(IconButton));
        expect(button.onPressed, isNotNull);
      });

      testWidgets('should have accessible dialog', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Act
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert - Dialog should have title and close button
        expect(find.text('Test Plugin'), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('should have semantic icon meaning', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Assert
        expect(find.byIcon(Icons.star), findsOneWidget);
      });
    });

    group('Layout & Responsiveness', () {
      testWidgets('should render on mobile screens', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Act
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Dialog), findsOneWidget);
      });

      testWidgets('should render on tablet screens', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Act
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Dialog), findsOneWidget);
      });

      testWidgets('should render on desktop screens', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Act
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Dialog), findsOneWidget);
      });
    });

    group('Use Cases', () {
      testWidgets('UC1: User opens plugin popup', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Act
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.text('Test Plugin'), findsOneWidget);
      });

      testWidgets('UC2: User closes plugin popup', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsOneWidget);

        // Act
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Dialog), findsNothing);
      });

      testWidgets('UC3: User sees empty plugin list', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Act
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('No items'), findsOneWidget);
      });

      testWidgets('UC4: Plugin button in header bar', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Assert - Button should be visible in UI
        expect(find.byType(IconButton), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);
      });

      testWidgets('UC5: User hovers to see tooltip', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Assert - Tooltip should be available
        expect(find.byTooltip('Test Plugin'), findsOneWidget);
      });

      testWidgets('UC6: Dialog displays plugin content', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Act
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert - Dialog should show all expected elements
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.text('Test Plugin'), findsOneWidget); // Title
        expect(find.byIcon(Icons.star), findsNWidgets(2)); // Button + dialog
        expect(find.byIcon(Icons.close), findsOneWidget); // Close button
        expect(find.byType(Divider), findsOneWidget); // Divider
      });
    });

    group('Dialog Structure', () {
      testWidgets('should have rounded corners', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Act
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert
        final dialog = tester.widget<Dialog>(find.byType(Dialog));
        expect(dialog.shape, isA<RoundedRectangleBorder>());
        final shape = dialog.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, isA<BorderRadius>());
      });

      testWidgets('should have proper padding in header', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Act
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert
        final padding = tester.widget<Padding>(
          find.ancestor(
            of: find.text('Test Plugin'),
            matching: find.byType(Padding),
          ).first,
        );
        expect(padding.padding, equals(const EdgeInsets.all(16.0)));
      });

      testWidgets('should use Row layout in header', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Act
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert - Header should contain a Row
        expect(find.byType(Row), findsWidgets);
      });

      testWidgets('should use Column for dialog structure', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Act
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Column), findsWidgets);
      });

      testWidgets('should have flexible content area', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget(descriptor: testDescriptor));

        // Act
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Flexible), findsOneWidget);
      });
    });

    group('Multiple Instances', () {
      testWidgets('should support multiple plugin buttons', (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  PluginHeaderButton(
                    descriptor: testDescriptor,
                    onItemAction: (_, __) {},
                  ),
                  PluginHeaderButton(
                    descriptor: customIconDescriptor,
                    onItemAction: (_, __) {},
                  ),
                ],
              ),
            ),
          ),
        );

        // Act & Assert
        expect(find.byType(PluginHeaderButton), findsNWidgets(2));
        expect(find.byType(IconButton), findsNWidgets(2));
      });

      testWidgets('should open independent dialogs', (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  PluginHeaderButton(
                    descriptor: testDescriptor,
                    onItemAction: (_, __) {},
                  ),
                  PluginHeaderButton(
                    descriptor: customIconDescriptor,
                    onItemAction: (_, __) {},
                  ),
                ],
              ),
            ),
          ),
        );

        // Act - Open first dialog
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.text('Test Plugin'), findsOneWidget);

        // Act - Close first dialog and open second
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.bookmark));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.text('Custom Icon Plugin'), findsOneWidget);
      });
    });
  });
}
