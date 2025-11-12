/// Data models for global search
/// Mirrors Rust WASM structures

/// A single match found in a file
class SearchMatch {
  /// File path where match was found
  final String filePath;

  /// Line number (1-indexed)
  final int lineNumber;

  /// Column number where match starts (0-indexed)
  final int column;

  /// The matched line content
  final String lineContent;

  /// Length of the matched text
  final int matchLength;

  /// Lines before the match (for context)
  final List<String> contextBefore;

  /// Lines after the match (for context)
  final List<String> contextAfter;

  const SearchMatch({
    required this.filePath,
    required this.lineNumber,
    required this.column,
    required this.lineContent,
    required this.matchLength,
    required this.contextBefore,
    required this.contextAfter,
  });

  factory SearchMatch.fromJson(Map<String, dynamic> json) {
    return SearchMatch(
      filePath: json['file_path'] as String,
      lineNumber: json['line_number'] as int,
      column: json['column'] as int,
      lineContent: json['line_content'] as String,
      matchLength: json['match_length'] as int,
      contextBefore: (json['context_before'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      contextAfter: (json['context_after'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  /// Extract the matched text from line content
  String get matchedText {
    if (column + matchLength <= lineContent.length) {
      return lineContent.substring(column, column + matchLength);
    }
    return '';
  }
}

/// Search results containing all matches
class SearchResults {
  /// All matches found
  final List<SearchMatch> matches;

  /// Total number of matches
  final int totalMatches;

  /// Number of files searched
  final int filesSearched;

  /// Number of files with matches
  final int filesWithMatches;

  /// Search duration in milliseconds
  final int durationMs;

  const SearchResults({
    required this.matches,
    required this.totalMatches,
    required this.filesSearched,
    required this.filesWithMatches,
    required this.durationMs,
  });

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    final matchesJson = json['matches'] as List<dynamic>;
    final matches = matchesJson
        .map((m) => SearchMatch.fromJson(m as Map<String, dynamic>))
        .toList();

    return SearchResults(
      matches: matches,
      totalMatches: json['total_matches'] as int,
      filesSearched: json['files_searched'] as int,
      filesWithMatches: json['files_with_matches'] as int,
      durationMs: json['duration_ms'] as int,
    );
  }

  /// Empty search results
  static const empty = SearchResults(
    matches: [],
    totalMatches: 0,
    filesSearched: 0,
    filesWithMatches: 0,
    durationMs: 0,
  );

  /// Group matches by file path
  Map<String, List<SearchMatch>> groupByFile() {
    final grouped = <String, List<SearchMatch>>{};
    for (final match in matches) {
      grouped.putIfAbsent(match.filePath, () => []).add(match);
    }
    return grouped;
  }
}

/// Configuration for search operation
class SearchConfig {
  /// The search pattern (can be regex if useRegex is true)
  final String pattern;

  /// Whether to use regex matching
  final bool useRegex;

  /// Case-insensitive search
  final bool caseInsensitive;

  /// Maximum number of matches to return (0 = unlimited)
  final int maxMatches;

  /// Number of context lines before match
  final int contextBefore;

  /// Number of context lines after match
  final int contextAfter;

  /// File extensions to include (e.g., ["rs", "dart"])
  final List<String> includeExtensions;

  /// File extensions to exclude
  final List<String> excludeExtensions;

  /// Paths to exclude (e.g., ["node_modules", ".git"])
  final List<String> excludePaths;

  const SearchConfig({
    required this.pattern,
    this.useRegex = false,
    this.caseInsensitive = false,
    this.maxMatches = 1000,
    this.contextBefore = 2,
    this.contextAfter = 2,
    this.includeExtensions = const [],
    this.excludeExtensions = const [],
    this.excludePaths = const [
      '.git',
      'node_modules',
      '.dart_tool',
      'build',
      'target',
      '.idea',
      '.vscode',
    ],
  });

  Map<String, dynamic> toJson() {
    return {
      'pattern': pattern,
      'use_regex': useRegex,
      'case_insensitive': caseInsensitive,
      'max_matches': maxMatches,
      'context_before': contextBefore,
      'context_after': contextAfter,
      'include_extensions': includeExtensions,
      'exclude_extensions': excludeExtensions,
      'exclude_paths': excludePaths,
    };
  }
}

/// File content for search
class FileContent {
  final String path;
  final String content;

  const FileContent({
    required this.path,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'content': content,
    };
  }
}
