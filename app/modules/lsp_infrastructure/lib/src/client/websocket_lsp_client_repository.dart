import 'dart:async';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';
import '../protocol/json_rpc_protocol.dart';
import '../protocol/request_manager.dart';
import '../mappers/lsp_protocol_mappers.dart';

/// WebSocket-based implementation of ILspClientRepository.
///
/// This is the main adapter that connects the domain layer to
/// the Rust LSP Bridge server via WebSocket.
///
/// Architecture:
/// ```
/// Domain (lsp_domain)
///     ↓ depends on
/// ILspClientRepository (port/interface)
///     ↑ implemented by
/// WebSocketLspClientRepository (adapter)
///     ↓ uses
/// WebSocket → Rust LSP Bridge → LSP Servers
/// ```
///
/// Responsibilities:
/// - Manages WebSocket connection to LSP Bridge
/// - Translates domain operations to JSON-RPC requests
/// - Maps LSP protocol responses to domain models
/// - Manages session state
/// - Handles errors and reconnection
///
/// Example:
/// ```dart
/// final repository = WebSocketLspClientRepository(
///   bridgeUrl: 'ws://localhost:9999',
/// );
///
/// await repository.connect();
///
/// final session = await repository.initialize(
///   languageId: LanguageId.dart,
///   rootUri: DocumentUri.fromFilePath('/project'),
/// );
///
/// final completions = await repository.getCompletions(
///   sessionId: session.id,
///   documentUri: DocumentUri.fromFilePath('/file.dart'),
///   position: CursorPosition.create(line: 10, column: 5),
/// );
/// ```
class WebSocketLspClientRepository implements ILspClientRepository {
  final String _bridgeUrl;
  final Duration _connectionTimeout;
  final Duration _requestTimeout;

  WebSocketChannel? _channel;
  final RequestManager _requestManager;
  final Map<LanguageId, LspSession> _sessions = {};

  // Event controllers
  final _diagnosticsController = StreamController<DiagnosticUpdate>.broadcast();
  final _statusController = StreamController<LspServerStatus>.broadcast();

  StreamSubscription? _messageSubscription;
  bool _isConnected = false;

  WebSocketLspClientRepository({
    String bridgeUrl = 'ws://localhost:9999',
    Duration connectionTimeout = const Duration(seconds: 10),
    Duration requestTimeout = const Duration(seconds: 30),
  })  : _bridgeUrl = bridgeUrl,
        _connectionTimeout = connectionTimeout,
        _requestTimeout = requestTimeout,
        _requestManager = RequestManager(
          defaultTimeout: requestTimeout,
          useStringIds: true,
        );

  // ================================================================
  // Connection Management
  // ================================================================

  /// Connects to the LSP Bridge server.
  ///
  /// Must be called before using any LSP operations.
  ///
  /// Returns:
  /// - Right(Unit) on success
  /// - Left(LspFailure) on failure
  Future<Either<LspFailure, Unit>> connect() async {
    if (_isConnected) {
      return right(unit);
    }

    try {
      final uri = Uri.parse(_bridgeUrl);

      _channel = WebSocketChannel.connect(uri);

      // Wait for connection with timeout
      await _channel!.ready.timeout(
        _connectionTimeout,
        onTimeout: () {
          throw TimeoutException(
            'Connection timeout after ${_connectionTimeout.inSeconds}s',
          );
        },
      );

      // Setup message listener
      _setupMessageListener();

      _isConnected = true;
      _statusController.add(LspServerStatus.running);

      return right(unit);
    } catch (e) {
      return left(LspFailure.connectionFailed(
        reason: 'Failed to connect to LSP Bridge: $e',
      ));
    }
  }

  /// Disconnects from the LSP Bridge server.
  Future<void> disconnect() async {
    await _messageSubscription?.cancel();
    await _channel?.sink.close();

    _channel = null;
    _messageSubscription = null;
    _isConnected = false;
    _requestManager.dispose();
    _sessions.clear();

    _statusController.add(LspServerStatus.stopped);
  }

  /// Checks if connected to LSP Bridge.
  bool get isConnected => _isConnected;

  // ================================================================
  // Session Management (ILspClientRepository)
  // ================================================================

  @override
  Future<Either<LspFailure, LspSession>> initialize({
    required LanguageId languageId,
    required DocumentUri rootUri,
  }) async {
    if (!_isConnected) {
      return left(const LspFailure.connectionFailed(
        reason: 'Not connected to LSP Bridge',
      ));
    }

    try {
      // Create JSON-RPC request
      final request = _requestManager.createRequest(
        method: 'initialize',
        params: {
          'languageId': languageId.value,
          'rootUri': rootUri.value,
        },
      );

      // Send request and wait for response
      final responseFuture = _requestManager.waitForResponse(request.id);
      _sendMessage(request);

      final response = await responseFuture;

      if (response.hasError) {
        return left(LspFailure.initializationFailed(
          reason: response.error!.message,
        ));
      }

      // Create session from response
      final sessionId = SessionId.fromString(
        response.result!['sessionId'] as String,
      );

      final session = LspSession(
        id: sessionId,
        languageId: languageId,
        state: SessionState.initialized,
        rootUri: rootUri,
        createdAt: DateTime.now(),
        initializedAt: DateTime.now(),
      );

      // Cache session
      _sessions[languageId] = session;

      return right(session);
    } catch (e) {
      return left(LspFailure.unexpected(
        message: 'Failed to initialize LSP session',
        error: e,
      ));
    }
  }

  @override
  Future<Either<LspFailure, Unit>> shutdown(SessionId sessionId) async {
    if (!_isConnected) {
      return left(const LspFailure.connectionFailed(
        reason: 'Not connected',
      ));
    }

    try {
      final request = _requestManager.createRequest(
        method: 'shutdown',
        params: {
          'sessionId': sessionId.value,
        },
      );

      final responseFuture = _requestManager.waitForResponse(request.id);
      _sendMessage(request);

      final response = await responseFuture;

      if (response.hasError) {
        return left(LspFailure.requestFailed(
          method: 'shutdown',
          reason: response.error!.message,
        ));
      }

      // Remove session from cache
      _sessions.removeWhere((_, session) => session.id == sessionId);

      return right(unit);
    } catch (e) {
      return left(LspFailure.unexpected(
        message: 'Failed to shutdown session',
        error: e,
      ));
    }
  }

  @override
  Future<Either<LspFailure, LspSession>> getSession(
    LanguageId languageId,
  ) async {
    final session = _sessions[languageId];

    if (session == null) {
      return left(LspFailure.sessionNotFound(
        message: 'No session found for language: ${languageId.value}',
      ));
    }

    return right(session);
  }

  @override
  Future<bool> hasSession(LanguageId languageId) async {
    return _sessions.containsKey(languageId);
  }

  // ================================================================
  // Text Document Synchronization (ILspClientRepository)
  // ================================================================

  @override
  Future<Either<LspFailure, Unit>> notifyDocumentOpened({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required LanguageId languageId,
    required String content,
  }) async {
    return _sendNotification(
      method: 'textDocument/didOpen',
      params: {
        'sessionId': sessionId.value,
        'textDocument': LspProtocolMappers.toTextDocumentItem(
          uri: documentUri,
          languageId: languageId,
          text: content,
        ),
      },
    );
  }

  @override
  Future<Either<LspFailure, Unit>> notifyDocumentChanged({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required String content,
  }) async {
    return _sendNotification(
      method: 'textDocument/didChange',
      params: {
        'sessionId': sessionId.value,
        'textDocument': LspProtocolMappers.toVersionedTextDocumentIdentifier(
          documentUri,
        ),
        'contentChanges': [
          {'text': content}
        ],
      },
    );
  }

  @override
  Future<Either<LspFailure, Unit>> notifyDocumentClosed({
    required SessionId sessionId,
    required DocumentUri documentUri,
  }) async {
    return _sendNotification(
      method: 'textDocument/didClose',
      params: {
        'sessionId': sessionId.value,
        'textDocument': LspProtocolMappers.toTextDocumentIdentifier(
          documentUri,
        ),
      },
    );
  }

  @override
  Future<Either<LspFailure, Unit>> notifyDocumentSaved({
    required SessionId sessionId,
    required DocumentUri documentUri,
  }) async {
    return _sendNotification(
      method: 'textDocument/didSave',
      params: {
        'sessionId': sessionId.value,
        'textDocument': LspProtocolMappers.toTextDocumentIdentifier(
          documentUri,
        ),
      },
    );
  }

  // ================================================================
  // Language Features (ILspClientRepository)
  // ================================================================

  @override
  Future<Either<LspFailure, CompletionList>> getCompletions({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required CursorPosition position,
  }) async {
    return _sendRequest(
      method: 'textDocument/completion',
      params: {
        'sessionId': sessionId.value,
        'textDocument': LspProtocolMappers.toTextDocumentIdentifier(
          documentUri,
        ),
        'position': LspProtocolMappers.fromDomainPosition(position),
      },
      mapper: (result) =>
          LspProtocolMappers.toDomainCompletionList(result as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<LspFailure, HoverInfo>> getHoverInfo({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required CursorPosition position,
  }) async {
    return _sendRequest(
      method: 'textDocument/hover',
      params: {
        'sessionId': sessionId.value,
        'textDocument': LspProtocolMappers.toTextDocumentIdentifier(
          documentUri,
        ),
        'position': LspProtocolMappers.fromDomainPosition(position),
      },
      mapper: (result) =>
          LspProtocolMappers.toDomainHoverInfo(result as Map<String, dynamic>?),
    );
  }

  @override
  Future<Either<LspFailure, List<Diagnostic>>> getDiagnostics({
    required SessionId sessionId,
    required DocumentUri documentUri,
  }) async {
    return _sendRequest(
      method: 'textDocument/diagnostic',
      params: {
        'sessionId': sessionId.value,
        'textDocument': LspProtocolMappers.toTextDocumentIdentifier(
          documentUri,
        ),
      },
      mapper: (result) {
        final items = (result as Map<String, dynamic>)['items'] as List?;
        if (items == null) return <Diagnostic>[];

        return items
            .map((item) =>
                LspProtocolMappers.toDomainDiagnostic(item as Map<String, dynamic>))
            .toList();
      },
    );
  }

  @override
  Future<Either<LspFailure, List<Location>>> getDefinition({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required CursorPosition position,
  }) async {
    return _sendRequest(
      method: 'textDocument/definition',
      params: {
        'sessionId': sessionId.value,
        'textDocument': LspProtocolMappers.toTextDocumentIdentifier(
          documentUri,
        ),
        'position': LspProtocolMappers.fromDomainPosition(position),
      },
      mapper: (result) => LspProtocolMappers.toDomainLocations(result as List?),
    );
  }

  @override
  Future<Either<LspFailure, List<Location>>> getReferences({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required CursorPosition position,
    bool includeDeclaration = true,
  }) async {
    return _sendRequest(
      method: 'textDocument/references',
      params: {
        'sessionId': sessionId.value,
        'textDocument': LspProtocolMappers.toTextDocumentIdentifier(
          documentUri,
        ),
        'position': LspProtocolMappers.fromDomainPosition(position),
        'context': {'includeDeclaration': includeDeclaration},
      },
      mapper: (result) => LspProtocolMappers.toDomainLocations(result as List?),
    );
  }

  // ================================================================
  // Events (ILspClientRepository)
  // ================================================================

  @override
  Stream<DiagnosticUpdate> get onDiagnostics => _diagnosticsController.stream;

  @override
  Stream<LspServerStatus> get onStatusChanged => _statusController.stream;

  // ================================================================
  // Private Helper Methods
  // ================================================================

  /// Sends a JSON-RPC request and waits for response.
  Future<Either<LspFailure, T>> _sendRequest<T>({
    required String method,
    required Map<String, dynamic> params,
    required T Function(dynamic) mapper,
  }) async {
    if (!_isConnected) {
      return left(const LspFailure.connectionFailed(reason: 'Not connected'));
    }

    try {
      final request = _requestManager.createRequest(
        method: method,
        params: params,
      );

      final responseFuture = _requestManager.waitForResponse(
        request.id,
        timeout: _requestTimeout,
      );

      _sendMessage(request);

      final response = await responseFuture;

      if (response.hasError) {
        return left(LspFailure.requestFailed(
          method: method,
          reason: response.error!.message,
        ));
      }

      final mappedResult = mapper(response.result);
      return right(mappedResult);
    } on TimeoutException {
      return left(LspFailure.serverNotResponding(
        message: 'Request timeout for method: $method',
      ));
    } catch (e) {
      return left(LspFailure.unexpected(
        message: 'Request failed for method: $method',
        error: e,
      ));
    }
  }

  /// Sends a JSON-RPC notification (no response expected).
  Future<Either<LspFailure, Unit>> _sendNotification({
    required String method,
    required Map<String, dynamic> params,
  }) async {
    if (!_isConnected) {
      return left(const LspFailure.connectionFailed(reason: 'Not connected'));
    }

    try {
      final notification = JsonRpcNotification(
        method: method,
        params: params,
      );

      _sendMessage(notification);

      return right(unit);
    } catch (e) {
      return left(LspFailure.unexpected(
        message: 'Failed to send notification: $method',
        error: e,
      ));
    }
  }

  /// Sends a message to the WebSocket.
  void _sendMessage(Object message) {
    final json = jsonEncode(message);
    _channel?.sink.add(json);
  }

  /// Sets up message listener for incoming messages.
  void _setupMessageListener() {
    _messageSubscription = _channel?.stream.listen(
      (message) {
        _handleIncomingMessage(message as String);
      },
      onError: (error) {
        _statusController.add(LspServerStatus.error);
      },
      onDone: () {
        _isConnected = false;
        _statusController.add(LspServerStatus.stopped);
      },
    );
  }

  /// Handles incoming WebSocket message.
  void _handleIncomingMessage(String message) {
    try {
      final json = jsonDecode(message) as Map<String, dynamic>;

      // Check if it's a response (has 'id')
      if (json.containsKey('id')) {
        final response = JsonRpcResponse.fromJson(json);
        _requestManager.handleResponse(response);
      }
      // Check if it's a notification
      else if (json.containsKey('method')) {
        _handleNotification(json);
      }
    } catch (e) {
      // Invalid JSON or parsing error - log and ignore
    }
  }

  /// Handles incoming notifications from server.
  void _handleNotification(Map<String, dynamic> json) {
    final method = json['method'] as String;
    final params = json['params'] as Map<String, dynamic>?;

    // Handle diagnostic notifications
    if (method == 'textDocument/publishDiagnostics' && params != null) {
      final uri = DocumentUri(params['uri'] as String);
      final diagnosticsJson = params['diagnostics'] as List?;

      if (diagnosticsJson != null) {
        final diagnostics = diagnosticsJson
            .map((d) =>
                LspProtocolMappers.toDomainDiagnostic(d as Map<String, dynamic>))
            .toList();

        _diagnosticsController.add(DiagnosticUpdate(
          documentUri: uri,
          diagnostics: diagnostics,
        ));
      }
    }
  }

  /// Disposes the repository.
  Future<void> dispose() async {
    await disconnect();
    await _diagnosticsController.close();
    await _statusController.close();
  }
}

  // ================================================================
  // Additional Language Features (ILspClientRepository)
  // ================================================================

  @override
  Future<Either<LspFailure, List<CodeAction>>> getCodeActions({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required TextSelection range,
    required List<Diagnostic> diagnostics,
  }) async {
    return _sendRequest(
      method: 'textDocument/codeAction',
      params: {
        'sessionId': sessionId.value,
        'textDocument': LspProtocolMappers.toTextDocumentIdentifier(documentUri),
        'range': LspProtocolMappers.fromDomainRange(range),
        'context': {
          'diagnostics': diagnostics
              .map((d) => LspProtocolMappers.fromDomainDiagnostic(d))
              .toList(),
        },
      },
      mapper: (result) => LspProtocolMappers.toDomainCodeActions(result as List?),
    );
  }

  @override
  Future<Either<LspFailure, SignatureHelp>> getSignatureHelp({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required CursorPosition position,
    String? triggerCharacter,
  }) async {
    return _sendRequest(
      method: 'textDocument/signatureHelp',
      params: {
        'sessionId': sessionId.value,
        'textDocument': LspProtocolMappers.toTextDocumentIdentifier(documentUri),
        'position': LspProtocolMappers.fromDomainPosition(position),
        if (triggerCharacter != null)
          'context': {'triggerCharacter': triggerCharacter},
      },
      mapper: (result) =>
          LspProtocolMappers.toDomainSignatureHelp(result as Map<String, dynamic>?),
    );
  }

  @override
  Future<Either<LspFailure, List<TextEdit>>> formatDocument({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required FormattingOptions options,
  }) async {
    return _sendRequest(
      method: 'textDocument/formatting',
      params: {
        'sessionId': sessionId.value,
        'textDocument': LspProtocolMappers.toTextDocumentIdentifier(documentUri),
        'options': LspProtocolMappers.fromDomainFormattingOptions(options),
      },
      mapper: (result) => LspProtocolMappers.toDomainTextEdits(result as List?),
    );
  }

  @override
  Future<Either<LspFailure, WorkspaceEdit>> rename({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required CursorPosition position,
    required String newName,
  }) async {
    return _sendRequest(
      method: 'textDocument/rename',
      params: {
        'sessionId': sessionId.value,
        'textDocument': LspProtocolMappers.toTextDocumentIdentifier(documentUri),
        'position': LspProtocolMappers.fromDomainPosition(position),
        'newName': newName,
      },
      mapper: (result) =>
          LspProtocolMappers.toDomainWorkspaceEdit(result as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<LspFailure, dynamic>> executeCommand({
    required SessionId sessionId,
    required String command,
    List<dynamic>? arguments,
  }) async {
    return _sendRequest(
      method: 'workspace/executeCommand',
      params: {
        'sessionId': sessionId.value,
        'command': command,
        if (arguments != null) 'arguments': arguments,
      },
      mapper: (result) => result,
    );
  }

  @override
  Future<Either<LspFailure, List<DocumentSymbol>>> getDocumentSymbols({
    required SessionId sessionId,
    required DocumentUri documentUri,
  }) async {
    return _sendRequest(
      method: 'textDocument/documentSymbol',
      params: {
        'sessionId': sessionId.value,
        'textDocument': LspProtocolMappers.toTextDocumentIdentifier(documentUri),
      },
      mapper: (result) =>
          LspProtocolMappers.toDomainDocumentSymbols(result as List?),
    );
  }

  @override
  Future<Either<LspFailure, List<WorkspaceSymbol>>> getWorkspaceSymbols({
    required SessionId sessionId,
    required String query,
  }) async {
    return _sendRequest(
      method: 'workspace/symbol',
      params: {
        'sessionId': sessionId.value,
        'query': query,
      },
      mapper: (result) =>
          LspProtocolMappers.toDomainWorkspaceSymbols(result as List?),
    );
  }

  @override
  Future<Either<LspFailure, CallHierarchyItem?>> prepareCallHierarchy({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required CursorPosition position,
  }) async {
    return _sendRequest(
      method: 'textDocument/prepareCallHierarchy',
      params: {
        'sessionId': sessionId.value,
        'textDocument': LspProtocolMappers.toTextDocumentIdentifier(documentUri),
        'position': LspProtocolMappers.fromDomainPosition(position),
      },
      mapper: (result) =>
          LspProtocolMappers.toDomainCallHierarchyItem(result as List?),
    );
  }

  @override
  Future<Either<LspFailure, List<CallHierarchyIncomingCall>>> getIncomingCalls({
    required SessionId sessionId,
    required CallHierarchyItem item,
  }) async {
    return _sendRequest(
      method: 'callHierarchy/incomingCalls',
      params: {
        'sessionId': sessionId.value,
        'item': LspProtocolMappers.fromDomainCallHierarchyItem(item),
      },
      mapper: (result) =>
          LspProtocolMappers.toDomainIncomingCalls(result as List?),
    );
  }

  @override
  Future<Either<LspFailure, List<CallHierarchyOutgoingCall>>> getOutgoingCalls({
    required SessionId sessionId,
    required CallHierarchyItem item,
  }) async {
    return _sendRequest(
      method: 'callHierarchy/outgoingCalls',
      params: {
        'sessionId': sessionId.value,
        'item': LspProtocolMappers.fromDomainCallHierarchyItem(item),
      },
      mapper: (result) =>
          LspProtocolMappers.toDomainOutgoingCalls(result as List?),
    );
  }

  @override
  Future<Either<LspFailure, TypeHierarchyItem?>> prepareTypeHierarchy({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required CursorPosition position,
  }) async {
    return _sendRequest(
      method: 'textDocument/prepareTypeHierarchy',
      params: {
        'sessionId': sessionId.value,
        'textDocument': LspProtocolMappers.toTextDocumentIdentifier(documentUri),
        'position': LspProtocolMappers.fromDomainPosition(position),
      },
      mapper: (result) =>
          LspProtocolMappers.toDomainTypeHierarchyItem(result as List?),
    );
  }

  @override
  Future<Either<LspFailure, List<TypeHierarchyItem>>> getSupertypes({
    required SessionId sessionId,
    required TypeHierarchyItem item,
  }) async {
    return _sendRequest(
      method: 'typeHierarchy/supertypes',
      params: {
        'sessionId': sessionId.value,
        'item': LspProtocolMappers.fromDomainTypeHierarchyItem(item),
      },
      mapper: (result) => LspProtocolMappers.toDomainTypeHierarchyItems(result as List?),
    );
  }

  @override
  Future<Either<LspFailure, List<TypeHierarchyItem>>> getSubtypes({
    required SessionId sessionId,
    required TypeHierarchyItem item,
  }) async {
    return _sendRequest(
      method: 'typeHierarchy/subtypes',
      params: {
        'sessionId': sessionId.value,
        'item': LspProtocolMappers.fromDomainTypeHierarchyItem(item),
      },
      mapper: (result) => LspProtocolMappers.toDomainTypeHierarchyItems(result as List?),
    );
  }

  @override
  Future<Either<LspFailure, List<CodeLens>>> getCodeLenses({
    required SessionId sessionId,
    required DocumentUri documentUri,
  }) async {
    return _sendRequest(
      method: 'textDocument/codeLens',
      params: {
        'sessionId': sessionId.value,
        'textDocument': LspProtocolMappers.toTextDocumentIdentifier(documentUri),
      },
      mapper: (result) => LspProtocolMappers.toDomainCodeLenses(result as List?),
    );
  }

  @override
  Future<Either<LspFailure, CodeLens>> resolveCodeLens({
    required SessionId sessionId,
    required CodeLens codeLens,
  }) async {
    return _sendRequest(
      method: 'codeLens/resolve',
      params: {
        'sessionId': sessionId.value,
        'codeLens': LspProtocolMappers.fromDomainCodeLens(codeLens),
      },
      mapper: (result) => LspProtocolMappers.toDomainCodeLens(result as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<LspFailure, SemanticTokens>> getSemanticTokens({
    required SessionId sessionId,
    required DocumentUri documentUri,
  }) async {
    return _sendRequest(
      method: 'textDocument/semanticTokens/full',
      params: {
        'sessionId': sessionId.value,
        'textDocument': LspProtocolMappers.toTextDocumentIdentifier(documentUri),
      },
      mapper: (result) => LspProtocolMappers.toDomainSemanticTokens(result as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<LspFailure, SemanticTokensDelta>> getSemanticTokensDelta({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required String previousResultId,
  }) async {
    return _sendRequest(
      method: 'textDocument/semanticTokens/full/delta',
      params: {
        'sessionId': sessionId.value,
        'textDocument': LspProtocolMappers.toTextDocumentIdentifier(documentUri),
        'previousResultId': previousResultId,
      },
      mapper: (result) => LspProtocolMappers.toDomainSemanticTokensDelta(result as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<LspFailure, List<InlayHint>>> getInlayHints({
    required SessionId sessionId,
    required DocumentUri documentUri,
    required TextSelection range,
  }) async {
    return _sendRequest(
      method: 'textDocument/inlayHint',
      params: {
        'sessionId': sessionId.value,
        'textDocument': LspProtocolMappers.toTextDocumentIdentifier(documentUri),
        'range': LspProtocolMappers.fromDomainRange(range),
      },
      mapper: (result) => LspProtocolMappers.toDomainInlayHints(result as List?),
    );
  }

  @override
  Future<Either<LspFailure, InlayHint>> resolveInlayHint({
    required SessionId sessionId,
    required InlayHint hint,
  }) async {
    return _sendRequest(
      method: 'inlayHint/resolve',
      params: {
        'sessionId': sessionId.value,
        'hint': LspProtocolMappers.fromDomainInlayHint(hint),
      },
      mapper: (result) => LspProtocolMappers.toDomainInlayHint(result as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<LspFailure, List<FoldingRange>>> getFoldingRanges({
    required SessionId sessionId,
    required DocumentUri documentUri,
  }) async {
    return _sendRequest(
      method: 'textDocument/foldingRange',
      params: {
        'sessionId': sessionId.value,
        'textDocument': LspProtocolMappers.toTextDocumentIdentifier(documentUri),
      },
      mapper: (result) => LspProtocolMappers.toDomainFoldingRanges(result as List?),
    );
  }

  @override
  Future<Either<LspFailure, List<DocumentLink>>> getDocumentLinks({
    required SessionId sessionId,
    required DocumentUri documentUri,
  }) async {
    return _sendRequest(
      method: 'textDocument/documentLink',
      params: {
        'sessionId': sessionId.value,
        'textDocument': LspProtocolMappers.toTextDocumentIdentifier(documentUri),
      },
      mapper: (result) => LspProtocolMappers.toDomainDocumentLinks(result as List?),
    );
  }

  @override
  Future<Either<LspFailure, DocumentLink>> resolveDocumentLink({
    required SessionId sessionId,
    required DocumentLink link,
  }) async {
    return _sendRequest(
      method: 'documentLink/resolve',
      params: {
        'sessionId': sessionId.value,
        'link': LspProtocolMappers.fromDomainDocumentLink(link),
      },
      mapper: (result) => LspProtocolMappers.toDomainDocumentLink(result as Map<String, dynamic>),
    );
  }
}
