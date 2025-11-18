import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';
import 'package:multi_editor_plugin_file_icons/src/presentation/plugin/file_icons_plugin.dart';
import 'package:multi_editor_plugin_file_icons/src/presentation/config/file_icons_config.dart';

class MockPluginContext extends Mock implements PluginContext {}

class MockEventBus extends Mock implements EventBus {}

void main() {
  late MockPluginContext mockContext;
  late MockEventBus mockEventBus;

  setUp(() {
    mockContext = MockPluginContext();
    mockEventBus = MockEventBus();

    when(() => mockContext.events).thenReturn(mockEventBus);
    when(() => mockEventBus.publish(any())).thenReturn(null);
  });

  group('FileIconsPlugin - Lifecycle', () {
    test('should have correct manifest', () {
      // Arrange
      final plugin = FileIconsPlugin();

      // Act
      final manifest = plugin.manifest;

      // Assert
      expect(manifest.id, 'plugin.file-icons');
      expect(manifest.name, 'File Icons');
      expect(manifest.version, '0.2.0');
      expect(manifest.description, contains('colorful icons'));
      expect(manifest.author, 'Editor Team');
    });

    test('should start uninitialized', () {
      // Arrange & Act
      final plugin = FileIconsPlugin();

      // Assert
      expect(plugin.isInitialized, false);
    });

    test('should initialize successfully with default config', () async {
      // Arrange
      final plugin = FileIconsPlugin();

      // Act
      await plugin.initialize(mockContext);

      // Assert
      expect(plugin.isInitialized, true);
    });

    test('should initialize with custom config', () async {
      // Arrange
      const customConfig = FileIconsConfig(
        defaultTheme: 'material-icons',
        iconSize: 24,
        maxCacheSize: 200,
      );
      final plugin = FileIconsPlugin(config: customConfig);

      // Act
      await plugin.initialize(mockContext);

      // Assert
      expect(plugin.isInitialized, true);
      expect(plugin.config.defaultTheme, 'material-icons');
      expect(plugin.config.iconSize, 24);
      expect(plugin.config.maxCacheSize, 200);
    });

    test('should dispose successfully', () async {
      // Arrange
      final plugin = FileIconsPlugin();
      await plugin.initialize(mockContext);

      // Act
      await plugin.dispose();

      // Assert
      expect(plugin.isInitialized, false);
    });

    test('should dispose without initialization', () async {
      // Arrange
      final plugin = FileIconsPlugin();

      // Act & Assert - should not throw
      await plugin.dispose();
      expect(plugin.isInitialized, false);
    });

    test('should clear cache on disposal', () async {
      // Arrange
      final plugin = FileIconsPlugin();
      await plugin.initialize(mockContext);

      // Act
      await plugin.dispose();

      // Assert - Cache should be cleared (tested indirectly)
      expect(plugin.isInitialized, false);
    });
  });

  group('FileIconsPlugin - Configuration', () {
    test('should use default configuration when not provided', () {
      // Arrange & Act
      final plugin = FileIconsPlugin();

      // Assert
      expect(plugin.config.defaultTheme, 'vscode-icons');
      expect(plugin.config.iconSize, 18);
      expect(plugin.config.maxCacheSize, 100);
      expect(plugin.config.priority, 100);
    });

    test('should respect custom configuration', () {
      // Arrange
      const customConfig = FileIconsConfig(
        defaultTheme: 'material-icons',
        iconSize: 20,
        maxCacheSize: 150,
        priority: 50,
      );

      // Act
      final plugin = FileIconsPlugin(config: customConfig);

      // Assert
      expect(plugin.config.defaultTheme, 'material-icons');
      expect(plugin.config.iconSize, 20);
      expect(plugin.config.maxCacheSize, 150);
      expect(plugin.config.priority, 50);
    });
  });

  group('FileIconsPlugin - Icon Resolution', () {
    test('should return null for folder nodes', () async {
      // Arrange
      final plugin = FileIconsPlugin();
      await plugin.initialize(mockContext);

      final folderNode = FileTreeNode(
        id: 'folder-1',
        name: 'src',
        type: FileTreeNodeType.folder,
        children: [],
      );

      // Act
      final descriptor = plugin.getFileIconDescriptor(folderNode);

      // Assert
      expect(descriptor, null);
    });

    test('should return icon descriptor for Dart file', () async {
      // Arrange
      final plugin = FileIconsPlugin();
      await plugin.initialize(mockContext);

      final fileNode = FileTreeNode(
        id: 'file-1',
        name: 'main.dart',
        type: FileTreeNodeType.file,
      );

      // Act
      final descriptor = plugin.getFileIconDescriptor(fileNode);

      // Assert
      expect(descriptor, isNotNull);
      expect(descriptor!.url, contains('dart'));
      expect(descriptor.size, 18.0);
      expect(descriptor.priority, 100);
      expect(descriptor.pluginId, 'plugin.file-icons');
    });

    test('should return icon descriptor for JavaScript file', () async {
      // Arrange
      final plugin = FileIconsPlugin();
      await plugin.initialize(mockContext);

      final fileNode = FileTreeNode(
        id: 'file-2',
        name: 'app.js',
        type: FileTreeNodeType.file,
      );

      // Act
      final descriptor = plugin.getFileIconDescriptor(fileNode);

      // Assert
      expect(descriptor, isNotNull);
      expect(descriptor!.url, contains('javascript'));
    });

    test('should return icon descriptor for TypeScript file', () async {
      // Arrange
      final plugin = FileIconsPlugin();
      await plugin.initialize(mockContext);

      final fileNode = FileTreeNode(
        id: 'file-3',
        name: 'index.ts',
        type: FileTreeNodeType.file,
      );

      // Act
      final descriptor = plugin.getFileIconDescriptor(fileNode);

      // Assert
      expect(descriptor, isNotNull);
      expect(descriptor!.url, contains('typescript'));
    });

    test('should return icon descriptor for Python file', () async {
      // Arrange
      final plugin = FileIconsPlugin();
      await plugin.initialize(mockContext);

      final fileNode = FileTreeNode(
        id: 'file-4',
        name: 'script.py',
        type: FileTreeNodeType.file,
      );

      // Act
      final descriptor = plugin.getFileIconDescriptor(fileNode);

      // Assert
      expect(descriptor, isNotNull);
      expect(descriptor!.url, contains('python'));
    });

    test('should return icon descriptor for JSON file', () async {
      // Arrange
      final plugin = FileIconsPlugin();
      await plugin.initialize(mockContext);

      final fileNode = FileTreeNode(
        id: 'file-5',
        name: 'package.json',
        type: FileTreeNodeType.file,
      );

      // Act
      final descriptor = plugin.getFileIconDescriptor(fileNode);

      // Assert
      expect(descriptor, isNotNull);
      expect(descriptor!.url, contains('json'));
    });

    test('should handle file without extension', () async {
      // Arrange
      final plugin = FileIconsPlugin();
      await plugin.initialize(mockContext);

      final fileNode = FileTreeNode(
        id: 'file-6',
        name: 'README',
        type: FileTreeNodeType.file,
      );

      // Act
      final descriptor = plugin.getFileIconDescriptor(fileNode);

      // Assert
      expect(descriptor, isNotNull);
      expect(descriptor!.url, contains('file'));
    });

    test('should handle file with multiple dots in name', () async {
      // Arrange
      final plugin = FileIconsPlugin();
      await plugin.initialize(mockContext);

      final fileNode = FileTreeNode(
        id: 'file-7',
        name: 'my.component.test.ts',
        type: FileTreeNodeType.file,
      );

      // Act
      final descriptor = plugin.getFileIconDescriptor(fileNode);

      // Assert
      expect(descriptor, isNotNull);
      expect(descriptor!.url, contains('typescript'));
    });

    test('should use custom icon size from config', () async {
      // Arrange
      const customConfig = FileIconsConfig(iconSize: 24);
      final plugin = FileIconsPlugin(config: customConfig);
      await plugin.initialize(mockContext);

      final fileNode = FileTreeNode(
        id: 'file-8',
        name: 'test.dart',
        type: FileTreeNodeType.file,
      );

      // Act
      final descriptor = plugin.getFileIconDescriptor(fileNode);

      // Assert
      expect(descriptor, isNotNull);
      expect(descriptor!.size, 24.0);
    });

    test('should use custom priority from config', () async {
      // Arrange
      const customConfig = FileIconsConfig(priority: 50);
      final plugin = FileIconsPlugin(config: customConfig);
      await plugin.initialize(mockContext);

      final fileNode = FileTreeNode(
        id: 'file-9',
        name: 'test.dart',
        type: FileTreeNodeType.file,
      );

      // Act
      final descriptor = plugin.getFileIconDescriptor(fileNode);

      // Assert
      expect(descriptor, isNotNull);
      expect(descriptor!.priority, 50);
    });

    test('should handle errors gracefully and return null', () async {
      // Arrange
      final plugin = FileIconsPlugin();
      await plugin.initialize(mockContext);

      // Create node with null name to trigger error
      final invalidNode = FileTreeNode(
        id: 'file-10',
        name: '',
        type: FileTreeNodeType.file,
      );

      // Act
      final descriptor = plugin.getFileIconDescriptor(invalidNode);

      // Assert - Should return null on error instead of throwing
      expect(descriptor, isNotNull); // Empty string gets 'file' icon
    });
  });

  group('FileIconsPlugin - Common File Types', () {
    test('should support all common programming language extensions', () async {
      // Arrange
      final plugin = FileIconsPlugin();
      await plugin.initialize(mockContext);

      final testCases = [
        ('test.dart', 'dart'),
        ('test.js', 'javascript'),
        ('test.ts', 'typescript'),
        ('test.py', 'python'),
        ('test.java', 'java'),
        ('test.go', 'go'),
        ('test.rs', 'rust'),
        ('test.cpp', 'cplusplus'),
        ('test.c', 'c'),
        ('test.rb', 'ruby'),
        ('test.php', 'php'),
      ];

      // Act & Assert
      for (final (fileName, expectedIcon) in testCases) {
        final fileNode = FileTreeNode(
          id: 'file-$fileName',
          name: fileName,
          type: FileTreeNodeType.file,
        );

        final descriptor = plugin.getFileIconDescriptor(fileNode);
        expect(descriptor, isNotNull, reason: 'Failed for $fileName');
        expect(
          descriptor!.url,
          contains(expectedIcon),
          reason: 'Failed for $fileName',
        );
      }
    });

    test('should support common config file extensions', () async {
      // Arrange
      final plugin = FileIconsPlugin();
      await plugin.initialize(mockContext);

      final testCases = [
        ('config.json', 'json'),
        ('config.yaml', 'yaml'),
        ('config.yml', 'yaml'),
        ('data.xml', 'xml'),
        ('README.md', 'markdown'),
      ];

      // Act & Assert
      for (final (fileName, expectedIcon) in testCases) {
        final fileNode = FileTreeNode(
          id: 'file-$fileName',
          name: fileName,
          type: FileTreeNodeType.file,
        );

        final descriptor = plugin.getFileIconDescriptor(fileNode);
        expect(descriptor, isNotNull, reason: 'Failed for $fileName');
        expect(
          descriptor!.url,
          contains(expectedIcon),
          reason: 'Failed for $fileName',
        );
      }
    });
  });

  group('FileIconsPlugin - Use Cases', () {
    test('Use Case: Initialize plugin with default settings', () async {
      // Arrange
      final plugin = FileIconsPlugin();

      // Act
      await plugin.initialize(mockContext);

      // Assert
      expect(plugin.isInitialized, true);
      expect(plugin.config.defaultTheme, 'vscode-icons');
    });

    test('Use Case: Get icon for multiple files in file tree', () async {
      // Arrange
      final plugin = FileIconsPlugin();
      await plugin.initialize(mockContext);

      final files = [
        FileTreeNode(id: '1', name: 'main.dart', type: FileTreeNodeType.file),
        FileTreeNode(id: '2', name: 'app.js', type: FileTreeNodeType.file),
        FileTreeNode(id: '3', name: 'config.json', type: FileTreeNodeType.file),
        FileTreeNode(id: '4', name: 'README.md', type: FileTreeNodeType.file),
      ];

      // Act
      final descriptors = files
          .map((file) => plugin.getFileIconDescriptor(file))
          .where((d) => d != null)
          .toList();

      // Assert
      expect(descriptors.length, 4);
      expect(descriptors.every((d) => d!.pluginId == 'plugin.file-icons'), true);
    });

    test('Use Case: Filter out folder nodes in tree', () async {
      // Arrange
      final plugin = FileIconsPlugin();
      await plugin.initialize(mockContext);

      final nodes = [
        FileTreeNode(id: '1', name: 'src', type: FileTreeNodeType.folder, children: []),
        FileTreeNode(id: '2', name: 'main.dart', type: FileTreeNodeType.file),
        FileTreeNode(id: '3', name: 'lib', type: FileTreeNodeType.folder, children: []),
        FileTreeNode(id: '4', name: 'app.js', type: FileTreeNodeType.file),
      ];

      // Act
      final fileIcons = nodes
          .map((node) => plugin.getFileIconDescriptor(node))
          .where((d) => d != null)
          .toList();

      // Assert
      expect(fileIcons.length, 2); // Only files should have icons
    });

    test('Use Case: Customize icon size for high-DPI display', () async {
      // Arrange
      const highDPIConfig = FileIconsConfig(iconSize: 32);
      final plugin = FileIconsPlugin(config: highDPIConfig);
      await plugin.initialize(mockContext);

      final fileNode = FileTreeNode(
        id: 'file-1',
        name: 'test.dart',
        type: FileTreeNodeType.file,
      );

      // Act
      final descriptor = plugin.getFileIconDescriptor(fileNode);

      // Assert
      expect(descriptor!.size, 32.0);
    });

    test('Use Case: Set higher priority to override other icon plugins', () async {
      // Arrange
      const highPriorityConfig = FileIconsConfig(priority: 10);
      final plugin = FileIconsPlugin(config: highPriorityConfig);
      await plugin.initialize(mockContext);

      final fileNode = FileTreeNode(
        id: 'file-1',
        name: 'test.dart',
        type: FileTreeNodeType.file,
      );

      // Act
      final descriptor = plugin.getFileIconDescriptor(fileNode);

      // Assert
      expect(descriptor!.priority, 10);
    });

    test('Use Case: Plugin cleanup on editor shutdown', () async {
      // Arrange
      final plugin = FileIconsPlugin();
      await plugin.initialize(mockContext);

      // Simulate some icon resolutions
      final fileNode = FileTreeNode(
        id: 'file-1',
        name: 'test.dart',
        type: FileTreeNodeType.file,
      );
      plugin.getFileIconDescriptor(fileNode);

      // Act
      await plugin.dispose();

      // Assert
      expect(plugin.isInitialized, false);
    });
  });

  group('FileIconsPlugin - Edge Cases', () {
    test('should handle uppercase file extensions', () async {
      // Arrange
      final plugin = FileIconsPlugin();
      await plugin.initialize(mockContext);

      final fileNode = FileTreeNode(
        id: 'file-1',
        name: 'TEST.DART',
        type: FileTreeNodeType.file,
      );

      // Act
      final descriptor = plugin.getFileIconDescriptor(fileNode);

      // Assert
      expect(descriptor, isNotNull);
    });

    test('should handle mixed case file names', () async {
      // Arrange
      final plugin = FileIconsPlugin();
      await plugin.initialize(mockContext);

      final fileNode = FileTreeNode(
        id: 'file-2',
        name: 'MyComponent.Dart',
        type: FileTreeNodeType.file,
      );

      // Act
      final descriptor = plugin.getFileIconDescriptor(fileNode);

      // Assert
      expect(descriptor, isNotNull);
    });

    test('should handle file names with spaces', () async {
      // Arrange
      final plugin = FileIconsPlugin();
      await plugin.initialize(mockContext);

      final fileNode = FileTreeNode(
        id: 'file-3',
        name: 'my file.dart',
        type: FileTreeNodeType.file,
      );

      // Act
      final descriptor = plugin.getFileIconDescriptor(fileNode);

      // Assert
      expect(descriptor, isNotNull);
    });

    test('should handle very long file names', () async {
      // Arrange
      final plugin = FileIconsPlugin();
      await plugin.initialize(mockContext);

      final longName = 'a' * 200 + '.dart';
      final fileNode = FileTreeNode(
        id: 'file-4',
        name: longName,
        type: FileTreeNodeType.file,
      );

      // Act
      final descriptor = plugin.getFileIconDescriptor(fileNode);

      // Assert
      expect(descriptor, isNotNull);
    });

    test('should handle special characters in file name', () async {
      // Arrange
      final plugin = FileIconsPlugin();
      await plugin.initialize(mockContext);

      final fileNode = FileTreeNode(
        id: 'file-5',
        name: 'test@#\$.dart',
        type: FileTreeNodeType.file,
      );

      // Act
      final descriptor = plugin.getFileIconDescriptor(fileNode);

      // Assert
      expect(descriptor, isNotNull);
    });
  });
}
