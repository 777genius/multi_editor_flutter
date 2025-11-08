import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:lsp_application/lsp_application.dart';
import 'package:lsp_infrastructure/lsp_infrastructure.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';

import 'package:editor_ffi/editor_ffi.dart';

import '../stores/editor/editor_store.dart';
import '../stores/lsp/lsp_store.dart';
import '../services/file_service.dart';
import '../services/file_picker_service.dart';

/// Dependency Injection Container
///
/// Configures and provides all dependencies using GetIt + Injectable + Provider pattern.
///
/// Architecture (Dependency Inversion Principle):
/// ```
/// Presentation Layer (MobX Stores)
///     ↓ depends on
/// Application Layer (Use Cases, Services)
///     ↓ depends on
/// Domain Layer (Interfaces/Ports)
///     ↑ implemented by
/// Infrastructure Layer (Adapters)
/// ```
///
/// Patterns Used:
/// - **GetIt**: Service locator for dependency injection
/// - **Injectable**: Code generation for dependency registration
/// - **Provider**: Widget tree dependency provision (for stores)
/// - **MobX**: Reactive state management in stores
///
/// Layers and their dependencies:
/// 1. **Infrastructure** (Adapters):
///    - WebSocketLspClientRepository implements ILspClientRepository
///    - NativeEditorRepository implements ICodeEditorRepository
///
/// 2. **Application** (Use Cases & Services):
///    - Use Cases depend on ILspClientRepository
///    - Services coordinate multiple use cases
///
/// 3. **Presentation** (MobX Stores):
///    - Stores depend on Use Cases
///    - UI widgets observe Stores via Provider + Observer
///
/// Example:
/// ```dart
/// // In main.dart
/// void main() async {
///   await configureDependencies();
///
///   runApp(
///     MultiProvider(
///       providers: createStoreProviders(),
///       child: MyApp(),
///     ),
///   );
/// }
///
/// // In widget (Option 1: Provider.of)
/// final editorStore = Provider.of<EditorStore>(context, listen: false);
///
/// // In widget (Option 2: GetIt)
/// final editorStore = getIt<EditorStore>();
///
/// // In widget (Option 3: context.read)
/// final editorStore = context.read<EditorStore>();
/// ```

final getIt = GetIt.instance;

/// Configures all dependencies
///
/// Must be called before using any dependencies.
/// Typically called in main() before runApp().
@InjectableInit()
Future<void> configureDependencies() async {
  // ================================================================
  // Infrastructure Layer (Adapters)
  // ================================================================

  // LSP Infrastructure
  // WebSocket URL configurable via environment variable for different deployments
  // Usage: flutter run --dart-define=LSP_BRIDGE_URL=ws://production-server:9999
  const defaultLspBridgeUrl = 'ws://localhost:9999';
  const lspBridgeUrl = String.fromEnvironment(
    'LSP_BRIDGE_URL',
    defaultValue: defaultLspBridgeUrl,
  );

  getIt.registerLazySingleton<ILspClientRepository>(
    () => WebSocketLspClientRepository(
      bridgeUrl: lspBridgeUrl,
      connectionTimeout: const Duration(seconds: 10),
      requestTimeout: const Duration(seconds: 30),
    ),
  );

  // Editor Infrastructure
  // Using NativeEditorRepository with Rust FFI
  // Note: Requires compiled Rust library (libeditor_native.so/.dylib/.dll)
  getIt.registerLazySingleton<ICodeEditorRepository>(
    () => NativeEditorRepository(),
  );

  // File Services
  getIt.registerLazySingleton<FileService>(
    () => FileService(),
  );

  getIt.registerLazySingleton<FilePickerService>(
    () => FilePickerService(),
  );

  // ================================================================
  // Application Layer (Use Cases & Services)
  // ================================================================

  // LSP Services
  getIt.registerLazySingleton<LspSessionService>(
    () => LspSessionService(
      lspRepository: getIt<ILspClientRepository>(),
    ),
  );

  // LSP Use Cases
  getIt.registerLazySingleton<InitializeLspSessionUseCase>(
    () => InitializeLspSessionUseCase(
      sessionService: getIt<LspSessionService>(),
    ),
  );

  getIt.registerLazySingleton<ShutdownLspSessionUseCase>(
    () => ShutdownLspSessionUseCase(
      sessionService: getIt<LspSessionService>(),
    ),
  );

  getIt.registerLazySingleton<GetCompletionsUseCase>(
    () => GetCompletionsUseCase(
      getIt<ILspClientRepository>(),
      getIt<ICodeEditorRepository>(),
    ),
  );

  getIt.registerLazySingleton<GetHoverInfoUseCase>(
    () => GetHoverInfoUseCase(
      lspRepository: getIt<ILspClientRepository>(),
    ),
  );

  getIt.registerLazySingleton<GetDiagnosticsUseCase>(
    () => GetDiagnosticsUseCase(
      lspRepository: getIt<ILspClientRepository>(),
    ),
  );

  getIt.registerLazySingleton<GoToDefinitionUseCase>(
    () => GoToDefinitionUseCase(
      lspRepository: getIt<ILspClientRepository>(),
    ),
  );

  getIt.registerLazySingleton<FindReferencesUseCase>(
    () => FindReferencesUseCase(
      lspRepository: getIt<ILspClientRepository>(),
    ),
  );

  // ================================================================
  // Presentation Layer (MobX Stores)
  // ================================================================

  // Editor Store (Singleton - one instance per app)
  getIt.registerLazySingleton<EditorStore>(
    () => EditorStore(
      editorRepository: getIt<ICodeEditorRepository>(),
    ),
  );

  // LSP Store (Singleton - one instance per app)
  getIt.registerLazySingleton<LspStore>(
    () => LspStore(
      initializeSessionUseCase: getIt<InitializeLspSessionUseCase>(),
      shutdownSessionUseCase: getIt<ShutdownLspSessionUseCase>(),
      getCompletionsUseCase: getIt<GetCompletionsUseCase>(),
      getHoverInfoUseCase: getIt<GetHoverInfoUseCase>(),
      getDiagnosticsUseCase: getIt<GetDiagnosticsUseCase>(),
      goToDefinitionUseCase: getIt<GoToDefinitionUseCase>(),
      findReferencesUseCase: getIt<FindReferencesUseCase>(),
    ),
  );
}

/// Creates Provider list for MobX Stores
///
/// Use this with MultiProvider to provide stores to widget tree.
///
/// Example:
/// ```dart
/// runApp(
///   MultiProvider(
///     providers: createStoreProviders(),
///     child: MyApp(),
///   ),
/// );
/// ```
///
/// Benefits of Provider + MobX:
/// - Provider: Widget tree-based dependency injection
/// - MobX: Reactive state management within stores
/// - Clean separation: Provider provides stores, Observer observes stores
/// - Testability: Easy to provide mock stores for testing
/// - Scoping: Can create scoped providers for different parts of app
///
/// Note: For simple apps, you can just use GetIt directly without Provider.
/// Provider is optional but recommended for better widget tree scoping.

/// Alternative: Creates ChangeNotifierProvider list (if stores extend ChangeNotifier)
///
/// Note: MobX stores don't need ChangeNotifier because they use their own
/// reactive system with Observer widgets. Use regular Provider instead.

/// Resets all dependencies (useful for testing)
Future<void> resetDependencies() async {
  await getIt.reset();
}
