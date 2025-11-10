import 'package:freezed_annotation/freezed_annotation.dart';

part 'semantic_tokens.freezed.dart';

/// Semantic tokens provide semantic highlighting information.
///
/// Tokens are encoded as an array of integers where each token
/// is represented by 5 consecutive values:
/// - deltaLine (relative to previous token)
/// - deltaStartChar (relative to previous token if same line)
/// - length (token length in characters)
/// - tokenType (index into legend)
/// - tokenModifiers (bitmask into legend)
@freezed
class SemanticTokens with _$SemanticTokens {
  const factory SemanticTokens({
    /// Optional result ID for delta updates
    String? resultId,

    /// Encoded token data (array of integers)
    required List<int> data,
  }) = _SemanticTokens;

  const SemanticTokens._();

  static const empty = SemanticTokens(data: []);
}

/// Semantic tokens delta (incremental update).
@freezed
class SemanticTokensDelta with _$SemanticTokensDelta {
  const factory SemanticTokensDelta({
    String? resultId,
    required List<SemanticTokensEdit> edits,
  }) = _SemanticTokensDelta;
}

/// Edit to semantic tokens data.
@freezed
class SemanticTokensEdit with _$SemanticTokensEdit {
  const factory SemanticTokensEdit({
    /// Start offset in data array
    required int start,

    /// Delete count
    required int deleteCount,

    /// Data to insert
    List<int>? data,
  }) = _SemanticTokensEdit;
}

/// Legend describing token types and modifiers.
@freezed
class SemanticTokensLegend with _$SemanticTokensLegend {
  const factory SemanticTokensLegend({
    required List<String> tokenTypes,
    required List<String> tokenModifiers,
  }) = _SemanticTokensLegend;
}
