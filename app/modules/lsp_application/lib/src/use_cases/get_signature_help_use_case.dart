import 'package:dartz/dartz.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';

/// Use Case: Get signature help (function/method parameter info).
///
/// This use case requests signature help from LSP server.
/// Signature help shows:
/// - Function/method parameter names and types
/// - Current parameter being edited (highlighted)
/// - Overload variants (if multiple signatures exist)
/// - Documentation for parameters
///
/// Flow:
/// 1. Validates that LSP session exists for the language
/// 2. Gets current document state and cursor position
/// 3. Requests signature help from LSP server
/// 4. Returns signature info for UI to display
///
/// Example:
/// ```dart
/// final useCase = GetSignatureHelpUseCase(lspRepository, editorRepository);
///
/// final result = await useCase(
///   languageId: LanguageId.dart,
///   documentUri: DocumentUri.fromFilePath('/file.dart'),
///   position: CursorPosition.create(line: 10, column: 15),
/// );
///
/// result.fold(
///   (failure) => hideSignatureHelp(),
///   (signatureHelp) => showSignatureHelp(signatureHelp),
/// );
/// ```
class GetSignatureHelpUseCase {
  final ILspClientRepository _lspRepository;
  final ICodeEditorRepository _editorRepository;

  const GetSignatureHelpUseCase(
    this._lspRepository,
    this._editorRepository,
  );

  /// Executes the use case.
  ///
  /// Parameters:
  /// - [languageId]: The programming language
  /// - [documentUri]: URI of the document
  /// - [position]: Cursor position (typically inside function call)
  /// - [triggerCharacter]: Character that triggered signature help (e.g., '(', ',')
  ///
  /// Returns:
  /// - Right(SignatureHelp) on success
  /// - Left(LspFailure) on failure
  Future<Either<LspFailure, SignatureHelp>> call({
    required LanguageId languageId,
    required DocumentUri documentUri,
    required CursorPosition position,
    String? triggerCharacter,
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
            final notifyResult = await _lspRepository.notifyDocumentChanged(
              sessionId: session.id,
              documentUri: documentUri,
              content: content,
            );

            // Check if notification failed
            // Note: We continue even if notification fails, but log the error
            // as signature help may still work with stale document state
            notifyResult.fold(
              (failure) {
                // Log warning but don't fail the request
                // Signature help may still work with slightly stale state
              },
              (_) {
                // Notification successful, continue
              },
            );

            // Request signature help from LSP
            return _lspRepository.getSignatureHelp(
              sessionId: session.id,
              documentUri: documentUri,
              position: position,
              triggerCharacter: triggerCharacter,
            );
          },
        );
      },
    );
  }
}
