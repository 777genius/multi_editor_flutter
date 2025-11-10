import 'package:dartz/dartz.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';

/// Use Case: Searches for symbols across the entire workspace.
///
/// Workspace symbols allow searching for:
/// - Classes, interfaces, structs
/// - Functions, methods
/// - Variables, constants
/// - Across all files in the workspace
///
/// This is used for:
/// - "Go to Symbol in Workspace" (Cmd+T / Ctrl+T)
/// - Quick navigation to any symbol
/// - Finding definitions across the project
///
/// Supports fuzzy matching - user can type partial names.
///
/// Example:
/// ```dart
/// final useCase = GetWorkspaceSymbolsUseCase(lspRepository);
///
/// // Search for "UserRepo"
/// final result = await useCase(
///   languageId: LanguageId.dart,
///   query: 'UserRepo',
/// );
///
/// result.fold(
///   (failure) => showError(failure),
///   (symbols) {
///     // symbols might include:
///     // - UserRepository (class)
///     // - IUserRepository (interface)
///     // - getUserRepository (function)
///     displaySymbolPicker(symbols);
///   },
/// );
/// ```
class GetWorkspaceSymbolsUseCase {
  final ILspClientRepository _lspRepository;

  GetWorkspaceSymbolsUseCase(this._lspRepository);

  /// Searches for symbols in the workspace.
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [query]: Search query (supports fuzzy matching)
  ///
  /// Returns:
  /// - Right(List<WorkspaceSymbol>) on success
  /// - Left(LspFailure) on failure
  Future<Either<LspFailure, List<WorkspaceSymbol>>> call({
    required LanguageId languageId,
    required String query,
  }) async {
    // Empty query returns all symbols (can be huge - some LSPs limit results)
    if (query.isEmpty) {
      return right([]);
    }

    // Get session
    final sessionResult = await _lspRepository.getSession(languageId);

    return sessionResult.fold(
      (failure) => left(failure),
      (session) async {
        // Search workspace symbols via LSP
        final symbolsResult = await _lspRepository.getWorkspaceSymbols(
          sessionId: session.id,
          query: query,
        );

        return symbolsResult.map((symbols) {
          // Sort by relevance (exact matches first, then by name)
          final sortedSymbols = List<WorkspaceSymbol>.from(symbols);
          sortedSymbols.sort((a, b) {
            final aExact = a.name.toLowerCase() == query.toLowerCase();
            final bExact = b.name.toLowerCase() == query.toLowerCase();

            if (aExact && !bExact) return -1;
            if (!aExact && bExact) return 1;

            // If both exact or both not exact, sort by name
            return a.name.compareTo(b.name);
          });

          return sortedSymbols;
        });
      },
    );
  }
}
