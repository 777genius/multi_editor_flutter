import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugin_base/multi_editor_plugin_base.dart';

import 'helpers/mock_storage.dart';
import 'helpers/test_plugins.dart';

void main() {
  late MockPluginStorage mockStorage;
  late ConfigurableTestPlugin plugin;
  late PluginId pluginId;

  setUp(() {
    mockStorage = MockPluginStorage();
    plugin = ConfigurableTestPlugin();
    pluginId = const PluginId(value: 'plugin.configurable-test-plugin');
  });

  tearDown(() {
    mockStorage.reset();
  });

  group('ConfigurablePlugin', () {
    group('Load Configuration', () {
      test('should load configuration successfully', () async {
        await plugin.loadConfiguration(mockStorage, pluginId);

        expect(plugin.hasConfiguration, true);
        expect(plugin.configuration.pluginId, pluginId);
      });

      test('should create default configuration if storage is empty', () async {
        await plugin.loadConfiguration(mockStorage, pluginId);

        expect(plugin.configuration.enabled, true);
        expect(plugin.configuration.settings, isEmpty);
      });

      test('should load existing configuration from storage', () async {
        // Pre-populate storage
        await mockStorage.save(
          'config.plugin.configurable-test-plugin',
          {
            'pluginId': {'value': 'plugin.configurable-test-plugin'},
            'enabled': false,
            'settings': {'option1': 'saved-value'},
          },
        );

        await plugin.loadConfiguration(mockStorage, pluginId);

        expect(plugin.configuration.enabled, false);
        expect(plugin.getConfigSetting<String>('option1'), 'saved-value');
      });

      test('should create default config on load error from storage', () async {
        // Storage returns corrupted data
        await mockStorage.save(
          'config.plugin.configurable-test-plugin',
          {'invalid': 'data'},
        );

        await plugin.loadConfiguration(mockStorage, pluginId);

        expect(plugin.hasConfiguration, true);
        expect(plugin.configuration.pluginId, pluginId);
      });

      test('should throw StateError when accessing config before load', () {
        expect(() => plugin.configuration, throwsStateError);
      });
    });

    group('Save Configuration', () {
      test('should save configuration to storage', () async {
        await plugin.loadConfiguration(mockStorage, pluginId);
        await plugin.setConfigSetting('testKey', 'testValue');

        final result = await mockStorage.load('config.plugin.configurable-test-plugin');
        expect(result.fold((_) => false, (_) => true), true);
      });

      test('should throw StateError when saving without loading first', () {
        expect(() => plugin.saveConfiguration(), throwsStateError);
      });

      test('should handle storage failure gracefully', () async {
        await plugin.loadConfiguration(mockStorage, pluginId);

        mockStorage.setShouldFail(true);

        // Should not throw, but fail silently or return Either
        // Depending on implementation, this might need adjustment
        await expectLater(
          plugin.saveConfiguration(),
          completes,
        );
      });
    });

    group('Update Configuration', () {
      test('should update configuration with callback', () async {
        await plugin.loadConfiguration(mockStorage, pluginId);

        await plugin.updateConfiguration((config) {
          return config.copyWith(enabled: false);
        });

        expect(plugin.configuration.enabled, false);
      });

      test('should save after updating configuration', () async {
        await plugin.loadConfiguration(mockStorage, pluginId);

        await plugin.updateConfiguration((config) {
          return config.updateSetting('newKey', 'newValue');
        });

        // Verify it was saved
        final result = await mockStorage.load('config.plugin.configurable-test-plugin');
        result.fold(
          (_) => fail('Should have saved successfully'),
          (data) {
            expect(data['settings']['newKey'], 'newValue');
          },
        );
      });

      test('should throw StateError when updating without loading', () {
        expect(
          () => plugin.updateConfiguration((config) => config),
          throwsStateError,
        );
      });
    });

    group('Get/Set Config Settings', () {
      test('should get setting value', () async {
        await plugin.loadConfiguration(mockStorage, pluginId);
        await plugin.setConfigSetting('myKey', 'myValue');

        expect(plugin.getConfigSetting<String>('myKey'), 'myValue');
      });

      test('should return default value if setting not found', () async {
        await plugin.loadConfiguration(mockStorage, pluginId);

        expect(
          plugin.getConfigSetting<String>('nonexistent', defaultValue: 'default'),
          'default',
        );
      });

      test('should set setting value', () async {
        await plugin.loadConfiguration(mockStorage, pluginId);

        await plugin.setConfigSetting('testKey', 'testValue');

        expect(plugin.getConfigSetting<String>('testKey'), 'testValue');
      });

      test('should throw StateError when setting without loading', () {
        expect(
          () => plugin.setConfigSetting('key', 'value'),
          throwsStateError,
        );
      });

      test('should support different value types', () async {
        await plugin.loadConfiguration(mockStorage, pluginId);

        await plugin.setConfigSetting('stringKey', 'text');
        await plugin.setConfigSetting('intKey', 42);
        await plugin.setConfigSetting('boolKey', true);
        await plugin.setConfigSetting('listKey', [1, 2, 3]);

        expect(plugin.getConfigSetting<String>('stringKey'), 'text');
        expect(plugin.getConfigSetting<int>('intKey'), 42);
        expect(plugin.getConfigSetting<bool>('boolKey'), true);
        expect(plugin.getConfigSetting<List>('listKey'), [1, 2, 3]);
      });
    });

    group('Enable/Disable', () {
      test('should start enabled by default', () async {
        await plugin.loadConfiguration(mockStorage, pluginId);

        expect(plugin.isEnabled, true);
      });

      test('should disable plugin', () async {
        await plugin.loadConfiguration(mockStorage, pluginId);

        await plugin.disable();

        expect(plugin.isEnabled, false);
      });

      test('should enable plugin', () async {
        await plugin.loadConfiguration(mockStorage, pluginId);
        await plugin.disable();

        await plugin.enable();

        expect(plugin.isEnabled, true);
      });

      test('should save state after enable/disable', () async {
        await plugin.loadConfiguration(mockStorage, pluginId);
        await plugin.disable();

        // Load from storage to verify
        final result = await mockStorage.load('config.plugin.configurable-test-plugin');
        result.fold(
          (_) => fail('Should have saved'),
          (data) {
            expect(data['enabled'], false);
          },
        );
      });

      test('should throw StateError when enabling without loading', () {
        expect(() => plugin.enable(), throwsStateError);
      });

      test('should throw StateError when disabling without loading', () {
        expect(() => plugin.disable(), throwsStateError);
      });
    });
  });
}
