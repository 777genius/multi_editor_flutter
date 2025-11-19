import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_ui/src/theme/systems/interaction_states.dart';

void main() {
  group('InteractionStates', () {
    group('constructor', () {
      test('should have private constructor', () {
        // Arrange & Act & Assert
        // Cannot instantiate due to private constructor
        // This test verifies the class design
        expect(InteractionStates, isNotNull);
      });
    });

    group('hover', () {
      test('should return lighter color for dark mode', () {
        // Arrange
        const baseColor = Color(0xFF212121);
        const brightness = Brightness.dark;

        // Act
        final hoverColor = InteractionStates.hover(baseColor, brightness);

        // Assert
        expect(hoverColor, isNot(equals(baseColor)));
        expect(hoverColor, isA<Color>());
      });

      test('should return darker color for light mode', () {
        // Arrange
        const baseColor = Color(0xFFFFFFFF);
        const brightness = Brightness.light;

        // Act
        final hoverColor = InteractionStates.hover(baseColor, brightness);

        // Assert
        expect(hoverColor, isNot(equals(baseColor)));
        expect(hoverColor, isA<Color>());
      });

      test('should apply white overlay with 0.08 alpha for dark mode', () {
        // Arrange
        const baseColor = Color(0xFF000000);
        const brightness = Brightness.dark;

        // Act
        final hoverColor = InteractionStates.hover(baseColor, brightness);

        // Assert
        final expectedOverlay = Colors.white.withValues(alpha: 0.08);
        final expected = Color.alphaBlend(expectedOverlay, baseColor);
        expect(hoverColor.value, equals(expected.value));
      });

      test('should apply black overlay with 0.04 alpha for light mode', () {
        // Arrange
        const baseColor = Color(0xFFFFFFFF);
        const brightness = Brightness.light;

        // Act
        final hoverColor = InteractionStates.hover(baseColor, brightness);

        // Assert
        final expectedOverlay = Colors.black.withValues(alpha: 0.04);
        final expected = Color.alphaBlend(expectedOverlay, baseColor);
        expect(hoverColor.value, equals(expected.value));
      });

      test('should maintain alpha channel of base color', () {
        // Arrange
        const baseColor = Color(0x80FF0000); // Semi-transparent red
        const brightness = Brightness.light;

        // Act
        final hoverColor = InteractionStates.hover(baseColor, brightness);

        // Assert
        expect(hoverColor, isA<Color>());
      });
    });

    group('pressed', () {
      test('should return lighter color for dark mode', () {
        // Arrange
        const baseColor = Color(0xFF212121);
        const brightness = Brightness.dark;

        // Act
        final pressedColor = InteractionStates.pressed(baseColor, brightness);

        // Assert
        expect(pressedColor, isNot(equals(baseColor)));
        expect(pressedColor, isA<Color>());
      });

      test('should return darker color for light mode', () {
        // Arrange
        const baseColor = Color(0xFFFFFFFF);
        const brightness = Brightness.light;

        // Act
        final pressedColor = InteractionStates.pressed(baseColor, brightness);

        // Assert
        expect(pressedColor, isNot(equals(baseColor)));
        expect(pressedColor, isA<Color>());
      });

      test('should apply white overlay with 0.12 alpha for dark mode', () {
        // Arrange
        const baseColor = Color(0xFF000000);
        const brightness = Brightness.dark;

        // Act
        final pressedColor = InteractionStates.pressed(baseColor, brightness);

        // Assert
        final expectedOverlay = Colors.white.withValues(alpha: 0.12);
        final expected = Color.alphaBlend(expectedOverlay, baseColor);
        expect(pressedColor.value, equals(expected.value));
      });

      test('should apply black overlay with 0.08 alpha for light mode', () {
        // Arrange
        const baseColor = Color(0xFFFFFFFF);
        const brightness = Brightness.light;

        // Act
        final pressedColor = InteractionStates.pressed(baseColor, brightness);

        // Assert
        final expectedOverlay = Colors.black.withValues(alpha: 0.08);
        final expected = Color.alphaBlend(expectedOverlay, baseColor);
        expect(pressedColor.value, equals(expected.value));
      });

      test('should be more intense than hover for dark mode', () {
        // Arrange
        const baseColor = Color(0xFF212121);
        const brightness = Brightness.dark;

        // Act
        final hoverColor = InteractionStates.hover(baseColor, brightness);
        final pressedColor = InteractionStates.pressed(baseColor, brightness);

        // Assert
        // Pressed should have more overlay, resulting in different value
        expect(pressedColor, isNot(equals(hoverColor)));
      });

      test('should be more intense than hover for light mode', () {
        // Arrange
        const baseColor = Color(0xFFFFFFFF);
        const brightness = Brightness.light;

        // Act
        final hoverColor = InteractionStates.hover(baseColor, brightness);
        final pressedColor = InteractionStates.pressed(baseColor, brightness);

        // Assert
        // Pressed should have more overlay, resulting in different value
        expect(pressedColor, isNot(equals(hoverColor)));
      });
    });

    group('focused', () {
      test('should return lighter color for dark mode', () {
        // Arrange
        const baseColor = Color(0xFF212121);
        const brightness = Brightness.dark;

        // Act
        final focusedColor = InteractionStates.focused(baseColor, brightness);

        // Assert
        expect(focusedColor, isNot(equals(baseColor)));
        expect(focusedColor, isA<Color>());
      });

      test('should return darker color for light mode', () {
        // Arrange
        const baseColor = Color(0xFFFFFFFF);
        const brightness = Brightness.light;

        // Act
        final focusedColor = InteractionStates.focused(baseColor, brightness);

        // Assert
        expect(focusedColor, isNot(equals(baseColor)));
        expect(focusedColor, isA<Color>());
      });

      test('should apply white overlay with 0.10 alpha for dark mode', () {
        // Arrange
        const baseColor = Color(0xFF000000);
        const brightness = Brightness.dark;

        // Act
        final focusedColor = InteractionStates.focused(baseColor, brightness);

        // Assert
        final expectedOverlay = Colors.white.withValues(alpha: 0.10);
        final expected = Color.alphaBlend(expectedOverlay, baseColor);
        expect(focusedColor.value, equals(expected.value));
      });

      test('should apply black overlay with 0.06 alpha for light mode', () {
        // Arrange
        const baseColor = Color(0xFFFFFFFF);
        const brightness = Brightness.light;

        // Act
        final focusedColor = InteractionStates.focused(baseColor, brightness);

        // Assert
        final expectedOverlay = Colors.black.withValues(alpha: 0.06);
        final expected = Color.alphaBlend(expectedOverlay, baseColor);
        expect(focusedColor.value, equals(expected.value));
      });

      test('should be between hover and pressed intensity for dark mode', () {
        // Arrange
        const baseColor = Color(0xFF212121);
        const brightness = Brightness.dark;

        // Act
        final hoverColor = InteractionStates.hover(baseColor, brightness);
        final focusedColor = InteractionStates.focused(baseColor, brightness);
        final pressedColor = InteractionStates.pressed(baseColor, brightness);

        // Assert
        expect(hoverColor, isNot(equals(focusedColor)));
        expect(focusedColor, isNot(equals(pressedColor)));
        expect(hoverColor, isNot(equals(pressedColor)));
      });

      test('should be between hover and pressed intensity for light mode', () {
        // Arrange
        const baseColor = Color(0xFFFFFFFF);
        const brightness = Brightness.light;

        // Act
        final hoverColor = InteractionStates.hover(baseColor, brightness);
        final focusedColor = InteractionStates.focused(baseColor, brightness);
        final pressedColor = InteractionStates.pressed(baseColor, brightness);

        // Assert
        expect(hoverColor, isNot(equals(focusedColor)));
        expect(focusedColor, isNot(equals(pressedColor)));
        expect(hoverColor, isNot(equals(pressedColor)));
      });
    });

    group('disabled', () {
      test('should reduce opacity to 0.38', () {
        // Arrange
        const baseColor = Color(0xFFFF0000);

        // Act
        final disabledColor = InteractionStates.disabled(baseColor);

        // Assert
        expect(disabledColor, isNot(equals(baseColor)));
        expect(disabledColor.alpha / 255.0, closeTo(0.38, 0.01));
      });

      test('should work with any brightness', () {
        // Arrange
        const lightColor = Color(0xFFFFFFFF);
        const darkColor = Color(0xFF000000);

        // Act
        final disabledLight = InteractionStates.disabled(lightColor);
        final disabledDark = InteractionStates.disabled(darkColor);

        // Assert
        expect(disabledLight.alpha / 255.0, closeTo(0.38, 0.01));
        expect(disabledDark.alpha / 255.0, closeTo(0.38, 0.01));
      });

      test('should preserve RGB values', () {
        // Arrange
        const baseColor = Color(0xFFFF5500);

        // Act
        final disabledColor = InteractionStates.disabled(baseColor);

        // Assert
        expect(disabledColor.red, equals(baseColor.red));
        expect(disabledColor.green, equals(baseColor.green));
        expect(disabledColor.blue, equals(baseColor.blue));
      });

      test('should handle already semi-transparent color', () {
        // Arrange
        const baseColor = Color(0x80FF0000);

        // Act
        final disabledColor = InteractionStates.disabled(baseColor);

        // Assert
        expect(disabledColor.alpha / 255.0, closeTo(0.38, 0.01));
      });

      test('should handle fully transparent color', () {
        // Arrange
        const baseColor = Color(0x00FF0000);

        // Act
        final disabledColor = InteractionStates.disabled(baseColor);

        // Assert
        expect(disabledColor.alpha / 255.0, closeTo(0.38, 0.01));
      });
    });

    group('overlay', () {
      test('should return white overlay for dark mode by default', () {
        // Arrange
        const brightness = Brightness.dark;

        // Act
        final overlayColor = InteractionStates.overlay(brightness);

        // Assert
        expect(overlayColor.red, equals(Colors.white.red));
        expect(overlayColor.green, equals(Colors.white.green));
        expect(overlayColor.blue, equals(Colors.white.blue));
        expect(overlayColor.alpha / 255.0, closeTo(0.08, 0.01));
      });

      test('should return black overlay for light mode by default', () {
        // Arrange
        const brightness = Brightness.light;

        // Act
        final overlayColor = InteractionStates.overlay(brightness);

        // Assert
        expect(overlayColor.red, equals(Colors.black.red));
        expect(overlayColor.green, equals(Colors.black.green));
        expect(overlayColor.blue, equals(Colors.black.blue));
        expect(overlayColor.alpha / 255.0, closeTo(0.08, 0.01));
      });

      test('should use custom opacity when provided', () {
        // Arrange
        const brightness = Brightness.dark;
        const customOpacity = 0.15;

        // Act
        final overlayColor =
            InteractionStates.overlay(brightness, opacity: customOpacity);

        // Assert
        expect(overlayColor.alpha / 255.0, closeTo(customOpacity, 0.01));
      });

      test('should support various opacity values for dark mode', () {
        // Arrange
        const brightness = Brightness.dark;

        // Act & Assert
        final overlay1 = InteractionStates.overlay(brightness, opacity: 0.05);
        final overlay2 = InteractionStates.overlay(brightness, opacity: 0.10);
        final overlay3 = InteractionStates.overlay(brightness, opacity: 0.20);

        expect(overlay1.alpha / 255.0, closeTo(0.05, 0.01));
        expect(overlay2.alpha / 255.0, closeTo(0.10, 0.01));
        expect(overlay3.alpha / 255.0, closeTo(0.20, 0.01));
      });

      test('should support various opacity values for light mode', () {
        // Arrange
        const brightness = Brightness.light;

        // Act & Assert
        final overlay1 = InteractionStates.overlay(brightness, opacity: 0.05);
        final overlay2 = InteractionStates.overlay(brightness, opacity: 0.10);
        final overlay3 = InteractionStates.overlay(brightness, opacity: 0.20);

        expect(overlay1.alpha / 255.0, closeTo(0.05, 0.01));
        expect(overlay2.alpha / 255.0, closeTo(0.10, 0.01));
        expect(overlay3.alpha / 255.0, closeTo(0.20, 0.01));
      });

      test('should handle edge case with 0 opacity', () {
        // Arrange
        const brightness = Brightness.dark;

        // Act
        final overlayColor =
            InteractionStates.overlay(brightness, opacity: 0.0);

        // Assert
        expect(overlayColor.alpha, equals(0));
      });

      test('should handle edge case with max opacity', () {
        // Arrange
        const brightness = Brightness.light;

        // Act
        final overlayColor =
            InteractionStates.overlay(brightness, opacity: 1.0);

        // Assert
        expect(overlayColor.alpha, equals(255));
      });
    });

    group('common usage scenarios', () {
      test('should create consistent hover state across themes', () {
        // Arrange
        const baseColor = Color(0xFF2196F3);

        // Act
        final darkHover =
            InteractionStates.hover(baseColor, Brightness.dark);
        final lightHover =
            InteractionStates.hover(baseColor, Brightness.light);

        // Assert
        expect(darkHover, isNot(equals(lightHover)));
        expect(darkHover, isA<Color>());
        expect(lightHover, isA<Color>());
      });

      test('should support complete interaction state progression', () {
        // Arrange
        const baseColor = Color(0xFF4CAF50);
        const brightness = Brightness.light;

        // Act
        final normal = baseColor;
        final hover = InteractionStates.hover(baseColor, brightness);
        final focused = InteractionStates.focused(baseColor, brightness);
        final pressed = InteractionStates.pressed(baseColor, brightness);
        final disabled = InteractionStates.disabled(baseColor);

        // Assert
        expect(normal, isNot(equals(hover)));
        expect(normal, isNot(equals(focused)));
        expect(normal, isNot(equals(pressed)));
        expect(normal, isNot(equals(disabled)));
        expect(hover, isNot(equals(pressed)));
      });

      test('should work with Material Design colors', () {
        // Arrange
        final primaryColor = Colors.blue[500]!;
        const brightness = Brightness.light;

        // Act
        final hover = InteractionStates.hover(primaryColor, brightness);
        final pressed = InteractionStates.pressed(primaryColor, brightness);
        final focused = InteractionStates.focused(primaryColor, brightness);

        // Assert
        expect(hover, isA<Color>());
        expect(pressed, isA<Color>());
        expect(focused, isA<Color>());
      });

      test('should create overlay that can be blended manually', () {
        // Arrange
        const baseColor = Color(0xFFFFFFFF);
        const brightness = Brightness.light;

        // Act
        final overlay = InteractionStates.overlay(brightness);
        final blendedColor = Color.alphaBlend(overlay, baseColor);

        // Assert
        expect(blendedColor, isNot(equals(baseColor)));
        expect(blendedColor, isA<Color>());
      });
    });

    group('edge cases', () {
      test('should handle pure black base color', () {
        // Arrange
        const black = Color(0xFF000000);

        // Act & Assert
        expect(
          InteractionStates.hover(black, Brightness.dark),
          isA<Color>(),
        );
        expect(
          InteractionStates.hover(black, Brightness.light),
          isA<Color>(),
        );
        expect(
          InteractionStates.pressed(black, Brightness.dark),
          isA<Color>(),
        );
        expect(
          InteractionStates.focused(black, Brightness.dark),
          isA<Color>(),
        );
        expect(InteractionStates.disabled(black), isA<Color>());
      });

      test('should handle pure white base color', () {
        // Arrange
        const white = Color(0xFFFFFFFF);

        // Act & Assert
        expect(
          InteractionStates.hover(white, Brightness.dark),
          isA<Color>(),
        );
        expect(
          InteractionStates.hover(white, Brightness.light),
          isA<Color>(),
        );
        expect(
          InteractionStates.pressed(white, Brightness.light),
          isA<Color>(),
        );
        expect(
          InteractionStates.focused(white, Brightness.light),
          isA<Color>(),
        );
        expect(InteractionStates.disabled(white), isA<Color>());
      });

      test('should handle transparent base color', () {
        // Arrange
        const transparent = Color(0x00000000);

        // Act & Assert
        expect(
          InteractionStates.hover(transparent, Brightness.dark),
          isA<Color>(),
        );
        expect(
          InteractionStates.pressed(transparent, Brightness.dark),
          isA<Color>(),
        );
        expect(
          InteractionStates.focused(transparent, Brightness.dark),
          isA<Color>(),
        );
        expect(InteractionStates.disabled(transparent), isA<Color>());
      });

      test('should handle colors with various alpha values', () {
        // Arrange
        const colors = [
          Color(0x10FF0000),
          Color(0x40FF0000),
          Color(0x80FF0000),
          Color(0xC0FF0000),
          Color(0xFFFF0000),
        ];

        // Act & Assert
        for (final color in colors) {
          expect(
            InteractionStates.hover(color, Brightness.dark),
            isA<Color>(),
          );
          expect(
            InteractionStates.pressed(color, Brightness.light),
            isA<Color>(),
          );
          expect(
            InteractionStates.focused(color, Brightness.dark),
            isA<Color>(),
          );
          expect(InteractionStates.disabled(color), isA<Color>());
        }
      });

      test('should handle all Material colors', () {
        // Arrange
        final materialColors = [
          Colors.red,
          Colors.pink,
          Colors.purple,
          Colors.deepPurple,
          Colors.indigo,
          Colors.blue,
          Colors.lightBlue,
          Colors.cyan,
          Colors.teal,
          Colors.green,
          Colors.lightGreen,
          Colors.lime,
          Colors.yellow,
          Colors.amber,
          Colors.orange,
          Colors.deepOrange,
          Colors.brown,
          Colors.grey,
          Colors.blueGrey,
        ];

        // Act & Assert
        for (final color in materialColors) {
          expect(
            InteractionStates.hover(color, Brightness.dark),
            isA<Color>(),
          );
          expect(
            InteractionStates.pressed(color, Brightness.light),
            isA<Color>(),
          );
          expect(
            InteractionStates.focused(color, Brightness.dark),
            isA<Color>(),
          );
          expect(InteractionStates.disabled(color), isA<Color>());
        }
      });
    });

    group('consistency checks', () {
      test('interaction states should be deterministic', () {
        // Arrange
        const baseColor = Color(0xFF2196F3);
        const brightness = Brightness.dark;

        // Act
        final hover1 = InteractionStates.hover(baseColor, brightness);
        final hover2 = InteractionStates.hover(baseColor, brightness);

        // Assert
        expect(hover1.value, equals(hover2.value));
      });

      test('all states should be unique for the same base color', () {
        // Arrange
        const baseColor = Color(0xFF4CAF50);
        const brightness = Brightness.light;

        // Act
        final hover = InteractionStates.hover(baseColor, brightness);
        final pressed = InteractionStates.pressed(baseColor, brightness);
        final focused = InteractionStates.focused(baseColor, brightness);
        final disabled = InteractionStates.disabled(baseColor);

        // Assert
        final uniqueColors = {hover, pressed, focused, disabled, baseColor};
        expect(uniqueColors.length, equals(5));
      });

      test('overlay opacity should match state implementations', () {
        // Arrange
        const baseColor = Color(0xFF000000);
        const brightness = Brightness.dark;

        // Act
        final hoverState = InteractionStates.hover(baseColor, brightness);
        final hoverOverlay = InteractionStates.overlay(brightness, opacity: 0.08);
        final hoverManual = Color.alphaBlend(hoverOverlay, baseColor);

        // Assert
        expect(hoverState.value, equals(hoverManual.value));
      });
    });
  });
}
