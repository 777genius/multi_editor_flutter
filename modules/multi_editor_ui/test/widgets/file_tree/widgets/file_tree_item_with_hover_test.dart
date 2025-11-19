import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_ui/src/theme/editor_theme_extension.dart';
import 'package:multi_editor_ui/src/widgets/file_tree/widgets/file_tree_item_with_hover.dart';

void main() {
  group('FileTreeItemWithHover Widget Tests', () {
    Widget createWidget({
      required Widget child,
      required bool isSelected,
      void Function(TapDownDetails)? onSecondaryTap,
      EditorThemeExtension? themeExtension,
    }) {
      return MaterialApp(
        theme: ThemeData.light().copyWith(
          extensions: [themeExtension ?? EditorThemeExtension.light],
        ),
        home: Scaffold(
          body: FileTreeItemWithHover(
            isSelected: isSelected,
            onSecondaryTap: onSecondaryTap,
            child: child,
          ),
        ),
      );
    }

    group('Rendering', () {
      testWidgets('should render child widget', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(
            child: const Text('Test Child'),
            isSelected: false,
          ),
        );

        // Assert
        expect(find.text('Test Child'), findsOneWidget);
      });

      testWidgets('should wrap child in MouseRegion', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(
            child: const Text('Test'),
            isSelected: false,
          ),
        );

        // Assert
        expect(find.byType(MouseRegion), findsOneWidget);
      });

      testWidgets('should wrap child in GestureDetector', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(
            child: const Text('Test'),
            isSelected: false,
          ),
        );

        // Assert
        expect(find.byType(GestureDetector), findsOneWidget);
      });

      testWidgets('should wrap child in AnimatedContainer', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(
            child: const Text('Test'),
            isSelected: false,
          ),
        );

        // Assert
        expect(find.byType(AnimatedContainer), findsOneWidget);
      });
    });

    group('Background Colors - Not Selected', () {
      testWidgets('should have transparent background when not hovered and not selected', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(
            child: const SizedBox(width: 100, height: 50),
            isSelected: false,
          ),
        );

        // Assert
        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        expect(container.color, isNull);
      });

      testWidgets('should show hover background when hovered and not selected', (tester) async {
        // Arrange
        const customTheme = EditorThemeExtension(
          fileTreeHoverBackground: Color(0xFF123456),
          fileTreeSelectionBackground: Color(0xFF234567),
          fileTreeSelectionHoverBackground: Color(0xFF345678),
          fileTreeBorder: Color(0xFF456789),
        );

        await tester.pumpWidget(
          createWidget(
            child: const SizedBox(width: 100, height: 50),
            isSelected: false,
            themeExtension: customTheme,
          ),
        );

        // Act - Trigger hover
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();

        await gesture.moveTo(tester.getCenter(find.byType(MouseRegion)));
        await tester.pumpAndSettle();

        // Assert
        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        expect(container.color, equals(const Color(0xFF123456)));
      });
    });

    group('Background Colors - Selected', () {
      testWidgets('should show selection background when selected and not hovered', (tester) async {
        // Arrange
        const customTheme = EditorThemeExtension(
          fileTreeHoverBackground: Color(0xFF123456),
          fileTreeSelectionBackground: Color(0xFF234567),
          fileTreeSelectionHoverBackground: Color(0xFF345678),
          fileTreeBorder: Color(0xFF456789),
        );

        // Act
        await tester.pumpWidget(
          createWidget(
            child: const SizedBox(width: 100, height: 50),
            isSelected: true,
            themeExtension: customTheme,
          ),
        );

        // Assert
        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        expect(container.color, equals(const Color(0xFF234567)));
      });

      testWidgets('should show selection hover background when selected and hovered', (tester) async {
        // Arrange
        const customTheme = EditorThemeExtension(
          fileTreeHoverBackground: Color(0xFF123456),
          fileTreeSelectionBackground: Color(0xFF234567),
          fileTreeSelectionHoverBackground: Color(0xFF345678),
          fileTreeBorder: Color(0xFF456789),
        );

        await tester.pumpWidget(
          createWidget(
            child: const SizedBox(width: 100, height: 50),
            isSelected: true,
            themeExtension: customTheme,
          ),
        );

        // Act - Trigger hover
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();

        await gesture.moveTo(tester.getCenter(find.byType(MouseRegion)));
        await tester.pumpAndSettle();

        // Assert
        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        expect(container.color, equals(const Color(0xFF345678)));
      });
    });

    group('Hover Interactions', () {
      testWidgets('should update state on mouse enter', (tester) async {
        // Arrange
        const customTheme = EditorThemeExtension(
          fileTreeHoverBackground: Color(0xFF123456),
          fileTreeSelectionBackground: Color(0xFF234567),
          fileTreeSelectionHoverBackground: Color(0xFF345678),
          fileTreeBorder: Color(0xFF456789),
        );

        await tester.pumpWidget(
          createWidget(
            child: const SizedBox(width: 100, height: 50),
            isSelected: false,
            themeExtension: customTheme,
          ),
        );

        // Initial state - not hovered
        var container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        expect(container.color, isNull);

        // Act - Mouse enter
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();

        await gesture.moveTo(tester.getCenter(find.byType(MouseRegion)));
        await tester.pumpAndSettle();

        // Assert - hovered
        container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        expect(container.color, equals(const Color(0xFF123456)));
      });

      testWidgets('should update state on mouse exit', (tester) async {
        // Arrange
        const customTheme = EditorThemeExtension(
          fileTreeHoverBackground: Color(0xFF123456),
          fileTreeSelectionBackground: Color(0xFF234567),
          fileTreeSelectionHoverBackground: Color(0xFF345678),
          fileTreeBorder: Color(0xFF456789),
        );

        await tester.pumpWidget(
          createWidget(
            child: const SizedBox(width: 100, height: 50),
            isSelected: false,
            themeExtension: customTheme,
          ),
        );

        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();

        // Act - Mouse enter
        await gesture.moveTo(tester.getCenter(find.byType(MouseRegion)));
        await tester.pumpAndSettle();

        // Verify hovered state
        var container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        expect(container.color, equals(const Color(0xFF123456)));

        // Act - Mouse exit
        await gesture.moveTo(const Offset(-1, -1));
        await tester.pumpAndSettle();

        // Assert - no longer hovered
        container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        expect(container.color, isNull);
      });

      testWidgets('should handle multiple hover enter/exit cycles', (tester) async {
        // Arrange
        const customTheme = EditorThemeExtension(
          fileTreeHoverBackground: Color(0xFF123456),
          fileTreeSelectionBackground: Color(0xFF234567),
          fileTreeSelectionHoverBackground: Color(0xFF345678),
          fileTreeBorder: Color(0xFF456789),
        );

        await tester.pumpWidget(
          createWidget(
            child: const SizedBox(width: 100, height: 50),
            isSelected: false,
            themeExtension: customTheme,
          ),
        );

        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();

        // Act & Assert - Cycle 1
        await gesture.moveTo(tester.getCenter(find.byType(MouseRegion)));
        await tester.pumpAndSettle();
        var container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
        expect(container.color, equals(const Color(0xFF123456)));

        await gesture.moveTo(const Offset(-1, -1));
        await tester.pumpAndSettle();
        container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
        expect(container.color, isNull);

        // Act & Assert - Cycle 2
        await gesture.moveTo(tester.getCenter(find.byType(MouseRegion)));
        await tester.pumpAndSettle();
        container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
        expect(container.color, equals(const Color(0xFF123456)));

        await gesture.moveTo(const Offset(-1, -1));
        await tester.pumpAndSettle();
        container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
        expect(container.color, isNull);
      });
    });

    group('Secondary Tap', () {
      testWidgets('should call onSecondaryTap when provided', (tester) async {
        // Arrange
        TapDownDetails? receivedDetails;

        await tester.pumpWidget(
          createWidget(
            child: const SizedBox(width: 100, height: 50),
            isSelected: false,
            onSecondaryTap: (details) {
              receivedDetails = details;
            },
          ),
        );

        // Act
        await tester.tap(find.byType(GestureDetector), buttons: kSecondaryButton);
        await tester.pumpAndSettle();

        // Assert
        expect(receivedDetails, isNotNull);
      });

      testWidgets('should not crash when onSecondaryTap is null', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(
            child: const SizedBox(width: 100, height: 50),
            isSelected: false,
            onSecondaryTap: null,
          ),
        );

        // Act & Assert - Should not throw
        await tester.tap(find.byType(GestureDetector), buttons: kSecondaryButton);
        await tester.pumpAndSettle();
      });

      testWidgets('should receive correct tap position', (tester) async {
        // Arrange
        Offset? tappedPosition;

        await tester.pumpWidget(
          createWidget(
            child: const SizedBox(width: 100, height: 50),
            isSelected: false,
            onSecondaryTap: (details) {
              tappedPosition = details.localPosition;
            },
          ),
        );

        // Act
        final center = tester.getCenter(find.byType(GestureDetector));
        await tester.tapAt(center, buttons: kSecondaryButton);
        await tester.pumpAndSettle();

        // Assert
        expect(tappedPosition, isNotNull);
      });
    });

    group('Animation', () {
      testWidgets('should have correct animation duration', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(
            child: const SizedBox(width: 100, height: 50),
            isSelected: false,
          ),
        );

        // Assert
        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        expect(container.duration, equals(const Duration(milliseconds: 150)));
      });

      testWidgets('should have correct animation curve', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(
            child: const SizedBox(width: 100, height: 50),
            isSelected: false,
          ),
        );

        // Assert
        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        expect(container.curve, equals(Curves.easeInOut));
      });

      testWidgets('should animate color change on hover', (tester) async {
        // Arrange
        const customTheme = EditorThemeExtension(
          fileTreeHoverBackground: Color(0xFF123456),
          fileTreeSelectionBackground: Color(0xFF234567),
          fileTreeSelectionHoverBackground: Color(0xFF345678),
          fileTreeBorder: Color(0xFF456789),
        );

        await tester.pumpWidget(
          createWidget(
            child: const SizedBox(width: 100, height: 50),
            isSelected: false,
            themeExtension: customTheme,
          ),
        );

        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();

        // Act - Start hover
        await gesture.moveTo(tester.getCenter(find.byType(MouseRegion)));
        await tester.pump(); // Start animation
        await tester.pump(const Duration(milliseconds: 75)); // Mid animation

        // Assert - Animation in progress (this just verifies no crash during animation)
        expect(find.byType(AnimatedContainer), findsOneWidget);

        // Complete animation
        await tester.pumpAndSettle();
        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        expect(container.color, equals(const Color(0xFF123456)));
      });
    });

    group('GestureDetector Configuration', () {
      testWidgets('should have opaque hit test behavior', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(
            child: const SizedBox(width: 100, height: 50),
            isSelected: false,
          ),
        );

        // Assert
        final gestureDetector = tester.widget<GestureDetector>(
          find.byType(GestureDetector),
        );
        expect(gestureDetector.behavior, equals(HitTestBehavior.opaque));
      });
    });

    group('Theme Integration', () {
      testWidgets('should use light theme colors by default', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(
            child: const SizedBox(width: 100, height: 50),
            isSelected: true,
          ),
        );

        // Assert
        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        expect(container.color, equals(EditorThemeExtension.light.fileTreeSelectionBackground));
      });

      testWidgets('should use dark theme colors when specified', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark().copyWith(
              extensions: [EditorThemeExtension.dark],
            ),
            home: Scaffold(
              body: FileTreeItemWithHover(
                isSelected: true,
                child: const SizedBox(width: 100, height: 50),
              ),
            ),
          ),
        );

        // Assert
        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        expect(container.color, equals(EditorThemeExtension.dark.fileTreeSelectionBackground));
      });
    });

    group('Use Cases', () {
      testWidgets('UC1: File item in file tree - not selected, not hovered', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(
            child: const Row(
              children: [
                Icon(Icons.insert_drive_file),
                SizedBox(width: 8),
                Text('main.dart'),
              ],
            ),
            isSelected: false,
          ),
        );

        // Assert
        expect(find.text('main.dart'), findsOneWidget);
        expect(find.byIcon(Icons.insert_drive_file), findsOneWidget);
        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        expect(container.color, isNull);
      });

      testWidgets('UC2: File item - selected and user hovers', (tester) async {
        // Arrange
        await tester.pumpWidget(
          createWidget(
            child: const Text('selected_file.dart'),
            isSelected: true,
          ),
        );

        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();

        // Act - Hover over selected item
        await gesture.moveTo(tester.getCenter(find.byType(MouseRegion)));
        await tester.pumpAndSettle();

        // Assert - Shows selection hover background
        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        expect(
          container.color,
          equals(EditorThemeExtension.light.fileTreeSelectionHoverBackground),
        );
      });

      testWidgets('UC3: Right-click on file for context menu', (tester) async {
        // Arrange
        TapDownDetails? contextMenuTap;

        await tester.pumpWidget(
          createWidget(
            child: const Text('file.dart'),
            isSelected: false,
            onSecondaryTap: (details) {
              contextMenuTap = details;
            },
          ),
        );

        // Act - Right-click
        await tester.tap(find.byType(GestureDetector), buttons: kSecondaryButton);
        await tester.pumpAndSettle();

        // Assert
        expect(contextMenuTap, isNotNull);
      });

      testWidgets('UC4: Folder item with expand icon - hover changes background', (tester) async {
        // Arrange
        const customTheme = EditorThemeExtension(
          fileTreeHoverBackground: Color(0xFFEEEEEE),
          fileTreeSelectionBackground: Color(0xFFDDDDDD),
          fileTreeSelectionHoverBackground: Color(0xFFCCCCCC),
          fileTreeBorder: Color(0xFFBBBBBB),
        );

        await tester.pumpWidget(
          createWidget(
            child: const Row(
              children: [
                Icon(Icons.folder),
                SizedBox(width: 8),
                Text('src'),
                Spacer(),
                Icon(Icons.chevron_right, size: 16),
              ],
            ),
            isSelected: false,
            themeExtension: customTheme,
          ),
        );

        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();

        // Act - Hover
        await gesture.moveTo(tester.getCenter(find.byType(MouseRegion)));
        await tester.pumpAndSettle();

        // Assert
        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        expect(container.color, equals(const Color(0xFFEEEEEE)));
      });

      testWidgets('UC5: Switching selection while hovering', (tester) async {
        // Arrange - Start with not selected
        const customTheme = EditorThemeExtension(
          fileTreeHoverBackground: Color(0xFF111111),
          fileTreeSelectionBackground: Color(0xFF222222),
          fileTreeSelectionHoverBackground: Color(0xFF333333),
          fileTreeBorder: Color(0xFF444444),
        );

        await tester.pumpWidget(
          createWidget(
            child: const Text('file.dart'),
            isSelected: false,
            themeExtension: customTheme,
          ),
        );

        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();

        // Act - Hover while not selected
        await gesture.moveTo(tester.getCenter(find.byType(MouseRegion)));
        await tester.pumpAndSettle();

        var container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        expect(container.color, equals(const Color(0xFF111111)));

        // Act - Change to selected while still hovering
        await tester.pumpWidget(
          createWidget(
            child: const Text('file.dart'),
            isSelected: true,
            themeExtension: customTheme,
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Now shows selection hover background
        container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        expect(container.color, equals(const Color(0xFF333333)));
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle very fast mouse movements', (tester) async {
        // Arrange
        await tester.pumpWidget(
          createWidget(
            child: const SizedBox(width: 100, height: 50),
            isSelected: false,
          ),
        );

        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();

        // Act - Rapid enter/exit without settle
        await gesture.moveTo(tester.getCenter(find.byType(MouseRegion)));
        await tester.pump();
        await gesture.moveTo(const Offset(-1, -1));
        await tester.pump();
        await gesture.moveTo(tester.getCenter(find.byType(MouseRegion)));
        await tester.pumpAndSettle();

        // Assert - Should handle gracefully
        expect(find.byType(AnimatedContainer), findsOneWidget);
      });

      testWidgets('should handle rebuild while hovered', (tester) async {
        // Arrange
        await tester.pumpWidget(
          createWidget(
            child: const Text('Original'),
            isSelected: false,
          ),
        );

        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();

        await gesture.moveTo(tester.getCenter(find.byType(MouseRegion)));
        await tester.pumpAndSettle();

        // Act - Rebuild with different child
        await tester.pumpWidget(
          createWidget(
            child: const Text('Updated'),
            isSelected: false,
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Still shows hover state
        expect(find.text('Updated'), findsOneWidget);
        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        expect(container.color, isNotNull); // Still hovered
      });
    });
  });
}
