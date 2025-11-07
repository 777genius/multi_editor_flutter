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

  FileDocument createTestFile(String id) {
    return FileDocument(
      id: id,
      name: 'test.dart',
      folderId: 'folder',
      content: '',
      language: 'dart',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  group('Throttling', () {
    test('should execute handler immediately on first event', () async {
      var executionCount = 0;

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'test-plugin',
        handler: (context) {
          executionCount++;
        },
        throttle: const Duration(milliseconds: 100),
      );

      final file = createTestFile('test-1');
      await dispatcher.dispatch(FileOpened(file: file));

      expect(executionCount, 1);
    });

    test('should skip events within throttle duration', () async {
      var executionCount = 0;

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'test-plugin',
        handler: (context) {
          executionCount++;
        },
        throttle: const Duration(milliseconds: 100),
      );

      // Fire 5 events rapidly
      for (var i = 0; i < 5; i++) {
        final file = createTestFile('test-$i');
        await dispatcher.dispatch(FileOpened(file: file));
      }

      // Only first event should execute
      expect(executionCount, 1);
    });

    test('should execute again after throttle duration passes', () async {
      var executionCount = 0;

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'test-plugin',
        handler: (context) {
          executionCount++;
        },
        throttle: const Duration(milliseconds: 50),
      );

      // First event
      final file1 = createTestFile('test-1');
      await dispatcher.dispatch(FileOpened(file: file1));
      expect(executionCount, 1);

      // Wait for throttle duration to pass
      await Future.delayed(const Duration(milliseconds: 60));

      // Second event should execute
      final file2 = createTestFile('test-2');
      await dispatcher.dispatch(FileOpened(file: file2));
      expect(executionCount, 2);
    });

    test('should throttle each handler independently', () async {
      var handler1Count = 0;
      var handler2Count = 0;

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'plugin-1',
        handler: (context) {
          handler1Count++;
        },
        throttle: const Duration(milliseconds: 100),
      );

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'plugin-2',
        handler: (context) {
          handler2Count++;
        },
        throttle: const Duration(milliseconds: 200),
      );

      // First event - both execute
      final file1 = createTestFile('test-1');
      await dispatcher.dispatch(FileOpened(file: file1));
      expect(handler1Count, 1);
      expect(handler2Count, 1);

      // Wait 150ms - only plugin-1 should be ready
      await Future.delayed(const Duration(milliseconds: 150));

      final file2 = createTestFile('test-2');
      await dispatcher.dispatch(FileOpened(file: file2));
      expect(handler1Count, 2);
      expect(handler2Count, 1); // Still throttled
    });

    test('should work with priority ordering', () async {
      final callOrder = <String>[];

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'low-priority',
        priority: EventPriority.low,
        handler: (context) {
          callOrder.add('low');
        },
        throttle: const Duration(milliseconds: 100),
      );

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'high-priority',
        priority: EventPriority.high,
        handler: (context) {
          callOrder.add('high');
        },
        throttle: const Duration(milliseconds: 100),
      );

      final file = createTestFile('test-1');
      await dispatcher.dispatch(FileOpened(file: file));

      expect(callOrder, ['high', 'low']);

      // Fire again immediately - both should be throttled
      callOrder.clear();
      final file2 = createTestFile('test-2');
      await dispatcher.dispatch(FileOpened(file: file2));

      expect(callOrder, isEmpty);
    });
  });

  group('Debouncing', () {
    test('should delay execution until debounce period passes', () async {
      var executionCount = 0;

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'test-plugin',
        handler: (context) {
          executionCount++;
        },
        debounce: const Duration(milliseconds: 100),
      );

      final file = createTestFile('test-1');
      await dispatcher.dispatch(FileOpened(file: file));

      // Should not execute immediately
      expect(executionCount, 0);

      // Wait for debounce period
      await Future.delayed(const Duration(milliseconds: 120));

      // Now it should have executed
      expect(executionCount, 1);
    });

    test('should reset timer on each new event', () async {
      var executionCount = 0;

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'test-plugin',
        handler: (context) {
          executionCount++;
        },
        debounce: const Duration(milliseconds: 100),
      );

      // Fire events every 50ms for 250ms
      for (var i = 0; i < 5; i++) {
        final file = createTestFile('test-$i');
        await dispatcher.dispatch(FileOpened(file: file));
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Should not have executed yet (timer keeps resetting)
      expect(executionCount, 0);

      // Wait for debounce period after last event
      await Future.delayed(const Duration(milliseconds: 120));

      // Now it should execute once
      expect(executionCount, 1);
    });

    test('should cancel timer when handler is removed', () async {
      var executionCount = 0;

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'test-plugin',
        handler: (context) {
          executionCount++;
        },
        debounce: const Duration(milliseconds: 100),
      );

      final file = createTestFile('test-1');
      await dispatcher.dispatch(FileOpened(file: file));

      // Remove handler before debounce fires
      dispatcher.removeHandlers('test-plugin');

      // Wait for debounce period
      await Future.delayed(const Duration(milliseconds: 120));

      // Should not have executed
      expect(executionCount, 0);
    });

    test('should debounce each handler independently', () async {
      var handler1Count = 0;
      var handler2Count = 0;

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'plugin-1',
        handler: (context) {
          handler1Count++;
        },
        debounce: const Duration(milliseconds: 50),
      );

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'plugin-2',
        handler: (context) {
          handler2Count++;
        },
        debounce: const Duration(milliseconds: 100),
      );

      final file = createTestFile('test-1');
      await dispatcher.dispatch(FileOpened(file: file));

      // Wait 70ms - plugin-1 should execute, plugin-2 should not
      await Future.delayed(const Duration(milliseconds: 70));
      expect(handler1Count, 1);
      expect(handler2Count, 0);

      // Wait another 50ms - plugin-2 should execute
      await Future.delayed(const Duration(milliseconds: 50));
      expect(handler1Count, 1);
      expect(handler2Count, 1);
    });

    test('should work with filters', () async {
      var executionCount = 0;
      String? lastFileId;

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'test-plugin',
        handler: (context) {
          executionCount++;
          lastFileId = context.event.file.id;
        },
        debounce: const Duration(milliseconds: 100),
        filter: (event) => event.file.language == 'dart',
      );

      // Dispatch dart file - should schedule debounce
      final dartFile = createTestFile('dart-file');
      await dispatcher.dispatch(FileOpened(file: dartFile));

      // Dispatch js file - should be filtered out
      final jsFile = FileDocument(
        id: 'js-file',
        name: 'test.js',
        folderId: 'folder',
        content: '',
        language: 'javascript',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await dispatcher.dispatch(FileOpened(file: jsFile));

      // Wait for debounce
      await Future.delayed(const Duration(milliseconds: 120));

      // Should execute once, for dart file only
      expect(executionCount, 1);
      expect(lastFileId, 'dart-file');
    });
  });

  group('Validation', () {
    test('should throw assertion error when using both throttle and debounce', () {
      expect(
        () => dispatcher.registerHandler<FileOpened>(
          pluginId: 'test-plugin',
          handler: (context) {},
          throttle: const Duration(milliseconds: 100),
          debounce: const Duration(milliseconds: 100),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Cleanup', () {
    test('should cancel all timers on dispose', () async {
      var executionCount = 0;

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'test-plugin',
        handler: (context) {
          executionCount++;
        },
        debounce: const Duration(milliseconds: 100),
      );

      final file = createTestFile('test-1');
      await dispatcher.dispatch(FileOpened(file: file));

      // Dispose before debounce fires
      dispatcher.dispose();

      // Wait for debounce period
      await Future.delayed(const Duration(milliseconds: 120));

      // Should not have executed
      expect(executionCount, 0);
    });

    test('should handle multiple debounced handlers on dispose', () async {
      var count1 = 0;
      var count2 = 0;

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'plugin-1',
        handler: (context) {
          count1++;
        },
        debounce: const Duration(milliseconds: 100),
      );

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'plugin-2',
        handler: (context) {
          count2++;
        },
        debounce: const Duration(milliseconds: 100),
      );

      final file = createTestFile('test-1');
      await dispatcher.dispatch(FileOpened(file: file));

      dispatcher.dispose();

      await Future.delayed(const Duration(milliseconds: 120));

      expect(count1, 0);
      expect(count2, 0);
    });
  });

  group('Integration', () {
    test('should work with non-throttled handlers', () async {
      var throttledCount = 0;
      var normalCount = 0;

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'throttled',
        handler: (context) {
          throttledCount++;
        },
        throttle: const Duration(milliseconds: 100),
      );

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'normal',
        handler: (context) {
          normalCount++;
        },
      );

      // Fire 3 events rapidly
      for (var i = 0; i < 3; i++) {
        final file = createTestFile('test-$i');
        await dispatcher.dispatch(FileOpened(file: file));
      }

      expect(throttledCount, 1); // Only first event
      expect(normalCount, 3); // All events
    });

    test('should respect propagation stop with throttling', () async {
      var handler1Count = 0;
      var handler2Count = 0;

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'first',
        priority: EventPriority.highest,
        handler: (context) {
          handler1Count++;
          context.stopPropagation();
        },
        throttle: const Duration(milliseconds: 100),
      );

      dispatcher.registerHandler<FileOpened>(
        pluginId: 'second',
        priority: EventPriority.normal,
        handler: (context) {
          handler2Count++;
        },
        throttle: const Duration(milliseconds: 100),
      );

      final file = createTestFile('test-1');
      await dispatcher.dispatch(FileOpened(file: file));

      expect(handler1Count, 1);
      expect(handler2Count, 0); // Stopped by first handler
    });
  });
}
