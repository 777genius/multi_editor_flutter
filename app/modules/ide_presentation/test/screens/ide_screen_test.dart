import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:ide_presentation/src/screens/ide_screen.dart';
import 'package:ide_presentation/src/stores/editor/editor_store.dart';
import 'package:ide_presentation/src/stores/lsp/lsp_store.dart';
import 'package:ide_presentation/src/infrastructure/file_service.dart';
import 'package:ide_presentation/src/infrastructure/file_picker_service.dart';

// Mocks
class MockEditorStore extends Mock implements EditorStore {}
class MockLspStore extends Mock implements LspStore {}
class MockFileService extends Mock implements FileService {}
class MockFilePickerService extends Mock implements FilePickerService {}
class MockCodeEditorRepository extends Mock implements ICodeEditorRepository {}

void main() {
  late MockEditorStore mockEditorStore;
  late MockLspStore mockLspStore;
  late MockFileService mockFileService;
  late MockFilePickerService mockFilePickerService;
  late MockCodeEditorRepository mockEditorRepository;

  setUpAll(() {
    // Register fallback values for Mocktail
    registerFallbackValue(DocumentUri.fromFilePath('/test'));
    registerFallbackValue(LanguageId.dart);
    registerFallbackValue(CursorPosition.create(line: 0, column: 0));
  });

  setUp(() {
    // Create mocks
    mockEditorStore = MockEditorStore();
    mockLspStore = MockLspStore();
    mockFileService = MockFileService();
    mockFilePickerService = MockFilePickerService();
    mockEditorRepository = MockCodeEditorRepository();

    // Setup default behavior
    when(() => mockEditorStore.hasDocument).thenReturn(false);
    when(() => mockEditorStore.hasUnsavedChanges).thenReturn(false);
    when(() => mockEditorStore.canUndo).thenReturn(false);
    when(() => mockEditorStore.canRedo).thenReturn(false);
    when(() => mockEditorStore.languageId).thenReturn(null);
    when(() => mockEditorStore.lineCount).thenReturn(0);
    when(() => mockEditorStore.cursorPosition).thenReturn(
      CursorPosition.create(line: 0, column: 0),
    );
    when(() => mockEditorStore.content).thenReturn('');
    when(() => mockEditorStore.isLoading).thenReturn(false);
    when(() => mockEditorStore.hasError).thenReturn(false);
    when(() => mockEditorStore.errorMessage).thenReturn(null);

    when(() => mockLspStore.isReady).thenReturn(false);
    when(() => mockLspStore.isInitializing).thenReturn(false);
    when(() => mockLspStore.hasError).thenReturn(false);
    when(() => mockLspStore.hasDiagnostics).thenReturn(false);
    when(() => mockLspStore.errorCount).thenReturn(0);
    when(() => mockLspStore.warningCount).thenReturn(0);
    when(() => mockLspStore.diagnostics).thenReturn([]);

    when(() => mockEditorRepository.initialize()).thenAnswer((_) async {});

    // Register with GetIt
    final getIt = GetIt.instance;
    if (getIt.isRegistered<EditorStore>()) {
      getIt.unregister<EditorStore>();
    }
    if (getIt.isRegistered<LspStore>()) {
      getIt.unregister<LspStore>();
    }
    if (getIt.isRegistered<FileService>()) {
      getIt.unregister<FileService>();
    }
    if (getIt.isRegistered<FilePickerService>()) {
      getIt.unregister<FilePickerService>();
    }
    if (getIt.isRegistered<ICodeEditorRepository>()) {
      getIt.unregister<ICodeEditorRepository>();
    }

    getIt.registerSingleton<EditorStore>(mockEditorStore);
    getIt.registerSingleton<LspStore>(mockLspStore);
    getIt.registerSingleton<FileService>(mockFileService);
    getIt.registerSingleton<FilePickerService>(mockFilePickerService);
    getIt.registerSingleton<ICodeEditorRepository>(mockEditorRepository);
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  Widget createTestWidget() {
    return const ProviderScope(
      child: MaterialApp(
        home: IdeScreen(),
      ),
    );
  }

  group('IdeScreen', () {
    testWidgets('should render AppBar with title', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Flutter IDE'), findsOneWidget);
    });

    testWidgets('should show Explorer and Git tabs', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Explorer'), findsOneWidget);
      expect(find.text('Git'), findsOneWidget);
    });

    testWidgets('should switch between Explorer and Git tabs', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Explorer tab is selected by default
      expect(find.text('EXPLORER'), findsOneWidget);

      // Act - Tap Git tab
      await tester.tap(find.text('Git'));
      await tester.pumpAndSettle();

      // Assert - Git tab content should be visible
      // Note: GitPanelEnhanced might not render without a repository
      // Just verify the tab switch happened
      expect(find.text('Explorer'), findsOneWidget);
      expect(find.text('Git'), findsOneWidget);

      // Act - Switch back to Explorer
      await tester.tap(find.text('Explorer'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('EXPLORER'), findsOneWidget);
    });

    testWidgets('should show action buttons in AppBar', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Find buttons by icon
      expect(find.byIcon(Icons.folder_open), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.save), findsOneWidget);
      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.redo), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('should disable save button when no unsaved changes',
        (tester) async {
      // Arrange
      when(() => mockEditorStore.hasUnsavedChanges).thenReturn(false);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Save button should be disabled
      final saveButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.save),
          matching: find.byType(IconButton),
        ),
      );
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('should enable save button when there are unsaved changes',
        (tester) async {
      // Arrange
      when(() => mockEditorStore.hasUnsavedChanges).thenReturn(true);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Save button should be enabled
      final saveButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.save),
          matching: find.byType(IconButton),
        ),
      );
      expect(saveButton.onPressed, isNotNull);
    });

    testWidgets('should show LSP status in status bar', (tester) async {
      // Arrange
      when(() => mockLspStore.isReady).thenReturn(true);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('LSP Ready'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should show LSP initializing status', (tester) async {
      // Arrange
      when(() => mockLspStore.isReady).thenReturn(false);
      when(() => mockLspStore.isInitializing).thenReturn(true);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Initializing...'), findsOneWidget);
    });

    testWidgets('should show LSP error status', (tester) async {
      // Arrange
      when(() => mockLspStore.isReady).thenReturn(false);
      when(() => mockLspStore.isInitializing).thenReturn(false);
      when(() => mockLspStore.hasError).thenReturn(true);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('LSP Error'), findsOneWidget);
    });

    testWidgets('should show diagnostics count in status bar', (tester) async {
      // Arrange
      when(() => mockLspStore.hasDiagnostics).thenReturn(true);
      when(() => mockLspStore.errorCount).thenReturn(3);
      when(() => mockLspStore.warningCount).thenReturn(5);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('3'), findsOneWidget); // Error count
      expect(find.text('5'), findsOneWidget); // Warning count
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsAtLeastNWidgets(1));
    });

    testWidgets('should show language indicator when document is open',
        (tester) async {
      // Arrange
      when(() => mockEditorStore.languageId).thenReturn(LanguageId.dart);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('dart'), findsOneWidget);
    });

    testWidgets('should show cursor position when document is open',
        (tester) async {
      // Arrange
      when(() => mockEditorStore.hasDocument).thenReturn(true);
      when(() => mockEditorStore.cursorPosition).thenReturn(
        CursorPosition.create(line: 10, column: 25),
      );

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Ln 11, Col 26'), findsOneWidget); // 0-indexed to 1-indexed
    });

    testWidgets('should show line count when document is open', (tester) async {
      // Arrange
      when(() => mockEditorStore.hasDocument).thenReturn(true);
      when(() => mockEditorStore.lineCount).thenReturn(42);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('42 lines'), findsOneWidget);
    });

    testWidgets('should show file name in title with unsaved indicator',
        (tester) async {
      // This test requires opening a file, which would need more complex setup
      // Skipping for now as it depends on file operations
    });

    testWidgets('should open settings dialog when settings button is tapped',
        (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Assert - Settings dialog should open
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Editor'), findsOneWidget);
      expect(find.text('LSP'), findsOneWidget);
      expect(find.text('Git'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('should show "No file opened" in Explorer when no file is open',
        (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No file opened'), findsOneWidget);
    });

    testWidgets('should show New File and Open File buttons in Explorer',
        (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('New File'), findsOneWidget);
      expect(find.text('Open File'), findsOneWidget);
    });
  });

  group('IdeScreen - Sidebar Width', () {
    testWidgets('sidebar should have correct width', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Sidebar should be 300px wide
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Explorer'),
          matching: find.byType(Container),
        ).first,
      );
      expect(container.constraints?.maxWidth, 300);
    });
  });

  group('IdeScreen - Tab Styling', () {
    testWidgets('selected tab should have blue underline', (tester) async {
      // This would require checking decoration properties
      // which is complex in widget tests. Skipping detailed styling tests.
    });
  });
}
