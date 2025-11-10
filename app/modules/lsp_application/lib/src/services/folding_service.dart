import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';

/// Application Service: Manages code folding (collapsing regions).
///
/// Code folding allows collapsing/expanding regions of code:
/// - Functions, methods
/// - Classes, interfaces
/// - Blocks (if, for, while)
/// - Comments
/// - Imports
///
/// This service is responsible for:
/// - Fetching folding ranges from LSP server
/// - Managing fold/unfold state per document
/// - Providing fold all/unfold all functionality
/// - Handling smart folding (fold all functions, comments, etc.)
///
/// Example:
/// ```dart
/// final service = FoldingService(lspRepository);
///
/// // Get folding ranges
/// final result = await service.getFoldingRanges(
///   languageId: LanguageId.dart,
///   documentUri: DocumentUri.fromFilePath('/file.dart'),
/// );
///
/// result.fold(
///   (failure) => print('Error: $failure'),
///   (ranges) => displayFoldingGutters(ranges),
/// );
///
/// // Fold all functions
/// service.foldAllByKind(
///   documentUri: DocumentUri.fromFilePath('/file.dart'),
///   kind: FoldingRangeKind.function,
/// );
/// ```
class FoldingService {
  final ILspClientRepository _lspRepository;

  /// Cache of folding ranges by document URI
  final Map<DocumentUri, List<FoldingRange>> _rangesCache = {};

  /// Folded state by document URI (set of folded range start lines)
  final Map<DocumentUri, Set<int>> _foldedState = {};

  /// Stream controller for folding updates
  final _foldingController = StreamController<FoldingUpdate>.broadcast();

  FoldingService(this._lspRepository);

  /// Gets folding ranges for a document.
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [documentUri]: Document URI
  /// - [forceRefresh]: Whether to bypass cache
  ///
  /// Returns:
  /// - Right(List<FoldingRange>) on success
  /// - Left(LspFailure) on failure
  Future<Either<LspFailure, List<FoldingRange>>> getFoldingRanges({
    required LanguageId languageId,
    required DocumentUri documentUri,
    bool forceRefresh = false,
  }) async {
    // Check cache if not forcing refresh
    if (!forceRefresh && _rangesCache.containsKey(documentUri)) {
      return right(_rangesCache[documentUri]!);
    }

    // Get session
    final sessionResult = await _lspRepository.getSession(languageId);

    return sessionResult.fold(
      (failure) => left(failure),
      (session) async {
        // Fetch folding ranges from LSP
        final rangesResult = await _lspRepository.getFoldingRanges(
          sessionId: session.id,
          documentUri: documentUri,
        );

        return rangesResult.map((ranges) {
          // Sort ranges by start line
          final sortedRanges = List<FoldingRange>.from(ranges);
          sortedRanges.sort((a, b) => a.startLine.compareTo(b.startLine));

          // Update cache
          _rangesCache[documentUri] = sortedRanges;

          // Emit update event
          _foldingController.add(FoldingUpdate(
            documentUri: documentUri,
            ranges: sortedRanges,
            foldedLines: _foldedState[documentUri] ?? {},
          ));

          return sortedRanges;
        });
      },
    );
  }

  /// Folds a range (collapses it).
  ///
  /// Parameters:
  /// - [documentUri]: Document URI
  /// - [range]: Range to fold
  void foldRange({
    required DocumentUri documentUri,
    required FoldingRange range,
  }) {
    _foldedState.putIfAbsent(documentUri, () => {});
    _foldedState[documentUri]!.add(range.startLine);

    _emitFoldingUpdate(documentUri);
  }

  /// Unfolds a range (expands it).
  ///
  /// Parameters:
  /// - [documentUri]: Document URI
  /// - [range]: Range to unfold
  void unfoldRange({
    required DocumentUri documentUri,
    required FoldingRange range,
  }) {
    _foldedState[documentUri]?.remove(range.startLine);

    _emitFoldingUpdate(documentUri);
  }

  /// Toggles fold state of a range.
  ///
  /// Parameters:
  /// - [documentUri]: Document URI
  /// - [range]: Range to toggle
  void toggleFold({
    required DocumentUri documentUri,
    required FoldingRange range,
  }) {
    if (isFolded(documentUri: documentUri, range: range)) {
      unfoldRange(documentUri: documentUri, range: range);
    } else {
      foldRange(documentUri: documentUri, range: range);
    }
  }

  /// Checks if a range is folded.
  ///
  /// Parameters:
  /// - [documentUri]: Document URI
  /// - [range]: Range to check
  ///
  /// Returns: true if folded
  bool isFolded({
    required DocumentUri documentUri,
    required FoldingRange range,
  }) {
    return _foldedState[documentUri]?.contains(range.startLine) ?? false;
  }

  /// Folds all ranges in a document.
  ///
  /// Parameters:
  /// - [documentUri]: Document URI
  void foldAll({required DocumentUri documentUri}) {
    final ranges = _rangesCache[documentUri];
    if (ranges == null) return;

    _foldedState[documentUri] = ranges.map((r) => r.startLine).toSet();

    _emitFoldingUpdate(documentUri);
  }

  /// Unfolds all ranges in a document.
  ///
  /// Parameters:
  /// - [documentUri]: Document URI
  void unfoldAll({required DocumentUri documentUri}) {
    _foldedState[documentUri]?.clear();

    _emitFoldingUpdate(documentUri);
  }

  /// Folds all ranges of a specific kind.
  ///
  /// Parameters:
  /// - [documentUri]: Document URI
  /// - [kind]: Kind of ranges to fold (e.g., comments, imports)
  void foldAllByKind({
    required DocumentUri documentUri,
    required FoldingRangeKind kind,
  }) {
    final ranges = _rangesCache[documentUri];
    if (ranges == null) return;

    _foldedState.putIfAbsent(documentUri, () => {});

    for (final range in ranges) {
      if (range.kind == kind) {
        _foldedState[documentUri]!.add(range.startLine);
      }
    }

    _emitFoldingUpdate(documentUri);
  }

  /// Unfolds all ranges of a specific kind.
  ///
  /// Parameters:
  /// - [documentUri]: Document URI
  /// - [kind]: Kind of ranges to unfold
  void unfoldAllByKind({
    required DocumentUri documentUri,
    required FoldingRangeKind kind,
  }) {
    final ranges = _rangesCache[documentUri];
    if (ranges == null) return;

    for (final range in ranges) {
      if (range.kind == kind) {
        _foldedState[documentUri]?.remove(range.startLine);
      }
    }

    _emitFoldingUpdate(documentUri);
  }

  /// Folds all comments.
  void foldAllComments({required DocumentUri documentUri}) {
    foldAllByKind(documentUri: documentUri, kind: FoldingRangeKind.comment);
  }

  /// Folds all imports.
  void foldAllImports({required DocumentUri documentUri}) {
    foldAllByKind(documentUri: documentUri, kind: FoldingRangeKind.imports);
  }

  /// Folds all regions (user-defined fold markers).
  void foldAllRegions({required DocumentUri documentUri}) {
    foldAllByKind(documentUri: documentUri, kind: FoldingRangeKind.region);
  }

  /// Folds a range at a specific line.
  ///
  /// Useful when user clicks fold gutter at a line.
  ///
  /// Parameters:
  /// - [documentUri]: Document URI
  /// - [line]: Line number
  ///
  /// Returns: true if a range was found and folded
  bool foldAtLine({
    required DocumentUri documentUri,
    required int line,
  }) {
    final ranges = _rangesCache[documentUri];
    if (ranges == null) return false;

    // Find range that starts at this line
    for (final range in ranges) {
      if (range.startLine == line) {
        foldRange(documentUri: documentUri, range: range);
        return true;
      }
    }

    return false;
  }

  /// Refreshes folding ranges for a document.
  ///
  /// Should be called when:
  /// - Document content changes significantly
  /// - User requests manual refresh
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [documentUri]: Document URI
  ///
  /// Returns: true if refresh succeeded
  Future<bool> refreshFoldingRanges({
    required LanguageId languageId,
    required DocumentUri documentUri,
  }) async {
    final result = await getFoldingRanges(
      languageId: languageId,
      documentUri: documentUri,
      forceRefresh: true,
    );

    return result.isRight();
  }

  /// Clears folding ranges for a document.
  ///
  /// Parameters:
  /// - [documentUri]: Document URI
  void clearFoldingRanges({required DocumentUri documentUri}) {
    _rangesCache.remove(documentUri);
    _foldedState.remove(documentUri);

    _foldingController.add(FoldingUpdate(
      documentUri: documentUri,
      ranges: [],
      foldedLines: {},
    ));
  }

  /// Clears all folding ranges.
  void clearAllFoldingRanges() {
    _rangesCache.clear();
    _foldedState.clear();
  }

  /// Stream of folding updates.
  Stream<FoldingUpdate> get onFoldingChanged => _foldingController.stream;

  /// Stream of folding updates for a specific document.
  Stream<FoldingUpdate> foldingForDocument({
    required DocumentUri documentUri,
  }) {
    return onFoldingChanged.where((update) => update.documentUri == documentUri);
  }

  /// Gets all documents with folding ranges.
  List<DocumentUri> getDocumentsWithFolding() {
    return _rangesCache.keys.toList();
  }

  /// Gets count of folding ranges for a document.
  int getFoldingRangeCount({required DocumentUri documentUri}) {
    return _rangesCache[documentUri]?.length ?? 0;
  }

  /// Gets count of folded ranges for a document.
  int getFoldedCount({required DocumentUri documentUri}) {
    return _foldedState[documentUri]?.length ?? 0;
  }

  /// Emits folding update event.
  void _emitFoldingUpdate(DocumentUri documentUri) {
    final ranges = _rangesCache[documentUri] ?? [];
    final foldedLines = _foldedState[documentUri] ?? {};

    _foldingController.add(FoldingUpdate(
      documentUri: documentUri,
      ranges: ranges,
      foldedLines: foldedLines,
    ));
  }

  /// Disposes the service.
  Future<void> dispose() async {
    await _foldingController.close();
    _rangesCache.clear();
    _foldedState.clear();
  }
}

/// Folding update event.
class FoldingUpdate {
  final DocumentUri documentUri;
  final List<FoldingRange> ranges;
  final Set<int> foldedLines;

  const FoldingUpdate({
    required this.documentUri,
    required this.ranges,
    required this.foldedLines,
  });

  /// Gets count of folded ranges.
  int get foldedCount => foldedLines.length;

  /// Gets count of total ranges.
  int get totalRanges => ranges.length;

  /// Checks if all ranges are folded.
  bool get allFolded => foldedCount == totalRanges;

  /// Checks if no ranges are folded.
  bool get noneFolded => foldedCount == 0;
}
