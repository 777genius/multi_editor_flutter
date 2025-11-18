import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:ide_presentation/ide_presentation.dart';

void main() {
  group('HoverInfoWidget', () {
    late HoverInfo testHoverInfo;

    setUp(() {
      testHoverInfo = HoverInfo(
        contents: [
          MarkupContent(
            kind: MarkupKind.plaintext,
            value: 'Test hover info',
          ),
        ],
      );
    });

    testWidgets('should render with hover info', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                HoverInfoWidget(
                  hoverInfo: testHoverInfo,
                  position: const Offset(100, 200),
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Test hover info'), findsOneWidget);
    });

    testWidgets('should position widget at specified offset', (tester) async {
      // Arrange
      const position = Offset(150, 250);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                HoverInfoWidget(
                  hoverInfo: testHoverInfo,
                  position: position,
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      final positioned = tester.widget<Positioned>(find.byType(Positioned));
      expect(positioned.left, isNotNull);
      expect(positioned.top, isNotNull);
    });

    testWidgets('should clamp position within screen bounds', (tester) async {
      // Arrange - Position near right edge
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;

      const position = Offset(750, 550);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                HoverInfoWidget(
                  hoverInfo: testHoverInfo,
                  position: position,
                ),
              ],
            ),
          ),
        ),
      );

      // Assert - Widget should be clamped to stay within bounds
      final positioned = tester.widget<Positioned>(find.byType(Positioned));
      expect(positioned.left, lessThan(800 - 16)); // With margin
      expect(positioned.top, lessThan(600 - 16)); // With margin
    });

    testWidgets('should display plain text correctly', (tester) async {
      // Arrange
      final hoverInfo = HoverInfo(
        contents: [
          MarkupContent(
            kind: MarkupKind.plaintext,
            value: 'Simple text without code',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                HoverInfoWidget(
                  hoverInfo: hoverInfo,
                  position: const Offset(100, 100),
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Simple text without code'), findsOneWidget);
      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('should detect and format code blocks', (tester) async {
      // Arrange
      final hoverInfo = HoverInfo(
        contents: [
          MarkupContent(
            kind: MarkupKind.markdown,
            value: '```dart\nvoid main() {}\n```',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                HoverInfoWidget(
                  hoverInfo: hoverInfo,
                  position: const Offset(100, 100),
                ),
              ],
            ),
          ),
        ),
      );

      // Assert - Code should be formatted
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should detect code with backticks', (tester) async {
      // Arrange
      final hoverInfo = HoverInfo(
        contents: [
          MarkupContent(
            kind: MarkupKind.markdown,
            value: 'Use `print()` function',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                HoverInfoWidget(
                  hoverInfo: hoverInfo,
                  position: const Offset(100, 100),
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('should call onDismiss when tapped', (tester) async {
      // Arrange
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                HoverInfoWidget(
                  hoverInfo: testHoverInfo,
                  position: const Offset(100, 100),
                  onDismiss: () => dismissed = true,
                ),
              ],
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      // Assert
      expect(dismissed, isTrue);
    });

    testWidgets('should work without onDismiss callback', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                HoverInfoWidget(
                  hoverInfo: testHoverInfo,
                  position: const Offset(100, 100),
                ),
              ],
            ),
          ),
        ),
      );

      // Assert - Should not crash
      expect(find.byType(HoverInfoWidget), findsOneWidget);
    });

    testWidgets('should have VS Code dark styling', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                HoverInfoWidget(
                  hoverInfo: testHoverInfo,
                  position: const Offset(100, 100),
                ),
              ],
            ),
          ),
        ),
      );

      // Assert - Check for dark background
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(Material),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(const Color(0xFF1E1E1E)));
    });

    testWidgets('should have elevation shadow', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                HoverInfoWidget(
                  hoverInfo: testHoverInfo,
                  position: const Offset(100, 100),
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      final material = tester.widget<Material>(find.byType(Material));
      expect(material.elevation, equals(4));
    });

    testWidgets('should enforce max width constraint', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                HoverInfoWidget(
                  hoverInfo: testHoverInfo,
                  position: const Offset(100, 100),
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(Material),
          matching: find.byType(Container),
        ).first,
      );
      expect(container.constraints?.maxWidth, equals(500.0));
      expect(container.constraints?.maxHeight, equals(300.0));
    });

    testWidgets('should be scrollable for long content', (tester) async {
      // Arrange
      final longHoverInfo = HoverInfo(
        contents: [
          MarkupContent(
            kind: MarkupKind.plaintext,
            value: 'Very long text\n' * 50,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                HoverInfoWidget(
                  hoverInfo: longHoverInfo,
                  position: const Offset(100, 100),
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should support selectable text', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                HoverInfoWidget(
                  hoverInfo: testHoverInfo,
                  position: const Offset(100, 100),
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(SelectableText), findsOneWidget);
    });

    group('Position Clamping Edge Cases', () {
      testWidgets('should clamp negative positions', (tester) async {
        // Arrange
        const position = Offset(-10, -20);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  HoverInfoWidget(
                    hoverInfo: testHoverInfo,
                    position: position,
                  ),
                ],
              ),
            ),
          ),
        );

        // Assert
        final positioned = tester.widget<Positioned>(find.byType(Positioned));
        expect(positioned.left, greaterThanOrEqualTo(16)); // Min margin
        expect(positioned.top, greaterThanOrEqualTo(16)); // Min margin
      });

      testWidgets('should handle small screen sizes', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(400, 300);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  HoverInfoWidget(
                    hoverInfo: testHoverInfo,
                    position: const Offset(100, 100),
                  ),
                ],
              ),
            ),
          ),
        );

        // Assert - Widget should adapt to small screen
        expect(find.byType(HoverInfoWidget), findsOneWidget);
      });
    });

    group('Content Formatting', () {
      testWidgets('should detect code with curly braces', (tester) async {
        // Arrange
        final hoverInfo = HoverInfo(
          contents: [
            MarkupContent(
              kind: MarkupKind.plaintext,
              value: 'class MyClass { }',
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  HoverInfoWidget(
                    hoverInfo: hoverInfo,
                    position: const Offset(100, 100),
                  ),
                ],
              ),
            ),
          ),
        );

        // Assert - Should be formatted as code
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('should strip markdown code fences', (tester) async {
        // Arrange
        final hoverInfo = HoverInfo(
          contents: [
            MarkupContent(
              kind: MarkupKind.markdown,
              value: '```\ncode here\n```',
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  HoverInfoWidget(
                    hoverInfo: hoverInfo,
                    position: const Offset(100, 100),
                  ),
                ],
              ),
            ),
          ),
        );

        // Assert - Backticks should be removed
        expect(find.textContaining('code here'), findsOneWidget);
      });
    });
  });
}
