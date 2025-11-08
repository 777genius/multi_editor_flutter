import 'package:dartz/dartz.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';

/// Application Service: Manages LSP session lifecycle.
///
/// This service is responsible for:
/// - Creating and managing LSP sessions
/// - Ensuring one session per language
/// - Session health monitoring
/// - Graceful shutdown of sessions
///
/// This is NOT a domain service - it's an application service that
/// coordinates between domain objects and use cases.
///
/// Follows SRP: One responsibility - manage session lifecycle.
///
/// Example:
/// ```dart
/// final service = LspSessionService(lspRepository);
///
/// // Get or create session
/// final session = await service.getOrCreateSession(
///   languageId: LanguageId.dart,
///   rootUri: DocumentUri.fromFilePath('/project'),
/// );
///
/// // Later: shutdown
/// await service.shutdownSession(LanguageId.dart);
/// ```
class LspSessionService {
  final ILspClientRepository _lspRepository;

  /// Cache of active sessions by language ID
  /// This prevents multiple sessions for the same language
  final Map<LanguageId, LspSession> _activeSessions = {};

  LspSessionService(this._lspRepository);

  /// Gets an existing session or creates a new one.
  ///
  /// This method ensures that only one session exists per language.
  /// If a session already exists and is active, it returns the existing one.
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  /// - [rootUri]: Project root URI
  ///
  /// Returns:
  /// - Right(LspSession) - Active session
  /// - Left(LspFailure) on failure
  Future<Either<LspFailure, LspSession>> getOrCreateSession({
    required LanguageId languageId,
    required DocumentUri rootUri,
  }) async {
    // Check cache first
    final cachedSession = _activeSessions[languageId];

    if (cachedSession != null && cachedSession.isActive) {
      return right(cachedSession);
    }

    // Try to get existing session from repository
    final existingResult = await _lspRepository.getSession(languageId);

    final existingSession = existingResult.fold(
      (_) => null,
      (session) => session,
    );

    if (existingSession != null && existingSession.isActive) {
      _activeSessions[languageId] = existingSession;
      return right(existingSession);
    }

    // Create new session
    final initResult = await _lspRepository.initialize(
      languageId: languageId,
      rootUri: rootUri,
    );

    return initResult.map((session) {
      _activeSessions[languageId] = session;
      return session;
    });
  }

  /// Gets an existing session (doesn't create one).
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  ///
  /// Returns:
  /// - Right(LspSession) if exists and is active
  /// - Left(LspFailure) if not found or inactive
  Future<Either<LspFailure, LspSession>> getSession({
    required LanguageId languageId,
  }) async {
    // Check cache - verify isActive before returning
    final cachedSession = _activeSessions[languageId];

    if (cachedSession != null) {
      // CRITICAL FIX: Verify session is still active before returning
      if (cachedSession.isActive) {
        return right(cachedSession);
      } else {
        // Remove stale session from cache
        _activeSessions.remove(languageId);
      }
    }

    // Check repository
    final repoResult = await _lspRepository.getSession(languageId);

    // Update cache if session is active
    return repoResult.map((session) {
      if (session.isActive) {
        _activeSessions[languageId] = session;
      }
      return session;
    });
  }

  /// Checks if a session exists for a language.
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  ///
  /// Returns: true if session exists
  Future<bool> hasSession({
    required LanguageId languageId,
  }) async {
    final sessionResult = await getSession(languageId: languageId);
    return sessionResult.isRight();
  }

  /// Shuts down a session for a specific language.
  ///
  /// This should be called when:
  /// - Closing a project
  /// - Switching languages
  /// - Exiting the IDE
  ///
  /// Parameters:
  /// - [languageId]: Programming language
  ///
  /// Returns:
  /// - Right(Unit) on success
  /// - Left(LspFailure) on failure
  Future<Either<LspFailure, Unit>> shutdownSession({
    required LanguageId languageId,
  }) async {
    final sessionResult = await getSession(languageId: languageId);

    return sessionResult.fold(
      (failure) => left(failure),
      (session) async {
        final shutdownResult = await _lspRepository.shutdown(session.id);

        return shutdownResult.map((_) {
          _activeSessions.remove(languageId);
          return unit;
        });
      },
    );
  }

  /// Shuts down all active sessions.
  ///
  /// This should be called when closing the IDE.
  ///
  /// Returns: Number of sessions shut down successfully
  Future<int> shutdownAllSessions() async {
    var shutdownCount = 0;

    for (final languageId in _activeSessions.keys.toList()) {
      final result = await shutdownSession(languageId: languageId);
      if (result.isRight()) {
        shutdownCount++;
      }
    }

    return shutdownCount;
  }

  /// Gets all active sessions.
  ///
  /// Returns: List of active sessions (filters out stale/inactive sessions)
  List<LspSession> getActiveSessions() {
    // Filter out any stale sessions that became inactive
    final activeSessions = _activeSessions.entries
        .where((entry) => entry.value.isActive)
        .map((entry) => entry.value)
        .toList();

    // Clean up stale sessions from cache
    _activeSessions.removeWhere((_, session) => !session.isActive);

    return activeSessions;
  }

  /// Gets count of active sessions.
  ///
  /// Returns: Number of active sessions
  int getActiveSessionCount() {
    return _activeSessions.length;
  }

  /// Clears the session cache.
  ///
  /// Use with caution - this doesn't shut down sessions,
  /// just clears the cache.
  void clearCache() {
    _activeSessions.clear();
  }
}
