# MobX Quick Start Guide

Руководство по работе с MobX в IDE Presentation Layer.

## 📚 Содержание

1. [Архитектура](#архитектура)
2. [MobX Stores](#mobx-stores)
3. [Widgets с Observer](#widgets-с-observer)
4. [Dependency Injection](#dependency-injection)
5. [Лучшие практики](#лучшие-практики)
6. [Code Generation](#code-generation)
7. [Testing](#testing)

---

## 🏛️ Архитектура

### Clean Architecture + MobX + Provider

```
┌─────────────────────────────────────┐
│  UI Widgets (Flutter)                │
│  - Observer pattern                  │
│  - Reactive rebuilds                 │
└──────────────┬──────────────────────┘
               │ observes @observable
┌──────────────▼──────────────────────┐
│  MobX Stores (Presentation)          │
│  - @observable state                 │
│  - @action mutations                 │
│  - @computed derived state           │
└──────────────┬──────────────────────┘
               │ calls
┌──────────────▼──────────────────────┐
│  Use Cases (Application)             │
│  - Business logic                    │
│  - Orchestration                     │
└──────────────┬──────────────────────┘
               │ uses
┌──────────────▼──────────────────────┐
│  Repositories (Domain Interfaces)    │
└─────────────────────────────────────┘
```

### Ключевые принципы

- ✅ **Clean Architecture**: Store зависит от Use Cases, не от Infrastructure
- ✅ **Reactive**: Автоматические обновления при изменении @observable
- ✅ **Testable**: Store - чистый Dart класс, легко тестировать
- ✅ **Type-safe**: Полная type safety с compile-time проверками

---

## 📦 MobX Stores

### EditorStore

Управляет состоянием редактора.

#### Observables (Reactive State)

```dart
@observable
String content = '';  // Текущий контент редактора

@observable
CursorPosition cursorPosition = CursorPosition.create(line: 0, column: 0);

@observable
bool hasUnsavedChanges = false;

@observable
bool canUndo = false;

@observable
bool canRedo = false;
```

#### Actions (State Mutations)

```dart
@action
Future<void> insertText(String text) async {
  // 1. Call repository
  final result = await _editorRepository.insertText(text);

  // 2. Handle result
  result.fold(
    (failure) => _handleError('Failed to insert text', failure),
    (_) async {
      await _refreshEditorState();
      hasUnsavedChanges = true;
      canUndo = true;
    },
  );
}

@action
Future<void> undo() async {
  if (!canUndo) return;

  final result = await _editorRepository.undo();

  result.fold(
    (failure) => _handleError('Failed to undo', failure),
    (_) async {
      await _refreshEditorState();
      canRedo = true;
    },
  );
}
```

#### Computed Properties (Derived State)

```dart
@computed
bool get hasDocument => documentUri != null;

@computed
bool get hasError => errorMessage != null;

@computed
bool get isReady => hasDocument && !isLoading && !hasError;

@computed
int get lineCount => content.split('\n').length;

@computed
String get currentLine {
  if (content.isEmpty) return '';
  final lines = content.split('\n');
  if (cursorPosition.line >= lines.length) return '';
  return lines[cursorPosition.line];
}
```

### LspStore

Управляет LSP взаимодействиями.

#### Observables

```dart
@observable
LspSession? session;

@observable
CompletionList? completions;

@observable
ObservableList<Diagnostic>? diagnostics;

@observable
bool isInitializing = false;

@observable
String? errorMessage;
```

#### Actions

```dart
@action
Future<void> initializeSession({
  required LanguageId language,
  required DocumentUri rootUri,
}) async {
  isInitializing = true;
  errorMessage = null;

  final result = await _initializeSessionUseCase(
    languageId: language,
    rootUri: rootUri,
  );

  result.fold(
    (failure) {
      _handleError('Failed to initialize LSP', failure);
      isInitializing = false;
    },
    (newSession) {
      session = newSession;
      isInitializing = false;
    },
  );
}

@action
Future<void> getCompletions({
  required LanguageId language,
  required DocumentUri documentUri,
  required CursorPosition position,
}) async {
  final result = await _getCompletionsUseCase(
    languageId: language,
    documentUri: documentUri,
    position: position,
  );

  result.fold(
    (failure) {
      // Silently fail - don't disrupt editing
      completions = null;
    },
    (newCompletions) {
      completions = newCompletions;
    },
  );
}
```

#### Computed Properties

```dart
@computed
bool get isReady => session != null && !isInitializing && !hasError;

@computed
bool get hasCompletions =>
    completions != null && completions!.items.isNotEmpty;

@computed
int get errorCount {
  if (diagnostics == null) return 0;
  return diagnostics!
      .where((d) => d.severity == DiagnosticSeverity.error)
      .length;
}

@computed
int get warningCount {
  if (diagnostics == null) return 0;
  return diagnostics!
      .where((d) => d.severity == DiagnosticSeverity.warning)
      .length;
}

@computed
List<Diagnostic> get errors {
  if (diagnostics == null) return [];
  return diagnostics!
      .where((d) => d.severity == DiagnosticSeverity.error)
      .toList();
}
```

---

## 🎨 Widgets с Observer

### EditorView

```dart
class EditorView extends StatefulWidget {
  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  late final EditorStore _store;

  @override
  void initState() {
    super.initState();
    _store = GetIt.I<EditorStore>();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        // Automatically rebuilds when observables change
        if (!_store.hasDocument) {
          return _buildEmptyState();
        }

        if (_store.isLoading) {
          return _buildLoadingState();
        }

        if (_store.hasError) {
          return _buildErrorState();
        }

        return _buildEditor();
      },
    );
  }

  Widget _buildEditor() {
    return Observer(
      builder: (_) {
        // Granular observer for line numbers
        final lineCount = _store.lineCount;
        final currentLine = _store.cursorPosition.line;

        return // ... build UI with lineCount and currentLine
      },
    );
  }
}
```

### IdeScreen с Multiple Observers

```dart
class IdeScreen extends StatefulWidget {
  @override
  State<IdeScreen> createState() => _IdeScreenState();
}

class _IdeScreenState extends State<IdeScreen> {
  late final EditorStore _editorStore;
  late final LspStore _lspStore;

  @override
  void initState() {
    super.initState();
    _editorStore = GetIt.I<EditorStore>();
    _lspStore = GetIt.I<LspStore>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildStatusBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Observer(
        builder: (_) {
          final hasUnsaved = _editorStore.hasUnsavedChanges;
          final fileName = _editorStore.documentUri?.path.split('/').last
              ?? 'Untitled';

          return Text(hasUnsaved ? '$fileName *' : fileName);
        },
      ),
      actions: [
        // Save button - reactive enable/disable
        Observer(
          builder: (_) {
            final canSave = _editorStore.hasUnsavedChanges;

            return IconButton(
              icon: Icon(Icons.save),
              onPressed: canSave ? _handleSave : null,
            );
          },
        ),

        // Undo button
        Observer(
          builder: (_) {
            final canUndo = _editorStore.canUndo;

            return IconButton(
              icon: Icon(Icons.undo),
              onPressed: canUndo ? () => _editorStore.undo() : null,
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusBar() {
    return Observer(
      builder: (_) {
        return Container(
          child: Row(
            children: [
              // Cursor position
              if (_editorStore.hasDocument)
                Text(
                  'Ln ${_editorStore.cursorPosition.line + 1}, '
                  'Col ${_editorStore.cursorPosition.column + 1}',
                ),

              // Diagnostics count
              if (_lspStore.errorCount > 0)
                Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    Text('${_lspStore.errorCount}'),
                  ],
                ),

              // LSP status
              Text(_lspStore.statusText),
            ],
          ),
        );
      },
    );
  }

  void _handleSave() {
    _editorStore.saveDocument();
  }
}
```

---

## 💉 Dependency Injection

### Setup в main.dart

```dart
import 'package:ide_presentation/ide_presentation.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure GetIt dependencies
  await configureDependencies();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: IdeScreen(),
    );
  }
}
```

### Доступ к Stores

#### Вариант 1: GetIt (рекомендуется)

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late final EditorStore _store;

  @override
  void initState() {
    super.initState();
    _store = GetIt.I<EditorStore>();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => Text(_store.content),
    );
  }
}
```

#### Вариант 2: Provider (опционально)

```dart
// In main.dart
runApp(
  MultiProvider(
    providers: [
      Provider<EditorStore>(
        create: (_) => getIt<EditorStore>(),
        dispose: (_, store) => store.dispose(),
      ),
      Provider<LspStore>(
        create: (_) => getIt<LspStore>(),
        dispose: (_, store) => store.dispose(),
      ),
    ],
    child: MyApp(),
  ),
);

// In widget
final editorStore = Provider.of<EditorStore>(context, listen: false);
// or
final editorStore = context.read<EditorStore>();
```

---

## 🎯 Лучшие практики

### 1. Granular Observers

❌ **BAD**: One big Observer

```dart
Observer(
  builder: (_) {
    return Column(
      children: [
        Text(_store.content),  // Rebuilds on ANY observable change
        Text(_store.cursorPosition.toString()),
        Text(_store.lineCount.toString()),
      ],
    );
  },
);
```

✅ **GOOD**: Multiple small Observers

```dart
Column(
  children: [
    Observer(
      builder: (_) => Text(_store.content),  // Only rebuilds on content change
    ),
    Observer(
      builder: (_) => Text(_store.cursorPosition.toString()),  // Only on cursor change
    ),
    Observer(
      builder: (_) => Text(_store.lineCount.toString()),  // Only on lineCount change
    ),
  ],
);
```

### 2. Computed Properties

❌ **BAD**: Calculate in widget

```dart
Observer(
  builder: (_) {
    final errorCount = _lspStore.diagnostics
        ?.where((d) => d.severity == DiagnosticSeverity.error)
        .length ?? 0;

    return Text('Errors: $errorCount');  // Recalculates on every rebuild
  },
);
```

✅ **GOOD**: Use @computed

```dart
// In Store
@computed
int get errorCount {
  if (diagnostics == null) return 0;
  return diagnostics!
      .where((d) => d.severity == DiagnosticSeverity.error)
      .length;
}

// In Widget
Observer(
  builder: (_) => Text('Errors: ${_lspStore.errorCount}'),  // Memoized
);
```

### 3. Actions for Mutations

❌ **BAD**: Direct mutation

```dart
void updateContent(String newContent) {
  _store.content = newContent;  // No tracking, no reactions
  _store.hasUnsavedChanges = true;
}
```

✅ **GOOD**: Use @action

```dart
@action
void updateContent(String newContent) {
  content = newContent;  // Tracked, triggers reactions
  hasUnsavedChanges = true;
}
```

### 4. ObservableList for Collections

❌ **BAD**: Regular List

```dart
@observable
List<Diagnostic> diagnostics = [];  // Changes not tracked

void addDiagnostic(Diagnostic d) {
  diagnostics.add(d);  // Not reactive!
}
```

✅ **GOOD**: ObservableList

```dart
@observable
ObservableList<Diagnostic> diagnostics = ObservableList();

@action
void addDiagnostic(Diagnostic d) {
  diagnostics.add(d);  // Reactive!
}
```

### 5. dispose() Pattern

```dart
class EditorStore {
  late final ReactionDisposer _disposer;

  EditorStore() {
    // Setup reactions
    _disposer = reaction(
      (_) => content,
      (content) {
        // React to content changes
      },
    );
  }

  void dispose() {
    _disposer();  // Clean up reactions
  }
}
```

---

## ⚙️ Code Generation

### Generate MobX Code

```bash
# Generate *.g.dart files
cd app/modules/ide_presentation
dart run build_runner build

# Watch mode (auto-regenerate on save)
dart run build_runner watch

# Clean and rebuild
dart run build_runner build --delete-conflicting-outputs
```

### Generated Files

- `editor_store.g.dart` - Generated MobX code for EditorStore
- `lsp_store.g.dart` - Generated MobX code for LspStore

**Важно**: Не редактируйте *.g.dart файлы вручную!

---

## 🧪 Testing

### Unit Testing Stores

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEditorRepository extends Mock implements ICodeEditorRepository {}

void main() {
  group('EditorStore', () {
    late EditorStore store;
    late MockEditorRepository mockRepository;

    setUp(() {
      mockRepository = MockEditorRepository();
      store = EditorStore(editorRepository: mockRepository);
    });

    tearDown(() {
      store.dispose();
    });

    test('insertText updates content and sets hasUnsavedChanges', () async {
      // Arrange
      when(() => mockRepository.insertText(any()))
          .thenAnswer((_) async => right(unit));
      when(() => mockRepository.getContent())
          .thenAnswer((_) async => right('Hello'));

      // Act
      await store.insertText('Hello');

      // Assert
      expect(store.content, 'Hello');
      expect(store.hasUnsavedChanges, true);
      expect(store.canUndo, true);
    });

    test('computed lineCount returns correct value', () {
      // Arrange
      store.loadContent('Line 1\nLine 2\nLine 3');

      // Assert
      expect(store.lineCount, 3);
    });

    test('hasDocument returns true when documentUri is set', () {
      // Arrange
      expect(store.hasDocument, false);

      // Act
      store.openDocument(
        uri: DocumentUri.fromFilePath('/test.dart'),
        language: LanguageId.dart,
      );

      // Assert
      expect(store.hasDocument, true);
    });
  });
}
```

### Widget Testing with Stores

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  group('EditorView', () {
    late EditorStore mockStore;

    setUp(() {
      mockStore = EditorStore(editorRepository: MockEditorRepository());

      // Register in GetIt
      GetIt.I.registerSingleton<EditorStore>(mockStore);
    });

    tearDown(() {
      GetIt.I.reset();
    });

    testWidgets('displays content from store', (tester) async {
      // Arrange
      mockStore.loadContent('Test content');

      // Act
      await tester.pumpWidget(
        MaterialApp(home: EditorView()),
      );

      // Assert
      expect(find.text('Test content'), findsOneWidget);
    });

    testWidgets('shows empty state when no document', (tester) async {
      // Arrange
      // mockStore has no document by default

      // Act
      await tester.pumpWidget(
        MaterialApp(home: EditorView()),
      );

      // Assert
      expect(find.text('No document opened'), findsOneWidget);
    });
  });
}
```

---

## 📚 Дополнительные ресурсы

- [MobX Official Docs](https://mobx.netlify.app/)
- [flutter_mobx Package](https://pub.dev/packages/flutter_mobx)
- [MobX Codegen](https://pub.dev/packages/mobx_codegen)
- [Provider Package](https://pub.dev/packages/provider)
- [GetIt Package](https://pub.dev/packages/get_it)

---

## 🚀 Next Steps

1. **Generate Code**: Run `dart run build_runner build`
2. **Test Reactivity**: Modify store values, observe UI updates
3. **Add MobX DevTools**: Install for debugging
4. **Write Tests**: Test stores and widgets
5. **Performance**: Profile with Flutter DevTools

**Happy Coding with MobX!** 🎉
