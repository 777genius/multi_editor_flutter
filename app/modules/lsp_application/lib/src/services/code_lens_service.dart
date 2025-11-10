import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';

/// Application Service: Manages code lenses.
///
/// Code lenses are inline actionable insights in the editor, such as:
/// - "5 references" - click to show all references
/// - "Run Test" - click to execute test
/// - "Debug" - click to debug method
/// - Inlay hints for types, parameters
///
/// This service is responsible for:
/// - Fetching code lenses from LSP server
/// - Caching code lenses per document
/// - Resolving code lens commands (when user clicks)
/// - Managing visibility (can be toggled on/off)
///
/// Example:
/// ```dart
/// final service = CodeLensService(lspRepository);
///
/// // Get code lenses for current file
/// final result = await service.getCodeLenses(
///   languageId: LanguageId.dart,
///   documentUri: DocumentUri.fromFilePath('/file.dart'),
/// );
///
/// result.fold(
///   (failure) => print('Error: $failure'),
///   (codeLenses) => displayCodeLenses(codeLenses),
/// );
/// ```
class CodeLensService {
  final ILspClientRepository _lspRepository;

  /// Cache of code lenses by document URI
  final Map<DocumentUri, List<CodeLens>> _codeLensCache = {};

  /// Access order for LRU eviction (most recently accessed at end)
  final List<DocumentUri> _accessOrder = [];

  /// Maximum number of documents to cache (prevents unbounded growth)
  static const int _maxCacheSize = 100;

  /// Stream controller for code lens updates
  final _codeLensController = StreamController<CodeLensUpdate>.broadcast();

  /// Whether code lenses are enabled
  bool _enabled = true;

  CodeLensService(this._lspRepository);

  /// Gets code lenses for a document.
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [documentUri]: Document URI
  /// - [forceRefresh]: Whether to bypass cache
  ///
  /// Returns:
  /// - Right(List<CodeLens>) on success
  /// - Left(LspFailure) on failure
  Future<Either<LspFailure, List<CodeLens>>> getCodeLenses({
    required LanguageId languageId,
    required DocumentUri documentUri,
    bool forceRefresh = false,
  }) async {
    // Return empty if disabled
    if (!_enabled) {
      return right([]);
    }

    // Check cache if not forcing refresh
    if (!forceRefresh && _codeLensCache.containsKey(documentUri)) {
      // Update access order for LRU
      _updateAccessOrder(documentUri);
      return right(_codeLensCache[documentUri]!);
    }

    // Get session
    final sessionResult = await _lspRepository.getSession(languageId);

    return sessionResult.fold(
      (failure) => left(failure),
      (session) async {
        // Fetch code lenses from LSP
        final codeLensesResult = await _lspRepository.getCodeLenses(
          sessionId: session.id,
          documentUri: documentUri,
        );

        return codeLensesResult.map((codeLenses) {
          // Update cache with LRU eviction
          _addToCache(documentUri, codeLenses);

          // Emit update event
          _codeLensController.add(CodeLensUpdate(
            documentUri: documentUri,
            codeLenses: codeLenses,
          ));

          return codeLenses;
        });
      },
    );
  }

  /// Resolves a code lens (fetches additional data).
  ///
  /// Some code lenses are returned partially and need resolution
  /// to get command details. This happens on-demand when user
  /// hovers over or clicks a code lens.
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [codeLens]: Code lens to resolve
  ///
  /// Returns:
  /// - Right(CodeLens) - resolved code lens
  /// - Left(LspFailure) on failure
  Future<Either<LspFailure, CodeLens>> resolveCodeLens({
    required LanguageId languageId,
    required CodeLens codeLens,
  }) async {
    // Get session
    final sessionResult = await _lspRepository.getSession(languageId);

    return sessionResult.fold(
      (failure) => left(failure),
      (session) async {
        // Resolve code lens from LSP
        return _lspRepository.resolveCodeLens(
          sessionId: session.id,
          codeLens: codeLens,
        );
      },
    );
  }

  /// Executes a code lens command.
  ///
  /// When user clicks a code lens, this executes its associated command.
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [codeLens]: Code lens to execute
  ///
  /// Returns:
  /// - Right(Unit) on success
  /// - Left(LspFailure) on failure
  Future<Either<LspFailure, Unit>> executeCodeLens({
    required LanguageId languageId,
    required CodeLens codeLens,
  }) async {
    if (codeLens.command == null) {
      return left(const LspFailure.invalidParams(
        message: 'Code lens has no command',
      ));
    }

    // Get session
    final sessionResult = await _lspRepository.getSession(languageId);

    return sessionResult.fold(
      (failure) => left(failure),
      (session) async {
        // Execute command via LSP
        return _lspRepository.executeCommand(
          sessionId: session.id,
          command: codeLens.command!.command,
          arguments: codeLens.command!.arguments,
        );
      },
    );
  }

  /// Refreshes code lenses for a document.
  ///
  /// Should be called when:
  /// - Document content changes
  /// - Diagnostics change
  /// - User requests manual refresh
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [documentUri]: Document URI
  ///
  /// Returns: true if refresh succeeded
  Future<bool> refreshCodeLenses({
    required LanguageId languageId,
    required DocumentUri documentUri,
  }) async {
    final result = await getCodeLenses(
      languageId: languageId,
      documentUri: documentUri,
      forceRefresh: true,
    );

    return result.isRight();
  }

  /// Clears code lenses for a document.
  ///
  /// Parameters:
  /// - [documentUri]: Document URI
  void clearCodeLenses({required DocumentUri documentUri}) {
    _codeLensCache.remove(documentUri);
    _accessOrder.remove(documentUri);

    _codeLensController.add(CodeLensUpdate(
      documentUri: documentUri,
      codeLenses: [],
    ));
  }

  /// Clears all code lenses.
  void clearAllCodeLenses() {
    _codeLensCache.clear();
    _accessOrder.clear();
  }

  /// Enables or disables code lenses globally.
  ///
  /// When disabled, getCodeLenses returns empty list.
  void setEnabled(bool enabled) {
    _enabled = enabled;

    if (!enabled) {
      clearAllCodeLenses();
    }
  }

  /// Checks if code lenses are enabled.
  bool get isEnabled => _enabled;

  /// Updates access order for LRU tracking (moves to end = most recently used).
  void _updateAccessOrder(DocumentUri uri) {
    _accessOrder.remove(uri);
    _accessOrder.add(uri);
  }

  /// Adds code lenses to cache with LRU eviction if needed.
  void _addToCache(DocumentUri uri, List<CodeLens> codeLenses) {
    // Evict least recently used entry if cache is full
    if (_codeLensCache.length >= _maxCacheSize && !_codeLensCache.containsKey(uri)) {
      if (_accessOrder.isNotEmpty) {
        final lruUri = _accessOrder.first;
        _codeLensCache.remove(lruUri);
        _accessOrder.removeAt(0);
      }
    }

    // Add or update cache entry
    _codeLensCache[uri] = codeLenses;
    _updateAccessOrder(uri);
  }

  /// Stream of code lens updates.
  Stream<CodeLensUpdate> get onCodeLensChanged => _codeLensController.stream;

  /// Stream of code lens updates for a specific document.
  Stream<CodeLensUpdate> codeLensesForDocument({
    required DocumentUri documentUri,
  }) {
    return onCodeLensChanged
        .where((update) => update.documentUri == documentUri);
  }

  /// Gets all documents with code lenses.
  List<DocumentUri> getDocumentsWithCodeLenses() {
    return _codeLensCache.keys.toList();
  }

  /// Gets count of code lenses for a document.
  int getCodeLensCount({required DocumentUri documentUri}) {
    return _codeLensCache[documentUri]?.length ?? 0;
  }

  /// Gets total code lens count across all documents.
  int getTotalCodeLensCount() {
    return _codeLensCache.values
        .fold(0, (sum, codeLenses) => sum + codeLenses.length);
  }

  /// Disposes the service.
  Future<void> dispose() async {
    await _codeLensController.close();
    _codeLensCache.clear();
  }
}

/// Code lens update event.
class CodeLensUpdate {
  final DocumentUri documentUri;
  final List<CodeLens> codeLenses;

  const CodeLensUpdate({
    required this.documentUri,
    required this.codeLenses,
  });
}
