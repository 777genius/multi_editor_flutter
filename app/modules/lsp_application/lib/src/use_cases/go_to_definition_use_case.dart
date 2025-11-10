import 'package:dartz/dartz.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';

/// Use Case: Navigate to symbol definition.
///
/// This use case handles "Go to Definition" feature, allowing users
/// to jump to where a symbol (function, class, variable) is defined.
///
/// SRP: One responsibility - navigate to definition.
///
/// Example:
/// ```dart
/// final useCase = GoToDefinitionUseCase(lspRepository, editorRepository);
///
/// final result = await useCase(
///   languageId: LanguageId.dart,
///   documentUri: DocumentUri.fromFilePath('/current/file.dart'),
///   position: CursorPosition.create(line: 10, column: 5),
/// );
///
/// result.fold(
///   (failure) => showError('Definition not found'),
///   (locations) => navigateToLocation(locations.first),
/// );
/// ```
class GoToDefinitionUseCase {
  final ILspClientRepository _lspRepository;
  final ICodeEditorRepository _editorRepository;

  const GoToDefinitionUseCase(
    this._lspRepository,
    this._editorRepository,
  );

  /// Executes the use case.
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [documentUri]: Current document URI
  /// - [position]: Cursor position on the symbol
  ///
  /// Returns:
  /// - Right(List<Location>) - List of definition locations (usually 1)
  /// - Left(LspFailure) on failure
  Future<Either<LspFailure, List<Location>>> call({
    required LanguageId languageId,
    required DocumentUri documentUri,
    required CursorPosition position,
  }) async {
    // Step 1: Get LSP session
    final sessionResult = await _lspRepository.getSession(languageId);

    return sessionResult.fold(
      (failure) => left(failure),
      (session) async {
        // Validate session is ready
        if (!session.canHandleRequests) {
          return left(LspFailure.serverNotResponding(
            message: 'LSP session not ready for ${languageId.value}',
          ));
        }

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

            // Request definition from LSP server
            return _lspRepository.getDefinition(
              sessionId: session.id,
              documentUri: documentUri,
              position: position,
            );
          },
        );
      },
    );
  }
}
