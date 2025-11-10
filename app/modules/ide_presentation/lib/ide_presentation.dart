/// IDE Presentation Layer
///
/// This package provides UI widgets, MobX Stores, and screens for the IDE.
/// It is the outermost layer in Clean Architecture and coordinates user interactions.
///
/// Architecture Layer: Presentation
/// - Depends on: lsp_application (Application), editor_core (Domain), lsp_domain (Domain)
/// - Used by: Main app
/// - Independent of: Infrastructure details
///
/// Key Components:
///
/// **MobX Stores** (Reactive State Management):
/// - EditorStore: Manages editor state (@observable, @action, @computed)
/// - LspStore: Coordinates LSP interactions (@observable, @action, @computed)
///
/// **Widgets** (UI Components):
/// - EditorView: Main code editor widget with Observer pattern
/// - CompletionPopup: Code completion suggestions popup (TODO)
/// - DiagnosticPanel: Errors and warnings panel (TODO)
///
/// **Screens** (Full Page Layouts):
/// - IdeScreen: Main IDE screen with editor, sidebar, panels
///
/// **Dependency Injection**:
/// - Uses GetIt + Injectable for dependency injection
/// - Uses Provider for widget tree store provision
/// - Configured in injection_container.dart
///
/// Architecture Pattern: Clean Architecture + MobX + Provider
/// ```
/// User Interaction
///     ↓ triggers
/// Widget (UI with Observer)
///     ↓ observes @observable
/// MobX Store (Presentation Logic)
///     ↓ calls @action
/// Use Cases (Application Logic)
///     ↓ uses
/// Repositories (Domain Interfaces)
///     ↑ implemented by
/// Infrastructure Adapters
/// ```
///
/// MobX Best Practices Applied:
/// - **@observable**: Reactive state (content, cursor, completions)
/// - **@action**: State mutations (insertText, getCompletions)
/// - **@computed**: Derived state (hasDocument, errorCount)
/// - **Observer**: Granular rebuilds only when observables change
/// - **Provider**: Widget tree dependency provision
/// - **GetIt**: Service locator for stores and use cases
///
/// Example:
/// ```dart
/// // Setup dependency injection
/// await configureDependencies();
///
/// // Provide stores via Provider
/// runApp(
///   MultiProvider(
///     providers: [
///       Provider<EditorStore>(create: (_) => getIt<EditorStore>()),
///       Provider<LspStore>(create: (_) => getIt<LspStore>()),
///     ],
///     child: MyApp(),
///   ),
/// );
///
/// // In widget, get store from Provider or GetIt
/// final editorStore = context.read<EditorStore>();
/// // or
/// final editorStore = getIt<EditorStore>();
///
/// // In widget, observe state
/// Observer(
///   builder: (_) {
///     return Text(editorStore.content);
///   },
/// );
///
/// // Trigger action
/// editorStore.insertText('Hello');
/// ```
library ide_presentation;

// MobX Stores
export 'src/stores/editor/editor_store.dart';
export 'src/stores/lsp/lsp_store.dart';

// Widgets
export 'src/widgets/editor_view.dart';
export 'src/widgets/completion_popup.dart';
export 'src/widgets/diagnostics_panel.dart';
export 'src/widgets/hover_info_widget.dart';
export 'src/widgets/settings_dialog.dart';
export 'src/widgets/error_boundary.dart';
export 'src/widgets/advanced_completion_popup.dart';
export 'src/widgets/file_tree_explorer.dart';
export 'src/widgets/command_palette.dart';
export 'src/widgets/editor_tab_bar.dart';
export 'src/widgets/search_and_replace_panel.dart';

// Screens
export 'src/screens/ide_screen.dart';

// Theme
export 'src/theme/ide_theme.dart';

// Infrastructure Services
export 'src/infrastructure/file_service.dart';
export 'src/infrastructure/file_picker_service.dart';

// Dependency Injection
export 'src/di/injection_container.dart';
