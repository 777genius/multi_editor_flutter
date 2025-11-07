import '../tokens/primitive/size_primitives.dart';

/// Border radius system - consistent rounding throughout the app.
class AppRadius {
  AppRadius._();

  /// No radius - sharp corners
  static const none = SizePrimitives.size0;

  /// Extra small radius (2px)
  static const xs = SizePrimitives.size2;

  /// Small radius (4px)
  static const s = SizePrimitives.size4;

  /// Medium radius (8px)
  static const m = SizePrimitives.size8;

  /// Large radius (12px)
  static const l = SizePrimitives.size12;

  /// Extra large radius (16px)
  static const xl = SizePrimitives.size16;

  /// Extra extra large radius (24px)
  static const xxl = SizePrimitives.size24;

  /// Fully rounded (999px)
  static const round = 999.0;
}
