import 'package:flutter/material.dart';

/// Primitive font tokens - foundational typography values.
///
/// These define raw font properties without semantic meaning.
/// They should be referenced by semantic typography tokens.
class FontPrimitives {
  FontPrimitives._();

  // Font families
  // Note: Using system fonts for now. Can be customized to use custom fonts.
  static const String fontFamilySans = 'SF Pro Text, -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif';
  static const String fontFamilyMono = 'SF Mono, Monaco, Consolas, Courier New, monospace';
  static const String fontFamilySerif = 'SF Pro Display, Georgia, serif';

  // Font sizes (following Material 3 + code editor needs)
  static const fontSize10 = 10.0;
  static const fontSize11 = 11.0;
  static const fontSize12 = 12.0;
  static const fontSize13 = 13.0;
  static const fontSize14 = 14.0;
  static const fontSize16 = 16.0;
  static const fontSize18 = 18.0;
  static const fontSize20 = 20.0;
  static const fontSize22 = 22.0;
  static const fontSize24 = 24.0;
  static const fontSize28 = 28.0;
  static const fontSize32 = 32.0;
  static const fontSize36 = 36.0;
  static const fontSize45 = 45.0;
  static const fontSize57 = 57.0;

  // Font weights
  static const fontWeightThin = FontWeight.w100;
  static const fontWeightExtraLight = FontWeight.w200;
  static const fontWeightLight = FontWeight.w300;
  static const fontWeightRegular = FontWeight.w400;
  static const fontWeightMedium = FontWeight.w500;
  static const fontWeightSemiBold = FontWeight.w600;
  static const fontWeightBold = FontWeight.w700;
  static const fontWeightExtraBold = FontWeight.w800;
  static const fontWeightBlack = FontWeight.w900;

  // Line heights (relative to font size)
  static const lineHeight100 = 1.0;   // Tight (for headings)
  static const lineHeight110 = 1.1;
  static const lineHeight120 = 1.2;
  static const lineHeight125 = 1.25;  // Normal (for body text)
  static const lineHeight140 = 1.4;
  static const lineHeight150 = 1.5;   // Relaxed (for readability)
  static const lineHeight160 = 1.6;
  static const lineHeight180 = 1.8;
  static const lineHeight200 = 2.0;

  // Letter spacing (tracking)
  static const letterSpacingTight = -0.5;
  static const letterSpacingNormal = 0.0;
  static const letterSpacingRelaxed = 0.5;
  static const letterSpacingWide = 1.0;
  static const letterSpacingExtraWide = 1.5;
}
