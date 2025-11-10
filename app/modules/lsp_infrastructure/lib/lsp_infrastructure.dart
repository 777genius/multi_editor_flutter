/// LSP Infrastructure Layer
///
/// This package provides infrastructure implementations for LSP functionality.
/// It contains adapters that connect the domain layer to external systems
/// (WebSocket, LSP Bridge server, etc.).
///
/// Architecture Layer: Infrastructure
/// - Implements: lsp_domain interfaces (ILspClientRepository)
/// - Depends on: editor_core, lsp_domain
/// - Used by: Application layer (lsp_application)
///
/// Key Components:
///
/// **Client** (WebSocket LSP Client):
/// - WebSocketLspClientRepository: Main adapter implementing ILspClientRepository
///
/// **Protocol** (JSON-RPC):
/// - JsonRpcRequest: Request model
/// - JsonRpcResponse: Response model
/// - JsonRpcNotification: Notification model
/// - RequestManager: Manages request/response lifecycle
///
/// **Mappers** (Protocol Translation):
/// - LspProtocolMappers: Converts between LSP JSON and domain models
///
/// Example:
/// ```dart
/// // Create repository
/// final repository = WebSocketLspClientRepository(
///   bridgeUrl: 'ws://localhost:9999',
/// );
///
/// // Connect to LSP Bridge
/// await repository.connect();
///
/// // Initialize session
/// final session = await repository.initialize(
///   languageId: LanguageId.dart,
///   rootUri: DocumentUri.fromFilePath('/project'),
/// );
///
/// // Get completions
/// final completions = await repository.getCompletions(
///   sessionId: session.id,
///   documentUri: DocumentUri.fromFilePath('/file.dart'),
///   position: CursorPosition.create(line: 10, column: 5),
/// );
///
/// completions.fold(
///   (failure) => print('Error: $failure'),
///   (list) => print('Got ${list.items.length} completions'),
/// );
///
/// // Dispose
/// await repository.dispose();
/// ```
library lsp_infrastructure;

// Client
export 'src/client/websocket_lsp_client_repository.dart';

// Protocol
export 'src/protocol/json_rpc_protocol.dart';
export 'src/protocol/request_manager.dart';

// Mappers
export 'src/mappers/lsp_protocol_mappers.dart';

// Dependency Injection
export 'src/di/lsp_infrastructure_module.dart';
