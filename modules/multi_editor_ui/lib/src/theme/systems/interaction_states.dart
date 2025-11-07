import 'package:flutter/material.dart';

/// Interaction states utilities for consistent hover, pressed, and focused effects.
class InteractionStates {
  InteractionStates._();

  /// Calculate hover state color
  static Color hover(Color base, Brightness brightness) {
    return Color.alphaBlend(
      brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.04),
      base,
    );
  }

  /// Calculate pressed state color
  static Color pressed(Color base, Brightness brightness) {
    return Color.alphaBlend(
      brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.08),
      base,
    );
  }

  /// Calculate focused state color
  static Color focused(Color base, Brightness brightness) {
    return Color.alphaBlend(
      brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.10)
          : Colors.black.withValues(alpha: 0.06),
      base,
    );
  }

  /// Calculate disabled state color
  static Color disabled(Color base) {
    return base.withValues(alpha: 0.38);
  }

  /// Calculate overlay color for states
  static Color overlay(Brightness brightness, {double opacity = 0.08}) {
    return (brightness == Brightness.dark ? Colors.white : Colors.black)
        .withValues(alpha: opacity);
  }
}
