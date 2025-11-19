import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugins/src/plugin_api/plugin_manifest.dart';

void main() {
  group('PluginManifest', () {
    group('constructor', () {
      test('should create manifest with required fields', () {
        // Arrange & Act
        final manifest = PluginManifest(
          id: 'test-plugin',
          name: 'Test Plugin',
          version: '1.0.0',
        );

        // Assert
        expect(manifest.id, 'test-plugin');
        expect(manifest.name, 'Test Plugin');
        expect(manifest.version, '1.0.0');
        expect(manifest.description, null);
        expect(manifest.author, null);
        expect(manifest.dependencies, isEmpty);
        expect(manifest.capabilities, isEmpty);
        expect(manifest.activationEvents, isEmpty);
        expect(manifest.metadata, isEmpty);
      });

      test('should create manifest with all fields', () {
        // Arrange & Act
        final manifest = PluginManifest(
          id: 'full-plugin',
          name: 'Full Plugin',
          version: '2.0.0',
          description: 'A fully specified plugin',
          author: 'Test Author',
          dependencies: ['dep1', 'dep2'],
          capabilities: {'edit': 'files', 'view': 'ui'},
          activationEvents: ['onStartup', 'onCommand'],
          metadata: {'key1': 'value1', 'key2': 42},
        );

        // Assert
        expect(manifest.id, 'full-plugin');
        expect(manifest.name, 'Full Plugin');
        expect(manifest.version, '2.0.0');
        expect(manifest.description, 'A fully specified plugin');
        expect(manifest.author, 'Test Author');
        expect(manifest.dependencies, ['dep1', 'dep2']);
        expect(manifest.capabilities, {'edit': 'files', 'view': 'ui'});
        expect(manifest.activationEvents, ['onStartup', 'onCommand']);
        expect(manifest.metadata, {'key1': 'value1', 'key2': 42});
      });

      test('should use default values for optional collections', () {
        // Arrange & Act
        final manifest = PluginManifest(
          id: 'default-plugin',
          name: 'Default Plugin',
          version: '1.0.0',
        );

        // Assert
        expect(manifest.dependencies, isEmpty);
        expect(manifest.capabilities, isEmpty);
        expect(manifest.activationEvents, isEmpty);
        expect(manifest.metadata, isEmpty);
      });
    });

    group('requiresCapability', () {
      test('should return true when capability exists', () {
        // Arrange
        final manifest = PluginManifest(
          id: 'test',
          name: 'Test',
          version: '1.0.0',
          capabilities: {'fileSystem': 'read', 'network': 'enabled'},
        );

        // Act & Assert
        expect(manifest.requiresCapability('fileSystem'), true);
        expect(manifest.requiresCapability('network'), true);
      });

      test('should return false when capability does not exist', () {
        // Arrange
        final manifest = PluginManifest(
          id: 'test',
          name: 'Test',
          version: '1.0.0',
          capabilities: {'fileSystem': 'read'},
        );

        // Act & Assert
        expect(manifest.requiresCapability('network'), false);
        expect(manifest.requiresCapability('nonexistent'), false);
      });

      test('should return false when no capabilities defined', () {
        // Arrange
        final manifest = PluginManifest(
          id: 'test',
          name: 'Test',
          version: '1.0.0',
        );

        // Act & Assert
        expect(manifest.requiresCapability('anyCapability'), false);
      });

      test('should be case-sensitive', () {
        // Arrange
        final manifest = PluginManifest(
          id: 'test',
          name: 'Test',
          version: '1.0.0',
          capabilities: {'FileSystem': 'read'},
        );

        // Act & Assert
        expect(manifest.requiresCapability('FileSystem'), true);
        expect(manifest.requiresCapability('filesystem'), false);
      });
    });

    group('hasActivationEvent', () {
      test('should return true when activation event exists', () {
        // Arrange
        final manifest = PluginManifest(
          id: 'test',
          name: 'Test',
          version: '1.0.0',
          activationEvents: ['onStartup', 'onCommand:test', 'onLanguage:dart'],
        );

        // Act & Assert
        expect(manifest.hasActivationEvent('onStartup'), true);
        expect(manifest.hasActivationEvent('onCommand:test'), true);
        expect(manifest.hasActivationEvent('onLanguage:dart'), true);
      });

      test('should return false when activation event does not exist', () {
        // Arrange
        final manifest = PluginManifest(
          id: 'test',
          name: 'Test',
          version: '1.0.0',
          activationEvents: ['onStartup'],
        );

        // Act & Assert
        expect(manifest.hasActivationEvent('onCommand'), false);
        expect(manifest.hasActivationEvent('nonexistent'), false);
      });

      test('should return false when no activation events defined', () {
        // Arrange
        final manifest = PluginManifest(
          id: 'test',
          name: 'Test',
          version: '1.0.0',
        );

        // Act & Assert
        expect(manifest.hasActivationEvent('onStartup'), false);
      });

      test('should be case-sensitive', () {
        // Arrange
        final manifest = PluginManifest(
          id: 'test',
          name: 'Test',
          version: '1.0.0',
          activationEvents: ['onStartup'],
        );

        // Act & Assert
        expect(manifest.hasActivationEvent('onStartup'), true);
        expect(manifest.hasActivationEvent('onstartup'), false);
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON with all fields', () {
        // Arrange
        final manifest = PluginManifest(
          id: 'json-plugin',
          name: 'JSON Plugin',
          version: '1.2.3',
          description: 'Test description',
          author: 'Test Author',
          dependencies: ['dep1', 'dep2'],
          capabilities: {'cap1': 'value1'},
          activationEvents: ['event1'],
          metadata: {'key': 'value'},
        );

        // Act
        final json = manifest.toJson();

        // Assert
        expect(json['id'], 'json-plugin');
        expect(json['name'], 'JSON Plugin');
        expect(json['version'], '1.2.3');
        expect(json['description'], 'Test description');
        expect(json['author'], 'Test Author');
        expect(json['dependencies'], ['dep1', 'dep2']);
        expect(json['capabilities'], {'cap1': 'value1'});
        expect(json['activationEvents'], ['event1']);
        expect(json['metadata'], {'key': 'value'});
      });

      test('should serialize minimal manifest to JSON', () {
        // Arrange
        final manifest = PluginManifest(
          id: 'minimal',
          name: 'Minimal',
          version: '0.1.0',
        );

        // Act
        final json = manifest.toJson();

        // Assert
        expect(json['id'], 'minimal');
        expect(json['name'], 'Minimal');
        expect(json['version'], '0.1.0');
        expect(json['dependencies'], isEmpty);
        expect(json['capabilities'], isEmpty);
        expect(json['activationEvents'], isEmpty);
        expect(json['metadata'], isEmpty);
      });

      test('should deserialize from JSON with all fields', () {
        // Arrange
        final json = {
          'id': 'json-plugin',
          'name': 'JSON Plugin',
          'version': '1.2.3',
          'description': 'Test description',
          'author': 'Test Author',
          'dependencies': ['dep1', 'dep2'],
          'capabilities': {'cap1': 'value1'},
          'activationEvents': ['event1'],
          'metadata': {'key': 'value'},
        };

        // Act
        final manifest = PluginManifest.fromJson(json);

        // Assert
        expect(manifest.id, 'json-plugin');
        expect(manifest.name, 'JSON Plugin');
        expect(manifest.version, '1.2.3');
        expect(manifest.description, 'Test description');
        expect(manifest.author, 'Test Author');
        expect(manifest.dependencies, ['dep1', 'dep2']);
        expect(manifest.capabilities, {'cap1': 'value1'});
        expect(manifest.activationEvents, ['event1']);
        expect(manifest.metadata, {'key': 'value'});
      });

      test('should deserialize minimal JSON', () {
        // Arrange
        final json = {
          'id': 'minimal',
          'name': 'Minimal',
          'version': '0.1.0',
        };

        // Act
        final manifest = PluginManifest.fromJson(json);

        // Assert
        expect(manifest.id, 'minimal');
        expect(manifest.name, 'Minimal');
        expect(manifest.version, '0.1.0');
        expect(manifest.description, null);
        expect(manifest.author, null);
      });

      test('should round-trip through JSON', () {
        // Arrange
        final original = PluginManifest(
          id: 'roundtrip',
          name: 'Roundtrip Test',
          version: '1.0.0',
          description: 'Testing serialization',
          author: 'Tester',
          dependencies: ['a', 'b', 'c'],
          capabilities: {'x': 'y', 'z': 'w'},
          activationEvents: ['e1', 'e2'],
          metadata: {'m1': 'v1', 'm2': 123, 'm3': true},
        );

        // Act
        final json = original.toJson();
        final deserialized = PluginManifest.fromJson(json);

        // Assert
        expect(deserialized.id, original.id);
        expect(deserialized.name, original.name);
        expect(deserialized.version, original.version);
        expect(deserialized.description, original.description);
        expect(deserialized.author, original.author);
        expect(deserialized.dependencies, original.dependencies);
        expect(deserialized.capabilities, original.capabilities);
        expect(deserialized.activationEvents, original.activationEvents);
        expect(deserialized.metadata, original.metadata);
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        // Arrange
        final manifest1 = PluginManifest(
          id: 'test',
          name: 'Test',
          version: '1.0.0',
          description: 'Description',
        );
        final manifest2 = PluginManifest(
          id: 'test',
          name: 'Test',
          version: '1.0.0',
          description: 'Description',
        );

        // Act & Assert
        expect(manifest1, equals(manifest2));
        expect(manifest1.hashCode, equals(manifest2.hashCode));
      });

      test('should not be equal when IDs differ', () {
        // Arrange
        final manifest1 = PluginManifest(
          id: 'test1',
          name: 'Test',
          version: '1.0.0',
        );
        final manifest2 = PluginManifest(
          id: 'test2',
          name: 'Test',
          version: '1.0.0',
        );

        // Act & Assert
        expect(manifest1, isNot(equals(manifest2)));
      });

      test('should not be equal when versions differ', () {
        // Arrange
        final manifest1 = PluginManifest(
          id: 'test',
          name: 'Test',
          version: '1.0.0',
        );
        final manifest2 = PluginManifest(
          id: 'test',
          name: 'Test',
          version: '2.0.0',
        );

        // Act & Assert
        expect(manifest1, isNot(equals(manifest2)));
      });
    });

    group('edge cases', () {
      test('should handle empty strings', () {
        // Arrange & Act
        final manifest = PluginManifest(
          id: '',
          name: '',
          version: '',
          description: '',
          author: '',
        );

        // Assert
        expect(manifest.id, '');
        expect(manifest.name, '');
        expect(manifest.version, '');
        expect(manifest.description, '');
        expect(manifest.author, '');
      });

      test('should handle special characters in strings', () {
        // Arrange & Act
        final manifest = PluginManifest(
          id: 'plugin-123_test.special',
          name: 'Test Plugin™ © 2024',
          version: '1.0.0-beta+001',
          description: 'A plugin with "quotes" and \'apostrophes\'',
          author: 'Author <email@example.com>',
        );

        // Assert
        expect(manifest.id, contains('plugin-123_test.special'));
        expect(manifest.name, contains('™'));
        expect(manifest.version, contains('-beta+001'));
      });

      test('should handle unicode in strings', () {
        // Arrange & Act
        final manifest = PluginManifest(
          id: 'unicode-plugin',
          name: '测试插件',
          version: '1.0.0',
          description: 'Плагин с поддержкой юникода',
          author: 'مؤلف',
        );

        // Assert
        expect(manifest.name, '测试插件');
        expect(manifest.description, contains('Плагин'));
        expect(manifest.author, 'مؤلف');
      });

      test('should handle large dependency lists', () {
        // Arrange
        final largeDependencies = List.generate(1000, (i) => 'dep-$i');

        // Act
        final manifest = PluginManifest(
          id: 'large-deps',
          name: 'Large Dependencies',
          version: '1.0.0',
          dependencies: largeDependencies,
        );

        // Assert
        expect(manifest.dependencies.length, 1000);
        expect(manifest.dependencies.first, 'dep-0');
        expect(manifest.dependencies.last, 'dep-999');
      });

      test('should handle complex nested metadata', () {
        // Arrange
        final complexMetadata = {
          'level1': {
            'level2': {
              'level3': ['a', 'b', 'c'],
            },
          },
          'array': [1, 2, 3],
          'mixed': {
            'string': 'value',
            'number': 42,
            'bool': true,
            'null': null,
          },
        };

        // Act
        final manifest = PluginManifest(
          id: 'complex',
          name: 'Complex',
          version: '1.0.0',
          metadata: complexMetadata,
        );

        // Assert
        expect(manifest.metadata['level1']['level2']['level3'], ['a', 'b', 'c']);
        expect(manifest.metadata['array'], [1, 2, 3]);
        expect(manifest.metadata['mixed']['number'], 42);
      });

      test('should handle activation events with various formats', () {
        // Arrange
        final activationEvents = [
          'onStartup',
          'onCommand:myCommand',
          'onLanguage:dart',
          'onView:myView',
          'onFileSystem:myScheme',
          'custom:event:with:colons',
        ];

        // Act
        final manifest = PluginManifest(
          id: 'events',
          name: 'Events',
          version: '1.0.0',
          activationEvents: activationEvents,
        );

        // Assert
        for (final event in activationEvents) {
          expect(manifest.hasActivationEvent(event), true);
        }
      });

      test('should handle capabilities with various value types', () {
        // Arrange
        final capabilities = {
          'string': 'value',
          'number': '123',
          'boolean': 'true',
          'empty': '',
        };

        // Act
        final manifest = PluginManifest(
          id: 'caps',
          name: 'Caps',
          version: '1.0.0',
          capabilities: capabilities,
        );

        // Assert
        expect(manifest.requiresCapability('string'), true);
        expect(manifest.requiresCapability('number'), true);
        expect(manifest.requiresCapability('boolean'), true);
        expect(manifest.requiresCapability('empty'), true);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        // Arrange
        final original = PluginManifest(
          id: 'original',
          name: 'Original',
          version: '1.0.0',
        );

        // Act
        final copy = original.copyWith(
          name: 'Updated',
          version: '2.0.0',
        );

        // Assert
        expect(copy.id, 'original'); // Unchanged
        expect(copy.name, 'Updated'); // Changed
        expect(copy.version, '2.0.0'); // Changed
      });

      test('should create identical copy when no fields specified', () {
        // Arrange
        final original = PluginManifest(
          id: 'original',
          name: 'Original',
          version: '1.0.0',
          description: 'Test',
        );

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy, equals(original));
      });
    });

    group('toString', () {
      test('should provide readable string representation', () {
        // Arrange
        final manifest = PluginManifest(
          id: 'test',
          name: 'Test Plugin',
          version: '1.0.0',
        );

        // Act
        final str = manifest.toString();

        // Assert
        expect(str, contains('PluginManifest'));
        expect(str, contains('test'));
      });
    });

    group('real-world scenarios', () {
      test('should represent a typical plugin manifest', () {
        // Arrange & Act
        final manifest = PluginManifest(
          id: 'com.example.git-integration',
          name: 'Git Integration',
          version: '1.5.2',
          description: 'Provides Git version control integration',
          author: 'Example Inc.',
          dependencies: [
            'com.example.file-system',
            'com.example.terminal',
          ],
          capabilities: {
            'fileSystem': 'read,write',
            'network': 'enabled',
            'terminal': 'enabled',
          },
          activationEvents: [
            'onStartup',
            'onCommand:git.commit',
            'onCommand:git.push',
            'onFileSystem:git',
          ],
          metadata: {
            'repository': 'https://github.com/example/git-integration',
            'license': 'MIT',
            'keywords': ['git', 'version-control', 'scm'],
          },
        );

        // Assert
        expect(manifest.id, 'com.example.git-integration');
        expect(manifest.requiresCapability('fileSystem'), true);
        expect(manifest.requiresCapability('network'), true);
        expect(manifest.hasActivationEvent('onStartup'), true);
        expect(manifest.hasActivationEvent('onCommand:git.commit'), true);
        expect(manifest.dependencies.length, 2);
      });
    });
  });
}
