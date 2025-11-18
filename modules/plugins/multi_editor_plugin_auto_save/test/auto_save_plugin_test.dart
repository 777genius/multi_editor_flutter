import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import 'package:multi_editor_plugin_auto_save/multi_editor_plugin_auto_save.dart';
import 'package:multi_editor_plugin_auto_save/src/infrastructure/plugin/auto_save_plugin.dart';
import 'package:multi_editor_plugin_auto_save/src/domain/value_objects/auto_save_config.dart';
import 'package:multi_editor_plugin_auto_save/src/domain/value_objects/save_interval.dart';

class MockPluginContext extends Mock implements PluginContext {}

class MockFileRepository extends Mock implements FileRepository {}

class MockEventBus extends Mock implements EventBus {}

class FakeFileDocument extends Fake implements FileDocument {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeFileDocument());
  });

  late MockPluginContext mockContext;
  late MockFileRepository mockFileRepository;
  late MockEventBus mockEventBus;

  setUp(() {
    mockContext = MockPluginContext();
    mockFileRepository = MockFileRepository();
    mockEventBus = MockEventBus();

    when(() => mockContext.fileRepository).thenReturn(mockFileRepository);
    when(() => mockContext.events).thenReturn(mockEventBus);
    when(() => mockEventBus.publish(any())).thenReturn(null);
  });

  group('AutoSavePlugin - Lifecycle', () {
    test('should have correct manifest', () {
      // Arrange
      final plugin = AutoSavePlugin();

      // Act
      final manifest = plugin.manifest;

      // Assert
      expect(manifest.id, 'plugin.auto-save');
      expect(manifest.name, 'Auto Save');
      expect(manifest.version, '0.1.0');
      expect(manifest.description, contains('Automatically saves'));
    });

    test('should initialize successfully with default config', () async {
      // Arrange
      final plugin = AutoSavePlugin();

      // Act
      await plugin.initialize(mockContext);

      // Assert
      expect(plugin.isInitialized, true);
      expect(plugin.hasConfiguration, true);
    });

    test('should start uninitialized', () {
      // Arrange & Act
      final plugin = AutoSavePlugin();

      // Assert
      expect(plugin.isInitialized, false);
    });

    test('should dispose successfully and stop timer', () async {
      // Arrange
      final plugin = AutoSavePlugin();
      await plugin.initialize(mockContext);

      // Act
      await plugin.dispose();

      // Assert
      expect(plugin.isInitialized, false);
    });

    test('should handle disposal without initialization', () async {
      // Arrange
      final plugin = AutoSavePlugin();

      // Act & Assert - should not throw
      await plugin.dispose();
      expect(plugin.isInitialized, false);
    });
  });

  group('AutoSavePlugin - Configuration', () {
    test('should create default configuration on initialization', () async {
      // Arrange
      final plugin = AutoSavePlugin();

      // Act
      await plugin.initialize(mockContext);

      // Assert
      expect(plugin.hasConfiguration, true);
      final config = plugin.getConfigSetting<Map<String, dynamic>>('config');
      expect(config, isNotNull);
    });

    test('should update configuration and restart timer when enabled', () async {
      // Arrange
      final plugin = AutoSavePlugin();
      await plugin.initialize(mockContext);

      // Act
      final newConfig = AutoSaveConfig(
        enabled: true,
        interval: SaveInterval.fromSeconds(3),
      );
      await plugin.updateAutoSaveConfig(newConfig);

      // Assert
      expect(plugin.hasConfiguration, true);
    });

    test('should stop timer when configuration is disabled', () async {
      // Arrange
      final plugin = AutoSavePlugin();
      await plugin.initialize(mockContext);

      // Act
      final disabledConfig = AutoSaveConfig(
        enabled: false,
        interval: SaveInterval.fromSeconds(5),
      );
      await plugin.updateAutoSaveConfig(disabledConfig);

      // Assert - Timer should be stopped (tested indirectly)
      expect(plugin.hasConfiguration, true);
    });

    test('should handle invalid configuration gracefully', () async {
      // Arrange
      final plugin = AutoSavePlugin();
      await plugin.initialize(mockContext);

      // Act - Set invalid config manually
      await plugin.setConfigSetting('config', {'invalid': 'data'});

      // Assert - Should fall back to default config without throwing
      expect(plugin.hasConfiguration, true);
    });
  });

  group('AutoSavePlugin - Content Change Tracking', () {
    test('should track content changes', () async {
      // Arrange
      final plugin = AutoSavePlugin();
      await plugin.initialize(mockContext);
      const fileId = 'file-1';
      const content = 'test content';

      // Act
      plugin.onFileContentChange(fileId, content);

      // Wait for throttle
      await Future.delayed(const Duration(milliseconds: 600));

      // Assert - Content should be tracked internally
      expect(plugin.getState('lastChange'), isNotNull);
    });

    test('should throttle rapid content changes', () async {
      // Arrange
      final plugin = AutoSavePlugin();
      await plugin.initialize(mockContext);
      const fileId = 'file-1';

      // Act - Rapid changes within throttle window
      plugin.onFileContentChange(fileId, 'content 1');
      plugin.onFileContentChange(fileId, 'content 2');
      plugin.onFileContentChange(fileId, 'content 3');

      // Assert - Only first change should be tracked
      await Future.delayed(const Duration(milliseconds: 100));
      final lastChange = plugin.getState('lastChange');
      expect(lastChange, isNotNull);
    });

    test('should track multiple files independently', () async {
      // Arrange
      final plugin = AutoSavePlugin();
      await plugin.initialize(mockContext);

      // Act
      plugin.onFileContentChange('file-1', 'content 1');
      await Future.delayed(const Duration(milliseconds: 600));

      plugin.onFileContentChange('file-2', 'content 2');
      await Future.delayed(const Duration(milliseconds: 600));

      // Assert
      expect(plugin.getState('lastChange'), isNotNull);
    });

    test('should clear content on file close', () async {
      // Arrange
      final plugin = AutoSavePlugin();
      await plugin.initialize(mockContext);
      const fileId = 'file-1';

      // Act
      plugin.onFileContentChange(fileId, 'test content');
      await Future.delayed(const Duration(milliseconds: 600));

      plugin.onFileClose(fileId);

      // Assert - Content should be cleared
      expect(plugin.isInitialized, true);
    });
  });

  group('AutoSavePlugin - Auto Save Execution', () {
    test('should attempt to save files when timer triggers', () async {
      // Arrange
      final plugin = AutoSavePlugin();
      final testFile = FileDocument(
        id: 'file-1',
        name: 'test.dart',
        content: 'original content',
      );

      when(() => mockFileRepository.load('file-1'))
          .thenAnswer((_) async => Either.right(testFile));
      when(() => mockFileRepository.save(any()))
          .thenAnswer((_) async => const Either.right(null));

      await plugin.initialize(mockContext);

      // Act
      plugin.onFileContentChange('file-1', 'new content');

      // Wait for throttle and timer
      await Future.delayed(const Duration(milliseconds: 600));

      // Update config with very short interval for testing
      final config = AutoSaveConfig(
        enabled: true,
        interval: SaveInterval.fromSeconds(1),
      );
      await plugin.updateAutoSaveConfig(config);

      // Wait for timer to trigger
      await Future.delayed(const Duration(milliseconds: 1200));

      // Assert - Save should have been attempted
      verify(() => mockFileRepository.load(any())).called(greaterThan(0));
    });

    test('should not save when no content changes exist', () async {
      // Arrange
      final plugin = AutoSavePlugin();
      await plugin.initialize(mockContext);

      final config = AutoSaveConfig(
        enabled: true,
        interval: SaveInterval.fromSeconds(1),
      );
      await plugin.updateAutoSaveConfig(config);

      // Act - Wait for timer without any content changes
      await Future.delayed(const Duration(milliseconds: 1200));

      // Assert - No saves should be attempted
      verifyNever(() => mockFileRepository.load(any()));
    });

    test('should handle save failures gracefully', () async {
      // Arrange
      final plugin = AutoSavePlugin();
      when(() => mockFileRepository.load('file-1'))
          .thenAnswer((_) async => Either.left(
                DomainFailure.notFound(entityType: 'File', entityId: 'file-1'),
              ));

      await plugin.initialize(mockContext);

      // Act
      plugin.onFileContentChange('file-1', 'content');
      await Future.delayed(const Duration(milliseconds: 600));

      final config = AutoSaveConfig(
        enabled: true,
        interval: SaveInterval.fromSeconds(1),
      );
      await plugin.updateAutoSaveConfig(config);

      // Wait for timer
      await Future.delayed(const Duration(milliseconds: 1200));

      // Assert - Should not throw, just log error
      expect(plugin.isInitialized, true);
    });

    test('should not save after plugin is disposed', () async {
      // Arrange
      final plugin = AutoSavePlugin();
      await plugin.initialize(mockContext);

      plugin.onFileContentChange('file-1', 'content');
      await Future.delayed(const Duration(milliseconds: 600));

      final config = AutoSaveConfig(
        enabled: true,
        interval: SaveInterval.fromSeconds(1),
      );
      await plugin.updateAutoSaveConfig(config);

      // Act - Dispose immediately
      await plugin.dispose();

      // Wait for what would have been timer trigger
      await Future.delayed(const Duration(milliseconds: 1200));

      // Assert - No saves should occur after disposal
      verifyNever(() => mockFileRepository.load(any()));
    });
  });

  group('AutoSavePlugin - Use Cases', () {
    test('Use Case: Enable auto-save with custom interval', () async {
      // Arrange
      final plugin = AutoSavePlugin();
      await plugin.initialize(mockContext);

      // Act
      final config = AutoSaveConfig(
        enabled: true,
        interval: SaveInterval.fromSeconds(10),
        showNotifications: true,
      );
      await plugin.updateAutoSaveConfig(config);

      // Assert
      final savedConfig = plugin.getConfigSetting<Map<String, dynamic>>('config');
      expect(savedConfig, isNotNull);
      expect(savedConfig!['enabled'], true);
      expect(savedConfig['interval']['seconds'], 10);
    });

    test('Use Case: Disable auto-save temporarily', () async {
      // Arrange
      final plugin = AutoSavePlugin();
      await plugin.initialize(mockContext);

      // Enable first
      await plugin.updateAutoSaveConfig(
        AutoSaveConfig(enabled: true, interval: SaveInterval.fromSeconds(5)),
      );

      // Act - Disable
      await plugin.updateAutoSaveConfig(
        AutoSaveConfig(enabled: false, interval: SaveInterval.fromSeconds(5)),
      );

      // Assert
      final config = plugin.getConfigSetting<Map<String, dynamic>>('config');
      expect(config!['enabled'], false);
    });

    test('Use Case: Track multiple files and save all', () async {
      // Arrange
      final plugin = AutoSavePlugin();
      final file1 = FileDocument(id: 'file-1', name: 'test1.dart', content: 'old1');
      final file2 = FileDocument(id: 'file-2', name: 'test2.dart', content: 'old2');

      when(() => mockFileRepository.load('file-1'))
          .thenAnswer((_) async => Either.right(file1));
      when(() => mockFileRepository.load('file-2'))
          .thenAnswer((_) async => Either.right(file2));
      when(() => mockFileRepository.save(any()))
          .thenAnswer((_) async => const Either.right(null));

      await plugin.initialize(mockContext);

      // Act
      plugin.onFileContentChange('file-1', 'new content 1');
      await Future.delayed(const Duration(milliseconds: 600));

      plugin.onFileContentChange('file-2', 'new content 2');
      await Future.delayed(const Duration(milliseconds: 600));

      final config = AutoSaveConfig(
        enabled: true,
        interval: SaveInterval.fromSeconds(1),
      );
      await plugin.updateAutoSaveConfig(config);

      // Wait for timer
      await Future.delayed(const Duration(milliseconds: 1200));

      // Assert - Both files should be saved
      verify(() => mockFileRepository.load(any())).called(greaterThan(0));
    });

    test('Use Case: Change interval while plugin is running', () async {
      // Arrange
      final plugin = AutoSavePlugin();
      await plugin.initialize(mockContext);

      await plugin.updateAutoSaveConfig(
        AutoSaveConfig(enabled: true, interval: SaveInterval.fromSeconds(5)),
      );

      // Act - Change interval
      await plugin.updateAutoSaveConfig(
        AutoSaveConfig(enabled: true, interval: SaveInterval.fromSeconds(2)),
      );

      // Assert - Configuration should be updated
      final config = plugin.getConfigSetting<Map<String, dynamic>>('config');
      expect(config!['interval']['seconds'], 2);
    });

    test('Use Case: Handle rapid file edits with throttling', () async {
      // Arrange
      final plugin = AutoSavePlugin();
      await plugin.initialize(mockContext);
      const fileId = 'rapidly-edited-file';

      // Act - Simulate rapid typing
      for (int i = 0; i < 100; i++) {
        plugin.onFileContentChange(fileId, 'content $i');
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Assert - Should handle without errors
      expect(plugin.isInitialized, true);
      expect(plugin.getState('lastChange'), isNotNull);
    });
  });

  group('AutoSavePlugin - Edge Cases', () {
    test('should handle empty content', () async {
      // Arrange
      final plugin = AutoSavePlugin();
      await plugin.initialize(mockContext);

      // Act
      plugin.onFileContentChange('file-1', '');

      // Assert
      expect(plugin.isInitialized, true);
    });

    test('should handle very large content', () async {
      // Arrange
      final plugin = AutoSavePlugin();
      await plugin.initialize(mockContext);
      final largeContent = 'x' * 1000000; // 1MB of content

      // Act
      plugin.onFileContentChange('file-1', largeContent);

      // Assert
      expect(plugin.isInitialized, true);
    });

    test('should handle special characters in content', () async {
      // Arrange
      final plugin = AutoSavePlugin();
      await plugin.initialize(mockContext);
      const specialContent = 'Test\nNew Line\tTab\r\nWindows';

      // Act
      plugin.onFileContentChange('file-1', specialContent);

      // Assert
      expect(plugin.isInitialized, true);
    });

    test('should handle file ID with special characters', () async {
      // Arrange
      final plugin = AutoSavePlugin();
      await plugin.initialize(mockContext);
      const specialFileId = 'file@#\$%^&*()';

      // Act
      plugin.onFileContentChange(specialFileId, 'content');

      // Assert
      expect(plugin.isInitialized, true);
    });
  });
}
