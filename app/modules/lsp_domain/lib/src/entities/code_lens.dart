import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:editor_core/editor_core.dart';

part 'code_lens.freezed.dart';

/// Code lens is an actionable inline insight in the editor.
///
/// Examples:
/// - "5 references" - click to show all references
/// - "Run Test" - click to execute test
/// - "Debug" - click to debug method
@freezed
class CodeLens with _$CodeLens {
  const factory CodeLens({
    required TextSelection range,
    Command? command,
    dynamic data,
  }) = _CodeLens;
}

/// Command associated with a code lens.
@freezed
class Command with _$Command {
  const factory Command({
    required String title,
    required String command,
    List<dynamic>? arguments,
  }) = _Command;
}
