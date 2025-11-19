import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/painting.dart';

part 'bracket_match.freezed.dart';
part 'bracket_match.g.dart';

/// Type of bracket
enum BracketType {
  @JsonValue('Round')
  round,
  @JsonValue('Curly')
  curly,
  @JsonValue('Square')
  square,
  @JsonValue('Angle')
  angle,
}

extension BracketTypeExtension on BracketType {
  String get displayName {
    return switch (this) {
      BracketType.round => 'Round ()',
      BracketType.curly => 'Curly {}',
      BracketType.square => 'Square []',
      BracketType.angle => 'Angle <>',
    };
  }

  String get openChar {
    return switch (this) {
      BracketType.round => '(',
      BracketType.curly => '{',
      BracketType.square => '[',
      BracketType.angle => '<',
    };
  }

  String get closeChar {
    return switch (this) {
      BracketType.round => ')',
      BracketType.curly => '}',
      BracketType.square => ']',
      BracketType.angle => '>',
    };
  }
}

/// Side of bracket
enum BracketSide {
  @JsonValue('Opening')
  opening,
  @JsonValue('Closing')
  closing,
}

/// Position in source code
@freezed
class BracketPosition with _$BracketPosition {
  const factory BracketPosition({
    required int line,
    required int column,
    required int offset,
  }) = _BracketPosition;

  factory BracketPosition.fromJson(Map<String, dynamic> json) =>
      _$BracketPositionFromJson(json);
}

/// A single bracket
@freezed
class Bracket with _$Bracket {
  const factory Bracket({
    required BracketType bracketType,
    required BracketSide side,
    required BracketPosition position,
    required int depth,
    required int colorLevel,
    required String character,
  }) = _Bracket;

  factory Bracket.fromJson(Map<String, dynamic> json) =>
      _$BracketFromJson(json);
}

/// A matched bracket pair
@freezed
class BracketPair with _$BracketPair {
  const factory BracketPair({
    required Bracket opening,
    required Bracket closing,
    required int depth,
    required bool isMatched,
  }) = _BracketPair;

  const BracketPair._();

  int get colorLevel => opening.colorLevel;
  BracketType get bracketType => opening.bracketType;

  factory BracketPair.fromJson(Map<String, dynamic> json) =>
      _$BracketPairFromJson(json);
}

/// Unmatched bracket reason
enum UnmatchedReason {
  @JsonValue('MissingClosing')
  missingClosing,
  @JsonValue('MissingOpening')
  missingOpening,
  @JsonValue('TypeMismatch')
  typeMismatch,
  @JsonValue('InStringOrComment')
  inStringOrComment,
}

/// Unmatched bracket
@freezed
class UnmatchedBracket with _$UnmatchedBracket {
  const factory UnmatchedBracket({
    required Bracket bracket,
    required String reason,
  }) = _UnmatchedBracket;

  factory UnmatchedBracket.fromJson(Map<String, dynamic> json) =>
      _$UnmatchedBracketFromJson(json);
}

/// Statistics
@freezed
class BracketStatistics with _$BracketStatistics {
  const factory BracketStatistics({
    @Default(0) int roundPairs,
    @Default(0) int curlyPairs,
    @Default(0) int squarePairs,
    @Default(0) int anglePairs,
    @Default(0) int unmatchedCount,
    @Default(0) int mismatchedCount,
  }) = _BracketStatistics;

  const BracketStatistics._();

  int get totalPairs => roundPairs + curlyPairs + squarePairs + anglePairs;

  factory BracketStatistics.fromJson(Map<String, dynamic> json) =>
      _$BracketStatisticsFromJson(json);
}

/// Collection of brackets
@freezed
class BracketCollection with _$BracketCollection {
  const factory BracketCollection({
    required List<BracketPair> pairs,
    required List<UnmatchedBracket> unmatched,
    required int maxDepth,
    required int totalBrackets,
    required int analysisDurationMs,
    required BracketStatistics statistics,
  }) = _BracketCollection;

  const BracketCollection._();

  bool get hasErrors => unmatched.isNotEmpty;

  factory BracketCollection.fromJson(Map<String, dynamic> json) =>
      _$BracketCollectionFromJson(json);
}

/// Color scheme
@freezed
class ColorScheme with _$ColorScheme {
  const factory ColorScheme({
    required List<String> colors,
    @Default(true) bool enabled,
    @Default(100) int maxDepth,
  }) = _ColorScheme;

  const ColorScheme._();

  /// Default rainbow colors
  factory ColorScheme.rainbow() => const ColorScheme(
        colors: [
          '#FFD700', // Gold
          '#DA70D6', // Orchid
          '#179FFF', // Sky Blue
          '#FF6347', // Tomato
          '#3CB371', // Medium Sea Green
          '#FF8C00', // Dark Orange
        ],
      );

  /// Monochrome scheme
  factory ColorScheme.monochrome(String color) => ColorScheme(
        colors: [color],
      );

  /// Get color for depth level
  Color colorForLevel(int level) {
    if (colors.isEmpty) return const Color(0xFFFFFFFF);
    final index = level % colors.length;
    return _hexToColor(colors[index]);
  }

  /// Convert hex to Color
  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  factory ColorScheme.fromJson(Map<String, dynamic> json) =>
      _$ColorSchemeFromJson(json);
}
