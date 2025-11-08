import 'package:injectable/injectable.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';
import '../services/lsp_session_service.dart';
import '../services/diagnostic_service.dart';
import '../services/editor_sync_service.dart';
import '../use_cases/get_completions_use_case.dart';
import '../use_cases/get_hover_info_use_case.dart';
import '../use_cases/get_diagnostics_use_case.dart';
import '../use_cases/go_to_definition_use_case.dart';
import '../use_cases/find_references_use_case.dart';
import '../use_cases/initialize_lsp_session_use_case.dart';
import '../use_cases/shutdown_lsp_session_use_case.dart';

/// Dependency Injection module for LSP Application Layer.
///
/// This module registers all use cases and application services
/// with the dependency injection container.
///
/// Architecture:
/// - Services are singletons (shared across the app)
/// - Use cases are factory (new instance each time)
///
/// Usage:
/// ```dart
/// // In main.dart, configure DI:
/// configureDependencies();
///
/// // Then inject anywhere:
/// final getCompletions = getIt<GetCompletionsUseCase>();
/// ```
@module
abstract class LspApplicationModule {
  // ================================================================
  // Application Services (Singletons)
  // ================================================================

  /// Provides LspSessionService (singleton).
  ///
  /// Manages LSP session lifecycle.
  @singleton
  LspSessionService provideLspSessionService(
    ILspClientRepository lspRepository,
  ) {
    return LspSessionService(lspRepository);
  }

  /// Provides DiagnosticService (singleton).
  ///
  /// Manages diagnostics (errors, warnings, hints).
  @singleton
  DiagnosticService provideDiagnosticService(
    ILspClientRepository lspRepository,
  ) {
    return DiagnosticService(lspRepository);
  }

  /// Provides EditorSyncService (singleton).
  ///
  /// Synchronizes editor state with LSP server.
  @singleton
  EditorSyncService provideEditorSyncService(
    ICodeEditorRepository editorRepository,
    ILspClientRepository lspRepository,
    LspSessionService sessionService,
  ) {
    return EditorSyncService(
      editorRepository: editorRepository,
      lspRepository: lspRepository,
      sessionService: sessionService,
    );
  }

  // ================================================================
  // Use Cases (Factory - new instance each time)
  // ================================================================

  /// Provides GetCompletionsUseCase (factory).
  @injectable
  GetCompletionsUseCase provideGetCompletionsUseCase(
    ILspClientRepository lspRepository,
    ICodeEditorRepository editorRepository,
  ) {
    return GetCompletionsUseCase(lspRepository, editorRepository);
  }

  /// Provides GetHoverInfoUseCase (factory).
  @injectable
  GetHoverInfoUseCase provideGetHoverInfoUseCase(
    ILspClientRepository lspRepository,
    ICodeEditorRepository editorRepository,
  ) {
    return GetHoverInfoUseCase(lspRepository, editorRepository);
  }

  /// Provides GetDiagnosticsUseCase (factory).
  @injectable
  GetDiagnosticsUseCase provideGetDiagnosticsUseCase(
    ILspClientRepository lspRepository,
  ) {
    return GetDiagnosticsUseCase(lspRepository);
  }

  /// Provides GoToDefinitionUseCase (factory).
  @injectable
  GoToDefinitionUseCase provideGoToDefinitionUseCase(
    ILspClientRepository lspRepository,
    ICodeEditorRepository editorRepository,
  ) {
    return GoToDefinitionUseCase(lspRepository, editorRepository);
  }

  /// Provides FindReferencesUseCase (factory).
  @injectable
  FindReferencesUseCase provideFindReferencesUseCase(
    ILspClientRepository lspRepository,
    ICodeEditorRepository editorRepository,
  ) {
    return FindReferencesUseCase(lspRepository, editorRepository);
  }

  /// Provides InitializeLspSessionUseCase (factory).
  @injectable
  InitializeLspSessionUseCase provideInitializeLspSessionUseCase(
    ILspClientRepository lspRepository,
  ) {
    return InitializeLspSessionUseCase(lspRepository);
  }

  /// Provides ShutdownLspSessionUseCase (factory).
  @injectable
  ShutdownLspSessionUseCase provideShutdownLspSessionUseCase(
    ILspClientRepository lspRepository,
  ) {
    return ShutdownLspSessionUseCase(lspRepository);
  }
}
