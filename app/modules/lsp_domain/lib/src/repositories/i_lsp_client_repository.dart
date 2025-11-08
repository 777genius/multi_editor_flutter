import 'package:dartz/dartz.dart';
import 'package:meta/meta.dart';
import 'package:editor_core/editor_core.dart';
import '../entities/lsp_session.dart';
import '../entities/completion_list.dart';
import '../entities/diagnostic.dart';
import '../entities/hover_info.dart';
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
  });

  // ============================================================
  // Events
  // ============================================================

  /// Stream of diagnostic updates from LSP server
  Stream<DiagnosticUpdate> get onDiagnostics;

  /// Stream of LSP server status changes
  Stream<LspServerStatus> get onStatusChanged;
}

/// Represents a location in a document
@immutable
class Location {
  final DocumentUri uri;
  final TextSelection range;

  const Location({
    required this.uri,
    required this.range,
  });
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
