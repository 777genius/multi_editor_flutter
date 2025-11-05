import 'package:freezed_annotation/freezed_annotation.dart';

part 'snippet_data.freezed.dart';
part 'snippet_data.g.dart';

/// Represents a code snippet for autocomplete.
///
/// Snippets appear in Monaco editor's autocomplete dropdown and can be
/// inserted with tab stops and placeholders.
///
/// ## Example:
/// ```dart
/// const ifStatement = SnippetData(
///   prefix: 'if',
///   label: 'if statement',
///   body: 'if (\${1:condition}) {\n  \${2:// code}\n}',
///   description: 'If statement',
/// );
/// ```
@freezed
sealed class SnippetData with _$SnippetData {
  const SnippetData._();

  const factory SnippetData({
    /// The prefix that triggers this snippet (e.g., 'class', 'if', 'stless').
    required String prefix,

    /// The label shown in autocomplete (e.g., 'if statement').
    required String label,

    /// The snippet body with tab stops and placeholders.
    ///
    /// Use Monaco snippet syntax:
    /// - `${1:placeholder}` - tab stop 1 with placeholder text
    /// - `${2}` - tab stop 2
    /// - `$0` - final cursor position
    /// - `\\n` - newline
    /// - `\\t` - tab
    required String body,

    /// Description shown in autocomplete tooltip.
    required String description,
  }) = _SnippetData;

  factory SnippetData.fromJson(Map<String, dynamic> json) =>
      _$SnippetDataFromJson(json);
}
