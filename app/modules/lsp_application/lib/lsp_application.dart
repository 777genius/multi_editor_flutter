/// LSP Application Layer
///
/// This package provides use cases and application services for LSP functionality.
/// It orchestrates domain logic and coordinates between domain and infrastructure.
///
/// Architecture Layer: Application
/// - Depends on: editor_core (domain), lsp_domain (domain)
/// - Used by: Presentation layer (UI)
/// - Independent of: Infrastructure details
///
/// Key Components:
///
/// **Use Cases** (Single responsibility, orchestrate domain logic):
/// - GetCompletionsUseCase: Get code completions
/// - GetHoverInfoUseCase: Get hover documentation
/// - GetDiagnosticsUseCase: Get errors/warnings
/// - GoToDefinitionUseCase: Navigate to symbol definition
/// - FindReferencesUseCase: Find all references
/// - InitializeLspSessionUseCase: Initialize LSP server
/// - ShutdownLspSessionUseCase: Shutdown LSP server
///
/// **Application Services** (Coordinate and manage state):
/// - LspSessionService: Manages LSP session lifecycle
/// - EditorSyncService: Syncs editor state with LSP
/// - DiagnosticService: Manages diagnostics aggregation
///
/// Example:
/// ```dart
/// // Initialize services
/// final sessionService = LspSessionService(lspRepository);
/// final syncService = EditorSyncService(
///   editorRepository: editorRepo,
///   lspRepository: lspRepo,
///   sessionService: sessionService,
/// );
///
/// // Use case example
/// final getCompletions = GetCompletionsUseCase(lspRepo, editorRepo);
///
/// final result = await getCompletions(
///   languageId: LanguageId.dart,
///   documentUri: DocumentUri.fromFilePath('/file.dart'),
///   position: CursorPosition.create(line: 10, column: 5),
/// );
///
/// result.fold(
///   (failure) => showError(failure),
///   (completions) => showCompletionPopup(completions),
/// );
/// ```
library lsp_application;

// Use Cases
export 'src/use_cases/get_completions_use_case.dart';
export 'src/use_cases/get_hover_info_use_case.dart';
export 'src/use_cases/get_diagnostics_use_case.dart';
export 'src/use_cases/go_to_definition_use_case.dart';
export 'src/use_cases/find_references_use_case.dart';
export 'src/use_cases/initialize_lsp_session_use_case.dart';
export 'src/use_cases/shutdown_lsp_session_use_case.dart';
export 'src/use_cases/format_document_use_case.dart';
export 'src/use_cases/rename_symbol_use_case.dart';
export 'src/use_cases/get_code_actions_use_case.dart';
export 'src/use_cases/get_signature_help_use_case.dart';
export 'src/use_cases/execute_code_action_use_case.dart';
export 'src/use_cases/get_document_symbols_use_case.dart';
export 'src/use_cases/get_workspace_symbols_use_case.dart';
export 'src/use_cases/get_call_hierarchy_use_case.dart';
export 'src/use_cases/get_type_hierarchy_use_case.dart';

// Application Services
export 'src/services/lsp_session_service.dart';
export 'src/services/editor_sync_service.dart';
export 'src/services/diagnostic_service.dart';
export 'src/services/code_lens_service.dart';
export 'src/services/semantic_tokens_service.dart';
export 'src/services/inlay_hints_service.dart';
export 'src/services/folding_service.dart';
export 'src/services/document_links_service.dart';

// Dependency Injection
export 'src/di/lsp_application_module.dart';
export 'src/di/injection.dart';
