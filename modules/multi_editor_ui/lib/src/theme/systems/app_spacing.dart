import '../tokens/primitive/size_primitives.dart';

/// Spacing system - consistent spacing values throughout the app.
///
/// Uses an 8pt grid system with additional refinements.
/// All spacing should use these constants for consistency.
class AppSpacing {
  AppSpacing._();

  /// No spacing (0px)
  static const none = SizePrimitives.size0;

  /// Extra extra small spacing (2px)
  static const xxs = SizePrimitives.size2;

  /// Extra small spacing (4px)
  static const xs = SizePrimitives.size4;

  /// Small spacing (8px)
  static const s = SizePrimitives.size8;

  /// Medium spacing (12px)
  static const m = SizePrimitives.size12;

  /// Large spacing (16px)
  static const l = SizePrimitives.size16;

  /// Extra large spacing (24px)
  static const xl = SizePrimitives.size24;

  /// Extra extra large spacing (32px)
  static const xxl = SizePrimitives.size32;

  /// Extra extra extra large spacing (48px)
  static const xxxl = SizePrimitives.size48;

  /// Huge spacing (64px)
  static const huge = SizePrimitives.size64;
}
