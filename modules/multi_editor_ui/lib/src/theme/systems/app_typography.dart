import '../tokens/primitive/font_primitives.dart';

/// Typography system - consistent text styles throughout the app.
class AppTypography {
  AppTypography._();

  // Font families
  static const fontFamilySans = FontPrimitives.fontFamilySans;
  static const fontFamilyMono = FontPrimitives.fontFamilyMono;

  // Font sizes
  static const fontSizeXs = FontPrimitives.fontSize11;
  static const fontSizeS = FontPrimitives.fontSize12;
  static const fontSizeM = FontPrimitives.fontSize14;
  static const fontSizeL = FontPrimitives.fontSize16;
  static const fontSizeXl = FontPrimitives.fontSize18;
  static const fontSizeXxl = FontPrimitives.fontSize20;

  // Font weights
  static const fontWeightRegular = FontPrimitives.fontWeightRegular;
  static const fontWeightMedium = FontPrimitives.fontWeightMedium;
  static const fontWeightSemiBold = FontPrimitives.fontWeightSemiBold;
  static const fontWeightBold = FontPrimitives.fontWeightBold;

  // Line heights
  static const lineHeightTight = FontPrimitives.lineHeight120;
  static const lineHeightNormal = FontPrimitives.lineHeight140;
  static const lineHeightRelaxed = FontPrimitives.lineHeight150;
}
