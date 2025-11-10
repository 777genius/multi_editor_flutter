import 'package:injectable/injectable.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';
import '../services/lsp_session_service.dart';
import '../services/diagnostic_service.dart';
import '../services/editor_sync_service.dart';
import '../services/code_lens_service.dart';
import '../services/semantic_tokens_service.dart';
import '../services/inlay_hints_service.dart';
import '../services/folding_service.dart';
import '../services/document_links_service.dart';
import '../use_cases/get_completions_use_case.dart';
import '../use_cases/get_hover_info_use_case.dart';
import '../use_cases/get_diagnostics_use_case.dart';
import '../use_cases/go_to_definition_use_case.dart';
import '../use_cases/find_references_use_case.dart';
import '../use_cases/initialize_lsp_session_use_case.dart';
import '../use_cases/shutdown_lsp_session_use_case.dart';
import '../use_cases/format_document_use_case.dart';
import '../use_cases/rename_symbol_use_case.dart';
import '../use_cases/get_code_actions_use_case.dart';
import '../use_cases/get_signature_help_use_case.dart';
import '../use_cases/execute_code_action_use_case.dart';
import '../use_cases/get_document_symbols_use_case.dart';
import '../use_cases/get_workspace_symbols_use_case.dart';
import '../use_cases/get_call_hierarchy_use_case.dart';
import '../use_cases/get_type_hierarchy_use_case.dart';

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

  /// Provides CodeLensService (singleton).
  ///
  /// Manages code lenses (inline actionable insights).
  @singleton
  CodeLensService provideCodeLensService(
    ILspClientRepository lspRepository,
  ) {
    return CodeLensService(lspRepository);
  }

  /// Provides SemanticTokensService (singleton).
  ///
  /// Manages semantic tokens for syntax highlighting.
  @singleton
  SemanticTokensService provideSemanticTokensService(
    ILspClientRepository lspRepository,
  ) {
    return SemanticTokensService(lspRepository);
  }

  /// Provides InlayHintsService (singleton).
  ///
  /// Manages inlay hints for type annotations.
  @singleton
  InlayHintsService provideInlayHintsService(
    ILspClientRepository lspRepository,
  ) {
    return InlayHintsService(lspRepository);
  }

  /// Provides FoldingService (singleton).
  ///
  /// Manages code folding regions.
  @singleton
  FoldingService provideFoldingService(
    ILspClientRepository lspRepository,
  ) {
    return FoldingService(lspRepository);
  }

  /// Provides DocumentLinksService (singleton).
  ///
  /// Manages document links.
  @singleton
  DocumentLinksService provideDocumentLinksService(
    ILspClientRepository lspRepository,
  ) {
    return DocumentLinksService(lspRepository);
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
  ) {
    return GetHoverInfoUseCase(lspRepository);
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
  ) {
    return FindReferencesUseCase(lspRepository);
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

  /// Provides FormatDocumentUseCase (factory).
  @injectable
  FormatDocumentUseCase provideFormatDocumentUseCase(
    ILspClientRepository lspRepository,
    ICodeEditorRepository editorRepository,
  ) {
    return FormatDocumentUseCase(lspRepository, editorRepository);
  }

  /// Provides RenameSymbolUseCase (factory).
  @injectable
  RenameSymbolUseCase provideRenameSymbolUseCase(
    ILspClientRepository lspRepository,
    ICodeEditorRepository editorRepository,
  ) {
    return RenameSymbolUseCase(lspRepository, editorRepository);
  }

  /// Provides GetCodeActionsUseCase (factory).
  @injectable
  GetCodeActionsUseCase provideGetCodeActionsUseCase(
    ILspClientRepository lspRepository,
    ICodeEditorRepository editorRepository,
  ) {
    return GetCodeActionsUseCase(lspRepository, editorRepository);
  }

  /// Provides GetSignatureHelpUseCase (factory).
  @injectable
  GetSignatureHelpUseCase provideGetSignatureHelpUseCase(
    ILspClientRepository lspRepository,
    ICodeEditorRepository editorRepository,
  ) {
    return GetSignatureHelpUseCase(lspRepository, editorRepository);
  }

  /// Provides ExecuteCodeActionUseCase (factory).
  @injectable
  ExecuteCodeActionUseCase provideExecuteCodeActionUseCase(
    ILspClientRepository lspRepository,
    ICodeEditorRepository editorRepository,
  ) {
    return ExecuteCodeActionUseCase(lspRepository, editorRepository);
  }

  /// Provides GetDocumentSymbolsUseCase (factory).
  @injectable
  GetDocumentSymbolsUseCase provideGetDocumentSymbolsUseCase(
    ILspClientRepository lspRepository,
  ) {
    return GetDocumentSymbolsUseCase(lspRepository);
  }

  /// Provides GetWorkspaceSymbolsUseCase (factory).
  @injectable
  GetWorkspaceSymbolsUseCase provideGetWorkspaceSymbolsUseCase(
    ILspClientRepository lspRepository,
  ) {
    return GetWorkspaceSymbolsUseCase(lspRepository);
  }

  /// Provides GetCallHierarchyUseCase (factory).
  @injectable
  GetCallHierarchyUseCase provideGetCallHierarchyUseCase(
    ILspClientRepository lspRepository,
  ) {
    return GetCallHierarchyUseCase(lspRepository);
  }

  /// Provides GetTypeHierarchyUseCase (factory).
  @injectable
  GetTypeHierarchyUseCase provideGetTypeHierarchyUseCase(
    ILspClientRepository lspRepository,
  ) {
    return GetTypeHierarchyUseCase(lspRepository);
  }
}
