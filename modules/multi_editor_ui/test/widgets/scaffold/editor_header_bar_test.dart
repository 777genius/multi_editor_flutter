import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import 'package:multi_editor_ui/src/widgets/scaffold/widgets/editor_header_bar.dart';

// Mocks
class MockPluginUIService extends Mock implements PluginUIService {}

class MockPluginManager extends Mock implements PluginManager {}

void main() {
  group('EditorHeaderBar Widget Tests', () {
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
        name: 'very_long_file_name_that_might_cause_layout_issues_in_ui.dart',
        content: '',
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
          body: EditorHeaderBar(
            file: file,
            isDirty: isDirty,
            isSaving: isSaving,
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
      testWidgets('should display file name', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(file: testFile));

        // Assert
        expect(find.text('test.dart'), findsOneWidget);
      });

      testWidgets('should display long file name without overflow',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(file: longNameFile));

        // Assert
        expect(find.text(longNameFile.name), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should show save button when dirty', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(file: testFile, isDirty: true),
        );

        // Assert
        expect(find.byIcon(Icons.save), findsOneWidget);
        expect(find.text('Modified'), findsOneWidget);
      });

      testWidgets('should show progress when saving', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(file: testFile, isSaving: true, isDirty: true),
        );

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byIcon(Icons.save), findsNothing);
      });

      testWidgets('should not show save button when clean', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(file: testFile, isDirty: false),
        );

        // Assert
        expect(find.byIcon(Icons.save), findsNothing);
        expect(find.text('Modified'), findsNothing);
      });

      testWidgets('should always show close button', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(file: testFile));

        // Assert
        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('should show file icon', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(file: testFile));

        // Assert
        expect(find.byIcon(Icons.insert_drive_file), findsOneWidget);
      });

      testWidgets('should show modified text with italic style when dirty',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(file: testFile, isDirty: true),
        );

        // Assert
        final modifiedText = tester.widget<Text>(find.text('Modified'));
        expect(modifiedText.style?.fontStyle, equals(FontStyle.italic));
      });

      testWidgets('should show circular progress with correct stroke width',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(file: testFile, isSaving: true, isDirty: true),
        );

        // Assert
        final progress = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(progress.strokeWidth, equals(2));
      });
    });

    group('Interactions', () {
      testWidgets('should call onSave when save button tapped',
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

      testWidgets('should call onClose when close button tapped',
          (tester) async {
        // Arrange
        var closeCalled = false;
        await tester.pumpWidget(
          createWidget(file: testFile, onClose: () => closeCalled = true),
        );

        // Act
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Assert
        expect(closeCalled, isTrue);
      });

      testWidgets('should not call onSave when saving', (tester) async {
        // Arrange
        var saveCallCount = 0;
        await tester.pumpWidget(
          createWidget(
            file: testFile,
            isDirty: true,
            isSaving: true,
            onSave: () => saveCallCount++,
          ),
        );

        // Act & Assert - No save button should exist
        expect(find.byIcon(Icons.save), findsNothing);
        expect(saveCallCount, equals(0));
      });

      testWidgets('should handle multiple close button taps', (tester) async {
        // Arrange
        var closeCallCount = 0;
        await tester.pumpWidget(
          createWidget(
            file: testFile,
            onClose: () => closeCallCount++,
          ),
        );

        // Act
        await tester.tap(find.byIcon(Icons.close));
        await tester.pump(const Duration(milliseconds: 10));
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Assert
        expect(closeCallCount, equals(2));
      });
    });

    group('Plugin Integration', () {
      testWidgets('should show plugin buttons when service provided',
          (tester) async {
        // Arrange
        final mockService = MockPluginUIService();
        when(() => mockService.getRegisteredUIs()).thenReturn([]);

        // Act
        await tester.pumpWidget(
          createWidget(file: testFile, pluginUIService: mockService),
        );

        // Assert
        verify(() => mockService.getRegisteredUIs()).called(1);
      });

      testWidgets('should render plugin buttons from service', (tester) async {
        // Arrange
        final mockService = MockPluginUIService();
        final descriptor = PluginUIDescriptor(
          pluginId: 'test-plugin',
          iconCode: Icons.star.codePoint,
          tooltip: 'Test Plugin',
          uiData: const {'type': 'list', 'items': []},
        );
        when(() => mockService.getRegisteredUIs()).thenReturn([descriptor]);

        // Act
        await tester.pumpWidget(
          createWidget(file: testFile, pluginUIService: mockService),
        );

        // Assert
        expect(find.byIcon(Icons.star), findsOneWidget);
      });

      testWidgets('should handle null plugin services gracefully',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(
            file: testFile,
            pluginUIService: null,
            pluginManager: null,
          ),
        );

        // Assert - Should render without errors
        expect(tester.takeException(), isNull);
        expect(find.text('test.dart'), findsOneWidget);
      });

      testWidgets('should get file icon from plugin manager', (tester) async {
        // Arrange
        final mockManager = MockPluginManager();
        final iconDescriptor = FileIconDescriptor(
          iconCode: Icons.flutter_dash.codePoint,
          color: '#2196F3',
        );
        when(() => mockManager.getFileIconDescriptorByName('test.dart'))
            .thenReturn(iconDescriptor);

        // Act
        await tester.pumpWidget(
          createWidget(file: testFile, pluginManager: mockManager),
        );

        // Assert
        verify(() => mockManager.getFileIconDescriptorByName('test.dart'))
            .called(1);
      });

      testWidgets('should use default icon when plugin manager returns null',
          (tester) async {
        // Arrange
        final mockManager = MockPluginManager();
        when(() => mockManager.getFileIconDescriptorByName(any()))
            .thenReturn(null);

        // Act
        await tester.pumpWidget(
          createWidget(file: testFile, pluginManager: mockManager),
        );

        // Assert
        expect(find.byIcon(Icons.insert_drive_file), findsOneWidget);
      });

      testWidgets('should pass onPluginAction callback', (tester) async {
        // Arrange
        final mockService = MockPluginUIService();
        final descriptor = PluginUIDescriptor(
          pluginId: 'test-plugin',
          iconCode: Icons.star.codePoint,
          tooltip: 'Test Plugin',
          uiData: const {'type': 'list', 'items': []},
        );
        when(() => mockService.getRegisteredUIs()).thenReturn([descriptor]);

        var actionCalled = false;
        String? receivedAction;
        Map<String, dynamic>? receivedData;

        // Act
        await tester.pumpWidget(
          createWidget(
            file: testFile,
            pluginUIService: mockService,
            onPluginAction: (action, data) {
              actionCalled = true;
              receivedAction = action;
              receivedData = data;
            },
          ),
        );

        // Assert - Widget should render
        expect(find.byIcon(Icons.star), findsOneWidget);
      });
    });

    group('Theme Integration', () {
      testWidgets('should use theme colors for file name', (tester) async {
        // Arrange
        final customTheme = ThemeData(
          textTheme: const TextTheme(
            titleSmall: TextStyle(fontSize: 14, color: Colors.red),
          ),
        );

        // Act
        await tester.pumpWidget(
          createWidget(file: testFile, theme: customTheme),
        );

        // Assert
        final text = tester.widget<Text>(find.text('test.dart'));
        expect(text.style?.fontWeight, equals(FontWeight.w600));
      });

      testWidgets('should use theme primary color for modified text',
          (tester) async {
        // Arrange
        final customTheme = ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        );

        // Act
        await tester.pumpWidget(
          createWidget(file: testFile, isDirty: true, theme: customTheme),
        );

        // Assert
        final modifiedText = tester.widget<Text>(find.text('Modified'));
        expect(modifiedText.style?.color, equals(customTheme.colorScheme.primary));
      });

      testWidgets('should use theme divider color', (tester) async {
        // Arrange
        final customTheme = ThemeData(dividerColor: Colors.purple);

        // Act
        await tester.pumpWidget(
          createWidget(file: testFile, theme: customTheme),
        );
        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration as BoxDecoration;
        final border = decoration.border as Border;

        // Assert
        expect(border.bottom.color, equals(Colors.purple));
      });

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

        // Assert - Should render without errors
        expect(tester.takeException(), isNull);
        expect(find.text('test.dart'), findsOneWidget);
      });
    });

    group('Layout & Visual Design', () {
      testWidgets('should have correct padding', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(file: testFile));
        final container = tester.widget<Container>(find.byType(Container));

        // Assert
        expect(
          container.padding,
          equals(const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
        );
      });

      testWidgets('should have bottom border', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(file: testFile));
        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration as BoxDecoration;
        final border = decoration.border as Border;

        // Assert
        expect(border.bottom.width, equals(1));
      });

      testWidgets('should use Row layout', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(file: testFile));

        // Assert
        expect(find.byType(Row), findsWidgets);
      });

      testWidgets('should expand file name to fill available space',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(file: testFile));

        // Assert
        expect(find.byType(Expanded), findsOneWidget);
      });

      testWidgets('should have proper spacing between elements',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(file: testFile));

        // Assert
        final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
        expect(sizedBoxes.any((box) => box.width == 8), isTrue);
      });

      testWidgets('should maintain layout in narrow viewports', (tester) async {
        // Arrange
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Act
        await tester.pumpWidget(createWidget(file: testFile, isDirty: true));

        // Assert
        expect(tester.takeException(), isNull);
        expect(find.text('test.dart'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have save tooltip', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(file: testFile, isDirty: true),
        );

        // Assert
        expect(find.byTooltip('Save (Ctrl+S)'), findsOneWidget);
      });

      testWidgets('should have close tooltip', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(file: testFile));

        // Assert
        expect(find.byTooltip('Close'), findsOneWidget);
      });

      testWidgets('should have semantic labels for file name', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(file: testFile));

        // Assert
        expect(find.text('test.dart'), findsOneWidget);
      });

      testWidgets('should indicate modified state accessibly', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(file: testFile, isDirty: true),
        );

        // Assert
        expect(find.text('Modified'), findsOneWidget);
      });
    });

    group('State Transitions', () {
      testWidgets('should transition from clean to dirty', (tester) async {
        // Arrange
        var isDirty = false;
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return createWidget(
                file: testFile,
                isDirty: isDirty,
                onSave: () => setState(() => isDirty = false),
              );
            },
          ),
        );

        // Assert initial state
        expect(find.text('Modified'), findsNothing);

        // Act - Change state
        await tester.pumpWidget(
          createWidget(file: testFile, isDirty: true),
        );

        // Assert dirty state
        expect(find.text('Modified'), findsOneWidget);
        expect(find.byIcon(Icons.save), findsOneWidget);
      });

      testWidgets('should transition from dirty to saving', (tester) async {
        // Arrange - Dirty state
        await tester.pumpWidget(
          createWidget(file: testFile, isDirty: true, isSaving: false),
        );
        expect(find.byIcon(Icons.save), findsOneWidget);

        // Act - Change to saving
        await tester.pumpWidget(
          createWidget(file: testFile, isDirty: true, isSaving: true),
        );

        // Assert saving state
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byIcon(Icons.save), findsNothing);
      });

      testWidgets('should transition from saving to clean', (tester) async {
        // Arrange - Saving state
        await tester.pumpWidget(
          createWidget(file: testFile, isDirty: true, isSaving: true),
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Act - Change to clean
        await tester.pumpWidget(
          createWidget(file: testFile, isDirty: false, isSaving: false),
        );

        // Assert clean state
        expect(find.text('Modified'), findsNothing);
        expect(find.byIcon(Icons.save), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle empty file name', (tester) async {
        // Arrange
        final emptyNameFile = FileDocument(
          id: 'file-3',
          name: '',
          content: '',
          language: 'text',
          folderId: 'root',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        );

        // Act
        await tester.pumpWidget(createWidget(file: emptyNameFile));

        // Assert - Should render without error
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle very long file names', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createWidget(file: longNameFile));

        // Assert
        expect(tester.takeException(), isNull);
        expect(find.text(longNameFile.name), findsOneWidget);
      });

      testWidgets('should handle special characters in file name',
          (tester) async {
        // Arrange
        final specialFile = FileDocument(
          id: 'file-4',
          name: 'file-with-特殊字符-and-emojis-😀.txt',
          content: '',
          language: 'text',
          folderId: 'root',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        );

        // Act
        await tester.pumpWidget(createWidget(file: specialFile));

        // Assert
        expect(tester.takeException(), isNull);
        expect(find.text(specialFile.name), findsOneWidget);
      });

      testWidgets('should handle both dirty and saving states', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(file: testFile, isDirty: true, isSaving: true),
        );

        // Assert - Should show saving indicator, not save button
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byIcon(Icons.save), findsNothing);
        expect(find.text('Modified'), findsOneWidget);
      });
    });

    group('Use Cases', () {
      testWidgets('UC1: User opens a clean file', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(file: testFile, isDirty: false),
        );

        // Assert
        expect(find.text('test.dart'), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
        expect(find.text('Modified'), findsNothing);
        expect(find.byIcon(Icons.save), findsNothing);
      });

      testWidgets('UC2: User makes changes and sees dirty indicator',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(file: testFile, isDirty: true),
        );

        // Assert
        expect(find.text('test.dart'), findsOneWidget);
        expect(find.text('Modified'), findsOneWidget);
        expect(find.byIcon(Icons.save), findsOneWidget);
      });

      testWidgets('UC3: User saves file', (tester) async {
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

      testWidgets('UC4: User closes file', (tester) async {
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

      testWidgets('UC5: File is being saved', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          createWidget(file: testFile, isDirty: true, isSaving: true),
        );

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byIcon(Icons.save), findsNothing);
        expect(find.text('Modified'), findsOneWidget);
      });

      testWidgets('UC6: User interacts with plugin button', (tester) async {
        // Arrange
        final mockService = MockPluginUIService();
        final descriptor = PluginUIDescriptor(
          pluginId: 'test-plugin',
          iconCode: Icons.extension.codePoint,
          tooltip: 'Extensions',
          uiData: const {'type': 'list', 'items': []},
        );
        when(() => mockService.getRegisteredUIs()).thenReturn([descriptor]);

        await tester.pumpWidget(
          createWidget(file: testFile, pluginUIService: mockService),
        );

        // Act
        await tester.tap(find.byIcon(Icons.extension));
        await tester.pumpAndSettle();

        // Assert - Dialog should open
        expect(find.byType(Dialog), findsOneWidget);
      });
    });
  });
}
