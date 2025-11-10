import 'package:dartz/dartz.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';

/// Use Case: Executes a code action (quick fix or refactoring).
///
/// Code actions can be:
/// - Quick fixes (apply to fix diagnostic errors)
/// - Refactorings (extract method, rename, etc.)
/// - Source actions (organize imports, add missing imports)
///
/// This use case handles:
/// 1. Validating the code action
/// 2. Executing the workspace edit if present
/// 3. Executing the command if present
/// 4. Applying edits to the editor
///
/// Example:
/// ```dart
/// final useCase = ExecuteCodeActionUseCase(lspRepository, editorRepository);
///
/// // Execute a quick fix
/// final result = await useCase(
///   languageId: LanguageId.dart,
///   codeAction: selectedCodeAction,
/// );
///
/// result.fold(
///   (failure) => showError('Failed to apply fix: $failure'),
///   (result) => showSuccess('Applied ${result.editsApplied} edits'),
/// );
/// ```
class ExecuteCodeActionUseCase {
  final ILspClientRepository _lspRepository;
  final ICodeEditorRepository _editorRepository;

  ExecuteCodeActionUseCase(
    this._lspRepository,
    this._editorRepository,
  );

  /// Executes a code action.
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [codeAction]: The code action to execute
  ///
  /// Returns:
  /// - Right(ExecuteCodeActionResult) on success
  /// - Left(LspFailure) on failure
  Future<Either<LspFailure, ExecuteCodeActionResult>> call({
    required LanguageId languageId,
    required CodeAction codeAction,
  }) async {
    // Validate code action has either edit or command
    if (codeAction.edit == null && codeAction.command == null) {
      return left(const LspFailure.invalidParams(
        message: 'Code action has neither edit nor command',
      ));
    }

    // Get session
    final sessionResult = await _lspRepository.getSession(languageId);

    return sessionResult.fold(
      (failure) => left(failure),
      (session) async {
        var editsApplied = 0;
        var commandExecuted = false;

        // Step 1: Apply workspace edit if present
        if (codeAction.edit != null) {
          final applyResult = await _applyWorkspaceEdit(
            codeAction.edit!,
          );

          if (applyResult.isLeft()) {
            return applyResult.map((_) => ExecuteCodeActionResult(
                  editsApplied: 0,
                  commandExecuted: false,
                ));
          }

          applyResult.fold(
            (_) => null,
            (count) => editsApplied = count,
          );
        }

        // Step 2: Execute command if present
        if (codeAction.command != null) {
          final commandResult = await _lspRepository.executeCommand(
            sessionId: session.id,
            command: codeAction.command!.command,
            arguments: codeAction.command!.arguments,
          );

          if (commandResult.isLeft()) {
            return commandResult.map((_) => ExecuteCodeActionResult(
                  editsApplied: editsApplied,
                  commandExecuted: false,
                ));
          }

          commandExecuted = true;
        }

        return right(ExecuteCodeActionResult(
          editsApplied: editsApplied,
          commandExecuted: commandExecuted,
        ));
      },
    );
  }

  /// Applies workspace edit to the editor.
  ///
  /// Workspace edits can contain changes to multiple files.
  /// This method applies all text edits in reverse order to avoid
  /// offset issues.
  Future<Either<LspFailure, int>> _applyWorkspaceEdit(
    WorkspaceEdit workspaceEdit,
  ) async {
    var totalEditsApplied = 0;

    // Apply edits to each file
    for (final entry in workspaceEdit.changes.entries) {
      final documentUri = entry.key;
      final textEdits = entry.value;

      // Sort edits in reverse order (by position) to avoid offset issues
      final sortedEdits = List<TextEdit>.from(textEdits);
      sortedEdits.sort((a, b) {
        final lineCompare = b.range.start.line.compareTo(a.range.start.line);
        if (lineCompare != 0) return lineCompare;
        return b.range.start.column.compareTo(a.range.start.column);
      });

      // Apply each edit
      for (final edit in sortedEdits) {
        final replaceResult = await _editorRepository.replaceText(
          start: edit.range.start,
          end: edit.range.end,
          text: edit.newText,
        );

        if (replaceResult.isLeft()) {
          return replaceResult.map((_) => 0);
        }

        totalEditsApplied++;
      }
    }

    return right(totalEditsApplied);
  }
}

/// Result of executing a code action.
class ExecuteCodeActionResult {
  /// Number of text edits applied
  final int editsApplied;

  /// Whether a command was executed
  final bool commandExecuted;

  const ExecuteCodeActionResult({
    required this.editsApplied,
    required this.commandExecuted,
  });

  /// Whether the code action execution was successful
  bool get isSuccessful => editsApplied > 0 || commandExecuted;
}
