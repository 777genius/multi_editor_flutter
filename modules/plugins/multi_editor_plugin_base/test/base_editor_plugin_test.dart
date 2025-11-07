import 'package:flutter_test/flutter_test.dart';

import 'helpers/mock_plugin_context.dart';
import 'helpers/test_plugins.dart';

void main() {
  late MockPluginContext mockContext;

  setUp(() {
    mockContext = MockPluginContext();
  });

  group('BaseEditorPlugin', () {
    group('Lifecycle', () {
      test('should start uninitialized', () {
        final plugin = TestPlugin();

        expect(plugin.testIsInitialized, false);
      });

      test('should initialize successfully', () async {
        final plugin = TestPlugin();

        await plugin.initialize(mockContext);

        expect(plugin.testIsInitialized, true);
        expect(plugin.isInitializeCalled, true);
      });

      test('should set context after initialization', () async {
        final plugin = TestPlugin();

        await plugin.initialize(mockContext);

        expect(plugin.getContext(), mockContext);
      });

      test('should throw StateError when accessing context before init', () {
        final plugin = TestPlugin();

        expect(() => plugin.getContext(), throwsStateError);
      });

      test('should throw when initializing twice', () async {
        final plugin = TestPlugin();

        await plugin.initialize(mockContext);

        expect(
          () => plugin.initialize(mockContext),
          throwsA(isA<StateError>()),
        );
      });

      test('should throw on initialization failure', () async {
        final plugin = FailingPlugin(errorMessage: 'Test error');

        expect(
          () => plugin.initialize(mockContext),
          throwsA(isA<Exception>()),
        );
      });

      test('should dispose successfully', () async {
        final plugin = TestPlugin();

        await plugin.initialize(mockContext);
        await plugin.dispose();

        expect(plugin.isDisposeCalled, true);
        expect(plugin.testIsInitialized, false);
      });

      test('should throw on disposal error', () async {
        final plugin = ThrowingDisposePlugin();

        await plugin.initialize(mockContext);

        expect(
          () => plugin.dispose(),
          throwsA(isA<Exception>()),
        );
      });

      test('should dispose uninitialized plugin without error', () async {
        final plugin = TestPlugin();

        await plugin.dispose();

        expect(plugin.isDisposeCalled, true);
      });
    });

    group('Safe Execution', () {
      test('should execute action successfully', () async {
        final plugin = TestPlugin();
        await plugin.initialize(mockContext);

        var executed = false;
        plugin.executeSafely(() {
          executed = true;
        });

        expect(executed, true);
      });

      test('should catch and handle exceptions in safeExecute', () async {
        final plugin = TestPlugin();
        await plugin.initialize(mockContext);

        var errorHandled = false;

        plugin.executeSafely(
          () {
            throw Exception('Test error');
          },
          onError: (e) {
            errorHandled = true;
          },
        );

        expect(errorHandled, true);
      });

      test('should execute async action successfully', () async {
        final plugin = TestPlugin();
        await plugin.initialize(mockContext);

        var executed = false;

        await plugin.executeSafelyAsync(() async {
          await Future.delayed(const Duration(milliseconds: 10));
          executed = true;
        });

        expect(executed, true);
      });

      test('should catch and handle exceptions in safeExecuteAsync',
          () async {
        final plugin = TestPlugin();
        await plugin.initialize(mockContext);

        var errorHandled = false;

        await plugin.executeSafelyAsync(
          () async {
            throw Exception('Test async error');
          },
          onError: (e) {
            errorHandled = true;
          },
        );

        expect(errorHandled, true);
      });
    });
  });
}
