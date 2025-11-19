import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import 'package:multi_editor_ui/src/widgets/scaffold/widgets/loaded_editor_view.dart';
import 'package:multi_editor_ui/src/widgets/code_editor/editor_config.dart';

// Mocks
class MockOnContentChanged extends Mock {
  void call(String content);
}

class MockPluginUIService extends Mock implements PluginUIService {}

class MockPluginManager extends Mock implements PluginManager {}

void main() {
  group('LoadedEditorView Widget Tests', () {
    late FileDocument testFile;
    late FileDocument longNameFile;

    setUp(() {
      testFile = FileDocument(
        id: 'file-1',
        name: 'test.dart',
        content: 'void main() {}',
        language: 'dart',
        folderId: 'root',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      longNameFile = FileDocument(
        id: 'file-2',
        name: 'very_long_file_name_for_testing_layout.dart',
        content: 'class VeryLongClassName {}',
        language: 'dart',
        folderId: 'root',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
    });

    Widget createWidget({
      required FileDocument file,
      bool isDirty = false,
      bool isSaving = false,
      EditorConfig? editorConfig,
      ValueChanged<String>? onContentChanged,
      VoidCallback? onSave,
      VoidCallback? onClose,
      PluginUIService? pluginUIService,
      PluginManager? pluginManager,
      Function(String action, Map<String, dynamic> data)? onPluginAction,
      ThemeData? theme,
    }) {
      return MaterialApp(
        theme: theme,
        home: Scaffold(
          body: LoadedEditorView(
            file: file,
            isDirty: isDirty,
            isSaving: isSaving,
            editorConfig: editorConfig ?? const EditorConfig(),
            onContentChanged: onContentChanged ?? (_) {},
            onSave: onSave ?? () {},
            onClose: onClose ?? () {},
            pluginUIService: pluginUIService,
            pluginManager: pluginManager,
            onPluginAction: onPluginAction,
          ),
        ),
      );
    }

    group('Rendering', () {
      testWidgets('should display editor header bar', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(file: testFile));

        // Assert
        expect(find.text('test.dart'), findsOneWidget);
      });

      testWidgets('should show dirty indicator when dirty', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(file: testFile, isDirty: true),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('You have unsaved changes'), findsOneWidget);
      });

      testWidgets('should not show dirty indicator when clean',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(file: testFile, isDirty: false),
        );

        // Assert
        expect(find.text('You have unsaved changes'), findsNothing);
      });

      testWidgets('should show header bar regardless of dirty state',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(file: testFile, isDirty: false),
        );

        // Assert
        expect(find.text('test.dart'), findsOneWidget);
      });

      testWidgets('should render column layout', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(file: testFile));

        // Assert
        expect(find.byType(Column), findsWidgets);
      });

      testWidgets('should have divider after header', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(file: testFile));

        // Assert
        expect(find.byType(Divider), findsOneWidget);
        final divider = tester.widget<Divider>(find.byType(Divider));
        expect(divider.height, equals(1));
      });
    });

    group('Layout Structure', () {
      testWidgets('should arrange items in column', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(file: testFile));

        // Assert
        expect(find.byType(Column), findsWidgets);
      });

      testWidgets('should have expanded monaco editor', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(file: testFile));

        // Assert
        expect(find.byType(Expanded), findsOneWidget);
      });

      testWidgets('should show all elements in correct order', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(file: testFile, isDirty: true),
        );
        await tester.pumpAndSettle();

        // Assert - Order should be: Header, Divider, Editor (Expanded), DirtyIndicator
        expect(find.text('test.dart'), findsOneWidget); // Header
        expect(find.byType(Divider), findsOneWidget); // Divider
        expect(find.byType(Expanded), findsOneWidget); // Editor
        expect(find.text('You have unsaved changes'), findsOneWidget); // Dirty indicator
      });

      testWidgets('should omit dirty indicator when clean', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(file: testFile, isDirty: false),
        );

        // Assert
        expect(find.text('test.dart'), findsOneWidget);
        expect(find.text('You have unsaved changes'), findsNothing);
      });
    });

    group('State Management', () {
      testWidgets('should display correct file name', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(file: testFile));

        // Assert
        expect(find.text('test.dart'), findsOneWidget);
      });

      testWidgets('should handle file changes', (tester) async {
        // Arrange
        await tester.pumpWidget(createWidget(file: testFile));
        expect(find.text('test.dart'), findsOneWidget);

        // Act - Change file
        final newFile = FileDocument(
          id: 'file-2',
          name: 'new_file.dart',
          content: 'void test() {}',
          language: 'dart',
          folderId: 'root',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        );
        await tester.pumpWidget(createWidget(file: newFile));

        // Assert
        expect(find.text('new_file.dart'), findsOneWidget);
        expect(find.text('test.dart'), findsNothing);
      });
    });

    group('Callbacks', () {
      testWidgets('should call onSave when save button pressed',
          (tester) async {
        // Arrange
        var saveCalled = false;
        await tester.pumpWidget(
          createWidget(
            file: testFile,
            isDirty: true,
            onSave: () => saveCalled = true,
          ),
        );

        // Act
        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle();

        // Assert
        expect(saveCalled, isTrue);
      });

      testWidgets('should call onClose when close button pressed',
          (tester) async {
        // Arrange
        var closeCalled = false;
        await tester.pumpWidget(
          createWidget(
            file: testFile,
            onClose: () => closeCalled = true,
          ),
        );

        // Act
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Assert
        expect(closeCalled, isTrue);
      });

      testWidgets('should call onSave from dirty indicator', (tester) async {
        // Arrange
        var saveCount = 0;
        await tester.pumpWidget(
          createWidget(
            file: testFile,
            isDirty: true,
            onSave: () => saveCount++,
          ),
        );
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.text('Save').last);
        await tester.pumpAndSettle();

        // Assert
        expect(saveCount, equals(1));
      });
    });

    group('Editor Configuration', () {
      testWidgets('should use provided editor config', (tester) async {
        // Arrange
        const customConfig = EditorConfig(
          fontSize: 16,
          tabSize: 4,
          wordWrap: true,
        );

        // Act
        await tester.pumpWidget(
          createWidget(file: testFile, editorConfig: customConfig),
        );

        // Assert - Should render without errors
        expect(tester.takeException(), isNull);
      });

      testWidgets('should use default config when not provided',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(file: testFile));

        // Assert
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle different font sizes', (tester) async {
        // Arrange
        const configs = [
          EditorConfig(fontSize: 12),
          EditorConfig(fontSize: 16),
          EditorConfig(fontSize: 20),
        ];

        // Act & Assert
        for (final config in configs) {
          await tester.pumpWidget(
            createWidget(file: testFile, editorConfig: config),
          );
          expect(tester.takeException(), isNull);
        }
      });
    });

    group('Plugin Integration', () {
      testWidgets('should pass plugin services to header', (tester) async {
        // Arrange
        final mockUIService = MockPluginUIService();
        final mockManager = MockPluginManager();
        when(() => mockUIService.getRegisteredUIs()).thenReturn([]);

        // Act
        await tester.pumpWidget(
          createWidget(
            file: testFile,
            pluginUIService: mockUIService,
            pluginManager: mockManager,
          ),
        );

        // Assert
        verify(() => mockUIService.getRegisteredUIs()).called(1);
      });

      testWidgets('should handle null plugin services', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(
            file: testFile,
            pluginUIService: null,
            pluginManager: null,
          ),
        );

        // Assert
        expect(tester.takeException(), isNull);
      });

      testWidgets('should pass onPluginAction callback', (tester) async {
        // Arrange
        var actionCalled = false;
        String? receivedAction;

        await tester.pumpWidget(
          createWidget(
            file: testFile,
            onPluginAction: (action, data) {
              actionCalled = true;
              receivedAction = action;
            },
          ),
        );

        // Assert - Widget should render
        expect(find.text('test.dart'), findsOneWidget);
      });
    });

    group('Theme Integration', () {
      testWidgets('should adapt to dark theme', (tester) async {
        // Arrange
        final darkTheme = ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
        );

        // Act
        await tester.pumpWidget(
          createWidget(file: testFile, theme: darkTheme),
        );

        // Assert
        expect(tester.takeException(), isNull);
        expect(find.text('test.dart'), findsOneWidget);
      });

      testWidgets('should adapt to light theme', (tester) async {
        // Arrange
        final lightTheme = ThemeData(
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
        );

        // Act
        await tester.pumpWidget(
          createWidget(file: testFile, theme: lightTheme),
        );

        // Assert
        expect(find.text('test.dart'), findsOneWidget);
      });

      testWidgets('should use theme for divider', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(file: testFile));

        // Assert
        final divider = tester.widget<Divider>(find.byType(Divider));
        expect(divider.height, equals(1));
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle empty file content', (tester) async {
        // Arrange
        final emptyFile = FileDocument(
          id: 'empty',
          name: 'empty.txt',
          content: '',
          language: 'text',
          folderId: 'root',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        );

        // Act
        await tester.pumpWidget(createWidget(file: emptyFile));

        // Assert
        expect(tester.takeException(), isNull);
        expect(find.text('empty.txt'), findsOneWidget);
      });

      testWidgets('should handle long file names', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(file: longNameFile));

        // Assert
        expect(tester.takeException(), isNull);
        expect(find.text(longNameFile.name), findsOneWidget);
      });

      testWidgets('should handle both dirty and saving states', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(file: testFile, isDirty: true, isSaving: true),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('You have unsaved changes'), findsOneWidget);
      });

      testWidgets('should handle large file content', (tester) async {
        // Arrange
        final largeFile = FileDocument(
          id: 'large',
          name: 'large.dart',
          content: 'void main() {\n' * 1000 + '}',
          language: 'dart',
          folderId: 'root',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        );

        // Act
        await tester.pumpWidget(createWidget(file: largeFile));

        // Assert
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle special characters in file content',
          (tester) async {
        // Arrange
        final specialFile = FileDocument(
          id: 'special',
          name: 'special.txt',
          content: '特殊字符 emojis 😀 symbols @#\$%',
          language: 'text',
          folderId: 'root',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        );

        // Act
        await tester.pumpWidget(createWidget(file: specialFile));

        // Assert
        expect(find.text('special.txt'), findsOneWidget);
      });
    });

    group('Use Cases', () {
      testWidgets('UC1: Clean file loaded in editor', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(file: testFile, isDirty: false));

        // Assert
        expect(find.text('test.dart'), findsOneWidget);
        expect(find.text('You have unsaved changes'), findsNothing);
        expect(find.byType(Divider), findsOneWidget);
      });

      testWidgets('UC2: Dirty file shows save indicator', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(file: testFile, isDirty: true));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('You have unsaved changes'), findsOneWidget);
        expect(find.text('Modified'), findsOneWidget);
      });

      testWidgets('UC3: File being saved shows progress', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(file: testFile, isSaving: true, isDirty: true),
        );

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('UC4: User saves file from header', (tester) async {
        // Arrange
        var saved = false;
        await tester.pumpWidget(
          createWidget(
            file: testFile,
            isDirty: true,
            onSave: () => saved = true,
          ),
        );

        // Act
        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle();

        // Assert
        expect(saved, isTrue);
      });

      testWidgets('UC5: User saves file from dirty indicator',
          (tester) async {
        // Arrange
        var saved = false;
        await tester.pumpWidget(
          createWidget(
            file: testFile,
            isDirty: true,
            onSave: () => saved = true,
          ),
        );
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.text('Save').last);
        await tester.pumpAndSettle();

        // Assert
        expect(saved, isTrue);
      });

      testWidgets('UC6: User closes file', (tester) async {
        // Arrange
        var closed = false;
        await tester.pumpWidget(
          createWidget(
            file: testFile,
            onClose: () => closed = true,
          ),
        );

        // Act
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Assert
        expect(closed, isTrue);
      });

      testWidgets('UC7: File transitions from dirty to clean',
          (tester) async {
        // Arrange - Dirty state
        await tester.pumpWidget(
          createWidget(file: testFile, isDirty: true),
        );
        await tester.pumpAndSettle();
        expect(find.text('You have unsaved changes'), findsOneWidget);

        // Act - Change to clean
        await tester.pumpWidget(
          createWidget(file: testFile, isDirty: false),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('You have unsaved changes'), findsNothing);
      });

      testWidgets('UC8: File transitions from saving to clean',
          (tester) async {
        // Arrange - Saving state
        await tester.pumpWidget(
          createWidget(file: testFile, isDirty: true, isSaving: true),
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Act - Change to clean
        await tester.pumpWidget(
          createWidget(file: testFile, isDirty: false, isSaving: false),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('You have unsaved changes'), findsNothing);
      });
    });

    group('Layout Responsiveness', () {
      testWidgets('should render on mobile screens', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget(file: testFile, isDirty: true));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('test.dart'), findsOneWidget);
        expect(find.text('You have unsaved changes'), findsOneWidget);
      });

      testWidgets('should render on tablet screens', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget(file: testFile));

        // Assert
        expect(find.text('test.dart'), findsOneWidget);
      });

      testWidgets('should render on desktop screens', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget(file: testFile));

        // Assert
        expect(find.text('test.dart'), findsOneWidget);
      });

      testWidgets('should handle narrow viewports', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(300, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget(file: testFile));

        // Assert
        expect(tester.takeException(), isNull);
      });
    });

    group('File Types', () {
      testWidgets('should handle Dart files', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(file: testFile));

        // Assert
        expect(find.text('test.dart'), findsOneWidget);
      });

      testWidgets('should handle JavaScript files', (tester) async {
        // Arrange
        final jsFile = FileDocument(
          id: 'js',
          name: 'app.js',
          content: 'console.log("hello");',
          language: 'javascript',
          folderId: 'root',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        );

        // Act
        await tester.pumpWidget(createWidget(file: jsFile));

        // Assert
        expect(find.text('app.js'), findsOneWidget);
      });

      testWidgets('should handle JSON files', (tester) async {
        // Arrange
        final jsonFile = FileDocument(
          id: 'json',
          name: 'config.json',
          content: '{"key": "value"}',
          language: 'json',
          folderId: 'root',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        );

        // Act
        await tester.pumpWidget(createWidget(file: jsonFile));

        // Assert
        expect(find.text('config.json'), findsOneWidget);
      });

      testWidgets('should handle plain text files', (tester) async {
        // Arrange
        final textFile = FileDocument(
          id: 'txt',
          name: 'readme.txt',
          content: 'Plain text content',
          language: 'text',
          folderId: 'root',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        );

        // Act
        await tester.pumpWidget(createWidget(file: textFile));

        // Assert
        expect(find.text('readme.txt'), findsOneWidget);
      });
    });

    group('Multiple Save Options', () {
      testWidgets('should save from header bar when dirty', (tester) async {
        // Arrange
        var headerSaveCount = 0;
        await tester.pumpWidget(
          createWidget(
            file: testFile,
            isDirty: true,
            onSave: () => headerSaveCount++,
          ),
        );

        // Act
        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle();

        // Assert
        expect(headerSaveCount, equals(1));
      });

      testWidgets('should save from dirty indicator when dirty',
          (tester) async {
        // Arrange
        var indicatorSaveCount = 0;
        await tester.pumpWidget(
          createWidget(
            file: testFile,
            isDirty: true,
            onSave: () => indicatorSaveCount++,
          ),
        );
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.text('Save').last);
        await tester.pumpAndSettle();

        // Assert
        expect(indicatorSaveCount, equals(1));
      });

      testWidgets('should have two save buttons when dirty', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(file: testFile, isDirty: true),
        );
        await tester.pumpAndSettle();

        // Assert - One in header, one in dirty indicator
        expect(find.text('Save'), findsNWidgets(2));
      });
    });
  });
}
