import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:editor_core/editor_core.dart';
import 'completion_list.dart';
import 'diagnostic.dart';

part 'code_action.freezed.dart';

/// Represents a code action from LSP server.
///
/// Code actions include:
/// - Quick fixes for diagnostics
/// - Refactorings (extract, inline, rename, etc.)
/// - Source actions (organize imports, etc.)
@freezed
class CodeAction with _$CodeAction {
  const factory CodeAction({
    required String title,
    required CodeActionKind kind,
    List<Diagnostic>? diagnostics,
    WorkspaceEdit? edit,
    Command? command,
    @Default(false) bool isPreferred,
  }) = _CodeAction;
}

/// Kind of code action
enum CodeActionKind {
  /// Base kind for quickfixes
  quickFix,
  /// Base kind for refactorings
  refactor,
  /// Extract refactorings
  refactorExtract,
  /// Inline refactorings
  refactorInline,
  /// Rewrite refactorings
  refactorRewrite,
  /// Base kind for source actions
  source,
  /// Organize imports source action
  sourceOrganizeImports,
  /// Unknown/custom kind
  other,
}

/// Represents a workspace edit (changes to multiple files)
@freezed
class WorkspaceEdit with _$WorkspaceEdit {
  const factory WorkspaceEdit({
    @Default({}) Map<DocumentUri, List<TextEdit>> changes,
  }) = _WorkspaceEdit;
}

/// Represents a command that can be executed
@freezed
class Command with _$Command {
  const factory Command({
    required String title,
    required String command,
    List<dynamic>? arguments,
  }) = _Command;
}
