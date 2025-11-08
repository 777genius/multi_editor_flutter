import 'package:freezed_annotation/freezed_annotation.dart';
import '../value_objects/session_id.dart';
import 'package:editor_core/editor_core.dart';

part 'lsp_session.freezed.dart';

/// Represents an LSP session for a specific language.
///
/// This is an aggregate root in DDD - it manages the lifecycle of LSP communication
/// for a particular language server.
@freezed
class LspSession with _$LspSession {
  const factory LspSession({
    required SessionId id,
    required LanguageId languageId,
    required SessionState state,
    required DocumentUri rootUri,
    required DateTime createdAt,
    DateTime? initializedAt,
  }) = _LspSession;

  const LspSession._();

  /// Creates a new session
  factory LspSession.create({
    required LanguageId languageId,
    required DocumentUri rootUri,
  }) {
    return LspSession(
      id: SessionId.generate(),
      languageId: languageId,
      state: SessionState.created,
      rootUri: rootUri,
      createdAt: DateTime.now(),
    );
  }

  /// Marks session as initializing (transition from created to initializing)
  LspSession markInitializing() {
    return copyWith(state: SessionState.initializing);
  }

  /// Marks session as initialized
  LspSession markInitialized() {
    return copyWith(
      state: SessionState.initialized,
      initializedAt: DateTime.now(),
    );
  }

  /// Marks session as failed
  LspSession markFailed() {
    return copyWith(state: SessionState.failed);
  }

  /// Marks session as shutdown
  LspSession markShutdown() {
    return copyWith(state: SessionState.shutdown);
  }

  /// Checks if session can handle requests
  bool get canHandleRequests =>
      state == SessionState.initialized;

  /// Checks if session is active
  bool get isActive =>
      state == SessionState.initialized ||
      state == SessionState.initializing;
}

enum SessionState {
  created,
  initializing,
  initialized,
  failed,
  shutdown,
}
