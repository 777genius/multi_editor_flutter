import 'package:dartz/dartz.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';

/// Use Case: Find all references to a symbol.
///
/// This use case finds all places where a symbol (function, variable, class)
/// is referenced throughout the codebase.
///
/// SRP: One responsibility - find references.
///
/// Example:
/// ```dart
/// final useCase = FindReferencesUseCase(lspRepository);
///
/// final result = await useCase(
///   languageId: LanguageId.dart,
///   documentUri: DocumentUri.fromFilePath('/path/to/file.dart'),
///   position: CursorPosition.create(line: 10, column: 5),
///   includeDeclaration: true,
/// );
///
/// result.fold(
///   (failure) => showError('References not found'),
///   (locations) => showReferencesPanel(locations),
/// );
/// ```
class FindReferencesUseCase {
  final ILspClientRepository _lspRepository;

  const FindReferencesUseCase(this._lspRepository);

  /// Executes the use case.
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [documentUri]: Document URI
  /// - [position]: Position of the symbol
  /// - [includeDeclaration]: Whether to include the declaration itself
  ///
  /// Returns:
  /// - Right(List<Location>) - List of reference locations
  /// - Left(LspFailure) on failure
  Future<Either<LspFailure, List<Location>>> call({
    required LanguageId languageId,
    required DocumentUri documentUri,
    required CursorPosition position,
    bool includeDeclaration = true,
  }) async {
    // Step 1: Get LSP session
    final sessionResult = await _lspRepository.getSession(languageId);

    return sessionResult.fold(
      (failure) => left(failure),
      (session) async {
        // Step 2: Validate session is ready
        if (!session.canHandleRequests) {
          return left(LspFailure.serverNotResponding(
            message: 'LSP session not ready for ${languageId.value}',
          ));
        }

        // Step 3: Request references from LSP server
        return _lspRepository.getReferences(
          sessionId: session.id,
          documentUri: documentUri,
          position: position,
          includeDeclaration: includeDeclaration,
        );
      },
    );
  }
}
