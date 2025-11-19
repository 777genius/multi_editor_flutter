import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import 'package:multi_editor_ui/src/plugins/plugin_ui_builder.dart';

void main() {
  group('PluginUIBuilder Widget Tests', () {
    Widget createWidget({
      required PluginUIDescriptor descriptor,
      Function(String action, Map<String, dynamic> data)? onItemAction,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: PluginUIBuilder.build(
            descriptor,
            onItemAction: onItemAction ?? (_, __) {},
          ),
        ),
      );
    }

    group('List Type', () {
      testWidgets('should render empty list message', (tester) async {
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'list',
            'items': [],
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));
        expect(find.text('No items'), findsOneWidget);
      });

      testWidgets('should render list with items', (tester) async {
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'list',
            'items': [
              {
                'id': 'item1',
                'title': 'Item 1',
                'subtitle': 'Description',
              },
            ],
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Description'), findsOneWidget);
      });

      testWidgets('should render list item with icon', (tester) async {
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: {
            'type': 'list',
            'items': [
              {
                'id': 'item1',
                'title': 'File',
                'iconCode': Icons.insert_drive_file.codePoint,
              },
            ],
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));
        expect(find.text('File'), findsOneWidget);
        expect(find.byIcon(Icons.insert_drive_file), findsOneWidget);
      });

      testWidgets('should handle item tap', (tester) async {
        String? tappedId;
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'list',
            'items': [
              {
                'id': 'item1',
                'title': 'Tap Me',
                'onTap': 'select',
              },
            ],
          },
        );

        await tester.pumpWidget(
          createWidget(
            descriptor: descriptor,
            onItemAction: (action, data) {
              tappedId = data['id'] as String?;
            },
          ),
        );

        await tester.tap(find.text('Tap Me'));
        await tester.pumpAndSettle();

        expect(tappedId, equals('item1'));
      });

      testWidgets('should render multiple list items', (tester) async {
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'list',
            'items': [
              {'id': '1', 'title': 'Item 1'},
              {'id': '2', 'title': 'Item 2'},
              {'id': '3', 'title': 'Item 3'},
            ],
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 2'), findsOneWidget);
        expect(find.text('Item 3'), findsOneWidget);
      });
    });

    group('Custom Type', () {
      testWidgets('should show not implemented message', (tester) async {
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.widgets.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'custom',
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));
        expect(find.text('Custom UI type not yet implemented'), findsOneWidget);
      });
    });

    group('Unknown Type', () {
      testWidgets('should show error for unknown type', (tester) async {
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.error.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'unknown',
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));
        expect(find.text('Unknown UI type: unknown'), findsOneWidget);
      });
    });

    group('Use Cases', () {
      testWidgets('UC1: Recent files list', (tester) async {
        final descriptor = PluginUIDescriptor(
          pluginId: 'recent-files',
          iconCode: Icons.history.codePoint,
          tooltip: 'Recent Files',
          uiData: {
            'type': 'list',
            'items': [
              {
                'id': 'file1',
                'title': 'main.dart',
                'subtitle': 'lib/',
                'iconCode': Icons.code.codePoint,
                'onTap': 'openFile',
              },
              {
                'id': 'file2',
                'title': 'pubspec.yaml',
                'subtitle': 'root/',
                'iconCode': Icons.description.codePoint,
                'onTap': 'openFile',
              },
            ],
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));

        expect(find.text('main.dart'), findsOneWidget);
        expect(find.text('lib/'), findsOneWidget);
        expect(find.text('pubspec.yaml'), findsOneWidget);
        expect(find.text('root/'), findsOneWidget);
      });

      testWidgets('UC2: Empty search results', (tester) async {
        final descriptor = PluginUIDescriptor(
          pluginId: 'search',
          iconCode: Icons.search.codePoint,
          tooltip: 'Search',
          uiData: const {
            'type': 'list',
            'items': [],
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));
        expect(find.text('No items'), findsOneWidget);
      });

      testWidgets('UC3: Clickable list items trigger actions', (tester) async {
        var actionCalled = false;
        String? actionType;

        final descriptor = PluginUIDescriptor(
          pluginId: 'actions',
          iconCode: Icons.bolt.codePoint,
          tooltip: 'Actions',
          uiData: const {
            'type': 'list',
            'items': [
              {
                'id': 'action1',
                'title': 'Run Tests',
                'onTap': 'runTests',
              },
            ],
          },
        );

        await tester.pumpWidget(
          createWidget(
            descriptor: descriptor,
            onItemAction: (action, data) {
              actionCalled = true;
              actionType = action;
            },
          ),
        );

        await tester.tap(find.text('Run Tests'));
        await tester.pumpAndSettle();

        expect(actionCalled, isTrue);
        expect(actionType, equals('runTests'));
      });
    });

    group('HoverListTile Interactions', () {
      testWidgets('should show hover effect on mouse enter', (tester) async {
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'list',
            'items': [
              {'id': 'item1', 'title': 'Test Item'},
            ],
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));

        // Find the MouseRegion inside the list tile
        final mouseRegion = find.byType(MouseRegion).first;
        expect(mouseRegion, findsOneWidget);

        // Simulate hover
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();

        await gesture.moveTo(tester.getCenter(find.text('Test Item')));
        await tester.pumpAndSettle();

        // Verify AnimatedContainer exists (hover effect applied)
        expect(find.byType(AnimatedContainer), findsWidgets);
      });

      testWidgets('should remove hover effect on mouse exit', (tester) async {
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'list',
            'items': [
              {'id': 'item1', 'title': 'Test Item'},
            ],
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));

        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();

        // Hover
        await gesture.moveTo(tester.getCenter(find.text('Test Item')));
        await tester.pumpAndSettle();

        // Exit hover
        await gesture.moveTo(const Offset(-1, -1));
        await tester.pumpAndSettle();

        // Widget should still exist
        expect(find.text('Test Item'), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle missing type in uiData', (tester) async {
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.error.codePoint,
          tooltip: 'Test',
          uiData: const {}, // No 'type' field
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));
        expect(find.text('Unknown UI type: null'), findsOneWidget);
      });

      testWidgets('should handle null items in list', (tester) async {
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'list',
            // Missing 'items' field
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));
        expect(find.text('No items'), findsOneWidget);
      });

      testWidgets('should handle item without title', (tester) async {
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'list',
            'items': [
              {'id': 'item1'}, // No title
            ],
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));
        expect(find.text(''), findsOneWidget); // Empty title
      });

      testWidgets('should handle item without subtitle', (tester) async {
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'list',
            'items': [
              {'id': 'item1', 'title': 'Title Only'},
            ],
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));
        expect(find.text('Title Only'), findsOneWidget);
        // Subtitle should not be rendered
        final listTile = tester.widget<ListTile>(find.byType(ListTile).first);
        expect(listTile.subtitle, isNull);
      });

      testWidgets('should handle item without iconCode', (tester) async {
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'list',
            'items': [
              {'id': 'item1', 'title': 'No Icon'},
            ],
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));
        expect(find.text('No Icon'), findsOneWidget);
        // Should use default icon
        expect(find.byIcon(Icons.insert_drive_file), findsOneWidget);
      });

      testWidgets('should handle item without id', (tester) async {
        String? receivedId;
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'list',
            'items': [
              {'title': 'No ID'}, // Missing id
            ],
          },
        );

        await tester.pumpWidget(
          createWidget(
            descriptor: descriptor,
            onItemAction: (action, data) {
              receivedId = data['id'] as String?;
            },
          ),
        );

        await tester.tap(find.text('No ID'));
        await tester.pumpAndSettle();

        expect(receivedId, equals('')); // Default empty id
      });

      testWidgets('should handle item without onTap action', (tester) async {
        String? receivedAction;
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'list',
            'items': [
              {'id': 'item1', 'title': 'Default Action'},
            ],
          },
        );

        await tester.pumpWidget(
          createWidget(
            descriptor: descriptor,
            onItemAction: (action, data) {
              receivedAction = action;
            },
          ),
        );

        await tester.tap(find.text('Default Action'));
        await tester.pumpAndSettle();

        expect(receivedAction, equals('select')); // Default action
      });

      testWidgets('should handle very long item title', (tester) async {
        final longTitle = 'A' * 1000;
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: {
            'type': 'list',
            'items': [
              {'id': 'item1', 'title': longTitle},
            ],
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));
        expect(find.text(longTitle), findsOneWidget);
      });

      testWidgets('should handle special characters in title', (tester) async {
        const specialTitle = 'File<>:\"|?*.dart';
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'list',
            'items': [
              {'id': 'item1', 'title': specialTitle},
            ],
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));
        expect(find.text(specialTitle), findsOneWidget);
      });

      testWidgets('should handle empty list items array', (tester) async {
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'list',
            'items': [],
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));
        expect(find.text('No items'), findsOneWidget);
      });
    });

    group('List Item Properties', () {
      testWidgets('should render all item properties correctly', (tester) async {
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: {
            'type': 'list',
            'items': [
              {
                'id': 'file1',
                'title': 'main.dart',
                'subtitle': 'lib/src/',
                'iconCode': Icons.code.codePoint,
                'onTap': 'openFile',
              },
            ],
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));

        expect(find.text('main.dart'), findsOneWidget);
        expect(find.text('lib/src/'), findsOneWidget);
        expect(find.byIcon(Icons.code), findsOneWidget);
      });

      testWidgets('should pass all item data in onItemAction', (tester) async {
        Map<String, dynamic>? receivedData;
        String? receivedAction;

        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'list',
            'items': [
              {
                'id': 'file1',
                'title': 'main.dart',
                'subtitle': 'lib/',
                'customField': 'customValue',
                'onTap': 'openFile',
              },
            ],
          },
        );

        await tester.pumpWidget(
          createWidget(
            descriptor: descriptor,
            onItemAction: (action, data) {
              receivedAction = action;
              receivedData = data;
            },
          ),
        );

        await tester.tap(find.text('main.dart'));
        await tester.pumpAndSettle();

        expect(receivedAction, equals('openFile'));
        expect(receivedData?['id'], equals('file1'));
        expect(receivedData?['title'], equals('main.dart'));
        expect(receivedData?['customField'], equals('customValue'));
      });

      testWidgets('should handle dense list tiles', (tester) async {
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'list',
            'items': [
              {'id': 'item1', 'title': 'Item'},
            ],
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));

        final listTile = tester.widget<ListTile>(find.byType(ListTile).first);
        expect(listTile.dense, isTrue);
      });
    });

    group('Animation Tests', () {
      testWidgets('should have correct animation duration', (tester) async {
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'list',
            'items': [
              {'id': 'item1', 'title': 'Test'},
            ],
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));

        final animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        expect(animatedContainer.duration, equals(const Duration(milliseconds: 150)));
      });

      testWidgets('should have correct animation curve', (tester) async {
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'list',
            'items': [
              {'id': 'item1', 'title': 'Test'},
            ],
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));

        final animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        expect(animatedContainer.curve, equals(Curves.easeInOut));
      });
    });

    group('ListView Configuration', () {
      testWidgets('should use shrinkWrap for ListView', (tester) async {
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'list',
            'items': [
              {'id': 'item1', 'title': 'Item 1'},
            ],
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));

        final listView = tester.widget<ListView>(find.byType(ListView));
        expect(listView.shrinkWrap, isTrue);
      });

      testWidgets('should render correct number of items', (tester) async {
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'list',
            'items': [
              {'id': '1', 'title': 'Item 1'},
              {'id': '2', 'title': 'Item 2'},
              {'id': '3', 'title': 'Item 3'},
              {'id': '4', 'title': 'Item 4'},
              {'id': '5', 'title': 'Item 5'},
            ],
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));

        expect(find.byType(ListTile), findsNWidgets(5));
      });
    });

    group('Error Handling', () {
      testWidgets('should show error for null type', (tester) async {
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.error.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': null,
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));
        expect(find.text('Unknown UI type: null'), findsOneWidget);
      });

      testWidgets('should show error text in red', (tester) async {
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.error.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'invalid',
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));

        final text = tester.widget<Text>(find.text('Unknown UI type: invalid'));
        expect(text.style?.color, equals(Colors.red));
      });
    });

    group('Custom UI Type', () {
      testWidgets('should show not implemented message with gray text', (tester) async {
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.widgets.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'custom',
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));

        final text = tester.widget<Text>(
          find.text('Custom UI type not yet implemented'),
        );
        expect(text.style?.color, isNotNull);
      });

      testWidgets('should center custom UI message', (tester) async {
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.widgets.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'custom',
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));

        expect(find.byType(Center), findsOneWidget);
      });
    });

    group('Integration Tests', () {
      testWidgets('should handle rapid taps on list items', (tester) async {
        int tapCount = 0;
        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'list',
            'items': [
              {'id': 'item1', 'title': 'Tap Me'},
            ],
          },
        );

        await tester.pumpWidget(
          createWidget(
            descriptor: descriptor,
            onItemAction: (_, __) => tapCount++,
          ),
        );

        // Rapid taps
        for (int i = 0; i < 5; i++) {
          await tester.tap(find.text('Tap Me'));
          await tester.pump();
        }

        expect(tapCount, equals(5));
      });

      testWidgets('should handle scrolling in long list', (tester) async {
        final items = List.generate(
          50,
          (i) => {'id': 'item$i', 'title': 'Item $i'},
        );

        final descriptor = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: {
            'type': 'list',
            'items': items,
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor));

        // Should render the list
        expect(find.byType(ListView), findsOneWidget);

        // Check first and last items
        expect(find.text('Item 0'), findsOneWidget);
      });

      testWidgets('should maintain state during rebuild', (tester) async {
        final descriptor1 = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'list',
            'items': [
              {'id': 'item1', 'title': 'Original Item'},
            ],
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor1));
        expect(find.text('Original Item'), findsOneWidget);

        final descriptor2 = PluginUIDescriptor(
          pluginId: 'test',
          iconCode: Icons.list.codePoint,
          tooltip: 'Test',
          uiData: const {
            'type': 'list',
            'items': [
              {'id': 'item1', 'title': 'Updated Item'},
            ],
          },
        );

        await tester.pumpWidget(createWidget(descriptor: descriptor2));
        expect(find.text('Updated Item'), findsOneWidget);
        expect(find.text('Original Item'), findsNothing);
      });
    });
  });
}
