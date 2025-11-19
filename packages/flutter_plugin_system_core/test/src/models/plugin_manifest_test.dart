import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_plugin_system_core/src/models/plugin_manifest.dart';
import 'package:flutter_plugin_system_core/src/types/plugin_types.dart';

void main() {
  group('PluginManifest', () {
    group('constructor', () {
      test('should create instance with required fields only', () {
        // Arrange & Act
        const manifest = PluginManifest(
          id: 'plugin.test',
          name: 'Test Plugin',
          version: '1.0.0',
          description: 'A test plugin',
          runtime: PluginRuntimeType.wasm,
        );

        // Assert
        expect(manifest.id, 'plugin.test');
        expect(manifest.name, 'Test Plugin');
        expect(manifest.version, '1.0.0');
        expect(manifest.description, 'A test plugin');
        expect(manifest.runtime, PluginRuntimeType.wasm);
        expect(manifest.author, isNull);
        expect(manifest.homepage, isNull);
        expect(manifest.repository, isNull);
        expect(manifest.license, isNull);
        expect(manifest.dependencies, isEmpty);
        expect(manifest.configSchema, isNull);
        expect(manifest.requiredHostFunctions, isEmpty);
        expect(manifest.providedEvents, isEmpty);
        expect(manifest.subscribesTo, isEmpty);
        expect(manifest.minHostVersion, isNull);
        expect(manifest.maxHostVersion, isNull);
        expect(manifest.metadata, isNull);
      });

      test('should create instance with all fields', () {
        // Arrange & Act
        final manifest = PluginManifest(
          id: 'plugin.file-icons',
          name: 'File Icons',
          version: '2.1.0',
          description: 'Beautiful file icons',
          runtime: PluginRuntimeType.native,
          author: 'Editor Team',
          homepage: 'https://example.com',
          repository: 'https://github.com/example/plugin',
          license: 'MIT',
          dependencies: const ['plugin.core', 'plugin.utils'],
          configSchema: const {'theme': 'string', 'size': 'number'},
          requiredHostFunctions: const ['get_file_extension', 'log_info'],
          providedEvents: const ['icon.loaded', 'icon.error'],
          subscribesTo: const ['file.opened', 'file.saved'],
          minHostVersion: '1.0.0',
          maxHostVersion: '2.0.0',
          metadata: const {'custom': 'value'},
        );

        // Assert
        expect(manifest.id, 'plugin.file-icons');
        expect(manifest.name, 'File Icons');
        expect(manifest.version, '2.1.0');
        expect(manifest.description, 'Beautiful file icons');
        expect(manifest.runtime, PluginRuntimeType.native);
        expect(manifest.author, 'Editor Team');
        expect(manifest.homepage, 'https://example.com');
        expect(manifest.repository, 'https://github.com/example/plugin');
        expect(manifest.license, 'MIT');
        expect(manifest.dependencies, ['plugin.core', 'plugin.utils']);
        expect(manifest.configSchema, {'theme': 'string', 'size': 'number'});
        expect(manifest.requiredHostFunctions, ['get_file_extension', 'log_info']);
        expect(manifest.providedEvents, ['icon.loaded', 'icon.error']);
        expect(manifest.subscribesTo, ['file.opened', 'file.saved']);
        expect(manifest.minHostVersion, '1.0.0');
        expect(manifest.maxHostVersion, '2.0.0');
        expect(manifest.metadata, {'custom': 'value'});
      });

      test('should create with different runtime types', () {
        // Arrange & Act
        const wasmManifest = PluginManifest(
          id: 'plugin.wasm',
          name: 'WASM Plugin',
          version: '1.0.0',
          description: 'WASM runtime plugin',
          runtime: PluginRuntimeType.wasm,
        );
        const nativeManifest = PluginManifest(
          id: 'plugin.native',
          name: 'Native Plugin',
          version: '1.0.0',
          description: 'Native runtime plugin',
          runtime: PluginRuntimeType.native,
        );
        const scriptManifest = PluginManifest(
          id: 'plugin.script',
          name: 'Script Plugin',
          version: '1.0.0',
          description: 'Script runtime plugin',
          runtime: PluginRuntimeType.script,
        );

        // Assert
        expect(wasmManifest.runtime, PluginRuntimeType.wasm);
        expect(nativeManifest.runtime, PluginRuntimeType.native);
        expect(scriptManifest.runtime, PluginRuntimeType.script);
      });
    });

    group('equality', () {
      test('should be equal when all fields are the same', () {
        // Arrange
        const manifest1 = PluginManifest(
          id: 'plugin.test',
          name: 'Test',
          version: '1.0.0',
          description: 'Test plugin',
          runtime: PluginRuntimeType.wasm,
        );
        const manifest2 = PluginManifest(
          id: 'plugin.test',
          name: 'Test',
          version: '1.0.0',
          description: 'Test plugin',
          runtime: PluginRuntimeType.wasm,
        );

        // Act & Assert
        expect(manifest1, equals(manifest2));
        expect(manifest1.hashCode, equals(manifest2.hashCode));
      });

      test('should not be equal when id differs', () {
        // Arrange
        const manifest1 = PluginManifest(
          id: 'plugin.test1',
          name: 'Test',
          version: '1.0.0',
          description: 'Test plugin',
          runtime: PluginRuntimeType.wasm,
        );
        const manifest2 = PluginManifest(
          id: 'plugin.test2',
          name: 'Test',
          version: '1.0.0',
          description: 'Test plugin',
          runtime: PluginRuntimeType.wasm,
        );

        // Act & Assert
        expect(manifest1, isNot(equals(manifest2)));
      });

      test('should not be equal when runtime differs', () {
        // Arrange
        const manifest1 = PluginManifest(
          id: 'plugin.test',
          name: 'Test',
          version: '1.0.0',
          description: 'Test plugin',
          runtime: PluginRuntimeType.wasm,
        );
        const manifest2 = PluginManifest(
          id: 'plugin.test',
          name: 'Test',
          version: '1.0.0',
          description: 'Test plugin',
          runtime: PluginRuntimeType.native,
        );

        // Act & Assert
        expect(manifest1, isNot(equals(manifest2)));
      });
    });

    group('copyWith', () {
      test('should copy with new id', () {
        // Arrange
        const original = PluginManifest(
          id: 'plugin.test',
          name: 'Test',
          version: '1.0.0',
          description: 'Test plugin',
          runtime: PluginRuntimeType.wasm,
        );

        // Act
        final copied = original.copyWith(id: 'plugin.new');

        // Assert
        expect(copied.id, 'plugin.new');
        expect(copied.name, original.name);
      });

      test('should copy with new version', () {
        // Arrange
        const original = PluginManifest(
          id: 'plugin.test',
          name: 'Test',
          version: '1.0.0',
          description: 'Test plugin',
          runtime: PluginRuntimeType.wasm,
        );

        // Act
        final copied = original.copyWith(version: '2.0.0');

        // Assert
        expect(copied.version, '2.0.0');
        expect(copied.id, original.id);
      });

      test('should copy with new dependencies', () {
        // Arrange
        const original = PluginManifest(
          id: 'plugin.test',
          name: 'Test',
          version: '1.0.0',
          description: 'Test plugin',
          runtime: PluginRuntimeType.wasm,
          dependencies: ['plugin.a'],
        );

        // Act
        final copied = original.copyWith(dependencies: ['plugin.a', 'plugin.b']);

        // Assert
        expect(copied.dependencies, ['plugin.a', 'plugin.b']);
      });

      test('should copy with new metadata', () {
        // Arrange
        const original = PluginManifest(
          id: 'plugin.test',
          name: 'Test',
          version: '1.0.0',
          description: 'Test plugin',
          runtime: PluginRuntimeType.wasm,
        );

        // Act
        final copied = original.copyWith(metadata: {'key': 'value'});

        // Assert
        expect(copied.metadata, {'key': 'value'});
      });
    });

    group('JSON serialization', () {
      test('should serialize minimal manifest to JSON', () {
        // Arrange
        const manifest = PluginManifest(
          id: 'plugin.test',
          name: 'Test Plugin',
          version: '1.0.0',
          description: 'A test plugin',
          runtime: PluginRuntimeType.wasm,
        );

        // Act
        final json = manifest.toJson();

        // Assert
        expect(json['id'], 'plugin.test');
        expect(json['name'], 'Test Plugin');
        expect(json['version'], '1.0.0');
        expect(json['description'], 'A test plugin');
        expect(json['runtime'], 'wasm');
        expect(json['dependencies'], isEmpty);
        expect(json['requiredHostFunctions'], isEmpty);
        expect(json['providedEvents'], isEmpty);
        expect(json['subscribesTo'], isEmpty);
      });

      test('should serialize full manifest to JSON', () {
        // Arrange
        final manifest = PluginManifest(
          id: 'plugin.file-icons',
          name: 'File Icons',
          version: '2.1.0',
          description: 'Beautiful file icons',
          runtime: PluginRuntimeType.native,
          author: 'Editor Team',
          homepage: 'https://example.com',
          repository: 'https://github.com/example/plugin',
          license: 'MIT',
          dependencies: const ['plugin.core'],
          configSchema: const {'theme': 'string'},
          requiredHostFunctions: const ['get_file_extension'],
          providedEvents: const ['icon.loaded'],
          subscribesTo: const ['file.opened'],
          minHostVersion: '1.0.0',
          maxHostVersion: '2.0.0',
          metadata: const {'custom': 'value'},
        );

        // Act
        final json = manifest.toJson();

        // Assert
        expect(json['id'], 'plugin.file-icons');
        expect(json['name'], 'File Icons');
        expect(json['author'], 'Editor Team');
        expect(json['homepage'], 'https://example.com');
        expect(json['license'], 'MIT');
        expect(json['dependencies'], ['plugin.core']);
        expect(json['configSchema'], {'theme': 'string'});
        expect(json['minHostVersion'], '1.0.0');
      });

      test('should deserialize from JSON', () {
        // Arrange
        final json = {
          'id': 'plugin.test',
          'name': 'Test Plugin',
          'version': '1.0.0',
          'description': 'A test plugin',
          'runtime': 'wasm',
          'dependencies': <String>[],
          'requiredHostFunctions': <String>[],
          'providedEvents': <String>[],
          'subscribesTo': <String>[],
        };

        // Act
        final manifest = PluginManifest.fromJson(json);

        // Assert
        expect(manifest.id, 'plugin.test');
        expect(manifest.name, 'Test Plugin');
        expect(manifest.version, '1.0.0');
        expect(manifest.description, 'A test plugin');
        expect(manifest.runtime, PluginRuntimeType.wasm);
      });

      test('should round-trip through JSON', () {
        // Arrange
        final original = PluginManifest(
          id: 'plugin.roundtrip',
          name: 'Round Trip',
          version: '3.0.0',
          description: 'Round trip test',
          runtime: PluginRuntimeType.script,
          author: 'Test Author',
          dependencies: const ['plugin.dep1', 'plugin.dep2'],
          requiredHostFunctions: const ['func1', 'func2'],
          metadata: const {'key1': 'value1', 'key2': 42},
        );

        // Act
        final json = original.toJson();
        final deserialized = PluginManifest.fromJson(json);

        // Assert
        expect(deserialized, equals(original));
      });
    });

    group('edge cases', () {
      test('should handle empty strings', () {
        // Arrange & Act
        const manifest = PluginManifest(
          id: '',
          name: '',
          version: '',
          description: '',
          runtime: PluginRuntimeType.wasm,
        );

        // Assert
        expect(manifest.id, '');
        expect(manifest.name, '');
        expect(manifest.version, '');
        expect(manifest.description, '');
      });

      test('should handle large dependency lists', () {
        // Arrange
        final dependencies = List.generate(100, (i) => 'plugin.dep$i');
        final manifest = PluginManifest(
          id: 'plugin.test',
          name: 'Test',
          version: '1.0.0',
          description: 'Test',
          runtime: PluginRuntimeType.wasm,
          dependencies: dependencies,
        );

        // Act & Assert
        expect(manifest.dependencies.length, 100);
        expect(manifest.dependencies.first, 'plugin.dep0');
        expect(manifest.dependencies.last, 'plugin.dep99');
      });

      test('should handle complex config schema', () {
        // Arrange
        final schema = {
          'type': 'object',
          'properties': {
            'theme': {'type': 'string', 'enum': ['light', 'dark']},
            'size': {'type': 'number', 'minimum': 10, 'maximum': 100},
            'enabled': {'type': 'boolean'},
          },
          'required': ['theme'],
        };
        final manifest = PluginManifest(
          id: 'plugin.test',
          name: 'Test',
          version: '1.0.0',
          description: 'Test',
          runtime: PluginRuntimeType.wasm,
          configSchema: schema,
        );

        // Act & Assert
        expect(manifest.configSchema, schema);
        expect(manifest.configSchema!['type'], 'object');
        expect(manifest.configSchema!['properties'], isNotNull);
      });

      test('should handle unicode in fields', () {
        // Arrange
        const manifest = PluginManifest(
          id: 'plugin.unicode',
          name: 'Test 测试',
          version: '1.0.0',
          description: 'Description with emoji 🎉',
          runtime: PluginRuntimeType.wasm,
          author: 'Author 作者',
        );

        // Act & Assert
        expect(manifest.name, 'Test 测试');
        expect(manifest.description, contains('🎉'));
        expect(manifest.author, 'Author 作者');
      });

      test('should handle version formats', () {
        // Arrange
        const versions = [
          '1.0.0',
          '2.1.3',
          '0.0.1',
          '10.20.30',
          '1.0.0-alpha',
          '1.0.0-beta.1',
          '1.0.0+build.123',
        ];

        // Act & Assert
        for (final version in versions) {
          final manifest = PluginManifest(
            id: 'plugin.test',
            name: 'Test',
            version: version,
            description: 'Test',
            runtime: PluginRuntimeType.wasm,
          );
          expect(manifest.version, version);
        }
      });
    });
  });

  group('PluginPermissions', () {
    group('constructor', () {
      test('should create with default values', () {
        // Arrange & Act
        const permissions = PluginPermissions();

        // Assert
        expect(permissions.allowedHostFunctions, isEmpty);
        expect(permissions.maxExecutionTime, const Duration(seconds: 5));
        expect(permissions.maxMemoryBytes, 52428800); // 50 MB
        expect(permissions.maxCallDepth, 100);
        expect(permissions.canAccessNetwork, false);
        expect(permissions.filesystemAccess, FilesystemAccessLevel.none);
        expect(permissions.customLimits, isNull);
      });

      test('should create with custom values', () {
        // Arrange & Act
        final permissions = PluginPermissions(
          allowedHostFunctions: const ['func1', 'func2'],
          maxExecutionTime: const Duration(seconds: 10),
          maxMemoryBytes: 104857600, // 100 MB
          maxCallDepth: 200,
          canAccessNetwork: true,
          filesystemAccess: FilesystemAccessLevel.readWrite,
          customLimits: const {'custom': 'value'},
        );

        // Assert
        expect(permissions.allowedHostFunctions, ['func1', 'func2']);
        expect(permissions.maxExecutionTime, const Duration(seconds: 10));
        expect(permissions.maxMemoryBytes, 104857600);
        expect(permissions.maxCallDepth, 200);
        expect(permissions.canAccessNetwork, true);
        expect(permissions.filesystemAccess, FilesystemAccessLevel.readWrite);
        expect(permissions.customLimits, {'custom': 'value'});
      });
    });

    group('equality', () {
      test('should be equal when all fields are the same', () {
        // Arrange
        const permissions1 = PluginPermissions(
          allowedHostFunctions: ['func1'],
          maxExecutionTime: Duration(seconds: 5),
        );
        const permissions2 = PluginPermissions(
          allowedHostFunctions: ['func1'],
          maxExecutionTime: Duration(seconds: 5),
        );

        // Act & Assert
        expect(permissions1, equals(permissions2));
        expect(permissions1.hashCode, equals(permissions2.hashCode));
      });

      test('should not be equal when fields differ', () {
        // Arrange
        const permissions1 = PluginPermissions(canAccessNetwork: true);
        const permissions2 = PluginPermissions(canAccessNetwork: false);

        // Act & Assert
        expect(permissions1, isNot(equals(permissions2)));
      });
    });

    group('copyWith', () {
      test('should copy with new allowed host functions', () {
        // Arrange
        const original = PluginPermissions(
          allowedHostFunctions: ['func1'],
        );

        // Act
        final copied = original.copyWith(
          allowedHostFunctions: ['func1', 'func2'],
        );

        // Assert
        expect(copied.allowedHostFunctions, ['func1', 'func2']);
      });

      test('should copy with new network access', () {
        // Arrange
        const original = PluginPermissions(canAccessNetwork: false);

        // Act
        final copied = original.copyWith(canAccessNetwork: true);

        // Assert
        expect(copied.canAccessNetwork, true);
        expect(original.canAccessNetwork, false);
      });

      test('should copy with new filesystem access', () {
        // Arrange
        const original = PluginPermissions(
          filesystemAccess: FilesystemAccessLevel.none,
        );

        // Act
        final copied = original.copyWith(
          filesystemAccess: FilesystemAccessLevel.full,
        );

        // Assert
        expect(copied.filesystemAccess, FilesystemAccessLevel.full);
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON', () {
        // Arrange
        const permissions = PluginPermissions(
          allowedHostFunctions: ['func1', 'func2'],
          canAccessNetwork: true,
          filesystemAccess: FilesystemAccessLevel.readOnly,
        );

        // Act
        final json = permissions.toJson();

        // Assert
        expect(json['allowedHostFunctions'], ['func1', 'func2']);
        expect(json['canAccessNetwork'], true);
        expect(json['filesystemAccess'], 'readOnly');
      });

      test('should deserialize from JSON', () {
        // Arrange
        final json = {
          'allowedHostFunctions': ['func1'],
          'maxExecutionTime': 5000000,
          'maxMemoryBytes': 52428800,
          'maxCallDepth': 100,
          'canAccessNetwork': false,
          'filesystemAccess': 'none',
        };

        // Act
        final permissions = PluginPermissions.fromJson(json);

        // Assert
        expect(permissions.allowedHostFunctions, ['func1']);
        expect(permissions.canAccessNetwork, false);
        expect(permissions.filesystemAccess, FilesystemAccessLevel.none);
      });

      test('should round-trip through JSON', () {
        // Arrange
        final original = PluginPermissions(
          allowedHostFunctions: const ['func1', 'func2'],
          maxExecutionTime: const Duration(seconds: 10),
          maxMemoryBytes: 100000000,
          maxCallDepth: 150,
          canAccessNetwork: true,
          filesystemAccess: FilesystemAccessLevel.readWrite,
          customLimits: const {'limit1': 100, 'limit2': 'value'},
        );

        // Act
        final json = original.toJson();
        final deserialized = PluginPermissions.fromJson(json);

        // Assert
        expect(deserialized, equals(original));
      });
    });
  });

  group('FilesystemAccessLevel', () {
    test('should have all expected values', () {
      // Arrange & Act & Assert
      expect(FilesystemAccessLevel.values, [
        FilesystemAccessLevel.none,
        FilesystemAccessLevel.readOnly,
        FilesystemAccessLevel.readWrite,
        FilesystemAccessLevel.full,
      ]);
    });

    test('should have correct enum values', () {
      // Arrange & Act & Assert
      expect(FilesystemAccessLevel.none.name, 'none');
      expect(FilesystemAccessLevel.readOnly.name, 'readOnly');
      expect(FilesystemAccessLevel.readWrite.name, 'readWrite');
      expect(FilesystemAccessLevel.full.name, 'full');
    });

    test('should be usable in switch statements', () {
      // Arrange
      const level = FilesystemAccessLevel.readOnly;

      // Act
      final result = switch (level) {
        FilesystemAccessLevel.none => 'none',
        FilesystemAccessLevel.readOnly => 'read',
        FilesystemAccessLevel.readWrite => 'rw',
        FilesystemAccessLevel.full => 'full',
      };

      // Assert
      expect(result, 'read');
    });
  });
}
