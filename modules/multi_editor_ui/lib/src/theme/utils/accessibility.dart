import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Accessibility utilities for WCAG compliance.
class Accessibility {
  Accessibility._();

  /// Calculate contrast ratio between two colors (WCAG formula).
  ///
  /// Returns a value between 1 and 21.
  /// - 4.5:1 is minimum for normal text (WCAG AA)
  /// - 3.0:1 is minimum for large text (WCAG AA)
  /// - 7.0:1 is minimum for normal text (WCAG AAA)
  static double contrastRatio(Color foreground, Color background) {
    final fgLuminance = _relativeLuminance(foreground);
    final bgLuminance = _relativeLuminance(background);

    final lighter = math.max(fgLuminance, bgLuminance);
    final darker = math.min(fgLuminance, bgLuminance);

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check if contrast meets WCAG AA standard for normal text (4.5:1).
  static bool meetsWcagAA(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= 4.5;
  }

  /// Check if contrast meets WCAG AA standard for large text (3.0:1).
  static bool meetsWcagAALarge(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= 3.0;
  }

  /// Check if contrast meets WCAG AAA standard for normal text (7.0:1).
  static bool meetsWcagAAA(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= 7.0;
  }

  /// Check if contrast meets WCAG AAA standard for large text (4.5:1).
  static bool meetsWcagAAALarge(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= 4.5;
  }

  /// Calculate relative luminance of a color (WCAG formula).
  static double _relativeLuminance(Color color) {
    final r = _channelLuminance(color.r / 255.0);
    final g = _channelLuminance(color.g / 255.0);
    final b = _channelLuminance(color.b / 255.0);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Calculate luminance for a single RGB channel.
  static double _channelLuminance(double channel) {
    return channel <= 0.03928
        ? channel / 12.92
        : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  /// Assert contrast ratio in debug mode (won't crash release builds).
  static void assertContrast(
    Color foreground,
    Color background, {
    double minimumRatio = 4.5,
    String? label,
  }) {
    assert(() {
      final ratio = contrastRatio(foreground, background);
      if (ratio < minimumRatio) {
        final message = label != null
            ? '$label: Insufficient contrast ratio $ratio:1 (minimum: $minimumRatio:1)'
            : 'Insufficient contrast ratio $ratio:1 (minimum: $minimumRatio:1)';
        debugPrint('⚠️ ACCESSIBILITY WARNING: $message');
        debugPrint('  Foreground: $foreground');
        debugPrint('  Background: $background');
      }
      return true;
    }());
  }

  /// Get recommended text color (black or white) for a background.
  static Color recommendedTextColor(Color background) {
    final blackContrast = contrastRatio(Colors.black, background);
    final whiteContrast = contrastRatio(Colors.white, background);

    return blackContrast > whiteContrast ? Colors.black : Colors.white;
  }
}
