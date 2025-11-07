import 'package:flutter/material.dart';

/// Primitive color tokens - the foundational color palette.
///
/// These are raw color values without semantic meaning.
/// They should not be used directly in components, but rather
/// referenced by semantic tokens.
///
/// Naming convention: {hue}{lightness}
/// Example: blue60 (60% lightness on blue hue)
class ColorPrimitives {
  ColorPrimitives._();

  // Blue palette
  static const blue10 = Color(0xFF001F3F);
  static const blue20 = Color(0xFF003366);
  static const blue30 = Color(0xFF004080);
  static const blue40 = Color(0xFF0052A3);
  static const blue50 = Color(0xFF0066CC);
  static const blue60 = Color(0xFF3385D6);
  static const blue70 = Color(0xFF66A3E0);
  static const blue80 = Color(0xFF99C2EB);
  static const blue90 = Color(0xFFCCE0F5);
  static const blue95 = Color(0xFFE6F0FA);

  // Gray palette (neutral)
  static const gray10 = Color(0xFF0A0A0A);
  static const gray20 = Color(0xFF1E1E1E);
  static const gray30 = Color(0xFF2D2D30);
  static const gray40 = Color(0xFF3E3E42);
  static const gray50 = Color(0xFF5C5C60);
  static const gray60 = Color(0xFF8899A8);
  static const gray70 = Color(0xFFA0A0A0);
  static const gray80 = Color(0xFFC0C0C0);
  static const gray90 = Color(0xFFE0E0E0);
  static const gray95 = Color(0xFFF5F5F5);
  static const gray98 = Color(0xFFFAFAFA);

  // Accent palettes
  static const purple50 = Color(0xFF9C27B0);
  static const purple60 = Color(0xFFAB47BC);
  static const purple70 = Color(0xFFBA68C8);

  static const green50 = Color(0xFF4CAF50);
  static const green60 = Color(0xFF66BB6A);
  static const green70 = Color(0xFF81C784);

  static const red50 = Color(0xFFD32F2F);
  static const red60 = Color(0xFFE57373);
  static const red70 = Color(0xFFEF5350);

  static const orange50 = Color(0xFFFF9800);
  static const orange60 = Color(0xFFFFA726);
  static const orange70 = Color(0xFFFFB74D);

  static const yellow50 = Color(0xFFF7DF1E);
  static const yellow60 = Color(0xFFF9E54B);
  static const yellow70 = Color(0xFFFBEB77);

  // Language-specific colors (staying as primitives)
  static const dartBlue = Color(0xFF0175C2);
  static const javaScriptYellow = Color(0xFFF7DF1E);
  static const typeScriptBlue = Color(0xFF3178C6);
  static const pythonGreen = Color(0xFF3776AB);
  static const htmlOrange = Color(0xFFE44D26);
  static const cssBlue = Color(0xFF264DE4);

  // Pure colors
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const transparent = Colors.transparent;
}
