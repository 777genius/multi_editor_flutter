import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';

/// Application Service: Manages semantic tokens for syntax highlighting.
///
/// Semantic tokens provide rich syntax highlighting based on semantic analysis:
/// - Distinguishes between types, variables, functions
/// - Identifies readonly variables, deprecated symbols
/// - Highlights parameters, properties, methods differently
/// - More accurate than regex-based syntax highlighting
///
/// This service is responsible for:
/// - Fetching semantic tokens from LSP server
/// - Caching tokens per document
/// - Handling incremental updates (delta tokens)
/// - Managing token refresh on document changes
///
/// Example:
/// ```dart
/// final service = SemanticTokensService(lspRepository);
///
/// // Get semantic tokens for file
/// final result = await service.getSemanticTokens(
///   languageId: LanguageId.dart,
///   documentUri: DocumentUri.fromFilePath('/file.dart'),
/// );
///
/// result.fold(
///   (failure) => fallbackToBasicHighlighting(),
///   (tokens) => applySemanticHighlighting(tokens),
/// );
///
/// // Listen for token updates
/// service.onTokensChanged.listen((update) {
///   updateHighlighting(update.documentUri, update.tokens);
/// });
/// ```
class SemanticTokensService {
  final ILspClientRepository _lspRepository;

  /// Cache of semantic tokens by document URI
  final Map<DocumentUri, SemanticTokens> _tokensCache = {};

  /// Stream controller for token updates
  final _tokensController = StreamController<SemanticTokensUpdate>.broadcast();

  /// Whether semantic tokens are enabled
  bool _enabled = true;

  SemanticTokensService(this._lspRepository);

  /// Gets semantic tokens for a document.
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [documentUri]: Document URI
  /// - [forceRefresh]: Whether to bypass cache
  ///
  /// Returns:
  /// - Right(SemanticTokens) on success
  /// - Left(LspFailure) on failure
  Future<Either<LspFailure, SemanticTokens>> getSemanticTokens({
    required LanguageId languageId,
    required DocumentUri documentUri,
    bool forceRefresh = false,
  }) async {
    // Return empty if disabled
    if (!_enabled) {
      return right(SemanticTokens.empty());
    }

    // Check cache if not forcing refresh
    if (!forceRefresh && _tokensCache.containsKey(documentUri)) {
      return right(_tokensCache[documentUri]!);
    }

    // Get session
    final sessionResult = await _lspRepository.getSession(languageId);

    return sessionResult.fold(
      (failure) => left(failure),
      (session) async {
        // Fetch semantic tokens from LSP
        final tokensResult = await _lspRepository.getSemanticTokens(
          sessionId: session.id,
          documentUri: documentUri,
        );

        return tokensResult.map((tokens) {
          // Update cache
          _tokensCache[documentUri] = tokens;

          // Emit update event
          _tokensController.add(SemanticTokensUpdate(
            documentUri: documentUri,
            tokens: tokens,
            isDelta: false,
          ));

          return tokens;
        });
      },
    );
  }

  /// Gets semantic tokens delta (incremental update).
  ///
  /// Some LSP servers support incremental token updates for efficiency.
  /// Instead of sending all tokens again, they send only what changed.
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [documentUri]: Document URI
  /// - [previousResultId]: ID from previous token result
  ///
  /// Returns:
  /// - Right(SemanticTokens) - complete tokens after applying delta
  /// - Left(LspFailure) on failure
  Future<Either<LspFailure, SemanticTokens>> getSemanticTokensDelta({
    required LanguageId languageId,
    required DocumentUri documentUri,
    required String previousResultId,
  }) async {
    if (!_enabled) {
      return right(SemanticTokens.empty());
    }

    // Get session
    final sessionResult = await _lspRepository.getSession(languageId);

    return sessionResult.fold(
      (failure) => left(failure),
      (session) async {
        // Fetch semantic tokens delta from LSP
        final deltaResult = await _lspRepository.getSemanticTokensDelta(
          sessionId: session.id,
          documentUri: documentUri,
          previousResultId: previousResultId,
        );

        return deltaResult.map((tokens) {
          // Update cache
          _tokensCache[documentUri] = tokens;

          // Emit delta update event
          _tokensController.add(SemanticTokensUpdate(
            documentUri: documentUri,
            tokens: tokens,
            isDelta: true,
          ));

          return tokens;
        });
      },
    );
  }

  /// Refreshes semantic tokens for a document.
  ///
  /// Should be called when:
  /// - Document content changes significantly
  /// - Dependencies change
  /// - User requests manual refresh
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [documentUri]: Document URI
  ///
  /// Returns: true if refresh succeeded
  Future<bool> refreshSemanticTokens({
    required LanguageId languageId,
    required DocumentUri documentUri,
  }) async {
    final result = await getSemanticTokens(
      languageId: languageId,
      documentUri: documentUri,
      forceRefresh: true,
    );

    return result.isRight();
  }

  /// Clears semantic tokens for a document.
  ///
  /// Parameters:
  /// - [documentUri]: Document URI
  void clearSemanticTokens({required DocumentUri documentUri}) {
    _tokensCache.remove(documentUri);

    _tokensController.add(SemanticTokensUpdate(
      documentUri: documentUri,
      tokens: SemanticTokens.empty(),
      isDelta: false,
    ));
  }

  /// Clears all semantic tokens.
  void clearAllSemanticTokens() {
    _tokensCache.clear();
  }

  /// Enables or disables semantic tokens globally.
  ///
  /// When disabled, getSemanticTokens returns empty tokens.
  void setEnabled(bool enabled) {
    _enabled = enabled;

    if (!enabled) {
      clearAllSemanticTokens();
    }
  }

  /// Checks if semantic tokens are enabled.
  bool get isEnabled => _enabled;

  /// Stream of semantic token updates.
  Stream<SemanticTokensUpdate> get onTokensChanged => _tokensController.stream;

  /// Stream of semantic token updates for a specific document.
  Stream<SemanticTokensUpdate> tokensForDocument({
    required DocumentUri documentUri,
  }) {
    return onTokensChanged
        .where((update) => update.documentUri == documentUri);
  }

  /// Gets all documents with semantic tokens.
  List<DocumentUri> getDocumentsWithSemanticTokens() {
    return _tokensCache.keys.toList();
  }

  /// Checks if semantic tokens are cached for a document.
  bool hasSemanticTokens({required DocumentUri documentUri}) {
    return _tokensCache.containsKey(documentUri);
  }

  /// Disposes the service.
  Future<void> dispose() async {
    await _tokensController.close();
    _tokensCache.clear();
  }
}

/// Semantic tokens update event.
class SemanticTokensUpdate {
  final DocumentUri documentUri;
  final SemanticTokens tokens;
  final bool isDelta;

  const SemanticTokensUpdate({
    required this.documentUri,
    required this.tokens,
    required this.isDelta,
  });
}
