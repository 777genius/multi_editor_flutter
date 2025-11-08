# Dependency Injection Setup

This document explains how to use dependency injection in the Multi-Editor IDE application.

## Architecture

The application uses **Injectable** + **GetIt** for dependency injection, following Clean Architecture principles.

### Module Structure

```
lsp_application (Use Cases & Services)
    ↓ depends on
lsp_domain (Abstractions) ← implements ← lsp_infrastructure (WebSocket Client)
    ↓
editor_core (Abstractions) ← implements ← editor_monaco / editor_ffi
```

## Setup

### 1. Install Dependencies

All required dependencies are already in `pubspec.yaml` files:

```yaml
dependencies:
  injectable: ^2.5.0
  get_it: ^8.0.2

dev_dependencies:
  injectable_generator: ^2.6.2
  build_runner: ^2.4.13
```

### 2. Generate DI Code

Run code generation to create `injection.config.dart` files:

```bash
# From app directory
cd app/modules/lsp_application
dart run build_runner build --delete-conflicting-outputs

cd ../lsp_infrastructure
dart run build_runner build --delete-conflicting-outputs

cd ../editor_monaco
dart run build_runner build --delete-conflicting-outputs

cd ../editor_ffi
dart run build_runner build --delete-conflicting-outputs
```

Or use melos to build all at once:

```bash
cd app
dart run melos run build_runner
```

### 3. Configure in Main App

In your `main.dart`:

```dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:lsp_application/lsp_application.dart';
import 'package:lsp_infrastructure/lsp_infrastructure.dart';
import 'package:editor_monaco/editor_monaco.dart';
import 'package:editor_ffi/editor_ffi.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  asExtension: true,
)
void configureDependencies() => getIt.init();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure dependency injection
  configureDependencies();

  // Connect to LSP Bridge (optional - auto-connects on first use)
  final lspRepository = getIt<ILspClientRepository>();
  await lspRepository.connect();

  runApp(const MyApp());
}
```

## Usage

### Injecting Dependencies

#### Option 1: GetIt (Recommended)

```dart
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get use case
    final getCompletions = getIt<GetCompletionsUseCase>();

    // Get service
    final sessionService = getIt<LspSessionService>();

    // Get repository (Monaco)
    final monacoEditor = getIt<ICodeEditorRepository>(
      instanceName: 'monaco',
    );

    // Get repository (Native Rust)
    final nativeEditor = getIt<ICodeEditorRepository>(
      instanceName: 'native',
    );

    return Container();
  }
}
```

#### Option 2: Injectable Annotations (For ViewModels/Stores)

```dart
import 'package:injectable/injectable.dart';

@injectable
class EditorViewModel {
  final GetCompletionsUseCase _getCompletions;
  final LspSessionService _sessionService;
  final ICodeEditorRepository _editorRepository;

  EditorViewModel(
    this._getCompletions,
    this._sessionService,
    @Named('monaco') this._editorRepository,
  );

  Future<void> requestCompletions() async {
    final result = await _getCompletions(
      languageId: LanguageId.dart,
      documentUri: DocumentUri.fromFilePath('/file.dart'),
      position: CursorPosition.create(line: 10, column: 5),
    );

    result.fold(
      (failure) => print('Error: $failure'),
      (completions) => print('Got ${completions.items.length} completions'),
    );
  }
}

// Then inject:
final viewModel = getIt<EditorViewModel>();
```

## Registered Components

### LSP Application Layer

| Component | Type | Description |
|-----------|------|-------------|
| `LspSessionService` | Singleton | Manages LSP session lifecycle |
| `DiagnosticService` | Singleton | Manages diagnostics (errors, warnings) |
| `EditorSyncService` | Singleton | Syncs editor with LSP server |
| `GetCompletionsUseCase` | Factory | Get code completions |
| `GetHoverInfoUseCase` | Factory | Get hover documentation |
| `GetDiagnosticsUseCase` | Factory | Get diagnostics |
| `GoToDefinitionUseCase` | Factory | Navigate to definition |
| `FindReferencesUseCase` | Factory | Find all references |
| `InitializeLspSessionUseCase` | Factory | Initialize LSP session |
| `ShutdownLspSessionUseCase` | Factory | Shutdown LSP session |

### LSP Infrastructure Layer

| Component | Type | Description |
|-----------|------|-------------|
| `ILspClientRepository` | Singleton | WebSocket LSP client |
| `lspBridgeUrl` | Singleton | LSP Bridge URL (ws://localhost:9999) |

### Editor Implementations

| Component | Type | Named | Description |
|-----------|------|-------|-------------|
| `ICodeEditorRepository` | Lazy Singleton | `monaco` | Monaco editor (WebView) |
| `ICodeEditorRepository` | Lazy Singleton | `native` | Rust native editor (FFI) |

## Choosing Editor Implementation

### Monaco Editor (Default)

```dart
final editor = getIt<ICodeEditorRepository>(
  instanceName: 'monaco',
);
```

**Pros:**
- ✅ Full VS Code features
- ✅ 100+ languages
- ✅ Proven in production

**Cons:**
- ⚠️ WebView overhead (~200-400MB memory)
- ⚠️ Slower for large files

### Rust Native Editor (High Performance)

```dart
final editor = getIt<ICodeEditorRepository>(
  instanceName: 'native',
);
```

**Pros:**
- ✅ **4-10x faster** text operations
- ✅ **50-70% less memory** usage
- ✅ Native performance
- ✅ Offline syntax highlighting (tree-sitter)

**Cons:**
- ⚠️ Limited features compared to Monaco
- ⚠️ Experimental (in development)

## Testing

### Mock Dependencies

```dart
import 'package:mocktail/mocktail.dart';

class MockLspRepository extends Mock implements ILspClientRepository {}
class MockEditorRepository extends Mock implements ICodeEditorRepository {}

void main() {
  late MockLspRepository mockLspRepo;
  late MockEditorRepository mockEditorRepo;
  late GetCompletionsUseCase useCase;

  setUp(() {
    mockLspRepo = MockLspRepository();
    mockEditorRepo = MockEditorRepository();

    // Create use case with mocks (no DI needed in tests)
    useCase = GetCompletionsUseCase(mockLspRepo, mockEditorRepo);
  });

  test('should return completions', () async {
    // Arrange
    when(() => mockLspRepo.getSession(any())).thenAnswer(
      (_) async => right(mockSession),
    );

    // Act
    final result = await useCase(...);

    // Assert
    expect(result.isRight(), true);
  });
}
```

## Troubleshooting

### "No registered instance found"

```
Error: GetIt: Object/factory with type X is not registered inside GetIt.
```

**Solution:** Run code generation:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### "Circular dependency detected"

```
Error: Circular dependency detected
```

**Solution:** Check your constructors. Services should not depend on each other circularly:

```dart
// ❌ Bad: Circular dependency
class ServiceA {
  ServiceA(ServiceB b);
}
class ServiceB {
  ServiceB(ServiceA a);
}

// ✅ Good: One-way dependency
class ServiceA {
  ServiceA(Repository repo);
}
class ServiceB {
  ServiceB(Repository repo);
}
```

### Multiple implementations of same interface

Use `@Named` annotation:

```dart
@lazySingleton
@Named('monaco')
ICodeEditorRepository provideMonacoEditor() {
  return MonacoEditorRepository();
}

@lazySingleton
@Named('native')
ICodeEditorRepository provideNativeEditor() {
  return NativeEditorRepository();
}

// Inject:
final monaco = getIt<ICodeEditorRepository>(instanceName: 'monaco');
final native = getIt<ICodeEditorRepository>(instanceName: 'native');
```

## Best Practices

1. **Use Singletons for Stateful Services**
   - `LspSessionService` - Maintains session state
   - `DiagnosticService` - Caches diagnostics
   - Repositories - Manage connections

2. **Use Factory for Stateless Use Cases**
   - Use cases should be stateless
   - Create new instance each time

3. **Inject Interfaces, Not Implementations**
   ```dart
   // ✅ Good
   class MyService {
     MyService(ILspClientRepository lspRepo);
   }

   // ❌ Bad
   class MyService {
     MyService(WebSocketLspClientRepository lspRepo);
   }
   ```

4. **Don't Use GetIt in Domain Layer**
   - Domain layer should not know about DI
   - Pass dependencies via constructors

5. **Test Without DI**
   - Create instances manually in tests
   - Use mocks/fakes for dependencies

## Further Reading

- [Injectable Documentation](https://pub.dev/packages/injectable)
- [GetIt Documentation](https://pub.dev/packages/get_it)
- [Clean Architecture with Flutter](https://resocoder.com/2019/08/27/flutter-tdd-clean-architecture-course-1-explanation-project-structure/)
