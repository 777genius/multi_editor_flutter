import 'package:dartz/dartz.dart';
import 'package:meta/meta.dart';
import 'package:editor_core/editor_core.dart';
import '../entities/lsp_session.dart';
import '../entities/completion_list.dart';
import '../entities/diagnostic.dart';
import '../entities/hover_info.dart';
import '../entities/code_action.dart';
import '../entities/signature_help.dart';
import '../entities/document_symbol.dart';
import '../entities/formatting_options.dart';
import '../entities/call_hierarchy.dart';
import '../entities/type_hierarchy.dart';
import '../entities/location.dart';
import '../value_objects/session_id.dart';
import '../failures/lsp_failure.dart';

/// Repository interface for LSP client operations.
///
/// This is a port in Clean Architecture - the domain layer defines WHAT
/// operations are needed, not HOW they're implemented.
///
/// Implementations can be:
/// - WebSocket-based LSP client (current)
/// - HTTP-based LSP client
/// - Mock LSP client for testing
abstract class ILspClientRepository {
  // ============================================================
  // Session Management
  // ============================================================

  /// Initializes a new LSP session for a language
  Future<Either<LspFailure, LspSession>> initialize({
    required LanguageId languageId,
    required DocumentUri rootUri,
  });

  /// Shuts down an LSP session
  Future<Either<LspFailure, Unit>> shutdown(SessionId sessionId);

  /// Gets an active session by language ID
  Future<Either<LspFailure, LspSession>> getSession(LanguageId languageId);

  /// Checks if a session exists for a language
  Future<bool> hasSession(LanguageId languageId);

  // ============================================================
  // Text Document Synchronization
  // ============================================================

  /// Notifies LSP server that a document was opened
  Future<Either<LspFailure, Unit>> notifyDocumentOpened({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required LanguageId languageId,
    required String content,
  });

  /// Notifies LSP server that a document changed
  Future<Either<LspFailure, Unit>> notifyDocumentChanged({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required String content,
  });

  /// Notifies LSP server that a document was closed
  Future<Either<LspFailure, Unit>> notifyDocumentClosed({
    required SessionId sessionId,
    required DocumentUri documentUri,
  });

  /// Notifies LSP server that a document was saved
  Future<Either<LspFailure, Unit>> notifyDocumentSaved({
    required SessionId sessionId,
    required DocumentUri documentUri,
  });

  // ============================================================
  // Language Features
  // ============================================================

  /// Requests code completions at a position
  Future<Either<LspFailure, CompletionList>> getCompletions({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required CursorPosition position,
  });

  /// Requests hover information at a position
  Future<Either<LspFailure, HoverInfo>> getHoverInfo({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required CursorPosition position,
  });

  /// Requests diagnostics for a document
  Future<Either<LspFailure, List<Diagnostic>>> getDiagnostics({
    required SessionId sessionId,
    required DocumentUri documentUri,
  });

  /// Requests go to definition at a position
  Future<Either<LspFailure, List<Location>>> getDefinition({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required CursorPosition position,
  });

  /// Requests find references at a position
  Future<Either<LspFailure, List<Location>>> getReferences({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required CursorPosition position,
    bool includeDeclaration = true,
  });

  /// Requests code actions (quick fixes, refactorings) for a range
  Future<Either<LspFailure, List<CodeAction>>> getCodeActions({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required TextSelection range,
    required List<Diagnostic> diagnostics,
  });

  /// Requests signature help at a position
  Future<Either<LspFailure, SignatureHelp>> getSignatureHelp({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required CursorPosition position,
    String? triggerCharacter,
  });

  /// Requests document formatting
  Future<Either<LspFailure, List<TextEdit>>> formatDocument({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required FormattingOptions options,
  });

  /// Requests symbol rename
  Future<Either<LspFailure, WorkspaceEdit>> rename({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required CursorPosition position,
    required String newName,
  });

  /// Executes a server command
  Future<Either<LspFailure, dynamic>> executeCommand({
    required SessionId sessionId,
    required String command,
    List<dynamic>? arguments,
  });

  /// Requests document symbols
  Future<Either<LspFailure, List<DocumentSymbol>>> getDocumentSymbols({
    required SessionId sessionId,
    required DocumentUri documentUri,
  });

  /// Requests workspace symbols
  Future<Either<LspFailure, List<WorkspaceSymbol>>> getWorkspaceSymbols({
    required SessionId sessionId,
    required String query,
  });

  /// Prepares call hierarchy at position
  Future<Either<LspFailure, CallHierarchyItem?>> prepareCallHierarchy({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required CursorPosition position,
  });

  /// Gets incoming calls for a call hierarchy item
  Future<Either<LspFailure, List<CallHierarchyIncomingCall>>> getIncomingCalls({
    required SessionId sessionId,
    required CallHierarchyItem item,
  });

  /// Gets outgoing calls for a call hierarchy item
  Future<Either<LspFailure, List<CallHierarchyOutgoingCall>>> getOutgoingCalls({
    required SessionId sessionId,
    required CallHierarchyItem item,
  });

  /// Prepares type hierarchy at position
  Future<Either<LspFailure, TypeHierarchyItem?>> prepareTypeHierarchy({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required CursorPosition position,
  });

  /// Gets supertypes for a type hierarchy item
  Future<Either<LspFailure, List<TypeHierarchyItem>>> getSupertypes({
    required SessionId sessionId,
    required TypeHierarchyItem item,
  });

  /// Gets subtypes for a type hierarchy item
  Future<Either<LspFailure, List<TypeHierarchyItem>>> getSubtypes({
    required SessionId sessionId,
    required TypeHierarchyItem item,
  });

  /// Gets code lenses for a document
  Future<Either<LspFailure, List<CodeLens>>> getCodeLenses({
    required SessionId sessionId,
    required DocumentUri documentUri,
  });

  /// Resolves a code lens (fetches additional data)
  Future<Either<LspFailure, CodeLens>> resolveCodeLens({
    required SessionId sessionId,
    required CodeLens codeLens,
  });

  /// Gets semantic tokens for a document
  Future<Either<LspFailure, SemanticTokens>> getSemanticTokens({
    required SessionId sessionId,
    required DocumentUri documentUri,
  });

  /// Gets semantic tokens delta (incremental update)
  Future<Either<LspFailure, SemanticTokensDelta>> getSemanticTokensDelta({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required String previousResultId,
  });

  /// Gets inlay hints for a document range
  Future<Either<LspFailure, List<InlayHint>>> getInlayHints({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required TextSelection range,
  });

  /// Resolves an inlay hint (fetches additional data)
  Future<Either<LspFailure, InlayHint>> resolveInlayHint({
    required SessionId sessionId,
    required InlayHint hint,
  });

  /// Gets folding ranges for a document
  Future<Either<LspFailure, List<FoldingRange>>> getFoldingRanges({
    required SessionId sessionId,
    required DocumentUri documentUri,
  });

  /// Gets document links for a document
  Future<Either<LspFailure, List<DocumentLink>>> getDocumentLinks({
    required SessionId sessionId,
    required DocumentUri documentUri,
  });

  /// Resolves a document link (fetches target URI)
  Future<Either<LspFailure, DocumentLink>> resolveDocumentLink({
    required SessionId sessionId,
    required DocumentLink link,
  });

  // ============================================================
  // Events
  // ============================================================

  /// Stream of diagnostic updates from LSP server
  Stream<DiagnosticUpdate> get onDiagnostics;

  /// Stream of LSP server status changes
  Stream<LspServerStatus> get onStatusChanged;
}

/// Diagnostic update event
@immutable
class DiagnosticUpdate {
  final DocumentUri documentUri;
  final List<Diagnostic> diagnostics;

  const DiagnosticUpdate({
    required this.documentUri,
    required this.diagnostics,
  });
}

/// LSP server status
enum LspServerStatus {
  starting,
  running,
  stopped,
  error,
}
