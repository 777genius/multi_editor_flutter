import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';

void main() {
  group('PluginManifestBuilder', () {
    test('should build a minimal valid manifest', () {
      final manifest = PluginManifestBuilder()
          .withId('test-plugin')
          .withName('Test Plugin')
          .withVersion('1.0.0')
          .build();

      expect(manifest.id, 'test-plugin');
      expect(manifest.name, 'Test Plugin');
      expect(manifest.version, '1.0.0');
      expect(manifest.dependencies, isEmpty);
      expect(manifest.capabilities, isEmpty);
      expect(manifest.activationEvents, isEmpty);
      expect(manifest.metadata, isEmpty);
    });

    test('should build a full manifest with all fields', () {
      final manifest = PluginManifestBuilder()
          .withId('full-plugin')
          .withName('Full Plugin')
          .withVersion('2.1.3')
          .withDescription('A comprehensive plugin')
          .withAuthor('John Doe')
          .addDependency('plugin-a')
          .addDependency('plugin-b@^1.0.0')
          .withCapability('lint', 'true')
          .withCapability('format', 'true')
          .addActivationEvent('onFileOpen:*.dart')
          .addActivationEvent('onFileOpen:*.json')
          .withMetadata({
            'homepage': 'https://example.com',
            'repository': 'github.com/example/plugin',
          })
          .build();

      expect(manifest.id, 'full-plugin');
      expect(manifest.name, 'Full Plugin');
      expect(manifest.version, '2.1.3');
      expect(manifest.description, 'A comprehensive plugin');
      expect(manifest.author, 'John Doe');
      expect(manifest.dependencies, ['plugin-a', 'plugin-b@^1.0.0']);
      expect(manifest.capabilities, {'lint': 'true', 'format': 'true'});
      expect(manifest.activationEvents, [
        'onFileOpen:*.dart',
        'onFileOpen:*.json',
      ]);
      expect(manifest.metadata['homepage'], 'https://example.com');
    });

    test('should support method chaining', () {
      final builder = PluginManifestBuilder();
      final result = builder
          .withId('chain-test')
          .withName('Chain Test')
          .withVersion('1.0.0');

      expect(result, same(builder));
    });

    test('should allow adding multiple dependencies at once', () {
      final manifest = PluginManifestBuilder()
          .withId('test-plugin')
          .withName('Test Plugin')
          .withVersion('1.0.0')
          .withDependencies(['dep1', 'dep2', 'dep3'])
          .build();

      expect(manifest.dependencies, ['dep1', 'dep2', 'dep3']);
    });

    test('should allow adding multiple capabilities at once', () {
      final manifest = PluginManifestBuilder()
          .withId('test-plugin')
          .withName('Test Plugin')
          .withVersion('1.0.0')
          .withCapabilities({'cap1': 'val1', 'cap2': 'val2'})
          .build();

      expect(manifest.capabilities, {'cap1': 'val1', 'cap2': 'val2'});
    });

    test('should allow adding multiple activation events at once', () {
      final manifest = PluginManifestBuilder()
          .withId('test-plugin')
          .withName('Test Plugin')
          .withVersion('1.0.0')
          .withActivationEvents(['event1', 'event2'])
          .build();

      expect(manifest.activationEvents, ['event1', 'event2']);
    });

    test('should allow adding metadata entries individually', () {
      final manifest = PluginManifestBuilder()
          .withId('test-plugin')
          .withName('Test Plugin')
          .withVersion('1.0.0')
          .addMetadata('key1', 'value1')
          .addMetadata('key2', 42)
          .build();

      expect(manifest.metadata['key1'], 'value1');
      expect(manifest.metadata['key2'], 42);
    });

    group('Validation', () {
      test('should throw error when ID is missing', () {
        expect(
          () => PluginManifestBuilder()
              .withName('Test Plugin')
              .withVersion('1.0.0')
              .build(),
          throwsArgumentError,
        );
      });

      test('should throw error when ID is empty', () {
        expect(
          () => PluginManifestBuilder()
              .withId('')
              .withName('Test Plugin')
              .withVersion('1.0.0')
              .build(),
          throwsArgumentError,
        );
      });

      test('should throw error when name is missing', () {
        expect(
          () => PluginManifestBuilder()
              .withId('test-plugin')
              .withVersion('1.0.0')
              .build(),
          throwsArgumentError,
        );
      });

      test('should throw error when version is missing', () {
        expect(
          () => PluginManifestBuilder()
              .withId('test-plugin')
              .withName('Test Plugin')
              .build(),
          throwsArgumentError,
        );
      });

      test('should throw error for invalid version format', () {
        expect(
          () => PluginManifestBuilder()
              .withId('test-plugin')
              .withName('Test Plugin')
              .withVersion('invalid')
              .build(),
          throwsArgumentError,
        );
      });

      test('should accept valid semver versions', () {
        expect(
          () => PluginManifestBuilder()
              .withId('test-plugin')
              .withName('Test Plugin')
              .withVersion('1.0.0')
              .build(),
          returnsNormally,
        );

        expect(
          () => PluginManifestBuilder()
              .withId('test-plugin')
              .withName('Test Plugin')
              .withVersion('1.0.0-alpha.1')
              .build(),
          returnsNormally,
        );
      });

      test('should throw error for invalid plugin ID format', () {
        expect(
          () => PluginManifestBuilder()
              .withId('Invalid_Plugin')
              .withName('Test Plugin')
              .withVersion('1.0.0')
              .build(),
          throwsArgumentError,
        );

        expect(
          () => PluginManifestBuilder()
              .withId('Plugin With Spaces')
              .withName('Test Plugin')
              .withVersion('1.0.0')
              .build(),
          throwsArgumentError,
        );
      });

      test('should accept valid plugin ID formats', () {
        expect(
          () => PluginManifestBuilder()
              .withId('valid-plugin')
              .withName('Test Plugin')
              .withVersion('1.0.0')
              .build(),
          returnsNormally,
        );

        expect(
          () => PluginManifestBuilder()
              .withId('my.plugin.name')
              .withName('Test Plugin')
              .withVersion('1.0.0')
              .build(),
          returnsNormally,
        );

        expect(
          () => PluginManifestBuilder()
              .withId('plugin123')
              .withName('Test Plugin')
              .withVersion('1.0.0')
              .build(),
          returnsNormally,
        );
      });
    });

    group('Reset and Reuse', () {
      test('should reset builder to initial state', () {
        final builder = PluginManifestBuilder()
            .withId('test-plugin')
            .withName('Test Plugin')
            .withVersion('1.0.0');

        builder.reset();

        expect(() => builder.build(), throwsArgumentError);
      });

      test('should allow reuse after reset', () {
        final builder = PluginManifestBuilder();

        final manifest1 = builder
            .withId('plugin1')
            .withName('Plugin 1')
            .withVersion('1.0.0')
            .build();

        builder.reset();

        final manifest2 = builder
            .withId('plugin2')
            .withName('Plugin 2')
            .withVersion('2.0.0')
            .build();

        expect(manifest1.id, 'plugin1');
        expect(manifest2.id, 'plugin2');
      });
    });

    group('fromManifest', () {
      test('should create builder from existing manifest', () {
        const original = PluginManifest(
          id: 'original-plugin',
          name: 'Original Plugin',
          version: '1.0.0',
          description: 'Original description',
          author: 'Original Author',
          dependencies: ['dep1'],
          capabilities: {'cap1': 'val1'},
          activationEvents: ['event1'],
          metadata: {'key': 'value'},
        );

        final builder = PluginManifestBuilder.fromManifest(original);
        final copy = builder.build();

        expect(copy.id, original.id);
        expect(copy.name, original.name);
        expect(copy.version, original.version);
        expect(copy.description, original.description);
        expect(copy.author, original.author);
        expect(copy.dependencies, original.dependencies);
        expect(copy.capabilities, original.capabilities);
        expect(copy.activationEvents, original.activationEvents);
        expect(copy.metadata, original.metadata);
      });

      test('should allow modifying cloned builder', () {
        const original = PluginManifest(
          id: 'original-plugin',
          name: 'Original Plugin',
          version: '1.0.0',
        );

        final modified = PluginManifestBuilder.fromManifest(
          original,
        ).withVersion('2.0.0').addDependency('new-dep').build();

        expect(modified.id, original.id);
        expect(modified.name, original.name);
        expect(modified.version, '2.0.0');
        expect(modified.dependencies, ['new-dep']);
      });
    });
  });

  group('ConfigFieldSchemaBuilder', () {
    test('should build a string field', () {
      final schema = ConfigFieldSchemaBuilder()
          .withKey('name')
          .asString()
          .withLabel('Name')
          .withDescription('User name')
          .withDefault('John')
          .required()
          .build();

      expect(schema.key, 'name');
      expect(schema.type, ConfigFieldType.string);
      expect(schema.label, 'Name');
      expect(schema.description, 'User name');
      expect(schema.defaultValue, 'John');
      expect(schema.required, true);
    });

    test('should build a number field with range', () {
      final schema = ConfigFieldSchemaBuilder()
          .withKey('timeout')
          .asNumber()
          .withDefault(5000)
          .withRange(min: 1000, max: 60000)
          .build();

      expect(schema.key, 'timeout');
      expect(schema.type, ConfigFieldType.number);
      expect(schema.defaultValue, 5000);
      expect(schema.min, 1000);
      expect(schema.max, 60000);
    });

    test('should build a boolean field', () {
      final schema = ConfigFieldSchemaBuilder()
          .withKey('enabled')
          .asBoolean()
          .withDefault(true)
          .build();

      expect(schema.key, 'enabled');
      expect(schema.type, ConfigFieldType.boolean);
      expect(schema.defaultValue, true);
    });

    test('should build a select field', () {
      final schema = ConfigFieldSchemaBuilder()
          .withKey('theme')
          .asSelect(['light', 'dark', 'auto'])
          .withDefault('auto')
          .build();

      expect(schema.key, 'theme');
      expect(schema.type, ConfigFieldType.select);
      expect(schema.options, ['light', 'dark', 'auto']);
      expect(schema.defaultValue, 'auto');
    });

    test('should build a multiSelect field', () {
      final schema = ConfigFieldSchemaBuilder()
          .withKey('features')
          .asMultiSelect(['lint', 'format', 'refactor'])
          .withDefault(['lint', 'format'])
          .build();

      expect(schema.key, 'features');
      expect(schema.type, ConfigFieldType.multiSelect);
      expect(schema.options, ['lint', 'format', 'refactor']);
      expect(schema.defaultValue, ['lint', 'format']);
    });

    test('should build an object field', () {
      final schema = ConfigFieldSchemaBuilder().withKey('server').asObject({
        'host': const ConfigFieldSchema(
          key: 'host',
          type: ConfigFieldType.string,
          defaultValue: 'localhost',
        ),
        'port': const ConfigFieldSchema(
          key: 'port',
          type: ConfigFieldType.number,
          defaultValue: 8080,
        ),
      }).build();

      expect(schema.key, 'server');
      expect(schema.type, ConfigFieldType.object);
      expect(schema.properties, isNotNull);
      expect(schema.properties!.containsKey('host'), true);
      expect(schema.properties!.containsKey('port'), true);
    });

    test('should build string field with pattern', () {
      final schema = ConfigFieldSchemaBuilder()
          .withKey('email')
          .asString()
          .withPattern(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
          .build();

      expect(schema.key, 'email');
      expect(schema.pattern, isNotNull);
    });

    test('should support optional fields', () {
      final schema = ConfigFieldSchemaBuilder()
          .withKey('optional-field')
          .asString()
          .optional()
          .build();

      expect(schema.required, false);
    });

    group('Validation', () {
      test('should throw error when key is missing', () {
        expect(
          () => ConfigFieldSchemaBuilder().asString().build(),
          throwsArgumentError,
        );
      });

      test('should throw error when type is missing', () {
        expect(
          () => ConfigFieldSchemaBuilder().withKey('field').build(),
          throwsArgumentError,
        );
      });

      test('should throw error for select without options', () {
        expect(
          () =>
              ConfigFieldSchemaBuilder().withKey('field').asSelect([]).build(),
          throwsArgumentError,
        );
      });

      test('should throw error for object without properties', () {
        expect(
          () =>
              ConfigFieldSchemaBuilder().withKey('field').asObject({}).build(),
          throwsArgumentError,
        );
      });

      test('should throw error for invalid default value type', () {
        expect(
          () => ConfigFieldSchemaBuilder()
              .withKey('field')
              .asString()
              .withDefault(123)
              .build(),
          throwsArgumentError,
        );

        expect(
          () => ConfigFieldSchemaBuilder()
              .withKey('field')
              .asNumber()
              .withDefault('not a number')
              .build(),
          throwsArgumentError,
        );

        expect(
          () => ConfigFieldSchemaBuilder()
              .withKey('field')
              .asBoolean()
              .withDefault('not a boolean')
              .build(),
          throwsArgumentError,
        );
      });
    });
  });

  group('PluginConfigSchemaBuilder', () {
    test('should build config schema with multiple fields', () {
      final configSchema = PluginConfigSchemaBuilder()
          .addField(
            ConfigFieldSchemaBuilder()
                .withKey('enabled')
                .asBoolean()
                .withDefault(true)
                .required()
                .build(),
          )
          .addField(
            ConfigFieldSchemaBuilder()
                .withKey('timeout')
                .asNumber()
                .withDefault(5000)
                .build(),
          )
          .build();

      expect(configSchema.fields.length, 2);
      expect(configSchema.fields.containsKey('enabled'), true);
      expect(configSchema.fields.containsKey('timeout'), true);
    });

    test('should support adding fields using builder function', () {
      final configSchema = PluginConfigSchemaBuilder()
          .field(
            (b) => b.withKey('name').asString().withDefault('default').build(),
          )
          .field((b) => b.withKey('count').asNumber().withDefault(0).build())
          .build();

      expect(configSchema.fields.length, 2);
      expect(configSchema.fields.containsKey('name'), true);
      expect(configSchema.fields.containsKey('count'), true);
    });

    test('should allow adding multiple fields at once', () {
      final fields = [
        ConfigFieldSchemaBuilder().withKey('field1').asString().build(),
        ConfigFieldSchemaBuilder().withKey('field2').asNumber().build(),
      ];

      final configSchema = PluginConfigSchemaBuilder()
          .addFields(fields)
          .build();

      expect(configSchema.fields.length, 2);
    });

    test('should allow removing fields', () {
      final configSchema = PluginConfigSchemaBuilder()
          .addField(
            ConfigFieldSchemaBuilder().withKey('field1').asString().build(),
          )
          .addField(
            ConfigFieldSchemaBuilder().withKey('field2').asString().build(),
          )
          .removeField('field1')
          .build();

      expect(configSchema.fields.length, 1);
      expect(configSchema.fields.containsKey('field2'), true);
    });

    test('should throw error when no fields are added', () {
      expect(() => PluginConfigSchemaBuilder().build(), throwsArgumentError);
    });

    test('should create builder from existing schema', () {
      const original = PluginConfigSchema({
        'field1': ConfigFieldSchema(
          key: 'field1',
          type: ConfigFieldType.string,
        ),
        'field2': ConfigFieldSchema(
          key: 'field2',
          type: ConfigFieldType.number,
        ),
      });

      final builder = PluginConfigSchemaBuilder.fromSchema(original);
      final copy = builder.build();

      expect(copy.fields.length, 2);
      expect(copy.fields.containsKey('field1'), true);
      expect(copy.fields.containsKey('field2'), true);
    });
  });
}
