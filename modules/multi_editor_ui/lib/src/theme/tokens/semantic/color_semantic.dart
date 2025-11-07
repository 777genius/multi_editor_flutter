import 'package:flutter/material.dart';
import '../primitive/color_primitives.dart';

/// Semantic color tokens - colors with meaningful context.
///
/// These map primitive colors to semantic purposes and are used
/// to build component tokens. They adapt for light and dark themes.
class ColorSemantic {
  const ColorSemantic({
    required this.actionPrimary,
    required this.actionPrimaryHover,
    required this.actionSecondary,
    required this.actionSecondaryHover,
    required this.surfaceBase,
    required this.surfaceElevated,
    required this.surfaceOverlay,
    required this.surfaceHigh,
    required this.contentPrimary,
    required this.contentSecondary,
    required this.contentTertiary,
    required this.contentInverse,
    required this.borderDefault,
    required this.borderSubtle,
    required this.borderStrong,
    required this.feedbackSuccess,
    required this.feedbackError,
    required this.feedbackWarning,
    required this.feedbackInfo,
  });

  // Action colors (buttons, links, interactive elements)
  final Color actionPrimary;
  final Color actionPrimaryHover;
  final Color actionSecondary;
  final Color actionSecondaryHover;

  // Surface colors (backgrounds, cards, containers)
  final Color surfaceBase;
  final Color surfaceElevated;
  final Color surfaceOverlay;
  final Color surfaceHigh;

  // Content colors (text, icons)
  final Color contentPrimary;
  final Color contentSecondary;
  final Color contentTertiary;
  final Color contentInverse;

  // Border colors
  final Color borderDefault;
  final Color borderSubtle;
  final Color borderStrong;

  // Feedback colors (status indicators)
  final Color feedbackSuccess;
  final Color feedbackError;
  final Color feedbackWarning;
  final Color feedbackInfo;

  /// Light theme semantic colors
  static const light = ColorSemantic(
    // Actions
    actionPrimary: ColorPrimitives.blue50,
    actionPrimaryHover: ColorPrimitives.blue60,
    actionSecondary: ColorPrimitives.purple50,
    actionSecondaryHover: ColorPrimitives.purple60,

    // Surfaces
    surfaceBase: ColorPrimitives.gray98,
    surfaceElevated: ColorPrimitives.white,
    surfaceOverlay: ColorPrimitives.gray95,
    surfaceHigh: ColorPrimitives.gray90,

    // Content
    contentPrimary: ColorPrimitives.gray10,
    contentSecondary: ColorPrimitives.gray40,
    contentTertiary: ColorPrimitives.gray60,
    contentInverse: ColorPrimitives.white,

    // Borders
    borderDefault: ColorPrimitives.gray90,
    borderSubtle: ColorPrimitives.gray95,
    borderStrong: ColorPrimitives.gray70,

    // Feedback
    feedbackSuccess: ColorPrimitives.green50,
    feedbackError: ColorPrimitives.red50,
    feedbackWarning: ColorPrimitives.orange50,
    feedbackInfo: ColorPrimitives.blue50,
  );

  /// Dark theme semantic colors
  static const dark = ColorSemantic(
    // Actions
    actionPrimary: ColorPrimitives.blue60,
    actionPrimaryHover: ColorPrimitives.blue70,
    actionSecondary: ColorPrimitives.purple60,
    actionSecondaryHover: ColorPrimitives.purple70,

    // Surfaces
    surfaceBase: ColorPrimitives.gray20,
    surfaceElevated: ColorPrimitives.gray30,
    surfaceOverlay: ColorPrimitives.gray40,
    surfaceHigh: ColorPrimitives.gray50,

    // Content
    contentPrimary: ColorPrimitives.gray95,
    contentSecondary: ColorPrimitives.gray80,
    contentTertiary: ColorPrimitives.gray60,
    contentInverse: ColorPrimitives.gray10,

    // Borders
    borderDefault: ColorPrimitives.gray40,
    borderSubtle: ColorPrimitives.gray30,
    borderStrong: ColorPrimitives.gray60,

    // Feedback
    feedbackSuccess: ColorPrimitives.green60,
    feedbackError: ColorPrimitives.red60,
    feedbackWarning: ColorPrimitives.orange60,
    feedbackInfo: ColorPrimitives.blue60,
  );

  /// Copy with method for customization
  ColorSemantic copyWith({
    Color? actionPrimary,
    Color? actionPrimaryHover,
    Color? actionSecondary,
    Color? actionSecondaryHover,
    Color? surfaceBase,
    Color? surfaceElevated,
    Color? surfaceOverlay,
    Color? surfaceHigh,
    Color? contentPrimary,
    Color? contentSecondary,
    Color? contentTertiary,
    Color? contentInverse,
    Color? borderDefault,
    Color? borderSubtle,
    Color? borderStrong,
    Color? feedbackSuccess,
    Color? feedbackError,
    Color? feedbackWarning,
    Color? feedbackInfo,
  }) {
    return ColorSemantic(
      actionPrimary: actionPrimary ?? this.actionPrimary,
      actionPrimaryHover: actionPrimaryHover ?? this.actionPrimaryHover,
      actionSecondary: actionSecondary ?? this.actionSecondary,
      actionSecondaryHover: actionSecondaryHover ?? this.actionSecondaryHover,
      surfaceBase: surfaceBase ?? this.surfaceBase,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceOverlay: surfaceOverlay ?? this.surfaceOverlay,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      contentPrimary: contentPrimary ?? this.contentPrimary,
      contentSecondary: contentSecondary ?? this.contentSecondary,
      contentTertiary: contentTertiary ?? this.contentTertiary,
      contentInverse: contentInverse ?? this.contentInverse,
      borderDefault: borderDefault ?? this.borderDefault,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      feedbackSuccess: feedbackSuccess ?? this.feedbackSuccess,
      feedbackError: feedbackError ?? this.feedbackError,
      feedbackWarning: feedbackWarning ?? this.feedbackWarning,
      feedbackInfo: feedbackInfo ?? this.feedbackInfo,
    );
  }
}
