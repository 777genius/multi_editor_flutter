import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugins/multi_editor_plugins.dart';

void main() {
  group('DependencyRequirement', () {
    group('parse', () {
      test('should parse dependency without version', () {
        final req = DependencyRequirement.parse('plugin-id');
        expect(req.pluginId, 'plugin-id');
        expect(req.versionConstraint, '*');
      });

      test('should parse dependency with version constraint', () {
        final req = DependencyRequirement.parse('plugin-id@^1.0.0');
        expect(req.pluginId, 'plugin-id');
        expect(req.versionConstraint, '^1.0.0');
      });

      test('should parse dependency with exact version', () {
        final req = DependencyRequirement.parse('plugin-id@1.2.3');
        expect(req.pluginId, 'plugin-id');
        expect(req.versionConstraint, '1.2.3');
      });

      test('should handle multiple @ symbols (take first)', () {
        final req = DependencyRequirement.parse('plugin-id@1.0.0@extra');
        expect(req.pluginId, 'plugin-id');
        expect(req.versionConstraint, '1.0.0');
      });
    });

    group('isSatisfiedBy', () {
      test('should accept any version with * constraint', () {
        final req = DependencyRequirement.parse('plugin@*');
        expect(req.isSatisfiedBy('1.0.0'), true);
        expect(req.isSatisfiedBy('2.5.8'), true);
        expect(req.isSatisfiedBy('0.1.0'), true);
      });

      test('should match exact version', () {
        final req = DependencyRequirement.parse('plugin@1.2.3');
        expect(req.isSatisfiedBy('1.2.3'), true);
        expect(req.isSatisfiedBy('1.2.4'), false);
        expect(req.isSatisfiedBy('1.2.2'), false);
      });

      test('should match caret constraint', () {
        final req = DependencyRequirement.parse('plugin@^1.2.0');
        expect(req.isSatisfiedBy('1.2.0'), true);
        expect(req.isSatisfiedBy('1.2.5'), true);
        expect(req.isSatisfiedBy('1.9.0'), true);
        expect(req.isSatisfiedBy('2.0.0'), false);
      });

      test('should match tilde constraint', () {
        final req = DependencyRequirement.parse('plugin@~1.2.0');
        expect(req.isSatisfiedBy('1.2.0'), true);
        expect(req.isSatisfiedBy('1.2.5'), true);
        expect(req.isSatisfiedBy('1.3.0'), false);
      });

      test('should match >= constraint', () {
        final req = DependencyRequirement.parse('plugin@>=1.2.0');
        expect(req.isSatisfiedBy('1.2.0'), true);
        expect(req.isSatisfiedBy('1.3.0'), true);
        expect(req.isSatisfiedBy('2.0.0'), true);
        expect(req.isSatisfiedBy('1.1.9'), false);
      });
    });
  });

  group('DependencyValidator', () {
    group('validateAll', () {
      test('should return no errors for valid dependencies', () {
        final manifests = {
          'plugin-a': const PluginManifest(
            id: 'plugin-a',
            name: 'Plugin A',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
          ),
          'plugin-b': const PluginManifest(
            id: 'plugin-b',
            name: 'Plugin B',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
            dependencies: ['plugin-a'],
          ),
        };

        final validator = DependencyValidator(manifests);
        final errors = validator.validateAll();

        expect(errors, isEmpty);
      });

      test('should detect missing dependencies', () {
        final manifests = {
          'plugin-a': const PluginManifest(
            id: 'plugin-a',
            name: 'Plugin A',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
            dependencies: ['missing-plugin'],
          ),
        };

        final validator = DependencyValidator(manifests);
        final errors = validator.validateAll();

        expect(errors.length, 1);
        expect(errors[0].type, DependencyErrorType.missingDependency);
        expect(errors[0].pluginId, 'plugin-a');
        expect(errors[0].message, contains('missing-plugin'));
      });

      test('should detect circular dependencies', () {
        final manifests = {
          'plugin-a': const PluginManifest(
            id: 'plugin-a',
            name: 'Plugin A',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
            dependencies: ['plugin-b'],
          ),
          'plugin-b': const PluginManifest(
            id: 'plugin-b',
            name: 'Plugin B',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
            dependencies: ['plugin-a'],
          ),
        };

        final validator = DependencyValidator(manifests);
        final errors = validator.validateAll();

        expect(errors.any((e) => e.type == DependencyErrorType.circularDependency), true);
      });

      test('should detect version incompatibility', () {
        final manifests = {
          'plugin-a': const PluginManifest(
            id: 'plugin-a',
            name: 'Plugin A',
            version: '2.0.0',
            description: 'Test',
            author: 'Test',
          ),
          'plugin-b': const PluginManifest(
            id: 'plugin-b',
            name: 'Plugin B',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
            dependencies: ['plugin-a@^1.0.0'],
          ),
        };

        final validator = DependencyValidator(manifests);
        final errors = validator.validateAll();

        expect(errors.any((e) => e.type == DependencyErrorType.incompatibleVersion), true);
        expect(errors[0].pluginId, 'plugin-b');
      });
    });

    group('buildDependencyGraph', () {
      test('should build dependency graph', () {
        final manifests = {
          'plugin-a': const PluginManifest(
            id: 'plugin-a',
            name: 'Plugin A',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
          ),
          'plugin-b': const PluginManifest(
            id: 'plugin-b',
            name: 'Plugin B',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
            dependencies: ['plugin-a'],
          ),
          'plugin-c': const PluginManifest(
            id: 'plugin-c',
            name: 'Plugin C',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
            dependencies: ['plugin-a', 'plugin-b'],
          ),
        };

        final validator = DependencyValidator(manifests);
        final graph = validator.buildDependencyGraph();

        expect(graph['plugin-a'], isEmpty);
        expect(graph['plugin-b'], ['plugin-a']);
        expect(graph['plugin-c'], ['plugin-a', 'plugin-b']);
      });
    });

    group('getLeafPlugins', () {
      test('should return plugins without dependencies', () {
        final manifests = {
          'plugin-a': const PluginManifest(
            id: 'plugin-a',
            name: 'Plugin A',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
          ),
          'plugin-b': const PluginManifest(
            id: 'plugin-b',
            name: 'Plugin B',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
            dependencies: ['plugin-a'],
          ),
          'plugin-c': const PluginManifest(
            id: 'plugin-c',
            name: 'Plugin C',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
          ),
        };

        final validator = DependencyValidator(manifests);
        final leaves = validator.getLeafPlugins();

        expect(leaves, containsAll(['plugin-a', 'plugin-c']));
        expect(leaves, isNot(contains('plugin-b')));
      });
    });

    group('getDependents', () {
      test('should return plugins that depend on specified plugin', () {
        final manifests = {
          'plugin-a': const PluginManifest(
            id: 'plugin-a',
            name: 'Plugin A',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
          ),
          'plugin-b': const PluginManifest(
            id: 'plugin-b',
            name: 'Plugin B',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
            dependencies: ['plugin-a'],
          ),
          'plugin-c': const PluginManifest(
            id: 'plugin-c',
            name: 'Plugin C',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
            dependencies: ['plugin-a'],
          ),
          'plugin-d': const PluginManifest(
            id: 'plugin-d',
            name: 'Plugin D',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
            dependencies: ['plugin-b'],
          ),
        };

        final validator = DependencyValidator(manifests);
        final dependents = validator.getDependents('plugin-a');

        expect(dependents, containsAll(['plugin-b', 'plugin-c']));
        expect(dependents, isNot(contains('plugin-d')));
      });
    });

    group('getDependencyDepth', () {
      test('should return 0 for plugin without dependencies', () {
        final manifests = {
          'plugin-a': const PluginManifest(
            id: 'plugin-a',
            name: 'Plugin A',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
          ),
        };

        final validator = DependencyValidator(manifests);
        final depth = validator.getDependencyDepth('plugin-a');

        expect(depth, 0);
      });

      test('should return 1 for plugin with one level of dependencies', () {
        final manifests = {
          'plugin-a': const PluginManifest(
            id: 'plugin-a',
            name: 'Plugin A',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
          ),
          'plugin-b': const PluginManifest(
            id: 'plugin-b',
            name: 'Plugin B',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
            dependencies: ['plugin-a'],
          ),
        };

        final validator = DependencyValidator(manifests);
        final depth = validator.getDependencyDepth('plugin-b');

        expect(depth, 1);
      });

      test('should return correct depth for nested dependencies', () {
        final manifests = {
          'plugin-a': const PluginManifest(
            id: 'plugin-a',
            name: 'Plugin A',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
          ),
          'plugin-b': const PluginManifest(
            id: 'plugin-b',
            name: 'Plugin B',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
            dependencies: ['plugin-a'],
          ),
          'plugin-c': const PluginManifest(
            id: 'plugin-c',
            name: 'Plugin C',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
            dependencies: ['plugin-b'],
          ),
        };

        final validator = DependencyValidator(manifests);

        expect(validator.getDependencyDepth('plugin-a'), 0);
        expect(validator.getDependencyDepth('plugin-b'), 1);
        expect(validator.getDependencyDepth('plugin-c'), 2);
      });

      test('should handle complex dependency tree', () {
        final manifests = {
          'plugin-a': const PluginManifest(
            id: 'plugin-a',
            name: 'Plugin A',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
          ),
          'plugin-b': const PluginManifest(
            id: 'plugin-b',
            name: 'Plugin B',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
          ),
          'plugin-c': const PluginManifest(
            id: 'plugin-c',
            name: 'Plugin C',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
            dependencies: ['plugin-a', 'plugin-b'],
          ),
          'plugin-d': const PluginManifest(
            id: 'plugin-d',
            name: 'Plugin D',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
            dependencies: ['plugin-c'],
          ),
        };

        final validator = DependencyValidator(manifests);
        final depth = validator.getDependencyDepth('plugin-d');

        // plugin-d depends on plugin-c (depth 1), which depends on plugin-a and plugin-b (depth 1)
        // So total depth is 2
        expect(depth, 2);
      });
    });

    group('circular dependency detection', () {
      test('should detect simple circular dependency (A -> B -> A)', () {
        final manifests = {
          'plugin-a': const PluginManifest(
            id: 'plugin-a',
            name: 'Plugin A',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
            dependencies: ['plugin-b'],
          ),
          'plugin-b': const PluginManifest(
            id: 'plugin-b',
            name: 'Plugin B',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
            dependencies: ['plugin-a'],
          ),
        };

        final validator = DependencyValidator(manifests);
        final errors = validator.validateAll();
        final circularErrors = errors
            .where((e) => e.type == DependencyErrorType.circularDependency)
            .toList();

        expect(circularErrors, isNotEmpty);
        expect(circularErrors[0].message, contains('Circular dependency'));
      });

      test('should detect complex circular dependency (A -> B -> C -> A)', () {
        final manifests = {
          'plugin-a': const PluginManifest(
            id: 'plugin-a',
            name: 'Plugin A',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
            dependencies: ['plugin-b'],
          ),
          'plugin-b': const PluginManifest(
            id: 'plugin-b',
            name: 'Plugin B',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
            dependencies: ['plugin-c'],
          ),
          'plugin-c': const PluginManifest(
            id: 'plugin-c',
            name: 'Plugin C',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
            dependencies: ['plugin-a'],
          ),
        };

        final validator = DependencyValidator(manifests);
        final errors = validator.validateAll();
        final circularErrors = errors
            .where((e) => e.type == DependencyErrorType.circularDependency)
            .toList();

        expect(circularErrors, isNotEmpty);
      });

      test('should not report circular dependency for valid DAG', () {
        final manifests = {
          'plugin-a': const PluginManifest(
            id: 'plugin-a',
            name: 'Plugin A',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
          ),
          'plugin-b': const PluginManifest(
            id: 'plugin-b',
            name: 'Plugin B',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
            dependencies: ['plugin-a'],
          ),
          'plugin-c': const PluginManifest(
            id: 'plugin-c',
            name: 'Plugin C',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
            dependencies: ['plugin-a'],
          ),
          'plugin-d': const PluginManifest(
            id: 'plugin-d',
            name: 'Plugin D',
            version: '1.0.0',
            description: 'Test',
            author: 'Test',
            dependencies: ['plugin-b', 'plugin-c'],
          ),
        };

        final validator = DependencyValidator(manifests);
        final errors = validator.validateAll();
        final circularErrors = errors
            .where((e) => e.type == DependencyErrorType.circularDependency)
            .toList();

        expect(circularErrors, isEmpty);
      });
    });
  });
}
