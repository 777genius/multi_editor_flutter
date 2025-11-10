import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';

/// Application Service: Manages document links.
///
/// Document links are clickable links in:
/// - Comments (HTTP URLs, file paths)
/// - Strings (import paths, resource URLs)
/// - Imports (go to imported file)
///
/// Examples of document links:
/// ```dart
/// // https://example.com/docs  <-- Clickable HTTP link
/// import 'package:foo/bar.dart';  <-- Go to file
/// final url = 'assets/image.png';  <-- Open resource
/// ```
///
/// This service is responsible for:
/// - Fetching document links from LSP server
/// - Caching links per document
/// - Resolving link targets on-demand
/// - Handling link activation (open URL/file)
///
/// Example:
/// ```dart
/// final service = DocumentLinksService(lspRepository);
///
/// // Get all links in document
/// final result = await service.getDocumentLinks(
///   languageId: LanguageId.dart,
///   documentUri: DocumentUri.fromFilePath('/file.dart'),
/// );
///
/// result.fold(
///   (failure) => print('Error: $failure'),
///   (links) {
///     for (final link in links) {
///       renderLink(link.range, link.target);
///     }
///   },
/// );
///
/// // When user clicks a link
/// await service.resolveDocumentLink(
///   languageId: LanguageId.dart,
///   link: clickedLink,
/// );
/// ```
class DocumentLinksService {
  final ILspClientRepository _lspRepository;

  /// Cache of document links by document URI
  final Map<DocumentUri, List<DocumentLink>> _linksCache = {};

  /// Stream controller for link updates
  final _linksController = StreamController<DocumentLinksUpdate>.broadcast();

  /// Whether document links are enabled
  bool _enabled = true;

  DocumentLinksService(this._lspRepository);

  /// Gets document links for a file.
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [documentUri]: Document URI
  /// - [forceRefresh]: Whether to bypass cache
  ///
  /// Returns:
  /// - Right(List<DocumentLink>) on success
  /// - Left(LspFailure) on failure
  Future<Either<LspFailure, List<DocumentLink>>> getDocumentLinks({
    required LanguageId languageId,
    required DocumentUri documentUri,
    bool forceRefresh = false,
  }) async {
    // Return empty if disabled
    if (!_enabled) {
      return right([]);
    }

    // Check cache if not forcing refresh
    if (!forceRefresh && _linksCache.containsKey(documentUri)) {
      return right(_linksCache[documentUri]!);
    }

    // Get session
    final sessionResult = await _lspRepository.getSession(languageId);

    return sessionResult.fold(
      (failure) => left(failure),
      (session) async {
        // Fetch document links from LSP
        final linksResult = await _lspRepository.getDocumentLinks(
          sessionId: session.id,
          documentUri: documentUri,
        );

        return linksResult.map((links) {
          // Update cache
          _linksCache[documentUri] = links;

          // Emit update event
          _linksController.add(DocumentLinksUpdate(
            documentUri: documentUri,
            links: links,
          ));

          return links;
        });
      },
    );
  }

  /// Resolves a document link (fetches complete target information).
  ///
  /// Some document links are returned partially and need resolution
  /// to get the actual target URL.
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [link]: Link to resolve
  ///
  /// Returns:
  /// - Right(DocumentLink) - resolved link
  /// - Left(LspFailure) on failure
  Future<Either<LspFailure, DocumentLink>> resolveDocumentLink({
    required LanguageId languageId,
    required DocumentLink link,
  }) async {
    // If link already has target, return it
    if (link.target != null) {
      return right(link);
    }

    // Get session
    final sessionResult = await _lspRepository.getSession(languageId);

    return sessionResult.fold(
      (failure) => left(failure),
      (session) async {
        // Resolve link from LSP
        return _lspRepository.resolveDocumentLink(
          sessionId: session.id,
          link: link,
        );
      },
    );
  }

  /// Opens a document link.
  ///
  /// This handles:
  /// - HTTP/HTTPS URLs → open in browser
  /// - File paths → open in editor
  /// - Package imports → navigate to package
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [link]: Link to open
  /// - [linkHandler]: Callback to handle different link types
  ///
  /// Returns:
  /// - Right(Unit) on success
  /// - Left(LspFailure) on failure
  Future<Either<LspFailure, Unit>> openDocumentLink({
    required LanguageId languageId,
    required DocumentLink link,
    required DocumentLinkHandler linkHandler,
  }) async {
    // Resolve link if needed
    final resolveResult = await resolveDocumentLink(
      languageId: languageId,
      link: link,
    );

    return resolveResult.fold(
      (failure) => left(failure),
      (resolvedLink) async {
        if (resolvedLink.target == null) {
          return left(const LspFailure.invalidParams(
            message: 'Document link has no target',
          ));
        }

        // Handle link based on target type
        final target = resolvedLink.target!;

        if (target.startsWith('http://') || target.startsWith('https://')) {
          // HTTP URL
          await linkHandler.openUrl(target);
        } else if (target.startsWith('file://')) {
          // File path
          final filePath = target.replaceFirst('file://', '');
          await linkHandler.openFile(filePath);
        } else {
          // Custom scheme (e.g., package:, dart:)
          await linkHandler.openCustom(target);
        }

        return right(unit);
      },
    );
  }

  /// Refreshes document links for a file.
  ///
  /// Should be called when:
  /// - Document content changes
  /// - User requests manual refresh
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [documentUri]: Document URI
  ///
  /// Returns: true if refresh succeeded
  Future<bool> refreshDocumentLinks({
    required LanguageId languageId,
    required DocumentUri documentUri,
  }) async {
    final result = await getDocumentLinks(
      languageId: languageId,
      documentUri: documentUri,
      forceRefresh: true,
    );

    return result.isRight();
  }

  /// Clears document links for a file.
  ///
  /// Parameters:
  /// - [documentUri]: Document URI
  void clearDocumentLinks({required DocumentUri documentUri}) {
    _linksCache.remove(documentUri);

    _linksController.add(DocumentLinksUpdate(
      documentUri: documentUri,
      links: [],
    ));
  }

  /// Clears all document links.
  void clearAllDocumentLinks() {
    _linksCache.clear();
  }

  /// Enables or disables document links globally.
  void setEnabled(bool enabled) {
    _enabled = enabled;

    if (!enabled) {
      clearAllDocumentLinks();
    }
  }

  /// Checks if document links are enabled.
  bool get isEnabled => _enabled;

  /// Stream of document link updates.
  Stream<DocumentLinksUpdate> get onLinksChanged => _linksController.stream;

  /// Stream of document link updates for a specific file.
  Stream<DocumentLinksUpdate> linksForDocument({
    required DocumentUri documentUri,
  }) {
    return onLinksChanged.where((update) => update.documentUri == documentUri);
  }

  /// Gets all documents with links.
  List<DocumentUri> getDocumentsWithLinks() {
    return _linksCache.keys.toList();
  }

  /// Gets count of links for a document.
  int getLinkCount({required DocumentUri documentUri}) {
    return _linksCache[documentUri]?.length ?? 0;
  }

  /// Gets total link count across all documents.
  int getTotalLinkCount() {
    return _linksCache.values
        .fold(0, (sum, links) => sum + links.length);
  }

  /// Disposes the service.
  Future<void> dispose() async {
    await _linksController.close();
    _linksCache.clear();
  }
}

/// Document links update event.
class DocumentLinksUpdate {
  final DocumentUri documentUri;
  final List<DocumentLink> links;

  const DocumentLinksUpdate({
    required this.documentUri,
    required this.links,
  });
}

/// Handler for different types of document links.
abstract class DocumentLinkHandler {
  /// Opens an HTTP/HTTPS URL.
  Future<void> openUrl(String url);

  /// Opens a file path.
  Future<void> openFile(String filePath);

  /// Opens a custom scheme link (package:, dart:, etc.).
  Future<void> openCustom(String target);
}
