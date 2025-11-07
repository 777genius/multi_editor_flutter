import 'package:flutter/material.dart';

/// Convenient theme mode helpers.
extension ThemeModeHelpers on BuildContext {
  /// Check if current theme is dark mode.
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Check if current theme is light mode.
  bool get isLightMode => !isDarkMode;

  /// Get current brightness.
  Brightness get brightness => Theme.of(this).brightness;
}

/// Color manipulation helpers.
extension ColorHelpers on Color {
  /// Darken color by a percentage (0.0 - 1.0).
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return hslDark.toColor();
  }

  /// Lighten color by a percentage (0.0 - 1.0).
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(this);
    final hslLight =
        hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

    return hslLight.toColor();
  }

  /// Get a complementary color.
  Color get complementary {
    final hsl = HSLColor.fromColor(this);
    final hue = (hsl.hue + 180) % 360;
    return hsl.withHue(hue).toColor();
  }

  /// Create a monochromatic color scheme.
  List<Color> monochromatic([int count = 5]) {
    final hsl = HSLColor.fromColor(this);
    final colors = <Color>[];

    for (var i = 0; i < count; i++) {
      final lightness = (i / (count - 1)).clamp(0.2, 0.8);
      colors.add(hsl.withLightness(lightness).toColor());
    }

    return colors;
  }
}
