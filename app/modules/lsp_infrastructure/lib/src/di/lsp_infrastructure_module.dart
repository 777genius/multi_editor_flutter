import 'package:injectable/injectable.dart';
import 'package:lsp_domain/lsp_domain.dart';
import '../client/websocket_lsp_client_repository.dart';

/// Dependency Injection module for LSP Infrastructure Layer.
///
/// This module registers infrastructure implementations
/// with the dependency injection container.
///
/// Architecture:
/// - Repository implementation is a singleton (maintains WebSocket connection)
///
/// Usage:
/// ```dart
/// // In main.dart:
/// configureDependencies();
///
/// // Then inject anywhere:
/// final lspRepository = getIt<ILspClientRepository>();
/// ```
@module
abstract class LspInfrastructureModule {
  // ================================================================
  // LSP Client Repository (Singleton)
  // ================================================================

  /// Provides ILspClientRepository implementation (singleton).
  ///
  /// This is a singleton because:
  /// 1. Maintains persistent WebSocket connection to LSP Bridge
  /// 2. Manages session state
  /// 3. Should be shared across the entire application
  ///
  /// Parameters:
  /// - [bridgeUrl]: WebSocket URL for LSP Bridge (default: ws://localhost:9999)
  @singleton
  ILspClientRepository provideLspClientRepository(
    @Named('lspBridgeUrl') String bridgeUrl,
  ) {
    return WebSocketLspClientRepository(
      bridgeUrl: bridgeUrl,
      connectionTimeout: const Duration(seconds: 10),
      requestTimeout: const Duration(seconds: 30),
    );
  }

  /// Provides default LSP Bridge URL.
  ///
  /// Can be overridden in tests or for custom deployments.
  @singleton
  @Named('lspBridgeUrl')
  String provideLspBridgeUrl() {
    return 'ws://localhost:9999';
  }
}
