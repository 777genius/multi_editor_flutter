import 'package:dartz/dartz.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';

/// Use Case: Get code actions (quick fixes, refactorings) at cursor.
///
/// This use case requests available code actions from LSP server.
/// Code actions include:
/// - Quick fixes for diagnostics
/// - Refactorings (extract method, inline variable, etc.)
/// - Source actions (organize imports, add missing imports)
///
/// Flow:
/// 1. Validates that LSP session exists for the language
/// 2. Gets current document state and diagnostics
/// 3. Requests code actions from LSP server
/// 4. Returns available actions for UI to display
///
/// Example:
/// ```dart
/// final useCase = GetCodeActionsUseCase(lspRepository, editorRepository);
///
/// final result = await useCase(
///   languageId: LanguageId.dart,
///   documentUri: DocumentUri.fromFilePath('/file.dart'),
///   range: TextSelection(
///     start: CursorPosition.create(line: 10, column: 0),
///     end: CursorPosition.create(line: 10, column: 20),
///   ),
///   diagnostics: diagnosticsAtLine,
/// );
///
/// result.fold(
///   (failure) => showError(failure),
///   (actions) => showQuickFixMenu(actions),
/// );
/// ```
class GetCodeActionsUseCase {
  final ILspClientRepository _lspRepository;
  final ICodeEditorRepository _editorRepository;

  const GetCodeActionsUseCase(
    this._lspRepository,
    this._editorRepository,
  );

  /// Executes the use case.
  ///
  /// Parameters:
  /// - [languageId]: The programming language
  /// - [documentUri]: URI of the document
  /// - [range]: Text range to get code actions for
  /// - [diagnostics]: Diagnostics in the range (optional, for quick fixes)
  ///
  /// Returns:
  /// - Right(List<CodeAction>) on success
  /// - Left(LspFailure) on failure
  Future<Either<LspFailure, List<CodeAction>>> call({
    required LanguageId languageId,
    required DocumentUri documentUri,
    required TextSelection range,
    List<Diagnostic>? diagnostics,
  }) async {
    // Get LSP session
    final sessionResult = await _lspRepository.getSession(languageId);

    return sessionResult.fold(
      (failure) => left(failure),
      (session) async {
        // Get current document content and sync with LSP
        final contentResult = await _editorRepository.getContent();

        return contentResult.fold(
          (failure) => left(const LspFailure.unexpected(
            message: 'Failed to get document content from editor',
          )),
          (content) async {
            // Notify LSP about current document state
            await _lspRepository.notifyDocumentChanged(
              sessionId: session.id,
              documentUri: documentUri,
              content: content,
            );

            // Request code actions from LSP
            final codeActionsResult = await _lspRepository.getCodeActions(
              sessionId: session.id,
              documentUri: documentUri,
              range: range,
              diagnostics: diagnostics ?? [],
            );

            // Sort code actions by priority
            return codeActionsResult.map((actions) {
              actions.sort((a, b) {
                final aPriority = _getActionPriority(a);
                final bPriority = _getActionPriority(b);
                return aPriority.compareTo(bPriority);
              });
              return actions;
            });
          },
        );
      },
    );
  }

  /// Gets priority for sorting code actions.
  ///
  /// Lower number = higher priority.
  int _getActionPriority(CodeAction action) {
    return switch (action.kind) {
      CodeActionKind.quickFix => 0,
      CodeActionKind.refactor => 1,
      CodeActionKind.refactorExtract => 1,
      CodeActionKind.refactorInline => 1,
      CodeActionKind.refactorRewrite => 1,
      CodeActionKind.source => 2,
      CodeActionKind.sourceOrganizeImports => 2,
      _ => 3,
    };
  }
}
