import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_ui/src/theme/extensions/theme_extensions.dart';

void main() {
  group('ThemeModeHelpers', () {
    group('isDarkMode', () {
      testWidgets('should return true when theme brightness is dark',
          (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Builder(
              builder: (context) {
                // Act & Assert
                expect(context.isDarkMode, isTrue);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });

      testWidgets('should return false when theme brightness is light',
          (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Builder(
              builder: (context) {
                // Act & Assert
                expect(context.isDarkMode, isFalse);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });
    });

    group('isLightMode', () {
      testWidgets('should return true when theme brightness is light',
          (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Builder(
              builder: (context) {
                // Act & Assert
                expect(context.isLightMode, isTrue);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });

      testWidgets('should return false when theme brightness is dark',
          (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Builder(
              builder: (context) {
                // Act & Assert
                expect(context.isLightMode, isFalse);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });
    });

    group('brightness', () {
      testWidgets('should return Brightness.dark for dark theme',
          (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Builder(
              builder: (context) {
                // Act & Assert
                expect(context.brightness, equals(Brightness.dark));
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });

      testWidgets('should return Brightness.light for light theme',
          (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Builder(
              builder: (context) {
                // Act & Assert
                expect(context.brightness, equals(Brightness.light));
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });
    });

    group('consistency', () {
      testWidgets('isDarkMode and isLightMode should be opposite',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Builder(
              builder: (context) {
                // Assert
                expect(context.isDarkMode, equals(!context.isLightMode));
                expect(context.isLightMode, equals(!context.isDarkMode));
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });

      testWidgets('brightness should match isDarkMode', (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Builder(
              builder: (context) {
                // Act & Assert
                expect(
                  context.isDarkMode,
                  equals(context.brightness == Brightness.dark),
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });
    });
  });

  group('ColorHelpers', () {
    group('darken', () {
      test('should darken color by default amount', () {
        // Arrange
        const color = Color(0xFF808080); // Medium gray

        // Act
        final darkened = color.darken();

        // Assert
        expect(darkened, isNot(equals(color)));
        expect(darkened.value, lessThan(color.value));
      });

      test('should darken color by specified amount', () {
        // Arrange
        const color = Color(0xFFFFFFFF); // White
        const amount = 0.2;

        // Act
        final darkened = color.darken(amount);

        // Assert
        expect(darkened, isNot(equals(color)));
        final hsl = HSLColor.fromColor(darkened);
        expect(hsl.lightness, lessThan(1.0));
      });

      test('should not darken below 0 lightness', () {
        // Arrange
        const color = Color(0xFF000000); // Black
        const amount = 0.5;

        // Act
        final darkened = color.darken(amount);

        // Assert
        final hsl = HSLColor.fromColor(darkened);
        expect(hsl.lightness, greaterThanOrEqualTo(0.0));
      });

      test('should preserve hue when darkening', () {
        // Arrange
        const color = Color(0xFFFF0000); // Red
        final originalHsl = HSLColor.fromColor(color);

        // Act
        final darkened = color.darken(0.1);
        final darkenedHsl = HSLColor.fromColor(darkened);

        // Assert
        expect(darkenedHsl.hue, closeTo(originalHsl.hue, 0.01));
      });

      test('should preserve saturation when darkening', () {
        // Arrange
        const color = Color(0xFFFF0000); // Red
        final originalHsl = HSLColor.fromColor(color);

        // Act
        final darkened = color.darken(0.1);
        final darkenedHsl = HSLColor.fromColor(darkened);

        // Assert
        expect(darkenedHsl.saturation, closeTo(originalHsl.saturation, 0.01));
      });

      test('should handle edge case with amount 0', () {
        // Arrange
        const color = Color(0xFF808080);

        // Act
        final result = color.darken(0.0);

        // Assert
        expect(result.value, equals(color.value));
      });

      test('should handle edge case with amount 1', () {
        // Arrange
        const color = Color(0xFFFFFFFF);

        // Act
        final result = color.darken(1.0);

        // Assert
        final hsl = HSLColor.fromColor(result);
        expect(hsl.lightness, equals(0.0));
      });
    });

    group('lighten', () {
      test('should lighten color by default amount', () {
        // Arrange
        const color = Color(0xFF808080); // Medium gray

        // Act
        final lightened = color.lighten();

        // Assert
        expect(lightened, isNot(equals(color)));
        expect(lightened.value, greaterThan(color.value));
      });

      test('should lighten color by specified amount', () {
        // Arrange
        const color = Color(0xFF000000); // Black
        const amount = 0.2;

        // Act
        final lightened = color.lighten(amount);

        // Assert
        expect(lightened, isNot(equals(color)));
        final hsl = HSLColor.fromColor(lightened);
        expect(hsl.lightness, greaterThan(0.0));
      });

      test('should not lighten above 1.0 lightness', () {
        // Arrange
        const color = Color(0xFFFFFFFF); // White
        const amount = 0.5;

        // Act
        final lightened = color.lighten(amount);

        // Assert
        final hsl = HSLColor.fromColor(lightened);
        expect(hsl.lightness, lessThanOrEqualTo(1.0));
      });

      test('should preserve hue when lightening', () {
        // Arrange
        const color = Color(0xFF0000FF); // Blue
        final originalHsl = HSLColor.fromColor(color);

        // Act
        final lightened = color.lighten(0.1);
        final lightenedHsl = HSLColor.fromColor(lightened);

        // Assert
        expect(lightenedHsl.hue, closeTo(originalHsl.hue, 0.01));
      });

      test('should preserve saturation when lightening', () {
        // Arrange
        const color = Color(0xFF0000FF); // Blue
        final originalHsl = HSLColor.fromColor(color);

        // Act
        final lightened = color.lighten(0.1);
        final lightenedHsl = HSLColor.fromColor(lightened);

        // Assert
        expect(lightenedHsl.saturation, closeTo(originalHsl.saturation, 0.01));
      });

      test('should handle edge case with amount 0', () {
        // Arrange
        const color = Color(0xFF808080);

        // Act
        final result = color.lighten(0.0);

        // Assert
        expect(result.value, equals(color.value));
      });

      test('should handle edge case with amount 1', () {
        // Arrange
        const color = Color(0xFF000000);

        // Act
        final result = color.lighten(1.0);

        // Assert
        final hsl = HSLColor.fromColor(result);
        expect(hsl.lightness, equals(1.0));
      });
    });

    group('complementary', () {
      test('should return complementary color', () {
        // Arrange
        const color = Color(0xFFFF0000); // Red
        final originalHsl = HSLColor.fromColor(color);

        // Act
        final complementary = color.complementary;
        final complementaryHsl = HSLColor.fromColor(complementary);

        // Assert
        expect(complementary, isNot(equals(color)));
        expect(
          complementaryHsl.hue,
          closeTo((originalHsl.hue + 180) % 360, 0.01),
        );
      });

      test('should preserve lightness of complementary color', () {
        // Arrange
        const color = Color(0xFFFF0000); // Red
        final originalHsl = HSLColor.fromColor(color);

        // Act
        final complementary = color.complementary;
        final complementaryHsl = HSLColor.fromColor(complementary);

        // Assert
        expect(
          complementaryHsl.lightness,
          closeTo(originalHsl.lightness, 0.01),
        );
      });

      test('should preserve saturation of complementary color', () {
        // Arrange
        const color = Color(0xFFFF0000); // Red
        final originalHsl = HSLColor.fromColor(color);

        // Act
        final complementary = color.complementary;
        final complementaryHsl = HSLColor.fromColor(complementary);

        // Assert
        expect(
          complementaryHsl.saturation,
          closeTo(originalHsl.saturation, 0.01),
        );
      });

      test('should handle hue wraparound correctly', () {
        // Arrange
        const color = Color(0xFF00FFFF); // Cyan (hue ~180)
        final originalHsl = HSLColor.fromColor(color);

        // Act
        final complementary = color.complementary;
        final complementaryHsl = HSLColor.fromColor(complementary);

        // Assert
        final expectedHue = (originalHsl.hue + 180) % 360;
        expect(complementaryHsl.hue, closeTo(expectedHue, 1.0));
      });

      test('complementary of complementary should return similar color', () {
        // Arrange
        const color = Color(0xFF0000FF); // Blue

        // Act
        final comp1 = color.complementary;
        final comp2 = comp1.complementary;

        // Assert
        expect(comp2.value, closeTo(color.value, 0x01000000));
      });
    });

    group('monochromatic', () {
      test('should return default count of 5 colors', () {
        // Arrange
        const color = Color(0xFF808080);

        // Act
        final colors = color.monochromatic();

        // Assert
        expect(colors.length, equals(5));
      });

      test('should return specified count of colors', () {
        // Arrange
        const color = Color(0xFF808080);
        const count = 7;

        // Act
        final colors = color.monochromatic(count);

        // Assert
        expect(colors.length, equals(count));
      });

      test('should return colors with varying lightness', () {
        // Arrange
        const color = Color(0xFF808080);

        // Act
        final colors = color.monochromatic(5);

        // Assert
        final lightnesses = colors.map((c) => HSLColor.fromColor(c).lightness);
        expect(lightnesses.toSet().length, greaterThan(1));
      });

      test('should preserve hue in all monochromatic colors', () {
        // Arrange
        const color = Color(0xFFFF0000); // Red
        final originalHsl = HSLColor.fromColor(color);

        // Act
        final colors = color.monochromatic(5);

        // Assert
        for (final c in colors) {
          final hsl = HSLColor.fromColor(c);
          expect(hsl.hue, closeTo(originalHsl.hue, 0.01));
        }
      });

      test('should preserve saturation in all monochromatic colors', () {
        // Arrange
        const color = Color(0xFFFF0000); // Red
        final originalHsl = HSLColor.fromColor(color);

        // Act
        final colors = color.monochromatic(5);

        // Assert
        for (final c in colors) {
          final hsl = HSLColor.fromColor(c);
          expect(hsl.saturation, closeTo(originalHsl.saturation, 0.01));
        }
      });

      test('should return colors in ascending lightness order', () {
        // Arrange
        const color = Color(0xFF808080);

        // Act
        final colors = color.monochromatic(5);

        // Assert
        final lightnesses = colors.map((c) => HSLColor.fromColor(c).lightness);
        final lightnessValues = lightnesses.toList();
        for (var i = 0; i < lightnessValues.length - 1; i++) {
          expect(
            lightnessValues[i],
            lessThanOrEqualTo(lightnessValues[i + 1]),
          );
        }
      });

      test('should clamp lightness between 0.2 and 0.8', () {
        // Arrange
        const color = Color(0xFF808080);

        // Act
        final colors = color.monochromatic(10);

        // Assert
        for (final c in colors) {
          final hsl = HSLColor.fromColor(c);
          expect(hsl.lightness, greaterThanOrEqualTo(0.2));
          expect(hsl.lightness, lessThanOrEqualTo(0.8));
        }
      });

      test('should handle single color count', () {
        // Arrange
        const color = Color(0xFF808080);

        // Act
        final colors = color.monochromatic(1);

        // Assert
        expect(colors.length, equals(1));
        final hsl = HSLColor.fromColor(colors.first);
        expect(hsl.lightness, greaterThanOrEqualTo(0.0));
        expect(hsl.lightness, lessThanOrEqualTo(1.0));
      });

      test('should handle large color count', () {
        // Arrange
        const color = Color(0xFF808080);

        // Act
        final colors = color.monochromatic(20);

        // Assert
        expect(colors.length, equals(20));
        expect(colors.toSet().length, greaterThan(1));
      });
    });

    group('color manipulation combinations', () {
      test('should support chaining darken and lighten', () {
        // Arrange
        const color = Color(0xFF808080);

        // Act
        final result = color.darken(0.2).lighten(0.1);

        // Assert
        expect(result, isNot(equals(color)));
        expect(result, isA<Color>());
      });

      test('should support getting complementary then darkening', () {
        // Arrange
        const color = Color(0xFFFF0000);

        // Act
        final result = color.complementary.darken(0.1);

        // Assert
        expect(result, isNot(equals(color)));
        expect(result, isA<Color>());
      });

      test('should support getting complementary then lightening', () {
        // Arrange
        const color = Color(0xFF0000FF);

        // Act
        final result = color.complementary.lighten(0.1);

        // Assert
        expect(result, isNot(equals(color)));
        expect(result, isA<Color>());
      });
    });

    group('edge cases', () {
      test('should handle pure black', () {
        // Arrange
        const black = Color(0xFF000000);

        // Act & Assert
        expect(black.lighten(0.1), isNot(equals(black)));
        expect(black.darken(0.1), equals(black));
        expect(black.complementary, isA<Color>());
        expect(black.monochromatic(5).length, equals(5));
      });

      test('should handle pure white', () {
        // Arrange
        const white = Color(0xFFFFFFFF);

        // Act & Assert
        expect(white.darken(0.1), isNot(equals(white)));
        expect(white.lighten(0.1), equals(white));
        expect(white.complementary, isA<Color>());
        expect(white.monochromatic(5).length, equals(5));
      });

      test('should handle transparent color', () {
        // Arrange
        const transparent = Color(0x00000000);

        // Act & Assert
        expect(transparent.darken(0.1), isA<Color>());
        expect(transparent.lighten(0.1), isA<Color>());
        expect(transparent.complementary, isA<Color>());
        expect(transparent.monochromatic(5).length, equals(5));
      });

      test('should handle semi-transparent color', () {
        // Arrange
        const semiTransparent = Color(0x80FF0000);

        // Act & Assert
        expect(semiTransparent.darken(0.1), isA<Color>());
        expect(semiTransparent.lighten(0.1), isA<Color>());
        expect(semiTransparent.complementary, isA<Color>());
        expect(semiTransparent.monochromatic(5).length, equals(5));
      });
    });
  });
}
