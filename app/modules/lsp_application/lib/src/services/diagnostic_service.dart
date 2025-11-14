import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:rxdart/rxdart.dart';

/// Application Service: Manages diagnostics (errors, warnings, hints).
///
/// This service is responsible for:
/// - Aggregating diagnostics from multiple sources
/// - Caching diagnostics per document
/// - Providing filtered views (errors only, warnings only, etc.)
/// - Emitting diagnostic update events
///
/// Follows SRP: One responsibility - manage diagnostics.
///
/// Example:
/// ```dart
/// final service = DiagnosticService(lspRepository);
///
/// // Listen to diagnostic updates
/// service.onDiagnosticsChanged.listen((update) {
///   showDiagnostics(update.diagnostics);
/// });
///
/// // Get diagnostics for a document
/// final diagnostics = await service.getDiagnostics(
///   languageId: LanguageId.dart,
///   documentUri: DocumentUri.fromFilePath('/file.dart'),
/// );
/// ```
class DiagnosticService {
  final ILspClientRepository _lspRepository;

  /// Cache of diagnostics by document URI
  final Map<DocumentUri, List<Diagnostic>> _diagnosticsCache = {};

  /// Cache generation number - incremented on clear to invalidate in-flight requests
  int _cacheGeneration = 0;

  /// Stream controller for diagnostic updates
  final _diagnosticsController = StreamController<DiagnosticUpdate>.broadcast();

  DiagnosticService(this._lspRepository);

  /// Gets diagnostics for a document.
  ///
  /// This method:
  /// 1. Checks cache first
  /// 2. If not in cache, fetches from LSP
  /// 3. Updates cache
  /// 4. Emits update event
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [documentUri]: Document URI
  /// - [forceRefresh]: Whether to bypass cache
  ///
  /// Returns:
  /// - Right(List<Diagnostic>) on success
  /// - Left(LspFailure) on failure
  Future<Either<LspFailure, List<Diagnostic>>> getDiagnostics({
    required LanguageId languageId,
    required DocumentUri documentUri,
    bool forceRefresh = false,
  }) async {
    // Check cache if not forcing refresh
    if (!forceRefresh && _diagnosticsCache.containsKey(documentUri)) {
      return right(_diagnosticsCache[documentUri]!);
    }

    // Capture generation BEFORE awaiting - prevents race with clearDiagnostics()
    final generation = _cacheGeneration;

    // Get session
    final sessionResult = await _lspRepository.getSession(languageId);

    return sessionResult.fold(
      (failure) => left(failure),
      (session) async {
        // Fetch diagnostics from LSP
        final diagnosticsResult = await _lspRepository.getDiagnostics(
          sessionId: session.id,
          documentUri: documentUri,
        );

        return diagnosticsResult.map((diagnostics) {
          // CRITICAL: Only update cache if generation hasn't changed
          // If cache was cleared while we were fetching, generation will be different
          // This prevents writing stale data after cache clear
          if (generation == _cacheGeneration) {
            _diagnosticsCache[documentUri] = diagnostics;

            // Emit update event
            _diagnosticsController.add(DiagnosticUpdate(
              documentUri: documentUri,
              diagnostics: diagnostics,
            ));
          }

          return diagnostics;
        });
      },
    );
  }

  /// Gets only errors for a document.
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [documentUri]: Document URI
  ///
  /// Returns: List of errors
  Future<Either<LspFailure, List<Diagnostic>>> getErrors({
    required LanguageId languageId,
    required DocumentUri documentUri,
  }) async {
    final result = await getDiagnostics(
      languageId: languageId,
      documentUri: documentUri,
    );

    return result.map((diagnostics) =>
        diagnostics.where((d) => d.isError).toList());
  }

  /// Gets only warnings for a document.
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [documentUri]: Document URI
  ///
  /// Returns: List of warnings
  Future<Either<LspFailure, List<Diagnostic>>> getWarnings({
    required LanguageId languageId,
    required DocumentUri documentUri,
  }) async {
    final result = await getDiagnostics(
      languageId: languageId,
      documentUri: documentUri,
    );

    return result.map((diagnostics) =>
        diagnostics.where((d) => d.isWarning).toList());
  }

  /// Gets diagnostic counts for a document.
  ///
  /// Parameters:
  /// - [documentUri]: Document URI
  ///
  /// Returns: Map of severity → count
  Map<DiagnosticSeverity, int> getDiagnosticCounts({
    required DocumentUri documentUri,
  }) {
    final diagnostics = _diagnosticsCache[documentUri] ?? [];

    final counts = <DiagnosticSeverity, int>{};

    for (final diagnostic in diagnostics) {
      counts[diagnostic.severity] = (counts[diagnostic.severity] ?? 0) + 1;
    }

    return counts;
  }

  /// Gets error count for a document.
  ///
  /// Parameters:
  /// - [documentUri]: Document URI
  ///
  /// Returns: Number of errors
  int getErrorCount({required DocumentUri documentUri}) {
    return getDiagnosticCounts(documentUri: documentUri)[
            DiagnosticSeverity.error] ??
        0;
  }

  /// Gets warning count for a document.
  ///
  /// Parameters:
  /// - [documentUri]: Document URI
  ///
  /// Returns: Number of warnings
  int getWarningCount({required DocumentUri documentUri}) {
    return getDiagnosticCounts(documentUri: documentUri)[
            DiagnosticSeverity.warning] ??
        0;
  }

  /// Clears diagnostics for a document.
  ///
  /// Parameters:
  /// - [documentUri]: Document URI
  void clearDiagnostics({required DocumentUri documentUri}) {
    _diagnosticsCache.remove(documentUri);
    // Increment generation to invalidate in-flight requests
    _cacheGeneration++;

    _diagnosticsController.add(DiagnosticUpdate(
      documentUri: documentUri,
      diagnostics: [],
    ));
  }

  /// Clears all diagnostics.
  void clearAllDiagnostics() {
    _diagnosticsCache.clear();
    // Increment generation to invalidate in-flight requests
    _cacheGeneration++;
  }

  /// Stream of diagnostic updates.
  ///
  /// Emits whenever diagnostics change for any document.
  Stream<DiagnosticUpdate> get onDiagnosticsChanged =>
      _diagnosticsController.stream;

  /// Stream of diagnostic updates for a specific document.
  ///
  /// Parameters:
  /// - [documentUri]: Document URI to filter by
  ///
  /// Returns: Stream of updates for the document
  Stream<DiagnosticUpdate> diagnosticsForDocument({
    required DocumentUri documentUri,
  }) {
    return onDiagnosticsChanged
        .where((update) => update.documentUri == documentUri);
  }

  /// Gets all documents with diagnostics.
  ///
  /// Returns: List of document URIs
  List<DocumentUri> getDocumentsWithDiagnostics() {
    return _diagnosticsCache.keys.toList();
  }

  /// Gets total diagnostic count across all documents.
  ///
  /// Returns: Total number of diagnostics
  int getTotalDiagnosticCount() {
    return _diagnosticsCache.values
        .fold(0, (sum, diagnostics) => sum + diagnostics.length);
  }

  /// Disposes the service.
  ///
  /// Cleans up resources.
  Future<void> dispose() async {
    await _diagnosticsController.close();
    _diagnosticsCache.clear();
  }
}
