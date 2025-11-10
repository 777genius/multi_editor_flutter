import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';

/// Application Service: Manages inlay hints.
///
/// Inlay hints show additional inline information in the editor:
/// - Type annotations for variables (when type is inferred)
/// - Parameter names in function calls
/// - Return types for functions
/// - Type arguments for generic calls
///
/// Example display:
/// ```dart
/// var name = 'John';  // Shows: var name: String = 'John';
/// print(42);           // Shows: print(object: 42);
/// myList.map((x) =>    // Shows: myList.map((x: int) => ...
/// ```
///
/// This service is responsible for:
/// - Fetching inlay hints from LSP server
/// - Caching hints per document and range
/// - Managing hint visibility settings
/// - Refreshing hints on document changes
///
/// Example:
/// ```dart
/// final service = InlayHintsService(lspRepository);
///
/// // Get hints for visible range
/// final result = await service.getInlayHints(
///   languageId: LanguageId.dart,
///   documentUri: DocumentUri.fromFilePath('/file.dart'),
///   range: visibleRange,
/// );
///
/// result.fold(
///   (failure) => print('Error: $failure'),
///   (hints) => renderInlayHints(hints),
/// );
/// ```
class InlayHintsService {
  final ILspClientRepository _lspRepository;

  /// Cache of inlay hints by document URI and range
  final Map<DocumentUri, Map<TextSelection, List<InlayHint>>> _hintsCache = {};

  /// Stream controller for inlay hint updates
  final _hintsController = StreamController<InlayHintsUpdate>.broadcast();

  /// Whether inlay hints are enabled globally
  bool _enabled = true;

  /// Whether to show type hints
  bool _showTypeHints = true;

  /// Whether to show parameter hints
  bool _showParameterHints = true;

  InlayHintsService(this._lspRepository);

  /// Gets inlay hints for a document range.
  ///
  /// Typically called for the visible viewport range.
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [documentUri]: Document URI
  /// - [range]: Range to get hints for (usually viewport)
  /// - [forceRefresh]: Whether to bypass cache
  ///
  /// Returns:
  /// - Right(List<InlayHint>) on success
  /// - Left(LspFailure) on failure
  Future<Either<LspFailure, List<InlayHint>>> getInlayHints({
    required LanguageId languageId,
    required DocumentUri documentUri,
    required TextSelection range,
    bool forceRefresh = false,
  }) async {
    // Return empty if disabled
    if (!_enabled) {
      return right([]);
    }

    // Check cache if not forcing refresh
    if (!forceRefresh) {
      final cached = _getCachedHints(documentUri, range);
      if (cached != null) {
        return right(cached);
      }
    }

    // Get session
    final sessionResult = await _lspRepository.getSession(languageId);

    return sessionResult.fold(
      (failure) => left(failure),
      (session) async {
        // Fetch inlay hints from LSP
        final hintsResult = await _lspRepository.getInlayHints(
          sessionId: session.id,
          documentUri: documentUri,
          range: range,
        );

        return hintsResult.map((hints) {
          // Filter hints based on settings
          final filteredHints = _filterHints(hints);

          // Update cache
          _updateCache(documentUri, range, filteredHints);

          // Emit update event
          _hintsController.add(InlayHintsUpdate(
            documentUri: documentUri,
            range: range,
            hints: filteredHints,
          ));

          return filteredHints;
        });
      },
    );
  }

  /// Resolves an inlay hint (fetches additional data).
  ///
  /// Some inlay hints are returned partially and need resolution
  /// to get tooltip or label details.
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [hint]: Hint to resolve
  ///
  /// Returns:
  /// - Right(InlayHint) - resolved hint
  /// - Left(LspFailure) on failure
  Future<Either<LspFailure, InlayHint>> resolveInlayHint({
    required LanguageId languageId,
    required InlayHint hint,
  }) async {
    // Get session
    final sessionResult = await _lspRepository.getSession(languageId);

    return sessionResult.fold(
      (failure) => left(failure),
      (session) async {
        // Resolve hint from LSP
        return _lspRepository.resolveInlayHint(
          sessionId: session.id,
          hint: hint,
        );
      },
    );
  }

  /// Refreshes inlay hints for a document range.
  ///
  /// Should be called when:
  /// - User scrolls (new viewport range)
  /// - Document content changes
  /// - Settings change
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [documentUri]: Document URI
  /// - [range]: Range to refresh
  ///
  /// Returns: true if refresh succeeded
  Future<bool> refreshInlayHints({
    required LanguageId languageId,
    required DocumentUri documentUri,
    required TextSelection range,
  }) async {
    final result = await getInlayHints(
      languageId: languageId,
      documentUri: documentUri,
      range: range,
      forceRefresh: true,
    );

    return result.isRight();
  }

  /// Clears inlay hints for a document.
  ///
  /// Parameters:
  /// - [documentUri]: Document URI
  void clearInlayHints({required DocumentUri documentUri}) {
    _hintsCache.remove(documentUri);

    _hintsController.add(InlayHintsUpdate(
      documentUri: documentUri,
      range: TextSelection(
        start: CursorPosition.create(line: 0, column: 0),
        end: CursorPosition.create(line: 0, column: 0),
      ),
      hints: [],
    ));
  }

  /// Clears all inlay hints.
  void clearAllInlayHints() {
    _hintsCache.clear();
  }

  /// Enables or disables inlay hints globally.
  void setEnabled(bool enabled) {
    _enabled = enabled;

    if (!enabled) {
      clearAllInlayHints();
    }
  }

  /// Enables or disables type hints.
  void setShowTypeHints(bool show) {
    _showTypeHints = show;
    _refreshAllCachedHints();
  }

  /// Enables or disables parameter hints.
  void setShowParameterHints(bool show) {
    _showParameterHints = show;
    _refreshAllCachedHints();
  }

  /// Checks if inlay hints are enabled.
  bool get isEnabled => _enabled;

  /// Checks if type hints are shown.
  bool get showTypeHints => _showTypeHints;

  /// Checks if parameter hints are shown.
  bool get showParameterHints => _showParameterHints;

  /// Stream of inlay hint updates.
  Stream<InlayHintsUpdate> get onHintsChanged => _hintsController.stream;

  /// Stream of inlay hint updates for a specific document.
  Stream<InlayHintsUpdate> hintsForDocument({
    required DocumentUri documentUri,
  }) {
    return onHintsChanged.where((update) => update.documentUri == documentUri);
  }

  /// Gets all documents with inlay hints.
  List<DocumentUri> getDocumentsWithHints() {
    return _hintsCache.keys.toList();
  }

  /// Gets count of inlay hints for a document.
  int getHintCount({required DocumentUri documentUri}) {
    final ranges = _hintsCache[documentUri];
    if (ranges == null) return 0;

    return ranges.values.fold(0, (sum, hints) => sum + hints.length);
  }

  /// Filters hints based on settings.
  List<InlayHint> _filterHints(List<InlayHint> hints) {
    return hints.where((hint) {
      if (hint.kind == InlayHintKind.type && !_showTypeHints) {
        return false;
      }
      if (hint.kind == InlayHintKind.parameter && !_showParameterHints) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Gets cached hints for a range.
  List<InlayHint>? _getCachedHints(DocumentUri uri, TextSelection range) {
    final ranges = _hintsCache[uri];
    if (ranges == null) return null;

    // Check for exact range match
    return ranges[range];
  }

  /// Updates cache with new hints.
  void _updateCache(
    DocumentUri uri,
    TextSelection range,
    List<InlayHint> hints,
  ) {
    _hintsCache.putIfAbsent(uri, () => {});
    _hintsCache[uri]![range] = hints;
  }

  /// Refreshes all cached hints (when settings change).
  void _refreshAllCachedHints() {
    final documents = _hintsCache.keys.toList();
    for (final doc in documents) {
      final ranges = _hintsCache[doc]?.keys.toList() ?? [];
      for (final range in ranges) {
        final hints = _hintsCache[doc]![range]!;
        final filtered = _filterHints(hints);
        _hintsCache[doc]![range] = filtered;

        _hintsController.add(InlayHintsUpdate(
          documentUri: doc,
          range: range,
          hints: filtered,
        ));
      }
    }
  }

  /// Disposes the service.
  Future<void> dispose() async {
    await _hintsController.close();
    _hintsCache.clear();
  }
}

/// Inlay hints update event.
class InlayHintsUpdate {
  final DocumentUri documentUri;
  final TextSelection range;
  final List<InlayHint> hints;

  const InlayHintsUpdate({
    required this.documentUri,
    required this.range,
    required this.hints,
  });
}
