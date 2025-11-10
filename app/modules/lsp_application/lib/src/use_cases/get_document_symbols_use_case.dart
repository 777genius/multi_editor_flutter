import 'package:dartz/dartz.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';

/// Use Case: Gets document symbols (outline/structure).
///
/// Document symbols provide a hierarchical view of the code structure:
/// - Classes, interfaces, enums
/// - Methods, functions
/// - Properties, fields
/// - Variables, constants
///
/// This is used for:
/// - Document outline view
/// - Breadcrumb navigation
/// - Quick navigation (Cmd+Shift+O)
/// - Folding regions
///
/// Example:
/// ```dart
/// final useCase = GetDocumentSymbolsUseCase(lspRepository);
///
/// final result = await useCase(
///   languageId: LanguageId.dart,
///   documentUri: DocumentUri.fromFilePath('/lib/main.dart'),
/// );
///
/// result.fold(
///   (failure) => showError(failure),
///   (symbols) => displayOutline(symbols),
/// );
/// ```
class GetDocumentSymbolsUseCase {
  final ILspClientRepository _lspRepository;

  GetDocumentSymbolsUseCase(this._lspRepository);

  /// Gets document symbols for a file.
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [documentUri]: Document URI
  ///
  /// Returns:
  /// - Right(List<DocumentSymbol>) on success (hierarchical structure)
  /// - Left(LspFailure) on failure
  Future<Either<LspFailure, List<DocumentSymbol>>> call({
    required LanguageId languageId,
    required DocumentUri documentUri,
  }) async {
    // Get session
    final sessionResult = await _lspRepository.getSession(languageId);

    return sessionResult.fold(
      (failure) => left(failure),
      (session) async {
        // Get document symbols from LSP
        final symbolsResult = await _lspRepository.getDocumentSymbols(
          sessionId: session.id,
          documentUri: documentUri,
        );

        return symbolsResult.map((symbols) {
          // Sort symbols by position for consistent display
          final sortedSymbols = List<DocumentSymbol>.from(symbols);
          _sortSymbolsRecursively(sortedSymbols);
          return sortedSymbols;
        });
      },
    );
  }

  /// Recursively sorts symbols and their children by position.
  void _sortSymbolsRecursively(List<DocumentSymbol> symbols) {
    symbols.sort((a, b) {
      final lineCompare = a.range.start.line.compareTo(b.range.start.line);
      if (lineCompare != 0) return lineCompare;
      return a.range.start.column.compareTo(b.range.start.column);
    });

    for (final symbol in symbols) {
      if (symbol.children != null && symbol.children!.isNotEmpty) {
        _sortSymbolsRecursively(symbol.children!);
      }
    }
  }
}
