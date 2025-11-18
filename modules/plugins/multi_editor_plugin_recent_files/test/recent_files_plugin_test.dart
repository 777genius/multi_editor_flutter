import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import 'package:multi_editor_plugin_recent_files/src/infrastructure/plugin/recent_files_plugin.dart';

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

  group('RecentFilesPlugin - Lifecycle', () {
    test('should have correct manifest', () {
      // Arrange
      final plugin = RecentFilesPlugin();

      // Act
      final manifest = plugin.manifest;

      // Assert
      expect(manifest.id, 'plugin.recent-files');
      expect(manifest.name, 'Recent Files');
      expect(manifest.version, '0.1.0');
      expect(manifest.description, contains('recently opened files'));
      expect(manifest.author, 'Editor Team');
    });

    test('should start uninitialized', () {
      // Arrange & Act
      final plugin = RecentFilesPlugin();

      // Assert
      expect(plugin.isInitialized, false);
    });

    test('should initialize successfully', () async {
      // Arrange
      final plugin = RecentFilesPlugin();

      // Act
      await plugin.initialize(mockContext);

      // Assert
      expect(plugin.isInitialized, true);
      verify(() => mockUIService.registerUI(any())).called(1);
    });

    test('should set initial state on initialization', () async {
      // Arrange
      final plugin = RecentFilesPlugin();

      // Act
      await plugin.initialize(mockContext);

      // Assert
      final state = plugin.getState('recentFiles');
      expect(state, isNotNull);
    });

    test('should dispose successfully', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      // Act
      await plugin.dispose();

      // Assert
      expect(plugin.isInitialized, false);
    });

    test('should cancel timers on disposal', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      // Trigger debouncing by adding a file
      final file = FileDocument(id: 'file-1', name: 'test.dart', content: '');
      plugin.onFileOpen(file);

      // Act
      await plugin.dispose();

      // Wait for what would have been the debounce delay
      await Future.delayed(const Duration(milliseconds: 300));

      // Assert - Should not throw or crash
      expect(plugin.isInitialized, false);
    });
  });

  group('RecentFilesPlugin - File Tracking', () {
    test('should track opened file', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      final file = FileDocument(id: 'file-1', name: 'test.dart', content: '');

      // Act
      plugin.onFileOpen(file);

      // Wait a bit for state update
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(plugin.recentFiles.length, 1);
      expect(plugin.recentFiles.first.fileId, 'file-1');
      expect(plugin.recentFiles.first.fileName, 'test.dart');
    });

    test('should track multiple opened files', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      final file1 = FileDocument(id: 'file-1', name: 'test1.dart', content: '');
      final file2 = FileDocument(id: 'file-2', name: 'test2.dart', content: '');
      final file3 = FileDocument(id: 'file-3', name: 'test3.dart', content: '');

      // Act
      plugin.onFileOpen(file1);
      await Future.delayed(const Duration(milliseconds: 50));

      plugin.onFileOpen(file2);
      await Future.delayed(const Duration(milliseconds: 50));

      plugin.onFileOpen(file3);
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(plugin.recentFiles.length, 3);
      expect(plugin.recentFiles[0].fileId, 'file-3'); // Most recent first
      expect(plugin.recentFiles[1].fileId, 'file-2');
      expect(plugin.recentFiles[2].fileId, 'file-1');
    });

    test('should update timestamp when reopening same file', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      final file = FileDocument(id: 'file-1', name: 'test.dart', content: '');

      // Act
      plugin.onFileOpen(file);
      await Future.delayed(const Duration(milliseconds: 100));

      final firstTimestamp = plugin.recentFiles.first.lastOpened;

      // Wait a bit
      await Future.delayed(const Duration(milliseconds: 100));

      plugin.onFileOpen(file);
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(plugin.recentFiles.length, 1);
      expect(
        plugin.recentFiles.first.lastOpened.isAfter(firstTimestamp),
        true,
      );
    });

    test('should move reopened file to top of list', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      final file1 = FileDocument(id: 'file-1', name: 'test1.dart', content: '');
      final file2 = FileDocument(id: 'file-2', name: 'test2.dart', content: '');
      final file3 = FileDocument(id: 'file-3', name: 'test3.dart', content: '');

      // Act - Open files in order
      plugin.onFileOpen(file1);
      await Future.delayed(const Duration(milliseconds: 50));

      plugin.onFileOpen(file2);
      await Future.delayed(const Duration(milliseconds: 50));

      plugin.onFileOpen(file3);
      await Future.delayed(const Duration(milliseconds: 50));

      // Reopen file-1
      plugin.onFileOpen(file1);
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(plugin.recentFiles.length, 3);
      expect(plugin.recentFiles[0].fileId, 'file-1'); // Should be first now
      expect(plugin.recentFiles[1].fileId, 'file-3');
      expect(plugin.recentFiles[2].fileId, 'file-2');
    });

    test('should remove deleted file from recent list', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      final file1 = FileDocument(id: 'file-1', name: 'test1.dart', content: '');
      final file2 = FileDocument(id: 'file-2', name: 'test2.dart', content: '');

      plugin.onFileOpen(file1);
      await Future.delayed(const Duration(milliseconds: 50));

      plugin.onFileOpen(file2);
      await Future.delayed(const Duration(milliseconds: 50));

      // Act - Delete file-1
      plugin.onFileDelete('file-1');
      await Future.delayed(const Duration(milliseconds: 250)); // Wait for debounce

      // Assert
      expect(plugin.recentFiles.length, 1);
      expect(plugin.recentFiles.first.fileId, 'file-2');
    });

    test('should respect maximum entries limit', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      // Act - Open 15 files (max is 10)
      for (int i = 0; i < 15; i++) {
        final file = FileDocument(id: 'file-$i', name: 'test$i.dart', content: '');
        plugin.onFileOpen(file);
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Assert
      expect(plugin.recentFiles.length, 10); // Should not exceed max
      expect(plugin.recentFiles.first.fileId, 'file-14'); // Most recent
    });
  });

  group('RecentFilesPlugin - State Management', () {
    test('should update state immediately on file open', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      final file = FileDocument(id: 'file-1', name: 'test.dart', content: '');

      // Act
      plugin.onFileOpen(file);

      // Assert - State should be updated immediately (no debouncing on open)
      final state = plugin.getState('recentFiles');
      expect(state, isNotNull);
    });

    test('should debounce state updates on file delete', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      final file = FileDocument(id: 'file-1', name: 'test.dart', content: '');
      plugin.onFileOpen(file);
      await Future.delayed(const Duration(milliseconds: 50));

      // Act - Delete file
      plugin.onFileDelete('file-1');

      // Assert - Should still have file immediately
      expect(plugin.recentFiles.any((f) => f.fileId == 'file-1'), true);

      // Wait for debounce
      await Future.delayed(const Duration(milliseconds: 250));

      // Assert - Should be removed after debounce
      expect(plugin.recentFiles.any((f) => f.fileId == 'file-1'), false);
    });

    test('should update UI descriptor when files change', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      // Reset mock to clear initialization call
      reset(mockUIService);

      final file = FileDocument(id: 'file-1', name: 'test.dart', content: '');

      // Act
      plugin.onFileOpen(file);

      // Wait for immediate state update
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert - UI should be registered again with updated data
      verify(() => mockUIService.registerUI(any())).called(greaterThan(0));
    });
  });

  group('RecentFilesPlugin - UI Descriptor', () {
    test('should provide UI descriptor with recent files', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      final file1 = FileDocument(id: 'file-1', name: 'test1.dart', content: '');
      final file2 = FileDocument(id: 'file-2', name: 'test2.dart', content: '');

      plugin.onFileOpen(file1);
      await Future.delayed(const Duration(milliseconds: 50));

      plugin.onFileOpen(file2);
      await Future.delayed(const Duration(milliseconds: 50));

      // Act
      final descriptor = plugin.getUIDescriptor();

      // Assert
      expect(descriptor, isNotNull);
      expect(descriptor!.pluginId, 'plugin.recent-files');
      expect(descriptor.tooltip, 'Recent Files');
      expect(descriptor.priority, 10);
      expect(descriptor.uiData['type'], 'list');
      expect(descriptor.uiData['items'], isA<List>());
      expect((descriptor.uiData['items'] as List).length, 2);
    });

    test('should include file metadata in UI descriptor', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      final file = FileDocument(id: 'file-1', name: 'test.dart', content: '');
      plugin.onFileOpen(file);
      await Future.delayed(const Duration(milliseconds: 50));

      // Act
      final descriptor = plugin.getUIDescriptor();
      final items = descriptor!.uiData['items'] as List;
      final firstItem = items.first as Map;

      // Assert
      expect(firstItem['id'], 'file-1');
      expect(firstItem['title'], 'test.dart');
      expect(firstItem['subtitle'], isNotNull); // Contains formatted time
      expect(firstItem['onTap'], 'openFile');
    });

    test('should show files sorted by recency in UI descriptor', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      final file1 = FileDocument(id: 'file-1', name: 'old.dart', content: '');
      final file2 = FileDocument(id: 'file-2', name: 'new.dart', content: '');

      plugin.onFileOpen(file1);
      await Future.delayed(const Duration(milliseconds: 50));

      plugin.onFileOpen(file2);
      await Future.delayed(const Duration(milliseconds: 50));

      // Act
      final descriptor = plugin.getUIDescriptor();
      final items = descriptor!.uiData['items'] as List;

      // Assert
      expect((items[0] as Map)['title'], 'new.dart'); // Most recent first
      expect((items[1] as Map)['title'], 'old.dart');
    });
  });

  group('RecentFilesPlugin - Clear Recent Files', () {
    test('should clear all recent files', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      final file1 = FileDocument(id: 'file-1', name: 'test1.dart', content: '');
      final file2 = FileDocument(id: 'file-2', name: 'test2.dart', content: '');

      plugin.onFileOpen(file1);
      await Future.delayed(const Duration(milliseconds: 50));

      plugin.onFileOpen(file2);
      await Future.delayed(const Duration(milliseconds: 50));

      // Act
      plugin.clearRecentFiles();

      // Assert
      expect(plugin.recentFiles, isEmpty);
    });

    test('should update state after clearing', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      final file = FileDocument(id: 'file-1', name: 'test.dart', content: '');
      plugin.onFileOpen(file);
      await Future.delayed(const Duration(milliseconds: 50));

      // Act
      plugin.clearRecentFiles();

      // Assert
      final state = plugin.getState('recentFiles');
      expect(state, isNotNull);
    });
  });

  group('RecentFilesPlugin - Use Cases', () {
    test('Use Case: Track files as user navigates project', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      // Act - Simulate user opening multiple files
      final files = [
        FileDocument(id: '1', name: 'main.dart', content: ''),
        FileDocument(id: '2', name: 'app.dart', content: ''),
        FileDocument(id: '3', name: 'config.yaml', content: ''),
      ];

      for (final file in files) {
        plugin.onFileOpen(file);
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Assert
      expect(plugin.recentFiles.length, 3);
      expect(plugin.recentFiles[0].fileName, 'config.yaml');
      expect(plugin.recentFiles[1].fileName, 'app.dart');
      expect(plugin.recentFiles[2].fileName, 'main.dart');
    });

    test('Use Case: User returns to previously opened file', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      final mainFile = FileDocument(id: '1', name: 'main.dart', content: '');
      final testFile = FileDocument(id: '2', name: 'test.dart', content: '');

      // Act - User opens files
      plugin.onFileOpen(mainFile);
      await Future.delayed(const Duration(milliseconds: 50));

      plugin.onFileOpen(testFile);
      await Future.delayed(const Duration(milliseconds: 50));

      // User returns to main.dart
      plugin.onFileOpen(mainFile);
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert - main.dart should be at top
      expect(plugin.recentFiles[0].fileId, '1');
      expect(plugin.recentFiles.length, 2);
    });

    test('Use Case: Clean up deleted files from recent list', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      final files = List.generate(
        5,
        (i) => FileDocument(id: 'file-$i', name: 'test$i.dart', content: ''),
      );

      for (final file in files) {
        plugin.onFileOpen(file);
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Act - Delete some files
      plugin.onFileDelete('file-1');
      plugin.onFileDelete('file-3');
      await Future.delayed(const Duration(milliseconds: 250));

      // Assert
      expect(plugin.recentFiles.length, 3);
      expect(plugin.recentFiles.any((f) => f.fileId == 'file-1'), false);
      expect(plugin.recentFiles.any((f) => f.fileId == 'file-3'), false);
    });

    test('Use Case: Display recent files in sidebar', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      final files = [
        FileDocument(id: '1', name: 'feature.dart', content: ''),
        FileDocument(id: '2', name: 'service.dart', content: ''),
        FileDocument(id: '3', name: 'model.dart', content: ''),
      ];

      for (final file in files) {
        plugin.onFileOpen(file);
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Act
      final descriptor = plugin.getUIDescriptor();
      final items = descriptor!.uiData['items'] as List;

      // Assert - Should have UI data for sidebar
      expect(items.length, 3);
      expect(items.every((item) => (item as Map).containsKey('title')), true);
      expect(items.every((item) => (item as Map).containsKey('subtitle')), true);
      expect(items.every((item) => (item as Map).containsKey('onTap')), true);
    });

    test('Use Case: Clear recent files on new project', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      // Open files in old project
      for (int i = 0; i < 5; i++) {
        final file = FileDocument(id: 'old-$i', name: 'old$i.dart', content: '');
        plugin.onFileOpen(file);
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Act - User switches to new project
      plugin.clearRecentFiles();

      // Assert
      expect(plugin.recentFiles, isEmpty);
    });
  });

  group('RecentFilesPlugin - Edge Cases', () {
    test('should handle file with empty name', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      final file = FileDocument(id: 'file-1', name: '', content: '');

      // Act
      plugin.onFileOpen(file);
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(plugin.recentFiles.length, 1);
      expect(plugin.recentFiles.first.fileName, '');
    });

    test('should handle file with very long name', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      final longName = 'test' * 100 + '.dart';
      final file = FileDocument(id: 'file-1', name: longName, content: '');

      // Act
      plugin.onFileOpen(file);
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(plugin.recentFiles.length, 1);
      expect(plugin.recentFiles.first.fileName, longName);
    });

    test('should handle special characters in file name', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      final file = FileDocument(
        id: 'file-1',
        name: 'test@#\$%^&*.dart',
        content: '',
      );

      // Act
      plugin.onFileOpen(file);
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(plugin.recentFiles.length, 1);
      expect(plugin.recentFiles.first.fileName, 'test@#\$%^&*.dart');
    });

    test('should handle rapid file opening', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      // Act - Rapidly open files
      for (int i = 0; i < 50; i++) {
        final file = FileDocument(id: 'file-$i', name: 'test$i.dart', content: '');
        plugin.onFileOpen(file);
      }

      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - Should handle without errors and respect max limit
      expect(plugin.recentFiles.length, lessThanOrEqualTo(10));
    });

    test('should handle deleting non-existent file', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      final file = FileDocument(id: 'file-1', name: 'test.dart', content: '');
      plugin.onFileOpen(file);
      await Future.delayed(const Duration(milliseconds: 50));

      // Act - Delete non-existent file
      plugin.onFileDelete('non-existent-file');
      await Future.delayed(const Duration(milliseconds: 250));

      // Assert - Should not affect existing files
      expect(plugin.recentFiles.length, 1);
      expect(plugin.recentFiles.first.fileId, 'file-1');
    });

    test('should handle multiple rapid deletions', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      for (int i = 0; i < 5; i++) {
        final file = FileDocument(id: 'file-$i', name: 'test$i.dart', content: '');
        plugin.onFileOpen(file);
        await Future.delayed(const Duration(milliseconds: 20));
      }

      // Act - Rapidly delete files
      for (int i = 0; i < 5; i++) {
        plugin.onFileDelete('file-$i');
      }

      await Future.delayed(const Duration(milliseconds: 250));

      // Assert
      expect(plugin.recentFiles, isEmpty);
    });
  });

  group('RecentFilesPlugin - Debouncing', () {
    test('should not update state if disposed during debounce', () async {
      // Arrange
      final plugin = RecentFilesPlugin();
      await plugin.initialize(mockContext);

      final file = FileDocument(id: 'file-1', name: 'test.dart', content: '');
      plugin.onFileOpen(file);
      await Future.delayed(const Duration(milliseconds: 50));

      // Act - Trigger debounced update then dispose
      plugin.onFileDelete('file-1');
      await plugin.dispose();

      // Wait for what would have been debounce period
      await Future.delayed(const Duration(milliseconds: 250));

      // Assert - Should not crash
      expect(plugin.isInitialized, false);
    });
  });
}
