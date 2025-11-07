import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';

import 'helpers/mock_plugin_context.dart';

void main() {
  late MockEventBus eventBus;
  late PluginEventDispatcher dispatcher;

  setUp(() {
    eventBus = MockEventBus();
    dispatcher = PluginEventDispatcher(eventBus);
  });

  tearDown(() {
    dispatcher.dispose();
    eventBus.dispose();
  });

  group('PluginEventContext', () {
    test('should start with cancelled = false', () {
      final file = FileDocument(
        id: 'test',
        name: 'test.dart',
        folderId: 'folder',
        content: '',
        language: 'dart',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final event = FileOpened(file: file);
      final context = PluginEventContext(event);

      expect(context.isCancelled, false);
      expect(context.isPropagationStopped, false);
    });

    test('should allow cancellation', () {
      final file = FileDocument(
        id: 'test',
        name: 'test.dart',
        folderId: 'folder',
        content: '',
        language: 'dart',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final event = FileOpened(file: file);
      final context = PluginEventContext(event);

      context.cancel();

      expect(context.isCancelled, true);
    });

    test('should allow stopping propagation', () {
      final file = FileDocument(
        id: 'test',
        name: 'test.dart',
        folderId: 'folder',
        content: '',
        language: 'dart',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final event = FileOpened(file: file);
      final context = PluginEventContext(event);

      context.stopPropagation();

      expect(context.isPropagationStopped, true);
    });
  });

  group('registerHandler', () {
    test('should register handler for event type', () {
      var handlerCalled = false;

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'test-plugin',
        handler: (context) {
          handlerCalled = true;
        },
      );

      final handlers = dispatcher.getHandlersForEvent<FileOpened>();

      expect(handlers, contains('test-plugin'));
      expect(handlerCalled, false); // Not called until dispatch
    });

    test('should register multiple handlers', () {
      dispatcher.registerHandler<FileOpened>(
        pluginId: 'plugin-1',
        handler: (context) {},
      );

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'plugin-2',
        handler: (context) {},
      );

      final handlers = dispatcher.getHandlersForEvent<FileOpened>();

      expect(handlers, containsAll(['plugin-1', 'plugin-2']));
    });

    test('should sort handlers by priority', () {
      dispatcher.registerHandler<FileOpened>(
        pluginId: 'low-priority',
        priority: EventPriority.low,
        handler: (context) {},
      );

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'high-priority',
        priority: EventPriority.high,
        handler: (context) {},
      );

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'normal-priority',
        priority: EventPriority.normal,
        handler: (context) {},
      );

      final handlers = dispatcher.getHandlersForEvent<FileOpened>();

      // Should be sorted: high, normal, low
      expect(handlers[0], 'high-priority');
      expect(handlers[1], 'normal-priority');
      expect(handlers[2], 'low-priority');
    });
  });

  group('removeHandlers', () {
    test('should remove all handlers for a plugin', () {
      dispatcher.registerHandler<FileOpened>(
        pluginId: 'test-plugin',
        handler: (context) {},
      );

      dispatcher.registerHandler<FileSaved>(
        pluginId: 'test-plugin',
        handler: (context) {},
      );

      expect(dispatcher.getHandlersForEvent<FileOpened>(), contains('test-plugin'));
      expect(dispatcher.getHandlersForEvent<FileSaved>(), contains('test-plugin'));

      dispatcher.removeHandlers('test-plugin');

      expect(dispatcher.getHandlersForEvent<FileOpened>(), isEmpty);
      expect(dispatcher.getHandlersForEvent<FileSaved>(), isEmpty);
    });

    test('should not affect other plugins', () {
      dispatcher.registerHandler<FileOpened>(
        pluginId: 'plugin-1',
        handler: (context) {},
      );

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'plugin-2',
        handler: (context) {},
      );

      dispatcher.removeHandlers('plugin-1');

      expect(dispatcher.getHandlersForEvent<FileOpened>(), ['plugin-2']);
    });
  });

  group('dispatch', () {
    test('should call registered handlers', () async {
      var handlerCalled = false;
      FileDocument? receivedFile;

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'test-plugin',
        handler: (context) {
          handlerCalled = true;
          receivedFile = context.event.file;
        },
      );

      final file = FileDocument(
        id: 'test',
        name: 'test.dart',
        folderId: 'folder',
        content: '',
        language: 'dart',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final event = FileOpened(file: file);

      await dispatcher.dispatch(event);

      expect(handlerCalled, true);
      expect(receivedFile, file);
    });

    test('should call handlers in priority order', () async {
      final callOrder = <String>[];

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'low',
        priority: EventPriority.low,
        handler: (context) {
          callOrder.add('low');
        },
      );

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'highest',
        priority: EventPriority.highest,
        handler: (context) {
          callOrder.add('highest');
        },
      );

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'normal',
        priority: EventPriority.normal,
        handler: (context) {
          callOrder.add('normal');
        },
      );

      final file = FileDocument(
        id: 'test',
        name: 'test.dart',
        folderId: 'folder',
        content: '',
        language: 'dart',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final event = FileOpened(file: file);

      await dispatcher.dispatch(event);

      expect(callOrder, ['highest', 'normal', 'low']);
    });

    test('should stop propagation when requested', () async {
      final callOrder = <String>[];

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'first',
        priority: EventPriority.highest,
        handler: (context) {
          callOrder.add('first');
          context.stopPropagation();
        },
      );

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'second',
        priority: EventPriority.normal,
        handler: (context) {
          callOrder.add('second');
        },
      );

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'third',
        priority: EventPriority.low,
        handler: (context) {
          callOrder.add('third');
        },
      );

      final file = FileDocument(
        id: 'test',
        name: 'test.dart',
        folderId: 'folder',
        content: '',
        language: 'dart',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final event = FileOpened(file: file);

      final context = await dispatcher.dispatch(event);

      expect(callOrder, ['first']); // Only first handler called
      expect(context.isPropagationStopped, true);
    });

    test('should return context with cancellation status', () async {
      dispatcher.registerHandler<FileOpened>(
        pluginId: 'canceller',
        handler: (context) {
          context.cancel();
        },
      );

      final file = FileDocument(
        id: 'test',
        name: 'test.dart',
        folderId: 'folder',
        content: '',
        language: 'dart',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final event = FileOpened(file: file);

      final context = await dispatcher.dispatch(event);

      expect(context.isCancelled, true);
    });

    test('should return empty context when no handlers registered', () async {
      final file = FileDocument(
        id: 'test',
        name: 'test.dart',
        folderId: 'folder',
        content: '',
        language: 'dart',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final event = FileOpened(file: file);

      final context = await dispatcher.dispatch(event);

      expect(context.isCancelled, false);
      expect(context.isPropagationStopped, false);
    });

    test('should rethrow errors from handlers', () async {
      dispatcher.registerHandler<FileOpened>(
        pluginId: 'error-handler',
        handler: (context) {
          throw Exception('Handler error');
        },
      );

      final file = FileDocument(
        id: 'test',
        name: 'test.dart',
        folderId: 'folder',
        content: '',
        language: 'dart',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final event = FileOpened(file: file);

      expect(
        () => dispatcher.dispatch(event),
        throwsException,
      );
    });
  });

  group('filtering', () {
    test('should filter events based on condition', () async {
      final handledFiles = <String>[];

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'dart-only',
        handler: (context) {
          handledFiles.add(context.event.file.id);
        },
        filter: (event) => event.file.language == 'dart',
      );

      final dartFile = FileDocument(
        id: 'dart-file',
        name: 'test.dart',
        folderId: 'folder',
        content: '',
        language: 'dart',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final jsFile = FileDocument(
        id: 'js-file',
        name: 'test.js',
        folderId: 'folder',
        content: '',
        language: 'javascript',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await dispatcher.dispatch(FileOpened(file: dartFile));
      await dispatcher.dispatch(FileOpened(file: jsFile));

      expect(handledFiles, ['dart-file']); // Only dart file handled
    });

    test('should handle filter exceptions gracefully', () async {
      var handlerCalled = false;

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'broken-filter',
        handler: (context) {
          handlerCalled = true;
        },
        filter: (event) => throw Exception('Filter error'),
      );

      final file = FileDocument(
        id: 'test',
        name: 'test.dart',
        folderId: 'folder',
        content: '',
        language: 'dart',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await dispatcher.dispatch(FileOpened(file: file));

      expect(handlerCalled, false); // Handler not called due to filter error
    });
  });

  group('subscribeToEventBus', () {
    test('should dispatch events from EventBus', () async {
      var handlerCalled = false;

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'test-plugin',
        handler: (context) {
          handlerCalled = true;
        },
      );

      dispatcher.subscribeToEventBus<FileOpened>();

      final file = FileDocument(
        id: 'test',
        name: 'test.dart',
        folderId: 'folder',
        content: '',
        language: 'dart',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      eventBus.publish(FileOpened(file: file));

      // Give event bus time to process
      await Future.delayed(const Duration(milliseconds: 50));

      expect(handlerCalled, true);
    });
  });

  group('getHandlersForEvent', () {
    test('should return list of plugin IDs', () {
      dispatcher.registerHandler<FileOpened>(
        pluginId: 'plugin-1',
        handler: (context) {},
      );

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'plugin-2',
        handler: (context) {},
      );

      final handlers = dispatcher.getHandlersForEvent<FileOpened>();

      expect(handlers, ['plugin-1', 'plugin-2']);
    });

    test('should return empty list for unregistered event', () {
      final handlers = dispatcher.getHandlersForEvent<FileSaved>();

      expect(handlers, isEmpty);
    });
  });

  group('getRegisteredEventTypes', () {
    test('should return all registered event types', () {
      dispatcher.registerHandler<FileOpened>(
        pluginId: 'plugin-1',
        handler: (context) {},
      );

      dispatcher.registerHandler<FileSaved>(
        pluginId: 'plugin-2',
        handler: (context) {},
      );

      final types = dispatcher.getRegisteredEventTypes();

      expect(types, containsAll([FileOpened, FileSaved]));
    });

    test('should return empty list when no handlers registered', () {
      final types = dispatcher.getRegisteredEventTypes();

      expect(types, isEmpty);
    });
  });

  group('dispose', () {
    test('should clear all handlers', () {
      dispatcher.registerHandler<FileOpened>(
        pluginId: 'plugin-1',
        handler: (context) {},
      );

      expect(dispatcher.getHandlersForEvent<FileOpened>(), isNotEmpty);

      dispatcher.dispose();

      expect(dispatcher.getRegisteredEventTypes(), isEmpty);
    });
  });
}
