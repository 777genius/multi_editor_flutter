import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_result.freezed.dart';

/// Search match in a file
@freezed
class SearchMatch with _$SearchMatch {
  const factory SearchMatch({
    required String fileId,
    required String fileName,
    required int line,
    required int column,
    required int matchStart,
    required int matchEnd,
    required String matchedText,
    required String lineContent,
  }) = _SearchMatch;
}

/// Replace preview
@freezed
class ReplacePreview with _$ReplacePreview {
  const factory ReplacePreview({
    required SearchMatch match,
    required String originalText,
    required String replacedText,
    required String replacedLineContent,
    @Default(false) bool applied,
  }) = _ReplacePreview;
}

/// Search session
@freezed
class SearchSession with _$SearchSession {
  const factory SearchSession({
    required String query,
    required bool isRegex,
    required bool caseSensitive,
    required bool wholeWord,
    @Default([]) List<SearchMatch> matches,
    @Default(0) int currentMatchIndex,
  }) = _SearchSession;

  const SearchSession._();

  int get matchCount => matches.length;
  bool get hasMatches => matches.isNotEmpty;
  SearchMatch? get currentMatch =>
      hasMatches ? matches[currentMatchIndex] : null;
}

/// Replace session
@freezed
class ReplaceSession with _$ReplaceSession {
  const factory ReplaceSession({
    required SearchSession searchSession,
    required String replaceText,
    @Default([]) List<ReplacePreview> previews,
  }) = _ReplaceSession;

  const ReplaceSession._();

  int get previewCount => previews.length;
  int get appliedCount => previews.where((p) => p.applied).length;
  int get pendingCount => previews.where((p) => !p.applied).length;
}
