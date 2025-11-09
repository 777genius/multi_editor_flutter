import 'package:freezed_annotation/freezed_annotation.dart';

part 'formatting_options.freezed.dart';

/// Options for document formatting
@freezed
class FormattingOptions with _$FormattingOptions {
  const factory FormattingOptions({
    required int tabSize,
    required bool insertSpaces,
    bool? trimTrailingWhitespace,
    bool? insertFinalNewline,
    bool? trimFinalNewlines,
  }) = _FormattingOptions;

  const FormattingOptions._();

  /// Default formatting options
  static FormattingOptions defaults() => const FormattingOptions(
        tabSize: 2,
        insertSpaces: true,
        trimTrailingWhitespace: true,
        insertFinalNewline: true,
        trimFinalNewlines: true,
      );
}
