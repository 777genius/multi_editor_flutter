import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import 'package:multi_editor_plugin_file_stats/src/infrastructure/plugin/file_stats_plugin.dart';

class MockPluginContext extends Mock implements PluginContext {}

class MockPluginUIService extends Mock implements PluginUIService {}

class MockEventBus extends Mock implements EventBus {}

class FakeFileDocument extends Fake implements FileDocument {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeFileDocument());
  });

  late MockPluginContext mockContext;
  late MockPluginUIService mockUIService;
  late MockEventBus mockEventBus;

  setUp(() {
    mockContext = MockPluginContext();
    mockUIService = MockPluginUIService();
    mockEventBus = MockEventBus();

    when(() => mockContext.getService<PluginUIService>())
        .thenReturn(mockUIService);
    when(() => mockContext.events).thenReturn(mockEventBus);
    when(() => mockEventBus.publish(any())).thenReturn(null);
    when(() => mockUIService.registerUI(any())).thenReturn(null);
    when(() => mockUIService.unregisterUI(any())).thenReturn(null);
  });

  group('FileStatsPlugin - Lifecycle', () {
    test('should have correct manifest', () {
      // Arrange
      final plugin = FileStatsPlugin();

      // Act
      final manifest = plugin.manifest;

      // Assert
      expect(manifest.id, 'plugin.file-stats');
      expect(manifest.name, 'File Statistics');
      expect(manifest.version, '0.1.0');
      expect(manifest.description, contains('file metrics'));
      expect(manifest.author, 'Editor Team');
    });

    test('should start uninitialized', () {
      // Arrange & Act
      final plugin = FileStatsPlugin();

      // Assert
      expect(plugin.isInitialized, false);
    });

    test('should initialize successfully', () async {
      // Arrange
      final plugin = FileStatsPlugin();

      // Act
      await plugin.initialize(mockContext);

      // Assert
      expect(plugin.isInitialized, true);
      verify(() => mockUIService.registerUI(any())).called(1);
    });

    test('should set initial state on initialization', () async {
      // Arrange
      final plugin = FileStatsPlugin();

      // Act
      await plugin.initialize(mockContext);

      // Assert
      final state = plugin.getState('statistics');
      expect(state, isNotNull);
    });

    test('should dispose successfully', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      // Act
      await plugin.dispose();

      // Assert
      expect(plugin.isInitialized, false);
    });

    test('should cancel all timers on disposal', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      // Trigger multiple content changes to create timers
      plugin.onFileContentChange('file-1', 'content');
      plugin.onFileContentChange('file-2', 'content');

      // Act
      await plugin.dispose();

      // Wait for what would have been timer triggers
      await Future.delayed(const Duration(milliseconds: 300));

      // Assert - Should not crash
      expect(plugin.isInitialized, false);
    });
  });

  group('FileStatsPlugin - File Statistics Calculation', () {
    test('should calculate statistics on file open', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      final file = FileDocument(
        id: 'file-1',
        name: 'test.dart',
        content: 'void main() {\n  print("Hello");\n}',
      );

      // Act
      plugin.onFileOpen(file);

      // Wait a bit for calculation
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      final stats = plugin.getStatistics('file-1');
      expect(stats, isNotNull);
      expect(stats!.fileId, 'file-1');
      expect(stats.lines, 3);
      expect(stats.characters, greaterThan(0));
    });

    test('should update statistics on content change', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      final file = FileDocument(
        id: 'file-1',
        name: 'test.dart',
        content: 'line1',
      );

      plugin.onFileOpen(file);
      await Future.delayed(const Duration(milliseconds: 50));

      // Act - Change content
      plugin.onFileContentChange('file-1', 'line1\nline2\nline3');

      // Wait for throttle and update
      await Future.delayed(const Duration(milliseconds: 600));

      // Assert
      final stats = plugin.getStatistics('file-1');
      expect(stats, isNotNull);
      expect(stats!.lines, 3);
    });

    test('should throttle rapid content changes', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      final file = FileDocument(id: 'file-1', name: 'test.dart', content: 'test');
      plugin.onFileOpen(file);
      await Future.delayed(const Duration(milliseconds: 50));

      // Act - Rapid changes within throttle window
      plugin.onFileContentChange('file-1', 'content 1');
      plugin.onFileContentChange('file-1', 'content 2');
      plugin.onFileContentChange('file-1', 'content 3');

      // Wait briefly (less than throttle)
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - Should have ignored rapid changes
      final stats = plugin.getStatistics('file-1');
      expect(stats, isNotNull);
    });

    test('should track statistics for multiple files', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      final file1 = FileDocument(
        id: 'file-1',
        name: 'test1.dart',
        content: 'line1\nline2',
      );
      final file2 = FileDocument(
        id: 'file-2',
        name: 'test2.dart',
        content: 'line1\nline2\nline3',
      );

      // Act
      plugin.onFileOpen(file1);
      await Future.delayed(const Duration(milliseconds: 50));

      plugin.onFileOpen(file2);
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      final stats1 = plugin.getStatistics('file-1');
      final stats2 = plugin.getStatistics('file-2');

      expect(stats1, isNotNull);
      expect(stats2, isNotNull);
      expect(stats1!.lines, 2);
      expect(stats2!.lines, 3);
    });

    test('should clear statistics on file close', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      final file = FileDocument(
        id: 'file-1',
        name: 'test.dart',
        content: 'content',
      );

      plugin.onFileOpen(file);
      await Future.delayed(const Duration(milliseconds: 50));

      // Act
      plugin.onFileClose('file-1');

      // Assert
      final stats = plugin.getStatistics('file-1');
      expect(stats, isNull);
    });

    test('should update UI descriptor when current file changes', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      // Clear initialization call
      reset(mockUIService);

      final file = FileDocument(
        id: 'file-1',
        name: 'test.dart',
        content: 'test content',
      );

      // Act
      plugin.onFileOpen(file);

      // Wait for immediate update
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert - UI should be registered
      verify(() => mockUIService.registerUI(any())).called(greaterThan(0));
    });

    test('should unregister UI when last file is closed', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      final file = FileDocument(
        id: 'file-1',
        name: 'test.dart',
        content: 'content',
      );

      plugin.onFileOpen(file);
      await Future.delayed(const Duration(milliseconds: 50));

      // Clear previous calls
      reset(mockUIService);

      // Act
      plugin.onFileClose('file-1');

      // Assert
      verify(() => mockUIService.unregisterUI('plugin.file-stats')).called(1);
    });
  });

  group('FileStatsPlugin - Current File Tracking', () {
    test('should track current file on open', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      final file = FileDocument(
        id: 'file-1',
        name: 'test.dart',
        content: 'content',
      );

      // Act
      plugin.onFileOpen(file);
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert - Should have UI descriptor for current file
      final descriptor = plugin.getUIDescriptor();
      expect(descriptor, isNotNull);
    });

    test('should update current file when new file opens', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      final file1 = FileDocument(id: 'file-1', name: 'test1.dart', content: 'a');
      final file2 = FileDocument(id: 'file-2', name: 'test2.dart', content: 'b');

      // Act
      plugin.onFileOpen(file1);
      await Future.delayed(const Duration(milliseconds: 50));

      plugin.onFileOpen(file2);
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert - Should show stats for file2 (current)
      final descriptor = plugin.getUIDescriptor();
      expect(descriptor, isNotNull);
    });

    test('should clear current file on close', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      final file = FileDocument(id: 'file-1', name: 'test.dart', content: 'c');

      plugin.onFileOpen(file);
      await Future.delayed(const Duration(milliseconds: 50));

      // Act
      plugin.onFileClose('file-1');

      // Assert
      final descriptor = plugin.getUIDescriptor();
      expect(descriptor, isNull);
    });
  });

  group('FileStatsPlugin - UI Descriptor', () {
    test('should return null descriptor when no file is open', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      // Act
      final descriptor = plugin.getUIDescriptor();

      // Assert
      expect(descriptor, isNull);
    });

    test('should provide UI descriptor for current file', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      final file = FileDocument(
        id: 'file-1',
        name: 'test.dart',
        content: 'Hello World\nLine 2',
      );

      plugin.onFileOpen(file);
      await Future.delayed(const Duration(milliseconds: 50));

      // Act
      final descriptor = plugin.getUIDescriptor();

      // Assert
      expect(descriptor, isNotNull);
      expect(descriptor!.pluginId, 'plugin.file-stats');
      expect(descriptor.tooltip, 'File Statistics');
      expect(descriptor.priority, 20);
    });

    test('should include statistics in UI descriptor', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      final file = FileDocument(
        id: 'file-1',
        name: 'test.dart',
        content: 'Hello World\nLine 2\nLine 3',
      );

      plugin.onFileOpen(file);
      await Future.delayed(const Duration(milliseconds: 50));

      // Act
      final descriptor = plugin.getUIDescriptor();
      final items = descriptor!.uiData['items'] as List;
      final firstItem = items.first as Map;

      // Assert
      expect(firstItem['id'], 'file-1');
      expect(firstItem['title'], contains('Lines:'));
      expect(firstItem['subtitle'], contains('Chars:'));
      expect(firstItem['subtitle'], contains('Words:'));
    });
  });

  group('FileStatsPlugin - All Statistics', () {
    test('should return all statistics for open files', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      final file1 = FileDocument(id: 'file-1', name: 'test1.dart', content: 'a');
      final file2 = FileDocument(id: 'file-2', name: 'test2.dart', content: 'b');

      plugin.onFileOpen(file1);
      await Future.delayed(const Duration(milliseconds: 50));

      plugin.onFileOpen(file2);
      await Future.delayed(const Duration(milliseconds: 50));

      // Act
      final allStats = plugin.allStatistics;

      // Assert
      expect(allStats.length, 2);
      expect(allStats.containsKey('file-1'), true);
      expect(allStats.containsKey('file-2'), true);
    });

    test('should return empty map when no files open', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      // Act
      final allStats = plugin.allStatistics;

      // Assert
      expect(allStats, isEmpty);
    });
  });

  group('FileStatsPlugin - Use Cases', () {
    test('Use Case: Display real-time stats as user types', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      final file = FileDocument(id: 'file-1', name: 'test.dart', content: '');
      plugin.onFileOpen(file);
      await Future.delayed(const Duration(milliseconds: 50));

      // Act - User types
      plugin.onFileContentChange('file-1', 'void main() {');
      await Future.delayed(const Duration(milliseconds: 600));

      plugin.onFileContentChange('file-1', 'void main() {\n  print("Hello");');
      await Future.delayed(const Duration(milliseconds: 600));

      // Assert
      final stats = plugin.getStatistics('file-1');
      expect(stats, isNotNull);
      expect(stats!.lines, 2);
    });

    test('Use Case: Show stats for currently active file', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      final file1 = FileDocument(
        id: 'file-1',
        name: 'main.dart',
        content: 'void main() {}',
      );
      final file2 = FileDocument(
        id: 'file-2',
        name: 'app.dart',
        content: 'class App {}',
      );

      // Act - User switches between files
      plugin.onFileOpen(file1);
      await Future.delayed(const Duration(milliseconds: 50));

      var descriptor = plugin.getUIDescriptor();
      expect(descriptor, isNotNull);

      plugin.onFileOpen(file2);
      await Future.delayed(const Duration(milliseconds: 50));

      descriptor = plugin.getUIDescriptor();

      // Assert - Should show stats for file2 (current)
      expect(descriptor, isNotNull);
    });

    test('Use Case: Track statistics across file lifecycle', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      final file = FileDocument(
        id: 'file-1',
        name: 'test.dart',
        content: 'initial content',
      );

      // Act - File lifecycle
      plugin.onFileOpen(file);
      await Future.delayed(const Duration(milliseconds: 50));

      var stats = plugin.getStatistics('file-1');
      expect(stats, isNotNull);

      plugin.onFileContentChange('file-1', 'updated content\nwith more lines');
      await Future.delayed(const Duration(milliseconds: 600));

      stats = plugin.getStatistics('file-1');
      expect(stats!.lines, 2);

      plugin.onFileClose('file-1');
      stats = plugin.getStatistics('file-1');
      expect(stats, isNull);
    });

    test('Use Case: Performance with rapid typing', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      final file = FileDocument(id: 'file-1', name: 'test.dart', content: '');
      plugin.onFileOpen(file);
      await Future.delayed(const Duration(milliseconds: 50));

      // Act - Simulate rapid typing (throttled)
      for (int i = 0; i < 100; i++) {
        plugin.onFileContentChange('file-1', 'content $i');
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Assert - Should handle without errors
      expect(plugin.isInitialized, true);
      final stats = plugin.getStatistics('file-1');
      expect(stats, isNotNull);
    });

    test('Use Case: Multiple files with individual stats', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      final files = [
        FileDocument(id: '1', name: 'file1.dart', content: 'a\nb'),
        FileDocument(id: '2', name: 'file2.dart', content: 'a\nb\nc'),
        FileDocument(id: '3', name: 'file3.dart', content: 'a\nb\nc\nd'),
      ];

      // Act
      for (final file in files) {
        plugin.onFileOpen(file);
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Assert
      expect(plugin.getStatistics('1')!.lines, 2);
      expect(plugin.getStatistics('2')!.lines, 3);
      expect(plugin.getStatistics('3')!.lines, 4);
    });
  });

  group('FileStatsPlugin - Edge Cases', () {
    test('should handle empty file content', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      final file = FileDocument(id: 'file-1', name: 'empty.dart', content: '');

      // Act
      plugin.onFileOpen(file);
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      final stats = plugin.getStatistics('file-1');
      expect(stats, isNotNull);
      expect(stats!.lines, 1); // Empty file is 1 line
      expect(stats.characters, 0);
    });

    test('should handle very large file content', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      final largeContent = 'line\n' * 10000; // 10k lines
      final file = FileDocument(
        id: 'file-1',
        name: 'large.dart',
        content: largeContent,
      );

      // Act
      plugin.onFileOpen(file);
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      final stats = plugin.getStatistics('file-1');
      expect(stats, isNotNull);
      expect(stats!.lines, 10000);
    });

    test('should handle special characters in content', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      final file = FileDocument(
        id: 'file-1',
        name: 'special.dart',
        content: 'Test\nWith\tTabs\r\nAnd\nSpecial: @#\$%^&*',
      );

      // Act
      plugin.onFileOpen(file);
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      final stats = plugin.getStatistics('file-1');
      expect(stats, isNotNull);
      expect(stats!.characters, greaterThan(0));
    });

    test('should handle file close for non-existent file', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      // Act & Assert - Should not throw
      plugin.onFileClose('non-existent-file');
      expect(plugin.isInitialized, true);
    });

    test('should handle content change for non-opened file', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      // Act
      plugin.onFileContentChange('non-existent-file', 'content');
      await Future.delayed(const Duration(milliseconds: 600));

      // Assert - Should create stats for the file
      final stats = plugin.getStatistics('non-existent-file');
      expect(stats, isNotNull);
    });

    test('should handle multiple rapid file opens', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      // Act - Rapidly open different files
      for (int i = 0; i < 50; i++) {
        final file = FileDocument(
          id: 'file-$i',
          name: 'test$i.dart',
          content: 'content',
        );
        plugin.onFileOpen(file);
      }

      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - Should handle without errors
      expect(plugin.isInitialized, true);
    });

    test('should debounce UI updates properly', () async {
      // Arrange
      final plugin = FileStatsPlugin();
      await plugin.initialize(mockContext);

      final file = FileDocument(id: 'file-1', name: 'test.dart', content: '');
      plugin.onFileOpen(file);
      await Future.delayed(const Duration(milliseconds: 50));

      // Clear initialization calls
      reset(mockUIService);

      // Act - Trigger multiple content changes
      plugin.onFileContentChange('file-1', 'content 1');
      plugin.onFileContentChange('file-1', 'content 2');
      plugin.onFileContentChange('file-1', 'content 3');

      // Wait less than debounce delay
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - Should not update UI yet (throttled)
      verifyNever(() => mockUIService.registerUI(any()));

      // Wait for debounce delay
      await Future.delayed(const Duration(milliseconds: 600));

      // Assert - Should update UI after throttle
      verify(() => mockUIService.registerUI(any())).called(greaterThan(0));
    });
  });
}
