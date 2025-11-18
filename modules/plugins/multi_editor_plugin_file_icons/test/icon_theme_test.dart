import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugin_file_icons/src/domain/entities/icon_theme.dart';

void main() {
  group('IconTheme - Creation', () {
    test('should create with required fields', () {
      // Arrange & Act
      const theme = IconTheme(
        id: 'vscode-icons',
        name: 'VS Code Icons',
        provider: 'vscode',
        baseUrl: 'https://example.com/icons',
      );

      // Assert
      expect(theme.id, 'vscode-icons');
      expect(theme.name, 'VS Code Icons');
      expect(theme.provider, 'vscode');
      expect(theme.baseUrl, 'https://example.com/icons');
    });

    test('should use default values for optional fields', () {
      // Arrange & Act
      const theme = IconTheme(
        id: 'test-theme',
        name: 'Test Theme',
        provider: 'test',
        baseUrl: 'https://test.com',
      );

      // Assert
      expect(theme.priority, 100);
      expect(theme.isActive, false);
      expect(theme.supportedExtensions, isEmpty);
      expect(theme.metadata, isEmpty);
    });

    test('should create with all fields specified', () {
      // Arrange & Act
      const theme = IconTheme(
        id: 'custom-theme',
        name: 'Custom Theme',
        provider: 'custom',
        baseUrl: 'https://custom.com',
        priority: 50,
        isActive: true,
        supportedExtensions: ['dart', 'js', 'ts'],
        metadata: {'version': '1.0.0', 'author': 'Test Author'},
      );

      // Assert
      expect(theme.id, 'custom-theme');
      expect(theme.name, 'Custom Theme');
      expect(theme.provider, 'custom');
      expect(theme.baseUrl, 'https://custom.com');
      expect(theme.priority, 50);
      expect(theme.isActive, true);
      expect(theme.supportedExtensions, ['dart', 'js', 'ts']);
      expect(theme.metadata['version'], '1.0.0');
      expect(theme.metadata['author'], 'Test Author');
    });
  });

  group('IconTheme - Extension Support', () {
    test('should support all extensions when list is empty', () {
      // Arrange
      const theme = IconTheme(
        id: 'universal-theme',
        name: 'Universal Theme',
        provider: 'test',
        baseUrl: 'https://test.com',
        supportedExtensions: [],
      );

      // Act & Assert
      expect(theme.supportsExtension('dart'), true);
      expect(theme.supportsExtension('js'), true);
      expect(theme.supportsExtension('unknown'), true);
    });

    test('should support only listed extensions', () {
      // Arrange
      const theme = IconTheme(
        id: 'limited-theme',
        name: 'Limited Theme',
        provider: 'test',
        baseUrl: 'https://test.com',
        supportedExtensions: ['dart', 'js', 'ts'],
      );

      // Act & Assert
      expect(theme.supportsExtension('dart'), true);
      expect(theme.supportsExtension('js'), true);
      expect(theme.supportsExtension('ts'), true);
      expect(theme.supportsExtension('py'), false);
      expect(theme.supportsExtension('java'), false);
    });

    test('should be case-insensitive for extension matching', () {
      // Arrange
      const theme = IconTheme(
        id: 'test-theme',
        name: 'Test Theme',
        provider: 'test',
        baseUrl: 'https://test.com',
        supportedExtensions: ['dart', 'js'],
      );

      // Act & Assert
      expect(theme.supportsExtension('DART'), true);
      expect(theme.supportsExtension('Dart'), true);
      expect(theme.supportsExtension('JS'), true);
      expect(theme.supportsExtension('Js'), true);
    });

    test('should handle mixed case in supported extensions list', () {
      // Arrange
      const theme = IconTheme(
        id: 'test-theme',
        name: 'Test Theme',
        provider: 'test',
        baseUrl: 'https://test.com',
        supportedExtensions: ['DART', 'Js', 'tS'],
      );

      // Act & Assert
      expect(theme.supportsExtension('dart'), true);
      expect(theme.supportsExtension('js'), true);
      expect(theme.supportsExtension('ts'), true);
    });
  });

  group('IconTheme - Icon URL Generation', () {
    test('should generate URL for iconify provider', () {
      // Arrange
      const theme = IconTheme(
        id: 'iconify-theme',
        name: 'Iconify Theme',
        provider: 'iconify',
        baseUrl: 'https://api.iconify.design',
      );

      // Act
      final url = theme.getIconUrl('dart');

      // Assert
      expect(url, 'https://api.iconify.design/vscode-icons:file-type-dart.svg');
    });

    test('should generate URL for vscode provider', () {
      // Arrange
      const theme = IconTheme(
        id: 'vscode-theme',
        name: 'VS Code Theme',
        provider: 'vscode',
        baseUrl: 'https://vscode.com/icons',
      );

      // Act
      final url = theme.getIconUrl('dart');

      // Assert
      expect(url, 'https://vscode.com/icons/icons/file_type_dart.svg');
    });

    test('should generate URL for material provider', () {
      // Arrange
      const theme = IconTheme(
        id: 'material-theme',
        name: 'Material Theme',
        provider: 'material',
        baseUrl: 'https://material.io/icons',
      );

      // Act
      final url = theme.getIconUrl('dart');

      // Assert
      expect(url, 'https://material.io/icons/icons/dart.svg');
    });

    test('should generate URL for unknown provider with default pattern', () {
      // Arrange
      const theme = IconTheme(
        id: 'custom-theme',
        name: 'Custom Theme',
        provider: 'custom',
        baseUrl: 'https://custom.com',
      );

      // Act
      final url = theme.getIconUrl('dart');

      // Assert
      expect(url, 'https://custom.com/dart.svg');
    });

    test('should handle different file extensions correctly', () {
      // Arrange
      const theme = IconTheme(
        id: 'test-theme',
        name: 'Test Theme',
        provider: 'iconify',
        baseUrl: 'https://api.iconify.design',
      );

      final testCases = [
        ('dart', 'vscode-icons:file-type-dart.svg'),
        ('js', 'vscode-icons:file-type-js.svg'),
        ('py', 'vscode-icons:file-type-py.svg'),
      ];

      // Act & Assert
      for (final (extension, expectedSuffix) in testCases) {
        final url = theme.getIconUrl(extension);
        expect(
          url,
          endsWith(expectedSuffix),
          reason: 'Failed for extension: $extension',
        );
      }
    });
  });

  group('IconTheme - Priority', () {
    test('should have default priority of 100', () {
      // Arrange & Act
      const theme = IconTheme(
        id: 'test-theme',
        name: 'Test Theme',
        provider: 'test',
        baseUrl: 'https://test.com',
      );

      // Assert
      expect(theme.priority, 100);
    });

    test('should allow custom priority', () {
      // Arrange & Act
      const theme = IconTheme(
        id: 'high-priority-theme',
        name: 'High Priority Theme',
        provider: 'test',
        baseUrl: 'https://test.com',
        priority: 10,
      );

      // Assert
      expect(theme.priority, 10);
    });

    test('should support low priority values', () {
      // Arrange & Act
      const theme = IconTheme(
        id: 'low-priority-theme',
        name: 'Low Priority Theme',
        provider: 'test',
        baseUrl: 'https://test.com',
        priority: 1000,
      );

      // Assert
      expect(theme.priority, 1000);
    });
  });

  group('IconTheme - Active State', () {
    test('should be inactive by default', () {
      // Arrange & Act
      const theme = IconTheme(
        id: 'test-theme',
        name: 'Test Theme',
        provider: 'test',
        baseUrl: 'https://test.com',
      );

      // Assert
      expect(theme.isActive, false);
    });

    test('should be activatable', () {
      // Arrange & Act
      const theme = IconTheme(
        id: 'active-theme',
        name: 'Active Theme',
        provider: 'test',
        baseUrl: 'https://test.com',
        isActive: true,
      );

      // Assert
      expect(theme.isActive, true);
    });

    test('should toggle active state using copyWith', () {
      // Arrange
      const theme = IconTheme(
        id: 'test-theme',
        name: 'Test Theme',
        provider: 'test',
        baseUrl: 'https://test.com',
        isActive: false,
      );

      // Act
      final activeTheme = theme.copyWith(isActive: true);
      final inactiveTheme = activeTheme.copyWith(isActive: false);

      // Assert
      expect(theme.isActive, false);
      expect(activeTheme.isActive, true);
      expect(inactiveTheme.isActive, false);
    });
  });

  group('IconTheme - Metadata', () {
    test('should have empty metadata by default', () {
      // Arrange & Act
      const theme = IconTheme(
        id: 'test-theme',
        name: 'Test Theme',
        provider: 'test',
        baseUrl: 'https://test.com',
      );

      // Assert
      expect(theme.metadata, isEmpty);
    });

    test('should store custom metadata', () {
      // Arrange & Act
      const theme = IconTheme(
        id: 'test-theme',
        name: 'Test Theme',
        provider: 'test',
        baseUrl: 'https://test.com',
        metadata: {
          'version': '2.0.0',
          'author': 'John Doe',
          'license': 'MIT',
          'description': 'A custom icon theme',
        },
      );

      // Assert
      expect(theme.metadata['version'], '2.0.0');
      expect(theme.metadata['author'], 'John Doe');
      expect(theme.metadata['license'], 'MIT');
      expect(theme.metadata['description'], 'A custom icon theme');
    });

    test('should support nested metadata', () {
      // Arrange & Act
      const theme = IconTheme(
        id: 'test-theme',
        name: 'Test Theme',
        provider: 'test',
        baseUrl: 'https://test.com',
        metadata: {
          'config': {
            'size': 18,
            'format': 'svg',
          },
          'stats': {
            'downloads': 1000,
            'stars': 500,
          },
        },
      );

      // Assert
      expect(theme.metadata['config'], isA<Map>());
      expect(theme.metadata['stats'], isA<Map>());
    });
  });

  group('IconTheme - Equality', () {
    test('should be equal for same values', () {
      // Arrange
      const theme1 = IconTheme(
        id: 'test-theme',
        name: 'Test Theme',
        provider: 'test',
        baseUrl: 'https://test.com',
        priority: 50,
      );

      const theme2 = IconTheme(
        id: 'test-theme',
        name: 'Test Theme',
        provider: 'test',
        baseUrl: 'https://test.com',
        priority: 50,
      );

      // Act & Assert
      expect(theme1, equals(theme2));
      expect(theme1.hashCode, equals(theme2.hashCode));
    });

    test('should not be equal for different IDs', () {
      // Arrange
      const theme1 = IconTheme(
        id: 'theme-1',
        name: 'Test Theme',
        provider: 'test',
        baseUrl: 'https://test.com',
      );

      const theme2 = IconTheme(
        id: 'theme-2',
        name: 'Test Theme',
        provider: 'test',
        baseUrl: 'https://test.com',
      );

      // Act & Assert
      expect(theme1, isNot(equals(theme2)));
    });

    test('should not be equal for different active states', () {
      // Arrange
      const theme1 = IconTheme(
        id: 'test-theme',
        name: 'Test Theme',
        provider: 'test',
        baseUrl: 'https://test.com',
        isActive: false,
      );

      const theme2 = IconTheme(
        id: 'test-theme',
        name: 'Test Theme',
        provider: 'test',
        baseUrl: 'https://test.com',
        isActive: true,
      );

      // Act & Assert
      expect(theme1, isNot(equals(theme2)));
    });
  });

  group('IconTheme - Immutability', () {
    test('should create new instance with copyWith', () {
      // Arrange
      const original = IconTheme(
        id: 'test-theme',
        name: 'Test Theme',
        provider: 'test',
        baseUrl: 'https://test.com',
        priority: 100,
      );

      // Act
      final modified = original.copyWith(priority: 50);

      // Assert
      expect(original.priority, 100);
      expect(modified.priority, 50);
      expect(modified.id, original.id);
    });

    test('should preserve unchanged fields in copyWith', () {
      // Arrange
      const original = IconTheme(
        id: 'test-theme',
        name: 'Test Theme',
        provider: 'test',
        baseUrl: 'https://test.com',
        priority: 100,
        supportedExtensions: ['dart', 'js'],
      );

      // Act
      final modified = original.copyWith(isActive: true);

      // Assert
      expect(modified.id, original.id);
      expect(modified.name, original.name);
      expect(modified.provider, original.provider);
      expect(modified.baseUrl, original.baseUrl);
      expect(modified.priority, original.priority);
      expect(modified.supportedExtensions, original.supportedExtensions);
      expect(modified.isActive, true);
    });
  });

  group('IconTheme - Use Cases', () {
    test('Use Case: Create VS Code icons theme', () {
      // Arrange & Act
      const theme = IconTheme(
        id: 'vscode-icons',
        name: 'VS Code Icons',
        provider: 'vscode',
        baseUrl: 'https://raw.githubusercontent.com/vscode-icons/vscode-icons',
        priority: 10,
        supportedExtensions: [], // Supports all
      );

      // Assert
      expect(theme.id, 'vscode-icons');
      expect(theme.supportsExtension('dart'), true);
      expect(theme.supportsExtension('js'), true);
      expect(theme.getIconUrl('dart'), contains('file_type_dart.svg'));
    });

    test('Use Case: Create Material Design icons theme', () {
      // Arrange & Act
      const theme = IconTheme(
        id: 'material-icons',
        name: 'Material Design Icons',
        provider: 'material',
        baseUrl: 'https://fonts.gstatic.com/s/i/materialicons',
        priority: 20,
      );

      // Assert
      expect(theme.provider, 'material');
      expect(theme.getIconUrl('code'), contains('code.svg'));
    });

    test('Use Case: Create theme with limited language support', () {
      // Arrange & Act
      const theme = IconTheme(
        id: 'dart-only-theme',
        name: 'Dart Only Theme',
        provider: 'custom',
        baseUrl: 'https://custom.com',
        supportedExtensions: ['dart'],
      );

      // Assert
      expect(theme.supportsExtension('dart'), true);
      expect(theme.supportsExtension('js'), false);
      expect(theme.supportsExtension('py'), false);
    });

    test('Use Case: Activate theme for use', () {
      // Arrange
      const theme = IconTheme(
        id: 'test-theme',
        name: 'Test Theme',
        provider: 'test',
        baseUrl: 'https://test.com',
        isActive: false,
      );

      // Act
      final activeTheme = theme.copyWith(isActive: true);

      // Assert
      expect(theme.isActive, false);
      expect(activeTheme.isActive, true);
    });

    test('Use Case: Manage multiple themes with priorities', () {
      // Arrange
      const themes = [
        IconTheme(
          id: 'high-priority',
          name: 'High Priority',
          provider: 'test',
          baseUrl: 'https://test1.com',
          priority: 10,
        ),
        IconTheme(
          id: 'medium-priority',
          name: 'Medium Priority',
          provider: 'test',
          baseUrl: 'https://test2.com',
          priority: 50,
        ),
        IconTheme(
          id: 'low-priority',
          name: 'Low Priority',
          provider: 'test',
          baseUrl: 'https://test3.com',
          priority: 100,
        ),
      ];

      // Act - Sort by priority (lower = higher priority)
      final sorted = List<IconTheme>.from(themes)
        ..sort((a, b) => a.priority.compareTo(b.priority));

      // Assert
      expect(sorted[0].id, 'high-priority');
      expect(sorted[1].id, 'medium-priority');
      expect(sorted[2].id, 'low-priority');
    });

    test('Use Case: Store theme configuration in metadata', () {
      // Arrange & Act
      const theme = IconTheme(
        id: 'configurable-theme',
        name: 'Configurable Theme',
        provider: 'test',
        baseUrl: 'https://test.com',
        metadata: {
          'version': '1.2.3',
          'author': 'Theme Author',
          'homepage': 'https://theme.com',
          'license': 'MIT',
          'settings': {
            'colorful': true,
            'format': 'svg',
          },
        },
      );

      // Assert
      expect(theme.metadata['version'], '1.2.3');
      expect(theme.metadata['settings'], isA<Map>());
    });
  });

  group('IconTheme - Edge Cases', () {
    test('should handle empty ID', () {
      // Arrange & Act
      const theme = IconTheme(
        id: '',
        name: 'Test Theme',
        provider: 'test',
        baseUrl: 'https://test.com',
      );

      // Assert
      expect(theme.id, '');
    });

    test('should handle empty name', () {
      // Arrange & Act
      const theme = IconTheme(
        id: 'test-theme',
        name: '',
        provider: 'test',
        baseUrl: 'https://test.com',
      );

      // Assert
      expect(theme.name, '');
    });

    test('should handle empty base URL', () {
      // Arrange & Act
      const theme = IconTheme(
        id: 'test-theme',
        name: 'Test Theme',
        provider: 'test',
        baseUrl: '',
      );

      // Assert
      expect(theme.baseUrl, '');
      expect(theme.getIconUrl('dart'), '/dart.svg');
    });

    test('should handle base URL without trailing slash', () {
      // Arrange
      const theme = IconTheme(
        id: 'test-theme',
        name: 'Test Theme',
        provider: 'material',
        baseUrl: 'https://test.com',
      );

      // Act
      final url = theme.getIconUrl('dart');

      // Assert
      expect(url, 'https://test.com/icons/dart.svg');
    });

    test('should handle base URL with trailing slash', () {
      // Arrange
      const theme = IconTheme(
        id: 'test-theme',
        name: 'Test Theme',
        provider: 'material',
        baseUrl: 'https://test.com/',
      );

      // Act
      final url = theme.getIconUrl('dart');

      // Assert
      expect(url, 'https://test.com//icons/dart.svg'); // Note: double slash
    });

    test('should handle special characters in extension', () {
      // Arrange
      const theme = IconTheme(
        id: 'test-theme',
        name: 'Test Theme',
        provider: 'iconify',
        baseUrl: 'https://test.com',
      );

      // Act
      final url = theme.getIconUrl('test@#\$');

      // Assert
      expect(url, contains('test@#\$'));
    });

    test('should handle very long extension names', () {
      // Arrange
      const theme = IconTheme(
        id: 'test-theme',
        name: 'Test Theme',
        provider: 'iconify',
        baseUrl: 'https://test.com',
      );

      final longExtension = 'a' * 100;

      // Act
      final url = theme.getIconUrl(longExtension);

      // Assert
      expect(url, contains(longExtension));
    });
  });

  group('IconTheme - toString', () {
    test('should have readable toString representation', () {
      // Arrange
      const theme = IconTheme(
        id: 'test-theme',
        name: 'Test Theme',
        provider: 'test',
        baseUrl: 'https://test.com',
      );

      // Act
      final str = theme.toString();

      // Assert
      expect(str, contains('IconTheme'));
      expect(str, contains('id'));
    });
  });
}
